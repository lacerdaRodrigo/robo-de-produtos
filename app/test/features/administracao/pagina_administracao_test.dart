import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/administracao/pagina_administracao.dart';

void main() {
  testWidgets('lista parceiras e confirma a favorita pela API', (at) async {
    final chamadas = <http.Request>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          chamadas.add(requisicao);
          if (requisicao.method == 'PATCH') {
            return http.Response('{"id":"1","favorita":true}', 200);
          }
          if (requisicao.url.path == '/api/livelo/preferencias') {
            return http.Response(
              '{"multiplicador_padrao":"2","piso_pontos_padrao":"4","assinante_clube":false}',
              200,
            );
          }
          if (requisicao.url.path != '/api/inter/lojas') {
            if (requisicao.url.path == '/api/inter/produtos/lojas') {
              return http.Response(
                '{"itens":[{"id":"2","id_externo":"direta-2",'
                '"slug":"direta","nome":"Loja direta","selecionada":true,'
                '"ativa":true,"ultima_execucao":"2026-08-30T15:00:00Z",'
                '"ultimo_estado":"sucesso","paginas":12}],"pagina":1,'
                '"por_pagina":20,"total_itens":1,"total_paginas":1,'
                '"tem_proxima":false}',
                200,
              );
            }
            return http.Response(
              '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,"total_paginas":1,"tem_proxima":false}',
              200,
            );
          }
          return http.Response(
            jsonEncode({
              'itens': [
                {
                  'id': '1',
                  'id_externo': 'externo-1',
                  'slug': 'loja',
                  'nome': 'Loja parceira',
                  'cashback_principal_texto': '5% de cashback',
                  'cashback_principal_valor': '5.00',
                  'ativa': true,
                  'favorita': false,
                },
              ],
              'pagina': 1,
              'por_pagina': 20,
              'total_itens': 1,
              'total_paginas': 1,
              'tem_proxima': false,
            }),
            200,
          );
        }),
      ),
    );

    await at.pumpWidget(MaterialApp(home: PaginaAdministracao(api: api)));
    await at.pumpAndSettle();
    await at.tap(find.text('Sites parceiros'));
    await at.pumpAndSettle();

    expect(find.text('Loja parceira'), findsOneWidget);
    expect(find.text('1 encontrada(s)'), findsOneWidget);
    await at.tap(find.byType(Switch).first);
    await at.pumpAndSettle();

    final patch = chamadas.where((chamada) => chamada.method == 'PATCH').single;
    expect(patch.url.path, '/api/inter/lojas');
    expect(patch.body, '{"id":"1","favorita":true}');

    await at.tap(find.text('Compre direto'));
    await at.pumpAndSettle();
    expect(find.text('Loja direta'), findsOneWidget);
    expect(
      find.text(
        'Selecionada: sim · Atualizada em 30/08/2026, 12:00 · 12 páginas',
      ),
      findsOneWidget,
    );
  });

  testWidgets('administra preferências e loja Livelo pelo contrato seguro', (
    at,
  ) async {
    final chamadas = <http.Request>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          chamadas.add(requisicao);
          if (requisicao.url.path == '/api/livelo/preferencias') {
            if (requisicao.method == 'PATCH') {
              return http.Response(
                '{"multiplicador_padrao":"2.90","piso_pontos_padrao":"5.00","assinante_clube":true}',
                200,
              );
            }
            return http.Response(
              '{"multiplicador_padrao":"2.00","piso_pontos_padrao":"4.00","assinante_clube":false}',
              200,
            );
          }
          if (requisicao.url.path == '/api/livelo/lojas') {
            if (requisicao.method == 'POST') {
              return http.Response(
                '{"id":"8","nome":"Nova","categoria":"Viagem","apelidos":[],"multiplicador":null,"piso_pontos":null}',
                201,
              );
            }
            return http.Response(
              '{"itens":[{"id":"7","nome":"Loja Livelo","categoria":"Casa","multiplicador":"2.50","piso_pontos":null,"apelidos":["Loja BR"]}],"pagina":1,"por_pagina":20,"total_itens":1,"total_paginas":1,"tem_proxima":false}',
              200,
            );
          }
          if (requisicao.url.path == '/api/livelo/lojas/7') {
            return http.Response(
              requisicao.method == 'DELETE' ? '{"removida":true}' : '{}',
              200,
            );
          }
          return http.Response(
            '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,"total_paginas":1,"tem_proxima":false}',
            200,
          );
        }),
      ),
    );

    await at.pumpWidget(MaterialApp(home: PaginaAdministracao(api: api)));
    await at.pumpAndSettle();

    expect(find.text('Loja Livelo'), findsOneWidget);
    expect(find.textContaining('Alerta em 2.00'), findsOneWidget);

    await at.tap(find.byKey(const Key('editar-preferencias-livelo')));
    await at.pumpAndSettle();
    await at.enterText(
      find.byKey(const Key('preferencia-multiplicador')),
      '2,90',
    );
    await at.enterText(find.byKey(const Key('preferencia-piso')), '5.00');
    await at.tap(find.text('Assinante Clube Livelo'));
    await at.tap(find.byKey(const Key('confirmar-preferencias-livelo')));
    await at.pumpAndSettle();

    await at.ensureVisible(find.byKey(const Key('editar-regra-7')));
    await at.tap(find.byKey(const Key('editar-regra-7')));
    await at.pumpAndSettle();
    await at.enterText(find.byKey(const Key('regra-multiplicador')), '3.00');
    await at.enterText(find.byKey(const Key('regra-piso')), '6.00');
    await at.tap(find.byKey(const Key('confirmar-regra-livelo')));
    await at.pumpAndSettle();

    await at.ensureVisible(find.byKey(const Key('remover-loja-7')));
    await at.tap(find.byKey(const Key('remover-loja-7')));
    await at.pumpAndSettle();
    await at.tap(find.widgetWithText(FilledButton, 'Remover loja'));
    await at.pumpAndSettle();

    final preferencias = chamadas.singleWhere(
      (chamada) =>
          chamada.method == 'PATCH' &&
          chamada.url.path == '/api/livelo/preferencias',
    );
    expect(preferencias.body, contains('"multiplicador":"2,90"'));
    expect(preferencias.body, contains('"assinante_clube":true'));
    final regra = chamadas.singleWhere(
      (chamada) =>
          chamada.method == 'PATCH' &&
          chamada.url.path == '/api/livelo/lojas/7',
    );
    expect(regra.body, '{"multiplicador":"3.00","piso":"6.00"}');
    expect(
      chamadas.any(
        (chamada) =>
            chamada.method == 'DELETE' &&
            chamada.url.path == '/api/livelo/lojas/7',
      ),
      isTrue,
    );
    expect(find.text('Loja Livelo'), findsNothing);
  });

  testWidgets('usuário sem papel administrativo não consulta o catálogo', (
    at,
  ) async {
    var chamadas = 0;
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((_) async {
          chamadas++;
          return http.Response('{}', 200);
        }),
      ),
    );

    await at.pumpWidget(
      MaterialApp(home: PaginaAdministracao(api: api, administrador: false)),
    );
    await at.pumpAndSettle();

    expect(
      find.text('Seu acesso não permite administrar catálogos.'),
      findsOneWidget,
    );
    expect(chamadas, 0);
  });
}
