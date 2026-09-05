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
  String? secundaria = '2% de cashback',
  String? link = 'https://shopping.inter.co/site-parceiro/lojas',
}) => CashbackInter(
  id: nome.toLowerCase(),
  slug: nome.toLowerCase(),
  nome: nome,
  cashbackPrincipalTexto: 'Até 12% de cashback',
  cashbackPrincipalValor: '12.00',
  cashbackSecundarioTexto: secundaria,
  cashbackSecundarioValor: secundaria == null ? null : '2.00',
  etiqueta: 'Oferta especial',
  descricaoPrincipal: 'Em itens selecionados',
  descricaoSecundaria: secundaria == null ? null : 'Para não-correntistas',
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
    cliente: http_testing.MockClient((_) async => http.Response('{}', 500)),
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
    expect(find.text('Até 12% de cashback'), findsOneWidget);
    expect(find.text('Para correntista'), findsOneWidget);
    expect(find.text('Para não-correntista'), findsOneWidget);
    expect(find.text('Para correntista'), findsOneWidget);
    expect(find.text('Oferta especial'), findsOneWidget);
    expect(find.text('Para não-correntista'), findsOneWidget);
    await at.tap(find.text('Para não-correntista'));
    await at.pumpAndSettle();
    expect(find.textContaining('Para não-correntistas'), findsOneWidget);
    expect(controlador.temProxima, isFalse);
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

  testWidgets(
    'Cashback compacto mostra o catálogo inteiro e filtra acompanhadas',
    (at) async {
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
      expect(find.text('2 lojas encontradas'), findsOneWidget);
      expect(find.text('Catálogo completo de cashback'), findsOneWidget);
      expect(find.text('Página 1'), findsOneWidget);
      expect(find.text('Maior cashback'), findsNothing);
      expect(find.byKey(const Key('aba-radar-0')), findsOneWidget);
      expect(find.byKey(const Key('aba-radar-1')), findsOneWidget);
      expect(
        at.getTopLeft(find.text('2 lojas encontradas')).dy,
        greaterThan(at.getBottomLeft(find.byKey(const Key('aba-radar-0'))).dy),
      );

      await at.tap(find.text('Acompanhadas'));
      await at.pumpAndSettle();

      expect(find.text('Animale'), findsNothing);
      expect(find.text('Aramis'), findsOneWidget);
      expect(find.text('✓ Acompanhada'), findsOneWidget);
      expect(find.text('Suas lojas acompanhadas'), findsOneWidget);
      expect(find.text('Página 1'), findsOneWidget);
    },
  );

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
    var acompanhada = false;
    var alteracoes = 0;
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
          if (requisicao.url.path == '/api/inter/lojas' &&
              requisicao.method == 'PATCH') {
            alteracoes++;
            if (alteracoes == 1) await primeiraAlteracao.future;
            acompanhada =
                (jsonDecode(requisicao.body)
                        as Map<String, dynamic>)['favorita']
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
    final metrica = find.byKey(const Key('aba-radar-1'));
    expect(
      find.descendant(of: metrica, matching: find.text('0')),
      findsOneWidget,
    );
    await at.drag(
      find.byKey(const PageStorageKey('rolagem-cashback-inter')),
      const Offset(0, -520),
    );
    await at.pumpAndSettle();

    await at.tap(find.text('Acompanhar'));
    await at.pump();
    expect(find.text('Salvando…'), findsOneWidget);
    expect(
      find.descendant(of: metrica, matching: find.text('1')),
      findsOneWidget,
    );

    await at.tap(find.text('Acompanhadas'));
    await at.pump();
    expect(find.text('C&A'), findsOneWidget);

    primeiraAlteracao.complete();
    await at.pumpAndSettle();
    expect(find.text('Deixar de acompanhar'), findsOneWidget);
    expect(find.text('C&A'), findsOneWidget);
    expect(
      find.descendant(of: metrica, matching: find.text('1')),
      findsOneWidget,
    );

    await at.tap(find.text('Deixar de acompanhar'));
    await at.pumpAndSettle();
    expect(
      find.descendant(of: metrica, matching: find.text('0')),
      findsOneWidget,
    );
    expect(find.text('C&A'), findsNothing);
    expect(find.text('Nenhuma loja está acompanhada ainda.'), findsOneWidget);
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
    expect(find.text('Deixar de acompanhar'), findsOneWidget);
    expect(find.text('Ir para o Inter'), findsOneWidget);
    expect(at.takeException(), isNull);
    await at.drag(
      find.byKey(const Key('cashback-inter-compacto')),
      const Offset(0, -300),
    );
    await at.pump();
    expect(at.takeException(), isNull);
  });

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

    await at.tap(find.text('Ir para o Inter'));
    await at.pumpAndSettle();
    expect(aberta, Uri.parse('https://shopping.inter.co/site-parceiro/lojas'));
  });

  testWidgets('Sites parceiros informa quando o sistema não abre o destino', (
    at,
  ) async {
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

    await at.tap(find.text('Ir para o Inter'));
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
  }, tags: 'web');

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
