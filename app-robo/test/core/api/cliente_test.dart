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
    provedorToken: () async => 'token-teste',
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

    final corpo = await api.obter('/api/v1/status', autenticado: false);

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
      provedorToken: () async => 'id-token',
      provedorAppCheck: () async => 'app-check-token',
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

  test('envia ID token e App Check somente na chamada privada', () async {
    late http.Request chamada;
    final api = ClienteApi(
      baseUrl: baseUrl,
      cliente: http_testing.MockClient((requisicao) async {
        chamada = requisicao;
        return http.Response('{}', 200);
      }),
      provedorToken: () async => 'id-token',
      provedorAppCheck: () async => 'app-check-token',
    );

    await api.obter('/api/v1/perfil');

    expect(chamada.headers['authorization'], 'Bearer id-token');
    expect(chamada.headers['x-firebase-appcheck'], 'app-check-token');
  });

  test('não chama endpoint privado sem sessão', () async {
    var chamouRede = false;
    final api = ClienteApi(
      baseUrl: baseUrl,
      cliente: http_testing.MockClient((_) async {
        chamouRede = true;
        return http.Response('{}', 200);
      }),
    );

    expect(
      () => api.obter('/api/v1/perfil'),
      throwsA(isA<ErroDeAutenticacao>()),
    );
    expect(chamouRede, isFalse);
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
