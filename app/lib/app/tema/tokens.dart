import 'package:flutter/material.dart';

/// Tokens de cor do Radar de Benefícios.
///
/// Fonte visual do redesign mobile: `design-app/prototipo-mobile.html`.
/// Não altere estes valores para "aproximar" uma tela isolada: ajuste primeiro
/// o protótipo/UI_SPEC quando a direção visual mudar de propósito.
abstract final class Tokens {
  // Marca e superfícies institucionais.
  static const Color marcaProfunda = Color(0xFF081A2D); // --marca-950
  static const Color marca = Color(0xFF102A43); // --marca-900
  static const Color marcaMedia = Color(0xFF163B5C); // --marca-800
  static const Color marcaClara = Color(0xFF1769AA); // --acao

  // Ação e integração.
  static const Color acaoFundo = Color(0xFFDCEEFF);
  static const Color ciano = Color(0xFF25B8D8);
  static const Color cianoFundo = Color(0xFFDEF8FD);

  // Ganho/sucesso — cashback, economia, meta atingida. Nunca para ação neutra.
  static const Color ganho = Color(0xFF16803C);
  static const Color ganhoFundo = Color(0xFFDCFCE7);

  // Atenção — dado envelhecendo.
  static const Color atencao = Color(0xFF8B5A12);
  static const Color atencaoFundo = Color(0xFFFFF2D7);

  // Erro e zona de perigo.
  static const Color perigo = Color(0xFFC53030);

  // Texto e superfícies claras da direção mobile.
  static const Color texto = Color(0xFF102A43);
  static const Color textoSuave = Color(0xFF607487);
  static const Color fundo = Color(0xFFF3F7FB);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color superficieAlternativa = Color(0xFFEDF3F8);
  static const Color borda = Color(0xFFDCE6EE);

  // Contrapartes escuras extraídas do protótipo.
  static const Color textoEscuro = Color(0xFFEDF7FF);
  static const Color textoSuaveEscuro = Color(0xFF9FB3C5);
  static const Color fundoEscuro = Color(0xFF06111E);
  static const Color superficieEscura = Color(0xFF0D2032);
  static const Color superficieAlternativaEscura = Color(0xFF132B40);
  static const Color bordaEscura = Color(0x24BED9EE);
  static const Color acaoFundoEscuro = Color(0xFF173B56);
  static const Color cianoFundoEscuro = Color(0xFF103A47);
  static const Color ganhoFundoEscuro = Color(0xFF113A27);
  static const Color ganhoEscuro = Color(0xFF65D98B);
  static const Color atencaoFundoEscuro = Color(0xFF402F14);
  static const Color atencaoEscuro = Color(0xFFFFD17A);

  // O HTML não redefine estes tokens no escuro.
  static const Color acaoEscura = marcaClara;
  static const Color perigoEscuro = perigo;
}

/// Escala estrutural para evitar números mágicos espalhados pelo redesign.
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
  static const double medio = 14;
  static const double grande = 18;
  static const double destaque = 24;
  static const double pilula = 999;
}

abstract final class SombraRadar {
  static const BoxShadow clara = BoxShadow(
    color: Color(0x1A081A2D),
    blurRadius: 40,
    offset: Offset(0, 16),
  );

  static const BoxShadow escura = BoxShadow(
    color: Color(0x45000000),
    blurRadius: 42,
    offset: Offset(0, 18),
  );

  static BoxShadow para(Brightness brilho) =>
      brilho == Brightness.dark ? escura : clara;
}

/// Cores semânticas que mudam junto do tema sem alterar o significado.
@immutable
class CoresRadar extends ThemeExtension<CoresRadar> {
  const CoresRadar({
    required this.acao,
    required this.integracaoInter,
    required this.ganho,
    required this.atencao,
    required this.perigo,
    required this.textoSuave,
    required this.superficieAlternativa,
    required this.borda,
  });

  const CoresRadar.claras()
    : acao = Tokens.marcaClara,
      integracaoInter = Tokens.ciano,
      ganho = Tokens.ganho,
      atencao = Tokens.atencao,
      perigo = Tokens.perigo,
      textoSuave = Tokens.textoSuave,
      superficieAlternativa = Tokens.superficieAlternativa,
      borda = Tokens.borda;

  const CoresRadar.escuras()
    : acao = Tokens.acaoEscura,
      integracaoInter = Tokens.ciano,
      ganho = Tokens.ganhoEscuro,
      atencao = Tokens.atencaoEscuro,
      perigo = Tokens.perigoEscuro,
      textoSuave = Tokens.textoSuaveEscuro,
      superficieAlternativa = Tokens.superficieAlternativaEscura,
      borda = Tokens.bordaEscura;

  /// Paleta anterior preservada no Web e em layouts amplos durante a migração.
  const CoresRadar.legadas()
    : acao = Tokens.marcaClara,
      integracaoInter = const Color(0xFF087E8B),
      ganho = Tokens.ganho,
      atencao = Tokens.atencao,
      perigo = Tokens.perigo,
      textoSuave = const Color(0xFF60758A),
      superficieAlternativa = const Color(0xFFF0F4F7),
      borda = Tokens.borda;

  final Color acao;
  final Color integracaoInter;
  final Color ganho;
  final Color atencao;
  final Color perigo;
  final Color textoSuave;
  final Color superficieAlternativa;
  final Color borda;

  static CoresRadar de(BuildContext context) =>
      Theme.of(context).extension<CoresRadar>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? const CoresRadar.escuras()
          : const CoresRadar.claras());

  @override
  CoresRadar copyWith({
    Color? acao,
    Color? integracaoInter,
    Color? ganho,
    Color? atencao,
    Color? perigo,
    Color? textoSuave,
    Color? superficieAlternativa,
    Color? borda,
  }) => CoresRadar(
    acao: acao ?? this.acao,
    integracaoInter: integracaoInter ?? this.integracaoInter,
    ganho: ganho ?? this.ganho,
    atencao: atencao ?? this.atencao,
    perigo: perigo ?? this.perigo,
    textoSuave: textoSuave ?? this.textoSuave,
    superficieAlternativa: superficieAlternativa ?? this.superficieAlternativa,
    borda: borda ?? this.borda,
  );

  @override
  CoresRadar lerp(covariant CoresRadar? other, double t) {
    if (other == null) return this;
    return CoresRadar(
      acao: Color.lerp(acao, other.acao, t)!,
      integracaoInter: Color.lerp(integracaoInter, other.integracaoInter, t)!,
      ganho: Color.lerp(ganho, other.ganho, t)!,
      atencao: Color.lerp(atencao, other.atencao, t)!,
      perigo: Color.lerp(perigo, other.perigo, t)!,
      textoSuave: Color.lerp(textoSuave, other.textoSuave, t)!,
      superficieAlternativa: Color.lerp(
        superficieAlternativa,
        other.superficieAlternativa,
        t,
      )!,
      borda: Color.lerp(borda, other.borda, t)!,
    );
  }
}
