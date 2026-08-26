// Testa os tokens do design aprovado (PLANO §10.2) e o tema.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';

void main() {
  test('tokens carregam os valores aprovados', () {
    expect(Tokens.marca.toARGB32(), const Color(0xFF102A43).toARGB32());
    expect(Tokens.marcaClara.toARGB32(), const Color(0xFF1769AA).toARGB32());
    expect(Tokens.ganho.toARGB32(), const Color(0xFF16803C).toARGB32());
    expect(Tokens.atencao.toARGB32(), const Color(0xFFB7791F).toARGB32());
    expect(Tokens.perigo.toARGB32(), const Color(0xFFC53030).toARGB32());
    expect(Tokens.fundo.toARGB32(), const Color(0xFFF5F7FA).toARGB32());
  });

  test('tema gera um ColorScheme material', () {
    final tema = TemaRadar.claro();
    expect(tema.colorScheme, isNotNull);
  });

  test('tema escuro existe como base', () {
    final tema = TemaRadar.escuro();
    expect(tema.brightness, Brightness.dark);
  });
}
