import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:iheart/modelo/preprocesamiento.dart';

class InferenciaLocal {
  static final InferenciaLocal instancia = InferenciaLocal._interna();
  Interpreter? _interprete;
  bool _inicializado = false;

  InferenciaLocal._interna();

  bool get inicializado => _inicializado;

  Future<bool> inicializar() async {
    try {
      final directorio = await getApplicationDocumentsDirectory();
      final rutaModelo = '${directorio.path}/modelo.tflite';
      if (await File(rutaModelo).exists()) {
        _interprete = await Interpreter.fromFile(File(rutaModelo));
        _inicializado = true;
        await Preprocesamiento.instancia.cargarParametrosEscalador();
        return true;
      }
    } catch (e) {
      debugPrint('Error al inicializar TFLite: $e');
      _inicializado = false;
    }
    return false;
  }

  void desactivar() {
    _interprete?.close();
    _interprete = null;
    _inicializado = false;
  }

  Future<double> ejecutarInferencia(List<double> features) async {
    if (!_inicializado || _interprete == null) {
      throw Exception('Modelo TFLite no inicializado. Es necesario calibrar.');
    }

    final featuresEscalados = Preprocesamiento.instancia.escalar(features);

    // Formato de entrada: [1, 32]
    final entrada = [featuresEscalados];
    // Formato de salida: [1, 1] (probabilidad de CAD)
    final salida = List.generate(1, (_) => List.filled(1, 0.0));

    _interprete!.run(entrada, salida);

    double probabilidad = salida[0][0];
    if (probabilidad < 0.0) probabilidad = 0.0;
    if (probabilidad > 1.0) probabilidad = 1.0;

    return probabilidad;
  }
}
