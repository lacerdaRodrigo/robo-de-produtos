import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/administracao/controlador_catalogo_administracao.dart';

Pagina<String> respostaPagina(
  List<String> itens, {
  int numero = 1,
  int? total,
  bool proxima = false,
}) => Pagina<String>(
  itens: itens,
  pagina: numero,
  porPagina: 20,
  totalItens: total ?? itens.length,
  totalPaginas: proxima ? numero + 1 : numero,
  temProxima: proxima,
);

void main() {
  test('carrega primeira página, próxima e deduplica pelo id', () async {
    final controlador = ControladorCatalogoAdministracao<String>(
      identificar: (item) => item,
      buscar: ({required q, required pagina}) async => pagina == 1
          ? respostaPagina(['a', 'b'], total: 3, proxima: true)
          : respostaPagina(['b', 'c'], numero: 2, total: 3),
    );

    await controlador.carregarPrimeira();
    await controlador.carregarMais();

    expect(controlador.itens, ['a', 'b', 'c']);
    expect(controlador.total, 3);
    expect(controlador.temProxima, isFalse);
    controlador.dispose();
  });

  test(
    'bloqueia paginação simultânea e preserva itens se ela falhar',
    () async {
      final proxima = Completer<Pagina<String>>();
      var chamadas = 0;
      final controlador = ControladorCatalogoAdministracao<String>(
        identificar: (item) => item,
        buscar: ({required q, required pagina}) {
          chamadas++;
          if (pagina == 1) {
            return Future.value(respostaPagina(['a'], total: 2, proxima: true));
          }
          return proxima.future;
        },
      );

      await controlador.carregarPrimeira();
      unawaited(controlador.carregarMais());
      unawaited(controlador.carregarMais());
      expect(chamadas, 2);
      proxima.completeError(StateError('sem rede'));
      await Future<void>.delayed(Duration.zero);

      expect(controlador.itens, ['a']);
      expect(controlador.erroMais, isNotNull);
      controlador.dispose();
    },
  );

  test(
    'busca aguarda debounce e ignora a resposta da consulta anterior',
    () async {
      final antiga = Completer<Pagina<String>>();
      final controlador = ControladorCatalogoAdministracao<String>(
        identificar: (item) => item,
        debounce: const Duration(milliseconds: 10),
        buscar: ({required q, required pagina}) =>
            q.isEmpty ? antiga.future : Future.value(respostaPagina([q])),
      );

      unawaited(controlador.carregarPrimeira());
      controlador.mudarBusca('renner');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      antiga.complete(respostaPagina(['antiga']));
      await Future<void>.delayed(Duration.zero);

      expect(controlador.itens, ['renner']);
      expect(controlador.busca, 'renner');
      controlador.dispose();
    },
  );

  test('substitui somente o cartão já carregado', () async {
    final controlador = ControladorCatalogoAdministracao<String>(
      identificar: (item) => item.substring(0, 1),
      buscar: ({required q, required pagina}) async =>
          respostaPagina(['a:antes']),
    );

    await controlador.carregarPrimeira();
    controlador.substituir('a', 'a:depois');
    controlador.substituir('x', 'x:ignorado');

    expect(controlador.itens, ['a:depois']);
    controlador.dispose();
  });
}
