import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/produtos/cartao_produto.dart';
import 'package:app_robo/features/produtos/controlador_busca_produtos.dart';
import 'package:app_robo/features/produtos/pagina_historico_produto.dart';
import 'package:app_robo/features/produtos/pagina_detalhe_produto.dart';
import 'package:app_robo/features/produtos/pagina_produtos.dart';

ProdutoDireto _produto({
  String id = 'edge',
  String loja = 'Casas Bahia',
  String nome = 'Motorola Edge 60 Pro',
  String? categoria = 'Celular',
  bool acompanhado = false,
}) => ProdutoDireto(
  idExterno: id,
  nome: nome,
  marca: 'Motorola',
  categoria: categoria,
  caminho: 'produto/$id',
  precoCheioTexto: 'R\$ 4.000,00',
  precoCheioValor: '4000',
  precoAtualTexto: 'R\$ 3.688,89',
  precoAtualValor: '3688.89',
  descontoTexto: 'R\$ 311,11',
  descontoPercentualTexto: '8%',
  cashbackTexto: 'R\$ 332,00',
  cashbackPercentualTexto: '9%',
  precoLiquidoTexto: 'R\$ 3.356,89',
  parcelamento: 'Em 10x sem juros',
  estoque: 4,
  etiquetas: const ['Oferta'],
  lojaSlug: loja == 'Casas Bahia' ? 'casas-bahia' : 'ponto',
  lojaNome: loja,
  atualizadaEm: '2026-08-22T12:00:00Z',
  acompanhado: acompanhado,
);

Pagina<ProdutoDireto> _pagina(
  List<ProdutoDireto> itens, {
  int total = 1,
  bool proxima = false,
}) => Pagina(
  itens: itens,
  pagina: 1,
  porPagina: 20,
  totalItens: total,
  totalPaginas: proxima ? 2 : 1,
  temProxima: proxima,
  atualizadoEm: '2026-08-22T12:00:00Z',
  qualidade: 'degradada',
  ultimaTentativaEm: '2026-08-22T13:00:00Z',
  ultimaTentativaEstado: 'parcial',
);

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    cliente: http_testing.MockClient((_) async => http.Response('{}', 500)),
  ),
);

Api _apiFiltros() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      if (requisicao.url.path == '/api/inter/produtos/categorias') {
        return http.Response(
          jsonEncode({
            'configurada': true,
            'itens': [
              {
                'valor': 'Eletrônicos',
                'nome': 'Eletrônicos',
                'selecionada': false,
              },
              {'valor': 'Cabos', 'nome': 'Cabos', 'selecionada': false},
              {'valor': null, 'nome': 'Sem categoria', 'selecionada': false},
            ],
          }),
          200,
        );
      }
      if (requisicao.url.path == '/api/inter/produtos/lojas') {
        return http.Response(
          jsonEncode({
            'itens': [
              {
                'id': 'direta-1',
                'id_externo': 'casas-bahia',
                'slug': 'casas-bahia',
                'nome': 'Casas Bahia',
                'selecionada': true,
                'ativa': true,
              },
              {
                'id': 'direta-2',
                'id_externo': 'ponto',
                'slug': 'ponto',
                'nome': 'Ponto',
                'selecionada': true,
                'ativa': true,
              },
            ],
            'pagina': 1,
            'por_pagina': 20,
            'total_itens': 2,
            'total_paginas': 1,
            'tem_proxima': false,
          }),
          200,
        );
      }
      return http.Response('{}', 500);
    }),
  ),
);

Api _apiHistorico({
  bool primeiraFalha = false,
  bool falhaPaginaDois = false,
  bool? ativo,
}) {
  var chamadas = 0;
  var falhaPaginaDoisPendente = falhaPaginaDois;
  return Api(
    paginaPadrao: 20,
    cliente: ClienteApi(
      baseUrl: 'http://localhost:3000',
      provedorToken: () async => 'token-teste',
      cliente: http_testing.MockClient((requisicao) async {
        chamadas++;
        if (primeiraFalha && chamadas == 1) {
          return http.Response('{"erro":{"codigo":"falha"}}', 500);
        }
        final pagina = requisicao.url.queryParameters['pagina'] ?? '1';
        if (pagina == '2' && falhaPaginaDoisPendente) {
          falhaPaginaDoisPendente = false;
          return http.Response('{"erro":{"codigo":"falha"}}', 500);
        }
        final medicoes = pagina == '2'
            ? [
                {
                  'momento': '2026-08-21T12:00:00Z',
                  'preco_atual_valor': '3600.00',
                  'cashback_valor': '332.00',
                  'preco_liquido_valor': '3268.00',
                },
              ]
            : [
                for (final momento in [
                  '2026-08-22T12:00:00Z',
                  '2026-08-21T12:00:00Z',
                  '2026-08-20T12:00:00Z',
                  '2026-08-20T08:00:00Z',
                  '2026-08-19T12:00:00Z',
                ])
                  {
                    'momento': momento,
                    'preco_atual_valor': '3688.89',
                    'cashback_valor': '332.00',
                    'preco_liquido_valor': '3356.89',
                  },
              ];
        return http.Response(
          jsonEncode({
            'produto': {
              'id_externo': 'edge',
              'nome': 'Motorola Edge 60 Pro',
              'marca': 'Motorola',
              'categoria': 'Celular',
              'caminho': 'produto/edge',
              'preco_cheio_texto': 'R\$ 4.000,00',
              'preco_cheio_valor': '4000',
              'preco_atual_texto': 'R\$ 3.688,89',
              'preco_atual_valor': '3688.89',
              'desconto_texto': null,
              'desconto_percentual_texto': null,
              'cashback_texto': null,
              'cashback_percentual_texto': null,
              'preco_liquido_texto': null,
              'parcelamento': null,
              'estoque': null,
              'etiquetas': <String>[],
              'loja_slug': 'casas-bahia',
              'loja_nome': 'Casas Bahia',
              'atualizada_em': '2026-08-22T12:00:00Z',
              'ativo': ativo,
            },
            'minimo': '3500.00',
            'maximo': '4000.00',
            'medicoes': medicoes,
            'pagina': int.parse(pagina),
            'por_pagina': 5,
            'total_itens': 6,
            'total_paginas': 2,
            'tem_proxima': pagina != '2',
          }),
          200,
        );
      }),
    ),
  );
}

Widget _tela(ControladorBuscaProdutos controlador) => MaterialApp(
  theme: TemaRadar.claro(),
  home: PaginaProdutos(api: _api(), controlador: controlador),
);

void main() {
  testWidgets('oferta compacta identifica loja e Banco Inter', (at) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: CartaoProduto(
              produto: _produto(),
              compacto: true,
              mostrarLoja: false,
              aoAbrirDetalhes: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Casas Bahia'), findsOneWidget);
    expect(find.text('Motorola Edge 60 Pro'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(at.widget<Text>(find.text('Disponível')).textAlign, TextAlign.end);
    expect(
      at.widget<Text>(find.text('R\$ 3.688,89')).style?.fontSize,
      greaterThanOrEqualTo(28),
    );
    final semantica = at.getSemantics(find.byType(CartaoProduto));
    expect(
      semantica.label,
      contains(
        'Oferta Motorola Edge 60 Pro, da loja Casas Bahia, no Banco Inter',
      ),
    );
  });

  testWidgets('título compacto ocupa o card sem truncar o nome', (at) async {
    const nome = 'Fone de ouvido JBL Tune sem fio com cancelamento de ruído';
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: CartaoProduto(
              produto: _produto(nome: nome),
              compacto: true,
              aoAbrirDetalhes: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text(nome), findsOneWidget);
    expect(at.takeException(), isNull);
  });

  testWidgets('oferta compacta exibe sino quando o acompanhamento está ativo', (
    at,
  ) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: CartaoProduto(
            produto: _produto(),
            compacto: true,
            aoAcompanhar: () {},
            aoAbrirDetalhes: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('alerta-produto-casas-bahia-edge')),
      findsOneWidget,
    );
  });

  testWidgets('oferta sem categoria não inventa metadado', (at) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: CartaoProduto(
            produto: _produto(categoria: null),
            compacto: true,
            aoAbrirDetalhes: () {},
          ),
        ),
      ),
    );

    expect(find.text('Celular'), findsNothing);
    expect(find.text('Outros'), findsNothing);
  });

  testWidgets('detalhes e histórico preservam a oferta tocada', (at) async {
    final navegador = GlobalKey<NavigatorState>();
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async => _pagina([_produto(id: 'ponto-42', loja: 'Ponto')]),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: NavigatorPopHandler<void>(
          onPopWithResult: (_) => navegador.currentState?.pop(),
          child: Navigator(
            key: navegador,
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Compre direto')),
                body: PaginaProdutos(
                  api: _apiHistorico(),
                  controlador: controlador,
                  incorporada: true,
                  experienciaCompacta: true,
                  navegadorParaDetalhes: navegador,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await at.enterText(find.byKey(const Key('busca-produtos')), 'edge');
    await at.pumpAndSettle();
    await at.drag(
      find.byKey(const Key('produtos-compacto')),
      const Offset(0, -600),
    );
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('detalhes-produto')));
    await at.pumpAndSettle();

    expect(find.byType(PaginaDetalheProduto), findsOneWidget);
    expect(find.text('Compre direto'), findsNothing);
    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Preço de compra'), findsOneWidget);
    expect(find.text('Cashback'), findsOneWidget);
    expect(find.text('Estimativa após cashback'), findsOneWidget);
    expect(find.text('Loja'), findsOneWidget);
    await at.drag(find.byType(ListView).last, const Offset(0, -260));
    await at.pumpAndSettle();
    expect(find.text('Abrir Inter'), findsOneWidget);
    await at.tap(find.byKey(const Key('historico-detalhe-produto')));
    await at.pumpAndSettle();

    final pagina = at.widget<PaginaHistoricoProduto>(
      find.byType(PaginaHistoricoProduto),
    );
    expect(find.byKey(const Key('folha-radar-modal')), findsOneWidget);
    expect(find.text('Histórico de preço'), findsOneWidget);
    expect(find.text('Motorola Edge 60 Pro · Ponto'), findsOneWidget);
    expect(pagina.produto.idExterno, 'ponto-42');
    expect(pagina.produto.lojaSlug, 'ponto');
    expect(pagina.produto.lojaNome, 'Ponto');

    await at.tap(find.byKey(const Key('fechar-folha-radar')));
    await at.pumpAndSettle();
    await at.binding.handlePopRoute();
    await at.pumpAndSettle();
    expect(find.byType(PaginaDetalheProduto), findsNothing);
    expect(find.byKey(const Key('produtos-compacto')), findsOneWidget);
  });

  testWidgets('pede termo, agrupa por loja e mostra os dados comerciais', (
    at,
  ) async {
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async => _pagina([
            _produto(),
            _produto(id: 'ponto', loja: 'Ponto'),
          ], total: 2),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    expect(
      find.text('Digite pelo menos 2 caracteres para pesquisar no catálogo.'),
      findsOneWidget,
    );

    await at.enterText(find.byType(TextField).first, 'edge');
    await at.pumpAndSettle();

    expect(find.text('Casas Bahia'), findsAtLeastNWidgets(1));
    expect(find.text('Motorola Edge 60 Pro'), findsAtLeastNWidgets(1));
    expect(find.text('Após cashback'), findsAtLeastNWidgets(1));
    expect(find.text('R\$ 3.356,89'), findsAtLeastNWidgets(1));
    expect(find.text('Abrir no Shopping Inter'), findsOneWidget);
    await at.drag(find.byType(ListView), const Offset(0, -500));
    await at.pumpAndSettle();
    expect(find.text('Ponto'), findsAtLeastNWidgets(1));
    expect(find.text('Motorola Edge 60 Pro'), findsAtLeastNWidgets(1));
    expect(find.text('Após cashback'), findsAtLeastNWidgets(1));
    expect(find.text('R\$ 3.356,89'), findsAtLeastNWidgets(1));
    expect(find.textContaining('lojas teve coleta degradada'), findsOneWidget);
    expect(
      find.textContaining(
        'atualização das lojas destes resultados foi parcial',
      ),
      findsOneWidget,
    );
  });

  testWidgets('filtros seguem o protótipo e editam ordem, loja e preços', (
    at,
  ) async {
    var chamadas = 0;
    String? marcaRecebida;
    String? categoriaRecebida;
    String? lojaRecebida;
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async {
            chamadas++;
            marcaRecebida = marca;
            categoriaRecebida = categoria;
            lojaRecebida = loja;
            if (chamadas == 1) throw StateError('sem rede');
            return _pagina([_produto()]);
          },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaProdutos(
          api: _apiFiltros(),
          controlador: controlador,
          administrador: true,
        ),
      ),
    );
    await at.enterText(find.byType(TextField).first, 'edge');
    await at.pumpAndSettle();
    expect(
      find.text('Não foi possível buscar produtos agora.'),
      findsOneWidget,
    );

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    await at.tap(find.text('Filtros'));
    await at.pumpAndSettle();
    expect(find.text('Menor preço por loja'), findsOneWidget);
    expect(find.text('Todas as lojas'), findsOneWidget);
    expect(find.text('Todas as categorias'), findsOneWidget);
    await at.ensureVisible(find.byKey(const Key('filtro-ordenar')));
    await at.tap(find.byKey(const Key('filtro-ordenar')));
    await at.pumpAndSettle();
    await at.tap(find.text('Nome por loja').last);
    await at.pumpAndSettle();
    await at.ensureVisible(find.byKey(const Key('filtro-loja')));
    await at.tap(find.byKey(const Key('filtro-loja')));
    await at.pumpAndSettle();
    await at.tap(find.text('Ponto').last);
    await at.enterText(find.byKey(const Key('filtro-preco-minimo')), '100');
    await at.enterText(find.byKey(const Key('filtro-preco-maximo')), '500');
    await at.scrollUntilVisible(
      find.text('Aplicar filtros'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await at.tap(find.text('Aplicar filtros'));
    await at.pumpAndSettle();

    expect(marcaRecebida, isNull);
    expect(categoriaRecebida, isNull);
    expect(lojaRecebida, 'ponto');
    expect(find.text('Filtros ativos'), findsOneWidget);

    await at.tap(find.text('Limpar filtros'));
    await at.pumpAndSettle();
    expect(find.text('Filtros'), findsOneWidget);
  });

  testWidgets('falha compacta preserva oferta anterior e permite retry', (
    at,
  ) async {
    var chamada = 0;
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async {
            chamada++;
            if (chamada == 2) throw StateError('sem rede');
            return _pagina([_produto(id: 'oferta-$chamada')]);
          },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaProdutos(
            api: _api(),
            controlador: controlador,
            incorporada: true,
            experienciaCompacta: true,
          ),
        ),
      ),
    );
    await at.enterText(find.byKey(const Key('busca-produtos')), 'edge');
    await at.pumpAndSettle();
    await at.scrollUntilVisible(
      find.text('Motorola Edge 60 Pro'),
      180,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('produtos-compacto')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Motorola Edge 60 Pro'), findsOneWidget);

    controlador.mudarFiltros(const FiltrosProdutos(marca: 'Motorola'));
    await at.pumpAndSettle();

    expect(find.text('Não foi possível atualizar esta busca'), findsOneWidget);
    expect(find.text('1 oferta preservada'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    expect(find.text('Não foi possível atualizar esta busca'), findsNothing);
    expect(controlador.itens.single.idExterno, 'oferta-3');
  });

  testWidgets('catálogo compacto segue o protótipo e filtra No radar', (
    at,
  ) async {
    final acompanhados = <bool>[];
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async => _pagina([_produto()]),
      buscarComOpcoes:
          ({
            required termo,
            required pagina,
            required ordenar,
            required apenasAcompanhados,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async {
            acompanhados.add(apenasAcompanhados);
            return _pagina([
              _produto(acompanhado: apenasAcompanhados),
            ], total: 1);
          },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaProdutos(
            api: _api(),
            controlador: controlador,
            incorporada: true,
            experienciaCompacta: true,
          ),
        ),
      ),
    );

    expect(find.text('Produtos por loja'), findsOneWidget);
    expect(find.byKey(const Key('busca-produtos')), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('No radar'), findsOneWidget);
    expect(find.byKey(const Key('filtros-produtos')), findsOneWidget);

    await at.enterText(find.byKey(const Key('busca-produtos')), 'edge');
    await at.pumpAndSettle();
    expect(find.text('Casas Bahia'), findsAtLeastNWidgets(1));
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Detalhes'), findsOneWidget);

    await at.tap(find.text('No radar'));
    await at.pumpAndSettle();
    expect(controlador.apenasAcompanhados, isTrue);
    expect(acompanhados, contains(true));
    expect(find.text('Acompanhando'), findsOneWidget);
    expect(at.takeException(), isNull);
  });

  testWidgets('card compacto atualiza para Acompanhando após salvar', (
    at,
  ) async {
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async => _pagina([_produto()]),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaProdutos(
            api: _apiHistorico(),
            controlador: controlador,
            incorporada: true,
            experienciaCompacta: true,
          ),
        ),
      ),
    );
    await at.enterText(find.byKey(const Key('busca-produtos')), 'edge');
    await at.pumpAndSettle();

    final acompanhar = find.byKey(const Key('alerta-produto-casas-bahia-edge'));
    expect(find.text('Acompanhar'), findsOneWidget);
    await at.tap(acompanhar);
    await at.pumpAndSettle();

    expect(find.text('Acompanhando'), findsOneWidget);
    expect(at.takeException(), isNull);
  });

  testWidgets('busca compacta não estoura em 320 px com texto ampliado', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(320, 640);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async => _pagina([_produto()]),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.escuro(),
        home: Scaffold(
          body: PaginaProdutos(
            api: _api(),
            controlador: controlador,
            incorporada: true,
            experienciaCompacta: true,
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
    await at.enterText(find.byKey(const Key('busca-produtos')), 'edge');
    await at.pumpAndSettle();
    expect(at.takeException(), isNull);
    await at.drag(
      find.byKey(const Key('produtos-compacto')),
      const Offset(0, -400),
    );
    await at.pump();
    expect(at.takeException(), isNull);
  });

  testWidgets('filtros compactos não estouram em 320 px', (at) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(320, 640);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async => _pagina([_produto()]),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaProdutos(
            api: _apiFiltros(),
            controlador: controlador,
            incorporada: true,
            experienciaCompacta: true,
            administrador: true,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();

    final filtros = find.text('Filtros');
    final rolagemProdutos = find
        .descendant(
          of: find.byKey(const Key('produtos-compacto')),
          matching: find.byType(Scrollable),
        )
        .first;
    await at.scrollUntilVisible(filtros, 120, scrollable: rolagemProdutos);
    await at.drag(rolagemProdutos, const Offset(0, -80));
    await at.pumpAndSettle();
    await at.tap(filtros);
    await at.pumpAndSettle();

    expect(find.byKey(const Key('filtro-ordenar')), findsOneWidget);
    expect(find.byKey(const Key('filtro-loja')), findsOneWidget);
    expect(find.byKey(const Key('filtro-categoria')), findsOneWidget);
    expect(
      at.getSize(find.byKey(const Key('folha-radar-modal'))).height,
      lessThan(640),
    );
    expect(at.takeException(), isNull);
  });

  testWidgets('trocar filtro preserva os cards durante a nova consulta', (
    at,
  ) async {
    final respostaSeguinte = Completer<Pagina<ProdutoDireto>>();
    var chamadas = 0;
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) {
            chamadas++;
            if (chamadas == 1) return Future.value(_pagina([_produto()]));
            return respostaSeguinte.future;
          },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaProdutos(
            api: _api(),
            controlador: controlador,
            incorporada: true,
            experienciaCompacta: true,
          ),
        ),
      ),
    );
    await at.enterText(find.byKey(const Key('busca-produtos')), 'edge');
    await at.pumpAndSettle();
    await at.scrollUntilVisible(
      find.text('Motorola Edge 60 Pro'),
      120,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('produtos-compacto')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Motorola Edge 60 Pro'), findsOneWidget);

    controlador.mudarFiltros(const FiltrosProdutos(loja: 'ponto'));
    await at.pump();
    expect(find.text('Motorola Edge 60 Pro'), findsOneWidget);

    respostaSeguinte.complete(_pagina([_produto(loja: 'Ponto')]));
    await at.pumpAndSettle();
    expect(find.text('Ponto'), findsAtLeastNWidgets(1));
  });

  testWidgets('tela larga mantém cartões de produtos em duas colunas', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(1100, 1200);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            escopo,
            required semCategoria,
            loja,
            precoMin,
            precoMax,
          }) async => _pagina([_produto(), _produto(id: 'outro')], total: 2),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.enterText(find.byType(TextField).first, 'edge');
    await at.pumpAndSettle();

    expect(find.byType(CartaoProduto), findsNWidgets(2));
    expect(find.byType(Wrap), findsAtLeastNWidgets(2));
  });

  testWidgets('histórico mostra mínimo, máximo e pagina as medições', (
    at,
  ) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaHistoricoProduto(api: _apiHistorico(), produto: _produto()),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('22 ago 2026'), findsOneWidget);
    expect(find.text('6 medições nos últimos 30 dias'), findsOneWidget);
    expect(find.text('Preço atual'), findsNWidgets(5));
    expect(find.text('Cashback'), findsNWidgets(5));
    expect(find.text('R\$ 332,00'), findsNWidgets(5));
    expect(find.text('Após cashback'), findsNWidgets(5));
    expect(find.text('R\$ 3.356,89'), findsNWidgets(5));
    expect(find.text('R\$ 3.500,00'), findsOneWidget);
    expect(find.text('R\$ 4.000,00'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(
      (at.getCenter(find.text('Preço atual').first).dy -
              at.getCenter(find.text('R\$ 3.688,89').first).dy)
          .abs(),
      lessThan(2),
    );
    expect(
      (at.getCenter(find.text('Cashback').first).dy -
              at.getCenter(find.text('R\$ 332,00').first).dy)
          .abs(),
      lessThan(2),
    );
    await at.tap(find.byKey(const Key('historico-pagina-proxima')));
    await at.pumpAndSettle();
    expect(find.text('2 de 2'), findsOneWidget);
    expect(find.text('21 ago 2026'), findsOneWidget);
    expect(find.text('R\$ 3.600,00'), findsOneWidget);
    expect(find.text('R\$ 3.688,89'), findsNothing);
    await at.tap(find.byKey(const Key('historico-pagina-anterior')));
    await at.pumpAndSettle();
    expect(find.text('1 de 2'), findsOneWidget);
  });

  testWidgets('histórico mantém medições de produto que ficou inativo', (
    at,
  ) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaHistoricoProduto(
          api: _apiHistorico(ativo: false),
          produto: _produto(),
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('Oferta não está mais ativa'), findsOneWidget);
    expect(
      find.text('O histórico de preços continua disponível.'),
      findsOneWidget,
    );
    expect(find.text('R\$ 3.500,00'), findsOneWidget);
    expect(find.text('22 ago 2026'), findsOneWidget);
    await at.scrollUntilVisible(
      find.text('O histórico é paginado e limitado à janela de 30 dias.'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(
      find.text('O histórico é paginado e limitado à janela de 30 dias.'),
      findsOneWidget,
    );
  });

  testWidgets('histórico com falha inicial permite nova tentativa', (at) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaHistoricoProduto(
          api: _apiHistorico(primeiraFalha: true),
          produto: _produto(),
        ),
      ),
    );
    await at.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar o histórico deste produto.'),
      findsOneWidget,
    );

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    expect(find.text('Mínimo no contrato'), findsOneWidget);
  });

  testWidgets('falha em página adicional mantém o histórico já mostrado', (
    at,
  ) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: PaginaHistoricoProduto(
          api: _apiHistorico(falhaPaginaDois: true),
          produto: _produto(),
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('R\$ 3.688,89'), findsAtLeastNWidgets(1));
    await at.tap(find.byKey(const Key('historico-pagina-proxima')));
    await at.pumpAndSettle();

    expect(find.text('R\$ 3.688,89'), findsAtLeastNWidgets(1));
    expect(find.text('Tentar carregar esta página'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
  });
}
