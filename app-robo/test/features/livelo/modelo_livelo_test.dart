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
