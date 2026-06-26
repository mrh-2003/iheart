import 'package:flutter/material.dart';
import 'package:optima_ml/nucleo/tema.dart';

class TarjetaRiesgo extends StatelessWidget {
  final double porcentajeRiesgo;
  final String nivelRiesgo;

  const TarjetaRiesgo({
    super.key,
    required this.porcentajeRiesgo,
    required this.nivelRiesgo,
  });

  Color _obtenerColorRiesgo(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'bajo':
        return TemaApp.verdeExito;
      case 'moderado':
        return TemaApp.amarilloAlerta;
      case 'alto':
        return TemaApp.rojoClaro;
      case 'crítico':
      case 'critico':
        return TemaApp.rojoError;
      default:
        return TemaApp.textoSecundario;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorRiesgo = _obtenerColorRiesgo(nivelRiesgo);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riesgo Coronario Estimado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TemaApp.textoOscuro,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(porcentajeRiesgo * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: colorRiesgo,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorRiesgo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  nivelRiesgo.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorRiesgo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: porcentajeRiesgo,
              minHeight: 12,
              backgroundColor: TemaApp.grisSuperficie,
              color: colorRiesgo,
            ),
          ),
        ],
      ),
    );
  }
}
