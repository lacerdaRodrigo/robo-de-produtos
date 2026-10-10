import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/filtros_app.dart';
import 'package:app_robo/design_system/design_system.dart';

void main() {
  group('SecaoFaixa', () {
    test('converte decimal pt-BR em centavos sem double', () {
      expect(SecaoFaixa.centavosDe('1.234,5'), 123450);
      expect(SecaoFaixa.centavosDe('99'), 9900);
      expect(SecaoFaixa.centavosDe('10.50'), 1050);
      expect(SecaoFaixa.centavosDe('abc'), isNull);
      expect(SecaoFaixa.paraApi('1.234,5'), '1234.50');
    });

    test('máximo menor que mínimo é inválido', () {
      const secao = SecaoFaixa(id: 'preco', titulo: 'Preço');
      expect(
        secao.validar(const FaixaValor(minimo: '500', maximo: '100')),
        isNotNull,
      );
      expect(
        secao.validar(const FaixaValor(minimo: '100', maximo: '500')),
        isNull,
      );
    });
  });

  group('RegistroFiltros', () {
    test('estado do escopo é único e ordenação não conta como ativo', () {
      final registro = criarRegistroFiltrosApp();
      addTearDown(registro.dispose);
      final pichau = registro.de(EscopoFiltro.pichau);

      expect(pichau.ativos, 0);
      pichau.aplicar(pichau.value.com(IdFiltro.ordenar, 'nome'));
      expect(pichau.ativos, 0);

      pichau.aplicar(pichau.value.com(IdFiltro.disponibilidade, 'esgotados'));
      expect(pichau.ativos, 1);
      // Outra leitura do mesmo escopo vê o mesmo estado.
      expect(registro.de(EscopoFiltro.pichau).ativos, 1);

      pichau.limpar();
      expect(pichau.ativos, 0);
    });

    test('valores iguais não notificam de novo', () {
      final registro = criarRegistroFiltrosApp();
      addTearDown(registro.dispose);
      final central = registro.de(EscopoFiltro.central);
      var notificacoes = 0;
      central.addListener(() => notificacoes++);
      central.aplicar(central.espec.padroes);
      expect(notificacoes, 0);
    });
  });
}
