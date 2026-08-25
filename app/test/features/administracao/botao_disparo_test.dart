import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/idempotencia.dart';
import 'package:app_robo/features/administracao/botao_disparo.dart';

void main() {
  test('chave idempotente é opaca e tem comprimento aceito pelo servidor', () {
    final chave = novaChaveDeIdempotencia();

    expect(chave, matches(RegExp(r'^[a-f0-9]{48}$')));
  });

  testWidgets('admin solicita coleta uma vez e guarda o cooldown', (at) async {
    final requisicoes = <http.Request>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          requisicoes.add(requisicao);
          if (requisicao.method == 'POST') {
            return http.Response(
              jsonEncode({
                'dominio': 'inter',
                'estado': 'aceito',
                'cooldown_segundos': 300,
              }),
              202,
            );
          }
          return http.Response(
            jsonEncode({
              'dominio': 'inter',
              'cooldown_segundos': 0,
              'ultima_solicitacao_em': null,
              'ultimo_estado': null,
            }),
            200,
          );
        }),
      ),
    );

    await at.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BotaoDisparo(api: api, dominio: 'inter', administrador: true),
        ),
      ),
    );
    await at.pumpAndSettle();
    await at.tap(find.text('Atualizar agora'));
    await at.pumpAndSettle();

    final post = requisicoes
        .where((requisicao) => requisicao.method == 'POST')
        .single;
    expect(post.headers['idempotency-key'], matches(RegExp(r'^[a-f0-9]{48}$')));
    expect(find.textContaining('Aguarde 5 min'), findsOneWidget);
  });
}
