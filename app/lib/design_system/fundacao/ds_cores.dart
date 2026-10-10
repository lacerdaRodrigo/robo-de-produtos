import 'package:flutter/material.dart';

/// Paleta semântica do Radar DS.
///
/// Fonte única: o artefato "Radar DS" (tokens.json). Nenhuma feature deve
/// declarar `Color(0x...)`; leia sempre `context.cores`.
@immutable
class DsCores extends ThemeExtension<DsCores> {
  const DsCores({
    required this.fundoApp,
    required this.superficie1,
    required this.superficie2,
    required this.superficie3,
    required this.texto1,
    required this.texto2,
    required this.borda1,
    required this.borda2,
    required this.primaria,
    required this.primariaForte,
    required this.primariaSuave,
    required this.sobrePrimaria,
    required this.sinal,
    required this.sobreSinal,
    required this.sucesso,
    required this.sucessoSuave,
    required this.atencao,
    required this.atencaoSuave,
    required this.perigo,
    required this.perigoSuave,
    required this.scrim,
  });

  static const claro = DsCores(
    fundoApp: Color(0xFFF4F5F9),
    superficie1: Color(0xFFFFFFFF),
    superficie2: Color(0xFFEBEDF3),
    superficie3: Color(0xFFDFE2EA),
    texto1: Color(0xFF11131A),
    texto2: Color(0xFF565C6C),
    borda1: Color(0xFFDADDE6),
    borda2: Color(0xFF8C93A6),
    primaria: Color(0xFF2E45E6),
    primariaForte: Color(0xFF1F31B8),
    primariaSuave: Color(0xFFE4E8FF),
    sobrePrimaria: Color(0xFFFFFFFF),
    sinal: Color(0xFFCFF54A),
    sobreSinal: Color(0xFF1A2200),
    sucesso: Color(0xFF0B7A55),
    sucessoSuave: Color(0xFFDDF3EA),
    atencao: Color(0xFF8A5700),
    atencaoSuave: Color(0xFFFCEFD3),
    perigo: Color(0xFFB42A35),
    perigoSuave: Color(0xFFFCE3E5),
    scrim: Color(0x6611131A),
  );

  static const escuro = DsCores(
    fundoApp: Color(0xFF0D0F15),
    superficie1: Color(0xFF161922),
    superficie2: Color(0xFF1F2330),
    superficie3: Color(0xFF2A2F3E),
    texto1: Color(0xFFF1F3F8),
    texto2: Color(0xFFA3A9BA),
    borda1: Color(0xFF2B3040),
    borda2: Color(0xFF5E6680),
    primaria: Color(0xFF8C9BFF),
    primariaForte: Color(0xFFB4BEFF),
    primariaSuave: Color(0xFF232A55),
    sobrePrimaria: Color(0xFF0B1240),
    sinal: Color(0xFFD6F86B),
    sobreSinal: Color(0xFF1A2200),
    sucesso: Color(0xFF5BD6A4),
    sucessoSuave: Color(0xFF12382B),
    atencao: Color(0xFFF2C15C),
    atencaoSuave: Color(0xFF3A2E12),
    perigo: Color(0xFFFF8A93),
    perigoSuave: Color(0xFF3F1A1E),
    scrim: Color(0xA3000000),
  );

  final Color fundoApp;
  final Color superficie1;
  final Color superficie2;
  final Color superficie3;
  final Color texto1;
  final Color texto2;
  final Color borda1;
  final Color borda2;
  final Color primaria;
  final Color primariaForte;
  final Color primariaSuave;
  final Color sobrePrimaria;
  final Color sinal;
  final Color sobreSinal;
  final Color sucesso;
  final Color sucessoSuave;
  final Color atencao;
  final Color atencaoSuave;
  final Color perigo;
  final Color perigoSuave;
  final Color scrim;

  @override
  DsCores copyWith({
    Color? fundoApp,
    Color? superficie1,
    Color? superficie2,
    Color? superficie3,
    Color? texto1,
    Color? texto2,
    Color? borda1,
    Color? borda2,
    Color? primaria,
    Color? primariaForte,
    Color? primariaSuave,
    Color? sobrePrimaria,
    Color? sinal,
    Color? sobreSinal,
    Color? sucesso,
    Color? sucessoSuave,
    Color? atencao,
    Color? atencaoSuave,
    Color? perigo,
    Color? perigoSuave,
    Color? scrim,
  }) => DsCores(
    fundoApp: fundoApp ?? this.fundoApp,
    superficie1: superficie1 ?? this.superficie1,
    superficie2: superficie2 ?? this.superficie2,
    superficie3: superficie3 ?? this.superficie3,
    texto1: texto1 ?? this.texto1,
    texto2: texto2 ?? this.texto2,
    borda1: borda1 ?? this.borda1,
    borda2: borda2 ?? this.borda2,
    primaria: primaria ?? this.primaria,
    primariaForte: primariaForte ?? this.primariaForte,
    primariaSuave: primariaSuave ?? this.primariaSuave,
    sobrePrimaria: sobrePrimaria ?? this.sobrePrimaria,
    sinal: sinal ?? this.sinal,
    sobreSinal: sobreSinal ?? this.sobreSinal,
    sucesso: sucesso ?? this.sucesso,
    sucessoSuave: sucessoSuave ?? this.sucessoSuave,
    atencao: atencao ?? this.atencao,
    atencaoSuave: atencaoSuave ?? this.atencaoSuave,
    perigo: perigo ?? this.perigo,
    perigoSuave: perigoSuave ?? this.perigoSuave,
    scrim: scrim ?? this.scrim,
  );

  @override
  DsCores lerp(covariant ThemeExtension<DsCores>? other, double t) {
    if (other is! DsCores) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DsCores(
      fundoApp: l(fundoApp, other.fundoApp),
      superficie1: l(superficie1, other.superficie1),
      superficie2: l(superficie2, other.superficie2),
      superficie3: l(superficie3, other.superficie3),
      texto1: l(texto1, other.texto1),
      texto2: l(texto2, other.texto2),
      borda1: l(borda1, other.borda1),
      borda2: l(borda2, other.borda2),
      primaria: l(primaria, other.primaria),
      primariaForte: l(primariaForte, other.primariaForte),
      primariaSuave: l(primariaSuave, other.primariaSuave),
      sobrePrimaria: l(sobrePrimaria, other.sobrePrimaria),
      sinal: l(sinal, other.sinal),
      sobreSinal: l(sobreSinal, other.sobreSinal),
      sucesso: l(sucesso, other.sucesso),
      sucessoSuave: l(sucessoSuave, other.sucessoSuave),
      atencao: l(atencao, other.atencao),
      atencaoSuave: l(atencaoSuave, other.atencaoSuave),
      perigo: l(perigo, other.perigo),
      perigoSuave: l(perigoSuave, other.perigoSuave),
      scrim: l(scrim, other.scrim),
    );
  }
}
