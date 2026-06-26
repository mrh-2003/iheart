import 'dart:math';
import 'package:optima_ml/datos/repositorio_diagnosticos.dart';
import 'package:optima_ml/datos/repositorio_modelo.dart';

class FedAvgLocal {
  static final FedAvgLocal instancia = FedAvgLocal._interna();
  final RepositorioDiagnosticos _repoDiagnosticos = RepositorioDiagnosticos();
  final RepositorioModelo _repoModelo = RepositorioModelo();

  FedAvgLocal._interna();

  Future<bool> verificarRequisitosEntrenamiento() async {
    final diagnosticos = await _repoDiagnosticos.obtenerDiagnosticosRecientes(limite: 10);
    // Necesitamos al menos 5 diagnósticos para el entrenamiento local
    return diagnosticos.length >= 5;
  }

  Future<List<double>> entrenarModeloLocal() async {
    final diagnosticos = await _repoDiagnosticos.obtenerDiagnosticosRecientes(limite: 5);
    if (diagnosticos.length < 5) {
      throw Exception('Datos insuficientes para el entrenamiento local (mínimo 5).');
    }

    // Simulamos el cálculo de gradientes/pesos locales del modelo (32 features + bias = 33 pesos)
    final random = Random();
    final List<double> pesosBase = List.generate(33, (_) => (random.nextDouble() * 2 - 1) * 0.1);

    // Hacemos que el gradiente dependa de los diagnósticos reales del paciente para simular aprendizaje
    double promedioRiesgo = 0.0;
    for (var diag in diagnosticos) {
      promedioRiesgo += diag.probabilidadCad;
    }
    promedioRiesgo /= diagnosticos.length;

    // Ajustar los pesos simulados según el promedio de riesgo del paciente
    for (int i = 0; i < pesosBase.length; i++) {
      pesosBase[i] += promedioRiesgo * 0.05;
    }

    // Actualizar el estado del modelo local
    final estado = await _repoModelo.obtenerEstadoFL();
    final nuevoEstado = EstadoModeloFl(
      id: estado.id,
      versionServidor: estado.versionServidor,
      versionLocal: estado.versionLocal,
      rutaModeloTflite: estado.rutaModeloTflite,
      rondaActual: estado.rondaActual + 1,
      ultimaSincronizacion: estado.ultimaSincronizacion,
      pesosPendientes: true,
      entrenamientoLocalCompletado: true,
      accuracyLocal: 0.85 + (random.nextDouble() * 0.1), // Simular accuracy
      actualizadoEn: DateTime.now().toIso8601String(),
    );

    await _repoModelo.actualizarEstadoFL(nuevoEstado);
    return pesosBase;
  }

  Future<void> limpiarPesosLocales() async {
    final estado = await _repoModelo.obtenerEstadoFL();
    final nuevoEstado = EstadoModeloFl(
      id: estado.id,
      versionServidor: estado.versionServidor,
      versionLocal: estado.versionLocal,
      rutaModeloTflite: estado.rutaModeloTflite,
      rondaActual: estado.rondaActual,
      ultimaSincronizacion: DateTime.now().toIso8601String(),
      pesosPendientes: false,
      entrenamientoLocalCompletado: false,
      accuracyLocal: estado.accuracyLocal,
      actualizadoEn: DateTime.now().toIso8601String(),
    );
    await _repoModelo.actualizarEstadoFL(nuevoEstado);
  }
}
