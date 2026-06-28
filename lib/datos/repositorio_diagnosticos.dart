import 'package:iheart/datos/base_datos_local.dart';
import 'package:sqflite/sqflite.dart';

class CuestionarioClinico {
  final int? id;
  final int? idSesionMonitoreo;
  final bool tieneDiabetes;
  final bool tieneHipertension;
  final bool tieneAccidenteCerebrovascular;
  final bool tieneInsuficienciaRenal;
  final bool tieneEnfermedadRespiratoria;
  final bool tieneEnfermedadTiroidea;
  final bool tieneInsuficienciaCardiaca;
  final bool tieneDislipidemia;
  final bool tieneObesidad;
  final bool esFumadorActivo;
  final bool esExFumador;
  final bool antecedenteFamiliarCad;
  final bool presentaEdema;
  final bool presentaDolorPecho;
  final int frecuenciaDolorPecho;
  final int clasificacionDolor;
  final String? tipoDolor;
  final bool esfuerzoFisicoReciente;
  final bool disnea;
  final String creadoEn;

  const CuestionarioClinico({
    this.id,
    this.idSesionMonitoreo,
    required this.tieneDiabetes,
    required this.tieneHipertension,
    required this.tieneAccidenteCerebrovascular,
    required this.tieneInsuficienciaRenal,
    required this.tieneEnfermedadRespiratoria,
    required this.tieneEnfermedadTiroidea,
    required this.tieneInsuficienciaCardiaca,
    required this.tieneDislipidemia,
    required this.tieneObesidad,
    required this.esFumadorActivo,
    required this.esExFumador,
    required this.antecedenteFamiliarCad,
    required this.presentaEdema,
    required this.presentaDolorPecho,
    required this.frecuenciaDolorPecho,
    required this.clasificacionDolor,
    this.tipoDolor,
    required this.esfuerzoFisicoReciente,
    required this.disnea,
    required this.creadoEn,
  });

  factory CuestionarioClinico.desdeMapa(Map<String, Object?> mapa) {
    return CuestionarioClinico(
      id: mapa['id'] as int?,
      idSesionMonitoreo: mapa['id_sesion_monitoreo'] as int?,
      tieneDiabetes: (mapa['tiene_diabetes'] as int) == 1,
      tieneHipertension: (mapa['tiene_hipertension'] as int) == 1,
      tieneAccidenteCerebrovascular: (mapa['tiene_accidente_cerebrovascular'] as int) == 1,
      tieneInsuficienciaRenal: (mapa['tiene_insuficiencia_renal'] as int) == 1,
      tieneEnfermedadRespiratoria: (mapa['tiene_enfermedad_respiratoria'] as int) == 1,
      tieneEnfermedadTiroidea: (mapa['tiene_enfermedad_tiroidea'] as int) == 1,
      tieneInsuficienciaCardiaca: (mapa['tiene_insuficiencia_cardiaca'] as int) == 1,
      tieneDislipidemia: (mapa['tiene_dislipidemia'] as int) == 1,
      tieneObesidad: (mapa['tiene_obesidad'] as int) == 1,
      esFumadorActivo: (mapa['es_fumador_activo'] as int) == 1,
      esExFumador: (mapa['es_ex_fumador'] as int) == 1,
      antecedenteFamiliarCad: (mapa['antecedente_familiar_cad'] as int) == 1,
      presentaEdema: (mapa['presenta_edema'] as int) == 1,
      presentaDolorPecho: (mapa['presenta_dolor_pecho'] as int) == 1,
      frecuenciaDolorPecho: mapa['frecuencia_dolor_pecho'] as int? ?? 0,
      clasificacionDolor: mapa['clasificacion_dolor'] as int? ?? 0,
      tipoDolor: mapa['tipo_dolor'] as String?,
      esfuerzoFisicoReciente: (mapa['esfuerzo_fisico_reciente'] as int) == 1,
      disnea: (mapa['disnea'] as int) == 1,
      creadoEn: mapa['creado_en'] as String,
    );
  }

  Map<String, Object?> aMapa() {
    return {
      'id': id,
      'id_sesion_monitoreo': idSesionMonitoreo,
      'tiene_diabetes': tieneDiabetes ? 1 : 0,
      'tiene_hipertension': tieneHipertension ? 1 : 0,
      'tiene_accidente_cerebrovascular': tieneAccidenteCerebrovascular ? 1 : 0,
      'tiene_insuficiencia_renal': tieneInsuficienciaRenal ? 1 : 0,
      'tiene_enfermedad_respiratoria': tieneEnfermedadRespiratoria ? 1 : 0,
      'tiene_enfermedad_tiroidea': tieneEnfermedadTiroidea ? 1 : 0,
      'tiene_insuficiencia_cardiaca': tieneInsuficienciaCardiaca ? 1 : 0,
      'tiene_dislipidemia': tieneDislipidemia ? 1 : 0,
      'tiene_obesidad': tieneObesidad ? 1 : 0,
      'es_fumador_activo': esFumadorActivo ? 1 : 0,
      'es_ex_fumador': esExFumador ? 1 : 0,
      'antecedente_familiar_cad': antecedenteFamiliarCad ? 1 : 0,
      'presenta_edema': presentaEdema ? 1 : 0,
      'presenta_dolor_pecho': presentaDolorPecho ? 1 : 0,
      'frecuencia_dolor_pecho': frecuenciaDolorPecho,
      'clasificacion_dolor': clasificacionDolor,
      'tipo_dolor': tipoDolor,
      'esfuerzo_fisico_reciente': esfuerzoFisicoReciente ? 1 : 0,
      'disnea': disnea ? 1 : 0,
      'creado_en': creadoEn,
    };
  }
}

class DiagnosticoClinico {
  final int? id;
  final int? idSesionMonitoreo;
  final int? idCuestionario;
  final double probabilidadCad;
  final String nivelRiesgo;
  final String etiquetaPrediccion;
  final int versionModeloUsada;
  final double umbralAplicado;
  final bool inferenciaLocal;
  final String? featuresJson;
  final String creadoEn;

  const DiagnosticoClinico({
    this.id,
    this.idSesionMonitoreo,
    this.idCuestionario,
    required this.probabilidadCad,
    required this.nivelRiesgo,
    required this.etiquetaPrediccion,
    required this.versionModeloUsada,
    required this.umbralAplicado,
    required this.inferenciaLocal,
    this.featuresJson,
    required this.creadoEn,
  });

  factory DiagnosticoClinico.desdeMapa(Map<String, Object?> mapa) {
    return DiagnosticoClinico(
      id: mapa['id'] as int?,
      idSesionMonitoreo: mapa['id_sesion_monitoreo'] as int?,
      idCuestionario: mapa['id_cuestionario'] as int?,
      probabilidadCad: mapa['probabilidad_cad'] as double,
      nivelRiesgo: mapa['nivel_riesgo'] as String,
      etiquetaPrediccion: mapa['etiqueta_prediccion'] as String,
      versionModeloUsada: mapa['version_modelo_usada'] as int,
      umbralAplicado: mapa['umbral_applied'] as double? ?? 0.5,
      inferenciaLocal: (mapa['inferencia_local'] as int? ?? 1) == 1,
      featuresJson: mapa['features_json'] as String?,
      creadoEn: mapa['creado_en'] as String,
    );
  }

  Map<String, Object?> aMapa() {
    return {
      'id': id,
      'id_sesion_monitoreo': idSesionMonitoreo,
      'id_cuestionario': idCuestionario,
      'probabilidad_cad': probabilidadCad,
      'nivel_riesgo': nivelRiesgo,
      'etiqueta_prediccion': etiquetaPrediccion,
      'version_modelo_usada': versionModeloUsada,
      'umbral_aplicado': umbralAplicado,
      'inferencia_local': inferenciaLocal ? 1 : 0,
      'features_json': featuresJson,
      'creado_en': creadoEn,
    };
  }
}

class RecomendacionClinica {
  final int? id;
  final int idDiagnostico;
  final String texto;
  final String? icono;
  final int prioridad;
  final String creadoEn;

  const RecomendacionClinica({
    this.id,
    required this.idDiagnostico,
    required this.texto,
    this.icono,
    required this.prioridad,
    required this.creadoEn,
  });

  factory RecomendacionClinica.desdeMapa(Map<String, Object?> mapa) {
    return RecomendacionClinica(
      id: mapa['id'] as int?,
      idDiagnostico: mapa['id_diagnostico'] as int,
      texto: mapa['texto'] as String,
      icono: mapa['icono'] as String?,
      prioridad: mapa['prioridad'] as int? ?? 1,
      creadoEn: mapa['creado_en'] as String,
    );
  }

  Map<String, Object?> aMapa() {
    return {
      'id': id,
      'id_diagnostico': idDiagnostico,
      'texto': texto,
      'icono': icono,
      'prioridad': prioridad,
      'creado_en': creadoEn,
    };
  }
}

class RepositorioDiagnosticos {
  final BaseDatosLocal _baseDatos = BaseDatosLocal.instancia;

  Future<int> guardarCuestionario(CuestionarioClinico cuestionario) async {
    final db = await _baseDatos.baseDatos;
    return await db.insert(
      'cuestionarios',
      cuestionario.aMapa(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> guardarDiagnostico(DiagnosticoClinico diagnostico) async {
    final db = await _baseDatos.baseDatos;
    return await db.insert(
      'diagnosticos',
      diagnostico.aMapa(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> guardarRecomendacion(RecomendacionClinica recomendacion) async {
    final db = await _baseDatos.baseDatos;
    await db.insert(
      'recomendaciones',
      recomendacion.aMapa(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DiagnosticoClinico>> obtenerDiagnosticosRecientes({int limite = 10}) async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query(
      'diagnosticos',
      orderBy: 'creado_en DESC',
      limit: limite,
    );
    return listado.map((m) => DiagnosticoClinico.desdeMapa(m)).toList();
  }

  Future<DiagnosticoClinico?> obtenerUltimoDiagnostico() async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query(
      'diagnosticos',
      orderBy: 'creado_en DESC',
      limit: 1,
    );
    if (listado.isEmpty) return null;
    return DiagnosticoClinico.desdeMapa(listado.first);
  }

  Future<CuestionarioClinico?> obtenerCuestionarioPorId(int id) async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query(
      'cuestionarios',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (listado.isEmpty) return null;
    return CuestionarioClinico.desdeMapa(listado.first);
  }

  Future<List<RecomendacionClinica>> obtenerRecomendacionesPorDiagnostico(int idDiagnostico) async {
    final db = await _baseDatos.baseDatos;
    final listado = await db.query(
      'recomendaciones',
      where: 'id_diagnostico = ?',
      whereArgs: [idDiagnostico],
      orderBy: 'prioridad DESC',
    );
    return listado.map((m) => RecomendacionClinica.desdeMapa(m)).toList();
  }

  Future<List<Map<String, Object?>>> obtenerHistorialCompleto() async {
    final db = await _baseDatos.baseDatos;
    // Realizamos una consulta combinando diagnósticos y sesiones
    return await db.rawQuery('''
      SELECT d.id AS diagnostico_id, d.probabilidad_cad, d.nivel_riesgo, d.etiqueta_prediccion, d.creado_en,
             s.bpm_promedio, s.spo2_promedio, s.hrv_ms, s.tipo AS sesion_tipo
      FROM diagnosticos d
      LEFT JOIN sesiones_monitoreo s ON d.id_sesion_monitoreo = s.id
      ORDER BY d.creado_en DESC
    ''');
  }
}
