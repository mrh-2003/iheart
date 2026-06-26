import 'package:flutter/material.dart';

class TemaApp {
  static const Color rojoPrimario = Color(0xFF7B1624);
  static const Color rojoClaro = Color(0xFFB71C1C);
  static const Color blancoFondo = Color(0xFFFFFFFF);
  static const Color grisSuperficie = Color(0xFFF5F5F5);
  static const Color grisBorde = Color(0xFFE0E0E0);
  static const Color textoOscuro = Color(0xFF1A1A1A);
  static const Color textoSecundario = Color(0xFF757575);
  static const Color verdeExito = Color(0xFF2E7D32);
  static const Color amarilloAlerta = Color(0xFFF57C00);
  static const Color rojoError = Color(0xFFD32F2F);

  static ThemeData obtenerTema() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: blancoFondo,
      primaryColor: rojoPrimario,
      appBarTheme: const AppBarTheme(
        backgroundColor: rojoPrimario,
        foregroundColor: blancoFondo,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textoOscuro,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textoOscuro,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textoOscuro,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textoSecundario,
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: rojoPrimario,
        primary: rojoPrimario,
        surface: blancoFondo,
        error: rojoError,
      ),
    );
  }
}
