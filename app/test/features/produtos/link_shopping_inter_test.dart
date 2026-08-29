import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/features/produtos/link_shopping_inter.dart';

void main() {
  test('reconstrói caminho relativo no HTTPS fixo do Shopping Inter', () {
    expect(
      linkSeguroShoppingInter('produto/edge-60?v=azul'),
      Uri.parse('https://shopping.inter.co/produto/edge-60?v=azul'),
    );
  });

  test('recusa URL, autoridade e navegação hostis', () {
    for (final caminho in [
      'https://outro.exemplo/produto',
      '//outro.exemplo/produto',
      'produto/../senha',
      'produto/%2e%2e/senha',
      '',
    ]) {
      expect(linkSeguroShoppingInter(caminho), isNull);
    }
  });
}
