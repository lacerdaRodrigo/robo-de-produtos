import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/navegacao/moldura.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';

void main() {
  testWidgets('401 abre reautenticação sem quebrar a moldura', (at) async {
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient(
          (requisicao) async => requisicao.url.path == '/api/resumo'
              ? http.Response(
                  '{"erro":{"codigo":"autenticacao","mensagem":"sessao expirada"}}',
                  401,
                )
              : http.Response('{"api":"v1","saudavel":true}', 200),
        ),
      ),
    );

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: MolduraRadar(api: api),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('Sessão expirada'), findsOneWidget);
    expect(find.text('Entrar novamente'), findsOneWidget);
    await at.tap(find.text('Agora não'));
    await at.pumpAndSettle();
    expect(find.text('Sessão expirada'), findsNothing);
  });
}
