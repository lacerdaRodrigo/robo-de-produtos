import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/componentes/fundacao_visual.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/paginas/lojas.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/inter/cartao_cashback_inter.dart';
import 'package:app_robo/features/inter/controlador_cashback_inter.dart';
import 'package:app_robo/features/inter/pagina_cashback_inter.dart';

CashbackInter _loja({
  String nome = 'Magazine Luiza',
  bool encontrada = true,
  bool favorita = false,
  String? categoria = 'Eletrônicos',
  String? secundaria = '2% de cashback',
  String? descricaoPrincipal = 'Em itens selecionados',
  String? descricaoSecundaria,
  String? link = 'https://shopping.inter.co/site-parceiro/lojas/magazine-luiza',
}) => CashbackInter(
  id: nome.toLowerCase(),
  slug: nome.toLowerCase(),
  nome: nome,
  cashbackPrincipalTexto: 'Até 12% de cashback',
  cashbackPrincipalValor: '12.00',
  cashbackSecundarioTexto: secundaria,
  cashbackSecundarioValor: secundaria == null ? null : '2.00',
  etiqueta: 'Oferta especial',
  descricaoPrincipal: descricaoPrincipal,
  descricaoSecundaria:
      descricaoSecundaria ??
      (secundaria == null ? null : 'Para não-correntistas'),
  categoria: categoria,
  encontrada: encontrada,
  favorita: favorita,
  link: link,
);

Pagina<CashbackInter> _pagina(
  List<CashbackInter> itens, {
  int? total,
  int porPagina = 20,
  bool proxima = false,
  String? atualizadaEm = '2026-08-22T12:00:00Z',
  String? ultimaTentativaEstado,
}) => Pagina(
  itens: itens,
  pagina: 1,
  porPagina: porPagina,
  totalItens: total ?? itens.length,
  totalPaginas: proxima ? 2 : 1,
  temProxima: proxima,
  atualizadoEm: atualizadaEm,
  ultimaTentativaEstado: ultimaTentativaEstado,
);

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      if (requisicao.url.path == '/api/inter/cashback/categorias') {
        return http.Response(
          jsonEncode({
            'categorias': [
              {'codigo': 'beleza', 'nome': 'Beleza'},
              {'codigo': 'casa', 'nome': 'Casa'},
              {'codigo': 'eletronicos', 'nome': 'Eletrônicos'},
              {'codigo': 'esporte', 'nome': 'Esporte'},
              {'codigo': 'moda', 'nome': 'Moda'},
              {'codigo': 'outros', 'nome': 'Outros'},
              {'codigo': 'pets', 'nome': 'Pets'},
            ],
          }),
          200,
        );
      }
      return http.Response('{}', 500);
    }),
  ),
);

Widget _tela(ControladorCashbackInter controlador) => MaterialApp(
  theme: TemaRadar.claro(),
  home: Scaffold(
    body: PaginaCashbackInter(api: _api(), controlador: controlador),
  ),
);

Widget _telaCompacta(ControladorCashbackInter controlador) => MaterialApp(
  theme: TemaRadar.claro(),
  home: Scaffold(
    body: PaginaCashbackInter(
      api: _api(),
      controlador: controlador,
      incorporada: true,
    ),
  ),
);

void main() {
  testWidgets('mostra carregamento, filtros, cartão e condições secundárias', (
    at,
  ) async {
    final resposta = Completer<Pagina<CashbackInter>>();
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) =>
          resposta.future,
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    expect(find.text('Carregando cashback do Inter…'), findsOneWidget);

    resposta.complete(_pagina([_loja()]));
    await at.pumpAndSettle();

    expect(find.byType(CampoBuscaRadar), findsOneWidget);
    expect(find.text('Maior cashback'), findsOneWidget);
    expect(find.text('Nome A–Z'), findsOneWidget);
    expect(find.text('Magazine Luiza'), findsOneWidget);
    expect(
      find.byKey(const Key('alerta-inter-magazine luiza')),
      findsOneWidget,
    );
    final beneficio = find.text('Até 12% de cashback');
    expect(beneficio, findsOneWidget);
    final estiloBeneficio = at.widget<Text>(beneficio).style!;
    expect(estiloBeneficio.fontSize, 30);
    expect(estiloBeneficio.fontWeight, FontWeight.w800);
    expect(estiloBeneficio.height, 1.2);
    expect(estiloBeneficio.letterSpacing, -1);
    expect(
      estiloBeneficio.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(find.text('Para correntista'), findsOneWidget);
    expect(find.text('Para não-correntista'), findsOneWidget);
    expect(find.text('Para correntista'), findsOneWidget);
    expect(find.textContaining('Oferta especial'), findsOneWidget);
    expect(find.text('Para não-correntista'), findsOneWidget);
    await at.tap(find.text('Para não-correntista'));
    await at.pumpAndSettle();
    expect(find.textContaining('Para não-correntistas'), findsOneWidget);
    expect(controlador.temProxima, isFalse);
  });

  testWidgets('folha de filtros mantém a ordem e as categorias do protótipo', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(390, 844);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    String? categoriaConsultada;
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina([_loja()]),
      buscarComCategoria:
          ({
            required q,
            required ordenar,
            required categoria,
            required pagina,
          }) async {
            categoriaConsultada = categoria;
            return _pagina([_loja()]);
          },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_telaCompacta(controlador));
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('abrir-filtros-cashback-inter')));
    await at.pumpAndSettle();

    expect(find.text('Filtros · Sites parceiros'), findsOneWidget);
    expect(find.text('Maior cashback'), findsOneWidget);
    expect(find.text('Todas as categorias'), findsOneWidget);
    final ordenarRect = at.getRect(
      find.byKey(const Key('filtro-ordenacao-cashback-inter')),
    );
    final categoriaRect = at.getRect(
      find.byKey(const Key('filtro-categoria-cashback-inter')),
    );
    expect(categoriaRect.left, closeTo(ordenarRect.left, 0.1));
    expect(categoriaRect.right, closeTo(ordenarRect.right, 0.1));
    expect(ordenarRect.height, greaterThanOrEqualTo(48));
    expect(categoriaRect.height, greaterThanOrEqualTo(48));

    await at.tap(find.byKey(const Key('filtro-ordenacao-cashback-inter')));
    await at.pumpAndSettle();
    final maiorCashback = find.text('Maior cashback');
    final nomeDaLoja = find.text('Nome da loja');
    expect(maiorCashback, findsWidgets);
    expect(nomeDaLoja, findsOneWidget);
    expect(
      at.getTopLeft(maiorCashback.last).dy,
      lessThan(at.getTopLeft(nomeDaLoja).dy),
    );

    await at.tap(find.text('Nome da loja'));
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('filtro-categoria-cashback-inter')));
    await at.pumpAndSettle();
    for (final categoria in const [
      'Todas as categorias',
      'Beleza',
      'Casa',
      'Eletrônicos',
      'Esporte',
      'Moda',
      'Outros',
      'Pets',
    ]) {
      expect(find.text(categoria), findsWidgets);
    }

    await at.tap(find.text('Moda'));
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('aplicar-filtros-cashback-inter')));
    await at.pumpAndSettle();

    expect(controlador.categoria, 'moda');
    expect(categoriaConsultada, 'moda');

    await at.tap(find.byKey(const Key('abrir-filtros-cashback-inter')));
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('limpar-filtros-cashback-inter')));
    await at.pumpAndSettle();

    expect(controlador.categoria, isNull);
    expect(categoriaConsultada, isNull);
  });

  testWidgets('separa falha recente, atraso e loja ausente', (at) async {
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina(
            [_loja(nome: 'Loja ausente', encontrada: false, secundaria: null)],
            atualizadaEm: '2020-01-01T00:00:00Z',
            ultimaTentativaEstado: 'falha',
          ),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();

    expect(find.textContaining('dados atrasados'), findsOneWidget);
    expect(
      find.text(
        'A última sincronização do Inter falhou. Exibindo a última coleta válida.',
      ),
      findsOneWidget,
    );
    expect(find.text('Não encontrada na última coleta'), findsOneWidget);
  });

  testWidgets('Cashback compacto mostra a lista e filtra pelo No radar', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(390, 844);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina([
            _loja(nome: 'Animale'),
            _loja(nome: 'Aramis', favorita: true),
          ]),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_telaCompacta(controlador));
    await at.pumpAndSettle();

    expect(find.text('Animale'), findsOneWidget);
    expect(find.text('Aramis'), findsOneWidget);
    expect(find.text('2 lojas'), findsOneWidget);
    expect(find.text('Lojas com cashback'), findsOneWidget);
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.byKey(const Key('paginacao-radar-1')), findsNothing);
    expect(find.text('Maior cashback'), findsNothing);
    expect(find.byKey(const Key('filtros-cashback-inter')), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('No radar'), findsOneWidget);
    expect(
      at.getTopLeft(find.text('2 lojas')).dy,
      greaterThan(
        at.getBottomLeft(find.byKey(const Key('filtros-cashback-inter'))).dy,
      ),
    );

    await at.tap(find.text('No radar'));
    await at.pumpAndSettle();

    expect(find.text('Animale'), findsNothing);
    expect(find.text('Aramis'), findsOneWidget);
    expect(find.text('Acompanhando'), findsOneWidget);
    expect(find.byKey(const Key('paginacao-radar-1')), findsNothing);
  });

  testWidgets('busca compacta do Inter espera o envio do termo', (at) async {
    final consultas = <String>[];
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        consultas.add(q);
        return _pagina([_loja()]);
      },
    );
    addTearDown(controlador.dispose);
    await at.pumpWidget(_telaCompacta(controlador));
    await at.pumpAndSettle();
    expect(consultas, ['']);

    await at.enterText(find.byKey(const Key('busca-cashback-inter')), 'casas');
    await at.pumpAndSettle();
    expect(consultas, ['']);

    await at.testTextInput.receiveAction(TextInputAction.search);
    await at.pumpAndSettle();
    expect(consultas, ['', 'casas']);
  });

  testWidgets('puxar e voltar ao app atualizam cashback e resumo', (at) async {
    var consultas = 0;
    var atualizacoesResumo = 0;
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        consultas++;
        return _pagina([_loja()]);
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaCashbackInter(
            api: _api(),
            controlador: controlador,
            incorporada: true,
            aoAtualizar: () async => atualizacoesResumo++,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();
    expect(consultas, 1);

    await at.drag(
      find.byKey(const Key('cashback-inter-compacto')),
      const Offset(0, 360),
    );
    await at.pumpAndSettle();
    expect(consultas, 2);
    expect(atualizacoesResumo, 1);

    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await at.pumpAndSettle();
    expect(consultas, 3);
    expect(atualizacoesResumo, 2);
  });

  testWidgets('acompanhar sincroniza painel e aba antes e depois da API', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(390, 844);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    var acompanhada = false;
    var alteracoes = 0;
    var consultasGlobais = 0;
    final primeiraAlteracao = Completer<void>();
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          if (requisicao.url.path == '/api/resumo') {
            return http.Response(
              jsonEncode({
                'gerado_em': '2026-08-23T12:00:00Z',
                'estado_geral': 'atualizado',
                'livelo': {
                  'estado': 'sem_dados',
                  'ultimo_sucesso_em': null,
                  'lojas_acompanhadas': 0,
                  'alertas_ultima_coleta': 0,
                },
                'cashback_inter': {
                  'estado': 'atualizado',
                  'ultima_tentativa_em': '2026-08-23T12:00:00Z',
                  'ultima_tentativa_estado': 'sucesso',
                  'ultimo_sucesso_em': '2026-08-23T12:00:00Z',
                  'lojas_acompanhadas': 0,
                  'lojas_encontradas_ultima_coleta': 0,
                },
                'produtos': {
                  'estado': 'sem_dados',
                  'ultima_tentativa_em': null,
                  'ultima_tentativa_estado': null,
                  'dados_mais_antigos_em': null,
                  'dados_mais_recentes_em': null,
                  'qualidade': null,
                  'lojas_selecionadas': 0,
                  'lojas_sem_coleta': 0,
                  'produtos_ativos': 0,
                },
              }),
              200,
            );
          }
          if (requisicao.url.path == '/api/inter/cashback') {
            if (requisicao.url.queryParameters['escopo'] == 'global') {
              consultasGlobais++;
            }
            final somenteAcompanhadas =
                requisicao.url.queryParameters['acompanhadas'] == 'true';
            final itens = somenteAcompanhadas && !acompanhada
                ? <Map<String, Object?>>[]
                : [
                    {
                      'id': 'cea',
                      'slug': 'ca',
                      'nome': 'C&A',
                      'cashback_principal_texto': 'Até 10% de cashback',
                      'cashback_principal_valor': '10.00',
                      'cashback_secundario_texto': null,
                      'cashback_secundario_valor': null,
                      'etiqueta': null,
                      'descricao_principal': null,
                      'descricao_secundaria': null,
                      'encontrada': true,
                      'favorita': acompanhada,
                    },
                  ];
            return http.Response(
              jsonEncode({
                'itens': itens,
                'pagina': 1,
                'por_pagina': 20,
                'total_itens': itens.length,
                'total_paginas': 1,
                'tem_proxima': false,
                'atualizado_em': '2026-08-23T12:00:00Z',
              }),
              200,
            );
          }
          if (requisicao.url.path == '/api/inter/cashback/cea/acompanhamento' &&
              requisicao.method == 'PATCH') {
            alteracoes++;
            if (alteracoes == 1) await primeiraAlteracao.future;
            acompanhada =
                (jsonDecode(requisicao.body) as Map<String, dynamic>)['ativo']
                    as bool;
            return http.Response('{}', 200);
          }
          return http.Response('{}', 404);
        }),
      ),
    );

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaHubShoppingInter(
            api: api,
            administrador: true,
            experienciaCompacta: true,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();
    final modoSitesParceiros = find.byKey(const Key('modo-inter-cashback'));
    await at.ensureVisible(modoSitesParceiros);
    await at.tap(modoSitesParceiros);
    await at.pumpAndSettle();
    await at.drag(
      find.byKey(const Key('cashback-inter-compacto')),
      const Offset(0, -520),
    );
    await at.pumpAndSettle();

    final acompanhar = find.byKey(const ValueKey('acompanhar-cea'));
    await Scrollable.ensureVisible(
      at.element(acompanhar),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await at.tap(acompanhar);
    await at.pump();
    expect(find.text('Salvando…'), findsOneWidget);

    final acompanhadas = find.text('No radar');
    await Scrollable.ensureVisible(
      at.element(acompanhadas),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await at.tap(acompanhadas);
    await at.pump();
    expect(find.text('C&A'), findsOneWidget);

    primeiraAlteracao.complete();
    await at.pumpAndSettle();
    expect(find.text('Acompanhando'), findsOneWidget);
    expect(find.text('C&A'), findsOneWidget);

    await at.drag(
      find.byKey(const Key('cashback-inter-compacto')),
      const Offset(0, -220),
    );
    await at.pumpAndSettle();
    await Scrollable.ensureVisible(
      at.element(acompanhar),
      alignment: 0.5,
      duration: Duration.zero,
    );
    await at.tap(acompanhar);
    await at.pumpAndSettle();
    expect(find.text('C&A'), findsNothing);
    expect(find.text('Nenhuma loja está acompanhada ainda.'), findsOneWidget);
    expect(consultasGlobais, 0);
    expect(alteracoes, 2);
  });

  testWidgets('Cashback compacto não estoura em 320 px no tema escuro', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(320, 640);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina([_loja(favorita: true)]),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.escuro(),
        home: Scaffold(
          body: PaginaCashbackInter(
            api: _api(),
            controlador: controlador,
            incorporada: true,
            administrador: true,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
      ),
    );
    await at.pumpAndSettle();
    expect(find.text('Acompanhando'), findsOneWidget);
    expect(find.text('Ir para o Inter'), findsOneWidget);
    expect(at.takeException(), isNull);
    await at.drag(
      find.byKey(const Key('cashback-inter-compacto')),
      const Offset(0, -300),
    );
    await at.pump();
    expect(at.takeException(), isNull);
  });

  testWidgets('ações do card compacto seguem a composição do Pichau', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);

    for (final largura in <double>[320, 390, 430]) {
      at.view.physicalSize = Size(largura, 844);
      await at.pumpWidget(
        MaterialApp(
          theme: TemaRadar.claro(),
          home: Scaffold(
            body: CartaoCashbackInter(
              compacto: true,
              loja: _loja(favorita: true),
              acompanhada: true,
              aoAcompanhar: () {},
              aoAbrirParceiro: () {},
            ),
          ),
        ),
      );
      await at.pumpAndSettle();

      final cartao = at.widget<CartaoRadar>(
        find.descendant(
          of: find.byType(CartaoCashbackInter),
          matching: find.byType(CartaoRadar),
        ),
      );
      expect(cartao.comSombra, isFalse);
      expect(cartao.padding, const EdgeInsets.all(20));
      expect(at.widget<Text>(find.text('Magazine Luiza')).style?.fontSize, 18);

      final acompanhar = find.byKey(
        const ValueKey('acompanhar-magazine luiza'),
      );
      final condicoes = find.byKey(const ValueKey('condicoes-magazine luiza'));
      final irParaInter = find.byKey(const ValueKey('ir-inter-magazine luiza'));
      final topoAcompanhar = at.getTopLeft(acompanhar);
      final topoCondicoes = at.getTopLeft(condicoes);
      final topoIrParaInter = at.getTopLeft(irParaInter);

      if (largura < 340) {
        expect(topoAcompanhar.dx, closeTo(topoCondicoes.dx, 0.1));
        expect(topoAcompanhar.dy, lessThan(topoCondicoes.dy));
      } else {
        expect(topoAcompanhar.dx, lessThan(topoCondicoes.dx));
        expect(topoAcompanhar.dy, closeTo(topoCondicoes.dy, 0.1));
      }
      expect(topoIrParaInter.dy, greaterThan(topoCondicoes.dy));
      expect(at.takeException(), isNull);
    }
  });

  testWidgets('abre condições completas preservando regras e quebra de linha', (
    at,
  ) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: CartaoCashbackInter(
            compacto: true,
            loja: _loja(
              descricaoPrincipal:
                  '20% para o aparelho destacado.\n'
                  '11% em itens vendidos e entregues pela loja.\n'
                  '2% nas demais condições.',
              descricaoSecundaria:
                  '14% no aparelho destacado e 1,4% nas demais.',
            ),
            aoAcompanhar: () {},
          ),
        ),
      ),
    );

    await at.tap(find.byKey(const Key('condicoes-magazine luiza')));
    await at.pumpAndSettle();

    expect(find.byKey(const Key('folha-radar-modal')), findsOneWidget);
    expect(find.text('Condições da oferta'), findsOneWidget);
    expect(
      find.byKey(const Key('condicoes-principal-magazine luiza')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('folha-radar-modal')),
        matching: find.textContaining(
          '11% em itens vendidos e entregues pela loja.',
        ),
      ),
      findsOneWidget,
    );
    final folha = find.byKey(const Key('folha-radar-modal'));
    expect(
      find.descendant(of: folha, matching: find.text('Para não-correntista')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: folha, matching: find.text('2% de cashback')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: folha,
        matching: find.byKey(const Key('condicoes-secundaria-magazine luiza')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: folha,
        matching: find.text('14% no aparelho destacado e 1,4% nas demais.'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'descrição secundária continua legível em tela estreita e texto ampliado',
    (at) async {
      at.view.physicalSize = const Size(320, 640);
      at.view.devicePixelRatio = 1;
      addTearDown(at.view.resetPhysicalSize);
      addTearDown(at.view.resetDevicePixelRatio);

      const descricao =
          '14% no aparelho destacado.\n'
          '1,4% nas demais condições, para compras elegíveis feitas pelo site.';
      await at.pumpWidget(
        MaterialApp(
          theme: TemaRadar.claro(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CartaoCashbackInter(
                compacto: true,
                loja: _loja(descricaoSecundaria: descricao),
                aoAcompanhar: () {},
              ),
            ),
          ),
        ),
      );

      await at.ensureVisible(find.byKey(const Key('condicoes-magazine luiza')));
      await at.tap(find.byKey(const Key('condicoes-magazine luiza')));
      await at.pumpAndSettle();

      final descricaoCompleta = find.byKey(
        const Key('condicoes-secundaria-magazine luiza'),
      );
      expect(descricaoCompleta, findsOneWidget);
      await at.ensureVisible(descricaoCompleta);
      expect(at.takeException(), isNull);
    },
  );

  testWidgets(
    'condições ausentes mostram o estado neutro definido no contrato',
    (at) async {
      await at.pumpWidget(
        MaterialApp(
          theme: TemaRadar.claro(),
          home: Scaffold(
            body: CartaoCashbackInter(
              compacto: true,
              loja: _loja(
                secundaria: null,
                descricaoPrincipal: null,
                descricaoSecundaria: null,
              ),
              aoAcompanhar: () {},
            ),
          ),
        ),
      );

      await at.tap(find.byKey(const Key('condicoes-magazine luiza')));
      await at.pumpAndSettle();

      expect(
        find.text('O Inter não informou condições adicionais nesta consulta'),
        findsOneWidget,
      );
    },
  );

  testWidgets('distingue falha sem retrato, sem coleta e busca vazia', (
    at,
  ) async {
    var chamadas = 0;
    final controlador = ControladorCashbackInter(
      debounce: Duration.zero,
      buscar: ({required q, required ordenar, required pagina}) async {
        chamadas++;
        if (chamadas == 1) {
          return _pagina(
            [],
            atualizadaEm: null,
            ultimaTentativaEstado: 'falha',
          );
        }
        if (chamadas == 2) return _pagina([], atualizadaEm: null);
        return _pagina([], total: 0);
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();
    expect(
      find.text(
        'A última sincronização do Inter falhou. Ainda não há dados válidos para mostrar.',
      ),
      findsOneWidget,
    );

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    expect(find.text('O Inter ainda não foi sincronizado.'), findsOneWidget);

    await controlador.tentarNovamente();
    await at.pumpAndSettle();
    await at.enterText(find.byType(TextField), 'inexistente');
    await at.pumpAndSettle();
    expect(
      find.text('Nenhuma loja encontrada para “inexistente”.'),
      findsOneWidget,
    );
  });

  testWidgets('cartão ausente não se transforma em cashback zero', (at) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: CartaoCashbackInter(loja: _loja(encontrada: false)),
        ),
      ),
    );

    expect(find.text('Não encontrada na última coleta'), findsOneWidget);
    expect(
      find.text('A loja continua acompanhada; a fonte não a retornou.'),
      findsOneWidget,
    );
    expect(find.text('0% de cashback'), findsNothing);
  });

  testWidgets('Sites parceiros abre exatamente a URL real fornecida pela API', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(390, 844);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    Uri? aberta;
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina([_loja(nome: 'C&A')]),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaCashbackInter(
            api: _api(),
            controlador: controlador,
            incorporada: true,
            abrirUrlExterna: (uri) async {
              aberta = uri;
              return true;
            },
          ),
        ),
      ),
    );
    await at.pumpAndSettle();

    final abrirInter = find.byKey(const ValueKey('ir-inter-c&a'));
    await at.tap(abrirInter);
    await at.pumpAndSettle();
    expect(
      aberta,
      Uri.parse('https://shopping.inter.co/site-parceiro/lojas/magazine-luiza'),
    );
  });

  testWidgets('Sites parceiros informa quando o sistema não abre o destino', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(390, 844);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina([_loja(nome: 'C&A')]),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaCashbackInter(
            api: _api(),
            controlador: controlador,
            incorporada: true,
            abrirUrlExterna: (_) async => false,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();

    final abrirInter = find.byKey(const ValueKey('ir-inter-c&a'));
    await at.tap(abrirInter);
    await at.pump();
    expect(find.text('Não foi possível abrir o Banco Inter.'), findsOneWidget);
  });

  testWidgets('falha inicial oferece nova tentativa', (at) async {
    var chamadas = 0;
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        chamadas++;
        if (chamadas == 1) throw StateError('sem rede');
        return _pagina([_loja()]);
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar o cashback do Inter.'),
      findsOneWidget,
    );

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    expect(find.text('Magazine Luiza'), findsOneWidget);
  });

  testWidgets('paginação manual mostra carregamento, retry e duas colunas', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(1100, 1600);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    var falha = true;
    final paginaDois = Completer<Pagina<CashbackInter>>();
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        if (pagina == 1) {
          return _pagina(
            [_loja(), _loja(nome: 'Renner')],
            total: 11,
            porPagina: 10,
            proxima: true,
          );
        }
        if (falha) {
          falha = false;
          throw StateError('sem rede');
        }
        return paginaDois.future;
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();
    expect(find.byType(Wrap), findsNWidgets(2));
    await at.tap(find.byKey(const Key('paginacao-radar-2')));
    await at.pumpAndSettle();
    expect(find.byTooltip('Tentar próxima página'), findsOneWidget);

    await at.tap(find.byTooltip('Tentar próxima página'));
    await at.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    paginaDois.complete(
      Pagina(
        itens: [_loja(nome: 'C&A')],
        pagina: 2,
        porPagina: 10,
        totalItens: 11,
        totalPaginas: 2,
        temProxima: false,
      ),
    );
    await at.pumpAndSettle();
    expect(find.text('C&A'), findsOneWidget);
  });

  testWidgets('página mantém o foco nos Sites parceiros', (at) async {
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina([], atualizadaEm: null),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();

    expect(find.text('Sites parceiros'), findsOneWidget);
    expect(find.byTooltip('Produtos no Inter'), findsNothing);
  });
}
