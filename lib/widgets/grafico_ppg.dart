import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health/health.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/red/servicio_biometrico.dart';

class GraficoPPG extends StatefulWidget {
  final bool interactivo;

  const GraficoPPG({
    super.key,
    this.interactivo = false,
  });

  @override
  State<GraficoPPG> createState() => _GraficoPPGState();
}

class _GraficoPPGState extends State<GraficoPPG> {
  List<FlSpot> _puntos = [];
  bool _cargando = true;
  String? _error;
  DateTime? _inicioRango;
  DateTime? _finRango;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarDatosHealthConnect();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        _cargarDatosHealthConnect();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatosHealthConnect() async {
    try {
      final tipos = const [HealthDataType.HEART_RATE];
      final permisoConcedido = await ServicioBiometrico.instancia.solicitarAutorizacion(tipos);

      if (!permisoConcedido) {
        if (mounted) {
          setState(() {
            _error = 'Permiso de Health Connect no concedido.';
            _cargando = false;
          });
        }
        return;
      }

      final ahora = DateTime.now();
      final hace6Horas = ahora.subtract(const Duration(hours: 6));
      final datos = await ServicioBiometrico.instancia.obtenerDatosFrecuenciaCardiaca(
        hace6Horas,
        ahora,
      );

      if (!mounted) return;

      if (datos.isEmpty) {
        setState(() {
          _error = 'Sin datos de ritmo cardíaco en las últimas 6 horas.';
          _cargando = false;
        });
        return;
      }

      final List<HealthDataPoint> listadoClonado = List.from(datos);
      listadoClonado.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

      final baseMs = listadoClonado.first.dateFrom.millisecondsSinceEpoch.toDouble();
      final nuevos = <FlSpot>[];

      for (final punto in listadoClonado) {
        if (punto.value is NumericHealthValue) {
          final bpm = (punto.value as NumericHealthValue).numericValue.toDouble();
          if (bpm > 0 && bpm < 300) {
            final xMin = (punto.dateFrom.millisecondsSinceEpoch - baseMs) / 60000.0;
            nuevos.add(FlSpot(xMin, bpm));
          }
        }
      }

      if (nuevos.isEmpty) {
        setState(() {
          _error = 'Los datos disponibles no contienen valores de BPM válidos.';
          _cargando = false;
        });
        return;
      }

      setState(() {
        _puntos = nuevos;
        _inicioRango = listadoClonado.first.dateFrom;
        _finRango = listadoClonado.last.dateFrom;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al leer Health Connect: ${e.toString()}';
          _cargando = false;
        });
      }
    }
  }

  String _formatearEtiquetaX(double minutosDesdeInicio) {
    if (_inicioRango == null) return '';
    final momento = _inicioRango!.add(Duration(minutes: minutosDesdeInicio.toInt()));
    final h = momento.hour.toString().padLeft(2, '0');
    final m = momento.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: TemaApp.rojoPrimario),
              SizedBox(height: 12),
              Text(
                'Leyendo datos de Health Connect...',
                style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _puntos.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sensors_off_outlined,
                color: TemaApp.textoSecundario,
                size: 36,
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Sin datos disponibles.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _cargando = true;
                    _error = null;
                  });
                  _cargarDatosHealthConnect();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
                style: TextButton.styleFrom(foregroundColor: TemaApp.rojoPrimario),
              ),
            ],
          ),
        ),
      );
    }

    final minY = _puntos.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final maxY = _puntos.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final paddingY = (maxY - minY).clamp(5.0, double.infinity) * 0.2;
    final rangoMinX = _puntos.first.x;
    final rangoMaxX = _puntos.last.x;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_inicioRango != null && _finRango != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: TemaApp.textoSecundario),
                const SizedBox(width: 4),
                Text(
                  'Últimas 6 h · ${_puntos.length} lecturas',
                  style: const TextStyle(fontSize: 11, color: TemaApp.textoSecundario),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: TemaApp.grisBorde,
                  strokeWidth: 0.5,
                ),
                getDrawingVerticalLine: (_) => const FlLine(
                  color: TemaApp.grisBorde,
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Hora',
                      style: TextStyle(fontSize: 10, color: TemaApp.textoSecundario),
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: (rangoMaxX - rangoMinX) > 0 ? (rangoMaxX - rangoMinX) / 5 : 1,
                    getTitlesWidget: (valor, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          _formatearEtiquetaX(valor),
                          style: const TextStyle(fontSize: 9, color: TemaApp.textoSecundario),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: const RotatedBox(
                    quarterTurns: -1,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'BPM',
                        style: TextStyle(fontSize: 10, color: TemaApp.textoSecundario),
                      ),
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: ((maxY - minY) / 4).clamp(1.0, double.infinity),
                    getTitlesWidget: (valor, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          valor.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 9, color: TemaApp.textoSecundario),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: TemaApp.grisBorde, width: 0.5),
              ),
              minX: rangoMinX,
              maxX: rangoMaxX,
              minY: (minY - paddingY).clamp(0, double.infinity),
              maxY: maxY + paddingY,
              lineTouchData: LineTouchData(
                enabled: widget.interactivo,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            '${s.y.toStringAsFixed(0)} bpm',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: _puntos,
                  isCurved: true,
                  color: TemaApp.rojoPrimario,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: _puntos.length <= 30,
                    getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                      radius: 3,
                      color: TemaApp.rojoPrimario,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: TemaApp.rojoPrimario.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
