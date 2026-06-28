import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/datos/repositorio_sesiones.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/grafico_ppg.dart';
import 'package:iheart/widgets/tarjeta_sesion.dart';

class PantallaHistorial extends StatelessWidget {
  const PantallaHistorial({super.key});

  String _construirContenidoCsv(
    List<SesionMonitoreo> sesiones,
    List<Map<String, Object?>> historial,
  ) {
    final buffer = StringBuffer();

    buffer.writeln(
      'fecha,hora,tipo,bpm_promedio,bpm_minimo,bpm_maximo,spo2_promedio,'
      'hrv_ms,ritmo_tipo,calidad_senal,fuente,dispositivo,duracion_seg,'
      'nivel_riesgo,probabilidad_cad,etiqueta_prediccion',
    );

    for (final sesion in sesiones) {
      final diagAsociado = historial.firstWhere(
        (d) => d['sesion_tipo'] == sesion.tipo,
        orElse: () => <String, Object?>{},
      );

      final fechaHora = DateTime.tryParse(sesion.iniciadoEn);
      final fechaStr = fechaHora != null
          ? '${fechaHora.year}-${fechaHora.month.toString().padLeft(2, '0')}-${fechaHora.day.toString().padLeft(2, '0')}'
          : sesion.iniciadoEn;
      final horaStr = fechaHora != null
          ? '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}'
          : '';

      final campos = [
        fechaStr,
        horaStr,
        sesion.tipo,
        sesion.bpmPromedio?.toStringAsFixed(1) ?? '',
        sesion.bpmMinimo?.toStringAsFixed(1) ?? '',
        sesion.bpmMaximo?.toStringAsFixed(1) ?? '',
        sesion.spo2Promedio?.toStringAsFixed(1) ?? '',
        sesion.hrvMs?.toStringAsFixed(1) ?? '',
        sesion.ritmoTipo ?? '',
        sesion.calidadSenal ?? '',
        sesion.fuente ?? '',
        '"${(sesion.dispositivoNombre ?? '').replaceAll('"', '""')}"',
        sesion.duracionSegundos?.toString() ?? '',
        diagAsociado['nivel_riesgo']?.toString() ?? '',
        diagAsociado['probabilidad_cad'] != null
            ? (diagAsociado['probabilidad_cad'] as num).toStringAsFixed(4)
            : '',
        diagAsociado['etiqueta_prediccion']?.toString() ?? '',
      ];

      buffer.writeln(campos.join(','));
    }

    return buffer.toString();
  }

  Future<void> _exportarHistorial(BuildContext contexto) async {
    final estado = contexto.read<ProveedorEstado>();
    final sesiones = estado.sesiones;
    final historial = estado.historial;

    if (sesiones.isEmpty) {
      if (contexto.mounted) {
        contexto.mostrarMensajeError('No hay sesiones para exportar.');
      }
      return;
    }

    try {
      if (Platform.isAndroid) {
        final statusStorage = await Permission.storage.status;
        final statusManage = await Permission.manageExternalStorage.status;
        if (!statusStorage.isGranted && !statusManage.isGranted) {
          final resStorage = await Permission.storage.request();
          final resManage = await Permission.manageExternalStorage.request();
          if (!resStorage.isGranted && !resManage.isGranted) {
            if (contexto.mounted) {
              contexto.mostrarMensajeError(
                'Permiso de almacenamiento denegado.',
              );
            }
            return;
          }
        }
      }

      final carpetaSeleccionada = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Elegir carpeta de destino para el CSV',
      );

      if (carpetaSeleccionada == null) {
        return;
      }

      final contenidoCsv = _construirContenidoCsv(sesiones, historial);

      final ahora = DateTime.now();
      final nombreArchivo =
          'iheart_historial_${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}_'
          '${ahora.hour.toString().padLeft(2, '0')}${ahora.minute.toString().padLeft(2, '0')}.csv';

      String rutaFinal;
      bool usadoRutaSegura = false;

      try {
        final ruta = '$carpetaSeleccionada${Platform.pathSeparator}$nombreArchivo';
        final archivo = File(ruta);
        await archivo.writeAsString(contenidoCsv, flush: true);
        rutaFinal = ruta;
      } catch (_) {
        usadoRutaSegura = true;
        final dirs = await getExternalStorageDirectories(
          type: StorageDirectory.downloads,
        );
        if (dirs != null && dirs.isNotEmpty) {
          final rutaSegura =
              '${dirs.first.path}${Platform.pathSeparator}$nombreArchivo';
          final archivoSeguro = File(rutaSegura);
          await archivoSeguro.writeAsString(contenidoCsv, flush: true);
          rutaFinal = rutaSegura;
        } else {
          final dirDoc = await getApplicationDocumentsDirectory();
          final rutaSegura =
              '${dirDoc.path}${Platform.pathSeparator}$nombreArchivo';
          final archivoSeguro = File(rutaSegura);
          await archivoSeguro.writeAsString(contenidoCsv, flush: true);
          rutaFinal = rutaSegura;
        }
      }

      if (contexto.mounted) {
        if (usadoRutaSegura) {
          contexto.mostrarMensajeExito(
            'Guardado por seguridad en: $rutaFinal',
          );
        } else {
          contexto.mostrarMensajeExito(
            'Historial exportado: $nombreArchivo',
          );
        }
      }
    } catch (e) {
      if (contexto.mounted) {
        contexto.mostrarMensajeError(
          'Error al exportar: ${e.toString()}',
        );
      }
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
              'Ritmo Cardíaco (Health Connect)',
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
                      final diagAsociado = diagnosticos.firstWhere(
                        (d) => d['sesion_tipo'] == sesion.tipo,
                        orElse: () => <String, Object?>{},
                      );
                      if (diagAsociado.containsKey('diagnostico_id')) {
                        context.push('/diagnostico_detalle', extra: {
                          'diagnosticoId':
                              diagAsociado['diagnostico_id'] as int,
                        });
                      } else {
                        context.mostrarMensajeError(
                            'No hay diagnóstico clínico para esta sesión');
                      }
                    },
                  )),
            const SizedBox(height: 24),
            BotonPrimario(
              texto: 'EXPORTAR HISTORIAL CSV',
              alPresionar: () => _exportarHistorial(context),
            ),
            const SizedBox(height: 8),
            const Text(
              'Se abrirá un selector de carpeta. El archivo CSV contendrá todas las sesiones y diagnósticos locales.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: TemaApp.textoSecundario),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
