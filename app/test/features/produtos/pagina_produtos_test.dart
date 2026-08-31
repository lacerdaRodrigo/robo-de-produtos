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
import 'package:app_robo/features/produtos/controlador_busca_produtos.dart';
import 'package:app_robo/features/produtos/pagina_historico_produto.dart';
import 'package:app_robo/features/produtos/pagina_produtos.dart';

ProdutoDireto _produto({String id = 'edge', String loja = 'Casas Bahia'}) =>
    ProdutoDireto(
      idExterno: id,
      nome: 'Motorola Edge 60 Pro',
      marca: 'Motorola',
      categoria: 'Celular',
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
            'medicoes': [
              {
                'momento': pagina == '2'
                    ? '2026-08-21T12:00:00Z'
                    : '2026-08-22T12:00:00Z',
                'preco_atual_valor': pagina == '2' ? '3600.00' : '3688.89',
                'cashback_valor': '332.00',
                'preco_liquido_valor': '3356.89',
              },
            ],
            'pagina': int.parse(pagina),
            'por_pagina': 30,
            'total_itens': 2,
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

  testWidgets('filtros são aplicados e erro inicial oferece retry', (at) async {
    var chamadas = 0;
    String? marcaRecebida;
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            loja,
            precoMin,
            precoMax,
          }) async {
            chamadas++;
            marcaRecebida = marca;
            if (chamadas == 1) throw StateError('sem rede');
            return _pagina([_produto()]);
          },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
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
    await at.enterText(find.byType(TextField).at(1), 'Motorola');
    await at.tap(find.text('Aplicar filtros'));
    await at.pumpAndSettle();

    expect(marcaRecebida, 'Motorola');
    expect(find.text('Filtros ativos'), findsOneWidget);

    await at.tap(find.text('Limpar filtros'));
    await at.pumpAndSettle();
    expect(find.text('Filtros'), findsOneWidget);
  });

  testWidgets('busca compacta segue o protótipo e usa o catálogo local', (
    at,
  ) async {
    var escolheuLojas = false;
    final controlador = ControladorBuscaProdutos(
      debounce: Duration.zero,
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
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
            api: _api(),
            controlador: controlador,
            incorporada: true,
            experienciaCompacta: true,
            administrador: true,
            aoEscolherLojas: () => escolheuLojas = true,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('O que você procura?'), findsOneWidget);
    expect(find.text('Todas selecionadas'), findsOneWidget);
    expect(find.text('Atualizar Produtos'), findsNothing);
    await at.enterText(find.byKey(const Key('busca-produtos')), 'edge');
    await at.pumpAndSettle();
    expect(find.text('Após cashback'), findsOneWidget);
    expect(find.text('R\$ 3.356,89'), findsOneWidget);
    expect(find.text('Ver no Inter'), findsOneWidget);

    await at.tap(find.text('+ escolher lojas'));
    expect(escolheuLojas, isTrue);
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
            loja,
            precoMin,
            precoMax,
          }) async => _pagina([_produto(), _produto(id: 'outro')], total: 2),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.enterText(find.byType(TextField).first, 'edge');
    await at.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(2));
    expect(find.byType(Wrap), findsAtLeastNWidgets(2));
  }, tags: 'web');

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

    expect(find.text('R\$ 3.500,00'), findsOneWidget);
    expect(find.text('R\$ 4.000,00'), findsOneWidget);
    await at.tap(find.text('Carregar mais medições'));
    await at.pumpAndSettle();
    expect(find.text('R\$ 3.600,00'), findsOneWidget);
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
    expect(find.text('Medições'), findsOneWidget);
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
    expect(find.text('Menor em 30 dias'), findsOneWidget);
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
    await at.tap(find.text('Carregar mais medições'));
    await at.pumpAndSettle();

    expect(find.text('R\$ 3.688,89'), findsAtLeastNWidgets(1));
    expect(find.text('Tentar carregar mais medições'), findsOneWidget);
  });
}
