import 'package:flutter/material.dart';

/// Primitivos e aliases semânticos da identidade mobile V15.
///
/// Os aliases que ainda aparecem nas features preservam o contrato de código
/// enquanto cada domínio é migrado. Eles apontam para a mesma paleta V15; não
/// representam identidades de Livelo, Inter ou Pichau.
abstract final class Tokens {
  static const Color canvas = Color(0xFFF6F4F0);
  static const Color paper = Color(0xFFFFFDF9);
  static const Color paperSoft = Color(0xFFEEEAE4);
  static const Color paperStrong = Color(0xFFE5DFD7);
  static const Color ink = Color(0xFF282629);
  static const Color inkSoft = Color(0xFF4E4843);
  static const Color muted = Color(0xFF70675F);
  static const Color line = Color(0xFFD9D1C8);
  static const Color outline = Color(0xFF8A7A6D);
  static const Color action = Color(0xFFB6421E);
  static const Color actionStrong = Color(0xFF8F3416);
  static const Color actionSoft = Color(0xFFFBE6D9);
  static const Color actionInk = Color(0xFFFFF8F3);
  static const Color actionInkDark = Color(0xFF481B09);
  static const Color mark = action;
  static const Color markInk = actionInk;
  static const Color teal = Color(0xFF236347);
  static const Color focus = Color(0xFF835B16);
  static const Color danger = Color(0xFFAF303A);
  static const Color dangerSoft = Color(0xFFFBE4E5);
  static const Color successSoft = Color(0xFFE1EEE5);

  static const Color marca = ink;
  static const Color acaoFundo = actionSoft;
  static const Color ganho = teal;
  static const Color ganhoFundo = successSoft;
  static const Color atencao = focus;
  static const Color atencaoFundo = Color(0xFFF9EDCE);
  static const Color perigo = danger;
  static const Color texto = ink;
  static const Color textoSuave = muted;
  static const Color textoSutil = muted;
  static const Color pagina = canvas;
  static const Color fundo = canvas;
  static const Color superficie = paper;
  static const Color superficieAlternativa = paperSoft;
  static const Color superficieForte = ink;
  static const Color borda = line;

  static const Color textoEscuro = Color(0xFFF6F0E9);
  static const Color textoSuaveEscuro = Color(0xFFBFB7AE);
  static const Color textoSutilEscuro = Color(0xFFBFB7AE);
  static const Color paginaEscura = Color(0xFF222225);
  static const Color fundoEscuro = Color(0xFF222225);
  static const Color superficieEscura = Color(0xFF2B2B2E);
  static const Color superficieAlternativaEscura = Color(0xFF333337);
  static const Color superficieForteEscura = Color(0xFF414145);
  static const Color bordaEscura = Color(0xFF494747);
  static const Color acaoFundoEscuro = Color(0xFF4B3027);
  static const Color ganhoFundoEscuro = Color(0xFF2C4034);
  static const Color ganhoEscuro = Color(0xFFA1DAB8);
  static const Color atencaoFundoEscuro = Color(0xFF473D2B);
  static const Color atencaoEscuro = Color(0xFFEFCF89);
  static const Color acaoEscura = Color(0xFFFFAC86);
  static const Color acaoForteEscura = Color(0xFFFFC09F);
  static const Color marcaEscura = Color(0xFFF6F0E9);
  static const Color perigoEscuro = Color(0xFFFFADB2);
}

abstract final class EspacamentoRadar {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class RaioRadar {
  static const double pequeno = 10;
  static const double medio = 18;
  static const double grande = 18;
  static const double destaque = 26;
  static const double pilula = 999;
}

@immutable
class SombraRadar {
  const SombraRadar._();

  static const BoxShadow clara = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static const BoxShadow escura = BoxShadow(
    color: Color(0x30000000),
    blurRadius: 18,
    offset: Offset(0, 5),
  );

  static BoxShadow para(Brightness brilho) =>
      brilho == Brightness.dark ? escura : clara;
}

@immutable
class CoresRadar extends ThemeExtension<CoresRadar> {
  const CoresRadar({
    required this.marca,
    required this.acao,
    required this.ganho,
    required this.atencao,
    required this.perigo,
    required this.textoSuave,
    required this.superficieAlternativa,
    required this.borda,
    required this.canvas,
    required this.superficie,
    required this.texto,
    required this.teal,
    required this.marcaTexto,
    required this.perigoFundo,
  });

  const CoresRadar.claras()
    : marca = Tokens.ink,
      acao = Tokens.action,
      ganho = Tokens.teal,
      atencao = Tokens.focus,
      perigo = Tokens.danger,
      textoSuave = Tokens.muted,
      superficieAlternativa = Tokens.paperSoft,
      borda = Tokens.line,
      canvas = Tokens.canvas,
      superficie = Tokens.paper,
      texto = Tokens.ink,
      teal = Tokens.teal,
      marcaTexto = Tokens.actionInk,
      perigoFundo = Tokens.dangerSoft;

  const CoresRadar.escuras()
    : marca = Tokens.superficieEscura,
      acao = Tokens.acaoEscura,
      ganho = Tokens.ganhoEscuro,
      atencao = Tokens.atencaoEscuro,
      perigo = Tokens.perigoEscuro,
      textoSuave = Tokens.textoSuaveEscuro,
      superficieAlternativa = Tokens.superficieAlternativaEscura,
      borda = Tokens.bordaEscura,
      canvas = Tokens.fundoEscuro,
      superficie = Tokens.superficieEscura,
      texto = Tokens.textoEscuro,
      teal = Tokens.ganhoEscuro,
      marcaTexto = Tokens.actionInkDark,
      perigoFundo = Tokens.acaoFundoEscuro;

  final Color acao;
  final Color marca;
  final Color ganho;
  final Color atencao;
  final Color perigo;
  final Color textoSuave;
  final Color superficieAlternativa;
  final Color borda;
  final Color canvas;
  final Color superficie;
  final Color texto;
  final Color teal;
  final Color marcaTexto;
  final Color perigoFundo;

  static CoresRadar de(BuildContext context) =>
      Theme.of(context).extension<CoresRadar>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? const CoresRadar.escuras()
          : const CoresRadar.claras());

  @override
  CoresRadar copyWith({
    Color? marca,
    Color? acao,
    Color? ganho,
    Color? atencao,
    Color? perigo,
    Color? textoSuave,
    Color? superficieAlternativa,
    Color? borda,
    Color? canvas,
    Color? superficie,
    Color? texto,
    Color? teal,
    Color? marcaTexto,
    Color? perigoFundo,
  }) => CoresRadar(
    marca: marca ?? this.marca,
    acao: acao ?? this.acao,
    ganho: ganho ?? this.ganho,
    atencao: atencao ?? this.atencao,
    perigo: perigo ?? this.perigo,
    textoSuave: textoSuave ?? this.textoSuave,
    superficieAlternativa: superficieAlternativa ?? this.superficieAlternativa,
    borda: borda ?? this.borda,
    canvas: canvas ?? this.canvas,
    superficie: superficie ?? this.superficie,
    texto: texto ?? this.texto,
    teal: teal ?? this.teal,
    marcaTexto: marcaTexto ?? this.marcaTexto,
    perigoFundo: perigoFundo ?? this.perigoFundo,
  );

  @override
  CoresRadar lerp(covariant CoresRadar? other, double t) {
    if (other == null) return this;
    Color mistura(Color a, Color b) => Color.lerp(a, b, t)!;
    return CoresRadar(
      marca: mistura(marca, other.marca),
      acao: mistura(acao, other.acao),
      ganho: mistura(ganho, other.ganho),
      atencao: mistura(atencao, other.atencao),
      perigo: mistura(perigo, other.perigo),
      textoSuave: mistura(textoSuave, other.textoSuave),
      superficieAlternativa: mistura(
        superficieAlternativa,
        other.superficieAlternativa,
      ),
      borda: mistura(borda, other.borda),
      canvas: mistura(canvas, other.canvas),
      superficie: mistura(superficie, other.superficie),
      texto: mistura(texto, other.texto),
      teal: mistura(teal, other.teal),
      marcaTexto: mistura(marcaTexto, other.marcaTexto),
      perigoFundo: mistura(perigoFundo, other.perigoFundo),
    );
  }
}

@immutable
class AppSpacing {
  const AppSpacing({
    required this.one,
    required this.two,
    required this.three,
    required this.four,
    required this.five,
    required this.six,
    required this.seven,
    required this.eight,
    required this.nine,
    required this.ten,
  });

  const AppSpacing.v15()
    : one = 4,
      two = 8,
      three = 12,
      four = 16,
      five = 20,
      six = 24,
      seven = 32,
      eight = 40,
      nine = 48,
      ten = 64;

  final double one;
  final double two;
  final double three;
  final double four;
  final double five;
  final double six;
  final double seven;
  final double eight;
  final double nine;
  final double ten;
}

@immutable
class AppRadii {
  const AppRadii({
    required this.md,
    required this.lg,
    required this.xl,
    required this.pill,
  });

  const AppRadii.v15() : md = 10, lg = 18, xl = 26, pill = 999;

  final double md;
  final double lg;
  final double xl;
  final double pill;
}

@immutable
class AppSizes {
  const AppSizes({
    required this.touchTarget,
    required this.field,
    required this.icon,
    required this.badge,
    required this.brandWidth,
    required this.brandHeight,
    required this.compactRailWidth,
    required this.compactRailHeight,
    required this.illustrationWidth,
    required this.illustrationHeight,
    required this.sheetHandleWidth,
    required this.sheetHandleHeight,
  });

  const AppSizes.v15()
    : touchTarget = 48,
      field = 48,
      icon = 24,
      badge = 24,
      brandWidth = 104,
      brandHeight = 30,
      compactRailWidth = 148,
      compactRailHeight = 120,
      illustrationWidth = 96,
      illustrationHeight = 72,
      sheetHandleWidth = 40,
      sheetHandleHeight = 4;

  final double touchTarget;
  final double field;
  final double icon;
  final double badge;
  final double brandWidth;
  final double brandHeight;
  final double compactRailWidth;
  final double compactRailHeight;
  final double illustrationWidth;
  final double illustrationHeight;
  final double sheetHandleWidth;
  final double sheetHandleHeight;
}

@immutable
class AppMotion {
  const AppMotion({
    required this.fast,
    required this.standard,
    required this.slow,
    required this.splash,
  });

  const AppMotion.v15()
    : fast = const Duration(milliseconds: 110),
      standard = const Duration(milliseconds: 180),
      slow = const Duration(milliseconds: 300),
      splash = const Duration(milliseconds: 1600);

  final Duration fast;
  final Duration standard;
  final Duration slow;
  final Duration splash;

  Duration forReducedMotion(Duration normal, bool reduce) =>
      reduce ? const Duration(milliseconds: 1) : normal;
}

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.colors,
    required this.spacing,
    required this.radii,
    required this.sizes,
    required this.motion,
  });

  const AppTokens.claro()
    : colors = const CoresRadar.claras(),
      spacing = const AppSpacing.v15(),
      radii = const AppRadii.v15(),
      sizes = const AppSizes.v15(),
      motion = const AppMotion.v15();

  const AppTokens.escuro()
    : colors = const CoresRadar.escuras(),
      spacing = const AppSpacing.v15(),
      radii = const AppRadii.v15(),
      sizes = const AppSizes.v15(),
      motion = const AppMotion.v15();

  final CoresRadar colors;
  final AppSpacing spacing;
  final AppRadii radii;
  final AppSizes sizes;
  final AppMotion motion;

  static AppTokens de(BuildContext context) =>
      Theme.of(context).extension<AppTokens>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? const AppTokens.escuro()
          : const AppTokens.claro());

  @override
  AppTokens copyWith({
    CoresRadar? colors,
    AppSpacing? spacing,
    AppRadii? radii,
    AppSizes? sizes,
    AppMotion? motion,
  }) => AppTokens(
    colors: colors ?? this.colors,
    spacing: spacing ?? this.spacing,
    radii: radii ?? this.radii,
    sizes: sizes ?? this.sizes,
    motion: motion ?? this.motion,
  );

  @override
  AppTokens lerp(covariant AppTokens? other, double t) => this;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => AppTokens.de(this);
}
