import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/alertas/formatacao_alertas.dart';

void main() {
  test('formata preço decimal sem usar double', () {
    expect(
      formatarValorAlerta('2092.880000', TipoAlertaApp.preco),
      'R\$ 2.092,88',
    );
    expect(
      formatarValorAlerta('2102.810000', TipoAlertaApp.preco),
      'R\$ 2.102,81',
    );
  });

  test('arredonda somente a apresentação e preserva carry', () {
    expect(formatarValorAlerta('999.995', TipoAlertaApp.preco), 'R\$ 1.000,00');
    expect(formatarValorAlerta('0002.5', TipoAlertaApp.preco), 'R\$ 2,50');
  });

  test('não altera pontuação nem valor inválido', () {
    expect(
      formatarValorAlerta('2.000000', TipoAlertaApp.pontuacao),
      '2.000000',
    );
    expect(
      formatarValorAlerta('indisponível', TipoAlertaApp.preco),
      'indisponível',
    );
  });
}
