import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/app/navegacao/moldura.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
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

const _resumoComEstadosIndependentes =
    '{"gerado_em":"2026-08-23T12:00:00Z","estado_geral":"atencao",'
    '"livelo":{"estado":"atualizado","ultimo_sucesso_em":"2026-08-23T10:30:00Z",'
    '"lojas_acompanhadas":3,"alertas_ultima_coleta":2},'
    '"cashback_inter":{"estado":"falha_recente","ultima_tentativa_em":"2026-08-23T11:40:00Z",'
    '"ultima_tentativa_estado":"falha","ultimo_sucesso_em":"2026-08-23T08:00:00Z",'
    '"lojas_acompanhadas":4,"lojas_encontradas_ultima_coleta":4},'
    '"produtos":{"estado":"parcial","ultima_tentativa_em":"2026-08-23T11:30:00Z",'
    '"ultima_tentativa_estado":"parcial","dados_mais_antigos_em":"2026-08-23T09:00:00Z",'
    '"dados_mais_recentes_em":"2026-08-23T11:00:00Z","qualidade":"completa",'
    '"lojas_selecionadas":2,"lojas_sem_coleta":1,"produtos_ativos":15}}';

Api _api({String resumo = _resumo, List<http.Request>? requisicoes}) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      requisicoes?.add(requisicao);
      if (requisicao.url.path == '/api/status') {
        return http.Response('{"api":"v1","saudavel":true}', 200);
      }
      if (requisicao.url.path == '/api/resumo') {
        return http.Response(resumo, 200);
      }
      if (requisicao.url.path == '/api/livelo/preferencias') {
        return http.Response(
          '{"multiplicador_padrao":"2.00",'
          '"piso_pontos_padrao":"4.00","assinante_clube":false}',
          200,
        );
      }
      if (requisicao.url.path == '/api/administracao/disparos') {
        final dominio = requisicao.url.queryParameters['dominio'] ?? '';
        return http.Response(
          '{"dominio":"$dominio",'
          '"cooldown_segundos":0,"ultima_solicitacao_em":null,'
          '"ultimo_estado":null}',
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
  String resumo = _resumo,
  List<http.Request>? requisicoes,
}) async {
  at.view.devicePixelRatio = 1;
  at.view.physicalSize = tamanho;
  addTearDown(at.view.resetDevicePixelRatio);
  addTearDown(at.view.resetPhysicalSize);
  await at.pumpWidget(
    MaterialApp(
      theme: TemaRadar.claro(),
      home: MolduraRadar(
        api: _api(resumo: resumo, requisicoes: requisicoes),
        administrador: administrador,
      ),
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

  testWidgets('hub de Lojas mostra estados reais sem misturar os domínios', (
    at,
  ) async {
    await _abrir(at, resumo: _resumoComEstadosIndependentes);
    await _irPara(at, Destino.lojas);

    expect(find.text('3 lojas acompanhadas'), findsOneWidget);
    expect(find.text('2 alertas na última coleta'), findsOneWidget);
    expect(find.text('4 acompanhadas no Cashback'), findsOneWidget);
    expect(find.text('Cashback: falha recente'), findsOneWidget);
    expect(find.text('2 lojas selecionadas em Produtos'), findsOneWidget);
    expect(find.text('Produtos: parcial'), findsOneWidget);
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

  testWidgets(
    'Shopping Inter separa Cashback e Produtos com retornos próprios',
    (at) async {
      await _abrir(
        at,
        tamanho: const Size(390, 1500),
        resumo: _resumoComEstadosIndependentes,
      );
      await _irPara(at, Destino.lojas);
      await at.tap(find.byKey(const Key('abrir-lojas-inter')));
      await at.pumpAndSettle();

      expect(find.byKey(const Key('hub-shopping-inter')), findsOneWidget);
      expect(find.text('Cashback — Sites parceiros'), findsOneWidget);
      expect(find.text('Produtos — Compre direto'), findsOneWidget);
      expect(find.text('falha recente'), findsOneWidget);
      expect(find.text('parcial'), findsOneWidget);

      await at.tap(find.byKey(const Key('abrir-cashback-inter')));
      await at.pumpAndSettle();
      expect(
        find.byKey(const Key('voltar-para-shopping-inter')),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Buscar por loja'), findsOneWidget);

      await at.tap(find.byKey(const Key('voltar-para-shopping-inter')));
      await at.pumpAndSettle();
      await at.tap(find.byKey(const Key('abrir-produtos-inter')));
      await at.pumpAndSettle();
      expect(
        find.byKey(const Key('voltar-para-shopping-inter')),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Buscar produtos'), findsOneWidget);

      await at.tap(find.byKey(const Key('voltar-para-shopping-inter')));
      await at.pumpAndSettle();
      expect(find.byKey(const Key('hub-shopping-inter')), findsOneWidget);
      await at.binding.handlePopRoute();
      await at.pumpAndSettle();
      expect(find.byKey(const Key('hub-lojas')), findsOneWidget);
    },
  );

  testWidgets('admin recebe atualizações identificadas por modalidade', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await _abrir(
      at,
      tamanho: const Size(390, 1500),
      administrador: true,
      requisicoes: requisicoes,
    );
    await _irPara(at, Destino.lojas);
    await at.tap(find.byKey(const Key('abrir-lojas-inter')));
    await at.pumpAndSettle();

    expect(find.text('Atualizar Cashback'), findsOneWidget);
    expect(find.text('Atualizar Produtos'), findsOneWidget);
    final dominiosConsultados = requisicoes
        .where(
          (requisicao) => requisicao.url.path == '/api/administracao/disparos',
        )
        .map((requisicao) => requisicao.url.queryParameters['dominio'])
        .toSet();
    expect(dominiosConsultados, {'inter', 'produtos_inter'});
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
