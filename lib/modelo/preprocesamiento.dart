import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Preprocesamiento {
  static final Preprocesamiento instancia = Preprocesamiento._interna();
  List<double> _medias = [];
  List<double> _desviaciones = [];

  Preprocesamiento._interna() {
    _inicializarValoresPorDefecto();
  }

  void _inicializarValoresPorDefecto() {
    // Generar valores por defecto para las 32 variables
    _medias = List.filled(32, 0.0);
    _desviaciones = List.filled(32, 1.0);

    // Ajustes realistas por defecto
    _medias[0] = 75.0; // PR (bpm)
    _desviaciones[0] = 15.0;

    _medias[19] = 50.0; // Age
    _desviaciones[19] = 15.0;

    _medias[20] = 70.0; // Weight
    _desviaciones[20] = 15.0;

    _medias[21] = 1.65; // Length
    _desviaciones[21] = 0.1;

    _medias[23] = 25.0; // BMI
    _desviaciones[23] = 5.0;
  }

  Future<void> cargarParametrosEscalador() async {
    try {
      final directorio = await getApplicationDocumentsDirectory();
      final archivo = File('${directorio.path}/scaler.json');
      if (await archivo.exists()) {
        final contenido = await archivo.readAsString();
        final datos = jsonDecode(contenido) as Map<String, dynamic>;
        final mediasCargadas = List<double>.from(datos['mean'] as List);
        final desvCargadas = List<double>.from(datos['std'] as List);
        if (mediasCargadas.length == 32 && desvCargadas.length == 32) {
          _medias = mediasCargadas;
          _desviaciones = desvCargadas;
        }
      }
    } catch (_) {}
  }

  List<double> escalar(List<double> features) {
    if (features.length != 32) {
      return features;
    }
    final List<double> featuresEscaladas = [];
    for (int i = 0; i < 32; i++) {
      final media = _medias[i];
      final std = _desviaciones[i] == 0 ? 1.0 : _desviaciones[i];
      featuresEscaladas.add((features[i] - media) / std);
    }
    return featuresEscaladas;
  }
}
