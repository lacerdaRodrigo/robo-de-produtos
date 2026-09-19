// Testa os tokens do contrato visual mobile e o tema.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';

void main() {
  test('tokens carregam os valores da identidade mobile V15', () {
    expect(Tokens.canvas.toARGB32(), const Color(0xFFF6F4F0).toARGB32());
    expect(Tokens.paper.toARGB32(), const Color(0xFFFFFDF9).toARGB32());
    expect(Tokens.paperSoft.toARGB32(), const Color(0xFFEEEAE4).toARGB32());
    expect(Tokens.ink.toARGB32(), const Color(0xFF282629).toARGB32());
    expect(Tokens.muted.toARGB32(), const Color(0xFF70675F).toARGB32());
    expect(Tokens.line.toARGB32(), const Color(0xFFD9D1C8).toARGB32());
    expect(Tokens.action.toARGB32(), const Color(0xFFB6421E).toARGB32());
    expect(Tokens.actionStrong.toARGB32(), const Color(0xFF8F3416).toARGB32());
    expect(Tokens.actionSoft.toARGB32(), const Color(0xFFFBE6D9).toARGB32());
    expect(Tokens.ganho.toARGB32(), const Color(0xFF236347).toARGB32());
    expect(Tokens.ganhoFundo.toARGB32(), const Color(0xFFE1EEE5).toARGB32());
    expect(Tokens.atencao.toARGB32(), const Color(0xFF835B16).toARGB32());
    expect(Tokens.atencaoFundo.toARGB32(), const Color(0xFFF9EDCE).toARGB32());
    expect(Tokens.perigo.toARGB32(), const Color(0xFFAF303A).toARGB32());
    expect(Tokens.fundo.toARGB32(), const Color(0xFFF6F4F0).toARGB32());
    expect(Tokens.superficie.toARGB32(), const Color(0xFFFFFDF9).toARGB32());
    expect(
      Tokens.superficieAlternativa.toARGB32(),
      const Color(0xFFEEEAE4).toARGB32(),
    );
    expect(Tokens.borda.toARGB32(), const Color(0xFFD9D1C8).toARGB32());
  });

  test('tokens escuros carregam os valores da identidade mobile V15', () {
    expect(Tokens.paginaEscura.toARGB32(), const Color(0xFF222225).toARGB32());
    expect(Tokens.fundoEscuro.toARGB32(), const Color(0xFF222225).toARGB32());
    expect(
      Tokens.superficieEscura.toARGB32(),
      const Color(0xFF2B2B2E).toARGB32(),
    );
    expect(
      Tokens.superficieAlternativaEscura.toARGB32(),
      const Color(0xFF333337).toARGB32(),
    );
    expect(Tokens.textoEscuro.toARGB32(), const Color(0xFFF6F0E9).toARGB32());
    expect(
      Tokens.textoSuaveEscuro.toARGB32(),
      const Color(0xFFBFB7AE).toARGB32(),
    );
    expect(
      Tokens.acaoFundoEscuro.toARGB32(),
      const Color(0xFF4B3027).toARGB32(),
    );
    expect(
      Tokens.ganhoFundoEscuro.toARGB32(),
      const Color(0xFF2C4034).toARGB32(),
    );
    expect(
      Tokens.ganhoFundoEscuro.toARGB32(),
      const Color(0xFF2C4034).toARGB32(),
    );
    expect(
      Tokens.atencaoFundoEscuro.toARGB32(),
      const Color(0xFF473D2B).toARGB32(),
    );
    expect(Tokens.ganhoEscuro.toARGB32(), const Color(0xFFA1DAB8).toARGB32());
    expect(Tokens.atencaoEscuro.toARGB32(), const Color(0xFFEFCF89).toARGB32());
    expect(Tokens.bordaEscura.toARGB32(), const Color(0xFF494747).toARGB32());
    expect(Tokens.acaoEscura.toARGB32(), const Color(0xFFFFAC86).toARGB32());
    expect(Tokens.actionInkDark.toARGB32(), const Color(0xFF481B09).toARGB32());
    expect(
      Tokens.acaoForteEscura.toARGB32(),
      const Color(0xFFFFC09F).toARGB32(),
    );
    expect(Tokens.marcaEscura.toARGB32(), const Color(0xFFF6F0E9).toARGB32());
    expect(Tokens.perigoEscuro.toARGB32(), const Color(0xFFFFADB2).toARGB32());
  });

  test('escala estrutural do redesign permanece estável', () {
    expect(EspacamentoRadar.xs, 8);
    expect(EspacamentoRadar.md, 16);
    expect(EspacamentoRadar.xl, 24);
    expect(RaioRadar.medio, 18);
    expect(RaioRadar.destaque, 26);
    expect(RaioRadar.pilula, 999);
    expect(const AppSizes.v15().touchTarget, 48);
    expect(const AppSizes.v15().field, 48);
    expect(const AppSizes.v15().badge, 24);
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
    expect(tema.extension<CoresRadar>()?.marca, Tokens.superficieEscura);
  });
}
