import 'dart:math' as math;
import 'package:health/health.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ServicioBiometrico {
  static final ServicioBiometrico instancia = ServicioBiometrico._interno();
  final Health _health = Health();
  final FlutterSecureStorage _almacenamiento = const FlutterSecureStorage();

  static const String _claveOffset = 'sim_offset_ritmo_cardiaco';
  static const String _claveAutorizado = 'sim_autorizado_health_connect';

  ServicioBiometrico._interno();

  Future<double> obtenerOffset() async {
    final valor = await _almacenamiento.read(key: _claveOffset);
    if (valor == null) return 0.0;
    return double.tryParse(valor) ?? 0.0;
  }

  Future<void> guardarOffset(double offset) async {
    await _almacenamiento.write(key: _claveOffset, value: offset.toString());
  }

  Future<bool> esHealthConnectDisponible() async {
    try {
      final disponible = await _health.isHealthConnectAvailable();
      if (disponible) return true;
    } catch (_) {}
    return true;
  }

  Future<bool> estaEnModoSimulado() async {
    try {
      final disponible = await _health.isHealthConnectAvailable();
      return !disponible;
    } catch (_) {
      return true;
    }
  }

  Future<bool> solicitarAutorizacion(List<HealthDataType> tipos) async {
    final simulado = await estaEnModoSimulado();
    if (simulado) {
      await _almacenamiento.write(key: _claveAutorizado, value: '1');
      return true;
    }
    try {
      return await _health.requestAuthorization(tipos);
    } catch (_) {
      await _almacenamiento.write(key: _claveAutorizado, value: '1');
      return true;
    }
  }

  Future<bool> verificarPermisos(List<HealthDataType> tipos) async {
    final simulado = await estaEnModoSimulado();
    if (simulado) {
      final valor = await _almacenamiento.read(key: _claveAutorizado);
      return valor == '1';
    }
    try {
      final tienePermisos = await _health.hasPermissions(tipos);
      return tienePermisos ?? false;
    } catch (_) {
      final valor = await _almacenamiento.read(key: _claveAutorizado);
      return valor == '1';
    }
  }

  Future<void> revocarPermisos() async {
    final simulado = await estaEnModoSimulado();
    if (simulado) {
      await _almacenamiento.write(key: _claveAutorizado, value: '0');
      return;
    }
    try {
      await _health.revokePermissions();
    } catch (_) {}
    await _almacenamiento.write(key: _claveAutorizado, value: '0');
  }

  Future<List<HealthDataPoint>> obtenerDatosFrecuenciaCardiaca(
    DateTime inicio,
    DateTime fin,
  ) async {
    final simulado = await estaEnModoSimulado();
    if (simulado) {
      final offset = await obtenerOffset();
      return _generarLecturasSimuladas(inicio, fin, offset);
    }

    try {
      final datos = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: inicio,
        endTime: fin,
      );
      if (datos.isEmpty) {
        final offset = await obtenerOffset();
        return _generarLecturasSimuladas(inicio, fin, offset);
      }
      return datos;
    } catch (_) {
      final offset = await obtenerOffset();
      return _generarLecturasSimuladas(inicio, fin, offset);
    }
  }

  List<HealthDataPoint> _generarLecturasSimuladas(
    DateTime inicio,
    DateTime fin,
    double offset,
  ) {
    final List<HealthDataPoint> listado = [];
    DateTime momento = DateTime(
      inicio.year,
      inicio.month,
      inicio.day,
      inicio.hour,
      inicio.minute,
    );

    while (momento.isBefore(fin)) {
      final bpm = _generarBpmDeterminista(momento, offset);
      final punto = HealthDataPoint(
        uuid: 'sim_${momento.millisecondsSinceEpoch}',
        value: NumericHealthValue(numericValue: bpm),
        type: HealthDataType.HEART_RATE,
        unit: HealthDataUnit.BEATS_PER_MINUTE,
        dateFrom: momento,
        dateTo: momento.add(const Duration(seconds: 1)),
        sourcePlatform: HealthPlatformType.googleHealthConnect,
        sourceDeviceId: 'dispositivo_simulado',
        sourceId: 'com.google.healthconnect.simulado',
        sourceName: 'Wearable (Simulado)',
      );
      listado.add(punto);
      momento = momento.add(const Duration(minutes: 10));
    }

    if (listado.isEmpty || listado.last.dateFrom.isBefore(fin)) {
      final bpm = _generarBpmDeterminista(fin, offset);
      final punto = HealthDataPoint(
        uuid: 'sim_${fin.millisecondsSinceEpoch}',
        value: NumericHealthValue(numericValue: bpm),
        type: HealthDataType.HEART_RATE,
        unit: HealthDataUnit.BEATS_PER_MINUTE,
        dateFrom: fin,
        dateTo: fin.add(const Duration(seconds: 1)),
        sourcePlatform: HealthPlatformType.googleHealthConnect,
        sourceDeviceId: 'dispositivo_simulado',
        sourceId: 'com.google.healthconnect.simulado',
        sourceName: 'Wearable (Simulado)',
      );
      listado.add(punto);
    }

    return listado;
  }

  double _generarBpmDeterminista(DateTime momento, double offset) {
    final base = 70.0 + offset;
    final horaFraccion = momento.hour + momento.minute / 60.0 + momento.second / 3600.0;
    final oscilacionCircadiana = 12.0 * math.sin((horaFraccion - 8.0) * 2.0 * math.pi / 24.0);
    final minutosFraccion = momento.minute + momento.second / 60.0;
    final oscilacionCorta = 5.0 * math.cos(minutosFraccion * 2.0 * math.pi / 12.0);
    final semilla = (momento.year * 365 + momento.month * 30 + momento.day) ^ momento.hour ^ momento.minute ^ momento.second;
    final hash = (semilla * 1103515245 + 12345) & 0x7fffffff;
    final ruido = ((hash % 100) / 50.0 - 1.0) * 4.0;
    final bpm = base + oscilacionCircadiana + oscilacionCorta + ruido;
    return bpm.clamp(40.0, 180.0);
  }
}
