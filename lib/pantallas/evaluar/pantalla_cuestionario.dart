import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:health/health.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/datos/repositorio_diagnosticos.dart';
import 'package:iheart/datos/repositorio_sesiones.dart';
import 'package:iheart/modelo/feature_engineering.dart';
import 'package:iheart/modelo/inferencia_local.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/red/servicio_biometrico.dart';

class PantallaCuestionario extends StatefulWidget {
  const PantallaCuestionario({super.key});

  @override
  State<PantallaCuestionario> createState() => _PantallaCuestionarioState();
}

class _PantallaCuestionarioState extends State<PantallaCuestionario> {
  final _formularioClave = GlobalKey<FormState>();
  final _controladorFrecuencia = TextEditingController();

  bool _cargandoHealthConnect = false;
  String? _fuenteFrecuencia;

  bool _diabetes = false;
  bool _hipertension = false;
  bool _accidenteCerebrovascular = false;
  bool _insuficienciaRenal = false;
  bool _enfermedadRespiratoria = false;
  bool _enfermedadTiroidea = false;
  bool _insuficienciaCardiaca = false;
  bool _dislipidemia = false;

  bool _obesidad = false;
  bool _antecedenteFamiliar = false;
  bool _edema = false;
  bool _disnea = false;
  bool _esfuerzoFisico = false;

  String _estadoTabaco = 'no_fumador';

  bool _dolorPecho = false;
  int _frecuenciaDolor = 0;
  String _tipoDolor = 'tipico';

  @override
  void dispose() {
    _controladorFrecuencia.dispose();
    super.dispose();
  }

  Future<void> _leerFrecuenciaDesdeHealthConnect() async {
    setState(() => _cargandoHealthConnect = true);

    try {
      final tipos = const [HealthDataType.HEART_RATE];
      final permisoConcedido = await ServicioBiometrico.instancia.solicitarAutorizacion(tipos);

      if (!permisoConcedido) {
        if (mounted) {
          context.mostrarMensajeError(
            'Se requiere permiso de Health Connect para leer la frecuencia cardíaca.',
          );
        }
        return;
      }

      final ahora = DateTime.now();
      final hace6Horas = ahora.subtract(const Duration(hours: 6));
      final datos = await ServicioBiometrico.instancia.obtenerDatosFrecuenciaCardiaca(
        hace6Horas,
        ahora,
      );

      if (datos.isEmpty) {
        if (mounted) {
          context.mostrarMensajeError(
            'No se encontró frecuencia cardíaca reciente. Ingrese el valor manualmente.',
          );
        }
        return;
      }

      final lecturaReciente = datos.last;
      final valorNumerico = lecturaReciente.value;
      double? bpm;

      if (valorNumerico is NumericHealthValue) {
        bpm = valorNumerico.numericValue.toDouble();
      }

      if (bpm == null || bpm <= 0) {
        if (mounted) {
          context.mostrarMensajeError(
            'El valor leído no es válido. Ingrese la frecuencia manualmente.',
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _controladorFrecuencia.text = bpm!.toStringAsFixed(0);
          _fuenteFrecuencia = lecturaReciente.sourceName;
        });
        context.mostrarMensajeExito(
          'Frecuencia cardíaca obtenida de Health Connect: ${bpm.toStringAsFixed(0)} bpm',
        );
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError(
          'Error al leer Health Connect: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoHealthConnect = false);
    }
  }

  Future<void> _ejecutarDiagnostico() async {
    if (!_formularioClave.currentState!.validate()) return;

    final estado = context.read<ProveedorEstado>();
    final perfil = estado.perfil;
    if (perfil == null) {
      context.mostrarMensajeError('No se encontró el perfil del paciente.');
      return;
    }

    final double? ritmoCardiaco = double.tryParse(_controladorFrecuencia.text);
    if (ritmoCardiaco == null || ritmoCardiaco <= 0) {
      context.mostrarMensajeError(
        'Ingrese una frecuencia cardíaca válida antes de continuar.',
      );
      return;
    }

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
      clasificacionDolor: _dolorPecho
          ? (_tipoDolor == 'tipico' ? 2 : (_tipoDolor == 'atipico' ? 1 : 0))
          : 0,
      tipoDolor: _dolorPecho ? _tipoDolor : null,
      esfuerzoFisicoReciente: _esfuerzoFisico,
      disnea: _disnea,
      creadoEn: DateTime.now().toIso8601String(),
    );

    final sesion = SesionMonitoreo(
      tipo: _fuenteFrecuencia != null ? 'reposo' : 'manual',
      bpmPromedio: ritmoCardiaco,
      fuente: _fuenteFrecuencia != null ? 'smartwatch' : 'manual',
      dispositivoNombre: _fuenteFrecuencia ?? 'Ingreso manual del paciente',
      duracionSegundos: 0,
      iniciadoEn: DateTime.now().toIso8601String(),
    );

    try {
      final features = FeatureEngineering.generarFeatures(
        perfil: perfil,
        cuestionario: cuestionario,
        ritmoCardiaco: ritmoCardiaco,
      );

      final probabilidad = await InferenciaLocal.instancia.ejecutarInferencia(features);

      String nivelRiesgo = 'bajo';
      if (probabilidad > 0.8) {
        nivelRiesgo = 'crítico';
      } else if (probabilidad > 0.5) {
        nivelRiesgo = 'alto';
      } else if (probabilidad > 0.25) {
        nivelRiesgo = 'moderado';
      }

      final etiqueta = probabilidad >= 0.5 ? 'CAD' : 'Normal';

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

  Widget _construirTarjetaFrecuencia() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: TemaApp.rojoPrimario, size: 24),
              SizedBox(width: 12),
              Text(
                'Frecuencia Cardíaca (PR)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ingrese su ritmo cardíaco actual o impórtelo desde su wearable.',
                  style: TextStyle(fontSize: 13, color: TemaApp.textoSecundario),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 90,
                child: TextFormField(
                  controller: _controladorFrecuencia,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: '-- bpm',
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: TemaApp.rojoPrimario, width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: TemaApp.grisBorde),
                    ),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'Requerido';
                    }
                    final parsed = double.tryParse(valor);
                    if (parsed == null || parsed <= 0) {
                      return 'Inválido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (_fuenteFrecuencia != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: TemaApp.verdeExito, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sincronizado vía: $_fuenteFrecuencia',
                    style: const TextStyle(fontSize: 12, color: TemaApp.verdeExito, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _cargandoHealthConnect ? null : _leerFrecuenciaDesdeHealthConnect,
                  icon: _cargandoHealthConnect
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: TemaApp.rojoPrimario,
                          ),
                        )
                      : const Icon(Icons.watch_outlined, size: 18),
                  label: Text(_cargandoHealthConnect ? 'Sincronizando...' : 'Desde Health Connect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TemaApp.rojoPrimario,
                    side: const BorderSide(color: TemaApp.rojoPrimario),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _controladorFrecuencia.clear();
                      _fuenteFrecuencia = null;
                    });
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Ingresar Manual'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TemaApp.textoSecundario,
                    side: const BorderSide(color: TemaApp.grisBorde),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaAntecedentes() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assignment_outlined, color: TemaApp.rojoPrimario, size: 24),
              SizedBox(width: 12),
              Text(
                'Antecedentes de Salud',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Marque las comorbilidades y patologías diagnosticadas previamente.',
            style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Diabetes Mellitus (DM)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _diabetes,
            activeColor: TemaApp.rojoPrimario,
            onChanged: (val) => setState(() => _diabetes = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Hipertensión Arterial (HTN)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _hipertension,
            activeColor: TemaApp.rojoPrimario,
            onChanged: (val) => setState(() => _hipertension = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Accidente Cerebrovascular (CVA)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _accidenteCerebrovascular,
            activeColor: TemaApp.rojoPrimario,
            onChanged: (val) => setState(() => _accidenteCerebrovascular = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Insuficiencia Renal Crónica (CRF)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _insuficienciaRenal,
            activeColor: TemaApp.rojoPrimario,
            onChanged: (val) => setState(() => _insuficienciaRenal = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Enfermedad respiratoria crónica', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _enfermedadRespiratoria,
            activeColor: TemaApp.rojoPrimario,
            onChanged: (val) => setState(() => _enfermedadRespiratoria = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Enfermedad tiroidea', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _enfermedadTiroidea,
            activeColor: TemaApp.rojoPrimario,
            onChanged: (val) => setState(() => _enfermedadTiroidea = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Insuficiencia Cardíaca Congestiva (CHF)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _insuficienciaCardiaca,
            activeColor: TemaApp.rojoPrimario,
            onChanged: (val) => setState(() => _insuficienciaCardiaca = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          CheckboxListTile(
            title: const Text('Dislipidemia (DLP)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _dislipidemia,
            activeColor: TemaApp.rojoPrimario,
            onChanged: (val) => setState(() => _dislipidemia = val ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaFactoresRiesgo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: TemaApp.rojoPrimario, size: 24),
              SizedBox(width: 12),
              Text(
                'Hábitos y Factores de Riesgo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _estadoTabaco,
            decoration: InputDecoration(
              labelText: 'Consumo de tabaco',
              labelStyle: const TextStyle(color: TemaApp.textoSecundario),
              filled: true,
              fillColor: TemaApp.grisSuperficie,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: const [
              DropdownMenuItem(
                value: 'no_fumador',
                child: Text('No fumo / Nunca he fumado', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem(
                value: 'activo',
                child: Text('Soy fumador activo', style: TextStyle(fontSize: 14)),
              ),
              DropdownMenuItem(
                value: 'ex_fumador',
                child: Text('He dejado de fumar (Ex-fumador)', style: TextStyle(fontSize: 14)),
              ),
            ],
            onChanged: (val) => setState(() => _estadoTabaco = val ?? 'no_fumador'),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('¿Padece obesidad?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _obesidad,
            activeThumbColor: TemaApp.rojoPrimario,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => setState(() => _obesidad = val),
          ),
          SwitchListTile(
            title: const Text('¿Familiar con enfermedad coronaria prematura?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _antecedenteFamiliar,
            activeThumbColor: TemaApp.rojoPrimario,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => setState(() => _antecedenteFamiliar = val),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaSintomas() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: TemaApp.rojoPrimario, size: 24),
              SizedBox(width: 12),
              Text(
                'Síntomas Recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('¿Dificultad respiratoria (Disnea)?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _disnea,
            activeThumbColor: TemaApp.rojoPrimario,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => setState(() => _disnea = val),
          ),
          SwitchListTile(
            title: const Text('¿Esfuerzo físico intenso reciente?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _esfuerzoFisico,
            activeThumbColor: TemaApp.rojoPrimario,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => setState(() => _esfuerzoFisico = val),
          ),
          SwitchListTile(
            title: const Text('¿Presenta Edema (hinchazón de miembros inferiores)?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _edema,
            activeThumbColor: TemaApp.rojoPrimario,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => setState(() => _edema = val),
          ),
          SwitchListTile(
            title: const Text('¿Presenta dolor en el pecho?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _dolorPecho,
            activeThumbColor: TemaApp.rojoPrimario,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => setState(() => _dolorPecho = val),
          ),
          if (_dolorPecho) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frecuencia del dolor (1 a 5):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
                ),
                Text(
                  _frecuenciaDolor.toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.rojoPrimario),
                ),
              ],
            ),
            Slider(
              value: _frecuenciaDolor.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: _frecuenciaDolor.toString(),
              activeColor: TemaApp.rojoPrimario,
              inactiveColor: TemaApp.grisBorde,
              onChanged: (val) => setState(() => _frecuenciaDolor = val.toInt()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _tipoDolor,
              decoration: InputDecoration(
                labelText: 'Clasificación del dolor',
                labelStyle: const TextStyle(color: TemaApp.textoSecundario),
                filled: true,
                fillColor: TemaApp.grisSuperficie,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'tipico',
                  child: Text('Dolor típico anginoso', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'atipico',
                  child: Text('Dolor atípico', style: TextStyle(fontSize: 14)),
                ),
                DropdownMenuItem(
                  value: 'no_anginoso',
                  child: Text('Dolor no anginoso', style: TextStyle(fontSize: 14)),
                ),
              ],
              onChanged: (val) => setState(() => _tipoDolor = val ?? 'tipico'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
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
              _construirTarjetaFrecuencia(),
              const SizedBox(height: 24),
              _construirTarjetaAntecedentes(),
              const SizedBox(height: 24),
              _construirTarjetaFactoresRiesgo(),
              const SizedBox(height: 24),
              _construirTarjetaSintomas(),
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
