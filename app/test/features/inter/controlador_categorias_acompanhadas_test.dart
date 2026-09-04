import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/inter/controlador_categorias_acompanhadas.dart';

CategoriaRadar _categoria({
  required String slug,
  required bool selecionada,
  required bool acompanhada,
}) => CategoriaRadar(
  id: slug,
  slug: slug,
  nome: slug,
  categoriaPaiSlug: null,
  ordem: 0,
  selecionada: selecionada,
  acompanhada: acompanhada,
);

CatalogoCategoriasRadarUsuario _catalogo({
  bool configurada = true,
  List<CategoriaRadar> itens = const [],
}) => CatalogoCategoriasRadarUsuario(configurada: configurada, itens: itens);

void main() {
  test(
    'carrega seleção direta e resume a cobertura devolvida pela API',
    () async {
      final controlador = ControladorCategoriasAcompanhadas(
        carregar: () async => _catalogo(
          itens: [
            _categoria(
              slug: 'eletronicos',
              selecionada: true,
              acompanhada: true,
            ),
            _categoria(slug: 'cabos', selecionada: false, acompanhada: true),
          ],
        ),
        salvar: (_) async => _catalogo(),
      );
      addTearDown(controlador.dispose);

      await controlador.carregarAcompanhadas();

      expect(controlador.slugsSelecionadosDiretos, {'eletronicos'});
      expect(controlador.totalAcompanhadas, 2);
      expect(
        controlador.resumo,
        '2 categorias · aplicadas às lojas selecionadas',
      );
      expect(controlador.erro, isNull);
    },
  );

  test('falha ao salvar preserva o catálogo confirmado', () async {
    final confirmado = _catalogo(
      itens: [_categoria(slug: 'tv', selecionada: true, acompanhada: true)],
    );
    final controlador = ControladorCategoriasAcompanhadas(
      carregar: () async => confirmado,
      salvar: (_) async => throw StateError('sem rede'),
    );
    addTearDown(controlador.dispose);
    await controlador.carregarAcompanhadas();

    final salvo = await controlador.salvarSelecao({'geladeiras'});

    expect(salvo, isFalse);
    expect(controlador.catalogo, same(confirmado));
    expect(controlador.slugsSelecionadosDiretos, {'tv'});
    expect(controlador.erroSalvar, contains('sem rede'));
  });
}
