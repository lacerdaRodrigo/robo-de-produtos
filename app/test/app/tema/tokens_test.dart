// Testa os tokens do contrato visual mobile e o tema.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';

void main() {
  test('tokens carregam os valores do protótipo mobile', () {
    expect(Tokens.canvas.toARGB32(), const Color(0xFFF4EEE5).toARGB32());
    expect(Tokens.paper.toARGB32(), const Color(0xFFFFFDF8).toARGB32());
    expect(Tokens.paperSoft.toARGB32(), const Color(0xFFFAF5ED).toARGB32());
    expect(Tokens.ink.toARGB32(), const Color(0xFF291A2F).toARGB32());
    expect(Tokens.muted.toARGB32(), const Color(0xFF756B76).toARGB32());
    expect(Tokens.line.toARGB32(), const Color(0xFFE4D8CA).toARGB32());
    expect(Tokens.action.toARGB32(), const Color(0xFFE76043).toARGB32());
    expect(Tokens.actionStrong.toARGB32(), const Color(0xFFBA3B26).toARGB32());
    expect(Tokens.actionSoft.toARGB32(), const Color(0xFFFEE4DC).toARGB32());
    expect(Tokens.plum.toARGB32(), const Color(0xFF4C2E59).toARGB32());
    expect(Tokens.plumSoft.toARGB32(), const Color(0xFFEEE3F2).toARGB32());
    expect(Tokens.ganho.toARGB32(), const Color(0xFF28745A).toARGB32());
    expect(Tokens.ganhoFundo.toARGB32(), const Color(0xFFDCEEE4).toARGB32());
    expect(Tokens.atencao.toARGB32(), const Color(0xFF8A5D12).toARGB32());
    expect(Tokens.atencaoFundo.toARGB32(), const Color(0xFFFBEBBF).toARGB32());
    expect(Tokens.perigo.toARGB32(), const Color(0xFFAF3544).toARGB32());
    expect(Tokens.fundo.toARGB32(), const Color(0xFFF4EEE5).toARGB32());
    expect(Tokens.superficie.toARGB32(), const Color(0xFFFFFDF8).toARGB32());
    expect(
      Tokens.superficieAlternativa.toARGB32(),
      const Color(0xFFFAF5ED).toARGB32(),
    );
    expect(Tokens.borda.toARGB32(), const Color(0xFFE4D8CA).toARGB32());
  });

  test('tokens escuros carregam os valores do protótipo mobile', () {
    expect(Tokens.paginaEscura.toARGB32(), const Color(0xFF1D191E).toARGB32());
    expect(Tokens.fundoEscuro.toARGB32(), const Color(0xFF1D191E).toARGB32());
    expect(
      Tokens.superficieEscura.toARGB32(),
      const Color(0xFF292329).toARGB32(),
    );
    expect(
      Tokens.superficieAlternativaEscura.toARGB32(),
      const Color(0xFF332B32).toARGB32(),
    );
    expect(Tokens.textoEscuro.toARGB32(), const Color(0xFFFAF6EF).toARGB32());
    expect(
      Tokens.textoSuaveEscuro.toARGB32(),
      const Color(0xFFC2B6C0).toARGB32(),
    );
    expect(
      Tokens.acaoFundoEscuro.toARGB32(),
      const Color(0xFF4B2C2A).toARGB32(),
    );
    expect(
      Tokens.cianoFundoEscuro.toARGB32(),
      const Color(0xFF46364B).toARGB32(),
    );
    expect(
      Tokens.ganhoFundoEscuro.toARGB32(),
      const Color(0xFF263F35).toARGB32(),
    );
    expect(
      Tokens.atencaoFundoEscuro.toARGB32(),
      const Color(0xFF44391F).toARGB32(),
    );
    expect(Tokens.ganhoEscuro.toARGB32(), const Color(0xFF84D0AA).toARGB32());
    expect(Tokens.atencaoEscuro.toARGB32(), const Color(0xFFF3CB72).toARGB32());
    expect(Tokens.bordaEscura.toARGB32(), const Color(0xFF493C47).toARGB32());
    expect(Tokens.acaoEscura.toARGB32(), const Color(0xFFFF896B).toARGB32());
    expect(
      Tokens.acaoForteEscura.toARGB32(),
      const Color(0xFFFFB099).toARGB32(),
    );
    expect(Tokens.marcaEscura.toARGB32(), const Color(0xFFD8B9DF).toARGB32());
    expect(Tokens.perigoEscuro.toARGB32(), const Color(0xFFFF9AA7).toARGB32());
  });

  test('escala estrutural do redesign permanece estável', () {
    expect(EspacamentoRadar.xs, 6);
    expect(EspacamentoRadar.md, 14);
    expect(EspacamentoRadar.xl, 24);
    expect(RaioRadar.medio, 15);
    expect(RaioRadar.destaque, 26);
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
    expect(tema.extension<CoresRadar>()?.marca, Tokens.marcaEscura);
  });
}
