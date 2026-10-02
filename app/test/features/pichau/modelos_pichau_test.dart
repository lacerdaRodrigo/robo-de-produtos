import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/features/pichau/modelos_pichau.dart';

void main() {
  test('lê o estado da última tentativa do resumo real da API', () {
    final pagina = PaginaCatalogoPichau.parse({
      'itens': <dynamic>[],
      'resumo': <String, dynamic>{
        'ultima_tentativa_estado': 'parcial',
        'qualidade': 'degradada',
      },
      'pagina': 1,
      'por_pagina': 20,
      'total_itens': 0,
      'total_paginas': 1,
      'tem_proxima': false,
    });

    expect(pagina.ultimaTentativaEstado, 'parcial');
    expect(pagina.qualidade, 'degradada');
  });

  test(
    'preserva campos comerciais opcionais sem transformar ausência em zero',
    () {
      final produto = PichauProduto.parse({
        'id_externo': 'PG-7800',
        'nome': 'PC Gamer ilustrativo',
        'marca': 'Pichau',
        'categoria_externa': 'PC Gamer',
        'url_produto': 'https://www.pichau.com.br/produto/pg-7800',
        'presente_no_catalogo': true,
        'disponibilidade': 'disponivel',
        'preco_pix_texto': 'R\$ 7.499,90',
        'preco_original_texto': null,
        'preco_cartao_texto': null,
        'parcelamento': null,
        'sem_juros': null,
        'etiquetas': <String>['Oferta'],
      });

      expect(produto.precoPixTexto, 'R\$ 7.499,90');
      expect(produto.precoOriginalTexto, isNull);
      expect(produto.precoCartaoTexto, isNull);
      expect(produto.parcelamento, isNull);
      expect(produto.semJuros, isNull);
      expect(produto.esgotado, isFalse);
      expect(produto.foraDoCatalogo, isFalse);
    },
  );

  test('distingue esgotado de fora do catálogo', () {
    final esgotado = PichauProduto.parse({
      'id_externo': 'PG-1',
      'nome': 'Esgotado',
      'url_produto': 'https://www.pichau.com.br/produto/pg-1',
      'presente_no_catalogo': true,
      'disponibilidade': 'esgotado',
    });
    final fora = PichauProduto.parse({
      'id_externo': 'PG-2',
      'nome': 'Fora',
      'url_produto': 'https://www.pichau.com.br/produto/pg-2',
      'presente_no_catalogo': false,
      'disponibilidade': 'nao_informado',
    });

    expect(esgotado.esgotado, isTrue);
    expect(esgotado.foraDoCatalogo, isFalse);
    expect(fora.esgotado, isFalse);
    expect(fora.foraDoCatalogo, isTrue);
  });
}
