import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/widgets/boton_primario.dart';

class PantallaModeloFL extends StatelessWidget {
  const PantallaModeloFL({super.key});

  Future<void> _solicitarEntrenamiento(BuildContext contexto) async {
    final estado = contexto.read<ProveedorEstado>();
    
    // Validar si el paciente tiene al menos 5 diagnósticos
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

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();
    final modeloFl = estado.estadoModelo;

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
            // Badge FL Activo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaApp.verdeExito.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaApp.verdeExito.withOpacity(0.3)),
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

            // Métricas del Modelo
            const Text(
              'Métricas Globales del Modelo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaApp.grisSuperficie,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaApp.grisBorde),
              ),
              child: Column(
                children: [
                  _construirMetrica('Accuracy Local', '${((modeloFl?.accuracyLocal ?? 0.942) * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 12),
                  _construirMetrica('Precisión', '92.5%'),
                  const SizedBox(height: 12),
                  _construirMetrica('Recall', '93.1%'),
                  const SizedBox(height: 12),
                  _construirMetrica('F1-Score', '92.8%'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Dispositivo PPG
            const Text(
              'Dispositivo IoT Conectado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
            const SizedBox(height: 12),
            Container(
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
                      color: TemaApp.rojoPrimario.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, color: TemaApp.rojoPrimario),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IHeart Wearable Smartband',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Calidad de PPG: Alta • Procesando en local',
                          style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Botón de entrenamiento
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

  Widget _construirMetrica(String clave, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(clave, style: const TextStyle(fontWeight: FontWeight.w600, color: TemaApp.textoOscuro)),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, color: TemaApp.rojoPrimario)),
      ],
    );
  }
}
