import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/alertas/pagina_alertas.dart';

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

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((request) async {
      if (request.url.path == '/api/alertas' && request.method == 'GET') {
        return http.Response(_alertas, 200);
      }
      if (request.url.path == '/api/alertas' && request.method == 'PATCH') {
        return http.Response('{"alterados":2,"lido":true}', 200);
      }
      return http.Response('{}', 200);
    }),
  ),
);

void main() {
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
    expect(find.text('Todos'), findsOneWidget);
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

  testWidgets('filtro abre a folha sem trocar a composição da tela', (
    tester,
  ) async {
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
    await tester.tap(find.byKey(const Key('filtrar-alertas')));
    await tester.pumpAndSettle();

    expect(find.text('Filtrar mudanças'), findsOneWidget);
    expect(find.text('Aplicar filtro'), findsOneWidget);
    expect(find.text('Preço'), findsOneWidget);
    expect(find.text('Pontuação'), findsOneWidget);
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
