import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/produtos/seletor_categorias_inter.dart';

CategoriaInter _categoria(String? valor, {bool selecionada = false}) =>
    CategoriaInter(
      valor: valor,
      nome: valor ?? 'Sem categoria',
      selecionada: selecionada,
    );

final _categorias = <CategoriaInter>[
  _categoria('Celulares'),
  _categoria('Cabos e Adaptadores'),
  _categoria(null),
];

void main() {
  testWidgets('acompanhamento permite múltiplos valores externos e Sem categoria', (
    at,
  ) async {
    Future<Set<String?>?>? resultado;
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                resultado = mostrarSeletorCategoriasAcompanhadas(
                  context,
                  categorias: _categorias,
                  selecionadasIniciais: const <String?>{},
                );
              },
              child: const Text('Abrir categorias'),
            ),
          ),
        ),
      ),
    );

    await at.tap(find.text('Abrir categorias'));
    await at.pumpAndSettle();
    await at.tap(find.text('Celulares'));
    await at.tap(find.text('Sem categoria'));
    await at.pump();
    await at.tap(find.text('Salvar categorias'));
    await at.pumpAndSettle();

    expect(await resultado, {'Celulares', null});
  });

  testWidgets('filtro temporário mantém somente uma categoria externa', (
    at,
  ) async {
    Future<SelecaoCategoriaTemporaria?>? resultado;
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.escuro(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                resultado = mostrarSelecaoCategoriaTemporaria(
                  context,
                  categorias: _categorias,
                  categoriaAtual: null,
                  semCategoriaAtual: false,
                );
              },
              child: const Text('Filtrar'),
            ),
          ),
        ),
      ),
    );

    await at.tap(find.text('Filtrar'));
    await at.pumpAndSettle();
    await at.tap(find.text('Celulares'));
    await at.tap(find.text('Cabos e Adaptadores'));
    await at.pump();
    await at.tap(find.text('Ver ofertas'));
    await at.pumpAndSettle();

    final selecao = await resultado;
    expect(selecao?.categoria, 'Cabos e Adaptadores');
    expect(selecao?.semCategoria, isFalse);
  });

  testWidgets('filtro Sem categoria não inventa valor externo', (at) async {
    Future<SelecaoCategoriaTemporaria?>? resultado;
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                resultado = mostrarSelecaoCategoriaTemporaria(
                  context,
                  categorias: _categorias,
                  categoriaAtual: null,
                  semCategoriaAtual: false,
                );
              },
              child: const Text('Filtrar'),
            ),
          ),
        ),
      ),
    );

    await at.tap(find.text('Filtrar'));
    await at.pumpAndSettle();
    await at.tap(find.text('Sem categoria'));
    await at.tap(find.text('Ver ofertas'));
    await at.pumpAndSettle();

    final selecao = await resultado;
    expect(selecao?.categoria, isNull);
    expect(selecao?.semCategoria, isTrue);
  });

  testWidgets('lista longa rola e reabre no topo', (at) async {
    final categorias = [
      for (var indice = 0; indice < 24; indice++)
        _categoria('Categoria $indice com nome longo'),
    ];
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => mostrarSeletorCategoriasAcompanhadas(
                context,
                categorias: categorias,
                selecionadasIniciais: const <String?>{},
              ),
              child: const Text('Abrir categorias'),
            ),
          ),
        ),
      ),
    );

    await at.tap(find.text('Abrir categorias'));
    await at.pumpAndSettle();
    final lista = find.byKey(const Key('seletor-categorias-lista'));
    final rolagem = find.descendant(of: lista, matching: find.byType(Scrollable));
    await at.scrollUntilVisible(
      find.text('Categoria 23 com nome longo'),
      180,
      scrollable: rolagem,
    );
    expect(find.text('Salvar categorias'), findsOneWidget);
    await at.tap(find.text('Cancelar'));
    await at.pumpAndSettle();

    await at.tap(find.text('Abrir categorias'));
    await at.pumpAndSettle();
    final estadoRolagem = at.state<ScrollableState>(rolagem);
    expect(estadoRolagem.position.pixels, 0);
  });
}
