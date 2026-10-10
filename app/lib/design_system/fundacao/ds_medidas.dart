import 'package:flutter/animation.dart';

/// Grade de 4 px do Radar DS (tokens `espaco-*`).
abstract final class DsEspaco {
  static const double e1 = 4;
  static const double e2 = 8;
  static const double e3 = 12;
  static const double e4 = 16;
  static const double e5 = 20;
  static const double e6 = 24;
  static const double e8 = 32;
  static const double e10 = 40;
  static const double e12 = 48;

  /// Margem lateral padrão das telas.
  static const double margemTela = e4;

  /// Alvo de toque mínimo.
  static const double alvoToque = e12;
}

/// Raios por função (tokens `raio-*`).
abstract final class DsRaio {
  static const double xs = 8; // selos, skeleton
  static const double sm = 12; // botões, campos, segmentado
  static const double md = 16; // cartões
  static const double lg = 24; // topo das folhas
  static const double pill = 999; // chips, acompanhar, paginação
}

/// Durações e curvas. Com movimento reduzido, use [DsMovimento.de].
abstract final class DsMovimento {
  static const toque = Duration(milliseconds: 120);
  static const tela = Duration(milliseconds: 280);
  static const folhaEntrada = Duration(milliseconds: 280);
  static const folhaSaida = Duration(milliseconds: 160);
  static const pulso = Duration(milliseconds: 600);
  static const curva = Curves.easeOutCubic;

  /// Zera a duração quando o usuário pediu menos movimento.
  static Duration de(Duration base, {required bool reduzido}) =>
      reduzido ? Duration.zero : base;
}
