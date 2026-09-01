// Testa os tokens do contrato visual mobile e o tema.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';

void main() {
  test('tokens carregam os valores do protótipo mobile', () {
    expect(Tokens.marcaProfunda.toARGB32(), const Color(0xFF18212A).toARGB32());
    expect(Tokens.marca.toARGB32(), const Color(0xFF1788B8).toARGB32());
    expect(Tokens.marcaMedia.toARGB32(), const Color(0xFF126F97).toARGB32());
    expect(Tokens.marcaClara.toARGB32(), const Color(0xFF1788B8).toARGB32());
    expect(Tokens.acaoFundo.toARGB32(), const Color(0xFFE1F3FA).toARGB32());
    expect(Tokens.ciano.toARGB32(), const Color(0xFF1788B8).toARGB32());
    expect(Tokens.cianoFundo.toARGB32(), const Color(0xFFE1F3FA).toARGB32());
    expect(Tokens.ganho.toARGB32(), const Color(0xFF16835F).toARGB32());
    expect(Tokens.ganhoFundo.toARGB32(), const Color(0xFFE0F4EB).toARGB32());
    expect(Tokens.atencao.toARGB32(), const Color(0xFF8B5A12).toARGB32());
    expect(Tokens.atencaoFundo.toARGB32(), const Color(0xFFFFF2D7).toARGB32());
    expect(Tokens.perigo.toARGB32(), const Color(0xFFD44747).toARGB32());
    expect(Tokens.pagina.toARGB32(), const Color(0xFFDBE5EE).toARGB32());
    expect(Tokens.fundo.toARGB32(), const Color(0xFFEAF0F5).toARGB32());
    expect(Tokens.superficie.toARGB32(), const Color(0xFFFFFFFF).toARGB32());
    expect(
      Tokens.superficieAlternativa.toARGB32(),
      const Color(0xFFE1EAF2).toARGB32(),
    );
    expect(Tokens.borda.toARGB32(), const Color(0xFFC4D2DE).toARGB32());
  });

  test('tokens escuros carregam os valores do protótipo mobile', () {
    expect(Tokens.paginaEscura.toARGB32(), const Color(0xFF2C3035).toARGB32());
    expect(Tokens.fundoEscuro.toARGB32(), const Color(0xFF33383E).toARGB32());
    expect(
      Tokens.superficieEscura.toARGB32(),
      const Color(0xFF3E444B).toARGB32(),
    );
    expect(
      Tokens.superficieAlternativaEscura.toARGB32(),
      const Color(0xFF474E56).toARGB32(),
    );
    expect(Tokens.textoEscuro.toARGB32(), const Color(0xFFF4F7FA).toARGB32());
    expect(
      Tokens.textoSuaveEscuro.toARGB32(),
      const Color(0xFFC0C7CF).toARGB32(),
    );
    expect(
      Tokens.acaoFundoEscuro.toARGB32(),
      const Color(0xFF415B68).toARGB32(),
    );
    expect(
      Tokens.cianoFundoEscuro.toARGB32(),
      const Color(0xFF415B68).toARGB32(),
    );
    expect(
      Tokens.ganhoFundoEscuro.toARGB32(),
      const Color(0xFF3D5648).toARGB32(),
    );
    expect(
      Tokens.atencaoFundoEscuro.toARGB32(),
      const Color(0xFF402F14).toARGB32(),
    );
    expect(Tokens.ganhoEscuro.toARGB32(), const Color(0xFF81E4AD).toARGB32());
    expect(Tokens.atencaoEscuro.toARGB32(), const Color(0xFFFFD17A).toARGB32());
    expect(Tokens.bordaEscura.toARGB32(), const Color(0xFF5C6670).toARGB32());
    expect(Tokens.acaoEscura.toARGB32(), const Color(0xFF70CEF3).toARGB32());
    expect(Tokens.perigoEscuro.toARGB32(), const Color(0xFFFF8585).toARGB32());
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
