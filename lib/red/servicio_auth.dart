import 'dart:convert';
import 'package:optima_ml/red/cliente_api.dart';

class ResultAuth {
  final String token;
  final String expiraEn;
  final int usuarioId;
  final String nombreCompleto;
  final String numeroDni;
  final String correo;

  const ResultAuth({
    required this.token,
    required this.expiraEn,
    required this.usuarioId,
    required this.nombreCompleto,
    required this.numeroDni,
    required this.correo,
  });

  factory ResultAuth.desdeMapa(Map<String, dynamic> mapa) {
    return ResultAuth(
      token: mapa['access_token'] as String,
      expiraEn: mapa['expira_en'] as String? ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      usuarioId: mapa['usuario_id'] as int? ?? 1,
      nombreCompleto: mapa['nombre_completo'] as String? ?? '',
      numeroDni: mapa['numero_dni'] as String? ?? '',
      correo: mapa['correo'] as String? ?? '',
    );
  }
}

class ServicioAuth {
  final ClienteApi _cliente = ClienteApi.instancia;

  Future<ResultAuth> iniciarSesion(String correo, String contrasena) async {
    final respuesta = await _cliente.post(
      '/auth/login',
      cuerpo: {
        'correo': correo,
        'contrasena': contrasena,
      },
      requiereAuth: false,
    );

    final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
    return ResultAuth.desdeMapa(mapa);
  }

  Future<void> registrarUsuario({
    required String nombreCompleto,
    required String numeroDni,
    required String correo,
    required String contrasena,
  }) async {
    await _cliente.post(
      '/auth/register',
      cuerpo: {
        'nombre_completo': nombreCompleto,
        'numero_dni': numeroDni,
        'correo': correo,
        'contrasena': contrasena,
      },
      requiereAuth: false,
    );
  }
}
