import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:iheart/red/servicio_biometrico.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canalSalud = MethodChannel('flutter_health');
  const canalDispositivo = MethodChannel(
    'dev.fluttercommunity.plus/device_info',
  );
  final mensajero =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final servicio = ServicioBiometrico.instancia;

  setUp(() {
    mensajero.setMockMethodCallHandler(
      canalDispositivo,
      (_) async => {
        'name': 'Prueba',
        'systemName': 'Prueba',
        'systemVersion': '1',
        'model': 'Prueba',
        'localizedModel': 'Prueba',
        'identifierForVendor': 'prueba',
        'isPhysicalDevice': false,
        'utsname': {
          'sysname': 'Prueba',
          'nodename': 'Prueba',
          'release': '1',
          'version': '1',
          'machine': 'Prueba',
        },
      },
    );
  });

  tearDown(() {
    mensajero.setMockMethodCallHandler(canalSalud, null);
    mensajero.setMockMethodCallHandler(canalDispositivo, null);
  });

  test('El acceso existente no abre otro diálogo', () async {
    var solicitudes = 0;
    mensajero.setMockMethodCallHandler(canalSalud, (llamada) async {
      if (llamada.method == 'hasPermissions') return true;
      if (llamada.method == 'requestAuthorization') solicitudes++;
      return false;
    });
    expect(
      await servicio.solicitarAutorizacion(const [HealthDataType.HEART_RATE]),
      isTrue,
    );
    expect(solicitudes, 0);
  });

  test('La cancelación no se convierte en acceso concedido', () async {
    mensajero.setMockMethodCallHandler(canalSalud, (llamada) async => false);
    expect(
      await servicio.solicitarAutorizacion(const [HealthDataType.HEART_RATE]),
      isFalse,
    );
  });

  test('El fallo de consulta se conserva como error', () async {
    mensajero.setMockMethodCallHandler(canalSalud, (_) async {
      throw PlatformException(
        code: 'fallo_prueba',
        message: 'Proveedor inaccesible',
      );
    });
    await expectLater(
      servicio.verificarPermisos(const [HealthDataType.HEART_RATE]),
      throwsA(isA<StateError>()),
    );
  });

  test('La lectura no exige escritura de frecuencia cardíaca', () async {
    var autorizado = false;
    Object? permisosSolicitados;
    mensajero.setMockMethodCallHandler(canalSalud, (llamada) async {
      if (llamada.method == 'hasPermissions') return autorizado;
      if (llamada.method == 'requestAuthorization') {
        final argumentos = llamada.arguments;
        if (argumentos is Map) permisosSolicitados = argumentos['permissions'];
        autorizado = true;
        return true;
      }
      return false;
    });
    expect(
      await servicio.solicitarAutorizacion(const [HealthDataType.HEART_RATE]),
      isTrue,
    );
    expect(permisosSolicitados, [HealthDataAccess.READ.index]);
  });
}
