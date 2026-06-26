import 'package:optima_ml/datos/repositorio_perfil.dart';
import 'package:optima_ml/datos/repositorio_diagnosticos.dart';

class FeatureEngineering {
  static List<double> generarFeatures({
    required PerfilPaciente perfil,
    required CuestionarioClinico cuestionario,
    required double ritmoCardiaco,
  }) {
    final double edad = (perfil.edad ?? 45).toDouble();
    final double peso = perfil.pesoKg ?? 70.0;
    final double altura = perfil.alturaM ?? 1.70;
    final double imc = perfil.imc ?? (peso / (altura * altura));
    final double sexo = perfil.sexo == 'Masculino' ? 1.0 : 0.0;

    // 1. imc_categoria (1: Bajo peso, 2: Normal, 3: Sobrepeso, 4: Obesidad)
    double imcCategoria = 2.0;
    if (imc < 18.5) {
      imcCategoria = 1.0;
    } else if (imc >= 18.5 && imc < 25.0) {
      imcCategoria = 2.0;
    } else if (imc >= 25.0 && imc < 30.0) {
      imcCategoria = 3.0;
    } else {
      imcCategoria = 4.0;
    }

    // 2. grupo_edad (1: <30, 2: 30-45, 3: 46-60, 4: >60)
    double grupoEdad = 2.0;
    if (edad < 30) {
      grupoEdad = 1.0;
    } else if (edad >= 30 && edad <= 45) {
      grupoEdad = 2.0;
    } else if (edad > 45 && edad <= 60) {
      grupoEdad = 3.0;
    } else {
      grupoEdad = 4.0;
    }

    // 3. puntaje_riesgo_clinico (Suma de comorbilidades clínicas)
    double puntajeRiesgoClinico = 0.0;
    if (cuestionario.tieneDiabetes) puntajeRiesgoClinico += 1.0;
    if (cuestionario.tieneHipertension) puntajeRiesgoClinico += 1.0;
    if (cuestionario.tieneAccidenteCerebrovascular) puntajeRiesgoClinico += 1.0;
    if (cuestionario.tieneInsuficienciaRenal) puntajeRiesgoClinico += 1.0;
    if (cuestionario.tieneInsuficienciaCardiaca) puntajeRiesgoClinico += 1.0;
    if (cuestionario.tieneDislipidemia) puntajeRiesgoClinico += 1.0;

    // 4. estado_tabaco (0: No fuma, 1: Ex-fumador, 2: Fumador activo)
    double estadoTabaco = 0.0;
    if (cuestionario.esFumadorActivo) {
      estadoTabaco = 2.0;
    } else if (cuestionario.esExFumador) {
      estadoTabaco = 1.0;
    }

    // 5. intensidad_dolor_pecho (combinación de dolor y frecuencia)
    double intensidadDolor = cuestionario.presentaDolorPecho 
        ? cuestionario.frecuenciaDolorPecho.toDouble() 
        : 0.0;

    // 6. frecuencia_maxima_estimada (220 - edad)
    final double frecuenciaMaximaEstimada = 220.0 - edad;

    // 7. reserva_frecuencia_cardiaca (frecuencia_maxima - actual)
    final double reservaFrecuencia = frecuenciaMaximaEstimada - ritmoCardiaco;

    // 8. indice_riesgo_general
    double indiceRiesgoGeneral = puntajeRiesgoClinico;
    if (cuestionario.tieneObesidad) indiceRiesgoGeneral += 1.0;
    if (cuestionario.antecedenteFamiliarCad) indiceRiesgoGeneral += 1.5;
    if (cuestionario.esFumadorActivo) indiceRiesgoGeneral += 1.0;
    if (edad > 55) indiceRiesgoGeneral += 1.0;

    // Features base del modelo (19 features)
    // PR (bpm), Obesity, Current Smoker, EX-Smoker, FH, DM, HTN, CVA, CRF, 
    // Airway disease, Thyroid Disease, CHF, DLP, Edema, Typical Chest Pain, 
    // Atypical, Nonanginal, Dyspnea, Exertional CP
    final List<double> featuresBase = [
      ritmoCardiaco,
      cuestionario.tieneObesidad ? 1.0 : 0.0,
      cuestionario.esFumadorActivo ? 1.0 : 0.0,
      cuestionario.esExFumador ? 1.0 : 0.0,
      cuestionario.antecedenteFamiliarCad ? 1.0 : 0.0,
      cuestionario.tieneDiabetes ? 1.0 : 0.0,
      cuestionario.tieneHipertension ? 1.0 : 0.0,
      cuestionario.tieneAccidenteCerebrovascular ? 1.0 : 0.0,
      cuestionario.tieneInsuficienciaRenal ? 1.0 : 0.0,
      cuestionario.tieneEnfermedadRespiratoria ? 1.0 : 0.0,
      cuestionario.tieneEnfermedadTiroidea ? 1.0 : 0.0,
      cuestionario.tieneInsuficienciaCardiaca ? 1.0 : 0.0,
      cuestionario.tieneDislipidemia ? 1.0 : 0.0,
      cuestionario.presentaEdema ? 1.0 : 0.0,
      cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'tipico' ? 1.0 : 0.0,
      cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'atipico' ? 1.0 : 0.0,
      cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'no_anginoso' ? 1.0 : 0.0,
      cuestionario.disnea ? 1.0 : 0.0,
      cuestionario.esfuerzoFisicoReciente ? 1.0 : 0.0,
    ];

    // Variables de perfil (5 features)
    final List<double> featuresPerfil = [
      edad,
      peso,
      altura,
      sexo,
      imc,
    ];

    // Variables derivadas (8 features)
    final List<double> featuresDerivadas = [
      imcCategoria,
      grupoEdad,
      puntajeRiesgoClinico,
      estadoTabaco,
      intensidadDolor,
      frecuenciaMaximaEstimada,
      reservaFrecuencia,
      indiceRiesgoGeneral,
    ];

    return [...featuresBase, ...featuresPerfil, ...featuresDerivadas];
  }
}
