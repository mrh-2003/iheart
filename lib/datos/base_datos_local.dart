import 'dart:io';
import 'package:sqflite/sqflite.dart';

class BaseDatosLocal {
  static final BaseDatosLocal instancia = BaseDatosLocal._interna();
  static Database? _baseDatos;

  BaseDatosLocal._interna();

  Future<Database> get baseDatos async {
    if (_baseDatos != null) return _baseDatos!;
    _baseDatos = await _inicializarBD();
    return _baseDatos!;
  }

  Future<Database> _inicializarBD() async {
    final rutaDirectorio = await getDatabasesPath();
    try {
      await Directory(rutaDirectorio).create(recursive: true);
    } catch (_) {}
    final ruta = '$rutaDirectorio/ihearth_local.db';

    return await openDatabase(
      ruta,
      version: 1,
      onCreate: _crearBD,
      onConfigure: _configurarBD,
    );
  }

  Future<void> _configurarBD(Database db) async {
    await db.rawQuery('PRAGMA journal_mode = WAL;');
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _crearBD(Database db, int version) async {
    await db.execute('''
      CREATE TABLE perfil_paciente (
        id                    INTEGER PRIMARY KEY,
        nombre_completo       TEXT    NOT NULL,
        numero_dni            TEXT    NOT NULL UNIQUE,
        correo                TEXT    NOT NULL UNIQUE,
        edad                  INTEGER,
        sexo                  TEXT    CHECK(sexo IN ('Masculino', 'Femenino')),
        peso_kg               REAL,
        altura_m              REAL,
        imc                   REAL,
        ciudad                TEXT    DEFAULT 'Lima',
        pais                  TEXT    DEFAULT 'Perú',
        token_jwt             TEXT,
        token_expira_en       TEXT,
        version_modelo_local  INTEGER DEFAULT 0,
        creado_en             TEXT    DEFAULT (datetime('now')),
        actualizado_en        TEXT    DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE sesiones_monitoreo (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo                  TEXT    NOT NULL CHECK(tipo IN (
                                'reposo', 'actividad', 'nocturno', 'post_actividad', 'manual'
                              )),
        bpm_promedio          REAL,
        bpm_minimo            REAL,
        bpm_maximo            REAL,
        spo2_promedio         REAL,
        hrv_ms                REAL,
        ritmo_tipo            TEXT    CHECK(ritmo_tipo IN ('regular', 'irregular', 'variable')),
        calidad_senal         TEXT    CHECK(calidad_senal IN ('alta', 'media', 'baja')),
        fuente                TEXT    CHECK(fuente IN ('smartwatch', 'camara', 'manual')),
        dispositivo_nombre    TEXT,
        duracion_segundos     INTEGER,
        datos_ppg_json        TEXT,
        iniciado_en           TEXT    NOT NULL DEFAULT (datetime('now')),
        finalizado_en         TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cuestionarios (
        id                          INTEGER PRIMARY KEY AUTOINCREMENT,
        id_sesion_monitoreo         INTEGER REFERENCES sesiones_monitoreo(id),
        tiene_diabetes              INTEGER NOT NULL DEFAULT 0,
        tiene_hipertension          INTEGER NOT NULL DEFAULT 0,
        tiene_accidente_cerebrovascular INTEGER NOT NULL DEFAULT 0,
        tiene_insuficiencia_renal   INTEGER NOT NULL DEFAULT 0,
        tiene_enfermedad_respiratoria INTEGER NOT NULL DEFAULT 0,
        tiene_enfermedad_tiroidea   INTEGER NOT NULL DEFAULT 0,
        tiene_insuficiencia_cardiaca INTEGER NOT NULL DEFAULT 0,
        tiene_dislipidemia          INTEGER NOT NULL DEFAULT 0,
        tiene_obesidad              INTEGER NOT NULL DEFAULT 0,
        es_fumador_activo           INTEGER NOT NULL DEFAULT 0,
        es_ex_fumador               INTEGER NOT NULL DEFAULT 0,
        antecedente_familiar_cad    INTEGER NOT NULL DEFAULT 0,
        presenta_edema              INTEGER NOT NULL DEFAULT 0,
        presenta_dolor_pecho        INTEGER NOT NULL DEFAULT 0,
        frecuencia_dolor_pecho      INTEGER DEFAULT 0 CHECK(frecuencia_dolor_pecho BETWEEN 0 AND 5),
        clasificacion_dolor         INTEGER DEFAULT 0 CHECK(clasificacion_dolor BETWEEN 0 AND 5),
        tipo_dolor                  TEXT    CHECK(tipo_dolor IN ('tipico', 'atipico', 'no_anginoso', NULL)),
        esfuerzo_fisico_reciente    INTEGER NOT NULL DEFAULT 0,
        disnea                      INTEGER NOT NULL DEFAULT 0,
        creado_en                   TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE diagnosticos (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        id_sesion_monitoreo   INTEGER REFERENCES sesiones_monitoreo(id),
        id_cuestionario       INTEGER REFERENCES cuestionarios(id),
        probabilidad_cad      REAL    NOT NULL,
        nivel_riesgo          TEXT    NOT NULL CHECK(nivel_riesgo IN ('bajo', 'moderado', 'alto', 'critico')),
        etiqueta_prediccion   TEXT    NOT NULL CHECK(etiqueta_prediccion IN ('Normal', 'CAD')),
        version_modelo_usada  INTEGER NOT NULL DEFAULT 0,
        umbral_aplicado       REAL    NOT NULL DEFAULT 0.5,
        inferencia_local      INTEGER NOT NULL DEFAULT 1,
        features_json         TEXT,
        creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE recomendaciones (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        id_diagnostico        INTEGER NOT NULL REFERENCES diagnosticos(id),
        texto                 TEXT    NOT NULL,
        icono                 TEXT,
        prioridad             INTEGER DEFAULT 1,
        creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE dispositivos_iot (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre                TEXT    NOT NULL,
        marca                 TEXT,
        modelo                TEXT,
        mac_address           TEXT    UNIQUE,
        tipo                  TEXT    CHECK(tipo IN ('smartwatch', 'smartband', 'oximetro', 'otro')),
        firmware              TEXT,
        bateria_porcentaje    INTEGER,
        ultima_sincronizacion TEXT,
        activo                INTEGER NOT NULL DEFAULT 1,
        procesamiento_local   INTEGER NOT NULL DEFAULT 1,
        creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE estado_modelo_fl (
        id                    INTEGER PRIMARY KEY,
        version_servidor      INTEGER NOT NULL DEFAULT 0,
        version_local         INTEGER NOT NULL DEFAULT 0,
        ruta_modelo_tflite    TEXT,
        ronda_actual          INTEGER NOT NULL DEFAULT 0,
        ultima_sincronizacion TEXT,
        pesos_pendientes      INTEGER NOT NULL DEFAULT 0,
        entrenamiento_local_completado INTEGER NOT NULL DEFAULT 0,
        accuracy_local        REAL,
        actualizado_en        TEXT    DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE alertas (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo                  TEXT    NOT NULL CHECK(tipo IN (
                                'bpm_alto', 'bpm_bajo', 'spo2_bajo', 'hrv_anormal',
                                'riesgo_alto', 'riesgo_critico', 'calibracion_requerida'
                              )),
        mensaje               TEXT    NOT NULL,
        valor_detectado       REAL,
        leida                 INTEGER NOT NULL DEFAULT 0,
        creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE historial_sincronizacion (
        id                    INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo                  TEXT    NOT NULL CHECK(tipo IN ('descarga_modelo', 'subida_pesos', 'version_check')),
        exitoso               INTEGER NOT NULL DEFAULT 0,
        version_antes         INTEGER,
        version_despues       INTEGER,
        detalle               TEXT,
        creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('CREATE INDEX idx_sesiones_tipo ON sesiones_monitoreo(tipo);');
    await db.execute('CREATE INDEX idx_sesiones_fecha ON sesiones_monitoreo(iniciado_en);');
    await db.execute('CREATE INDEX idx_diagnosticos_fecha ON diagnosticos(creado_en);');
    await db.execute('CREATE INDEX idx_diagnosticos_riesgo ON diagnosticos(nivel_riesgo);');
    await db.execute('CREATE INDEX idx_alertas_leida ON alertas(leida);');
    await db.execute('CREATE INDEX idx_alertas_tipo ON alertas(tipo);');

    await db.execute('''
      INSERT INTO estado_modelo_fl (id, version_servidor, version_local, ronda_actual)
      VALUES (1, 0, 0, 0);
    ''');
  }
}
