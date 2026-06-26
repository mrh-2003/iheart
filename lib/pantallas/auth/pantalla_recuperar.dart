import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:optima_ml/nucleo/tema.dart';
import 'package:optima_ml/nucleo/extensiones.dart';
import 'package:optima_ml/widgets/boton_primario.dart';
import 'package:optima_ml/widgets/boton_secundario.dart';
import 'package:optima_ml/widgets/campo_texto.dart';

class PantallaRecuperar extends StatefulWidget {
  const PantallaRecuperar({super.key});

  @override
  State<PantallaRecuperar> createState() => _PantallaRecuperarState();
}

class _PantallaRecuperarState extends State<PantallaRecuperar> {
  final _formularioClave = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _controladorCorreo.dispose();
    super.dispose();
  }

  Future<void> _restablecer() async {
    if (!_formularioClave.currentState!.validate()) return;

    setState(() {
      _enviando = true;
    });

    try {
      // Simulando comunicación API de recuperación de contraseña
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.mostrarMensajeExito('Código de recuperación enviado a su correo.');
        context.pop();
      }
    } catch (_) {
      if (mounted) {
        context.mostrarMensajeError('Error al procesar la solicitud.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Form(
            key: _formularioClave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Ingrese su correo electrónico y le enviaremos un enlace con las instrucciones para restablecer su contraseña.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: TemaApp.textoSecundario,
                  ),
                ),
                const SizedBox(height: 36),
                CampoTexto(
                  controlador: _controladorCorreo,
                  etiqueta: 'Correo electrónico',
                  pista: 'ejemplo@correo.com',
                  iconoPrefijo: Icons.email_outlined,
                  tipoTeclado: TextInputType.emailAddress,
                  validador: (valor) {
                    if (valor == null || valor.isEmpty) {
                      return 'El correo es obligatorio';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(valor)) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),
                BotonPrimario(
                  texto: 'Restablecer',
                  cargando: _enviando,
                  alPresionar: _restablecer,
                ),
                const SizedBox(height: 16),
                BotonSecundario(
                  texto: 'Cancelar',
                  alPresionar: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
