import 'package:flutter/material.dart';
import 'package:iheart/nucleo/tema.dart';

class BarraNavegacion extends StatelessWidget {
  final int indiceSeleccionado;
  final ValueChanged<int> alCambiarFila;

  const BarraNavegacion({
    super.key,
    required this.indiceSeleccionado,
    required this.alCambiarFila,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TemaApp.blancoFondo,
        border: const Border(
          top: BorderSide(color: TemaApp.grisBorde, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: indiceSeleccionado,
        onTap: alCambiarFila,
        type: BottomNavigationBarType.fixed,
        backgroundColor: TemaApp.blancoFondo,
        selectedItemColor: TemaApp.rojoPrimario,
        unselectedItemColor: TemaApp.textoSecundario,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home, color: TemaApp.rojoPrimario),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety_outlined),
            activeIcon: Icon(Icons.health_and_safety, color: TemaApp.rojoPrimario),
            label: 'Evaluar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history, color: TemaApp.rojoPrimario),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: TemaApp.rojoPrimario),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings, color: TemaApp.rojoPrimario),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
