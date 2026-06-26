import 'dart:convert';
import 'dart:typed_data';
import 'package:optima_ml/red/cliente_api.dart';

class ServicioModelo {
  final ClienteApi _cliente = ClienteApi.instancia;

  Future<int> obtenerVersionModelo() async {
    final respuesta = await _cliente.get('/model/version');
    final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
    return mapa['version'] as int? ?? 0;
  }

  Future<Uint8List> descargarModeloTflite() async {
    final respuesta = await _cliente.get('/model/latest?formato=tflite');
    return respuesta.bodyBytes;
  }
}
