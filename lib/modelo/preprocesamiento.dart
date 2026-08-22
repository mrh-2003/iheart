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
    _medias = const [
      58.549586776859506,
      74.53719008264463,
      164.88842975206612,
      0.5785123966942148,
      27.417379253166768,
      0.3181818181818182,
      0.5743801652892562,
      0.1859504132231405,
      0.0371900826446281,
      0.1652892561983471,
      0.7107438016528925,
      0.02066115702479339,
      0.02066115702479339,
      0.028925619834710745,
      0.028925619834710745,
      0.004132231404958678,
      0.3677685950413223,
      129.39256198347107,
      74.95454545454545,
      0.0371900826446281,
      0.5413223140495868,
      0.4297520661157025,
      0.30991735537190085,
      0.045454545454545456,
      2.2644628099173554,
      2.0,
      2.3595041322314048,
      0.14049586776859505,
      1.3264462809917354,
      0.23553719008264462,
      2.2724256072162596,
      0.45867768595041325
    ];
    _desviaciones = const [
      10.296012418896602,
      12.360321295079165,
      9.10861630121454,
      0.4937973304558554,
      4.031338497737248,
      0.4657704893618,
      0.49443664003747084,
      0.389066648590295,
      0.18922732465876582,
      0.3714414058552768,
      0.4534170817965353,
      0.14224722709139265,
      0.14224722709139262,
      0.16759751893118444,
      0.16759751893118455,
      0.06414948221595089,
      0.48219794228372037,
      18.253235489439522,
      8.935142800174152,
      0.18922732465876574,
      0.4982895406905382,
      0.4950406324585761,
      0.4624592827603177,
      0.20829889522526585,
      1.0346764179873877,
      0.8381404052084444,
      1.1422088584970806,
      0.3591952696214991,
      0.5029283824343865,
      0.4243340926329362,
      0.4932155462306114,
      0.49828954069053844
    ];
  }

  Future<void> cargarParametrosEscalador() async {
    try {
      final directorio = await getApplicationDocumentsDirectory();
      final archivo = File('${directorio.path}/scaler.json');
      if (await archivo.exists()) {
        final contenido = await archivo.readAsString();
        final decodificado = jsonDecode(contenido);
        final datos = decodificado is Map<String, dynamic> ? decodificado : <String, dynamic>{};
        final meanVal = datos['mean'];
        final stdVal = datos['std'];
        final mediasCargadas = List<double>.from(meanVal is List ? meanVal : []);
        final desvCargadas = List<double>.from(stdVal is List ? stdVal : []);
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
      final std = _desviaciones[i] == 0.0 ? 1.0 : _desviaciones[i];
      featuresEscaladas.add((features[i] - media) / std);
    }
    return featuresEscaladas;
  }
}
