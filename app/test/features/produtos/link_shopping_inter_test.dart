import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/features/produtos/link_shopping_inter.dart';

void main() {
  test('reconstrói caminho relativo no HTTPS fixo do Shopping Inter', () {
    expect(
      linkSeguroShoppingInter('produto/edge-60?v=azul'),
      Uri.parse('https://shopping.inter.co/produto/edge-60?v=azul'),
    );
  });

  test('recusa URL, autoridade, navegação e encoding hostis', () {
    for (final caminho in [
      'https://outro.exemplo/produto',
      '//outro.exemplo/produto',
      'produto/../senha',
      'produto/%2e%2e/senha',
      'produto/9% cashback',
      '',
    ]) {
      expect(linkSeguroShoppingInter(caminho), isNull);
    }
  });

  test('aceita somente URL absoluta HTTPS do Shopping Inter', () {
    expect(
      linkAbsolutoSeguroShoppingInter(
        'https://shopping.inter.co/site-parceiro/lojas',
      ),
      Uri.parse('https://shopping.inter.co/site-parceiro/lojas'),
    );
    for (final destino in [
      'http://shopping.inter.co/site-parceiro/lojas',
      'https://outro.example/site-parceiro/lojas',
      'https://usuario@shopping.inter.co/site-parceiro/lojas',
      'https://shopping.inter.co/produto/9% cashback',
      null,
    ]) {
      expect(linkAbsolutoSeguroShoppingInter(destino), isNull);
    }
  });
}
