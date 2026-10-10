import 'package:flutter/material.dart';

import 'ds_cores.dart';
import 'ds_medidas.dart';
import 'ds_tipo.dart';

/// Monta o `ThemeData` Material 3 a partir dos tokens do Radar DS.
///
/// Uso: `MaterialApp(theme: DsTema.claro(), darkTheme: DsTema.escuro())`.
/// Widgets Material comuns (TextField, Switch, SnackBar…) herdam o visual
/// do DS sem estilização local.
abstract final class DsTema {
  static ThemeData claro() => _montar(DsCores.claro, Brightness.light);
  static ThemeData escuro() => _montar(DsCores.escuro, Brightness.dark);

  static ThemeData _montar(DsCores c, Brightness brilho) {
    final tipo = DsTipo.de(c);
    final esquema = ColorScheme(
      brightness: brilho,
      primary: c.primaria,
      onPrimary: c.sobrePrimaria,
      primaryContainer: c.primariaSuave,
      onPrimaryContainer: c.primariaForte,
      secondary: c.primaria,
      onSecondary: c.sobrePrimaria,
      secondaryContainer: c.primariaSuave,
      onSecondaryContainer: c.primariaForte,
      tertiary: c.sinal,
      onTertiary: c.sobreSinal,
      error: c.perigo,
      onError: c.superficie1,
      errorContainer: c.perigoSuave,
      onErrorContainer: c.perigo,
      surface: c.superficie1,
      onSurface: c.texto1,
      onSurfaceVariant: c.texto2,
      surfaceContainerLowest: c.fundoApp,
      surfaceContainerLow: c.superficie1,
      surfaceContainer: c.superficie2,
      surfaceContainerHigh: c.superficie2,
      surfaceContainerHighest: c.superficie3,
      outline: c.borda2,
      outlineVariant: c.borda1,
      scrim: c.scrim,
      shadow: const Color(0xFF000000),
      inverseSurface: c.texto1,
      onInverseSurface: c.fundoApp,
      inversePrimary: c.primariaSuave,
    );

    final raioSm = BorderRadius.circular(DsRaio.sm);
    final textTheme = TextTheme(
      displaySmall: tipo.display,
      headlineSmall: tipo.tituloTela,
      titleLarge: tipo.tituloSecao,
      titleMedium: tipo.tituloItem,
      bodyLarge: tipo.corpo,
      bodyMedium: tipo.corpo.copyWith(fontSize: 14, height: 20 / 14),
      bodySmall: tipo.apoio,
      labelLarge: tipo.rotulo.copyWith(fontSize: 14),
      labelMedium: tipo.rotulo,
      labelSmall: tipo.apoio,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brilho,
      colorScheme: esquema,
      fontFamily: DsTipo.familia,
      scaffoldBackgroundColor: c.fundoApp,
      canvasColor: c.fundoApp,
      textTheme: textTheme,
      dividerTheme: DividerThemeData(color: c.borda1, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: c.texto1, size: 24),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.fundoApp,
        foregroundColor: c.texto1,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: tipo.tituloSecao,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.superficie1,
        hintStyle: tipo.corpo.copyWith(color: c.texto2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DsEspaco.e4,
          vertical: DsEspaco.e3,
        ),
        border: OutlineInputBorder(
          borderRadius: raioSm,
          borderSide: BorderSide(color: c.borda2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: raioSm,
          borderSide: BorderSide(color: c.borda2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: raioSm,
          borderSide: BorderSide(color: c.primaria, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: raioSm,
          borderSide: BorderSide(color: c.perigo),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, DsEspaco.alvoToque),
          shape: RoundedRectangleBorder(borderRadius: raioSm),
          textStyle: tipo.rotulo.copyWith(fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, DsEspaco.alvoToque),
          foregroundColor: c.texto1,
          side: BorderSide(color: c.borda2),
          shape: RoundedRectangleBorder(borderRadius: raioSm),
          textStyle: tipo.rotulo.copyWith(fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, DsEspaco.alvoToque),
          foregroundColor: c.primaria,
          shape: RoundedRectangleBorder(borderRadius: raioSm),
          textStyle: tipo.rotulo.copyWith(fontSize: 14),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.superficie1,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: c.scrim,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DsRaio.lg)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.texto1,
        contentTextStyle: tipo.rotulo.copyWith(color: c.fundoApp, fontSize: 14),
        actionTextColor: c.primariaSuave,
        shape: RoundedRectangleBorder(borderRadius: raioSm),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.superficie1,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primariaSuave,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => tipo.apoio.copyWith(
            fontWeight: FontWeight.w600,
            color: estados.contains(WidgetState.selected) ? c.texto1 : c.texto2,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (estados) => IconThemeData(
            color: estados.contains(WidgetState.selected)
                ? c.primariaForte
                : c.texto2,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (e) => e.contains(WidgetState.selected) ? c.sobrePrimaria : c.borda2,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (e) => e.contains(WidgetState.selected) ? c.primaria : c.superficie2,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primaria),
      extensions: <ThemeExtension<dynamic>>[c, tipo],
    );
  }
}

/// Atalhos: `context.cores`, `context.tipo`, `context.movimentoReduzido`.
extension DsContexto on BuildContext {
  DsCores get cores =>
      Theme.of(this).extension<DsCores>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? DsCores.escuro
          : DsCores.claro);

  DsTipo get tipo => Theme.of(this).extension<DsTipo>() ?? DsTipo.de(cores);

  bool get movimentoReduzido => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
