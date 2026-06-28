import 'dart:convert';
import 'dart:typed_data';
import 'package:iheart/red/cliente_api.dart';

class ServicioModelo {
  final ClienteApi _cliente = ClienteApi.instancia;

  Future<int> obtenerVersionModelo() async {
    final respuesta = await _cliente.get('/model/version');
    final decodificado = jsonDecode(respuesta.body);
    final mapa = decodificado is Map<String, dynamic> ? decodificado : <String, dynamic>{};
    final versionVal = mapa['version'];
    return versionVal is int ? versionVal : 0;
  }

  Future<Uint8List> descargarModeloTflite() async {
    final respuesta = await _cliente.get('/model/latest?formato=tflite');
    return respuesta.bodyBytes;
  }
}
