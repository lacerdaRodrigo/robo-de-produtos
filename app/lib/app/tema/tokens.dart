import 'package:flutter/material.dart';

/// Tokens de cor do Radar de Benefícios.
///
/// Fonte visual: `design-app/prototipo-mobile-redesign-novo-11.html`.
/// Contrato: `design-app/SISTEMA-DESIGN-MOBILE-V11.md`.
/// Não altere estes valores para "aproximar" uma tela isolada: ajuste primeiro
/// o protótipo e o sistema de design quando a direção visual mudar de propósito.
abstract final class Tokens {
  // Contrato V11 — tema claro.
  static const Color canvas = Color(0xFFF4EEE5);
  static const Color paper = Color(0xFFFFFDF8);
  static const Color paperSoft = Color(0xFFFAF5ED);
  static const Color ink = Color(0xFF291A2F);
  static const Color muted = Color(0xFF756B76);
  static const Color line = Color(0xFFE4D8CA);
  static const Color action = Color(0xFFE76043);
  static const Color actionStrong = Color(0xFFBA3B26);
  static const Color actionSoft = Color(0xFFFEE4DC);
  static const Color plum = Color(0xFF4C2E59);
  static const Color plumSoft = Color(0xFFEEE3F2);
  static const Color positive = Color(0xFF28745A);
  static const Color positiveSoft = Color(0xFFDCEEE4);
  static const Color warning = Color(0xFF8A5D12);
  static const Color warningSoft = Color(0xFFFBEBBF);
  static const Color danger = Color(0xFFAF3544);

  // Aliases mantidos para os widgets existentes durante a migração visual.
  static const Color marcaProfunda = ink;
  static const Color marca = plum;
  static const Color marcaMedia = actionStrong;
  static const Color marcaClara = action;
  static const Color acaoFundo = actionSoft;
  static const Color ciano = plum;
  static const Color cianoFundo = plumSoft;

  // Ganho/sucesso — cashback, economia, meta atingida. Nunca para ação neutra.
  static const Color ganho = positive;
  static const Color ganhoFundo = positiveSoft;

  // Atenção — dado envelhecendo.
  static const Color atencao = warning;
  static const Color atencaoFundo = warningSoft;

  // Erro e zona de perigo.
  static const Color perigo = danger;

  // Texto e superfícies claras da direção mobile.
  static const Color texto = ink;
  static const Color textoSuave = muted;
  static const Color textoSutil = muted;
  static const Color pagina = canvas;
  static const Color fundo = canvas;
  static const Color superficie = paper;
  static const Color superficieAlternativa = paperSoft;
  static const Color superficieForte = plumSoft;
  static const Color borda = line;

  // Contrapartes escuras extraídas do protótipo.
  // Contrato V11 — tema escuro.
  static const Color textoEscuro = Color(0xFFFAF6EF);
  static const Color textoSuaveEscuro = Color(0xFFC2B6C0);
  static const Color textoSutilEscuro = Color(0xFFC2B6C0);
  static const Color paginaEscura = Color(0xFF1D191E);
  static const Color fundoEscuro = Color(0xFF1D191E);
  static const Color superficieEscura = Color(0xFF292329);
  static const Color superficieAlternativaEscura = Color(0xFF332B32);
  static const Color superficieForteEscura = Color(0xFF46364B);
  static const Color bordaEscura = Color(0xFF493C47);
  static const Color acaoFundoEscuro = Color(0xFF4B2C2A);
  static const Color cianoFundoEscuro = Color(0xFF46364B);
  static const Color ganhoFundoEscuro = Color(0xFF263F35);
  static const Color ganhoEscuro = Color(0xFF84D0AA);
  static const Color atencaoFundoEscuro = Color(0xFF44391F);
  static const Color atencaoEscuro = Color(0xFFF3CB72);
  static const Color acaoEscura = Color(0xFFFF896B);
  static const Color acaoForteEscura = Color(0xFFFFB099);
  static const Color marcaEscura = Color(0xFFD8B9DF);
  static const Color perigoEscuro = Color(0xFFFF9AA7);
}

/// Escala estrutural para evitar números mágicos espalhados pelo redesign.
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
  static const double pequeno = 12;
  static const double medio = 15;
  static const double grande = 21;
  static const double destaque = 26;
  static const double pilula = 999;
}

abstract final class SombraRadar {
  static const BoxShadow clara = BoxShadow(
    color: Color(0x143F2531),
    blurRadius: 24,
    offset: Offset(0, 8),
  );

  static const BoxShadow escura = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 28,
    offset: Offset(0, 10),
  );

  static BoxShadow para(Brightness brilho) =>
      brilho == Brightness.dark ? escura : clara;
}

/// Cores semânticas que mudam junto do tema sem alterar o significado.
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
  });

  const CoresRadar.claras()
    : marca = Tokens.plum,
      acao = Tokens.action,
      integracaoInter = Tokens.ciano,
      ganho = Tokens.ganho,
      atencao = Tokens.atencao,
      perigo = Tokens.perigo,
      textoSuave = Tokens.textoSuave,
      superficieAlternativa = Tokens.superficieAlternativa,
      borda = Tokens.borda;

  const CoresRadar.escuras()
    : marca = Tokens.marcaEscura,
      acao = Tokens.acaoEscura,
      integracaoInter = Tokens.marcaEscura,
      ganho = Tokens.ganhoEscuro,
      atencao = Tokens.atencaoEscuro,
      perigo = Tokens.perigoEscuro,
      textoSuave = Tokens.textoSuaveEscuro,
      superficieAlternativa = Tokens.superficieAlternativaEscura,
      borda = Tokens.bordaEscura;

  /// Paleta anterior preservada no Web e em layouts amplos durante a migração.
  const CoresRadar.legadas()
    : marca = const Color(0xFF1788B8),
      acao = const Color(0xFF1788B8),
      integracaoInter = const Color(0xFF087E8B),
      ganho = const Color(0xFF16835F),
      atencao = const Color(0xFF8B5A12),
      perigo = const Color(0xFFD44747),
      textoSuave = const Color(0xFF60758A),
      superficieAlternativa = const Color(0xFFF0F4F7),
      borda = const Color(0xFFC4D2DE);

  final Color acao;
  final Color marca;
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
    Color? marca,
    Color? acao,
    Color? integracaoInter,
    Color? ganho,
    Color? atencao,
    Color? perigo,
    Color? textoSuave,
    Color? superficieAlternativa,
    Color? borda,
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
  );

  @override
  CoresRadar lerp(covariant CoresRadar? other, double t) {
    if (other == null) return this;
    return CoresRadar(
      marca: Color.lerp(marca, other.marca, t)!,
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
