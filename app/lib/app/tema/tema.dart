import 'package:flutter/material.dart';

import 'tokens.dart';

extension TipografiaOfertaV15 on TextTheme {
  TextStyle? get tituloOferta => titleMedium?.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: -0.45,
  );

  TextStyle? get precoOferta => headlineSmall?.copyWith(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

extension TipografiaInicioV15 on TextTheme {
  TextStyle? get sobrelinhaInicio => bodySmall?.copyWith(
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0,
  );

  TextStyle? get estadoInicio => bodySmall?.copyWith(height: 1.55);

  TextStyle? get tituloSecaoInicio => titleLarge?.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
  );
}

/// Material 3 da identidade Radar V15.
abstract final class TemaRadar {
  static ThemeData claro() =>
      _criar(brilho: Brightness.light, cores: const CoresRadar.claras());

  static ThemeData escuro() =>
      _criar(brilho: Brightness.dark, cores: const CoresRadar.escuras());

  static ThemeData _criar({
    required Brightness brilho,
    required CoresRadar cores,
  }) {
    const tamanhos = AppSizes.v15();
    final base = ThemeData(
      useMaterial3: true,
      brightness: brilho,
      fontFamily: 'Manrope',
      fontFamilyFallback: const ['Arial', 'sans-serif'],
    );
    final esquema =
        ColorScheme.fromSeed(
          seedColor: cores.acao,
          brightness: brilho,
          primary: cores.acao,
          onPrimary: cores.marcaTexto,
          secondary: cores.ganho,
          onSecondary: brilho == Brightness.dark
              ? Tokens.ink
              : Tokens.actionInk,
          surface: cores.superficie,
          onSurface: cores.texto,
          outline: Tokens.outline,
          error: cores.perigo,
        ).copyWith(
          surfaceContainerLowest: cores.canvas,
          surfaceContainerLow: cores.superficie,
          surfaceContainer: cores.superficieAlternativa,
          surfaceContainerHigh: cores.superficieAlternativa,
          surfaceContainerHighest: Tokens.paperStrong,
          onSurfaceVariant: cores.textoSuave,
          outlineVariant: cores.borda,
          primaryContainer: cores.acao.withValues(alpha: 0.14),
          onPrimaryContainer: cores.acao,
          secondaryContainer: cores.ganho.withValues(alpha: 0.14),
          onSecondaryContainer: cores.ganho,
          errorContainer: cores.perigoFundo,
          onErrorContainer: cores.perigo,
          inverseSurface: cores.texto,
          onInverseSurface: cores.canvas,
          inversePrimary: cores.acao,
        );
    final texto = base.textTheme.apply(
      bodyColor: cores.texto,
      displayColor: cores.texto,
      fontFamily: 'Manrope',
    );
    final tipografia = texto.copyWith(
      displayLarge: texto.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
      ),
      displayMedium: texto.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineLarge: texto.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.16,
        letterSpacing: -1.4,
      ),
      headlineMedium: texto.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: texto.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      bodyMedium: texto.bodyMedium?.copyWith(height: 1.4),
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
          spacing: const AppSpacing.v15(),
          radii: const AppRadii.v15(),
          sizes: tamanhos,
          motion: const AppMotion.v15(),
        ),
        cores,
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: cores.canvas,
        foregroundColor: cores.texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: tipografia.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: tamanhos.bottomNavigationHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: cores.superficie,
        indicatorColor: brilho == Brightness.dark
            ? Tokens.acaoFundoEscuro
            : Tokens.actionSoft,
        indicatorShape: const StadiumBorder(),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((estados) {
          final selecionado = estados.contains(WidgetState.selected);
          return tipografia.labelMedium?.copyWith(
            color: selecionado ? cores.acao : cores.textoSuave,
            fontWeight: FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((estados) {
          final selecionado = estados.contains(WidgetState.selected);
          return IconThemeData(
            color: selecionado ? cores.acao : cores.textoSuave,
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
          borderRadius: BorderRadius.circular(RaioRadar.medio),
          side: BorderSide(color: cores.borda),
        ),
      ),
      filledButtonTheme: _botaoPreenchido(cores.acao, cores.marcaTexto),
      outlinedButtonTheme: _botaoContornado(cores.texto, cores.borda),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cores.acao,
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
        modalBarrierColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(RaioRadar.destaque),
          ),
        ),
        showDragHandle: true,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: cores.superficie,
        selectedColor: cores.acao.withValues(alpha: 0.14),
        side: BorderSide(color: cores.borda),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(color: cores.texto, fontWeight: FontWeight.w700),
      ),
      textTheme: tipografia,
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
      labelStyle: TextStyle(color: cores.texto, fontWeight: FontWeight.w600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: borda,
      enabledBorder: borda,
      focusedBorder: borda.copyWith(
        borderSide: BorderSide(color: cores.acao, width: 2),
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
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaioRadar.pequeno),
      ),
      elevation: 0,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );

  static OutlinedButtonThemeData _botaoContornado(
    Color primeiroPlano,
    Color linha,
  ) => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primeiroPlano,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      side: BorderSide(color: linha),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RaioRadar.pequeno),
      ),
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
