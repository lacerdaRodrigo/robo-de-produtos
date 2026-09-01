import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/inter/formato_cashback_inter.dart';

void main() {
  test('CashbackInter preserva textos, decimais e campos opcionais', () {
    final loja = CashbackInter.parse({
      'id': 'loja-1',
      'slug': 'loja-e-cia',
      'nome': 'Loja & Cia',
      'cashback_principal_texto': 'Até 12% de cashback',
      'cashback_principal_valor': '12.00',
      'cashback_secundario_texto': '2% de cashback',
      'cashback_secundario_valor': '2.00',
      'etiqueta': 'Oferta especial',
      'descricao_principal': 'Em itens selecionados\nEnquanto durar o estoque',
      'descricao_secundaria': null,
      'encontrada': true,
      'favorita': false,
      'link': 'https://shopping.inter.co/site-parceiro/lojas',
    });

    expect(loja.cashbackPrincipalTexto, 'Até 12% de cashback');
    expect(loja.cashbackPrincipalValor, '12.00');
    expect(loja.cashbackSecundarioValor, '2.00');
    expect(loja.descricaoSecundaria, isNull);
    expect(loja.encontrada, isTrue);
    expect(loja.link, 'https://shopping.inter.co/site-parceiro/lojas');
  });

  test('formata coleta do Inter em Brasília e atrasa apenas depois de 24h', () {
    final agora = DateTime.utc(2026, 8, 23, 12);

    expect(dataHoraInter('2026-08-22T15:30:00Z'), '22/08/2026, 12:30');
    expect(coletaInterAtrasada('2026-08-22T12:00:00Z', agora), isFalse);
    expect(coletaInterAtrasada('2026-08-22T11:59:00Z', agora), isTrue);
  });

  test('resume instante e percentual sem converter decimal para double', () {
    final agora = DateTime.utc(2026, 8, 23, 12);

    expect(
      tempoColetaInter('2026-08-23T11:38:00Z', agora),
      'Cashback há 22 min',
    );
    expect(tempoColetaInter(null, agora), 'Condição publicada pelo Inter');
    expect(percentualCompactoInter('20.00'), '20%');
    expect(percentualCompactoInter('7.50'), '7,5%');
    expect(percentualCompactoInter('não informado'), isNull);
  });
}
