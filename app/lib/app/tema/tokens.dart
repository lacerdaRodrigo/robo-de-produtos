import 'package:flutter/material.dart';

/// Tokens de cor do Radar de Benefícios.
///
/// A fonte visual vigente é o protótipo Delta em
/// `design-app/prototipos/mobile-v12/`. Os aliases com nomes históricos ficam
/// aqui apenas durante a migração das features; novas telas devem preferir
/// [AppTokens] pelo contexto do tema.
abstract final class Tokens {
  // Delta claro.
  static const Color canvas = Color(0xFFEEF4F1);
  static const Color paper = Color(0xFFFFFEFA);
  static const Color paperSoft = Color(0xFFE0EBE7);
  static const Color ink = Color(0xFF17262A);
  static const Color inkSoft = Color(0xFF2D4448);
  static const Color muted = Color(0xFF66787A);
  static const Color line = Color(0xFFCAD9D4);
  static const Color action = Color(0xFFF26B52);
  static const Color actionStrong = Color(0xFFBD4638);
  static const Color actionSoft = Color(0xFFFFE4DC);
  static const Color actionInk = Color(0xFFFFFAF3);
  static const Color mark = Color(0xFFD9F35B);
  static const Color markInk = ink;
  static const Color teal = Color(0xFF317C78);
  static const Color focus = Color(0xFFB85B00);
  static const Color danger = Color(0xFFD93C58);
  static const Color dangerSoft = Color(0xFFFFE1E8);

  // Identidade semântica das fontes.
  static const Color fonteLivelo = Color(0xFFC39212);
  static const Color fonteCashback = Color(0xFF287F73);
  static const Color fonteProdutos = Color(0xFF7861BC);
  static const Color fontePichau = Color(0xFFED654C);

  // Nomes legados usados por algumas features que ainda estão sendo
  // migradas para a nomenclatura Delta.
  static const Color plum = ink;
  static const Color plumSoft = paperSoft;
  static const Color positive = ganho;
  static const Color positiveSoft = ganhoFundo;
  static const Color warning = atencao;
  static const Color warningSoft = atencaoFundo;

  // Aliases mantidos para o código de domínio durante a migração.
  static const Color marcaProfunda = ink;
  static const Color marca = ink;
  static const Color marcaMedia = actionStrong;
  static const Color marcaClara = action;
  static const Color acaoFundo = actionSoft;
  static const Color ciano = teal;
  static const Color cianoFundo = paperSoft;
  static const Color ganho = teal;
  static const Color ganhoFundo = Color(0xFFD8ECE6);
  static const Color atencao = focus;
  static const Color atencaoFundo = Color(0xFFFFE8C7);
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

  // Delta escuro.
  static const Color textoEscuro = Color(0xFFF4F7ED);
  static const Color textoSuaveEscuro = Color(0xFFA7B9B3);
  static const Color textoSutilEscuro = Color(0xFFA7B9B3);
  static const Color paginaEscura = Color(0xFF172123);
  static const Color fundoEscuro = Color(0xFF172123);
  static const Color superficieEscura = Color(0xFF223133);
  static const Color superficieAlternativaEscura = Color(0xFF2D4040);
  static const Color superficieForteEscura = Color(0xFF49615E);
  static const Color bordaEscura = Color(0xFF49615E);
  static const Color acaoFundoEscuro = Color(0xFF5A3040);
  static const Color cianoFundoEscuro = Color(0xFF2D4040);
  static const Color ganhoFundoEscuro = Color(0xFF294442);
  static const Color ganhoEscuro = Color(0xFF7EC8B7);
  static const Color atencaoFundoEscuro = Color(0xFF4E4020);
  static const Color atencaoEscuro = Color(0xFFFFD166);
  static const Color acaoEscura = Color(0xFFFF886F);
  static const Color acaoForteEscura = Color(0xFFFF886F);
  static const Color marcaEscura = Color(0xFFD9F35B);
  static const Color perigoEscuro = Color(0xFFFF7891);
  static const Color fonteLiveloEscura = Color(0xFFF2C94C);
  static const Color fonteCashbackEscura = Color(0xFF7EC8B7);
  static const Color fonteProdutosEscura = Color(0xFFB6A3FF);
  static const Color fontePichauEscura = Color(0xFFFF947C);
}

/// Escala compatível com os componentes históricos do app.
///
/// A escala Delta completa está em [AppSpacing]. Estes nomes permanecem para
/// que a migração possa acontecer por componente sem alterar regras de negócio.
abstract final class EspacamentoRadar {
  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 28;
}

abstract final class RaioRadar {
  static const double pequeno = 14;
  static const double medio = 14;
  static const double grande = 20;
  static const double destaque = 28;
  static const double pilula = 999;
}

@immutable
class SombraRadar {
  const SombraRadar._();

  static const BoxShadow clara = BoxShadow(
    color: Color(0x1417262A),
    blurRadius: 0,
    offset: Offset(8, 8),
  );

  static const BoxShadow escura = BoxShadow(
    color: Color(0x3D000000),
    blurRadius: 0,
    offset: Offset(8, 8),
  );

  static BoxShadow para(Brightness brilho) =>
      brilho == Brightness.dark ? escura : clara;
}

/// Cores semânticas que mudam junto do tema sem alterar seu significado.
@immutable
class CoresRadar extends ThemeExtension<CoresRadar> {
  const CoresRadar({
    required this.marca,
    required this.acao,
    required this.integracaoInter,
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
    required this.livelo,
    required this.cashback,
    required this.produtos,
    required this.pichau,
  });

  const CoresRadar.claras()
    : marca = Tokens.ink,
      acao = Tokens.action,
      integracaoInter = Tokens.teal,
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
      marcaTexto = Tokens.mark,
      perigoFundo = Tokens.dangerSoft,
      livelo = Tokens.fonteLivelo,
      cashback = Tokens.fonteCashback,
      produtos = Tokens.fonteProdutos,
      pichau = Tokens.fontePichau;

  const CoresRadar.escuras()
    : marca = Tokens.marcaEscura,
      acao = Tokens.acaoEscura,
      integracaoInter = Tokens.teal,
      ganho = Tokens.ganhoEscuro,
      atencao = Tokens.atencaoEscuro,
      perigo = Tokens.perigoEscuro,
      textoSuave = Tokens.textoSuaveEscuro,
      superficieAlternativa = Tokens.superficieAlternativaEscura,
      borda = Tokens.bordaEscura,
      canvas = Tokens.fundoEscuro,
      superficie = Tokens.superficieEscura,
      texto = Tokens.textoEscuro,
      teal = Tokens.teal,
      marcaTexto = Tokens.mark,
      perigoFundo = Tokens.acaoFundoEscuro,
      livelo = Tokens.fonteLiveloEscura,
      cashback = Tokens.fonteCashbackEscura,
      produtos = Tokens.fonteProdutosEscura,
      pichau = Tokens.fontePichauEscura;

  /// Paleta anterior preservada exclusivamente para o layout amplo fora do
  /// ciclo mobile. Não usar em novas telas Delta.
  const CoresRadar.legadas()
    : marca = const Color(0xFF1788B8),
      acao = const Color(0xFF1788B8),
      integracaoInter = const Color(0xFF087E8B),
      ganho = const Color(0xFF16835F),
      atencao = const Color(0xFF8B5A12),
      perigo = const Color(0xFFD44747),
      textoSuave = const Color(0xFF60758A),
      superficieAlternativa = const Color(0xFFF0F4F7),
      borda = const Color(0xFFC4D2DE),
      canvas = const Color(0xFFEAF0F5),
      superficie = Colors.white,
      texto = const Color(0xFF18212A),
      teal = const Color(0xFF087E8B),
      marcaTexto = Colors.white,
      perigoFundo = const Color(0xFFFFE1E1),
      livelo = const Color(0xFF8B6500),
      cashback = const Color(0xFF087E8B),
      produtos = const Color(0xFF5D4AA8),
      pichau = const Color(0xFFB7442C);

  final Color acao;
  final Color marca;
  final Color integracaoInter;
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
  final Color livelo;
  final Color cashback;
  final Color produtos;
  final Color pichau;

  static CoresRadar de(BuildContext context) =>
      Theme.of(context).extension<CoresRadar>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? const CoresRadar.escuras()
          : const CoresRadar.claras());

  @override
  CoresRadar copyWith({
    Color? marca,
    Color? acao,
    Color? integracaoInter,
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
    Color? livelo,
    Color? cashback,
    Color? produtos,
    Color? pichau,
  }) => CoresRadar(
    marca: marca ?? this.marca,
    acao: acao ?? this.acao,
    integracaoInter: integracaoInter ?? this.integracaoInter,
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
    livelo: livelo ?? this.livelo,
    cashback: cashback ?? this.cashback,
    produtos: produtos ?? this.produtos,
    pichau: pichau ?? this.pichau,
  );

  @override
  CoresRadar lerp(covariant CoresRadar? other, double t) {
    if (other == null) return this;
    Color mistura(Color a, Color b) => Color.lerp(a, b, t)!;
    return CoresRadar(
      marca: mistura(marca, other.marca),
      acao: mistura(acao, other.acao),
      integracaoInter: mistura(integracaoInter, other.integracaoInter),
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
      livelo: mistura(livelo, other.livelo),
      cashback: mistura(cashback, other.cashback),
      produtos: mistura(produtos, other.produtos),
      pichau: mistura(pichau, other.pichau),
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

  const AppSpacing.delta()
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
  const AppRadii({required this.md, required this.lg, required this.xl});

  const AppRadii.delta() : md = 14, lg = 20, xl = 28;

  final double md;
  final double lg;
  final double xl;
}

@immutable
class AppMotion {
  const AppMotion({
    required this.fast,
    required this.standard,
    required this.slow,
  });

  const AppMotion.delta()
    : fast = const Duration(milliseconds: 150),
      standard = const Duration(milliseconds: 240),
      slow = const Duration(milliseconds: 360);

  final Duration fast;
  final Duration standard;
  final Duration slow;

  Duration forReducedMotion(Duration normal, bool reduce) =>
      reduce ? const Duration(milliseconds: 1) : normal;
}

/// Contrato completo do sistema Delta disponível pelo tema.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.colors,
    required this.spacing,
    required this.radii,
    required this.motion,
  });

  const AppTokens.claro()
    : colors = const CoresRadar.claras(),
      spacing = const AppSpacing.delta(),
      radii = const AppRadii.delta(),
      motion = const AppMotion.delta();

  const AppTokens.escuro()
    : colors = const CoresRadar.escuras(),
      spacing = const AppSpacing.delta(),
      radii = const AppRadii.delta(),
      motion = const AppMotion.delta();

  final CoresRadar colors;
  final AppSpacing spacing;
  final AppRadii radii;
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
    AppMotion? motion,
  }) => AppTokens(
    colors: colors ?? this.colors,
    spacing: spacing ?? this.spacing,
    radii: radii ?? this.radii,
    motion: motion ?? this.motion,
  );

  @override
  AppTokens lerp(covariant AppTokens? other, double t) => this;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => AppTokens.de(this);
}
