// Testa os tokens do contrato visual mobile e o tema.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';

void main() {
  test('tokens carregam os valores do protótipo mobile', () {
    expect(Tokens.canvas.toARGB32(), const Color(0xFFEEF4F1).toARGB32());
    expect(Tokens.paper.toARGB32(), const Color(0xFFFFFEFA).toARGB32());
    expect(Tokens.paperSoft.toARGB32(), const Color(0xFFE0EBE7).toARGB32());
    expect(Tokens.ink.toARGB32(), const Color(0xFF17262A).toARGB32());
    expect(Tokens.muted.toARGB32(), const Color(0xFF66787A).toARGB32());
    expect(Tokens.line.toARGB32(), const Color(0xFFCAD9D4).toARGB32());
    expect(Tokens.action.toARGB32(), const Color(0xFFF26B52).toARGB32());
    expect(Tokens.actionStrong.toARGB32(), const Color(0xFFBD4638).toARGB32());
    expect(Tokens.actionSoft.toARGB32(), const Color(0xFFFFE4DC).toARGB32());
    expect(Tokens.plum.toARGB32(), const Color(0xFF17262A).toARGB32());
    expect(Tokens.plumSoft.toARGB32(), const Color(0xFFE0EBE7).toARGB32());
    expect(Tokens.ganho.toARGB32(), const Color(0xFF317C78).toARGB32());
    expect(Tokens.ganhoFundo.toARGB32(), const Color(0xFFD8ECE6).toARGB32());
    expect(Tokens.atencao.toARGB32(), const Color(0xFFB85B00).toARGB32());
    expect(Tokens.atencaoFundo.toARGB32(), const Color(0xFFFFE8C7).toARGB32());
    expect(Tokens.perigo.toARGB32(), const Color(0xFFD93C58).toARGB32());
    expect(Tokens.fundo.toARGB32(), const Color(0xFFEEF4F1).toARGB32());
    expect(Tokens.superficie.toARGB32(), const Color(0xFFFFFEFA).toARGB32());
    expect(
      Tokens.superficieAlternativa.toARGB32(),
      const Color(0xFFE0EBE7).toARGB32(),
    );
    expect(Tokens.borda.toARGB32(), const Color(0xFFCAD9D4).toARGB32());
  });

  test('tokens escuros carregam os valores do protótipo mobile', () {
    expect(Tokens.paginaEscura.toARGB32(), const Color(0xFF172123).toARGB32());
    expect(Tokens.fundoEscuro.toARGB32(), const Color(0xFF172123).toARGB32());
    expect(
      Tokens.superficieEscura.toARGB32(),
      const Color(0xFF223133).toARGB32(),
    );
    expect(
      Tokens.superficieAlternativaEscura.toARGB32(),
      const Color(0xFF2D4040).toARGB32(),
    );
    expect(Tokens.textoEscuro.toARGB32(), const Color(0xFFF4F7ED).toARGB32());
    expect(
      Tokens.textoSuaveEscuro.toARGB32(),
      const Color(0xFFA7B9B3).toARGB32(),
    );
    expect(
      Tokens.acaoFundoEscuro.toARGB32(),
      const Color(0xFF5A3040).toARGB32(),
    );
    expect(
      Tokens.cianoFundoEscuro.toARGB32(),
      const Color(0xFF2D4040).toARGB32(),
    );
    expect(
      Tokens.ganhoFundoEscuro.toARGB32(),
      const Color(0xFF294442).toARGB32(),
    );
    expect(
      Tokens.atencaoFundoEscuro.toARGB32(),
      const Color(0xFF4E4020).toARGB32(),
    );
    expect(Tokens.ganhoEscuro.toARGB32(), const Color(0xFF7EC8B7).toARGB32());
    expect(Tokens.atencaoEscuro.toARGB32(), const Color(0xFFFFD166).toARGB32());
    expect(Tokens.bordaEscura.toARGB32(), const Color(0xFF49615E).toARGB32());
    expect(Tokens.acaoEscura.toARGB32(), const Color(0xFFFF886F).toARGB32());
    expect(
      Tokens.acaoForteEscura.toARGB32(),
      const Color(0xFFFF886F).toARGB32(),
    );
    expect(Tokens.marcaEscura.toARGB32(), const Color(0xFFD9F35B).toARGB32());
    expect(Tokens.perigoEscuro.toARGB32(), const Color(0xFFFF7891).toARGB32());
  });

  test('escala estrutural do redesign permanece estável', () {
    expect(EspacamentoRadar.xs, 6);
    expect(EspacamentoRadar.md, 14);
    expect(EspacamentoRadar.xl, 24);
    expect(RaioRadar.medio, 14);
    expect(RaioRadar.destaque, 28);
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
