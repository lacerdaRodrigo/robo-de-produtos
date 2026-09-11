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
        return http.Response(
          '{"itens":[{"id":"1","origem":"livelo","tipo":"pontuacao","entidade_id":"2","entidade_nome":"Loja","coleta_id":"9","valor_anterior":"2.00","valor_atual":"3.00","unidade":"pontos_por_real","direcao":"aumento","lido":false,"criado_em":"agora"}],"nao_lidos":1,"pagina":1,"por_pagina":2,"total_itens":3,"total_paginas":2,"tem_proxima":true}',
          200,
        );
      }
      return http.Response('{}', 200);
    }),
  ),
);

void main() {
  test('filtro novo reinicia página e mantém contrato de query', () async {
    final requisicoes = <http.Request>[];
    final controlador = ControladorAlertas(api: _api(requisicoes: requisicoes));
    addTearDown(controlador.dispose);

    await controlador.iniciar();
    expect(controlador.itens.single.valorAtual, '3.00');
    await controlador.mudarFiltro('pontuacao');

    expect(controlador.pagina, 1);
    expect(requisicoes.last.url.queryParameters['tipo'], 'pontuacao');
    expect(requisicoes.last.url.queryParameters['pagina'], '1');
  });
}
