import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:optima_ml/nucleo/tema.dart';
import 'package:optima_ml/nucleo/extensiones.dart';
import 'package:optima_ml/nucleo/proveedor_estado.dart';
import 'package:optima_ml/widgets/boton_primario.dart';

class PantallaCalibracion extends StatefulWidget {
  const PantallaCalibracion({super.key});

  @override
  State<PantallaCalibracion> createState() => _PantallaCalibracionState();
}

class _PantallaCalibracionState extends State<PantallaCalibracion> {
  double _progreso = 0.0;
  String _estadoActual = 'Pendiente de inicio';
  bool _calibrando = false;
  bool _paso1Listo = false;
  bool _paso2Listo = false;
  bool _paso3Listo = false;

  Future<void> _iniciarCalibracion() async {
    setState(() {
      _calibrando = true;
      _progreso = 0.1;
      _estadoActual = 'Conectando al servidor...';
    });

    final estado = context.read<ProveedorEstado>();
    
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _progreso = 0.3;
        _paso1Listo = true;
        _estadoActual = 'Descargando parámetros del modelo...';
      });

      await estado.sincronizarModelo();
      
      setState(() {
        _progreso = 0.7;
        _paso2Listo = true;
        _estadoActual = 'Inicializando motor TFLite...';
      });

      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _progreso = 1.0;
        _paso3Listo = true;
        _estadoActual = 'Calibración completada con éxito.';
      });

      if (mounted) {
        context.mostrarMensajeExito('Calibración completada correctamente');
        context.go('/inicio');
      }
    } catch (e) {
      setState(() {
        _calibrando = false;
        _estadoActual = 'Error en la calibración.';
      });
      if (mounted) {
        context.mostrarMensajeError('Error de calibración: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Calibración del Modelo'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _progreso,
                        strokeWidth: 8,
                        backgroundColor: TemaApp.grisSuperficie,
                        color: TemaApp.rojoPrimario,
                      ),
                      Center(
                        child: Text(
                          '${(_progreso * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: TemaApp.rojoPrimario,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                '¿Qué estamos haciendo?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _estadoActual,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: TemaApp.textoSecundario,
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Configuración inicial:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
              const SizedBox(height: 16),
              _construirPaso('1. Verificar versión del modelo', _paso1Listo, Icons.cloud_done_outlined),
              const SizedBox(height: 12),
              _construirPaso('2. Descargar modelo TFLite y scaler', _paso2Listo, Icons.download_outlined),
              const SizedBox(height: 12),
              _construirPaso('3. Inicializar inferencia local segura', _paso3Listo, Icons.security_outlined),
              const Spacer(),
              if (!_calibrando)
                BotonPrimario(
                  texto: 'Comenzar Calibración',
                  alPresionar: _iniciarCalibracion,
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirPaso(String titulo, bool completado, IconData icono) {
    return Row(
      children: [
        Icon(
          completado ? Icons.check_circle : icono,
          color: completado ? TemaApp.verdeExito : TemaApp.textoSecundario,
          size: 24,
        ),
        const SizedBox(width: 16),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 14,
            fontWeight: completado ? FontWeight.bold : FontWeight.normal,
            color: completado ? TemaApp.textoOscuro : TemaApp.textoSecundario,
          ),
        ),
      ],
    );
  }
}
