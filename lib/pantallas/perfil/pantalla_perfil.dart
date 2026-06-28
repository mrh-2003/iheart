import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/datos/repositorio_perfil.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/campo_texto.dart';

class PantallaPerfil extends StatefulWidget {
  const PantallaPerfil({super.key});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  final _formularioClave = GlobalKey<FormState>();
  late TextEditingController _controladorNombre;
  late TextEditingController _controladorEdad;
  late TextEditingController _controladorPeso;
  late TextEditingController _controladorAltura;
  
  String? _sexoSeleccionado;
  double _imcCalculado = 0.0;

  @override
  void initState() {
    super.initState();
    final perfil = context.read<ProveedorEstado>().perfil;
    _controladorNombre = TextEditingController(text: perfil?.nombreCompleto ?? '');
    _controladorEdad = TextEditingController(text: perfil?.edad?.toString() ?? '');
    _controladorPeso = TextEditingController(text: perfil?.pesoKg?.toString() ?? '');
    _controladorAltura = TextEditingController(text: perfil?.alturaM?.toString() ?? '');
    _sexoSeleccionado = perfil?.sexo;
    _calcularImcInicial();

    _controladorPeso.addListener(_recalcularImc);
    _controladorAltura.addListener(_recalcularImc);
  }

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorEdad.dispose();
    _controladorPeso.dispose();
    _controladorAltura.dispose();
    super.dispose();
  }

  void _calcularImcInicial() {
    final peso = double.tryParse(_controladorPeso.text) ?? 0.0;
    final altura = double.tryParse(_controladorAltura.text) ?? 0.0;
    if (altura > 0) {
      _imcCalculado = double.parse((peso / (altura * altura)).toStringAsFixed(2));
    }
  }

  void _recalcularImc() {
    final peso = double.tryParse(_controladorPeso.text) ?? 0.0;
    final altura = double.tryParse(_controladorAltura.text) ?? 0.0;
    if (altura > 0) {
      setState(() {
        _imcCalculado = double.parse((peso / (altura * altura)).toStringAsFixed(2));
      });
    } else {
      setState(() {
        _imcCalculado = 0.0;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formularioClave.currentState!.validate()) return;

    final estado = context.read<ProveedorEstado>();
    final perfilActual = estado.perfil;
    if (perfilActual == null) return;

    final perfilActualizado = PerfilPaciente(
      id: perfilActual.id,
      nombreCompleto: _controladorNombre.text,
      numeroDni: perfilActual.numeroDni,
      correo: perfilActual.correo,
      edad: int.tryParse(_controladorEdad.text),
      sexo: _sexoSeleccionado,
      pesoKg: double.tryParse(_controladorPeso.text),
      alturaM: double.tryParse(_controladorAltura.text),
      imc: _imcCalculado > 0 ? _imcCalculado : null,
      ciudad: perfilActual.ciudad,
      pais: perfilActual.pais,
      tokenJwt: perfilActual.tokenJwt,
      tokenExpiraEn: perfilActual.tokenExpiraEn,
      versionModeloLocal: perfilActual.versionModeloLocal,
    );

    try {
      await estado.actualizarPerfil(perfilActualizado);
      if (mounted) {
        context.mostrarMensajeExito('Perfil actualizado con éxito');
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError('Error al guardar: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil = context.watch<ProveedorEstado>().perfil;
    final iniciales = perfil != null && perfil.nombreCompleto.isNotEmpty
        ? perfil.nombreCompleto.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'P';

    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formularioClave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: TemaApp.rojoPrimario,
                      child: Text(
                        iniciales,
                        style: const TextStyle(
                          fontSize: 32,
                          color: TemaApp.blancoFondo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      perfil?.nombreCompleto ?? 'Paciente',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: TemaApp.textoOscuro,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${perfil?.ciudad ?? "Lima"}, ${perfil?.pais ?? "Perú"}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: TemaApp.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CampoTexto(
                controlador: _controladorNombre,
                etiqueta: 'Nombre completo',
                iconoPrefijo: Icons.person_outline,
                validador: (valor) {
                  if (valor == null || valor.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CampoTexto(
                controlador: _controladorEdad,
                etiqueta: 'Edad (años)',
                iconoPrefijo: Icons.calendar_today_outlined,
                tipoTeclado: TextInputType.number,
                validador: (valor) {
                  if (valor == null || valor.isEmpty) return 'La edad es obligatoria';
                  if (int.tryParse(valor) == null) return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _sexoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Sexo biológico',
                  prefixIcon: const Icon(Icons.transgender, color: TemaApp.textoSecundario),
                  filled: true,
                  fillColor: TemaApp.grisSuperficie,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TemaApp.grisBorde),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                ],
                onChanged: (valor) {
                  setState(() {
                    _sexoSeleccionado = valor;
                  });
                },
                validator: (valor) => valor == null ? 'Seleccione su sexo' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CampoTexto(
                      controlador: _controladorPeso,
                      etiqueta: 'Peso (kg)',
                      iconoPrefijo: Icons.scale_outlined,
                      tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                      validador: (valor) {
                        if (valor == null || valor.isEmpty) return 'Obligatorio';
                        if (double.tryParse(valor) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CampoTexto(
                      controlador: _controladorAltura,
                      etiqueta: 'Altura (m)',
                      iconoPrefijo: Icons.height_outlined,
                      tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
                      validador: (valor) {
                        if (valor == null || valor.isEmpty) return 'Obligatorio';
                        if (double.tryParse(valor) == null) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: TemaApp.grisSuperficie,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TemaApp.grisBorde),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Índice de Masa Corporal (IMC)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TemaApp.textoOscuro,
                      ),
                    ),
                    Text(
                      _imcCalculado > 0 ? _imcCalculado.toStringAsFixed(2) : '--',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TemaApp.rojoPrimario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              BotonPrimario(
                texto: 'Actualizar mi perfil',
                alPresionar: _guardar,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
