import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:iheart/nucleo/tema.dart';
import 'package:iheart/nucleo/extensiones.dart';
import 'package:iheart/nucleo/proveedor_estado.dart';

class PantallaAjustes extends StatefulWidget {
  final ValueChanged<int>? alCambiarTab;

  const PantallaAjustes({
    super.key,
    this.alCambiarTab,
  });

  @override
  State<PantallaAjustes> createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  bool _notificacionesActivas = true;

  Future<void> _cerrarSesion() async {
    final estado = context.read<ProveedorEstado>();
    await estado.cerrarSesion();
    if (mounted) {
      context.mostrarMensajeExito('Sesión cerrada correctamente');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TemaApp.blancoFondo,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          // Tarjeta: Mi Perfil
          _construirTarjetaAjuste(
            titulo: 'Mi Perfil',
            subtitulo: 'Ver y editar mis datos personales',
            icono: Icons.person_outline,
            alPresionar: () {
              if (widget.alCambiarTab != null) {
                widget.alCambiarTab!(3); // Indice del tab Perfil
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Tarjeta: Notificaciones
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: TemaApp.blancoFondo,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TemaApp.grisBorde),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TemaApp.rojoPrimario.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined, color: TemaApp.rojoPrimario),
              ),
              title: const Text(
                'Notificaciones',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Alertas de riesgo y recordatorios'),
              trailing: Switch(
                value: _notificacionesActivas,
                activeColor: TemaApp.rojoPrimario,
                onChanged: (valor) {
                  setState(() {
                    _notificacionesActivas = valor;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Tarjeta: Dispositivos Vinculados
          _construirTarjetaAjuste(
            titulo: 'Dispositivos Vinculados',
            subtitulo: 'Gestionar wearables y sensores BLE',
            icono: Icons.watch_outlined,
            alPresionar: () => context.push('/iot'),
          ),
          const SizedBox(height: 16),

          // Tarjeta: Revisar modelo federado
          _construirTarjetaAjuste(
            titulo: 'Modelo de Aprendizaje Federado',
            subtitulo: 'Ver métricas de precisión local y sincronización',
            icono: Icons.model_training_outlined,
            alPresionar: () => context.push('/modelo_fl'),
          ),
          const SizedBox(height: 32),

          // Botón Cerrar Sesión
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: TemaApp.rojoError, width: 1.2),
            ),
            tileColor: TemaApp.rojoError.withOpacity(0.04),
            leading: const Icon(Icons.logout, color: TemaApp.rojoError),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: TemaApp.rojoError,
                fontSize: 16,
              ),
            ),
            onTap: _cerrarSesion,
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaAjuste({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required VoidCallback alPresionar,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TemaApp.grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TemaApp.rojoPrimario.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: TemaApp.rojoPrimario),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: TemaApp.textoSecundario),
        onTap: alPresionar,
      ),
    );
  }
}
