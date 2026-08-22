-- ============================================================
-- I HEAR(TH) — Base de datos local SQLite
-- Ejecutar en el dispositivo móvil vía sqflite (Flutter)
-- Versión: 1.0.0
-- ============================================================

PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;


-- ─── PERFIL DEL PACIENTE ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS perfil_paciente (
    id                    INTEGER PRIMARY KEY,
    nombre_completo       TEXT    NOT NULL,
    numero_dni            TEXT    NOT NULL UNIQUE,
    correo                TEXT    NOT NULL UNIQUE,
    edad                  INTEGER,
    sexo                  TEXT,
    peso_kg               REAL,
    altura_m              REAL,
    imc                   REAL    GENERATED ALWAYS AS (
                              CASE WHEN altura_m > 0 THEN ROUND(peso_kg / (altura_m * altura_m), 2)
                              ELSE NULL END
                          ) STORED,
    ciudad                TEXT    DEFAULT 'Lima',
    pais                  TEXT    DEFAULT 'Perú',
    token_jwt             TEXT,
    token_expira_en       TEXT,
    version_modelo_local  INTEGER DEFAULT 0,
    creado_en             TEXT    DEFAULT (datetime('now')),
    actualizado_en        TEXT    DEFAULT (datetime('now'))
);


-- ─── SESIONES DE MONITOREO (PPG / IoT) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS sesiones_monitoreo (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo                  TEXT    NOT NULL,
    bpm_promedio          REAL,
    bpm_minimo            REAL,
    bpm_maximo            REAL,
    spo2_promedio         REAL,
    hrv_ms                REAL,
    ritmo_tipo            TEXT,
    calidad_senal         TEXT,
    fuente                TEXT,
    dispositivo_nombre    TEXT,
    duracion_segundos     INTEGER,
    datos_ppg_json        TEXT,
    iniciado_en           TEXT    NOT NULL DEFAULT (datetime('now')),
    finalizado_en         TEXT
);


-- ─── CUESTIONARIOS CLÍNICOS (formulario de evaluación) ───────────────────────
CREATE TABLE IF NOT EXISTS cuestionarios (
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
    frecuencia_dolor_pecho      INTEGER DEFAULT 0,
    clasificacion_dolor         INTEGER DEFAULT 0,
    tipo_dolor                  TEXT,
    esfuerzo_fisico_reciente    INTEGER NOT NULL DEFAULT 0,
    disnea                      INTEGER NOT NULL DEFAULT 0,
    creado_en                   TEXT    NOT NULL DEFAULT (datetime('now'))
);


-- ─── DIAGNÓSTICOS PREDICTIVOS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS diagnosticos (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    id_sesion_monitoreo   INTEGER REFERENCES sesiones_monitoreo(id),
    id_cuestionario       INTEGER REFERENCES cuestionarios(id),
    probabilidad_cad      REAL    NOT NULL,
    nivel_riesgo          TEXT    NOT NULL,
    etiqueta_prediccion   TEXT    NOT NULL,
    version_modelo_usada  INTEGER NOT NULL DEFAULT 0,
    umbral_aplicado       REAL    NOT NULL DEFAULT 0.5,
    inferencia_local      INTEGER NOT NULL DEFAULT 1,
    features_json         TEXT,
    creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
);


-- ─── RECOMENDACIONES GENERADAS ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS recomendaciones (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    id_diagnostico        INTEGER NOT NULL REFERENCES diagnosticos(id),
    texto                 TEXT    NOT NULL,
    icono                 TEXT,
    prioridad             INTEGER DEFAULT 1,
    creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
);


-- ─── DISPOSITIVOS IOT VINCULADOS ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dispositivos_iot (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre                TEXT    NOT NULL,
    marca                 TEXT,
    modelo                TEXT,
    mac_address           TEXT    UNIQUE,
    tipo                  TEXT,
    firmware              TEXT,
    bateria_porcentaje    INTEGER,
    ultima_sincronizacion TEXT,
    activo                INTEGER NOT NULL DEFAULT 1,
    procesamiento_local   INTEGER NOT NULL DEFAULT 1,
    creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
);


-- ─── ESTADO DEL MODELO FL LOCAL ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS estado_modelo_fl (
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
);


-- ─── ALERTAS CARDÍACAS ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS alertas (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo                  TEXT    NOT NULL,
    mensaje               TEXT    NOT NULL,
    valor_detectado       REAL,
    leida                 INTEGER NOT NULL DEFAULT 0,
    creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
);


-- ─── REGISTRO DE SINCRONIZACIONES ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS historial_sincronizacion (
    id                    INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo                  TEXT    NOT NULL,
    exitoso               INTEGER NOT NULL DEFAULT 0,
    version_antes         INTEGER,
    version_despues       INTEGER,
    detalle               TEXT,
    creado_en             TEXT    NOT NULL DEFAULT (datetime('now'))
);


-- ─── ÍNDICES ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_sesiones_tipo      ON sesiones_monitoreo(tipo);
CREATE INDEX IF NOT EXISTS idx_sesiones_fecha     ON sesiones_monitoreo(iniciado_en);
CREATE INDEX IF NOT EXISTS idx_diagnosticos_fecha ON diagnosticos(creado_en);
CREATE INDEX IF NOT EXISTS idx_diagnosticos_riesgo ON diagnosticos(nivel_riesgo);
CREATE INDEX IF NOT EXISTS idx_alertas_leida      ON alertas(leida);
CREATE INDEX IF NOT EXISTS idx_alertas_tipo       ON alertas(tipo);


-- ─── TRIGGERS: actualizado_en automático ──────────────────────────────────────
CREATE TRIGGER IF NOT EXISTS trg_perfil_actualizado
AFTER UPDATE ON perfil_paciente
BEGIN
    UPDATE perfil_paciente SET actualizado_en = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_modelo_fl_actualizado
AFTER UPDATE ON estado_modelo_fl
BEGIN
    UPDATE estado_modelo_fl SET actualizado_en = datetime('now') WHERE id = NEW.id;
END;


-- ─── REGISTRO INICIAL DEL ESTADO FL ──────────────────────────────────────────
INSERT OR IGNORE INTO estado_modelo_fl (id, version_servidor, version_local, ronda_actual)
VALUES (1, 0, 0, 0);
