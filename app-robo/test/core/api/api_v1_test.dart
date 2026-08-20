import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/core/api/api_v1.dart';
import 'package:app_robo/core/api/cliente.dart';

const baseUrl = 'http://localhost:3000';

const _itens = <Map<String, Object?>>[
  {
    'id_externo': '1',
    'nome': 'Camiseta',
    'marca': 'Nike',
    'categoria': 'Moda',
    'caminho': '/produto/1',
    'preco_cheio_texto': 'R\$ 1.099,00',
    'preco_cheio_valor': '1099',
    'preco_atual_texto': 'R\$ 999,00',
    'preco_atual_valor': '999',
    'desconto_texto': 'R\$ 100,00',
    'desconto_percentual_texto': '9%',
    'cashback_texto': 'R\$ 60,00',
    'cashback_percentual_texto': '6%',
    'preco_liquido_texto': 'R\$ 939,00',
    'parcelamento': 'em até 10x',
    'estoque': 4,
    'etiquetas': <String>['Frete grátis'],
    'loja_slug': 'casas-bahia',
    'loja_nome': 'Casas Bahia',
    'atualizada_em': '2026-08-19T00:00:00Z',
  },
];

ApiV1 apiQueResponde(String corpoHttp) {
  return ApiV1(
    paginaPadrao: 20,
    cliente: ClienteApi(
      baseUrl: baseUrl,
      cliente: http_testing.MockClient(
        (_) async => http.Response(corpoHttp, 200),
      ),
    ),
  );
}

void main() {
  test('buscarProdutos converte a página e os itens', () async {
    final corpo = jsonEncode({
      'itens': _itens,
      'pagina': 1,
      'por_pagina': 20,
      'total_itens': 45,
      'total_paginas': 3,
      'tem_proxima': true,
      'atualizado_em': '2026-08-19T00:00:00Z',
      'qualidade': 'completa',
    });
    final api = apiQueResponde(corpo);

    final pagina = await api.buscarProdutos('camiseta');

    expect(pagina.itens, hasLength(1));
    expect(pagina.itens.single.nome, 'Camiseta');
    expect(pagina.itens.single.precoAtualValor, '999');
    expect(pagina.itens.single.lojaNome, 'Casas Bahia');
    expect(pagina.totalItens, 45);
    expect(pagina.totalPaginas, 3);
    expect(pagina.temProxima, isTrue);
    expect(pagina.qualidade, 'completa');
  });

  test('buscarProdutos envia filtros na consulta', () async {
    final consultas = <Uri>[];
    final api = ApiV1(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        cliente: http_testing.MockClient((requisicao) async {
          consultas.add(requisicao.url);
          return http.Response(
            '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,"total_paginas":1,"tem_proxima":false}',
            200,
          );
        }),
      ),
    );

    await api.buscarProdutos('tv', marca: 'Samsung', loja: 'casas-bahia');

    expect(consultas.single.queryParameters['marca'], 'Samsung');
    expect(consultas.single.queryParameters['loja'], 'casas-bahia');
    expect(consultas.single.queryParameters['q'], 'tv');
  });

  test('página vazia não inventa itens', () async {
    final api = apiQueResponde(
      '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,"total_paginas":1,"tem_proxima":false}',
    );

    final pagina = await api.buscarProdutos('nada');

    expect(pagina.vazia, isTrue);
    expect(pagina.totalItens, 0);
    expect(pagina.temProxima, isFalse);
  });

  test('status converte o marcador de saudável', () async {
    final api = apiQueResponde(
      '{"api":"v1","produto":"Radar de Benefícios","saudavel":true}',
    );

    final status = await api.status();

    expect(status.api, 'v1');
    expect(status.saudavel, isTrue);
  });
}
