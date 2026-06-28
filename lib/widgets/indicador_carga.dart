import 'package:flutter/material.dart';
import 'package:iheart/nucleo/tema.dart';

class IndicadorCarga extends StatelessWidget {
  final String? mensaje;

  const IndicadorCarga({
    super.key,
    this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: TemaApp.rojoPrimario,
            strokeWidth: 3,
          ),
          if (mensaje != null) ...[
            const SizedBox(height: 16),
            Text(
              mensaje!,
              style: const TextStyle(
                fontSize: 14,
                color: TemaApp.textoSecundario,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
