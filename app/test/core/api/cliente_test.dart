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

    final corpo = await api.obter('/api/status', autenticado: false);

    expect(corpo, {'saudavel': true});
    expect(chamadas.single.path, '/api/status');
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
      '/api/inter/produtos',
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

    await api.obter('/api/perfil');

    expect(chamada.headers['authorization'], 'Bearer id-token');
    expect(chamada.headers['x-firebase-appcheck'], 'app-check-token');
  });

  test('PATCH administrativo leva tokens e corpo JSON', () async {
    late http.Request chamada;
    final api = ClienteApi(
      baseUrl: baseUrl,
      cliente: http_testing.MockClient((requisicao) async {
        chamada = requisicao;
        return http.Response('{"id":"loja-1","favorita":true}', 200);
      }),
      provedorToken: () async => 'id-token',
      provedorAppCheck: () async => 'app-check-token',
    );

    await api.alterar(
      '/api/inter/lojas',
      corpo: const {'id': 'loja-1', 'favorita': true},
    );

    expect(chamada.method, 'PATCH');
    expect(chamada.headers['authorization'], 'Bearer id-token');
    expect(chamada.headers['x-firebase-appcheck'], 'app-check-token');
    expect(chamada.headers['content-type'], 'application/json');
    expect(chamada.body, '{"id":"loja-1","favorita":true}');
  });

  test('POST administrativo preserva a chave idempotente', () async {
    late http.Request chamada;
    final api = ClienteApi(
      baseUrl: baseUrl,
      cliente: http_testing.MockClient((requisicao) async {
        chamada = requisicao;
        return http.Response('{"estado":"aceito"}', 202);
      }),
      provedorToken: () async => 'id-token',
    );

    await api.criar(
      '/api/administracao/disparos',
      corpo: const {'dominio': 'livelo'},
      cabecalhosExtras: const {'idempotency-key': 'chave-valida-123456'},
    );

    expect(chamada.method, 'POST');
    expect(chamada.headers['idempotency-key'], 'chave-valida-123456');
    expect(chamada.body, '{"dominio":"livelo"}');
  });

  test('DELETE administrativo leva os tokens sem corpo', () async {
    late http.Request chamada;
    final api = ClienteApi(
      baseUrl: baseUrl,
      cliente: http_testing.MockClient((requisicao) async {
        chamada = requisicao;
        return http.Response('{"removida":true}', 200);
      }),
      provedorToken: () async => 'id-token',
      provedorAppCheck: () async => 'app-check-token',
    );

    await api.remover('/api/livelo/lojas/42');

    expect(chamada.method, 'DELETE');
    expect(chamada.headers['authorization'], 'Bearer id-token');
    expect(chamada.headers['x-firebase-appcheck'], 'app-check-token');
    expect(chamada.body, isEmpty);
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
      () => api.obter('/api/perfil'),
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
