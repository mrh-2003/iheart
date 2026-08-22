import 'dart:async';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/widgets/boton_primario.dart';
import 'package:iheart/widgets/boton_secundario.dart';
import 'package:iheart/red/servicio_biometrico.dart';

class PantallaIoT extends StatefulWidget {
  const PantallaIoT({super.key});

  @override
  State<PantallaIoT> createState() => _PantallaIoTState();
}

class _PantallaIoTState extends State<PantallaIoT> {
  final List<HealthDataType> _tipos = const [HealthDataType.HEART_RATE];

  bool _disponible = false;
  bool _autorizado = false;
  bool _cargando = true;
  bool _cargandoAccion = false;
  bool _simulado = false;
  double _offset = 0.0;
  List<HealthDataPoint> _ultimasLecturas = [];

  @override
  void initState() {
    super.initState();
    _verificarEstado();
  }

  Future<void> _verificarEstado() async {
    setState(() {
      _cargando = true;
    });

    try {
      final bool disponible = await ServicioBiometrico.instancia.esHealthConnectDisponible();
      final bool simulado = await ServicioBiometrico.instancia.estaEnModoSimulado();
      final double offset = await ServicioBiometrico.instancia.obtenerOffset();
      setState(() {
        _disponible = disponible;
        _simulado = simulado;
        _offset = offset;
      });

      if (disponible) {
        final bool tienePermisos = await ServicioBiometrico.instancia.verificarPermisos(_tipos);
        setState(() {
          _autorizado = tienePermisos;
        });

        if (_autorizado) {
          await _cargarLecturasRecientes();
        }
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError('Error al verificar Health Connect: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _solicitarAutorizacion() async {
    setState(() {
      _cargandoAccion = true;
    });

    try {
      final bool permisoConcedido = await ServicioBiometrico.instancia.solicitarAutorizacion(_tipos);
      setState(() {
        _autorizado = permisoConcedido;
      });

      if (permisoConcedido) {
        if (mounted) {
          context.mostrarMensajeExito('Conexión con Health Connect establecida exitosamente.');
        }
        await _cargarLecturasRecientes();
      } else {
        if (mounted) {
          context.mostrarMensajeError('Permiso denegado por el usuario.');
        }
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError('Error al solicitar autorización: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoAccion = false;
        });
      }
    }
  }

  Future<void> _revocarAutorizacion() async {
    setState(() {
      _cargandoAccion = true;
    });

    try {
      await ServicioBiometrico.instancia.revocarPermisos();
      setState(() {
        _autorizado = false;
        _ultimasLecturas.clear();
      });
      if (mounted) {
        context.mostrarMensajeExito('Conexión revocada y desvinculada con éxito.');
      }
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError('Error al revocar permisos: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _cargandoAccion = false;
        });
      }
    }
  }

  Future<void> _cargarLecturasRecientes() async {
    try {
      final ahora = DateTime.now();
      final hace24Horas = ahora.subtract(const Duration(hours: 24));
      final datos = await ServicioBiometrico.instancia.obtenerDatosFrecuenciaCardiaca(
        hace24Horas,
        ahora,
      );

      setState(() {
        _ultimasLecturas = datos.reversed.toList();
      });
    } catch (e) {
      if (mounted) {
        context.mostrarMensajeError('Error al cargar lecturas: ${e.toString()}');
      }
    }
  }

  String _formatearFecha(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    final segundo = fecha.second.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    return '$dia/$mes/$anio $hora:$minuto:$segundo';
  }

  Widget _construirCabeceraEstado() {
    final String estadoTexto = _disponible
        ? (_autorizado ? (_simulado ? 'SIMULADO' : 'CONECTADO') : 'NO VINCULADO')
        : 'NO DISPONIBLE';
    final Color estadoColor = _disponible
        ? (_autorizado ? TemaApp.verdeExito : TemaApp.amarilloAlerta)
        : TemaApp.rojoError;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.health_and_safety_outlined, color: TemaApp.rojoPrimario, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _simulado ? 'Simulador Health Connect' : 'Google Health Connect',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TemaApp.textoOscuro,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  estadoTexto,
                  style: TextStyle(
                    color: estadoColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _simulado
                ? 'Simulación de datos de salud para compatibilidad con dispositivos antiguos.'
                : 'Sincronización directa y real de datos biométricos de salud sin simulaciones.',
            style: const TextStyle(
              fontSize: 13,
              color: TemaApp.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirAjusteOffset() {
    if (!_simulado || !_autorizado) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desviación del Ritmo Cardíaco (x)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TemaApp.textoOscuro,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ajuste el valor para inflar o desinflar el ritmo cardíaco simulado.',
            style: TextStyle(
              fontSize: 12,
              color: TemaApp.textoSecundario,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: TemaApp.rojoPrimario, size: 32),
                onPressed: () async {
                  setState(() {
                    _offset -= 5;
                  });
                  await ServicioBiometrico.instancia.guardarOffset(_offset);
                  await _cargarLecturasRecientes();
                },
              ),
              const SizedBox(width: 24),
              Text(
                '${_offset >= 0 ? "+" : ""}${_offset.toStringAsFixed(0)} bpm',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TemaApp.textoOscuro,
                ),
              ),
              const SizedBox(width: 24),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: TemaApp.rojoPrimario, size: 32),
                onPressed: () async {
                  setState(() {
                    _offset += 5;
                  });
                  await ServicioBiometrico.instancia.guardarOffset(_offset);
                  await _cargarLecturasRecientes();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirDetallesConexion() {
    if (!_disponible) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TemaApp.grisSuperficie,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'Health Connect no está instalado o no es compatible con este dispositivo.',
              style: TextStyle(color: TemaApp.textoSecundario, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            BotonPrimario(
              texto: 'Verificar disponibilidad',
              alPresionar: _verificarEstado,
            ),
          ],
        ),
      );
    }

    if (!_autorizado) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Vincule Health Connect para acceder a lecturas en tiempo real de su frecuencia cardíaca '
            'obtenida por sus dispositivos y wearables (como Xiaomi Smart Band 10 o similares).',
            style: TextStyle(color: TemaApp.textoSecundario, fontSize: 14),
          ),
          const SizedBox(height: 24),
          BotonPrimario(
            texto: 'Vincular Health Connect',
            alPresionar: _solicitarAutorizacion,
            cargando: _cargandoAccion,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TemaApp.grisSuperficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TemaApp.grisBorde),
          ),
          child: const Column(
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: TemaApp.verdeExito, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lectura de ritmo cardíaco activa',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.security, color: TemaApp.textoSecundario, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Los datos se procesan localmente',
                      style: TextStyle(color: TemaApp.textoSecundario, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: BotonSecundario(
                texto: 'Desvincular',
                alPresionar: _revocarAutorizacion,
                cargando: _cargandoAccion,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BotonPrimario(
                texto: 'Sincronizar',
                alPresionar: _cargarLecturasRecientes,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirListaLecturas() {
    if (!_autorizado || !_disponible) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lecturas recientes (últimas 24 horas)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: TemaApp.textoOscuro,
          ),
        ),
        const SizedBox(height: 12),
        if (_ultimasLecturas.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TemaApp.grisSuperficie,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: TemaApp.textoSecundario),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No se encontraron lecturas de frecuencia cardíaca.',
                    style: TextStyle(color: TemaApp.textoSecundario, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ..._ultimasLecturas.take(5).map((lectura) {
            final valor = lectura.value;
            double bpm = 0;
            if (valor is NumericHealthValue) {
              bpm = valor.numericValue.toDouble();
            }
            return Card(
              color: TemaApp.blancoFondo,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: TemaApp.grisBorde),
              ),
              child: ListTile(
                leading: const Icon(Icons.favorite, color: TemaApp.rojoClaro),
                title: Text(
                  '${bpm.toStringAsFixed(0)} bpm',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: TemaApp.textoOscuro,
                  ),
                ),
                subtitle: Text(
                  _formatearFecha(lectura.dateFrom),
                  style: const TextStyle(
                    fontSize: 12,
                    color: TemaApp.textoSecundario,
                  ),
                ),
                trailing: Text(
                  lectura.sourceName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: TemaApp.rojoPrimario,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Google Health Connect'),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SafeArea(
        child: _cargando
            ? const Center(
                child: CircularProgressIndicator(
                  color: TemaApp.rojoPrimario,
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                children: [
                  _construirCabeceraEstado(),
                  _construirAjusteOffset(),
                  const SizedBox(height: 24),
                  _construirDetallesConexion(),
                  const SizedBox(height: 24),
                  _construirListaLecturas(),
                ],
              ),
      ),
    );
  }
}
