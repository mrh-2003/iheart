import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:health/health.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/datos/repositorio_modelo.dart';
import 'package:iheart/widgets/boton_primario.dart';

class PantallaModeloFL extends StatefulWidget {
  const PantallaModeloFL({super.key});

  @override
  State<PantallaModeloFL> createState() => _PantallaModeloFLState();
}

class _PantallaModeloFLState extends State<PantallaModeloFL> {
  final Health _health = Health();
  bool _disponibleHC = false;
  bool _autorizadoHC = false;
  String _dispositivoOrigen = 'Ninguno';
  bool _cargandoHC = true;

  @override
  void initState() {
    super.initState();
    _verificarHealthConnect();
  }

  Future<void> _verificarHealthConnect() async {
    try {
      final bool disponible = await _health.isHealthConnectAvailable();
      setState(() {
        _disponibleHC = disponible;
      });

      if (disponible) {
        final bool? tienePermiso = await _health.hasPermissions([HealthDataType.HEART_RATE]);
        setState(() {
          _autorizadoHC = tienePermiso ?? false;
        });

        if (_autorizadoHC) {
          final ahora = DateTime.now();
          final hace24Horas = ahora.subtract(const Duration(hours: 24));
          final datos = await _health.getHealthDataFromTypes(
            types: [HealthDataType.HEART_RATE],
            startTime: hace24Horas,
            endTime: ahora,
          );
          if (datos.isNotEmpty && mounted) {
            setState(() {
              _dispositivoOrigen = datos.last.sourceName;
            });
          }
        }
      }
    } catch (e) {
      // Ignorar
    } finally {
      if (mounted) {
        setState(() {
          _cargandoHC = false;
        });
      }
    }
  }

  Future<void> _solicitarEntrenamiento(BuildContext contexto) async {
    final estado = contexto.read<ProveedorEstado>();

    if (estado.historial.length < 5) {
      contexto.mostrarMensajeError(
        'Se requieren al menos 5 diagnósticos locales para calcular gradientes de entrenamiento (actual: ${estado.historial.length}).'
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: contexto,
      builder: (ctx) => AlertDialog(
        title: const Text('Consentimiento de Datos'),
        content: const Text(
          '¿Desea iniciar el entrenamiento local sobre sus datos y subir únicamente los pesos numéricos del modelo al servidor? Sus datos clínicos jamás saldrán de su dispositivo.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: TemaApp.textoSecundario)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aceptar y Subir', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await estado.entrenarYSubirPesosFL();
        if (contexto.mounted) {
          contexto.mostrarMensajeExito('Entrenamiento completado y pesos subidos con éxito.');
        }
      } catch (e) {
        if (contexto.mounted) {
          contexto.mostrarMensajeError('Error en entrenamiento federado: ${e.toString()}');
        }
      }
    }
  }

  Widget _construirMetrica(String clave, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(clave, style: const TextStyle(fontWeight: FontWeight.w600, color: TemaApp.textoOscuro)),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, color: TemaApp.rojoPrimario)),
      ],
    );
  }

  Widget _construirMetricasCard(EstadoModeloFl? modeloFl, int cantidadHistorial) {
    final String accuracyStr = modeloFl?.accuracyLocal != null
        ? '${((modeloFl!.accuracyLocal!) * 100).toStringAsFixed(1)}%'
        : 'Sin entrenar';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.grisSuperficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
      ),
      child: Column(
        children: [
          _construirMetrica('Muestras Locales', '$cantidadHistorial'),
          const SizedBox(height: 12),
          _construirMetrica('Accuracy Local', accuracyStr),
          const SizedBox(height: 12),
          _construirMetrica('Ronda del Modelo', '${modeloFl?.rondaActual ?? 0}'),
          const SizedBox(height: 12),
          _construirMetrica('Versión Local', 'v${modeloFl?.versionLocal ?? 0}'),
        ],
      ),
    );
  }

  Widget _construirDispositivoCard() {
    final String tituloDispositivo = _disponibleHC
        ? (_autorizadoHC ? _dispositivoOrigen : 'Google Health Connect')
        : 'Google Health Connect';
    final String subtituloDispositivo = _disponibleHC
        ? (_autorizadoHC ? 'Conexión activa y autorizada' : 'Acceso no vinculado')
        : 'No disponible en este dispositivo';
    final IconData icono = _disponibleHC && _autorizadoHC
        ? Icons.health_and_safety
        : Icons.health_and_safety_outlined;
    final Color colorIcono = _disponibleHC && _autorizadoHC
        ? TemaApp.verdeExito
        : TemaApp.textoSecundario;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorIcono.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: colorIcono),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tituloDispositivo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtituloDispositivo,
                  style: const TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ProveedorEstado estado = context.watch<ProveedorEstado>();
    final EstadoModeloFl? modeloFl = estado.estadoModelo;

    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Modelo de Inferencia FL'),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaApp.verdeExito.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaApp.verdeExito.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: TemaApp.verdeExito),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Federated Learning Activo',
                          style: TextStyle(fontWeight: FontWeight.bold, color: TemaApp.verdeExito, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Última sincronización: ${modeloFl?.ultimaSincronizacion?.split('T')[0] ?? "Nunca"}',
                          style: const TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Métricas Globales del Modelo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
            const SizedBox(height: 12),
            _construirMetricasCard(modeloFl, estado.historial.length),
            const SizedBox(height: 24),
            const Text(
              'Dispositivo IoT Conectado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
            const SizedBox(height: 12),
            _cargandoHC
                ? const Center(child: CircularProgressIndicator(color: TemaApp.rojoPrimario))
                : _construirDispositivoCard(),
            const SizedBox(height: 40),
            BotonPrimario(
              texto: 'ENTRENAR Y SUBIR PESOS',
              cargando: estado.cargando,
              alPresionar: () => _solicitarEntrenamiento(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
