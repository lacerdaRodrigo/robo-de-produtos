import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/core/api/api_v1.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/administracao/zona_perigo.dart';

void main() {
  testWidgets('exige frase exata antes da limpeza Livelo', (at) async {
    final chamadas = <http.Request>[];
    final api = ApiV1(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          chamadas.add(requisicao);
          if (requisicao.method == 'POST') {
            return http.Response('{"dominio":"livelo","concluida":true}', 200);
          }
          return http.Response(
            jsonEncode({
              'dominio': 'livelo',
              'frase_confirmacao': 'APAGAR LIVELO',
              'contagens': {
                'lojas': 2,
                'apelidos': 3,
                'execucoes': 4,
                'pontuacoes': 5,
                'disparos': 1,
              },
            }),
            200,
          );
        }),
      ),
    );

    await at.pumpWidget(MaterialApp(home: ZonaPerigoAdministrativa(api: api)));
    final detalhes = find.widgetWithText(OutlinedButton, 'Ver detalhes').first;
    await at.ensureVisible(detalhes);
    await at.pumpAndSettle();
    await at.tap(detalhes);
    await at.pumpAndSettle();

    expect(find.text('Apagar dados da Livelo?'), findsOneWidget);
    expect(find.text('Lojas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    FilledButton botao = at.widget(find.byKey(const Key('confirmar-limpeza')));
    expect(botao.onPressed, isNull);

    await at.enterText(find.byKey(const Key('frase-limpeza')), 'apagar livelo');
    await at.pump();
    botao = at.widget(find.byKey(const Key('confirmar-limpeza')));
    expect(botao.onPressed, isNull);

    await at.enterText(find.byKey(const Key('frase-limpeza')), 'APAGAR LIVELO');
    await at.pump();
    botao = at.widget(find.byKey(const Key('confirmar-limpeza')));
    expect(botao.onPressed, isNotNull);
    final confirmar = find.byKey(const Key('confirmar-limpeza'));
    await at.ensureVisible(confirmar);
    await at.pumpAndSettle();
    await at.tap(confirmar);
    await at.pumpAndSettle();

    expect(find.text('Os dados da Livelo foram apagados.'), findsOneWidget);
    final post = chamadas.where((chamada) => chamada.method == 'POST').single;
    expect(post.url.path, '/api/v1/administracao/limpeza/livelo');
    expect(post.body, '{"frase":"APAGAR LIVELO"}');
  });

  testWidgets('falha do resumo permite tentar novamente sem POST', (at) async {
    var tentativas = 0;
    final api = ApiV1(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((_) async {
          tentativas++;
          if (tentativas == 1) {
            return http.Response(
              '{"erro":{"codigo":"inesperado","mensagem":"falha"}}',
              500,
            );
          }
          return http.Response(
            '{"dominio":"inter","frase_confirmacao":"RESETAR INTER",'
            '"contagens":{"produtos":0}}',
            200,
          );
        }),
      ),
    );

    await at.pumpWidget(
      MaterialApp(
        home: PaginaConfirmacaoLimpeza(api: api, dominio: 'inter'),
      ),
    );
    await at.pumpAndSettle();
    expect(
      find.text('Não foi possível consultar as contagens.'),
      findsOneWidget,
    );

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    expect(find.text('Produtos'), findsOneWidget);
    expect(tentativas, 2);
  });
}
