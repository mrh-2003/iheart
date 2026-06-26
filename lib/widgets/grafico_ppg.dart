import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:optima_ml/nucleo/tema.dart';

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
  final List<FlSpot> _puntos = [];
  Timer? _temporizador;
  double _contadorX = 0;

  @override
  void initState() {
    super.initState();
    _generarPuntosIniciales();
    if (widget.interactivo) {
      _iniciarAnimacion();
    }
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _generarPuntosIniciales() {
    for (double i = 0; i < 50; i += 1) {
      _puntos.add(FlSpot(i, _calcularValorOnda(i)));
    }
    _contadorX = 49;
  }

  void _iniciarAnimacion() {
    _temporizador = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      setState(() {
        _contadorX += 1;
        _puntos.removeAt(0);
        _puntos.add(FlSpot(_contadorX, _calcularValorOnda(_contadorX)));
      });
    });
  }

  double _calcularValorOnda(double x) {
    // Simula una señal PPG (Pletismografía) con sístole, dicrotismo y diástole
    final double periodo = x % 20;
    if (periodo < 5) {
      // Subida rápida (onda sistólica)
      return sin((periodo / 5) * pi / 2) * 8 + 2;
    } else if (periodo < 9) {
      // Bajada inicial
      return cos(((periodo - 5) / 4) * pi / 3) * 5 + 5;
    } else if (periodo < 11) {
      // Muesca dicrota
      return sin(((periodo - 9) / 2) * pi) * 1.5 + 4.5;
    } else {
      // Descenso diastólico lento
      return ((20 - periodo) / 9) * 3 + 1.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: _puntos.isEmpty ? 0 : _puntos.first.x,
          maxX: _puntos.isEmpty ? 50 : _puntos.last.x,
          minY: 0,
          maxY: 12,
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: _puntos,
              isCurved: true,
              color: TemaApp.rojoPrimario,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: TemaApp.rojoPrimario.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
