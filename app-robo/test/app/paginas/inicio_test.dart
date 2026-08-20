import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/componentes/estados.dart';
import 'package:app_robo/app/paginas/inicio.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api_v1.dart';
import 'package:app_robo/core/api/cliente.dart';

ApiV1 apiQue(http.Response resposta) => ApiV1(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    cliente: http_testing.MockClient((_) async => resposta),
  ),
);

Widget envolto(ApiV1 api) => MaterialApp(
  theme: TemaRadar.claro(),
  home: PaginaInicio(api: api),
);

void main() {
  testWidgets('mostra carregando enquanto responde', (at) async {
    final api = apiQue(http.Response('{"api":"v1","saudavel":true}', 200));
    await at.pumpWidget(envolto(api));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await at.pumpAndSettle();
  });

  testWidgets('status ok mostra serviço conectado', (at) async {
    final api = apiQue(
      http.Response('{"api":"v1","produto":"Radar","saudavel":true}', 200),
    );
    await at.pumpWidget(envolto(api));
    await at.pumpAndSettle();

    expect(find.text('Serviço conectado'), findsOneWidget);
    expect(find.text('API v1'), findsOneWidget);
  });

  testWidgets('falha de rede mostra estado de falha com retry', (at) async {
    final api = apiQue(http.Response('erro', 200));
    await at.pumpWidget(envolto(api));
    await at.pumpAndSettle();

    expect(find.byType(EstadoFalha), findsOneWidget);
  });

  testWidgets('erro da API mostra estado de falha', (at) async {
    final api = apiQue(
      http.Response('{"erro":{"codigo":"inesperado","mensagem":"x"}}', 500),
    );
    await at.pumpWidget(envolto(api));
    await at.pumpAndSettle();

    expect(find.byType(EstadoFalha), findsOneWidget);
  });
}
