import 'package:optima_ml/datos/base_datos_local.dart';
import 'package:sqflite/sqflite.dart';

class SesionMonitoreo {
  final int? id;
  final String tipo;
  final double? bpmPromedio;
  final double? bpmMinimo;
  final double? bpmMaximo;
  final double? spo2Promedio;
  final double? hrvMs;
  final String? ritmoTipo;
  final String? calidadSenal;
  final String? fuente;
  final String? dispositivoNombre;
  final int? duracionSegundos;
  final String? datosPpgJson;
  final String iniciadoEn;
  final String? finalizadoEn;

  const SesionMonitoreo({
    this.id,
    required this.tipo,
    this.bpmPromedio,
    this.bpmMinimo,
    this.bpmMaximo,
    this.spo2Promedio,
    this.hrvMs,
    this.ritmoTipo,
    this.calidadSenal,
    this.fuente,
    this.dispositivoNombre,
    this.duracionSegundos,
    this.datosPpgJson,
    required this.iniciadoEn,
    this.finalizadoEn,
  });

  factory SesionMonitoreo.desdeMapa(Map<String, Object?> mapa) {
    return SesionMonitoreo(
      id: mapa['id'] as int?,
      tipo: mapa['tipo'] as String,
      bpmPromedio: mapa['bpm_promedio'] as double?,
      bpmMinimo: mapa['bpm_minimo'] as double?,
      bpmMaximo: mapa['bpm_maximo'] as double?,
      spo2Promedio: mapa['spo2_promedio'] as double?,
      hrvMs: mapa['hrv_ms'] as double?,
      ritmoTipo: mapa['ritmo_tipo'] as String?,
      calidadSenal: mapa['calidad_senal'] as String?,
      fuente: mapa['fuente'] as String?,
      dispositivoNombre: mapa['dispositivo_nombre'] as String?,
      duracionSegundos: mapa['duracion_segundos'] as int?,
      datosPpgJson: mapa['datos_ppg_json'] as String?,
      iniciadoEn: mapa['iniciado_en'] as String,
      finalizadoEn: mapa['finalizado_en'] as String?,
    );
  }

  Map<String, Object?> aMapa() {
    return {
      'id': id,
      'tipo': tipo,
      'bpm_promedio': bpmPromedio,
      'bpm_minimo': bpmMinimo,
      'bpm_maximo': bpmMaximo,
      'spo2_promedio': spo2Promedio,
      'hrv_ms': hrvMs,
      'ritmo_tipo': ritmoTipo,
      'calidad_senal': calidadSenal,
      'fuente': fuente,
      'dispositivo_nombre': dispositivoNombre,
      'duracion_segundos': duracionSegundos,
      'datos_ppg_json': datosPpgJson,
      'iniciado_en': iniciadoEn,
      'finalizado_en': finalizadoEn,
    };
  }
}

class RepositorioSesiones {
  final BaseDatosLocal _baseDatos = BaseDatosLocal.instancia;

  Future<int> guardarSesion(SesionMonitoreo sesion) async {
    final db = await _baseDatos.baseDatos;
    return await db.insert(
      'sesiones_monitoreo',
      sesion.aMapa(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SesionMonitoreo>> obtenerSesionesRecientes({int limite = 10}) async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query(
      'sesiones_monitoreo',
      orderBy: 'iniciado_en DESC',
      limit: limite,
    );
    return listado.map((m) => SesionMonitoreo.desdeMapa(m)).toList();
  }

  Future<SesionMonitoreo?> obtenerUltimaSesion() async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query(
      'sesiones_monitoreo',
      orderBy: 'iniciado_en DESC',
      limit: 1,
    );
    if (listado.isEmpty) return null;
    return SesionMonitoreo.desdeMapa(listado.first);
  }
}
