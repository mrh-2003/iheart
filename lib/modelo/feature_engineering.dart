import 'package:iheart/datos/repositorio_perfil.dart';
import 'package:iheart/datos/repositorio_diagnosticos.dart';

class FeatureEngineering {
  static List<double> generarFeatures({
    required PerfilPaciente perfil,
    required CuestionarioClinico cuestionario,
    required double ritmoCardiaco,
  }) {
    final double edadVal = (perfil.edad ?? 58).toDouble();
    final double pesoVal = perfil.pesoKg ?? 74.0;
    final double alturaCm = perfil.alturaM != null
        ? (perfil.alturaM! < 3.0 ? perfil.alturaM! * 100.0 : perfil.alturaM!)
        : 165.0;
    final double imcVal = perfil.imc ?? (pesoVal / ((alturaCm / 100.0) * (alturaCm / 100.0)));
    final double sexoVal = perfil.sexo == 'Masculino' ? 1.0 : 0.0;

    final double grupoEdad = _calcularGrupoEdad(edadVal);
    final double categoriaImc = _calcularCategoriaImc(imcVal);

    final double puntajeRiesgo = (cuestionario.tieneDiabetes ? 1.0 : 0.0) +
        (cuestionario.tieneHipertension ? 1.0 : 0.0) +
        (cuestionario.esFumadorActivo ? 1.0 : 0.0) +
        (cuestionario.esExFumador ? 1.0 : 0.0) +
        (cuestionario.antecedenteFamiliarCad ? 1.0 : 0.0) +
        (cuestionario.tieneObesidad ? 1.0 : 0.0) +
        (cuestionario.tieneDislipidemia ? 1.0 : 0.0);

    final double conteoComorbilidades = (cuestionario.tieneInsuficienciaRenal ? 1.0 : 0.0) +
        (cuestionario.tieneAccidenteCerebrovascular ? 1.0 : 0.0) +
        (cuestionario.tieneEnfermedadRespiratoria ? 1.0 : 0.0) +
        (cuestionario.tieneEnfermedadTiroidea ? 1.0 : 0.0) +
        (cuestionario.tieneInsuficienciaCardiaca ? 1.0 : 0.0) +
        (cuestionario.presentaEdema ? 1.0 : 0.0);

    final double indiceSintomas = ((cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'tipico') ? 1.0 : 0.0) +
        (cuestionario.disnea ? 1.0 : 0.0) +
        ((cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'atipico') ? 1.0 : 0.0) +
        ((cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'no_anginoso') ? 1.0 : 0.0);

    final double interaccionHtnDm = (cuestionario.tieneHipertension && cuestionario.tieneDiabetes) ? 1.0 : 0.0;
    final double relacionPresionEdad = double.parse((130.0 / edadVal).toStringAsFixed(3));
    final double altoRiesgo = puntajeRiesgo >= 3.0 ? 1.0 : 0.0;

    return [
      edadVal,
      pesoVal,
      alturaCm,
      sexoVal,
      imcVal,
      cuestionario.tieneDiabetes ? 1.0 : 0.0,
      cuestionario.tieneHipertension ? 1.0 : 0.0,
      cuestionario.esFumadorActivo ? 1.0 : 0.0,
      cuestionario.esExFumador ? 1.0 : 0.0,
      cuestionario.antecedenteFamiliarCad ? 1.0 : 0.0,
      cuestionario.tieneObesidad ? 1.0 : 0.0,
      cuestionario.tieneInsuficienciaRenal ? 1.0 : 0.0,
      cuestionario.tieneAccidenteCerebrovascular ? 1.0 : 0.0,
      cuestionario.tieneEnfermedadRespiratoria ? 1.0 : 0.0,
      cuestionario.tieneEnfermedadTiroidea ? 1.0 : 0.0,
      cuestionario.tieneInsuficienciaCardiaca ? 1.0 : 0.0,
      cuestionario.tieneDislipidemia ? 1.0 : 0.0,
      130.0,
      ritmoCardiaco,
      cuestionario.presentaEdema ? 1.0 : 0.0,
      cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'tipico' ? 1.0 : 0.0,
      cuestionario.disnea ? 1.0 : 0.0,
      cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'atipico' ? 1.0 : 0.0,
      cuestionario.presentaDolorPecho && cuestionario.tipoDolor == 'no_anginoso' ? 1.0 : 0.0,
      grupoEdad,
      categoriaImc,
      puntajeRiesgo,
      conteoComorbilidades,
      indiceSintomas,
      interaccionHtnDm,
      relacionPresionEdad,
      altoRiesgo,
    ];
  }

  static double _calcularGrupoEdad(double edadVal) {
    if (edadVal <= 40.0) {
      return 0.0;
    } else if (edadVal <= 50.0) {
      return 1.0;
    } else if (edadVal <= 60.0) {
      return 2.0;
    } else if (edadVal <= 70.0) {
      return 3.0;
    } else {
      return 4.0;
    }
  }

  static double _calcularCategoriaImc(double imcVal) {
    if (imcVal <= 18.5) {
      return 0.0;
    } else if (imcVal <= 25.0) {
      return 1.0;
    } else if (imcVal <= 30.0) {
      return 2.0;
    } else if (imcVal <= 35.0) {
      return 3.0;
    } else {
      return 4.0;
    }
  }
}
