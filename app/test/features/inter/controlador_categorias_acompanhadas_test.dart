import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/inter/controlador_categorias_acompanhadas.dart';

CategoriaInter _categoria({
  required String? valor,
  required bool selecionada,
}) => CategoriaInter(
  valor: valor,
  nome: valor ?? 'Sem categoria',
  selecionada: selecionada,
);

CatalogoCategoriasInterUsuario _catalogo({
  bool configurada = true,
  List<CategoriaInter> itens = const [],
}) => CatalogoCategoriasInterUsuario(configurada: configurada, itens: itens);

void main() {
  test('carrega categorias externas selecionadas e resume a seleção', () async {
    final controlador = ControladorCategoriasAcompanhadas(
      carregar: () async => _catalogo(
        itens: [
          _categoria(valor: 'Eletrônicos', selecionada: true),
          _categoria(valor: 'Cabos', selecionada: false),
          _categoria(valor: null, selecionada: true),
        ],
      ),
      salvar: (_, {required semCategoria}) async => _catalogo(),
    );
    addTearDown(controlador.dispose);

    await controlador.carregarAcompanhadas();

    expect(controlador.valoresSelecionados, {'Eletrônicos', null});
    expect(controlador.totalAcompanhadas, 2);
    expect(
      controlador.resumo,
      '2 categorias · aplicadas às lojas selecionadas',
    );
    expect(controlador.erro, isNull);
  });

  test('salva categoria externa e Sem categoria separadamente', () async {
    List<String>? categoriasRecebidas;
    bool? semCategoriaRecebida;
    final controlador = ControladorCategoriasAcompanhadas(
      carregar: () async => _catalogo(),
      salvar: (categorias, {required semCategoria}) async {
        categoriasRecebidas = categorias;
        semCategoriaRecebida = semCategoria;
        return _catalogo(
          itens: [
            _categoria(valor: 'Geladeiras', selecionada: true),
            _categoria(valor: null, selecionada: true),
          ],
        );
      },
    );
    addTearDown(controlador.dispose);

    final salvo = await controlador.salvarSelecao({'Geladeiras', null});

    expect(salvo, isTrue);
    expect(categoriasRecebidas, ['Geladeiras']);
    expect(semCategoriaRecebida, isTrue);
    expect(controlador.valoresSelecionados, {'Geladeiras', null});
  });

  test('falha ao salvar preserva o catálogo confirmado', () async {
    final confirmado = _catalogo(
      itens: [_categoria(valor: 'TVs', selecionada: true)],
    );
    final controlador = ControladorCategoriasAcompanhadas(
      carregar: () async => confirmado,
      salvar: (_, {required semCategoria}) async =>
          throw StateError('sem rede'),
    );
    addTearDown(controlador.dispose);
    await controlador.carregarAcompanhadas();

    final salvo = await controlador.salvarSelecao({'Geladeiras'});

    expect(salvo, isFalse);
    expect(controlador.catalogo, same(confirmado));
    expect(controlador.valoresSelecionados, {'TVs'});
    expect(controlador.erroSalvar, contains('sem rede'));
  });
}
