import 'package:flutter/material.dart';

import 'tokens.dart';

/// Temas do Radar com a mesma identidade e sem misturar ação com ganho.
abstract final class TemaRadar {
  /// O login compacto usa o mesmo contrato V11 do restante do aplicativo.
  static ThemeData loginLegado() => claro();

  /// Tema congelado de jornadas que não fazem parte do ciclo mobile.
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

  /// Tema amplo anterior com as cores semânticas usadas pelos widgets novos.
  static ThemeData legadoClaroComCores() => legadoClaro().copyWith(
    extensions: const <ThemeExtension<dynamic>>[CoresRadar.legadas()],
  );

  static ThemeData claro() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Aptos',
      fontFamilyFallback: const ['Segoe UI Variable', 'Segoe UI', 'sans-serif'],
    );
    final esquema = ColorScheme.fromSeed(
      seedColor: Tokens.plum,
      brightness: Brightness.light,
      primary: Tokens.action,
      onPrimary: Colors.white,
      secondary: Tokens.plum,
      onSecondary: Colors.white,
      surface: Tokens.paper,
      onSurface: Tokens.ink,
      outline: Tokens.line,
      error: Tokens.danger,
    ).copyWith(
      surfaceContainerLowest: Tokens.paper,
      surfaceContainerLow: Tokens.paper,
      surfaceContainer: Tokens.paperSoft,
      surfaceContainerHigh: Tokens.plumSoft,
      surfaceContainerHighest: Tokens.plumSoft,
    );
    return base.copyWith(
      colorScheme: esquema,
      scaffoldBackgroundColor: Tokens.canvas,
      cardColor: Tokens.paper,
      dividerColor: Tokens.line,
      extensions: const <ThemeExtension<dynamic>>[CoresRadar.claras()],
      appBarTheme: const AppBarTheme(
        backgroundColor: Tokens.canvas,
        foregroundColor: Tokens.ink,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Tokens.paper,
        indicatorColor: Tokens.plum,
        iconTheme: WidgetStateProperty.resolveWith((estados) {
          return IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? Colors.white
                : Tokens.muted,
          );
        }),
      ),
      inputDecorationTheme: _campos(
        paper: Tokens.paper,
        ink: Tokens.ink,
        muted: Tokens.muted,
        line: Tokens.line,
        action: Tokens.action,
      ),
      cardTheme: CardThemeData(
        color: Tokens.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RaioRadar.grande),
          side: const BorderSide(color: Tokens.line),
        ),
      ),
      filledButtonTheme: _botaoPreenchido(Tokens.action, Colors.white),
      outlinedButtonTheme: _botaoContornado(Tokens.ink, Tokens.line),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Tokens.actionStrong,
          minimumSize: const Size(38, 38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RaioRadar.medio),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Tokens.paper,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Tokens.paper,
        modalBarrierColor: Color(0x7A1B121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Tokens.paper,
        selectedColor: Tokens.plum,
        side: const BorderSide(color: Tokens.line),
        shape: const StadiumBorder(),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Tokens.ink,
        displayColor: Tokens.ink,
      ),
    );
  }

  static ThemeData escuro() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Aptos',
      fontFamilyFallback: const ['Segoe UI Variable', 'Segoe UI', 'sans-serif'],
    );
    final esquema = ColorScheme.fromSeed(
      seedColor: Tokens.marcaEscura,
      brightness: Brightness.dark,
      primary: Tokens.acaoEscura,
      onPrimary: const Color(0xFF291A2F),
      secondary: Tokens.marcaEscura,
      onSecondary: const Color(0xFF291A2F),
      surface: Tokens.superficieEscura,
      error: Tokens.perigoEscuro,
      onSurface: Tokens.textoEscuro,
      outline: Tokens.bordaEscura,
    ).copyWith(
      surfaceContainerLowest: Tokens.superficieEscura,
      surfaceContainerLow: Tokens.superficieEscura,
      surfaceContainer: Tokens.superficieAlternativaEscura,
      surfaceContainerHigh: Tokens.superficieForteEscura,
      surfaceContainerHighest: Tokens.superficieForteEscura,
    );
    return base.copyWith(
      colorScheme: esquema,
      scaffoldBackgroundColor: Tokens.fundoEscuro,
      cardColor: Tokens.superficieEscura,
      dividerColor: Tokens.bordaEscura,
      extensions: const <ThemeExtension<dynamic>>[CoresRadar.escuras()],
      appBarTheme: const AppBarTheme(
        backgroundColor: Tokens.fundoEscuro,
        foregroundColor: Tokens.textoEscuro,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Tokens.superficieEscura,
        indicatorColor: Tokens.marcaEscura,
        iconTheme: WidgetStateProperty.resolveWith((estados) {
          return IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? const Color(0xFF291A2F)
                : Tokens.textoSuaveEscuro,
          );
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Tokens.fundoEscuro,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: _campos(
        paper: Tokens.superficieEscura,
        ink: Tokens.textoEscuro,
        muted: Tokens.textoSuaveEscuro,
        line: Tokens.bordaEscura,
        action: Tokens.acaoEscura,
      ),
      cardTheme: CardThemeData(
        color: Tokens.superficieEscura,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RaioRadar.grande),
          side: const BorderSide(color: Tokens.bordaEscura),
        ),
      ),
      filledButtonTheme: _botaoPreenchido(
        Tokens.acaoEscura,
        const Color(0xFF291A2F),
      ),
      outlinedButtonTheme: _botaoContornado(
        Tokens.textoEscuro,
        Tokens.bordaEscura,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Tokens.acaoForteEscura,
          minimumSize: const Size(38, 38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RaioRadar.medio),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Tokens.superficieEscura,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Tokens.superficieEscura,
        modalBarrierColor: Color(0x991B121B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(27)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Tokens.superficieEscura,
        selectedColor: Tokens.marcaEscura,
        side: const BorderSide(color: Tokens.bordaEscura),
        shape: const StadiumBorder(),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Tokens.textoEscuro,
        displayColor: Tokens.textoEscuro,
      ),
    );
  }

  static InputDecorationTheme _campos({
    required Color paper,
    required Color ink,
    required Color muted,
    required Color line,
    required Color action,
  }) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: BorderSide(color: line),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: paper,
      hintStyle: TextStyle(color: muted),
      labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w700),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: borda,
      enabledBorder: borda,
      focusedBorder: borda.copyWith(
        borderSide: BorderSide(color: action, width: 1.7),
      ),
    );
  }

  static FilledButtonThemeData _botaoPreenchido(
    Color fundo,
    Color primeiroPlano,
  ) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: fundo,
        foregroundColor: primeiroPlano,
        minimumSize: const Size(46, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RaioRadar.medio),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  static OutlinedButtonThemeData _botaoContornado(
    Color primeiroPlano,
    Color linha,
  ) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primeiroPlano,
        minimumSize: const Size(46, 46),
        side: BorderSide(color: linha),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(RaioRadar.medio),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
