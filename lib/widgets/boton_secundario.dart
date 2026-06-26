import 'package:flutter/material.dart';
import 'package:optima_ml/nucleo/tema.dart';

class BotonSecundario extends StatelessWidget {
  final String texto;
  final VoidCallback? alPresionar;
  final bool cargando;

  const BotonSecundario({
    super.key,
    required this.texto,
    this.alPresionar,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: (cargando || alPresionar == null) ? null : alPresionar,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: TemaApp.rojoPrimario, width: 2),
          foregroundColor: TemaApp.rojoPrimario,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
        ),
        child: cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: TemaApp.rojoPrimario,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                texto,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
