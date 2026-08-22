import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:health/health.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/tarjeta_riesgo.dart';
import 'package:iheart/widgets/grafico_ppg.dart';
import 'package:iheart/widgets/barra_navegacion.dart';
import 'package:iheart/pantallas/evaluar/pantalla_cuestionario.dart';
import 'package:iheart/pantallas/historial/pantalla_historial.dart';
import 'package:iheart/pantallas/perfil/pantalla_perfil.dart';
import 'package:iheart/pantallas/ajustes/pantalla_ajustes.dart';
import 'package:iheart/red/servicio_biometrico.dart';

class PantallaInicio extends StatefulWidget {
  final int indiceInicial;

  const PantallaInicio({
    super.key,
    this.indiceInicial = 0,
  });

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  late int _indiceSeleccionado;

  @override
  void initState() {
    super.initState();
    _indiceSeleccionado = widget.indiceInicial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _solicitarTodosLosPermisos();
    });
  }

  Future<void> _solicitarTodosLosPermisos() async {
    try {
      await Permission.notification.request();
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      if (Platform.isAndroid) {
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
      }
      await ServicioBiometrico.instancia.solicitarAutorizacion(const [HealthDataType.HEART_RATE]);
    } catch (_) {}
  }

  String _obtenerTituloTab(int indice) {
    switch (indice) {
      case 0:
        return 'I HEAR(TH)';
      case 1:
        return 'Evaluar Salud';
      case 2:
        return 'Historial Clínico';
      case 3:
        return 'Mi Perfil';
      case 4:
        return 'Ajustes';
      default:
        return 'I HEAR(TH)';
    }
  }

  Widget _construirCabecera(String iniciales, String saludoNombre) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: TemaApp.rojoPrimario,
          child: Text(
            iniciales,
            style: const TextStyle(color: TemaApp.blancoFondo, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, $saludoNombre',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
            const Text('¿Cómo se siente su corazón hoy?', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 13)),
          ],
        ),
      ],
    );
  }

  Widget _construirBiometria(Map<String, Object?>? ultimoDiag) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaApp.blancoFondo,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemaApp.grisBorde),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite, color: TemaApp.rojoPrimario, size: 20),
                    SizedBox(width: 8),
                    Text('Frec. Cardíaca', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ultimoDiag != null && ultimoDiag['bpm_promedio'] != null
                      ? '${(ultimoDiag['bpm_promedio'] as num).toStringAsFixed(0)} bpm'
                      : '— bpm',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TemaApp.blancoFondo,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemaApp.grisBorde),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.opacity, color: TemaApp.rojoPrimario, size: 20),
                    SizedBox(width: 8),
                    Text('SpO2', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  ultimoDiag != null && ultimoDiag['spo2_promedio'] != null
                      ? '${(ultimoDiag['spo2_promedio'] as num).toStringAsFixed(0)}%'
                      : '—%',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirGraficoYAccion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ritmo Cardíaco (Últimas 6 horas)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TemaApp.grisSuperficie,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TemaApp.grisBorde),
          ),
          child: const GraficoPPG(interactivo: false),
        ),
        const SizedBox(height: 32),
        BotonPrimario(
          texto: 'INICIAR NUEVO DIAGNÓSTICO',
          alPresionar: () {
            setState(() {
              _indiceSeleccionado = 1;
            });
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _construirDashboard(
    String iniciales,
    String saludoNombre,
    Map<String, Object?>? ultimoDiag,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _construirCabecera(iniciales, saludoNombre),
          const SizedBox(height: 24),
          TarjetaRiesgo(
            porcentajeRiesgo: ultimoDiag != null ? (ultimoDiag['probabilidad_cad'] as num).toDouble() : 0.0,
            nivelRiesgo: ultimoDiag != null ? (ultimoDiag['nivel_riesgo'] as String) : 'bajo',
          ),
          const SizedBox(height: 24),
          _construirBiometria(ultimoDiag),
          const SizedBox(height: 24),
          _construirGraficoYAccion(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<ProveedorEstado>();
    final perfil = estado.perfil;
    final ultimoDiag = estado.historial.isNotEmpty ? estado.historial.first : null;

    final String saludoNombre = perfil != null && perfil.nombreCompleto.isNotEmpty
        ? perfil.nombreCompleto.split(' ')[0]
        : 'Paciente';

    final String iniciales = perfil != null && perfil.nombreCompleto.isNotEmpty
        ? perfil.nombreCompleto.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'P';

    final List<Widget> vistas = [
      _construirDashboard(iniciales, saludoNombre, ultimoDiag),
      const PantallaCuestionario(),
      const PantallaHistorial(),
      const PantallaPerfil(),
      PantallaAjustes(
        alCambiarTab: (indice) {
          setState(() {
            _indiceSeleccionado = indice;
          });
        },
      ),
    ];

    return PopScope(
      canPop: _indiceSeleccionado == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        setState(() {
          _indiceSeleccionado = 0;
        });
      },
      child: Scaffold(
        backgroundColor: TemaApp.blancoFondo,
        appBar: AppBar(
          title: Text(
            _obtenerTituloTab(_indiceSeleccionado),
            style: const TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold),
          ),
          backgroundColor: TemaApp.blancoFondo,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: vistas[_indiceSeleccionado],
        bottomNavigationBar: BarraNavegacion(
          indiceSeleccionado: _indiceSeleccionado,
          alCambiarFila: (indice) {
            setState(() {
              _indiceSeleccionado = indice;
            });
          },
        ),
      ),
    );
  }
}
