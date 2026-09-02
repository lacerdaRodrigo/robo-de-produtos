// Teste de fundação: o app sobe e, injetando API falsa, nunca toca rede.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/app.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';

const _resumoVazio =
    '{"gerado_em":"2026-08-23T12:00:00Z","estado_geral":"sem_dados",'
    '"livelo":{"estado":"sem_dados"},'
    '"cashback_inter":{"estado":"sem_dados"},'
    '"produtos":{"estado":"sem_dados"}}';

void main() {
  testWidgets('RadarApp sobe e mostra a navegacao', (WidgetTester at) async {
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        cliente: http_testing.MockClient(
          (requisicao) async => http.Response(
            requisicao.url.path == '/api/resumo'
                ? _resumoVazio
                : '{"api":"v1","saudavel":true}',
            200,
          ),
        ),
      ),
    );

    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: api));

    expect(find.byKey(const Key('abrir-menu-principal')), findsOneWidget);
    expect(find.byKey(const Key('abrir-conta-cabecalho')), findsOneWidget);
  });
}
