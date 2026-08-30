import 'package:flutter/material.dart';

import 'tokens.dart';

/// Temas do Radar com a mesma identidade e sem misturar ação com ganho.
abstract final class TemaRadar {
  /// Tema congelado de jornadas que não fazem parte do ciclo mobile.
  static ThemeData legadoClaro() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Tokens.marcaClara,
        brightness: Brightness.light,
        primary: Tokens.marcaClara,
        surface: Tokens.superficie,
        error: Tokens.perigo,
        onSurface: Tokens.texto,
        outline: Tokens.borda,
      ),
      scaffoldBackgroundColor: Tokens.fundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: Tokens.superficie,
        foregroundColor: Tokens.texto,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Tokens.texto,
        displayColor: Tokens.texto,
      ),
    );
  }

  /// Tema amplo anterior com as cores semânticas usadas pelos widgets novos.
  static ThemeData legadoClaroComCores() => legadoClaro().copyWith(
    extensions: const <ThemeExtension<dynamic>>[CoresRadar.legadas()],
  );

  static ThemeData claro() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Tokens.marca,
        brightness: Brightness.light,
        primary: Tokens.marca,
      ),
      scaffoldBackgroundColor: Tokens.fundo,
      cardColor: Tokens.superficie,
      dividerColor: Tokens.borda,
      extensions: const <ThemeExtension<dynamic>>[CoresRadar.claras()],
      appBarTheme: const AppBarTheme(
        backgroundColor: Tokens.marca,
        foregroundColor: Colors.white,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Tokens.texto,
        displayColor: Tokens.texto,
      ),
    );
  }

  static ThemeData escuro() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
    );
    final esquema = ColorScheme.fromSeed(
      seedColor: Tokens.marcaClara,
      brightness: Brightness.dark,
      primary: Tokens.acaoEscura,
      surface: Tokens.superficieEscura,
      error: Tokens.perigoEscuro,
      onSurface: Tokens.textoEscuro,
      outline: Tokens.bordaEscura,
    );
    return base.copyWith(
      colorScheme: esquema,
      scaffoldBackgroundColor: Tokens.fundoEscuro,
      cardColor: Tokens.superficieEscura,
      dividerColor: Tokens.bordaEscura,
      extensions: const <ThemeExtension<dynamic>>[CoresRadar.escuras()],
      appBarTheme: const AppBarTheme(
        backgroundColor: Tokens.superficieEscura,
        foregroundColor: Tokens.textoEscuro,
        surfaceTintColor: Colors.transparent,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Tokens.superficieEscura,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Tokens.textoEscuro,
        displayColor: Tokens.textoEscuro,
      ),
    );
  }
}
