import 'package:flutter/material.dart';

import 'ds_cores.dart';

/// Escala tipográfica do Radar DS (Plus Jakarta Sans).
///
/// Os estilos já vêm com a cor de texto do tema; para metadados use
/// [apoio], que sai em `texto2`.
@immutable
class DsTipo extends ThemeExtension<DsTipo> {
  const DsTipo({
    required this.display,
    required this.tituloTela,
    required this.tituloSecao,
    required this.tituloItem,
    required this.corpo,
    required this.rotulo,
    required this.apoio,
    required this.kicker,
    required this.preco,
    required this.precoCartao,
    required this.numeroLinha,
  });

  static const familia = 'PlusJakartaSans';
  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  factory DsTipo.de(DsCores c) {
    TextStyle base(double tamanho, double altura, FontWeight peso,
            {double espaco = 0, Color? cor}) =>
        TextStyle(
          fontFamily: familia,
          fontSize: tamanho,
          height: altura / tamanho,
          fontWeight: peso,
          letterSpacing: espaco,
          color: cor ?? c.texto1,
        );
    return DsTipo(
      display: base(32, 36, FontWeight.w800, espaco: -0.6),
      tituloTela: base(24, 30, FontWeight.w800, espaco: -0.3),
      tituloSecao: base(18, 24, FontWeight.w700),
      tituloItem: base(16, 22, FontWeight.w700),
      corpo: base(15, 22, FontWeight.w500),
      rotulo: base(13, 18, FontWeight.w600),
      apoio: base(12, 16, FontWeight.w500, cor: c.texto2),
      kicker: base(11, 14, FontWeight.w700, espaco: 0.8, cor: c.primaria),
      preco: base(28, 32, FontWeight.w800, espaco: -0.4)
          .copyWith(fontFeatures: _tabular),
      precoCartao: base(20, 24, FontWeight.w800)
          .copyWith(fontFeatures: _tabular),
      numeroLinha: base(14, 20, FontWeight.w700)
          .copyWith(fontFeatures: _tabular),
    );
  }

  final TextStyle display;
  final TextStyle tituloTela;
  final TextStyle tituloSecao;
  final TextStyle tituloItem;
  final TextStyle corpo;
  final TextStyle rotulo;
  final TextStyle apoio;
  final TextStyle kicker;
  final TextStyle preco;
  final TextStyle precoCartao;
  final TextStyle numeroLinha;

  @override
  DsTipo copyWith({
    TextStyle? display,
    TextStyle? tituloTela,
    TextStyle? tituloSecao,
    TextStyle? tituloItem,
    TextStyle? corpo,
    TextStyle? rotulo,
    TextStyle? apoio,
    TextStyle? kicker,
    TextStyle? preco,
    TextStyle? precoCartao,
    TextStyle? numeroLinha,
  }) => DsTipo(
    display: display ?? this.display,
    tituloTela: tituloTela ?? this.tituloTela,
    tituloSecao: tituloSecao ?? this.tituloSecao,
    tituloItem: tituloItem ?? this.tituloItem,
    corpo: corpo ?? this.corpo,
    rotulo: rotulo ?? this.rotulo,
    apoio: apoio ?? this.apoio,
    kicker: kicker ?? this.kicker,
    preco: preco ?? this.preco,
    precoCartao: precoCartao ?? this.precoCartao,
    numeroLinha: numeroLinha ?? this.numeroLinha,
  );

  @override
  DsTipo lerp(covariant ThemeExtension<DsTipo>? other, double t) {
    if (other is! DsTipo) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return DsTipo(
      display: l(display, other.display),
      tituloTela: l(tituloTela, other.tituloTela),
      tituloSecao: l(tituloSecao, other.tituloSecao),
      tituloItem: l(tituloItem, other.tituloItem),
      corpo: l(corpo, other.corpo),
      rotulo: l(rotulo, other.rotulo),
      apoio: l(apoio, other.apoio),
      kicker: l(kicker, other.kicker),
      preco: l(preco, other.preco),
      precoCartao: l(precoCartao, other.precoCartao),
      numeroLinha: l(numeroLinha, other.numeroLinha),
    );
  }
}
