import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:optima_ml/widgets/boton_primario.dart';
import 'package:optima_ml/widgets/campo_texto.dart';
import 'package:optima_ml/modelo/feature_engineering.dart';
import 'package:optima_ml/datos/repositorio_perfil.dart';
import 'package:optima_ml/datos/repositorio_diagnosticos.dart';

void main() {
  group('Pruebas Unitarias - Feature Engineering', () {
    test('Debe generar exactamente 32 features a partir del perfil y cuestionario', () {
      const perfil = PerfilPaciente(
        id: 1,
        nombreCompleto: 'Juan Pérez',
        numeroDni: '12345678',
        correo: 'juan@correo.com',
        edad: 40,
        sexo: 'Masculino',
        pesoKg: 80.0,
        alturaM: 1.80,
        imc: 24.69,
        ciudad: 'Lima',
        pais: 'Perú',
        versionModeloLocal: 1,
      );

      final cuestionario = CuestionarioClinico(
        tieneDiabetes: true,
        tieneHipertension: true,
        tieneAccidenteCerebrovascular: false,
        tieneInsuficienciaRenal: false,
        tieneEnfermedadRespiratoria: false,
        tieneEnfermedadTiroidea: false,
        tieneInsuficienciaCardiaca: false,
        tieneDislipidemia: false,
        tieneObesidad: false,
        esFumadorActivo: true,
        esExFumador: false,
        antecedenteFamiliarCad: false,
        presentaEdema: false,
        presentaDolorPecho: false,
        frecuenciaDolorPecho: 0,
        clasificacionDolor: 0,
        esfuerzoFisicoReciente: false,
        disnea: false,
        creadoEn: DateTime.now().toIso8601String(),
      );

      final features = FeatureEngineering.generarFeatures(
        perfil: perfil,
        cuestionario: cuestionario,
        ritmoCardiaco: 75.0,
      );

      expect(features.length, equals(32));
      
      // Sexo = 1.0 (Masculino)
      expect(features[19], equals(40.0)); // Age
      expect(features[22], equals(1.0)); // Sex
    });
  });

  group('Pruebas de Widgets Críticos', () {
    testWidgets('BotonPrimario se renderiza correctamente con texto', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BotonPrimario(
              texto: 'Acceder',
              alPresionar: () {},
            ),
          ),
        ),
      );

      expect(find.text('Acceder'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('CampoTexto permite ingresar texto', (WidgetTester tester) async {
      final controlador = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CampoTexto(
              controlador: controlador,
              etiqueta: 'Correo',
            ),
          ),
        ),
      );

      expect(find.text('Correo'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'test@correo.com');
      expect(controlador.text, equals('test@correo.com'));
    });
  });
}
