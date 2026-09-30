import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/componentes/fundacao_visual.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';
import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/alertas/pagina_alertas.dart';
import 'package:app_robo/features/alertas/modelo_item_alerta.dart';
import 'package:app_robo/features/alertas/pagina_detalhe_alerta.dart';

const _alertas =
    '{"itens":['
    '{"id":"1","origem":"pichau","tipo":"preco",'
    '"entidade_id":"10","entidade_nome":"PC Gamer Ryzen 5",'
    '"coleta_id":"20","valor_anterior":"4199.90",'
    '"valor_atual":"3999.90","unidade":"reais",'
    '"direcao":"reducao","lido":false,'
    '"criado_em":"2026-09-20T12:02:00Z"},'
    '{"id":"2","origem":"livelo","tipo":"pontuacao",'
    '"entidade_id":"11","entidade_nome":"Natura",'
    '"coleta_id":"21","valor_anterior":"4",'
    '"valor_atual":"8","unidade":"pontos_por_real",'
    '"direcao":"aumento","lido":true,'
    '"criado_em":"2026-09-19T12:10:00Z"}],'
    '"nao_lidos":1,"pagina":1,"por_pagina":20,"total_itens":2,'
    '"total_paginas":1,"tem_proxima":false}';

const _preferencias =
    '{"push_global":true,"preco":false,"cashback":true,"pontuacao":false}';

const _itemPichau =
    '{"origem":"pichau","item":{'
    '"id_externo":"pc-10","sku":"SKU-10",'
    '"nome":"PC Gamer Ryzen 5", "marca":"Pichau",'
    '"categoria_externa":"PC Gamer",'
    '"url_produto":"https://www.pichau.com.br/pc-10",'
    '"presente_no_catalogo":true,"disponibilidade":"disponivel",'
    '"preco_original_texto":"R\$ 4.199,90",'
    '"preco_pix_texto":"R\$ 3.999,90",'
    '"desconto_pix_texto":"5% de desconto no Pix",'
    '"preco_cartao_texto":"R\$ 4.399,90",'
    '"parcelamento":"12x no cartão","sem_juros":false,'
    '"etiquetas":["PC Gamer"],"atualizado_em":null,'
    '"acompanhada":false}}';

Api _api({
  Future<http.Response?> Function(http.Request request)? responder,
  List<http.Request>? requisicoes,
}) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((request) async {
      requisicoes?.add(request);
      final personalizada = await responder?.call(request);
      if (personalizada != null) return personalizada;
      if (request.url.path == '/api/alertas' && request.method == 'GET') {
        return http.Response(_alertas, 200);
      }
      if (request.url.path == '/api/alertas' && request.method == 'PATCH') {
        return http.Response('{"alterados":2,"lido":true}', 200);
      }
      if (request.url.path == '/api/alertas/1/item' &&
          request.method == 'GET') {
        return http.Response(_itemPichau, 200);
      }
      if (request.url.path == '/api/alertas/preferencias' &&
          request.method == 'GET') {
        return http.Response(_preferencias, 200);
      }
      if (request.url.path == '/api/alertas/preferencias' &&
          request.method == 'PATCH') {
        return http.Response(request.body, 200);
      }
      return http.Response('{}', 200);
    }),
  ),
);

Future<void> _abrirPreferencias(
  WidgetTester tester,
  Api api, {
  Future<AuthorizationStatus?> Function()? solicitarPermissao,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: TemaRadar.claro(),
      home: PaginaAlertas(
        api: api,
        solicitarPermissaoNotificacoes: solicitarPermissao,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('preferencias-alertas')));
  await tester.pumpAndSettle();
}

Switch _switch(WidgetTester tester, String chave) => tester.widget<Switch>(
  find.descendant(of: find.byKey(Key(chave)), matching: find.byType(Switch)),
);

Future<void> _rolarPreferenciasAteCTA(WidgetTester tester) async {
  final cta = find.byKey(const Key('permissao-notificacoes-alertas'));
  final rolagem = find.byType(Scrollable).first;
  for (
    var tentativa = 0;
    tentativa < 10 && cta.evaluate().isEmpty;
    tentativa++
  ) {
    await tester.drag(rolagem, const Offset(0, -160));
    await tester.pumpAndSettle();
  }
  expect(cta, findsOneWidget);
  await tester.ensureVisible(cta);
  await tester.pumpAndSettle();
}

Future<void> _rolarFolhaAte(WidgetTester tester, Key chave) async {
  final alvo = find.byKey(chave);
  final modal = find.byKey(const Key('folha-radar-modal'));
  final rolagem = find
      .descendant(of: modal, matching: find.byType(Scrollable))
      .first;
  for (
    var tentativa = 0;
    tentativa < 10 && alvo.evaluate().isEmpty;
    tentativa++
  ) {
    await tester.drag(rolagem, const Offset(0, -120));
    await tester.pumpAndSettle();
  }
  expect(alvo, findsOneWidget);
  await tester.ensureVisible(alvo);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('detalhe alerta adapta os quatro DTOs sem overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final detalhes = <Map<String, dynamic>>[
      {
        'origem': 'livelo',
        'item': {
          'id_externo': 'natura',
          'nome': 'Natura',
          'categorias': ['Beleza'],
          'pontos_atuais': '8.00',
          'pontos_anteriores': '4.00',
          'pontos_base': '1.00',
          'pontos_clube': '10.00',
          'moeda': 'R\$',
          'prefixo_ate': false,
          'em_promocao': true,
          'campanha': 'Campanha especial',
          'descricao_campanha': 'Condições informadas pela Livelo.',
          'inicio_promocao': null,
          'fim_promocao': '2026-10-10T00:00:00Z',
          'acompanhada': false,
          'alerta': true,
          'link': 'https://www.livelo.com.br/',
        },
      },
      {
        'origem': 'inter_cashback',
        'item': {
          'id': 'magalu',
          'slug': 'magalu',
          'nome': 'Magazine Luiza',
          'cashback_principal_texto': 'Até 20% de cashback',
          'cashback_principal_valor': '20.00',
          'cashback_secundario_texto': 'Até 10%',
          'cashback_secundario_valor': '10.00',
          'etiqueta': 'Oferta especial',
          'descricao_principal': 'Oferta da fonte Inter.',
          'descricao_secundaria': null,
          'categoria': 'Eletrônicos',
          'encontrada': true,
          'favorita': false,
          'link': 'https://shopping.inter.co/site-parceiro/lojas/magalu',
        },
      },
      {
        'origem': 'inter_produto',
        'item': {
          'id_externo': 'edge-60',
          'nome': 'Motorola Edge 60 Pro',
          'marca': 'Motorola',
          'categoria': 'Celular',
          'caminho': 'produto/edge-60',
          'preco_cheio_texto': 'R\$ 4.000,00',
          'preco_cheio_valor': '4000',
          'preco_atual_texto': 'R\$ 3.688,89',
          'preco_atual_valor': '3688.89',
          'desconto_texto': null,
          'desconto_percentual_texto': null,
          'cashback_texto': 'R\$ 332,00',
          'cashback_percentual_texto': '9%',
          'preco_liquido_texto': 'R\$ 3.356,89',
          'parcelamento': 'Em 10x sem juros',
          'estoque': 4,
          'etiquetas': ['Frete grátis'],
          'loja_slug': 'casas-bahia',
          'loja_nome': 'Casas Bahia',
          'atualizada_em': '2026-09-28T12:00:00Z',
          'acompanhado': false,
          'ativo': true,
        },
      },
      jsonDecode(_itemPichau) as Map<String, dynamic>,
    ].map(ItemResolvidoAlerta.parse).toList(growable: false);

    for (final detalhe in detalhes) {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaRadar.claro(),
          home: PaginaDetalheAlerta(api: _api(), detalhe: detalhe),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('voltar-detalhe-alerta')), findsOneWidget);
      if (detalhe.origem == OrigemItemAlerta.interProduto ||
          detalhe.origem == OrigemItemAlerta.pichau) {
        expect(find.text('Disponível'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('detalhe não afirma disponibilidade quando o dado está ausente', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final respostaPichau = Map<String, dynamic>.from(
      jsonDecode(_itemPichau) as Map<String, dynamic>,
    );
    final itemPichau = Map<String, dynamic>.from(
      respostaPichau['item'] as Map<String, dynamic>,
    );
    itemPichau['disponibilidade'] = null;
    respostaPichau['item'] = itemPichau;

    final respostaPichauEsgotado = Map<String, dynamic>.from(
      jsonDecode(_itemPichau) as Map<String, dynamic>,
    );
    final itemPichauEsgotado = Map<String, dynamic>.from(
      respostaPichauEsgotado['item'] as Map<String, dynamic>,
    );
    itemPichauEsgotado['disponibilidade'] = 'esgotado';
    respostaPichauEsgotado['item'] = itemPichauEsgotado;

    final casos = <(ItemResolvidoAlerta, String)>[
      (
        ItemResolvidoAlerta.parse({
          'origem': 'inter_produto',
          'item': {
            'id_externo': 'edge-60',
            'nome': 'Motorola Edge 60 Pro',
            'caminho': 'produto/edge-60',
            'estoque': null,
            'loja_slug': 'casas-bahia',
            'loja_nome': 'Casas Bahia',
            'ativo': true,
          },
        }),
        'Disponibilidade não informada',
      ),
      (
        ItemResolvidoAlerta.parse(respostaPichau),
        'Disponibilidade não informada',
      ),
      (
        ItemResolvidoAlerta.parse({
          'origem': 'inter_produto',
          'item': {
            'id_externo': 'edge-60',
            'nome': 'Motorola Edge 60 Pro',
            'caminho': 'produto/edge-60',
            'estoque': 0,
            'loja_slug': 'casas-bahia',
            'loja_nome': 'Casas Bahia',
            'ativo': true,
          },
        }),
        'Esgotado',
      ),
      (ItemResolvidoAlerta.parse(respostaPichauEsgotado), 'Esgotado'),
    ];

    for (final (detalhe, statusEsperado) in casos) {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaRadar.claro(),
          home: PaginaDetalheAlerta(api: _api(), detalhe: detalhe),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(statusEsperado), findsOneWidget);
      if (statusEsperado == 'Disponibilidade não informada') {
        expect(find.text('Disponível'), findsNothing);
      }
      expect(tester.takeException(), isNull);

      if (detalhe.origem == OrigemItemAlerta.pichau &&
          statusEsperado == 'Disponibilidade não informada') {
        final precoFinder = find.text('R\$ 3.999,90');
        await tester.scrollUntilVisible(
          precoFinder,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        final preco = tester.widget<Text>(precoFinder);
        expect(preco.style?.fontSize, 30);
        expect(preco.style?.fontWeight, FontWeight.w800);
        expect(preco.style?.letterSpacing, -1);
        expect(preco.style?.height, 1.2);
      }
    }
  });

  testWidgets('acompanhar usa o fundo semântico no claro e no escuro', (
    tester,
  ) async {
    final detalhe = ItemResolvidoAlerta.parse({
      'origem': 'inter_produto',
      'item': {
        'id_externo': 'edge-60',
        'nome': 'Motorola Edge 60 Pro',
        'caminho': 'produto/edge-60',
        'preco_atual_texto': 'R\$ 3.688,89',
        'preco_atual_valor': '3688.89',
        'loja_slug': 'casas-bahia',
        'loja_nome': 'Casas Bahia',
        'acompanhado': false,
        'ativo': true,
      },
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    for (final tema in [TemaRadar.claro(), TemaRadar.escuro()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: tema,
          home: PaginaDetalheAlerta(
            key: ValueKey(tema.brightness),
            api: _api(),
            detalhe: detalhe,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final acompanhar = find.byKey(const Key('acompanhar-detalhe-alerta'));
      await tester.ensureVisible(acompanhar);
      await tester.tap(acompanhar);
      await tester.pumpAndSettle();

      final botao = tester.widget<OutlinedButton>(acompanhar);
      expect(
        botao.style?.backgroundColor?.resolve({}),
        tema.extension<CoresRadar>()!.acaoFundo,
      );
    }
  });

  testWidgets('Ver item marca lido, abre o DTO e retorna à mesma Central', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('abrir-central-detalhe-teste'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PaginaAlertas(
                    api: _api(
                      requisicoes: requisicoes,
                      responder: (request) async =>
                          request.url.path == '/api/alertas/1/item'
                          ? http.Response(_itemPichau, 200)
                          : null,
                    ),
                  ),
                ),
              ),
              child: const Text('Abrir Central'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('abrir-central-detalhe-teste')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver item').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('detalhe-alerta-pichau')), findsOneWidget);
    expect(
      requisicoes.any(
        (request) =>
            request.method == 'PATCH' &&
            request.url.path == '/api/alertas/1/leitura',
      ),
      isTrue,
    );
    final resolver = requisicoes.singleWhere(
      (request) => request.url.path == '/api/alertas/1/item',
    );
    expect(resolver.method, 'GET');
    expect(resolver.headers['authorization'], 'Bearer token-teste');

    await tester.tap(find.byKey(const Key('voltar-detalhe-alerta')));
    await tester.pumpAndSettle();
    expect(find.text('Abrir Central'), findsNothing);
    expect(find.byType(PaginaAlertas), findsOneWidget);
    expect(find.byKey(const Key('preferencias-alertas')), findsOneWidget);

    await tester.tap(find.text('Ver item').first);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(PaginaAlertas), findsOneWidget);
    expect(find.text('PC Gamer Ryzen 5'), findsOneWidget);
  });

  testWidgets('erro transitório oferece nova tentativa e 404 usa fallback', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final fallback = <AlertaApp>[];
    var tentativas = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaAlertas(
          api: _api(
            requisicoes: requisicoes,
            responder: (request) async {
              if (request.url.path == '/api/alertas/1/item') {
                tentativas++;
                return tentativas == 1
                    ? http.Response('{"erro":{"codigo":"inesperado"}}', 503)
                    : http.Response(
                        '{"erro":{"codigo":"nao-encontrado"}}',
                        404,
                      );
              }
              return null;
            },
          ),
          aoAbrirItem: fallback.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver item').first);
    await tester.pumpAndSettle();

    expect(find.byType(PaginaAlertas), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(fallback, isEmpty);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(tentativas, 2);
    expect(fallback.single.origem, 'pichau');
    expect(find.byKey(const Key('detalhe-alerta-pichau')), findsNothing);
    expect(find.byType(PaginaAlertas), findsOneWidget);
    expect(
      requisicoes.where(
        (request) =>
            request.method == 'PATCH' &&
            request.url.path == '/api/alertas/1/leitura',
      ),
      hasLength(1),
    );
  });

  testWidgets('Central segue a composição de alertas do V15', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaAlertas(api: _api()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mudou. Você viu.'), findsOneWidget);
    expect(find.text('Mudanças nos itens que você acompanha.'), findsOneWidget);
    expect(find.text('Todos'), findsWidgets);
    expect(find.text('Não lidos'), findsOneWidget);
    expect(find.text('Últimos 90 dias'), findsOneWidget);
    expect(find.byKey(const Key('voltar-alertas')), findsOneWidget);
    expect(find.byKey(const Key('filtrar-alertas')), findsOneWidget);
    expect(find.byKey(const Key('marcar-todos-alertas')), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.byKey(const Key('barra-inferior-v15')), findsOneWidget);
    expect(find.text('O preço Pix caiu'), findsOneWidget);
    expect(find.text('Mais pontos na loja'), findsOneWidget);
    expect(find.text('PC Gamer Ryzen 5'), findsOneWidget);
    expect(find.text('4 pts/R\$ 1'), findsOneWidget);
  });

  testWidgets('botão Voltar da Central retorna à rota anterior', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('abrir-alertas-teste'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PaginaAlertas(api: _api()),
                ),
              ),
              child: const Text('Abrir alertas'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('abrir-alertas-teste')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('voltar-alertas')));
    await tester.pumpAndSettle();

    expect(find.text('Abrir alertas'), findsOneWidget);
    expect(find.byType(PaginaAlertas), findsNothing);
  });

  testWidgets('barra da Central mantém seleção e oferece os quatro destinos', (
    tester,
  ) async {
    final destinos = <DestinoCompacto>[];
    const destinosFixos = [
      DestinoCompacto.inicio,
      DestinoCompacto.explorar,
      DestinoCompacto.radar,
      DestinoCompacto.perfil,
    ];
    for (var indice = 0; indice < destinosFixos.length; indice++) {
      await tester.pumpWidget(
        MaterialApp(
          theme: TemaRadar.claro(),
          home: PaginaAlertas(
            api: _api(),
            destinoSelecionado: destinosFixos[indice],
            aoNavegar: destinos.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NavigationBar>(find.byKey(const Key('barra-inferior-v15')))
            .selectedIndex,
        indice,
      );
    }

    for (final destino in destinosFixos) {
      await tester.tap(find.byKey(Key('barra-${destino.name}')));
      await tester.pumpAndSettle();
    }
    expect(destinos, [
      DestinoCompacto.inicio,
      DestinoCompacto.explorar,
      DestinoCompacto.radar,
      DestinoCompacto.perfil,
    ]);
  });

  testWidgets('filtro abre a folha sem trocar a composição da tela', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaAlertas(api: _api(requisicoes: requisicoes)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filtrar-alertas')));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar mudanças'), findsOneWidget);
    expect(find.text('Origem'), findsOneWidget);
    expect(find.text('Tipo de mudança'), findsOneWidget);
    expect(find.text('Aplicar'), findsOneWidget);
    expect(find.text('Todas as origens'), findsOneWidget);
    expect(find.byKey(const Key('origem-alertas')), findsOneWidget);
    expect(find.byKey(const Key('tipo-alertas')), findsOneWidget);
    expect(find.byKey(const Key('voltar-folha-radar')), findsNothing);
    expect(find.byKey(const Key('fechar-folha-radar')), findsOneWidget);
    expect(find.text('Escolha a origem e o tipo de mudança.'), findsNothing);

    await tester.tap(find.byKey(const Key('origem-alertas')));
    await tester.pumpAndSettle();
    expect(find.text('Todas as origens'), findsWidgets);
    expect(find.text('Sites parceiros'), findsOneWidget);
    expect(find.text('Compre direto'), findsOneWidget);
    expect(find.text('Livelo'), findsOneWidget);
    expect(find.text('Pichau'), findsOneWidget);
    await tester.tap(find.text('Compre direto').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tipo-alertas')));
    await tester.pumpAndSettle();
    expect(find.text('Todos'), findsWidgets);
    expect(find.text('Preço'), findsOneWidget);
    expect(find.text('Cashback'), findsOneWidget);
    expect(find.text('Pontos'), findsOneWidget);
    await tester.tap(find.text('Preço').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('aplicar-filtros-alertas')));
    await tester.pumpAndSettle();

    var consulta = requisicoes
        .where(
          (request) =>
              request.method == 'GET' && request.url.path == '/api/alertas',
        )
        .last
        .url
        .queryParameters;
    expect(consulta['origem'], 'inter_produto');
    expect(consulta['tipo'], 'preco');
    expect(consulta['pagina'], '1');
    expect(consulta.containsKey('somente_nao_lidos'), isFalse);

    await tester.tap(find.byKey(const Key('aba-radar-1')));
    await tester.pumpAndSettle();
    consulta = requisicoes
        .where(
          (request) =>
              request.method == 'GET' && request.url.path == '/api/alertas',
        )
        .last
        .url
        .queryParameters;
    expect(consulta['origem'], 'inter_produto');
    expect(consulta['tipo'], 'preco');
    expect(consulta['somente_nao_lidos'], 'true');
    expect(consulta['pagina'], '1');
    expect(
      tester
          .widget<AbasRadar>(find.byKey(const Key('abas-alertas')))
          .selecionada,
      1,
    );

    await tester.tap(find.byKey(const Key('filtrar-alertas')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('origem-alertas')),
        matching: find.text('Compre direto'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('tipo-alertas')),
        matching: find.text('Preço'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('preferências leem e gravam estado completo em PATCH', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final patchPendente = Completer<http.Response>();
    await _abrirPreferencias(
      tester,
      _api(
        requisicoes: requisicoes,
        responder: (request) async {
          if (request.url.path == '/api/alertas/preferencias' &&
              request.method == 'PATCH') {
            return patchPendente.future;
          }
          return null;
        },
      ),
    );

    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Só o que importa.'), findsOneWidget);
    expect(
      find.text(
        'A Central continua disponível mesmo sem notificações no aparelho.',
      ),
      findsOneWidget,
    );
    expect(find.text('Notificações no aparelho'), findsOneWidget);
    expect(find.text('Receber avisos de novas mudanças.'), findsOneWidget);
    expect(find.text('Preço'), findsOneWidget);
    expect(find.text('Aumento ou redução do preço.'), findsOneWidget);
    expect(find.text('Cashback'), findsOneWidget);
    expect(find.text('Mudanças no benefício publicado.'), findsOneWidget);
    expect(find.text('Pontos'), findsOneWidget);
    expect(find.text('Mudanças na pontuação comum.'), findsOneWidget);
    expect(_switch(tester, 'preferencia-preco').value, isFalse);

    await tester.tap(find.byKey(const Key('preferencia-preco')));
    await tester.pump();
    final patches = requisicoes
        .where(
          (request) =>
              request.url.path == '/api/alertas/preferencias' &&
              request.method == 'PATCH',
        )
        .toList();
    expect(patches, hasLength(1));
    expect(jsonDecode(patches.single.body), {
      'push_global': true,
      'preco': true,
      'cashback': true,
      'pontuacao': false,
    });
    expect(_switch(tester, 'preferencia-preco').value, isTrue);

    await tester.tap(find.byKey(const Key('preferencia-cashback')));
    await tester.pump();
    expect(_switch(tester, 'preferencia-cashback').value, isTrue);
    expect(
      requisicoes
          .where(
            (request) =>
                request.url.path == '/api/alertas/preferencias' &&
                request.method == 'PATCH',
          )
          .length,
      1,
    );

    patchPendente.complete(http.Response(patches.single.body, 200));
    await tester.pumpAndSettle();
    expect(_switch(tester, 'preferencia-preco').value, isTrue);
  });

  testWidgets('erro no GET de preferências mostra falha e opção de tentar', (
    tester,
  ) async {
    await _abrirPreferencias(
      tester,
      _api(
        responder: (request) async {
          if (request.url.path == '/api/alertas/preferencias' &&
              request.method == 'GET') {
            return http.Response('{}', 503);
          }
          return null;
        },
      ),
    );

    expect(
      find.text('Não foi possível carregar as preferências agora.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(
      find.byKey(const Key('voltar-notificacoes-alertas')),
      findsOneWidget,
    );
  });

  testWidgets('erro no PATCH restaura o valor confirmado e avisa', (
    tester,
  ) async {
    await _abrirPreferencias(
      tester,
      _api(
        responder: (request) async {
          if (request.url.path == '/api/alertas/preferencias' &&
              request.method == 'PATCH') {
            return http.Response('{}', 503);
          }
          return null;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('preferencia-preco')));
    await tester.pumpAndSettle();

    expect(_switch(tester, 'preferencia-preco').value, isFalse);
    expect(
      find.text('Não foi possível salvar as preferências.'),
      findsOneWidget,
    );
  });

  testWidgets('CTA abre a folha e delega a escolha sem plugin nativo', (
    tester,
  ) async {
    var solicitacoes = 0;
    await _abrirPreferencias(
      tester,
      _api(),
      solicitarPermissao: () async {
        solicitacoes++;
        return AuthorizationStatus.denied;
      },
    );

    await _rolarPreferenciasAteCTA(tester);
    await tester.tap(find.byKey(const Key('permissao-notificacoes-alertas')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('folha-radar-modal')), findsOneWidget);
    expect(find.text('Mudou. Te avisamos.'), findsOneWidget);
    expect(
      find.text(
        'Receba avisos sobre os itens que você acompanha. A Central funciona mesmo se você preferir não receber.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('voltar-folha-radar')), findsNothing);
    expect(find.byKey(const Key('fechar-folha-radar')), findsOneWidget);
    expect(solicitacoes, 0);

    await _rolarFolhaAte(tester, const Key('agora-nao-permissao-alertas'));
    await tester.tap(find.byKey(const Key('agora-nao-permissao-alertas')));
    await tester.pumpAndSettle();
    expect(find.text('Notificações'), findsOneWidget);
    expect(
      find.byKey(const Key('voltar-notificacoes-alertas')),
      findsOneWidget,
    );

    await _rolarPreferenciasAteCTA(tester);
    await tester.tap(find.byKey(const Key('permissao-notificacoes-alertas')));
    await tester.pumpAndSettle();
    await _rolarFolhaAte(tester, const Key('permitir-permissao-alertas'));
    await tester.tap(find.byKey(const Key('permitir-permissao-alertas')));
    await tester.pumpAndSettle();

    expect(solicitacoes, 1);
    await _rolarFolhaAte(tester, const Key('resultado-permissao-alertas'));
    expect(
      find.text(
        'Notificações não foram permitidas. A Central de Alertas continua disponível.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('folha-radar-modal')), findsOneWidget);
  });

  testWidgets('Notificações e folha mantêm ações roláveis com texto a 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: PaginaAlertas(api: _api()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preferencias-alertas')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _rolarPreferenciasAteCTA(tester);
    await tester.tap(find.byKey(const Key('permissao-notificacoes-alertas')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await _rolarFolhaAte(tester, const Key('permitir-permissao-alertas'));
    expect(
      find.byKey(const Key('agora-nao-permissao-alertas')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('permitir-permissao-alertas')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('back visível e Android retornam à Central preservada', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('abrir-alertas-com-pilha'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PaginaAlertas(api: _api()),
                ),
              ),
              child: const Text('Origem'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('abrir-alertas-com-pilha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preferencias-alertas')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('voltar-notificacoes-alertas')));
    await tester.pumpAndSettle();

    expect(find.byType(PaginaAlertas), findsOneWidget);
    expect(find.byKey(const Key('preferencias-alertas')), findsOneWidget);
    expect(find.text('Origem'), findsNothing);

    await tester.tap(find.byKey(const Key('preferencias-alertas')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(PaginaAlertas), findsOneWidget);
    expect(find.byKey(const Key('preferencias-alertas')), findsOneWidget);
    expect(find.text('Origem'), findsNothing);
  });

  testWidgets('navegação inferior fecha preferências e delega o destino', (
    tester,
  ) async {
    final destinos = <DestinoCompacto>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('abrir-central-com-navegacao'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PaginaAlertas(
                    api: _api(),
                    aoNavegar: (destino) {
                      destinos.add(destino);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
              child: const Text('Origem'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('abrir-central-com-navegacao')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('preferencias-alertas')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('barra-explorar')));
    await tester.pumpAndSettle();

    expect(destinos, [DestinoCompacto.explorar]);
    expect(find.byType(PaginaAlertas), findsNothing);
    expect(find.text('Origem'), findsOneWidget);
    expect(find.text('Só o que importa.'), findsNothing);
  });

  testWidgets('Central não estoura em largura estreita com fonte ampliada', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: PaginaAlertas(api: _api()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Mudou. Você viu.'), findsOneWidget);
  });
}
