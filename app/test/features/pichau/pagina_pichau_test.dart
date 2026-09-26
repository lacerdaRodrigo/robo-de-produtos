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
      'sku': 'PCM-7800',
      'nome': 'Pichau Gaming 7800X3D RTX 4070 Super',
      'marca': 'Pichau',
      'categoria_externa': 'PC Gamer',
      'url_produto': 'https://www.pichau.com.br/produto/pg-7800',
      'presente_no_catalogo': true,
      'acompanhada': false,
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
      'acompanhada': false,
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
  bool falharAcompanhamento = false,
  Map<String, dynamic>? catalogo,
  Map<String, dynamic>? catalogoAcompanhadas,
}) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      requisicoes.add(requisicao);
      if (requisicao.url.path == '/api/pichau/catalogo') {
        if (falharCatalogo) return http.Response('{}', 500);
        if (requisicao.url.queryParameters['aba'] == 'acompanhadas' &&
            catalogoAcompanhadas != null) {
          return http.Response(jsonEncode(catalogoAcompanhadas), 200);
        }
        return http.Response(jsonEncode(catalogo ?? _catalogo), 200);
      }
      if (requisicao.url.path ==
          '/api/pichau/catalogo/PG-7800/acompanhamento-pessoal') {
        if (falharAcompanhamento) return http.Response('{}', 500);
        return http.Response('{}', 200);
      }
      if (requisicao.url.path == '/api/pichau/catalogo/PG-7800/historico') {
        return http.Response(jsonEncode(_historico), 200);
      }
      return http.Response('{}', 404);
    }),
  ),
);

Widget _tela(
  Api api, {
  ThemeData? tema,
  bool administrador = false,
  TextScaler? textScaler,
}) {
  return MaterialApp(
    theme: tema ?? TemaRadar.claro(),
    home: Scaffold(
      body: PaginaPichau(
        key: UniqueKey(),
        api: api,
        administrador: administrador,
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
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

    expect(find.byKey(const Key('voltar-programas-pichau')), findsOneWidget);
    expect(find.byKey(const Key('atualizar-pichau')), findsOneWidget);
    expect(find.text('PCs gamer'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('No radar'), findsOneWidget);
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Tecnologia'), findsNothing);
    expect(find.text('Acompanhadas'), findsNothing);
    expect(find.text('PCM-7800'), findsOneWidget);
    expect(find.text('Pichau'), findsWidgets);
    expect(find.text('R\$ 7.499,90'), findsOneWidget);
    expect(
      find.text('Cartão R\$ 7.999,90 · 9% de desconto no Pix'),
      findsOneWidget,
    );
    expect(find.text('Disponível'), findsOneWidget);
    final titulo = at.widget<Text>(
      find.text('Pichau Gaming 7800X3D RTX 4070 Super'),
    );
    expect(titulo.maxLines, 2);
    expect(titulo.overflow, TextOverflow.ellipsis);
    await at.scrollUntilVisible(
      find.text('Esgotado'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Esgotado'), findsOneWidget);
    expect(find.byKey(const Key('detalhes-pichau-PG-7600')), findsOneWidget);
    expect(requisicoes.single.url.queryParameters['por_pagina'], '20');

    await at.tap(find.byKey(const Key('detalhes-pichau-PG-7800')));
    await at.pumpAndSettle();

    expect(find.text('Detalhes'), findsAtLeastNWidgets(1));
    await at.ensureVisible(find.byKey(const Key('historico-pichau-PG-7800')));
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

  testWidgets('catálogo permanece alcançável nas larguras mobile V15', (
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

  testWidgets('folha de filtros segue o protótipo em tela estreita', (
    at,
  ) async {
    addTearDown(at.view.reset);
    at.view.physicalSize = const Size(320, 844);
    at.view.devicePixelRatio = 1;
    await at.pumpWidget(_tela(_api(requisicoes: <http.Request>[])));
    await at.pumpAndSettle();

    await at.tap(find.byKey(const Key('filtrar-ordenar-pichau')));
    await at.pumpAndSettle();

    expect(find.text('Filtros · Pichau'), findsOneWidget);
    expect(find.byKey(const Key('voltar-folha-radar')), findsNothing);
    expect(find.byKey(const Key('filtro-preco-minimo-pichau')), findsOneWidget);
    expect(find.byKey(const Key('filtro-preco-maximo-pichau')), findsOneWidget);
    expect(at.takeException(), isNull);
  });

  testWidgets('folha de filtros mantém o preço acessível acima do teclado', (
    at,
  ) async {
    addTearDown(at.view.reset);
    at.view.physicalSize = const Size(390, 844);
    at.view.devicePixelRatio = 1;
    final requisicoes = <http.Request>[];
    await at.pumpWidget(_tela(_api(requisicoes: requisicoes)));
    await at.pumpAndSettle();

    await at.tap(find.byKey(const Key('filtrar-ordenar-pichau')));
    await at.pumpAndSettle();
    at.view.viewInsets = const FakeViewPadding(bottom: 320);
    await at.pumpAndSettle();

    final formulario = find
        .descendant(
          of: find.byKey(const Key('formulario-filtros-pichau-rolavel')),
          matching: find.byType(Scrollable),
        )
        .first;
    final minimo = find.byKey(const Key('filtro-preco-minimo-pichau'));
    await at.scrollUntilVisible(minimo, 120, scrollable: formulario);
    expect(at.getBottomRight(minimo).dy, lessThanOrEqualTo(524));

    await at.enterText(minimo, '3000,00');
    expect(find.text('3000,00'), findsOneWidget);
    final aplicar = find.byKey(const Key('aplicar-filtros-pichau'));
    await at.scrollUntilVisible(aplicar, 120, scrollable: formulario);
    expect(at.getBottomRight(aplicar).dy, lessThanOrEqualTo(524));
    await at.tap(aplicar);
    await at.pumpAndSettle();
    expect(requisicoes.last.url.queryParameters['preco_min'], '3000,00');
    expect(at.takeException(), isNull);
  });

  testWidgets('folha de filtros rola com texto ampliado', (at) async {
    addTearDown(at.view.reset);
    at.view.physicalSize = const Size(320, 844);
    at.view.devicePixelRatio = 1;
    await at.pumpWidget(
      _tela(
        _api(requisicoes: <http.Request>[]),
        textScaler: const TextScaler.linear(2),
      ),
    );
    await at.pumpAndSettle();

    await at.tap(find.byKey(const Key('filtrar-ordenar-pichau')));
    await at.pumpAndSettle();

    final formulario = find
        .descendant(
          of: find.byKey(const Key('formulario-filtros-pichau-rolavel')),
          matching: find.byType(Scrollable),
        )
        .first;
    await at.scrollUntilVisible(
      find.byKey(const Key('aplicar-filtros-pichau')),
      120,
      scrollable: formulario,
    );

    expect(find.byKey(const Key('aplicar-filtros-pichau')), findsOneWidget);
    expect(at.takeException(), isNull);
  });

  testWidgets('catálogo mantém a fundação visual no tema escuro', (at) async {
    addTearDown(at.view.reset);
    at.view.physicalSize = const Size(390, 844);
    at.view.devicePixelRatio = 1;
    await at.pumpWidget(
      _tela(_api(requisicoes: <http.Request>[]), tema: TemaRadar.escuro()),
    );
    await at.pumpAndSettle();

    expect(find.text('Catálogo'), findsOneWidget);
    await at.scrollUntilVisible(
      find.text('Esgotado'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('detalhes-pichau-PG-7600')), findsOneWidget);
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

  testWidgets('abas, filtros e acompanhamento usam o contrato da API', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    final acompanhadas = Map<String, dynamic>.from(_catalogo)
      ..['itens'] = <dynamic>[(_catalogo['itens'] as List<dynamic>).first]
      ..['total_itens'] = 1;
    await at.pumpWidget(
      _tela(
        _api(requisicoes: requisicoes, catalogoAcompanhadas: acompanhadas),
        administrador: true,
      ),
    );
    await at.pumpAndSettle();

    await at.tap(find.text('No radar'));
    await at.pumpAndSettle();
    expect(requisicoes.last.url.queryParameters['aba'], 'acompanhadas');
    expect(find.text('Pichau Gaming 7800X3D RTX 4070 Super'), findsOneWidget);
    expect(find.text('Pichau Gaming Ryzen 5 RX 7600'), findsNothing);
    expect(find.text('1 produto'), findsOneWidget);

    await at.tap(find.byKey(const Key('filtrar-ordenar-pichau')));
    await at.pumpAndSettle();
    expect(find.text('Filtros · Pichau'), findsOneWidget);
    expect(find.text('Ordenar'), findsOneWidget);
    expect(find.text('Preço mínimo (R\$)'), findsOneWidget);
    expect(find.text('Preço máximo (R\$)'), findsOneWidget);
    expect(find.text('Menor preço Pix'), findsOneWidget);
    expect(find.text('0,00'), findsOneWidget);
    expect(find.text('Sem limite'), findsOneWidget);
    await at.tap(find.byKey(const Key('filtro-ordenacao-pichau')));
    await at.pumpAndSettle();
    await at.tap(find.text('Nome').last);
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('filtro-disponibilidade-pichau')));
    await at.pumpAndSettle();
    await at.tap(find.text('Esgotados').last);
    await at.pumpAndSettle();
    await at.enterText(
      find.byKey(const Key('filtro-preco-minimo-pichau')),
      '8000,00',
    );
    await at.enterText(
      find.byKey(const Key('filtro-preco-maximo-pichau')),
      '3000,00',
    );
    await at.tap(find.text('Aplicar filtros'));
    await at.pumpAndSettle();
    expect(
      find.text('O preço máximo deve ser maior ou igual ao mínimo.'),
      findsOneWidget,
    );
    await at.enterText(
      find.byKey(const Key('filtro-preco-minimo-pichau')),
      '3000,00',
    );
    await at.enterText(
      find.byKey(const Key('filtro-preco-maximo-pichau')),
      '8000,00',
    );
    await at.tap(find.text('Aplicar filtros'));
    await at.pumpAndSettle();
    expect(
      requisicoes.last.url.queryParameters['disponibilidade'],
      'esgotados',
    );
    expect(requisicoes.last.url.queryParameters['ordenar'], 'nome');
    expect(requisicoes.last.url.queryParameters['preco_min'], '3000,00');
    expect(requisicoes.last.url.queryParameters['preco_max'], '8000,00');

    await at.tap(find.text('Todos'));
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('acompanhar-pichau-PG-7800')));
    await at.pumpAndSettle();
    expect(requisicoes.last.method, 'PATCH');
    expect(
      requisicoes.last.url.path,
      '/api/pichau/catalogo/PG-7800/acompanhamento-pessoal',
    );
    expect(jsonDecode(requisicoes.last.body)['ativo'], isTrue);
    expect(find.text('Acompanhando'), findsOneWidget);
  });

  testWidgets(
    'acompanhamento pessoal funciona para qualquer usuário e reverte em erro',
    (at) async {
      final requisicoes = <http.Request>[];
      await at.pumpWidget(_tela(_api(requisicoes: requisicoes)));
      await at.pumpAndSettle();
      expect(
        at
            .widget<OutlinedButton>(
              find.byKey(const Key('acompanhar-pichau-PG-7800')),
            )
            .onPressed,
        isNotNull,
      );

      final requisicoesComFalha = <http.Request>[];
      await at.pumpWidget(
        _tela(
          _api(requisicoes: requisicoesComFalha, falharAcompanhamento: true),
        ),
      );
      await at.pumpAndSettle();
      await at.tap(find.byKey(const Key('acompanhar-pichau-PG-7800')));
      await at.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('acompanhar-pichau-PG-7800')),
          matching: find.text('Acompanhar'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Não foi possível salvar o acompanhamento.'),
        findsOneWidget,
      );
    },
  );
}
