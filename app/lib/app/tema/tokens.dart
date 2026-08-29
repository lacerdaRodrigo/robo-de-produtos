import 'package:flutter/material.dart';

/// Tokens de cor do Radar de Benefícios.
///
/// Direção aprovada no protótipo mobile: azul-marinho como marca, verde só para
/// ganho e vermelho reservado a erro/zona de perigo.
abstract final class Tokens {
  // Marca e superfícies institucionais.
  static const Color marcaProfunda = Color(0xFF081A2D); // abertura e ícones
  static const Color marca = Color(0xFF102A43);
  static const Color marcaClara = Color(0xFF1769AA); // ação, links, foco

  // Ganho/sucesso — cashback, economia, meta atingida. Nunca para ação neutra.
  static const Color ganho = Color(0xFF16803C);

  // Atenção — dado envelhecendo.
  static const Color atencao = Color(0xFFB7791F);

  // Erro e zona de perigo.
  static const Color perigo = Color(0xFFC53030);

  // Texto e superfícies claras da nova direção mobile.
  static const Color texto = Color(0xFF102A43);
  static const Color textoSuave = Color(0xFF607487);
  static const Color fundo = Color(0xFFF5F7FA);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color superficieAlternativa = Color(0xFFEDF3F8);
  static const Color borda = Color(0xFFDCE6EE);

  // Contrapartes escuras. A marca profunda continua sendo institucional; estes
  // tokens existem para superfícies e conteúdo, não para redefinir domínios.
  static const Color textoEscuro = Color(0xFFEDF7FF);
  static const Color textoSuaveEscuro = Color(0xFF9FB3C5);
  static const Color fundoEscuro = Color(0xFF06111E);
  static const Color superficieEscura = Color(0xFF0D2032);
  static const Color superficieAlternativaEscura = Color(0xFF132B40);
  static const Color bordaEscura = Color(0xFF30485D);
  static const Color acaoEscura = Color(0xFF65DFF5);
  static const Color ganhoEscuro = Color(0xFF65D98B);
  static const Color atencaoEscura = Color(0xFFFFD17A);
  static const Color perigoEscuro = Color(0xFFFF8A8A);
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
      integracaoInter = const Color(0xFF0B7F99),
      ganho = Tokens.ganho,
      atencao = Tokens.atencao,
      perigo = Tokens.perigo,
      textoSuave = Tokens.textoSuave,
      superficieAlternativa = Tokens.superficieAlternativa,
      borda = Tokens.borda;

  const CoresRadar.escuras()
    : acao = Tokens.acaoEscura,
      integracaoInter = Tokens.acaoEscura,
      ganho = Tokens.ganhoEscuro,
      atencao = Tokens.atencaoEscura,
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
      borda = const Color(0xFFDCE6EE);

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
