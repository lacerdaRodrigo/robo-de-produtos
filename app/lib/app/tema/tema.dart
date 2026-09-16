import 'package:flutter/material.dart';

import 'tokens.dart';

/// Temas do Radar com a direção visual Delta compartilhada entre as telas.
abstract final class TemaRadar {
  /// Mantém o nome usado pela jornada de autenticação e pelos testes.
  static ThemeData loginLegado() => claro();

  /// Tema congelado das jornadas amplas que não fazem parte do ciclo mobile.
  static ThemeData legadoClaro() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
    );
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1788B8),
        brightness: Brightness.light,
        primary: const Color(0xFF1788B8),
        surface: Colors.white,
        error: const Color(0xFFD44747),
        onSurface: const Color(0xFF18212A),
        outline: const Color(0xFFC4D2DE),
      ),
      scaffoldBackgroundColor: const Color(0xFFEAF0F5),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF18212A),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFF18212A),
        displayColor: const Color(0xFF18212A),
      ),
    );
  }

  /// Paleta legada usada apenas pelo modo amplo preservado fora do mobile.
  static ThemeData legadoClaroComCores() => legadoClaro().copyWith(
    extensions: const <ThemeExtension<dynamic>>[CoresRadar.legadas()],
  );

  static ThemeData claro() {
    final cores = const CoresRadar.claras();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const ['Trebuchet MS', 'Arial', 'sans-serif'],
    );
    final esquema =
        ColorScheme.fromSeed(
          seedColor: cores.teal,
          brightness: Brightness.light,
          primary: cores.acao,
          onPrimary: Tokens.actionInk,
          secondary: cores.marca,
          onSecondary: cores.marcaTexto,
          surface: cores.superficie,
          onSurface: cores.texto,
          outline: cores.borda,
          error: cores.perigo,
        ).copyWith(
          surfaceContainerLowest: cores.superficie,
          surfaceContainerLow: cores.superficie,
          surfaceContainer: cores.superficieAlternativa,
          surfaceContainerHigh: cores.superficieAlternativa,
          surfaceContainerHighest: cores.superficieAlternativa,
          onSurfaceVariant: cores.textoSuave,
          outlineVariant: cores.borda,
          inverseSurface: cores.marca,
          onInverseSurface: cores.marcaTexto,
          inversePrimary: cores.acao,
        );
    return _baseComum(
      base,
      esquema,
      cores,
      preenchido: _botaoPreenchido(cores.acao, Tokens.actionInk),
      contornado: _botaoContornado(cores.texto, cores.borda),
    );
  }

  static ThemeData escuro() {
    final cores = const CoresRadar.escuras();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const ['Trebuchet MS', 'Arial', 'sans-serif'],
    );
    final esquema =
        ColorScheme.fromSeed(
          seedColor: cores.teal,
          brightness: Brightness.dark,
          primary: cores.acao,
          onPrimary: Tokens.actionInk,
          secondary: cores.marca,
          onSecondary: cores.marcaTexto,
          surface: cores.superficie,
          onSurface: cores.texto,
          outline: cores.borda,
          error: cores.perigo,
        ).copyWith(
          surfaceContainerLowest: cores.canvas,
          surfaceContainerLow: cores.superficie,
          surfaceContainer: cores.superficieAlternativa,
          surfaceContainerHigh: cores.superficieAlternativa,
          surfaceContainerHighest: cores.superficieAlternativa,
          onSurfaceVariant: cores.textoSuave,
          outlineVariant: cores.borda,
          inverseSurface: cores.texto,
          onInverseSurface: cores.canvas,
          inversePrimary: cores.acao,
        );
    return _baseComum(
      base,
      esquema,
      cores,
      preenchido: _botaoPreenchido(cores.acao, Tokens.actionInk),
      contornado: _botaoContornado(cores.texto, cores.borda),
    );
  }

  static ThemeData _baseComum(
    ThemeData base,
    ColorScheme esquema,
    CoresRadar cores, {
    required FilledButtonThemeData preenchido,
    required OutlinedButtonThemeData contornado,
  }) {
    final texto = base.textTheme.apply(
      bodyColor: cores.texto,
      displayColor: cores.texto,
    );
    final textoDelta = texto.copyWith(
      displayLarge: texto.displayLarge?.copyWith(
        fontFamily: 'Trebuchet MS',
        fontWeight: FontWeight.w900,
        letterSpacing: -2.4,
      ),
      displayMedium: texto.displayMedium?.copyWith(
        fontFamily: 'Trebuchet MS',
        fontWeight: FontWeight.w900,
        letterSpacing: -1.8,
      ),
      headlineLarge: texto.headlineLarge?.copyWith(
        fontFamily: 'Trebuchet MS',
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
      ),
      headlineMedium: texto.headlineMedium?.copyWith(
        fontFamily: 'Trebuchet MS',
        fontWeight: FontWeight.w900,
        letterSpacing: -0.9,
      ),
      titleLarge: texto.titleLarge?.copyWith(
        fontFamily: 'Trebuchet MS',
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
      titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      labelLarge: texto.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    );
    return base.copyWith(
      colorScheme: esquema,
      scaffoldBackgroundColor: cores.canvas,
      canvasColor: cores.canvas,
      cardColor: cores.superficie,
      dividerColor: cores.borda,
      extensions: <ThemeExtension<dynamic>>[
        AppTokens(
          colors: cores,
          spacing: const AppSpacing.delta(),
          radii: const AppRadii.delta(),
          motion: const AppMotion.delta(),
        ),
        cores,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: cores.canvas,
        foregroundColor: cores.texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cores.marca,
        indicatorColor: Tokens.mark,
        iconTheme: WidgetStateProperty.resolveWith((estados) {
          return IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? Tokens.markInk
                : cores.textoSuave,
          );
        }),
      ),
      inputDecorationTheme: _campos(cores),
      cardTheme: CardThemeData(
        color: cores.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RaioRadar.grande),
          side: BorderSide(color: cores.borda),
        ),
      ),
      filledButtonTheme: preenchido,
      outlinedButtonTheme: contornado,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cores.teal,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RaioRadar.pequeno),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cores.superficie,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: cores.superficie,
        modalBarrierColor: cores.marca.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RaioRadar.destaque),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: cores.superficie,
        selectedColor: cores.teal.withValues(alpha: 0.16),
        side: BorderSide(color: cores.borda),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: cores.texto, fontWeight: FontWeight.w700),
      ),
      textTheme: textoDelta,
    );
  }

  static InputDecorationTheme _campos(CoresRadar cores) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(RaioRadar.pequeno),
      borderSide: BorderSide(color: cores.borda),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: cores.superficie,
      hintStyle: TextStyle(color: cores.textoSuave),
      labelStyle: TextStyle(color: cores.texto, fontWeight: FontWeight.w700),
      contentPadding: EdgeInsets.symmetric(
        horizontal: const AppSpacing.delta().four,
        vertical: const AppSpacing.delta().three,
      ),
      border: borda,
      enabledBorder: borda,
      focusedBorder: borda.copyWith(
        borderSide: BorderSide(color: cores.teal, width: 2),
      ),
    );
  }

  static FilledButtonThemeData _botaoPreenchido(
    Color fundo,
    Color primeiroPlano,
  ) => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: fundo,
      foregroundColor: primeiroPlano,
      minimumSize: const Size(48, 50),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaioRadar.pequeno),
      ),
      elevation: 0,
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );

  static OutlinedButtonThemeData _botaoContornado(
    Color primeiroPlano,
    Color linha,
  ) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primeiroPlano,
      minimumSize: const Size(48, 50),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
      side: BorderSide(color: linha),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaioRadar.pequeno),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}
