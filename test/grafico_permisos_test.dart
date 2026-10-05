import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iheart/widgets/grafico_ppg.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canalSalud = MethodChannel('flutter_health');
  const canalDispositivo = MethodChannel(
    'dev.fluttercommunity.plus/device_info',
  );
  final mensajero =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

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

  testWidgets('El gráfico refresca sin pedir permisos y distingue errores', (
    probador,
  ) async {
    var solicitudes = 0;
    mensajero.setMockMethodCallHandler(canalSalud, (llamada) async {
      if (llamada.method == 'requestAuthorization') solicitudes++;
      return false;
    });
    await probador.pumpWidget(
      const MaterialApp(home: Scaffold(body: GraficoPPG())),
    );
    await probador.pumpAndSettle();
    expect(find.textContaining('Conceda acceso en Ajustes'), findsOneWidget);
    await probador.pump(const Duration(seconds: 16));
    await probador.pumpAndSettle();
    expect(solicitudes, 0);
    mensajero.setMockMethodCallHandler(canalSalud, (_) async {
      throw PlatformException(code: 'proveedor_no_disponible');
    });
    await probador.tap(find.text('Reintentar'));
    await probador.pumpAndSettle();
    expect(find.textContaining('Error al leer Health Connect'), findsOneWidget);
    expect(find.textContaining('Sin datos de ritmo cardíaco'), findsNothing);
    await probador.pumpWidget(const SizedBox.shrink());
  });
}
