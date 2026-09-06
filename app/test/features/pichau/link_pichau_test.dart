import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/features/pichau/link_pichau.dart';

void main() {
  test('aceita somente destinos HTTP e HTTPS com autoridade', () {
    expect(
      linkSeguroPichau('https://www.pichau.com.br/produto/1'),
      Uri.parse('https://www.pichau.com.br/produto/1'),
    );
    expect(
      linkSeguroPichau('http://www.pichau.com.br/produto/1'),
      Uri.parse('http://www.pichau.com.br/produto/1'),
    );
    expect(linkSeguroPichau('javascript:alert(1)'), isNull);
    expect(linkSeguroPichau('/produto/1'), isNull);
  });
}
