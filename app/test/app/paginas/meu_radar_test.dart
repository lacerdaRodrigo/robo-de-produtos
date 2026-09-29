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

Api _api({List<Uri>? consultas}) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      if (requisicao.url.path == '/api/alertas/acompanhamentos') {
        consultas?.add(requisicao.url);
        return http.Response(
          jsonEncode({
            'itens': [
              for (final item in [
                ['livelo', 'Loja Livelo'],
                ['inter_cashback', 'Loja Inter'],
                ['inter_produto', 'Produto Inter'],
                ['pichau', 'PC Pichau'],
                ['livelo', 'Outra Livelo'],
                ['pichau', 'Outro Pichau'],
              ])
                {
                  'id': item[1],
                  'origem': item[0],
                  'tipo_entidade': 'produto',
                  'entidade_id': item[1],
                  'nome': item[1],
                  'estado': 'atualizado',
                  'valor_texto': 'Dados reais',
                  'criado_em': '2026-08-23T12:00:00Z',
                  'atualizado_em': '2026-08-23T12:00:00Z',
                },
            ],
            'pagina': 1,
            'por_pagina': 20,
            'total_itens': 6,
            'total_paginas': 1,
            'tem_proxima': false,
            'totais_por_origem': {
              'livelo': 2,
              'inter_cashback': 1,
              'inter_produto': 1,
              'pichau': 2,
            },
          }),
          200,
        );
      }
      return http.Response(jsonEncode(_resumo), 200);
    }),
  ),
);

void main() {
  testWidgets('Meu radar segue a composição V15 e filtra por origem', (
    at,
  ) async {
    at.view.physicalSize = const Size(390, 844);
    at.view.devicePixelRatio = 1;
    addTearDown(at.view.resetPhysicalSize);
    addTearDown(at.view.resetDevicePixelRatio);
    final consultas = <Uri>[];
    var abriuAlertas = false;
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaMeuRadar(
            api: _api(consultas: consultas),
            aoExplorar: () {},
            aoAbrirAlertas: () => abriuAlertas = true,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.byKey(const Key('pagina-meu-radar')), findsOneWidget);
    expect(find.text('No seu radar'), findsOneWidget);
    expect(find.text('6 itens acompanhados por você.'), findsOneWidget);
    expect(find.text('Encontre na sua lista'), findsOneWidget);
    expect(find.text('Buscar no seu radar'), findsNothing);
    expect(find.text('O que merece sua atenção.'), findsNothing);
    expect(find.text('Ordenar'), findsNothing);
    expect(find.text('Central de alertas'), findsNothing);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Sites parceiros'), findsOneWidget);
    expect(find.text('Compre direto'), findsOneWidget);
    expect(find.text('Livelo'), findsOneWidget);
    expect(find.text('Pichau'), findsOneWidget);
    expect(find.byTooltip('Abrir alertas'), findsOneWidget);
    expect(find.byTooltip('Pesquisar'), findsOneWidget);
    expect(find.text('Loja Livelo'), findsOneWidget);
    expect(find.text('Loja Inter'), findsOneWidget);
    expect(find.text('Acompanhando'), findsWidgets);

    await at.tap(find.byTooltip('Abrir alertas'));
    expect(abriuAlertas, isTrue);

    await at.ensureVisible(find.text('Compre direto'));
    await at.tap(find.text('Compre direto'));
    await at.pumpAndSettle();
    expect(consultas.last.queryParameters['origem'], 'inter_produto');
    expect(consultas.last.queryParameters['ordenar'], 'recentes');
    final lista = find.byKey(const Key('pagina-meu-radar'));
    await at.drag(lista, const Offset(0, 400));
    await at.pumpAndSettle();
    expect(find.text('6 itens acompanhados por você.'), findsOneWidget);
    for (
      var tentativa = 0;
      tentativa < 6 && find.text('Produto Inter').evaluate().isEmpty;
      tentativa++
    ) {
      await at.drag(lista, const Offset(0, -300));
      await at.pumpAndSettle();
    }
    expect(find.text('Produto Inter'), findsOneWidget);
    for (
      var tentativa = 0;
      tentativa < 6 && find.text('PC Pichau').evaluate().isEmpty;
      tentativa++
    ) {
      await at.drag(lista, const Offset(0, -300));
      await at.pumpAndSettle();
    }
    expect(find.text('PC Pichau'), findsOneWidget);
    expect(at.takeException(), isNull);
  });

  testWidgets('Meu radar não estoura com texto ampliado e direção RTL', (
    at,
  ) async {
    at.view.physicalSize = const Size(320, 840);
    at.view.devicePixelRatio = 1;
    addTearDown(at.view.resetPhysicalSize);
    addTearDown(at.view.resetDevicePixelRatio);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.escuro(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: PaginaMeuRadar(
                  api: _api(),
                  aoExplorar: () {},
                  aoAbrirAlertas: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('No seu radar'), findsOneWidget);
    expect(find.text('Acompanhando'), findsWidgets);
    expect(at.takeException(), isNull);
  });
}
