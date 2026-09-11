import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';

void main() {
  test('parser preserva valores financeiros como texto e leitura', () {
    final alerta = AlertaApp.parse({
      'id': '8',
      'origem': 'inter_produto',
      'tipo': 'preco',
      'entidade_id': '3',
      'entidade_externa': 'sku-3',
      'entidade_nome': 'Produto',
      'coleta_id': '22',
      'valor_anterior': '3799.90',
      'valor_atual': '3688.89',
      'unidade': 'reais',
      'direcao': 'reducao',
      'lido': false,
      'criado_em': '2026-09-10T12:00:00Z',
    });

    expect(alerta.tipo, TipoAlertaApp.preco);
    expect(alerta.valorAnterior, '3799.90');
    expect(alerta.valorAtual, '3688.89');
    expect(alerta.lido, isFalse);
    expect(alerta.copiarCom(lido: true).lido, isTrue);
  });

  test('preferências serializam somente flags do contrato', () {
    const preferencias = PreferenciasAlertas(
      pushGlobal: false,
      preco: true,
      cashback: false,
      pontuacao: true,
    );
    expect(preferencias.toJson(), {
      'push_global': false,
      'preco': true,
      'cashback': false,
      'pontuacao': true,
    });
  });
}
