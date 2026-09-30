import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/componentes/fundacao_visual.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/pichau/modelos_pichau.dart';
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

Map<String, dynamic> _catalogoComDisponibilidade(String? disponibilidade) {
  final catalogo = Map<String, dynamic>.from(_catalogo);
  final itens = (_catalogo['itens'] as List<dynamic>)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  itens.first['disponibilidade'] = disponibilidade;
  catalogo['itens'] = itens;
  return catalogo;
}

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

PichauProduto _produtoPichau() => PichauProduto.parse(
  Map<String, dynamic>.from((_catalogo['itens'] as List).first as Map),
);

void _expectSuperficieOfertaV15(
  WidgetTester at,
  Finder cartao,
  EdgeInsetsGeometry padding,
) {
  const tokens = AppTokens.claro();
  final cartaoWidget = at.widget<CartaoRadar>(cartao);
  expect(cartaoWidget.padding, padding);
  expect(cartaoWidget.comSombra, isFalse);
  expect(cartaoWidget.corDestaque, isNull);

  final superficies = find.descendant(
    of: cartao,
    matching: find.byType(Material),
  );
  final superficie = at.widget<Material>(superficies.first);
  expect(superficie.color, tokens.colors.superficie);
  final forma = superficie.shape! as RoundedRectangleBorder;
  expect(forma.borderRadius, BorderRadius.circular(tokens.radii.lg));
  expect(forma.side.color, tokens.colors.borda);
  expect(forma.side.width, 1);
}

void _expectEstiloAcompanhamentoV15(
  WidgetTester at, {
  required bool acompanhada,
  required Brightness brilho,
}) {
  final botao = find.byKey(const Key('acompanhar-pichau-PG-7800'));
  final estilo = at.widget<OutlinedButton>(botao).style!;
  final escuro = brilho == Brightness.dark;
  final cores = escuro ? const CoresRadar.escuras() : const CoresRadar.claras();
  final corTexto = acompanhada ? cores.acaoForte : cores.texto;
  final corFundo = acompanhada ? cores.acaoFundo : Colors.transparent;
  final corBorda = acompanhada ? Colors.transparent : cores.borda;

  expect(estilo.foregroundColor?.resolve({}), corTexto);
  expect(estilo.backgroundColor?.resolve({}), corFundo);
  expect(estilo.side?.resolve({})?.color, corBorda);
  expect(at.getSize(botao).height, greaterThanOrEqualTo(48));
}

void main() {
  testWidgets('mostra catálogo Pichau, preços, estados e histórico', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await at.pumpWidget(_tela(_api(requisicoes: requisicoes)));
    expect(find.text('Carregando catálogo Pichau…'), findsOneWidget);
    await at.pumpAndSettle();
    _expectEstiloAcompanhamentoV15(
      at,
      acompanhada: false,
      brilho: Brightness.light,
    );

    final voltar = find.byKey(const Key('voltar-programas-pichau'));
    expect(voltar, findsOneWidget);
    expect(at.getTopLeft(voltar).dy, closeTo(16, 0.5));
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
    expect(find.byKey(const Key('atualizacao-pichau-PG-7800')), findsOneWidget);
    expect(find.text('2026-09-04T12:00:00Z'), findsNothing);
    expect(
      find.text('Cartão R\$ 7.999,90 · 9% de desconto no Pix'),
      findsOneWidget,
    );
    expect(find.text('Disponível'), findsOneWidget);
    final cartao = find.ancestor(
      of: find.text('Pichau Gaming 7800X3D RTX 4070 Super'),
      matching: find.byType(CartaoRadar),
    );
    _expectSuperficieOfertaV15(at, cartao, const EdgeInsets.all(20));
    final titulo = at.widget<Text>(
      find.text('Pichau Gaming 7800X3D RTX 4070 Super'),
    );
    expect(titulo.style?.fontSize, 18);
    expect(titulo.maxLines, 2);
    expect(titulo.overflow, TextOverflow.ellipsis);
    expect(at.widget<Text>(find.text('R\$ 7.499,90')).style?.fontSize, 30);
    await at.scrollUntilVisible(
      find.text('Esgotado'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Esgotado'), findsOneWidget);
    expect(find.byKey(const Key('detalhes-pichau-PG-7600')), findsOneWidget);
    expect(requisicoes.single.url.queryParameters['por_pagina'], '20');

    final detalhes7800 = find.byKey(const Key('detalhes-pichau-PG-7800'));
    final lista = find.byKey(const Key('pagina-pichau'));
    await at.drag(lista, const Offset(0, 700));
    await at.pumpAndSettle();
    await at.ensureVisible(detalhes7800);
    await at.tap(detalhes7800);
    await at.pumpAndSettle();

    expect(find.text('Detalhes'), findsAtLeastNWidgets(1));
    await at.ensureVisible(find.byKey(const Key('historico-pichau-PG-7800')));
    await at.tap(find.byKey(const Key('historico-pichau-PG-7800')));
    await at.pumpAndSettle();
    expect(find.text('Histórico de preço'), findsOneWidget);
    expect(find.text('R\$ 7.399,90'), findsOneWidget);
    expect(find.byKey(const Key('historico-pichau-conteudo')), findsOneWidget);
  });

  testWidgets('cartão Pichau permite texto a 200% sem overflow', (at) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(320, 640);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 320,
                child: CartaoPichau(
                  produto: _produtoPichau(),
                  aoAbrirDetalhes: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Pichau Gaming 7800X3D RTX 4070 Super'), findsOneWidget);
    expect(find.text('R\$ 7.499,90'), findsOneWidget);
    expect(at.takeException(), isNull);
    await at.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await at.pump();
    expect(at.takeException(), isNull);
  });

  testWidgets('Pichau não presume disponibilidade para valor ausente', (
    at,
  ) async {
    for (final disponibilidade in <String?>[null, '', 'valor_desconhecido']) {
      await at.pumpWidget(
        _tela(
          _api(
            requisicoes: [],
            catalogo: _catalogoComDisponibilidade(disponibilidade),
          ),
        ),
      );
      await at.pumpAndSettle();

      expect(find.text('Disponibilidade não informada'), findsOneWidget);
      final status = at.widget<Text>(
        find.text('Disponibilidade não informada'),
      );
      expect(
        status.style?.color,
        CoresRadar.de(at.element(find.text('PCs gamer'))).textoSuave,
      );

      await at.tap(find.byKey(const Key('detalhes-pichau-PG-7800')));
      await at.pumpAndSettle();
      final indicador = at.widget<IndicadorEstadoRadar>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IndicadorEstadoRadar &&
              widget.texto == 'Disponibilidade não informada',
        ),
      );
      expect(indicador.tom, TomRadar.neutro);
      await at.tap(find.byKey(const Key('fechar-folha-radar')));
      await at.pumpAndSettle();
    }
  });

  testWidgets('Pichau preserva Esgotado para disponibilidade confirmada', (
    at,
  ) async {
    await at.pumpWidget(
      _tela(
        _api(
          requisicoes: [],
          catalogo: _catalogoComDisponibilidade('esgotado'),
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('Esgotado'), findsWidgets);
    await at.tap(find.byKey(const Key('detalhes-pichau-PG-7800')));
    await at.pumpAndSettle();
    final indicador = at.widget<IndicadorEstadoRadar>(
      find.byWidgetPredicate(
        (widget) =>
            widget is IndicadorEstadoRadar && widget.texto == 'Esgotado',
      ),
    );
    expect(indicador.tom, TomRadar.atencao);
  });

  testWidgets('acompanhamento usa acento acessível no tema escuro', (at) async {
    final requisicoes = <http.Request>[];
    await at.pumpWidget(
      _tela(_api(requisicoes: requisicoes), tema: TemaRadar.escuro()),
    );
    await at.pumpAndSettle();

    _expectEstiloAcompanhamentoV15(
      at,
      acompanhada: false,
      brilho: Brightness.dark,
    );
    final botao = find.byKey(const Key('acompanhar-pichau-PG-7800'));
    await at.ensureVisible(botao);
    await at.tap(botao);
    await at.pumpAndSettle();
    _expectEstiloAcompanhamentoV15(
      at,
      acompanhada: true,
      brilho: Brightness.dark,
    );
  });

  testWidgets('busca preserva o termo e trata falha sem inventar catálogo', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await at.pumpWidget(_tela(_api(requisicoes: requisicoes)));
    await at.pumpAndSettle();
    final chamadasIniciais = requisicoes.length;
    await at.enterText(find.byKey(const Key('busca-pichau')), 'ryzen');
    await at.pumpAndSettle();

    expect(requisicoes, hasLength(chamadasIniciais));
    await at.tap(find.byTooltip('Pesquisar'));
    await at.pumpAndSettle();
    expect(requisicoes.last.url.queryParameters['q'], 'ryzen');
    await at.enterText(find.byKey(const Key('busca-pichau')), 'intel');
    await at.testTextInput.receiveAction(TextInputAction.search);
    await at.pumpAndSettle();
    expect(requisicoes.last.url.queryParameters['q'], 'intel');
    expect(
      at.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );

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
      if (largura == 320) {
        final contagem = find.byKey(const Key('contagem-resultados-pichau'));
        final filtros = find.byKey(const Key('filtrar-ordenar-pichau'));
        expect(at.getCenter(contagem).dy, closeTo(at.getCenter(filtros).dy, 1));
        expect(at.getSize(filtros).width, lessThan(200));
      }
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
    expect(find.byKey(const Key('fechar-folha-radar')), findsOneWidget);
    expect(find.byKey(const Key('filtro-preco-minimo-pichau')), findsOneWidget);
    expect(find.byKey(const Key('filtro-preco-maximo-pichau')), findsOneWidget);
    expect(find.byKey(const Key('rodape-filtros-pichau')), findsOneWidget);
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
    final maximo = find.byKey(const Key('filtro-preco-maximo-pichau'));
    await at.scrollUntilVisible(minimo, 120, scrollable: formulario);
    expect(at.getBottomRight(minimo).dy, lessThanOrEqualTo(524));

    await at.enterText(minimo, '3000,00');
    expect(find.text('3000,00'), findsOneWidget);
    final aplicar = find.byKey(const Key('aplicar-filtros-pichau'));
    await at.scrollUntilVisible(maximo, 120, scrollable: formulario);
    expect(
      at.getBottomRight(find.byKey(const Key('rodape-filtros-pichau'))).dy,
      lessThanOrEqualTo(524),
    );
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

    expect(find.byKey(const Key('aplicar-filtros-pichau')), findsOneWidget);
    expect(
      at.getBottomRight(find.byKey(const Key('rodape-filtros-pichau'))).dy,
      lessThanOrEqualTo(844),
    );
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

    await at.tap(find.byKey(const Key('filtrar-ordenar-pichau')));
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('limpar-filtros-pichau')));
    await at.pumpAndSettle();
    expect(find.text('Filtros · Pichau'), findsOneWidget);
    expect(requisicoes.last.url.queryParameters['disponibilidade'], 'todas');
    expect(requisicoes.last.url.queryParameters['ordenar'], 'preco');
    expect(
      requisicoes.last.url.queryParameters.containsKey('preco_min'),
      isFalse,
    );

    await at.tap(find.byKey(const Key('aplicar-filtros-pichau')));
    await at.pumpAndSettle();
    await at.tap(find.text('Todos').first);
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
    _expectEstiloAcompanhamentoV15(
      at,
      acompanhada: true,
      brilho: Brightness.light,
    );
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
