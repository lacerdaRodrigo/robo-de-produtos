import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/pagina.dart';

void main() {
  ProdutoParse leitor(Map<String, dynamic> objeto) =>
      ProdutoParse(objeto['nome']?.toString() ?? '');

  test('parse do envelope completo', () {
    final pagina = Pagina.parse({
      'itens': [
        {'nome': 'A'},
        {'nome': 'B'},
      ],
      'pagina': 1,
      'por_pagina': 20,
      'total_itens': 45,
      'total_paginas': 3,
      'tem_proxima': true,
      'atualizado_em': '2026-08-19T00:00:00Z',
      'qualidade': 'degradada',
      'ultima_tentativa_em': '2026-08-19T01:00:00Z',
      'ultima_tentativa_estado': 'parcial',
    }, leitor);

    expect(pagina.itens.map((p) => p.nome), ['A', 'B']);
    expect(pagina.totalPaginas, 3);
    expect(pagina.temProxima, isTrue);
    expect(pagina.atualizadoEm, '2026-08-19T00:00:00Z');
    expect(pagina.qualidade, 'degradada');
    expect(pagina.ultimaTentativaEm, '2026-08-19T01:00:00Z');
    expect(pagina.ultimaTentativaEstado, 'parcial');
  });

  test('campos ausentes ou nulos têm padrões seguros', () {
    final pagina = Pagina.parse({'itens': null}, leitor);

    expect(pagina.vazia, isTrue);
    expect(pagina.pagina, 1);
    expect(pagina.porPagina, 20);
    expect(pagina.totalPaginas, 1);
    expect(pagina.temProxima, isFalse);
    expect(pagina.atualizadoEm, isNull);
    expect(pagina.qualidade, isNull);
  });

  test('total_itens ausente não corta: usa o tamanho real da página', () {
    final pagina = Pagina.parse({
      'itens': [
        {'nome': 'A'},
        {'nome': 'B'},
        {'nome': 'C'},
      ],
    }, leitor);

    expect(pagina.totalItens, 3);
  });

  test('tem_proxima orienta a próxima página', () {
    final temAinda = Pagina.parse({
      'itens': [],
      'tem_proxima': true,
      'por_pagina': 20,
      'pagina': 1,
    }, leitor);
    final acabou = Pagina.parse({
      'itens': [],
      'tem_proxima': false,
      'por_pagina': 20,
      'pagina': 3,
    }, leitor);

    expect(temAinda.temProxima, isTrue);
    expect(acabou.temProxima, isFalse);
  });
}

class ProdutoParse {
  ProdutoParse(this.nome);
  final String nome;
}
