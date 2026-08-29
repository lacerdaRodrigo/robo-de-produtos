import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/produtos/formato_produtos.dart';

void main() {
  test('histórico preserva NUMERIC como texto e medição paginada', () {
    final historico = HistoricoProdutoDireto.parse({
      'produto': {
        'id_externo': 'edge-60',
        'nome': 'Motorola Edge 60 Pro',
        'marca': 'Motorola',
        'categoria': 'Celular',
        'caminho': 'produto/edge-60',
        'preco_cheio_texto': 'R\$ 4.000,00',
        'preco_cheio_valor': '4000.00',
        'preco_atual_texto': 'R\$ 3.688,89',
        'preco_atual_valor': '3688.89',
        'desconto_texto': null,
        'desconto_percentual_texto': null,
        'cashback_texto': '9% de cashback',
        'cashback_percentual_texto': '9%',
        'preco_liquido_texto': 'R\$ 3.356,89',
        'parcelamento': null,
        'estoque': 4,
        'etiquetas': ['Oferta'],
        'loja_slug': 'casas-bahia',
        'loja_nome': 'Casas Bahia',
        'atualizada_em': '2026-08-22T12:00:00Z',
      },
      'minimo': '3500.00',
      'maximo': '4000.00',
      'medicoes': [
        {
          'momento': '2026-08-22T12:00:00Z',
          'preco_atual_valor': '3688.89',
          'cashback_valor': '332.00',
          'preco_liquido_valor': '3356.89',
        },
      ],
      'pagina': 1,
      'por_pagina': 30,
      'total_itens': 90,
      'tem_proxima': true,
    });

    expect(historico.minimo, '3500.00');
    expect(historico.medicoes.single.cashbackValor, '332.00');
    expect(historico.temProxima, isTrue);
  });

  test('coleta de produtos atrasa somente após 12 horas e mostra Brasília', () {
    final agora = DateTime.utc(2026, 8, 23);
    expect(coletaProdutosAtrasada('2026-08-22T12:00:00Z', agora), isFalse);
    expect(coletaProdutosAtrasada('2026-08-22T11:59:00Z', agora), isTrue);
    expect(dataHoraProduto('2026-08-22T15:30:00Z'), '22/08/2026, 12:30');
  });

  test('loja direta aceita booleanos compatíveis do contrato HTTP', () {
    final loja = LojaDireto.parse({
      'id': 12,
      'id_externo': 'parceiro-12',
      'slug': 'casas-bahia',
      'nome': 'Casas Bahia',
      'selecionada': '1',
      'ativa': 'on',
    });

    expect(loja.id, '12');
    expect(loja.idExterno, 'parceiro-12');
    expect(loja.selecionada, isTrue);
    expect(loja.ativa, isTrue);
  });
}
