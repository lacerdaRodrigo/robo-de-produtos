import 'package:flutter/material.dart';

import 'tokens.dart';

/// Tema claro por padrão, com a paleta aprovada no PLANO §10.2.
///
/// Tema escuro completo é evolução posterior (PLANO §9.2); aqui existe só a
/// base clara. O token de ganho nunca define a cor de ação — a decisão de
/// "verde = ganho" fica no design, não no tema.
abstract final class TemaRadar {
  static ThemeData claro([Brightness brilho = Brightness.light]) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brilho,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Tokens.marca,
        brightness: brilho,
        primary: Tokens.marca,
      ),
      scaffoldBackgroundColor: Tokens.fundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: Tokens.marca,
        foregroundColor: Colors.white,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: brilho == Brightness.light
            ? const Color(0xFF102A43)
            : Colors.white,
        displayColor: brilho == Brightness.light
            ? const Color(0xFF102A43)
            : Colors.white,
      ),
    );
  }

  static ThemeData escuro() => claro(Brightness.dark);
}
