import 'package:health/health.dart';

class ServicioBiometrico {
  static final ServicioBiometrico instancia = ServicioBiometrico._interno();
  final Health _health = Health();

  ServicioBiometrico._interno();

  Future<bool> esHealthConnectDisponible() async {
    try {
      final disponible = await _health.isHealthConnectAvailable();
      return disponible ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> solicitarAutorizacion(
    List<HealthDataType> tipos, {
    List<HealthDataAccess>? permisos,
  }) async {
    try {
      final listaPermisos = permisos ??
          tipos
              .map((t) => t == HealthDataType.HEART_RATE
                  ? HealthDataAccess.READ_WRITE
                  : HealthDataAccess.READ)
              .toList();
      final autorizacion = await _health.requestAuthorization(tipos, permissions: listaPermisos);
      return autorizacion;
    } catch (_) {
      return false;
    }
  }

  Future<bool> verificarPermisos(
    List<HealthDataType> tipos, {
    List<HealthDataAccess>? permisos,
  }) async {
    try {
      final listaPermisos = permisos ??
          tipos.map((t) => HealthDataAccess.READ).toList();
      final tienePermisos = await _health.hasPermissions(tipos, permissions: listaPermisos);
      return tienePermisos ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> revocarPermisos() async {
    try {
      await _health.revokePermissions();
    } catch (_) {}
  }

  Future<List<HealthDataPoint>> obtenerDatosFrecuenciaCardiaca(
    DateTime inicio,
    DateTime fin,
  ) async {
    try {
      final datos = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: inicio,
        endTime: fin,
      );
      return datos;
    } catch (_) {
      return [];
    }
  }

  Future<List<HealthDataPoint>> obtenerDatosPorTipo(
    HealthDataType tipo,
    DateTime inicio,
    DateTime fin,
  ) async {
    try {
      final datos = await _health.getHealthDataFromTypes(
        types: [tipo],
        startTime: inicio,
        endTime: fin,
      );
      return datos;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> escribirFrecuenciaCardiacaPrueba(double bpm, DateTime momento) async {
    try {
      final exito = await _health.writeHealthData(
        value: bpm,
        type: HealthDataType.HEART_RATE,
        startTime: momento,
        endTime: momento.add(const Duration(seconds: 1)),
      );
      return exito;
    } catch (_) {
      return false;
    }
  }
}
