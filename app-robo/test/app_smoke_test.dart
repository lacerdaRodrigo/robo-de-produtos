// Teste de fundação: o app sobe e, injetando API falsa, nunca toca rede.

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/app.dart';
import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/core/api/api_v1.dart';
import 'package:app_robo/core/api/cliente.dart';

void main() {
  testWidgets('RadarApp sobe e mostra a navegacao', (WidgetTester at) async {
    final api = ApiV1(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        cliente: http_testing.MockClient(
          (_) async => http.Response('{"api":"v1","saudavel":true}', 200),
        ),
      ),
    );

    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: api));

    expect(find.byIcon(Destino.inicio.icone), findsWidgets);
    expect(find.byIcon(Destino.alertas.icone), findsWidgets);
  });
}
