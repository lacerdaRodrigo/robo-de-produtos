import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/pichau/pagina_pichau.dart';

const _catalogo = {
  'itens': [
    {
      'id_externo': 'PG-7800',
      'nome': 'Pichau Gaming 7800X3D RTX 4070 Super',
      'marca': 'Pichau',
      'categoria_externa': 'PC Gamer',
      'url_produto': 'https://www.pichau.com.br/produto/pg-7800',
      'presente_no_catalogo': true,
      'disponibilidade': 'disponivel',
      'preco_original_texto': 'R\$ 8.199,90',
      'preco_pix_texto': 'R\$ 7.499,90',
      'desconto_pix_texto': '9% off',
      'preco_cartao_texto': 'R\$ 7.999,90',
      'parcelamento': '12x de R\$ 666,66',
      'sem_juros': true,
      'etiquetas': ['Oferta', 'Montado'],
      'atualizado_em': '2026-09-04T12:00:00Z',
    },
    {
      'id_externo': 'PG-7600',
      'nome': 'Pichau Gaming Ryzen 5 RX 7600',
      'marca': 'Pichau',
      'categoria_externa': 'PC Gamer',
      'url_produto': 'https://www.pichau.com.br/produto/pg-7600',
      'presente_no_catalogo': true,
      'disponibilidade': 'esgotado',
      'preco_pix_texto': 'R\$ 4.699,90',
      'preco_cartao_texto': 'R\$ 4.899,90',
      'parcelamento': '12x de R\$ 408,32',
      'etiquetas': ['Montado'],
      'atualizado_em': '2026-09-04T12:00:00Z',
    },
  ],
  'pagina': 1,
  'por_pagina': 20,
  'total_itens': 2,
  'total_paginas': 1,
  'tem_proxima': false,
  'atualizado_em': '2026-09-04T12:00:00Z',
  'qualidade': 'completa',
};

final _historico = <String, dynamic>{
  'produto': (_catalogo['itens'] as List<dynamic>).first,
  'minimo_pix_texto': 'R\$ 7.399,90',
  'maximo_pix_texto': 'R\$ 7.899,90',
  'medicoes': [
    {
      'momento': '2026-09-04T12:00:00Z',
      'preco_pix_texto': 'R\$ 7.499,90',
      'preco_cartao_texto': 'R\$ 7.999,90',
    },
  ],
  'pagina': 1,
  'por_pagina': 30,
  'total_itens': 1,
  'tem_proxima': false,
};

Api _api({
  required List<http.Request> requisicoes,
  bool falharCatalogo = false,
  Map<String, dynamic>? catalogo,
}) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      requisicoes.add(requisicao);
      if (requisicao.url.path == '/api/pichau/catalogo') {
        if (falharCatalogo) return http.Response('{}', 500);
        return http.Response(jsonEncode(catalogo ?? _catalogo), 200);
      }
      if (requisicao.url.path == '/api/pichau/catalogo/PG-7800/historico') {
        return http.Response(jsonEncode(_historico), 200);
      }
      return http.Response('{}', 404);
    }),
  ),
);

Widget _tela(Api api, {ThemeData? tema}) {
  return MaterialApp(
    theme: tema ?? TemaRadar.claro(),
    home: Scaffold(
      body: PaginaPichau(key: UniqueKey(), api: api),
    ),
    builder: (context, child) =>
        MediaQuery(data: MediaQuery.of(context), child: child!),
  );
}

void main() {
  testWidgets('mostra catálogo Pichau, preços, estados e histórico', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await at.pumpWidget(_tela(_api(requisicoes: requisicoes)));
    expect(find.text('Carregando catálogo Pichau…'), findsOneWidget);
    await at.pumpAndSettle();

    expect(find.text('Pichau'), findsWidgets);
    expect(find.text('R\$ 7.499,90'), findsOneWidget);
    expect(find.text('R\$ 7.999,90'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Esgotado'), findsOneWidget);
    expect(find.text('Ver na Pichau'), findsNWidgets(2));
    expect(requisicoes.single.url.queryParameters['por_pagina'], '20');

    await at.tap(find.byKey(const Key('historico-pichau-PG-7800')));
    await at.pumpAndSettle();

    expect(find.text('Histórico de preço'), findsOneWidget);
    expect(find.text('R\$ 7.399,90'), findsOneWidget);
    expect(find.byKey(const Key('historico-pichau-conteudo')), findsOneWidget);
  });

  testWidgets('busca preserva o termo e trata falha sem inventar catálogo', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await at.pumpWidget(_tela(_api(requisicoes: requisicoes)));
    await at.pumpAndSettle();
    await at.enterText(find.byKey(const Key('busca-pichau')), 'ryzen');
    await at.pumpAndSettle();

    expect(requisicoes.last.url.queryParameters['q'], 'ryzen');

    final requisicoesComFalha = <http.Request>[];
    await at.pumpWidget(
      _tela(_api(requisicoes: requisicoesComFalha, falharCatalogo: true)),
    );
    await at.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar o catálogo Pichau.'),
      findsOneWidget,
    );
    expect(find.text('R\$ 0,00'), findsNothing);
  });

  testWidgets('catálogo permanece alcançável nas larguras mobile V11', (
    at,
  ) async {
    addTearDown(at.view.reset);
    for (final largura in <double>[320, 390, 430]) {
      at.view.physicalSize = Size(largura, 844);
      at.view.devicePixelRatio = 1;
      await at.pumpWidget(_tela(_api(requisicoes: <http.Request>[])));
      await at.pumpAndSettle();

      expect(find.byKey(const Key('pagina-pichau')), findsOneWidget);
      expect(at.takeException(), isNull, reason: 'largura $largura px');
    }
  });

  testWidgets('catálogo mantém a fundação visual no tema escuro', (at) async {
    addTearDown(at.view.reset);
    at.view.physicalSize = const Size(390, 844);
    at.view.devicePixelRatio = 1;
    await at.pumpWidget(
      _tela(_api(requisicoes: <http.Request>[]), tema: TemaRadar.escuro()),
    );
    await at.pumpAndSettle();

    expect(find.text('Catálogo atualizado'), findsOneWidget);
    expect(find.text('Ver na Pichau'), findsNWidgets(2));
    expect(at.takeException(), isNull);
  });

  testWidgets('catálogo vazio e coleta parcial usam estados próprios', (
    at,
  ) async {
    final vazio = Map<String, dynamic>.from(_catalogo)
      ..['itens'] = <dynamic>[]
      ..['total_itens'] = 0
      ..['total_paginas'] = 1;
    await at.pumpWidget(
      _tela(_api(requisicoes: <http.Request>[], catalogo: vazio)),
    );
    await at.pumpAndSettle();
    expect(
      find.text('Nenhum PC Gamer foi encontrado na última coleta completa.'),
      findsOneWidget,
    );
    expect(find.text('Catálogo vazio'), findsOneWidget);

    final parcial = Map<String, dynamic>.from(_catalogo)
      ..['qualidade'] = 'degradada'
      ..['ultima_tentativa_estado'] = 'parcial';
    await at.pumpWidget(
      _tela(_api(requisicoes: <http.Request>[], catalogo: parcial)),
    );
    await at.pumpAndSettle();
    expect(find.text('Parcial / atrasado'), findsOneWidget);
    expect(
      find.text(
        'A coleta da Pichau está parcial ou atrasada. O último catálogo válido continua disponível.',
      ),
      findsOneWidget,
    );
  });
}
