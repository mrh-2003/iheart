import 'package:iheart/datos/base_datos_local.dart';

class EstadoModeloFl {
  final int id;
  final int versionServidor;
  final int versionLocal;
  final String? rutaModeloTflite;
  final int rondaActual;
  final String? ultimaSincronizacion;
  final bool pesosPendientes;
  final bool entrenamientoLocalCompletado;
  final double? accuracyLocal;
  final String actualizadoEn;

  const EstadoModeloFl({
    required this.id,
    required this.versionServidor,
    required this.versionLocal,
    this.rutaModeloTflite,
    required this.rondaActual,
    this.ultimaSincronizacion,
    required this.pesosPendientes,
    required this.entrenamientoLocalCompletado,
    this.accuracyLocal,
    required this.actualizadoEn,
  });

  factory EstadoModeloFl.desdeMapa(Map<String, Object?> mapa) {
    return EstadoModeloFl(
      id: mapa['id'] as int,
      versionServidor: mapa['version_servidor'] as int,
      versionLocal: mapa['version_local'] as int,
      rutaModeloTflite: mapa['ruta_modelo_tflite'] as String?,
      rondaActual: mapa['ronda_actual'] as int,
      ultimaSincronizacion: mapa['ultima_sincronizacion'] as String?,
      pesosPendientes: (mapa['pesos_pendientes'] as int) == 1,
      entrenamientoLocalCompletado: (mapa['entrenamiento_local_completado'] as int) == 1,
      accuracyLocal: mapa['accuracy_local'] as double?,
      actualizadoEn: mapa['actualizado_en'] as String,
    );
  }

  Map<String, Object?> aMapa() {
    return {
      'id': id,
      'version_servidor': versionServidor,
      'version_local': versionLocal,
      'ruta_modelo_tflite': rutaModeloTflite,
      'ronda_actual': rondaActual,
      'ultima_sincronizacion': ultimaSincronizacion,
      'pesos_pendientes': pesosPendientes ? 1 : 0,
      'entrenamiento_local_completado': entrenamientoLocalCompletado ? 1 : 0,
      'accuracy_local': accuracyLocal,
      'actualizado_en': actualizadoEn,
    };
  }
}

class AlertaCardiaca {
  final int? id;
  final String tipo;
  final String mensaje;
  final double? valorDetectado;
  final bool leida;
  final String creadoEn;

  const AlertaCardiaca({
    this.id,
    required this.tipo,
    required this.mensaje,
    this.valorDetectado,
    required this.leida,
    required this.creadoEn,
  });

  factory AlertaCardiaca.desdeMapa(Map<String, Object?> mapa) {
    return AlertaCardiaca(
      id: mapa['id'] as int?,
      tipo: mapa['tipo'] as String,
      mensaje: mapa['mensaje'] as String,
      valorDetectado: mapa['valor_detectado'] as double?,
      leida: (mapa['leida'] as int) == 1,
      creadoEn: mapa['creado_en'] as String,
    );
  }

  Map<String, Object?> aMapa() {
    return {
      'id': id,
      'tipo': tipo,
      'mensaje': mensaje,
      'valor_detectado': valorDetectado,
      'leida': leida ? 1 : 0,
      'creado_en': creadoEn,
    };
  }
}

class RepositorioModelo {
  final BaseDatosLocal _baseDatos = BaseDatosLocal.instancia;

  Future<EstadoModeloFl> obtenerEstadoFL() async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query('estado_modelo_fl', where: 'id = 1');
    if (listado.isEmpty) {
      return EstadoModeloFl(
        id: 1,
        versionServidor: 0,
        versionLocal: 0,
        rondaActual: 0,
        pesosPendientes: false,
        entrenamientoLocalCompletado: false,
        actualizadoEn: DateTime.now().toIso8601String(),
      );
    }
    return EstadoModeloFl.desdeMapa(listado.first);
  }

  Future<void> actualizarEstadoFL(EstadoModeloFl estado) async {
    final db = await _baseDatos.baseDatos;
    await db.update(
      'estado_modelo_fl',
      estado.aMapa(),
      where: 'id = 1',
    );
  }

  Future<void> registrarSincronizacion({
    required String tipo,
    required bool exitoso,
    int? versionAntes,
    int? versionDespues,
    required String detalle,
  }) async {
    final db = await _baseDatos.baseDatos;
    await db.insert('historial_sincronizacion', {
      'tipo': tipo,
      'exitoso': exitoso ? 1 : 0,
      'version_antes': versionAntes,
      'version_despues': versionDespues,
      'detalle': detalle,
      'creado_en': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> obtenerHistorialSincronizacion() async {
    final db = await _baseDatos.baseDatos;
    return await db.query('historial_sincronizacion', orderBy: 'creado_en DESC');
  }

  Future<void> guardarAlerta(AlertaCardiaca alerta) async {
    final db = await _baseDatos.baseDatos;
    await db.insert('alertas', alerta.aMapa());
  }

  Future<List<AlertaCardiaca>> obtenerAlertasNoLeidas() async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query(
      'alertas',
      where: 'leida = 0',
      orderBy: 'creado_en DESC',
    );
    return listado.map((m) => AlertaCardiaca.desdeMapa(m)).toList();
  }

  Future<void> marcarAlertaComoLeida(int id) async {
    final db = await _baseDatos.baseDatos;
    await db.update(
      'alertas',
      {'leida': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
