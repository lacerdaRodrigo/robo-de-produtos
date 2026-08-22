import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/app.dart';
import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/app/navegacao/moldura.dart';
import 'package:app_robo/core/api/api_v1.dart';
import 'package:app_robo/core/api/cliente.dart';

ApiV1 _api() => ApiV1(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient(
      (_) async => http.Response('{"api":"v1","saudavel":true}', 200),
    ),
  ),
);

void main() {
  void usarTamanho(WidgetTester at, Size tamanho) {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = tamanho;
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
  }

  testWidgets('celular mostra os cinco destinos na barra inferior', (at) async {
    usarTamanho(at, const Size(390, 844));
    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: _api()));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BarraLateral), findsNothing);
    for (final destino in Destino.values) {
      expect(find.text(destino.titulo), findsOneWidget);
      expect(find.byIcon(destino.icone), findsOneWidget);
    }
  });

  testWidgets('celular em paisagem continua com a barra inferior', (at) async {
    usarTamanho(at, const Size(844, 390));
    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: _api()));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(BarraLateral), findsNothing);
  });

  testWidgets('tela larga conserva a barra lateral', (at) async {
    usarTamanho(at, const Size(1024, 768));
    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: _api()));

    expect(find.byType(BarraLateral), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    for (final destino in Destino.values) {
      expect(find.text(destino.titulo), findsOneWidget);
    }
  });

  testWidgets('Início aparece por padrão e conecta com a API', (at) async {
    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: _api()));
    await at.pumpAndSettle();

    expect(find.text('Serviço conectado'), findsOneWidget);
  });

  testWidgets('tocar o ícone de Livelo troca o painel', (at) async {
    usarTamanho(at, const Size(390, 844));
    await at.pumpWidget(RadarApp.semAutenticacaoParaTeste(api: _api()));
    await at.pumpAndSettle();

    await at.tap(find.byIcon(Icons.star_outline));
    await at.pumpAndSettle();

    expect(
      find.text('Ainda não há uma coleta da Livelo para mostrar.'),
      findsOneWidget,
    );
  });
}
