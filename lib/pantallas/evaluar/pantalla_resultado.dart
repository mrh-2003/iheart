import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/tarjeta_riesgo.dart';

class PantallaResultado extends StatelessWidget {
  final double probabilidadRiesgo;
  final String nivelRiesgo;

  const PantallaResultado({
    super.key,
    required this.probabilidadRiesgo,
    required this.nivelRiesgo,
  });

  IconData _obtenerIconoRecomendacion(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'diet':
        return Icons.restaurant_menu;
      case 'doctor':
        return Icons.local_hospital;
      case 'exercise':
        return Icons.directions_run;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos recomendaciones proactivas estáticas para la presentación del resultado
    final List<Map<String, String>> recomendaciones = [];
    if (nivelRiesgo == 'alto' || nivelRiesgo == 'crítico') {
      recomendaciones.add({
        'texto': 'Se recomienda programar una cita con su cardiólogo a la brevedad.',
        'icono': 'doctor',
      });
      recomendaciones.add({
        'texto': 'Reduzca al mínimo la ingesta de sodio y mantenga un control riguroso de su presión arterial.',
        'icono': 'diet',
      });
    } else {
      recomendaciones.add({
        'texto': 'Mantenga una dieta saludable baja en sodio y grasas saturadas.',
        'icono': 'diet',
      });
      if (probabilidadRiesgo > 0.15) {
        recomendaciones.add({
          'texto': 'Intente realizar actividad física moderada al menos 30 minutos al día.',
          'icono': 'exercise',
        });
      }
    }

    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Resultados del Diagnóstico'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TarjetaRiesgo(
                porcentajeRiesgo: probabilidadRiesgo,
                nivelRiesgo: nivelRiesgo,
              ),
              const SizedBox(height: 24),
              
              // Métricas
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TemaApp.grisSuperficie,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TemaApp.grisBorde),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.favorite, color: TemaApp.rojoPrimario, size: 28),
                          const SizedBox(height: 8),
                          const Text('Avg HR', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('72 bpm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TemaApp.grisSuperficie,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TemaApp.grisBorde),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.bolt, color: TemaApp.rojoPrimario, size: 28),
                          const SizedBox(height: 8),
                          const Text('HRV', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12)),
                          const SizedBox(height: 4),
                          const Text('45 ms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              const Text(
                'Recomendaciones Proactivas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
              const SizedBox(height: 12),
              
              ...recomendaciones.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TemaApp.rojoPrimario.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _obtenerIconoRecomendacion(rec['icono'] ?? ''),
                        color: TemaApp.rojoPrimario,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        rec['texto'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: TemaApp.textoOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TemaApp.rojoError.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TemaApp.rojoError.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: TemaApp.rojoError),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Aviso: La estimación de riesgo es meramente informativa. Consulte SIEMPRE a un profesional de la salud.',
                        style: TextStyle(
                          fontSize: 12,
                          color: TemaApp.rojoError,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              BotonPrimario(
                texto: 'Volver al Inicio',
                alPresionar: () => context.go('/inicio'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
