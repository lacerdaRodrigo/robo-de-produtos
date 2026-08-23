import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/app/navegacao/moldura.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api_v1.dart';
import 'package:app_robo/core/api/cliente.dart';

const _paginaVazia =
    '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,'
    '"total_paginas":1,"tem_proxima":false,"atualizado_em":null}';

const _resumo =
    '{"gerado_em":"2026-08-23T12:00:00Z","estado_geral":"sem_dados",'
    '"livelo":{"estado":"sem_dados","ultimo_sucesso_em":null,'
    '"lojas_acompanhadas":0,"alertas_ultima_coleta":0},'
    '"cashback_inter":{"estado":"sem_dados","ultima_tentativa_em":null,'
    '"ultima_tentativa_estado":null,"ultimo_sucesso_em":null,'
    '"lojas_acompanhadas":0,"lojas_encontradas_ultima_coleta":0},'
    '"produtos":{"estado":"sem_dados","ultima_tentativa_em":null,'
    '"ultima_tentativa_estado":null,"dados_mais_antigos_em":null,'
    '"dados_mais_recentes_em":null,"qualidade":null,"lojas_selecionadas":0,'
    '"lojas_sem_coleta":0,"produtos_ativos":0}}';

ApiV1 _api() => ApiV1(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      if (requisicao.url.path == '/api/v1/status') {
        return http.Response('{"api":"v1","saudavel":true}', 200);
      }
      if (requisicao.url.path == '/api/v1/resumo') {
        return http.Response(_resumo, 200);
      }
      if (requisicao.url.path == '/api/v1/livelo/preferencias') {
        return http.Response(
          '{"multiplicador_padrao":"2.00",'
          '"piso_pontos_padrao":"4.00","assinante_clube":false}',
          200,
        );
      }
      return http.Response(_paginaVazia, 200);
    }),
  ),
);

Future<void> _abrir(
  WidgetTester at, {
  Size tamanho = const Size(390, 844),
  double escalaTexto = 1,
  bool administrador = false,
}) async {
  at.view.devicePixelRatio = 1;
  at.view.physicalSize = tamanho;
  addTearDown(at.view.resetDevicePixelRatio);
  addTearDown(at.view.resetPhysicalSize);
  await at.pumpWidget(
    MaterialApp(
      theme: TemaRadar.claro(),
      home: MolduraRadar(api: _api(), administrador: administrador),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
    ),
  );
  await at.pumpAndSettle();
}

Future<void> _abrirGaveta(WidgetTester at) async {
  await at.tap(find.byKey(const Key('abrir-menu-principal')));
  await at.pumpAndSettle();
}

Future<void> _irPara(WidgetTester at, Destino destino) async {
  await _abrirGaveta(at);
  await at.tap(find.byKey(Key('destino-${destino.name}')));
  await at.pumpAndSettle();
}

void main() {
  testWidgets('celular usa cabeçalho e gaveta com cinco destinos fixos', (
    at,
  ) async {
    await _abrir(at);

    expect(find.byKey(const Key('abrir-menu-principal')), findsOneWidget);
    expect(find.byType(BarraLateral), findsNothing);
    await _abrirGaveta(at);

    for (final destino in Destino.values) {
      expect(find.byKey(Key('destino-${destino.name}')), findsOneWidget);
      expect(find.text(destino.titulo), findsOneWidget);
    }
    expect(find.text('Acesso padrão'), findsOneWidget);
  });

  testWidgets('celular em paisagem continua com a gaveta', (at) async {
    await _abrir(at, tamanho: const Size(844, 390));

    expect(find.byKey(const Key('abrir-menu-principal')), findsOneWidget);
    expect(find.byType(BarraLateral), findsNothing);
    await _abrirGaveta(at);
    expect(find.byKey(const Key('destino-produtos')), findsOneWidget);
  });

  testWidgets('Web amplo usa lateral com os mesmos cinco destinos', (at) async {
    await _abrir(at, tamanho: const Size(1440, 900));

    expect(find.byType(BarraLateral), findsOneWidget);
    expect(find.byKey(const Key('abrir-menu-principal')), findsNothing);
    for (final destino in Destino.values) {
      expect(
        find.byKey(Key('destino-lateral-${destino.name}')),
        findsOneWidget,
      );
    }
  });

  testWidgets('Início aparece por padrão e consome o resumo da API', (
    at,
  ) async {
    await _abrir(at);

    expect(find.text('Seu radar hoje'), findsOneWidget);
    expect(find.text('Livelo: sem dados'), findsOneWidget);
  });

  testWidgets('atalhos do Início abrem Produtos e os dois domínios de Lojas', (
    at,
  ) async {
    const tamanho = Size(1200, 2000);
    await _abrir(at, tamanho: tamanho);

    await at.tap(find.byKey(const Key('atalho-produtos')));
    await at.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Buscar produtos'), findsOneWidget);

    await at.pumpWidget(const SizedBox.shrink());
    await _abrir(at, tamanho: tamanho);
    await at.tap(find.byKey(const Key('atalho-livelo')));
    await at.pumpAndSettle();
    expect(find.byKey(const Key('voltar-para-lojas')), findsOneWidget);
    expect(
      find.text('Ainda não há uma coleta da Livelo para mostrar.'),
      findsOneWidget,
    );

    await at.pumpWidget(const SizedBox.shrink());
    await _abrir(at, tamanho: tamanho);
    await at.tap(find.byKey(const Key('atalho-cashback')));
    await at.pumpAndSettle();
    expect(find.byKey(const Key('voltar-para-lojas')), findsOneWidget);
    expect(find.text('Shopping Inter'), findsWidgets);
  });

  testWidgets('Lojas mantém Livelo e Shopping Inter alcançáveis', (at) async {
    await _abrir(at);
    await _irPara(at, Destino.lojas);

    expect(find.byKey(const Key('hub-lojas')), findsOneWidget);
    expect(find.text('Livelo'), findsOneWidget);
    expect(find.text('Shopping Inter'), findsOneWidget);

    await at.tap(find.byKey(const Key('abrir-lojas-livelo')));
    await at.pumpAndSettle();

    expect(find.byKey(const Key('voltar-para-lojas')), findsOneWidget);
    expect(
      find.text('Ainda não há uma coleta da Livelo para mostrar.'),
      findsOneWidget,
    );
  });

  testWidgets('Voltar do domínio interno retorna primeiro ao hub de Lojas', (
    at,
  ) async {
    await _abrir(at);
    await _irPara(at, Destino.lojas);
    await at.tap(find.byKey(const Key('abrir-lojas-inter')));
    await at.pumpAndSettle();

    expect(find.byKey(const Key('voltar-para-lojas')), findsOneWidget);
    await at.binding.handlePopRoute();
    await at.pumpAndSettle();

    expect(find.byKey(const Key('hub-lojas')), findsOneWidget);
    expect(find.byKey(const Key('voltar-para-lojas')), findsNothing);
  });

  testWidgets('Produtos é destino direto e preserva a busca entre áreas', (
    at,
  ) async {
    await _abrir(at);
    await _irPara(at, Destino.produtos);

    final busca = find.widgetWithText(TextField, 'Buscar produtos');
    expect(busca, findsOneWidget);
    await at.enterText(busca, 'x');

    await _irPara(at, Destino.alertas);
    expect(find.text('Ainda não implementado nesta fase.'), findsOneWidget);
    await _irPara(at, Destino.produtos);

    expect(at.widget<TextField>(busca).controller?.text, 'x');
  });

  testWidgets('atalho do cabeçalho abre Alertas sem passar pela gaveta', (
    at,
  ) async {
    await _abrir(at);
    await at.tap(find.byKey(const Key('abrir-alertas-cabecalho')));
    await at.pumpAndSettle();

    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Ainda não implementado nesta fase.'), findsOneWidget);
  });

  testWidgets('Mais conserva a administração existente para admin', (at) async {
    await _abrir(at, administrador: true);
    await _irPara(at, Destino.mais);

    expect(find.text('Administração'), findsOneWidget);
    expect(find.byKey(const Key('busca-lojas-livelo')), findsOneWidget);
  });

  testWidgets('gaveta aceita texto ampliado sem perder destinos', (at) async {
    await _abrir(at, tamanho: const Size(320, 640), escalaTexto: 1.5);
    await _abrirGaveta(at);

    expect(at.takeException(), isNull);
    for (final destino in Destino.values) {
      expect(find.byKey(Key('destino-${destino.name}')), findsOneWidget);
    }
  });

  testWidgets('gaveta mobile confere com o golden aprovado', (at) async {
    await _abrir(at);
    await _abrirGaveta(at);

    await expectLater(
      find.byType(MolduraRadar),
      matchesGoldenFile('../../goldens/moldura_mobile_gaveta.png'),
    );
  });

  testWidgets('lateral Web confere com o golden aprovado', (at) async {
    await _abrir(at, tamanho: const Size(1440, 900));

    await expectLater(
      find.byType(MolduraRadar),
      matchesGoldenFile('../../goldens/moldura_web_lateral.png'),
    );
  });
}
