import 'dart:convert';
import 'dart:typed_data';
import 'package:iheart/red/cliente_api.dart';

class ServicioFederado {
  final ClienteApi _cliente = ClienteApi.instancia;

  Future<void> subirPesosFL({
    required int idCliente,
    required int ronda,
    required int numeroMuestras,
    required List<double> pesos,
  }) async {
    await _cliente.post(
      '/federated/upload',
      cuerpo: {
        'id_cliente': idCliente.toString(),
        'ronda': ronda,
        'numero_muestras': numeroMuestras,
        'pesos': pesos,
      },
    );
  }

  Future<Map<String, dynamic>> obtenerEstadoAgregacion() async {
    final respuesta = await _cliente.get('/federated/status');
    return jsonDecode(respuesta.body) as Map<String, dynamic>;
  }

  Future<Uint8List> descargarModeloPostFL() async {
    final respuesta = await _cliente.get('/federated/model');
    return respuesta.bodyBytes;
  }
}
