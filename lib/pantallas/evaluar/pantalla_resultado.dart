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

  List<Map<String, String>> _obtenerRecomendaciones() {
    final List<Map<String, String>> lista = [];
    if (nivelRiesgo == 'alto' || nivelRiesgo == 'crítico') {
      lista.add({
        'texto': 'Se recomienda programar una cita con su cardiólogo a la brevedad.',
        'icono': 'doctor',
      });
      lista.add({
        'texto': 'Reduzca al mínimo la ingesta de sodio y mantenga un control riguroso de su presión arterial.',
        'icono': 'diet',
      });
    } else {
      lista.add({
        'texto': 'Mantenga una dieta saludable baja en sodio y grasas saturadas.',
        'icono': 'diet',
      });
      if (probabilidadRiesgo > 0.15) {
        lista.add({
          'texto': 'Intente realizar actividad física moderada al menos 30 minutos al día.',
          'icono': 'exercise',
        });
      }
    }
    return lista;
  }

  Widget _construirMetricas() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaApp.grisSuperficie,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TemaApp.grisBorde),
            ),
            child: const Column(
              children: [
                Icon(Icons.favorite, color: TemaApp.rojoPrimario, size: 28),
                SizedBox(height: 8),
                Text('Avg HR', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12)),
                SizedBox(height: 4),
                Text('72 bpm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            child: const Column(
              children: [
                Icon(Icons.bolt, color: TemaApp.rojoPrimario, size: 28),
                SizedBox(height: 8),
                Text('HRV', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12)),
                SizedBox(height: 4),
                Text('45 ms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirRecomendacionesLista(List<Map<String, String>> recomendaciones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  color: TemaApp.rojoPrimario.withValues(alpha: 0.08),
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
      ],
    );
  }

  Widget _construirAvisoLegal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TemaApp.rojoError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TemaApp.rojoError.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: TemaApp.rojoError),
          SizedBox(width: 16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final recomendaciones = _obtenerRecomendaciones();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        context.go('/inicio');
      },
      child: Scaffold(
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
                _construirMetricas(),
                const SizedBox(height: 24),
                _construirRecomendacionesLista(recomendaciones),
                const SizedBox(height: 32),
                _construirAvisoLegal(),
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
      ),
    );
  }
}
