import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:optima_ml/nucleo/tema.dart';
import 'package:optima_ml/nucleo/extensiones.dart';
import 'package:optima_ml/nucleo/proveedor_estado.dart';
import 'package:optima_ml/widgets/boton_primario.dart';
import 'package:optima_ml/widgets/grafico_ppg.dart';
import 'package:optima_ml/widgets/tarjeta_sesion.dart';

class PantallaHistorial extends StatelessWidget {
  const PantallaHistorial({super.key});

  Future<void> _exportarHistorial(BuildContext contexto) async {
    // Simular la exportación de archivos
    await Future.delayed(const Duration(milliseconds: 800));
    if (contexto.mounted) {
      contexto.mostrarMensajeExito('Historial exportado en formato CSV con éxito.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();
    final sesiones = estado.sesiones;

    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Señal PPG en vivo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TemaApp.textoOscuro,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TemaApp.grisSuperficie,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaApp.grisBorde),
              ),
              child: const GraficoPPG(interactivo: true),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sesiones Recientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TemaApp.textoOscuro,
              ),
            ),
            const SizedBox(height: 12),
            if (sesiones.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No hay sesiones registradas.',
                    style: TextStyle(color: TemaApp.textoSecundario),
                  ),
                ),
              )
            else
              ...sesiones.map((sesion) => TarjetaSesion(
                    sesion: sesion,
                    alPresionar: () {
                      final diagnosticos = estado.historial;
                      // Buscar el diagnóstico asociado a esta sesión
                      final diagAsociado = diagnosticos.firstWhere(
                        (d) => d['sesion_tipo'] == sesion.tipo,
                        orElse: () => <String, Object?>{},
                      );
                      if (diagAsociado.containsKey('diagnostico_id')) {
                        context.push('/diagnostico_detalle', extra: {
                          'diagnosticoId': diagAsociado['diagnostico_id'] as int,
                        });
                      } else {
                        context.mostrarMensajeError('No hay diagnóstico clínico para esta sesión');
                      }
                    },
                  )),
            const SizedBox(height: 24),
            BotonPrimario(
              texto: 'EXPORTAR HISTORIAL',
              alPresionar: () => _exportarHistorial(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
