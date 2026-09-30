import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/alertas/controlador_alertas.dart';

Api _api({required List<http.Request> requisicoes}) => Api(
  paginaPadrao: 2,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token',
    cliente: http_testing.MockClient((request) async {
      requisicoes.add(request);
      if (request.url.path == '/api/alertas' && request.method == 'GET') {
        final pagina =
            int.tryParse(request.url.queryParameters['pagina'] ?? '') ?? 1;
        return http.Response(
          jsonEncode({
            'itens': [
              {
                'id': '$pagina',
                'origem': 'livelo',
                'tipo': 'pontuacao',
                'entidade_id': '2',
                'entidade_nome': 'Loja',
                'coleta_id': '9',
                'valor_anterior': '2.00',
                'valor_atual': '3.00',
                'unidade': 'pontos_por_real',
                'direcao': 'aumento',
                'lido': false,
                'criado_em': 'agora',
              },
            ],
            'nao_lidos': 1,
            'pagina': pagina,
            'por_pagina': 2,
            'total_itens': 3,
            'total_paginas': 2,
            'tem_proxima': true,
          }),
          200,
        );
      }
      return http.Response('{}', 200);
    }),
  ),
);

void main() {
  test('aba e filtros independentes persistem ao paginar', () async {
    final requisicoes = <http.Request>[];
    final controlador = ControladorAlertas(api: _api(requisicoes: requisicoes));
    addTearDown(controlador.dispose);

    await controlador.iniciar();
    expect(controlador.itens.single.valorAtual, '3.00');
    await controlador.aplicarFiltros(origem: 'inter_produto', tipo: 'preco');

    expect(controlador.pagina, 1);
    expect(requisicoes.last.url.queryParameters['origem'], 'inter_produto');
    expect(requisicoes.last.url.queryParameters['tipo'], 'preco');
    expect(requisicoes.last.url.queryParameters['pagina'], '1');

    await controlador.mudarAba('nao_lidos');
    expect(controlador.aba, 'nao_lidos');
    expect(requisicoes.last.url.queryParameters['origem'], 'inter_produto');
    expect(requisicoes.last.url.queryParameters['tipo'], 'preco');
    expect(requisicoes.last.url.queryParameters['somente_nao_lidos'], 'true');

    await controlador.irParaPagina(2);
    expect(controlador.pagina, 2);
    expect(requisicoes.last.url.queryParameters['pagina'], '2');
    expect(requisicoes.last.url.queryParameters['origem'], 'inter_produto');
    expect(requisicoes.last.url.queryParameters['tipo'], 'preco');
    expect(requisicoes.last.url.queryParameters['somente_nao_lidos'], 'true');
  });

  test('marcar todos percorre páginas e atualiza a leitura local', () async {
    final requisicoes = <http.Request>[];
    final controlador = ControladorAlertas(api: _api(requisicoes: requisicoes));
    addTearDown(controlador.dispose);

    await controlador.iniciar();
    await controlador.aplicarFiltros(
      origem: 'inter_cashback',
      tipo: 'cashback',
    );
    await controlador.mudarAba('nao_lidos');
    await controlador.marcarTodos();

    expect(controlador.naoLidos, 0);
    expect(controlador.itens.single.lido, isTrue);
    final buscasDaVarredura = requisicoes
        .where(
          (request) =>
              request.method == 'GET' &&
              request.url.path == '/api/alertas' &&
              request.url.queryParameters['por_pagina'] == '50',
        )
        .toList();
    expect(buscasDaVarredura, hasLength(2));
    for (final busca in buscasDaVarredura) {
      expect(busca.url.queryParameters['origem'], 'inter_cashback');
      expect(busca.url.queryParameters['tipo'], 'cashback');
      expect(busca.url.queryParameters['somente_nao_lidos'], 'true');
    }
    expect(
      requisicoes.where(
        (request) =>
            request.method == 'PATCH' && request.url.path == '/api/alertas',
      ),
      hasLength(1),
    );
  });
}
