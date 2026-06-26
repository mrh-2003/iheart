import 'dart:async';
import 'package:flutter/material.dart';
import 'package:optima_ml/nucleo/tema.dart';
import 'package:optima_ml/nucleo/extensiones.dart';
import 'package:optima_ml/widgets/boton_primario.dart';

class PantallaIoT extends StatefulWidget {
  const PantallaIoT({super.key});

  @override
  State<PantallaIoT> createState() => _PantallaIoTState();
}

class _PantallaIoTState extends State<PantallaIoT> {
  bool _procesamientoLocal = true;
  bool _buscando = false;
  final List<String> _dispositivosEncontrados = [];
  Timer? _temporizadorBusqueda;

  void _iniciarBusquedaBLE() {
    setState(() {
      _buscando = true;
      _dispositivosEncontrados.clear();
    });

    _temporizadorBusqueda = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _buscando = false;
          _dispositivosEncontrados.addAll([
            'IHeart Band Active (BLE)',
            'Polar H10 Heart Rate Sensor',
            'Galaxy Watch 6 Heart Monitor',
          ]);
        });
      }
    });
  }

  @override
  void dispose() {
    _temporizadorBusqueda?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      appBar: AppBar(
        title: const Text('Dispositivos Vinculados'),
        backgroundColor: TemaApp.rojoPrimario,
        foregroundColor: TemaApp.blancoFondo,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            // Dispositivo Actual Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TemaApp.blancoFondo,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TemaApp.grisBorde),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
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
                      const Text(
                        'IHeart Smartband v1.2',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TemaApp.verdeExito.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'CONECTADO',
                          style: TextStyle(color: TemaApp.verdeExito, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.battery_5_bar, color: TemaApp.verdeExito),
                          SizedBox(width: 8),
                          Text('Batería: 82%'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.signal_cellular_alt, color: TemaApp.rojoPrimario),
                          const SizedBox(width: 8),
                          const Text('Señal: Excelente'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Firmware: v2.4.1-alpha', style: TextStyle(color: TemaApp.textoSecundario, fontSize: 12)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Procesamiento Local de PPG',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text('Ejecutar filtrado digital de señal en el wearable'),
                    value: _procesamientoLocal,
                    activeColor: TemaApp.rojoPrimario,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (valor) {
                      setState(() {
                        _procesamientoLocal = valor;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Añadir Wearable',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escanee el entorno para sincronizar una nueva smartband o monitor cardíaco compatible.',
              style: TextStyle(fontSize: 12, color: TemaApp.textoSecundario),
            ),
            const SizedBox(height: 20),
            
            BotonPrimario(
              texto: _buscando ? 'Buscando dispositivos BLE...' : 'Buscar dispositivos BLE',
              cargando: _buscando,
              alPresionar: _iniciarBusquedaBLE,
            ),
            
            const SizedBox(height: 24),
            if (_dispositivosEncontrados.isNotEmpty) ...[
              const Text(
                'Dispositivos Encontrados:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TemaApp.textoOscuro),
              ),
              const SizedBox(height: 12),
              ..._dispositivosEncontrados.map((nombre) => Card(
                    color: TemaApp.grisSuperficie,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth, color: TemaApp.rojoPrimario),
                      title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: TextButton(
                        onPressed: () {
                          context.mostrarMensajeExito('Conectado con éxito a $nombre');
                        },
                        child: const Text('VINCULAR', style: TextStyle(color: TemaApp.rojoPrimario, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
