import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/alertas/pagina_permissao_notificacoes.dart';

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((_) async => http.Response('{}', 200)),
  ),
);

void main() {
  testWidgets('permite revisar o pedido de push e adiar a decisão', (at) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(390, 844);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PaginaPermissaoNotificacoes(api: _api()),
                ),
              ),
              child: const Text('Abrir permissão'),
            ),
          ),
        ),
      ),
    );

    await at.tap(find.text('Abrir permissão'));
    await at.pumpAndSettle();
    expect(find.text('Quer receber mudanças importantes?'), findsOneWidget);
    expect(find.byKey(const Key('permitir-notificacoes')), findsOneWidget);
    await at.tap(find.byKey(const Key('agora-nao-notificacoes')));
    await at.pumpAndSettle();

    expect(find.text('Permissão de notificações'), findsNothing);
  });
}
