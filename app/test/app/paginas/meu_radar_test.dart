import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/paginas/meu_radar.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';

const _resumo = {
  'gerado_em': '2026-08-23T12:00:00.000Z',
  'estado_geral': 'atualizado',
  'livelo': {
    'estado': 'atualizado',
    'ultimo_sucesso_em': '2026-08-23T08:00:00.000Z',
    'lojas_acompanhadas': 2,
    'alertas_ultima_coleta': 1,
  },
  'cashback_inter': {
    'estado': 'atualizado',
    'ultima_tentativa_em': '2026-08-23T07:00:00.000Z',
    'ultima_tentativa_estado': 'sucesso',
    'ultimo_sucesso_em': '2026-08-23T07:10:00.000Z',
    'lojas_acompanhadas': 1,
    'lojas_encontradas_ultima_coleta': 1,
  },
  'produtos': {
    'estado': 'atualizado',
    'ultima_tentativa_em': '2026-08-23T06:00:00.000Z',
    'ultima_tentativa_estado': 'sucesso',
    'dados_mais_antigos_em': '2026-08-23T06:05:00.000Z',
    'dados_mais_recentes_em': '2026-08-23T06:30:00.000Z',
    'qualidade': 'completa',
    'lojas_selecionadas': 1,
    'lojas_sem_coleta': 0,
    'produtos_ativos': 4,
  },
  'pichau': {
    'estado': 'atualizado',
    'ultima_tentativa_em': '2026-08-23T07:00:00.000Z',
    'ultima_tentativa_estado': 'sucesso',
    'ultimo_sucesso_em': '2026-08-23T07:00:00.000Z',
    'qualidade': 'completa',
    'produtos_ativos': 4,
    'produtos_esgotados': 0,
    'acompanhadas': 3,
  },
};

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient(
      (_) async => http.Response(jsonEncode(_resumo), 200),
    ),
  ),
);

void main() {
  testWidgets('Meu radar mostra contagens reais por fonte', (at) async {
    var explorou = false;
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaMeuRadar(
          api: _api(),
          aoExplorar: () => explorou = true,
          aoAbrirAlertas: () {},
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.byKey(const Key('pagina-meu-radar')), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Livelo'), findsOneWidget);
    expect(find.text('Banco Inter'), findsOneWidget);
    expect(find.text('Pichau'), findsOneWidget);

    await at.tap(find.text('Livelo'));
    expect(explorou, isTrue);
  });
}
