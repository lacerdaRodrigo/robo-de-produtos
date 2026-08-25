// Testes do núcleo de formatação pt-BR (PRD 5.4 / RNF20: sem double).

import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/formato.dart';

void main() {
  group('moeda', () {
    test('formata inteiro simples', () {
      expect(moeda('123'), 'R\$ 123,00');
    });

    test('formata com centavos', () {
      expect(moeda('10.5'), 'R\$ 10,50');
      expect(moeda('10.555'), 'R\$ 10,55');
    });

    test('agrupa milhar com ponto', () {
      expect(moeda('1000'), 'R\$ 1.000,00');
      expect(moeda('1234567.9'), 'R\$ 1.234.567,90');
    });

    test('null e vazio viram null (ausência não é zero)', () {
      expect(moeda(null), isNull);
      expect(moeda(''), isNull);
    });
  });

  group('boleano', () {
    test('aceita bool e strings comuns', () {
      expect(boleano(true), isTrue);
      expect(boleano(false), isFalse);
      expect(boleano('true'), isTrue);
      expect(boleano('1'), isTrue);
      expect(boleano('on'), isTrue);
      expect(boleano('false'), isFalse);
      expect(boleano('0'), isFalse);
    });

    test('valor desconhecido vira false, sem quebrar', () {
      expect(boleano('qualquer-coisa'), isFalse);
      expect(boleano(null), isFalse);
    });
  });
}
