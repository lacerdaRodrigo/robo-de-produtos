import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/app.dart';
import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/core/api/api_v1.dart';
import 'package:app_robo/core/api/cliente.dart';

ApiV1 _api() => ApiV1(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    cliente: http_testing.MockClient(
      (_) async => http.Response('{"api":"v1","saudavel":true}', 200),
    ),
  ),
);

void main() {
  // No viewport estreto dos testes a barra lateral fica só com íconos; por
  // isso verificamos por ícono.
  testWidgets('a barra lateral mostra os cinco destinos', (at) async {
    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: _api()));

    for (final destino in Destino.values) {
      expect(find.byIcon(destino.icone), findsWidgets);
    }
  });

  testWidgets('Início aparece por padrão e conecta com a API', (at) async {
    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: _api()));
    await at.pumpAndSettle();

    expect(find.text('Serviço conectado'), findsOneWidget);
  });

  testWidgets('tocar o ícone de Livelo troca o painel', (at) async {
    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: _api()));
    await at.pumpAndSettle();

    await at.tap(find.byIcon(Icons.star_outline));
    await at.pumpAndSettle();

    expect(find.text('Ainda não implementado nesta fase.'), findsWidgets);
  });
}
