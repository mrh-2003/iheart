import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:optima_ml/datos/repositorio_perfil.dart';
import 'package:optima_ml/datos/repositorio_sesiones.dart';
import 'package:optima_ml/datos/repositorio_diagnosticos.dart';
import 'package:optima_ml/datos/repositorio_modelo.dart';
import 'package:optima_ml/red/servicio_auth.dart';
import 'package:optima_ml/red/servicio_modelo.dart';
import 'package:optima_ml/red/servicio_federado.dart';
import 'package:optima_ml/modelo/inferencia_local.dart';
import 'package:optima_ml/modelo/fedavg_local.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ProveedorEstado extends ChangeNotifier {
  final RepositorioPerfil _repoPerfil = RepositorioPerfil();
  final RepositorioSesiones _repoSesiones = RepositorioSesiones();
  final RepositorioDiagnosticos _repoDiagnosticos = RepositorioDiagnosticos();
  final RepositorioModelo _repoModelo = RepositorioModelo();

  final ServicioAuth _servicioAuth = ServicioAuth();
  final ServicioModelo _servicioModelo = ServicioModelo();
  final ServicioFederado _servicioFederado = ServicioFederado();

  PerfilPaciente? _perfil;
  EstadoModeloFl? _estadoModelo;
  List<SesionMonitoreo> _sesiones = [];
  List<Map<String, Object?>> _historial = [];
  bool _cargando = false;

  PerfilPaciente? get perfil => _perfil;
  EstadoModeloFl? get estadoModelo => _estadoModelo;
  List<SesionMonitoreo> get sesiones => _sesiones;
  List<Map<String, Object?>> get historial => _historial;
  bool get cargando => _cargando;

  Future<void> inicializarApp() async {
    _cargando = true;
    notifyListeners();

    try {
      _perfil = await _repoPerfil.obtenerPerfil();
      _estadoModelo = await _repoModelo.obtenerEstadoFL();
      
      // Intentar inicializar el modelo local si existe
      await InferenciaLocal.instancia.inicializar();
      
      if (_perfil != null) {
        await cargarDatosLocales();
      }
    } catch (_) {}

    _cargando = false;
    notifyListeners();
  }

  Future<void> cargarDatosLocales() async {
    _sesiones = await _repoSesiones.obtenerSesionesRecientes(limite: 10);
    _historial = await _repoDiagnosticos.obtenerHistorialCompleto();
    _estadoModelo = await _repoModelo.obtenerEstadoFL();
    notifyListeners();
  }

  Future<void> iniciarSesion(String correo, String contrasena) async {
    _cargando = true;
    notifyListeners();

    try {
      final resultado = await _servicioAuth.iniciarSesion(correo, contrasena);
      final nuevoPerfil = PerfilPaciente(
        id: resultado.usuarioId,
        nombreCompleto: resultado.nombreCompleto,
        numeroDni: resultado.numeroDni,
        correo: resultado.correo,
        ciudad: 'Lima',
        pais: 'Perú',
        tokenJwt: resultado.token,
        tokenExpiraEn: resultado.expiraEn,
        versionModeloLocal: 0,
      );

      await _repoPerfil.guardarPerfil(nuevoPerfil);
      _perfil = nuevoPerfil;

      // Cargar datos tras iniciar sesión
      await cargarDatosLocales();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registrarUsuario({
    required String nombreCompleto,
    required String numeroDni,
    required String correo,
    required String contrasena,
  }) async {
    _cargando = true;
    notifyListeners();

    try {
      await _servicioAuth.registrarUsuario(
        nombreCompleto: nombreCompleto,
        numeroDni: numeroDni,
        correo: correo,
        contrasena: contrasena,
      );
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    await _repoPerfil.cerrarSesion();
    _perfil = null;
    _sesiones = [];
    _historial = [];
    InferenciaLocal.instancia.desactivar();
    notifyListeners();
  }

  Future<void> actualizarPerfil(PerfilPaciente perfilActualizado) async {
    _cargando = true;
    notifyListeners();

    try {
      await _repoPerfil.guardarPerfil(perfilActualizado);
      _perfil = await _repoPerfil.obtenerPerfil();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> sincronizarModelo() async {
    _cargando = true;
    notifyListeners();

    try {
      final versionServidor = await _servicioModelo.obtenerVersionModelo();
      final versionLocal = _estadoModelo?.versionLocal ?? 0;

      await _repoModelo.registrarSincronizacion(
        tipo: 'version_check',
        exitoso: true,
        versionAntes: versionLocal,
        versionDespues: versionLocal,
        detalle: 'Verificación de versión del modelo. Servidor: $versionServidor. Local: $versionLocal',
      );

      if (versionServidor > versionLocal) {
        final bytesModelo = await _servicioModelo.descargarModeloTflite();
        final directorio = await getApplicationDocumentsDirectory();
        
        // Guardar archivo modelo.tflite
        final archivoModelo = File('${directorio.path}/modelo.tflite');
        await archivoModelo.writeAsBytes(bytesModelo);

        // Guardar también un scaler JSON simulado (StandardScaler del backend)
        final archivoScaler = File('${directorio.path}/scaler.json');
        await archivoScaler.writeAsString('{"mean": ${List.filled(32, 0.0).toString()}, "std": ${List.filled(32, 1.0).toString()}}');

        final inicializado = await InferenciaLocal.instancia.inicializar();
        if (inicializado) {
          final nuevoEstado = EstadoModeloFl(
            id: 1,
            versionServidor: versionServidor,
            versionLocal: versionServidor,
            rutaModeloTflite: archivoModelo.path,
            rondaActual: _estadoModelo?.rondaActual ?? 0,
            ultimaSincronizacion: DateTime.now().toIso8601String(),
            pesosPendientes: _estadoModelo?.pesosPendientes ?? false,
            entrenamientoLocalCompletado: _estadoModelo?.entrenamientoLocalCompletado ?? false,
            accuracyLocal: _estadoModelo?.accuracyLocal,
            actualizadoEn: DateTime.now().toIso8601String(),
          );

          await _repoModelo.actualizarEstadoFL(nuevoEstado);
          _estadoModelo = nuevoEstado;

          await _repoModelo.registrarSincronizacion(
            tipo: 'descarga_modelo',
            exitoso: true,
            versionAntes: versionLocal,
            versionDespues: versionServidor,
            detalle: 'Modelo TFLite versión $versionServidor descargado con éxito.',
          );
        }
      }
    } catch (e) {
      await _repoModelo.registrarSincronizacion(
        tipo: 'descarga_modelo',
        exitoso: false,
        versionAntes: _estadoModelo?.versionLocal ?? 0,
        versionDespues: _estadoModelo?.versionLocal ?? 0,
        detalle: 'Error descargando modelo: ${e.toString()}',
      );
      rethrow;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> entrenarYSubirPesosFL() async {
    _cargando = true;
    notifyListeners();

    try {
      final pesos = await FedAvgLocal.instancia.entrenarModeloLocal();
      
      if (_perfil != null && _estadoModelo != null) {
        await _servicioFederado.subirPesosFL(
          idCliente: _perfil!.id,
          ronda: _estadoModelo!.rondaActual + 1,
          numeroMuestras: 5,
          pesos: pesos,
        );

        await FedAvgLocal.instancia.limpiarPesosLocales();
        
        await _repoModelo.registrarSincronizacion(
          tipo: 'subida_pesos',
          exitoso: true,
          detalle: 'Pesos federados de la ronda ${_estadoModelo!.rondaActual + 1} subidos con éxito.',
        );
      }
    } catch (e) {
      await _repoModelo.registrarSincronizacion(
        tipo: 'subida_pesos',
        exitoso: false,
        detalle: 'Error subiendo pesos federados: ${e.toString()}',
      );
      rethrow;
    } finally {
      await cargarDatosLocales();
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> registrarNuevaSesion(SesionMonitoreo sesion) async {
    await _repoSesiones.guardarSesion(sesion);
    await cargarDatosLocales();
  }

  Future<void> registrarDiagnosticoCompleto({
    required SesionMonitoreo sesion,
    required CuestionarioClinico cuestionario,
    required double probabilidad,
    required String riesgo,
    required String etiqueta,
    required String featuresJson,
  }) async {
    final sesionId = await _repoSesiones.guardarSesion(sesion);
    
    final nuevoCuestionario = CuestionarioClinico(
      idSesionMonitoreo: sesionId,
      tieneDiabetes: cuestionario.tieneDiabetes,
      tieneHipertension: cuestionario.tieneHipertension,
      tieneAccidenteCerebrovascular: cuestionario.tieneAccidenteCerebrovascular,
      tieneInsuficienciaRenal: cuestionario.tieneInsuficienciaRenal,
      tieneEnfermedadRespiratoria: cuestionario.tieneEnfermedadRespiratoria,
      tieneEnfermedadTiroidea: cuestionario.tieneEnfermedadTiroidea,
      tieneInsuficienciaCardiaca: cuestionario.tieneInsuficienciaCardiaca,
      tieneDislipidemia: cuestionario.tieneDislipidemia,
      tieneObesidad: cuestionario.tieneObesidad,
      esFumadorActivo: cuestionario.esFumadorActivo,
      esExFumador: cuestionario.esExFumador,
      antecedenteFamiliarCad: cuestionario.antecedenteFamiliarCad,
      presentaEdema: cuestionario.presentaEdema,
      presentaDolorPecho: cuestionario.presentaDolorPecho,
      frecuenciaDolorPecho: cuestionario.frecuenciaDolorPecho,
      clasificacionDolor: cuestionario.clasificacionDolor,
      tipoDolor: cuestionario.tipoDolor,
      esfuerzoFisicoReciente: cuestionario.esfuerzoFisicoReciente,
      disnea: cuestionario.disnea,
      creadoEn: DateTime.now().toIso8601String(),
    );

    final cuestionarioId = await _repoDiagnosticos.guardarCuestionario(nuevoCuestionario);

    final diagnostico = DiagnosticoClinico(
      idSesionMonitoreo: sesionId,
      idCuestionario: cuestionarioId,
      probabilidadCad: probabilidad,
      nivelRiesgo: riesgo,
      etiquetaPrediccion: etiqueta,
      versionModeloUsada: _estadoModelo?.versionLocal ?? 0,
      umbralAplicado: 0.5,
      inferenciaLocal: true,
      featuresJson: featuresJson,
      creadoEn: DateTime.now().toIso8601String(),
    );

    final diagnosticoId = await _repoDiagnosticos.guardarDiagnostico(diagnostico);

    // Guardar recomendaciones basadas en la severidad del riesgo
    String textoRecomendacion = 'Mantenga una dieta saludable baja en sodio y grasas saturadas.';
    String icono = 'diet';
    if (riesgo == 'alto' || riesgo == 'crítico') {
      textoRecomendacion = 'Se recomienda programar una cita con su cardiólogo a la brevedad.';
      icono = 'doctor';
    } else if (probabilidad > 0.3) {
      textoRecomendacion = 'Reduzca el consumo de tabaco y aumente la actividad física diaria (al menos 30 min).';
      icono = 'exercise';
    }

    await _repoDiagnosticos.guardarRecomendacion(RecomendacionClinica(
      idDiagnostico: diagnosticoId,
      texto: textoRecomendacion,
      icono: icono,
      prioridad: 1,
      creadoEn: DateTime.now().toIso8601String(),
    ));

    // Si es un riesgo severo, disparar una alerta cardíaca local
    if (riesgo == 'alto' || riesgo == 'crítico') {
      await _repoModelo.guardarAlerta(AlertaCardiaca(
        tipo: 'riesgo_alto',
        mensaje: 'Se ha detectado un riesgo cardiovascular elevado ($riesgo). Recomendamos consultar con un médico.',
        valorDetectado: probabilidad,
        leida: false,
        creadoEn: DateTime.now().toIso8601String(),
      ));
    }

    await cargarDatosLocales();
  }
}
