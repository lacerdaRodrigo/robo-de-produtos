import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/componentes/estados.dart';
import 'package:app_robo/app/paginas/inicio.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';

Map<String, Object?> resumo({
  String livelo = 'atualizado',
  String cashback = 'atualizado',
  String produtos = 'atualizado',
}) => {
  'gerado_em': '2026-08-23T12:00:00.000Z',
  'estado_geral':
      [livelo, cashback, produtos].every((estado) => estado == 'atualizado')
      ? 'atualizado'
      : 'atencao',
  'livelo': {
    'estado': livelo,
    'ultimo_sucesso_em': '2026-08-23T08:00:00.000Z',
    'lojas_acompanhadas': 126,
    'alertas_ultima_coleta': 2,
  },
  'cashback_inter': {
    'estado': cashback,
    'ultima_tentativa_em': '2026-08-23T07:00:00.000Z',
    'ultima_tentativa_estado': 'sucesso',
    'ultimo_sucesso_em': '2026-08-23T07:10:00.000Z',
    'lojas_acompanhadas': 4,
    'lojas_encontradas_ultima_coleta': 3,
  },
  'produtos': {
    'estado': produtos,
    'ultima_tentativa_em': '2026-08-23T06:00:00.000Z',
    'ultima_tentativa_estado': produtos == 'parcial' ? 'parcial' : 'sucesso',
    'dados_mais_antigos_em': '2026-08-23T06:05:00.000Z',
    'dados_mais_recentes_em': '2026-08-23T06:30:00.000Z',
    'qualidade': produtos == 'degradado' ? 'degradada' : 'completa',
    'lojas_selecionadas': 3,
    'lojas_sem_coleta': produtos == 'parcial' ? 1 : 0,
    'produtos_ativos': 3310,
  },
};

Api apiQueResponde(Future<http.Response> Function(http.Request) responder) =>
    Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient(responder),
      ),
    );

Future<void> abrir(
  WidgetTester at,
  Api api, {
  VoidCallback? aoAbrirLojas,
  VoidCallback? aoAbrirLivelo,
  VoidCallback? aoAbrirProdutos,
  VoidCallback? aoAbrirCashback,
  Size tamanho = const Size(390, 844),
  double escalaTexto = 1,
  bool compacto = false,
}) async {
  at.view.devicePixelRatio = 1;
  at.view.physicalSize = tamanho;
  addTearDown(at.view.resetDevicePixelRatio);
  addTearDown(at.view.resetPhysicalSize);
  await at.pumpWidget(
    MaterialApp(
      theme: tamanho.width >= 920
          ? TemaRadar.legadoClaroComCores()
          : TemaRadar.claro(),
      home: Scaffold(
        body: PaginaInicio(
          api: api,
          aoAbrirLojas: aoAbrirLojas,
          aoAbrirLivelo: aoAbrirLivelo,
          aoAbrirProdutos: aoAbrirProdutos,
          aoAbrirCashback: aoAbrirCashback,
          agora: () => DateTime(2026, 8, 23),
          experienciaCompacta: compacto,
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('mostra carregamento antes do resumo', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await at.pumpAndSettle();
  });

  testWidgets('exibe métricas reais, recortes e estados independentes', (
    at,
  ) async {
    final api = apiQueResponde((requisicao) async {
      expect(requisicao.url.path, '/api/resumo');
      expect(requisicao.headers['authorization'], 'Bearer token-teste');
      return http.Response(jsonEncode(resumo()), 200);
    });
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.text('Seu radar hoje'), findsOneWidget);
    expect(find.text('Os três domínios estão atualizados.'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('3.310'), findsOneWidget);
    expect(find.text('Última coleta válida'), findsOneWidget);
    await at.scrollUntilVisible(find.text('Estado por domínio'), 300);
    await at.drag(
      find.byKey(const Key('resumo-inicio')),
      const Offset(0, -300),
    );
    await at.pumpAndSettle();
    expect(find.text('Atualizado'), findsNWidgets(3));
  });

  testWidgets('prioriza parcial e mantém os horários por domínio', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo(produtos: 'parcial')), 200),
    );
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.text('Produtos: parcial'), findsOneWidget);
    await at.scrollUntilVisible(find.text('Estado por domínio'), 400);
    expect(find.text('Parcial'), findsOneWidget);
    expect(find.textContaining('1 sem coleta'), findsOneWidget);
  });

  testWidgets('domínio indisponível usa traço em vez de zero inventado', (
    at,
  ) async {
    final corpo = resumo(livelo: 'indisponivel');
    final livelo = Map<String, Object?>.from(corpo['livelo']! as Map);
    livelo['ultimo_sucesso_em'] = null;
    corpo['livelo'] = livelo;
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(corpo), 200),
    );
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(find.text('Livelo: indisponível'), findsOneWidget);
  });

  testWidgets('falha inicial mostra retry', (at) async {
    final api = apiQueResponde(
      (_) async =>
          http.Response('{"erro":{"codigo":"inesperado","mensagem":"x"}}', 500),
    );
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.byType(EstadoFalha), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('falha ao atualizar preserva o último resumo', (at) async {
    var chamadas = 0;
    final api = apiQueResponde((_) async {
      chamadas++;
      if (chamadas == 1) return http.Response(jsonEncode(resumo()), 200);
      return http.Response(
        '{"erro":{"codigo":"inesperado","mensagem":"x"}}',
        500,
      );
    });
    await abrir(at, api);
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('atualizar-resumo')));
    await at.pumpAndSettle();

    expect(find.text('Seu radar hoje'), findsOneWidget);
    expect(
      find.text('A atualização falhou. Mantivemos o último resumo recebido.'),
      findsOneWidget,
    );
  });

  testWidgets('Início compacto consulta novamente a cada 30 segundos', (
    at,
  ) async {
    var chamadas = 0;
    final api = apiQueResponde((_) async {
      chamadas++;
      return http.Response(jsonEncode(resumo()), 200);
    });
    await abrir(at, api, compacto: true);
    await at.pumpAndSettle();
    expect(chamadas, 1);
    await at.pump(const Duration(seconds: 30));
    await at.pumpAndSettle();
    expect(chamadas, 2);
  });

  testWidgets('quatro atalhos chamam jornadas reais', (at) async {
    final abertos = <String>[];
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(
      at,
      api,
      aoAbrirLojas: () => abertos.add('lojas'),
      aoAbrirLivelo: () => abertos.add('livelo'),
      aoAbrirProdutos: () => abertos.add('produtos'),
      aoAbrirCashback: () => abertos.add('cashback'),
      tamanho: const Size(1200, 2000),
    );
    await at.pumpAndSettle();

    for (final chave in [
      'atalho-lojas',
      'atalho-livelo',
      'atalho-produtos',
      'atalho-cashback',
    ]) {
      final atalho = find.byKey(Key(chave));
      await at.tap(atalho);
    }
    expect(abertos, ['lojas', 'livelo', 'produtos', 'cashback']);
  });

  testWidgets('layout amplo e texto ampliado não estouram', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api, tamanho: const Size(1200, 900), escalaTexto: 1.5);
    await at.pumpAndSettle();

    expect(at.takeException(), isNull);
    expect(find.text('Produtos ativos'), findsOneWidget);
  });

  testWidgets('celular estreito com texto ampliado alcança todos os estados', (
    at,
  ) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api, tamanho: const Size(320, 640), escalaTexto: 1.5);
    await at.pumpAndSettle();
    expect(at.takeException(), isNull, reason: 'topo do resumo');
    await at.scrollUntilVisible(find.text('Estado por domínio'), 300);

    expect(at.takeException(), isNull, reason: 'estados por domínio');
    expect(find.text('Estado por domínio'), findsOneWidget);
  });

  testWidgets('Início mobile confere com o golden aprovado', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api);
    await at.pumpAndSettle();

    await expectLater(
      find.byType(PaginaInicio),
      matchesGoldenFile('../../goldens/inicio_mobile.png'),
    );
  });

  testWidgets('Início Web amplo confere com o golden aprovado', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api, tamanho: const Size(1440, 900));
    await at.pumpAndSettle();

    await expectLater(
      find.byType(PaginaInicio),
      matchesGoldenFile('../../goldens/inicio_web.png'),
    );
  });
}
