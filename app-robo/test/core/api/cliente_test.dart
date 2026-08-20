import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/erros.dart';

const baseUrl = 'http://localhost:3000';

void main() {
  ClienteApi cliente(http.Response resposta) => ClienteApi(
    baseUrl: baseUrl,
    cliente: http_testing.MockClient((_) async => resposta),
  );

  test('monta caminho e consulta, e decodifica JSON', () async {
    final chamadas = <Uri>[];
    final api = ClienteApi(
      baseUrl: baseUrl,
      cliente: http_testing.MockClient((requisicao) async {
        chamadas.add(requisicao.url);
        return http.Response('{"saudavel":true}', 200);
      }),
    );

    final corpo = await api.obter('/api/v1/status');

    expect(corpo, {'saudavel': true});
    expect(chamadas.single.path, '/api/v1/status');
  });

  test('passa consulta como query parameters', () async {
    final chamadas = <Uri>[];
    final api = ClienteApi(
      baseUrl: baseUrl,
      cliente: http_testing.MockClient((requisicao) async {
        chamadas.add(requisicao.url);
        return http.Response('{"itens":[]}', 200);
      }),
    );

    await api.obter(
      '/api/v1/inter/produtos',
      consulta: {'q': 'tv', 'pagina': '2', 'por_pagina': '20'},
    );

    expect(chamadas.single.queryParameters, {
      'q': 'tv',
      'pagina': '2',
      'por_pagina': '20',
    });
  });

  test('erro com corpo padrão vira ErroDeApi', () async {
    Future<void> acao() async {
      await cliente(
        http.Response('{"erro":{"codigo":"validacao","mensagem":"x"}}', 400),
      ).obter('/x');
    }

    expect(acao, throwsA(isA<ErroDeApi>()));
  });

  test('JSON inválido vira ErroDeRede', () async {
    Future<void> acao() async {
      await cliente(http.Response('isso não é json', 200)).obter('/x');
    }

    expect(acao, throwsA(isA<ErroDeRede>()));
  });

  test('corpo fora do formato vira ErroDeRede', () async {
    Future<void> acao() async {
      await cliente(http.Response('[1,2]', 200)).obter('/x');
    }

    expect(acao, throwsA(isA<ErroDeRede>()));
  });
}
