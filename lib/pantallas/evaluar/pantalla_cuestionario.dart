import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/datos/repositorio_diagnosticos.dart';
import 'package:iheart/datos/repositorio_sesiones.dart';
import 'package:iheart/modelo/feature_engineering.dart';
import 'package:iheart/modelo/inferencia_local.dart';
import 'package:iheart/widgets/boton_primario.dart';

class PantallaCuestionario extends StatefulWidget {
  const PantallaCuestionario({super.key});

  @override
  State<PantallaCuestionario> createState() => _PantallaCuestionarioState();
}

class _PantallaCuestionarioState extends State<PantallaCuestionario> {
  final _formularioClave = GlobalKey<FormState>();
  final _controladorFrecuencia = TextEditingController(text: '72');

  // Factores Clínicos (Enfermedades)
  bool _diabetes = false;
  bool _hipertension = false;
  bool _accidenteCerebrovascular = false;
  bool _insuficienciaRenal = false;
  bool _enfermedadRespiratoria = false;
  bool _enfermedadTiroidea = false;
  bool _insuficienciaCardiaca = false;
  bool _dislipidemia = false;

  // Toggles de Sí/No
  bool _obesidad = false;
  bool _antecedenteFamiliar = false;
  bool _edema = false;
  bool _disnea = false;
  bool _esfuerzoFisico = false;

  // Tabaquismo
  String _estadoTabaco = 'no_fumador'; // no_fumador, activo, ex_fumador

  // Dolor en el pecho
  bool _dolorPecho = false;
  int _frecuenciaDolor = 0; // 0-5
  String _tipoDolor = 'tipico'; // tipico, atipico, no_anginoso

  @override
  void dispose() {
    _controladorFrecuencia.dispose();
    super.dispose();
  }

  void _simularFrecuenciaCardiaca() {
    // Simula una lectura desde wearable IoT o Health Connect
    final valorSimulado = 60 + (DateTime.now().millisecond % 40);
    setState(() {
      _controladorFrecuencia.text = valorSimulado.toString();
    });
    context.mostrarMensajeExito('Frecuencia cardíaca actualizada desde sensor: $valorSimulado bpm');
  }

  Future<void> _ejecutarDiagnostico() async {
    if (!_formularioClave.currentState!.validate()) return;

    final estado = context.read<ProveedorEstado>();
    final perfil = estado.perfil;
    if (perfil == null) {
      context.mostrarMensajeError('No se encontró el perfil del paciente.');
      return;
    }

    final double ritmoCardiaco = double.tryParse(_controladorFrecuencia.text) ?? 72.0;

    final cuestionario = CuestionarioClinico(
      tieneDiabetes: _diabetes,
      tieneHipertension: _hipertension,
      tieneAccidenteCerebrovascular: _accidenteCerebrovascular,
      tieneInsuficienciaRenal: _insuficienciaRenal,
      tieneEnfermedadRespiratoria: _enfermedadRespiratoria,
      tieneEnfermedadTiroidea: _enfermedadTiroidea,
      tieneInsuficienciaCardiaca: _insuficienciaCardiaca,
      tieneDislipidemia: _dislipidemia,
      tieneObesidad: _obesidad,
      esFumadorActivo: _estadoTabaco == 'activo',
      esExFumador: _estadoTabaco == 'ex_fumador',
      antecedenteFamiliarCad: _antecedenteFamiliar,
      presentaEdema: _edema,
      presentaDolorPecho: _dolorPecho,
      frecuenciaDolorPecho: _dolorPecho ? _frecuenciaDolor : 0,
      clasificacionDolor: _dolorPecho ? (_tipoDolor == 'tipico' ? 2 : (_tipoDolor == 'atipico' ? 1 : 0)) : 0,
      tipoDolor: _dolorPecho ? _tipoDolor : null,
      esfuerzoFisicoReciente: _esfuerzoFisico,
      disnea: _disnea,
      creadoEn: DateTime.now().toIso8601String(),
    );

    final sesion = SesionMonitoreo(
      tipo: 'manual',
      bpmPromedio: ritmoCardiaco,
      bpmMinimo: ritmoCardiaco - 5,
      bpmMaximo: ritmoCardiaco + 10,
      spo2Promedio: 98.0,
      hrvMs: 45.0,
      ritmoTipo: 'regular',
      calidadSenal: 'alta',
      fuente: 'manual',
      dispositivoNombre: 'Ingreso Manual',
      duracionSegundos: 60,
      iniciadoEn: DateTime.now().toIso8601String(),
    );

    try {
      // 1. Generar features de entrada
      final features = FeatureEngineering.generarFeatures(
        perfil: perfil,
        cuestionario: cuestionario,
        ritmoCardiaco: ritmoCardiaco,
      );

      // 2. Ejecutar inferencia local con TFLite
      final probabilidad = await InferenciaLocal.instancia.ejecutarInferencia(features);

      // 3. Determinar severidad del riesgo
      String nivelRiesgo = 'bajo';
      if (probabilidad > 0.8) {
        nivelRiesgo = 'crítico';
      } else if (probabilidad > 0.5) {
        nivelRiesgo = 'alto';
      } else if (probabilidad > 0.25) {
        nivelRiesgo = 'moderado';
      }

      final etiqueta = probabilidad >= 0.5 ? 'CAD' : 'Normal';

      // 4. Guardar diagnóstico y sesión localmente
      await estado.registrarDiagnosticoCompleto(
        sesion: sesion,
        cuestionario: cuestionario,
        probabilidad: probabilidad,
        riesgo: nivelRiesgo,
        etiqueta: etiqueta,
        featuresJson: features.toString(),
      );

      if (mounted) {
        context.pushReplacement('/resultado', extra: {
          'probabilidad': probabilidad,
          'riesgo': nivelRiesgo,
        });
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError('Error al ejecutar diagnóstico: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Cuestionario Clínico'),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formularioClave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Complete los datos clínicos a continuación para procesar la estimación de riesgo.',
                style: TextStyle(
                  fontSize: 14,
                  color: TemaApp.textoSecundario,
                ),
              ),
              const SizedBox(height: 24),
              
              // Frecuencia Cardíaca
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TemaApp.grisSuperficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TemaApp.grisBorde),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: TemaApp.rojoPrimario),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Frecuencia Cardíaca (BPM)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _controladorFrecuencia,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              border: UnderlineInputBorder(),
                            ),
                            validator: (valor) {
                              if (valor == null || valor.isEmpty) return 'Requerido';
                              if (int.tryParse(valor) == null) return 'Inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _simularFrecuenciaCardiaca,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Registrar Frecuencia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TemaApp.rojoPrimario,
                        foregroundColor: TemaApp.blancoFondo,
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Enfermedades preexistentes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
              ),
              const SizedBox(height: 12),
              
              // Checkboxes de enfermedades
              CheckboxListTile(
                title: const Text('Diabetes Mellitus'),
                value: _diabetes,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _diabetes = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Hipertensión Arterial'),
                value: _hipertension,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _hipertension = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Accidente Cerebrovascular (ACV)'),
                value: _accidenteCerebrovascular,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _accidenteCerebrovascular = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Insuficiencia Renal Crónica'),
                value: _insuficienciaRenal,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _insuficienciaRenal = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Enfermedad respiratoria crónica'),
                value: _enfermedadRespiratoria,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _enfermedadRespiratoria = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Enfermedad tiroidea'),
                value: _enfermedadTiroidea,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _enfermedadTiroidea = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Insuficiencia Cardíaca Congestiva'),
                value: _insuficienciaCardiaca,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _insuficienciaCardiaca = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: const Text('Dislipidemia'),
                value: _dislipidemia,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _dislipidemia = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 24),
              const Text(
                'Hábitos y Síntomas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
              ),
              const SizedBox(height: 16),

              // Tabaquismo Dropdown
              DropdownButtonFormField<String>(
                value: _estadoTabaco,
                decoration: const InputDecoration(
                  labelText: 'Consumo de tabaco',
                  filled: true,
                  fillColor: TemaApp.grisSuperficie,
                ),
                items: const [
                  DropdownMenuItem(value: 'no_fumador', child: Text('No fumo / Nunca he fumado')),
                  DropdownMenuItem(value: 'activo', child: Text('Soy fumador activo')),
                  DropdownMenuItem(value: 'ex_fumador', child: Text('He dejado de fumar (Ex-fumador)')),
                ],
                onChanged: (val) => setState(() => _estadoTabaco = val ?? 'no_fumador'),
              ),
              const SizedBox(height: 24),

              // Toggles
              SwitchListTile(
                title: const Text('¿Tiene obesidad?'),
                value: _obesidad,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _obesidad = val),
              ),
              SwitchListTile(
                title: const Text('¿Familiar con enfermedad coronaria prematura?'),
                value: _antecedenteFamiliar,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _antecedenteFamiliar = val),
              ),
              SwitchListTile(
                title: const Text('¿Presenta Edema (hinchazón de piernas)?'),
                value: _edema,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _edema = val),
              ),
              SwitchListTile(
                title: const Text('¿Dificultad respiratoria (Disnea)?'),
                value: _disnea,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _disnea = val),
              ),
              SwitchListTile(
                title: const Text('¿Esfuerzo físico reciente?'),
                value: _esfuerzoFisico,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _esfuerzoFisico = val),
              ),
              
              const SizedBox(height: 24),
              // Dolor en el pecho
              SwitchListTile(
                title: const Text('¿Presenta dolor en el pecho?'),
                value: _dolorPecho,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (val) => setState(() => _dolorPecho = val),
              ),
              
              if (_dolorPecho) ...[
                const SizedBox(height: 16),
                Text(
                  'Frecuencia del dolor (1 a 5): $_frecuenciaDolor',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _frecuenciaDolor.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: _frecuenciaDolor.toString(),
                  activeColor: TemaApp.rojoPrimario,
                  onChanged: (val) => setState(() => _frecuenciaDolor = val.toInt()),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tipoDolor,
                  decoration: const InputDecoration(
                    labelText: 'Clasificación del dolor de pecho',
                    filled: true,
                    fillColor: TemaApp.grisSuperficie,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'tipico', child: Text('Dolor típico anginoso')),
                    DropdownMenuItem(value: 'atipico', child: Text('Dolor atípico')),
                    DropdownMenuItem(value: 'no_anginoso', child: Text('Dolor no anginoso')),
                  ],
                  onChanged: (val) => setState(() => _tipoDolor = val ?? 'tipico'),
                ),
              ],

              const SizedBox(height: 40),
              BotonPrimario(
                texto: 'COMENZAR DIAGNÓSTICO',
                alPresionar: _ejecutarDiagnostico,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
