import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:optima_ml/nucleo/tema.dart';
import 'package:optima_ml/nucleo/proveedor_estado.dart';

class PantallaDiagnosticoDetalle extends StatelessWidget {
  final int diagnosticoId;

  const PantallaDiagnosticoDetalle({
    super.key,
    required this.diagnosticoId,
  });

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();
    final historial = estado.historial;

    // Obtener la sesión seleccionada y la sesión anterior
    final indiceActual = historial.indexWhere((element) => element['diagnostico_id'] == diagnosticoId);
    
    final Map<String, Object?>? actual = indiceActual != -1 ? historial[indiceActual] : null;
    final Map<String, Object?>? anterior = (indiceActual != -1 && indiceActual + 1 < historial.length) 
        ? historial[indiceActual + 1] 
        : null;

    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Detalle de Diagnóstico'),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Comparativa de Sesiones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Análisis comparativo de las métricas fisiológicas entre la última sesión y la sesión anterior.',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaApp.textoSecundario,
                ),
              ),
              const SizedBox(height: 24),
              if (actual == null)
                const Center(child: Text('No se encontraron registros clínicos.'))
              else
                Table(
                  border: TableBorder.all(color: TemaApp.grisBorde, width: 1, borderRadius: BorderRadius.circular(8)),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1.5),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Cabecera
                    TableRow(
                      decoration: const BoxDecoration(
                        color: TemaApp.grisSuperficie,
                      ),
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Métrica', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Anterior', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Última', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                    // Fecha
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Fecha', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            anterior != null ? (anterior['creado_en'] as String).split('T')[0] : '--',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            (actual['creado_en'] as String).split('T')[0],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Ritmo cardíaco
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Frec. Cardíaca', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            anterior != null && anterior['bpm_promedio'] != null
                                ? '${(anterior['bpm_promedio'] as num).toStringAsFixed(0)} bpm'
                                : '--',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            actual['bpm_promedio'] != null
                                ? '${(actual['bpm_promedio'] as num).toStringAsFixed(0)} bpm'
                                : '--',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // SpO2
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('SpO2', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            anterior != null && anterior['spo2_promedio'] != null
                                ? '${(anterior['spo2_promedio'] as num).toStringAsFixed(0)}%'
                                : '--',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            actual['spo2_promedio'] != null
                                ? '${(actual['spo2_promedio'] as num).toStringAsFixed(0)}%'
                                : '--',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // HRV
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('HRV', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            anterior != null && anterior['hrv_ms'] != null
                                ? '${(anterior['hrv_ms'] as num).toStringAsFixed(0)} ms'
                                : '--',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            actual['hrv_ms'] != null
                                ? '${(actual['hrv_ms'] as num).toStringAsFixed(0)} ms'
                                : '--',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    // Riesgo
                    TableRow(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text('Riesgo CAD', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            anterior != null
                                ? '${((anterior['probabilidad_cad'] as num) * 100).toStringAsFixed(1)}%'
                                : '--',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            '${((actual['probabilidad_cad'] as num) * 100).toStringAsFixed(1)}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: TemaApp.rojoPrimario),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 32),
              const Text(
                'Nota de Privacidad',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Todos los diagnósticos e historial se calculan mediante inferencia local utilizando el modelo TFLite de su dispositivo. Ninguno de estos datos médicos se envía al exterior.',
                style: TextStyle(
                  fontSize: 12,
                  color: TemaApp.textoSecundario,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
