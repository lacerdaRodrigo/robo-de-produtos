// Testa os tokens do contrato visual mobile e o tema.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';

void main() {
  test('tokens carregam os valores do protótipo mobile', () {
    expect(Tokens.marcaProfunda.toARGB32(), const Color(0xFF081A2D).toARGB32());
    expect(Tokens.marca.toARGB32(), const Color(0xFF102A43).toARGB32());
    expect(Tokens.marcaMedia.toARGB32(), const Color(0xFF163B5C).toARGB32());
    expect(Tokens.marcaClara.toARGB32(), const Color(0xFF1769AA).toARGB32());
    expect(Tokens.acaoFundo.toARGB32(), const Color(0xFFDCEEFF).toARGB32());
    expect(Tokens.ciano.toARGB32(), const Color(0xFF25B8D8).toARGB32());
    expect(Tokens.cianoFundo.toARGB32(), const Color(0xFFDEF8FD).toARGB32());
    expect(Tokens.ganho.toARGB32(), const Color(0xFF16803C).toARGB32());
    expect(Tokens.ganhoFundo.toARGB32(), const Color(0xFFDCFCE7).toARGB32());
    expect(Tokens.atencao.toARGB32(), const Color(0xFF8B5A12).toARGB32());
    expect(Tokens.atencaoFundo.toARGB32(), const Color(0xFFFFF2D7).toARGB32());
    expect(Tokens.perigo.toARGB32(), const Color(0xFFC53030).toARGB32());
    expect(Tokens.fundo.toARGB32(), const Color(0xFFF3F7FB).toARGB32());
    expect(Tokens.superficie.toARGB32(), const Color(0xFFFFFFFF).toARGB32());
    expect(
      Tokens.superficieAlternativa.toARGB32(),
      const Color(0xFFEDF3F8).toARGB32(),
    );
    expect(Tokens.borda.toARGB32(), const Color(0xFFDCE6EE).toARGB32());
  });

  test('tokens escuros carregam os valores do protótipo mobile', () {
    expect(Tokens.fundoEscuro.toARGB32(), const Color(0xFF06111E).toARGB32());
    expect(
      Tokens.superficieEscura.toARGB32(),
      const Color(0xFF0D2032).toARGB32(),
    );
    expect(
      Tokens.superficieAlternativaEscura.toARGB32(),
      const Color(0xFF132B40).toARGB32(),
    );
    expect(Tokens.textoEscuro.toARGB32(), const Color(0xFFEDF7FF).toARGB32());
    expect(
      Tokens.textoSuaveEscuro.toARGB32(),
      const Color(0xFF9FB3C5).toARGB32(),
    );
    expect(
      Tokens.acaoFundoEscuro.toARGB32(),
      const Color(0xFF173B56).toARGB32(),
    );
    expect(
      Tokens.cianoFundoEscuro.toARGB32(),
      const Color(0xFF103A47).toARGB32(),
    );
    expect(
      Tokens.ganhoFundoEscuro.toARGB32(),
      const Color(0xFF113A27).toARGB32(),
    );
    expect(
      Tokens.atencaoFundoEscuro.toARGB32(),
      const Color(0xFF402F14).toARGB32(),
    );
    expect(Tokens.ganhoEscuro.toARGB32(), const Color(0xFF65D98B).toARGB32());
    expect(Tokens.atencaoEscuro.toARGB32(), const Color(0xFFFFD17A).toARGB32());
    expect(Tokens.bordaEscura.toARGB32(), const Color(0x24BED9EE).toARGB32());
    expect(Tokens.acaoEscura, Tokens.marcaClara);
    expect(Tokens.perigoEscuro, Tokens.perigo);
  });

  test('escala estrutural do redesign permanece estável', () {
    expect(EspacamentoRadar.xs, 8);
    expect(EspacamentoRadar.md, 16);
    expect(EspacamentoRadar.xl, 24);
    expect(RaioRadar.medio, 14);
    expect(RaioRadar.destaque, 24);
    expect(RaioRadar.pilula, 999);
  });

  test('tema gera um ColorScheme material', () {
    final tema = TemaRadar.claro();
    expect(tema.colorScheme, isNotNull);
    expect(tema.scaffoldBackgroundColor, Tokens.fundo);
  });

  test('tema escuro existe como base', () {
    final tema = TemaRadar.escuro();
    expect(tema.brightness, Brightness.dark);
    expect(tema.scaffoldBackgroundColor, Tokens.fundoEscuro);
    expect(tema.cardColor, Tokens.superficieEscura);
    expect(tema.extension<CoresRadar>()?.acao, Tokens.acaoEscura);
    expect(tema.extension<CoresRadar>()?.integracaoInter, Tokens.ciano);
  });
}
