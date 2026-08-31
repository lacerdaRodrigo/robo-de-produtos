import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/formato.dart';
import 'package:app_robo/features/livelo/formato_livelo.dart';

void main() {
  test('PontuacaoLivelo preserva decimais e opcionais como texto', () {
    final loja = PontuacaoLivelo.parse({
      'nome': 'Casas Bahia',
      'categoria': 'Marketplace',
      'pontos_atuais': '2.90',
      'pontos_base': '1.00',
      'pontos_clube': null,
      'valor_de_disparo': '4.00',
      'moeda': 'R\$',
      'prefixo_ate': true,
      'em_promocao': true,
      'alertou': true,
      'campanha': 'PROMOTION_CLUB',
      'descricao_campanha': 'Válida no site.',
      'fim_promocao': '2026-08-22T23:59:00Z',
    });

    expect(loja.pontosAtuais, '2.90');
    expect(loja.pontosBase, '1.00');
    expect(loja.pontosClube, isNull);
    expect(loja.valorDeDisparo, '4.00');
    expect(loja.prefixoAte, isTrue);
    expect(loja.alertou, isTrue);
    expect(loja.descricaoCampanha, 'Válida no site.');
  });

  test('PontuacaoLivelo aceita campos opcionais ausentes', () {
    final loja = PontuacaoLivelo.parse({
      'nome': 'Loja sem retrato',
      'moeda': 'R\$',
      'prefixo_ate': false,
      'em_promocao': false,
      'alertou': false,
    });

    expect(loja.categoria, isNull);
    expect(loja.pontosAtuais, isNull);
    expect(loja.valorDeDisparo, isNull);
    expect(loja.campanha, isNull);
  });

  test('catálogo Livelo preserva ID, categorias e decimais textuais', () {
    final pagina = PaginaCatalogoLivelo.parse({
      'itens': [
        {
          'id_externo': 'NAT',
          'nome': 'Natura',
          'categorias': ['Beleza'],
          'pontos_atuais': '2.90',
          'pontos_base': '1.00',
          'pontos_clube': '3.50',
          'moeda': 'R\$',
          'prefixo_ate': true,
          'em_promocao': true,
          'acompanhada': false,
          'alerta': false,
        },
      ],
      'resumo': {
        'ultima_coleta': '2026-08-28T12:00:00Z',
        'ultima_tentativa_em': '2026-08-28T12:05:00Z',
        'qualidade': 'degradada',
        'parceiros_lidos': 252,
        'total_catalogo': 252,
        'acompanhadas': 0,
        'alertas': 0,
        'melhor_oferta': {
          'id_externo': 'NAT',
          'nome': 'Natura',
          'pontos_atuais': '2.90',
          'moeda': 'R\$',
          'prefixo_ate': true,
        },
      },
      'categorias': ['Beleza'],
      'pagina': 1,
      'por_pagina': 20,
      'total_itens': 252,
      'total_paginas': 13,
      'tem_proxima': true,
    });

    expect(pagina.itens.single.idExterno, 'NAT');
    expect(pagina.itens.single.pontosAtuais, '2.90');
    expect(pagina.itens.single.pontosClube, '3.50');
    expect(pagina.resumo.melhorOferta!.pontosAtuais, '2.90');
    expect(pagina.resumo.ultimaTentativaEm, '2026-08-28T12:05:00Z');
    expect(pagina.resumo.qualidade, 'degradada');
    expect(pagina.totalPaginas, 13);

    final legado = ResumoCatalogoLivelo.parse(<String, dynamic>{});
    expect(legado.ultimaTentativaEm, isNull);
    expect(legado.qualidade, isNull);
  });

  test('decimal remove zeros sem usar double', () {
    expect(decimal('2.90'), '2,9');
    expect(decimal('6.000'), '6');
    expect(decimal(null), isNull);
  });

  test('rótulos do Clube distinguem as campanhas', () {
    expect(rotuloClube('CLUB'), 'Exclusivo para assinantes Clube');
    expect(rotuloClube('PROMOTION_CLUB'), 'Assinantes Clube ganham mais');
    expect(rotuloClube('PROMOTION'), isNull);
  });

  test('validade e atraso usam relógio explícito', () {
    final agora = DateTime.utc(2026, 8, 22, 15);

    expect(coletaAtrasada('2026-08-22T02:59:00Z', agora), isTrue);
    expect(coletaAtrasada('2026-08-22T03:00:00Z', agora), isFalse);
    expect(dataHoraLivelo('2026-08-22T15:30:00Z'), '22/08/2026, 12:30');
    expect(validadeLivelo('2026-08-22T23:59:00Z'), 'Válido até 22/08/2026');
  });
}
