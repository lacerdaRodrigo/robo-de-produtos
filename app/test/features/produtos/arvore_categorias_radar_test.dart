import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/produtos/arvore_categorias_radar.dart';

CategoriaRadar _categoria({
  required String slug,
  required String nome,
  String? pai,
  int ordem = 0,
}) => CategoriaRadar(
  id: slug,
  slug: slug,
  nome: nome,
  categoriaPaiSlug: pai,
  ordem: ordem,
  selecionada: false,
  acompanhada: false,
);

final _categorias = <CategoriaRadar>[
  _categoria(slug: 'cabos', nome: 'Cabos', pai: 'eletronicos', ordem: 3),
  _categoria(slug: 'eletronicos', nome: 'Eletrônicos', ordem: 1),
  _categoria(
    slug: 'celulares',
    nome: 'Celulares',
    pai: 'eletronicos',
    ordem: 2,
  ),
  _categoria(slug: 'eletro', nome: 'Eletrodomésticos', ordem: 2),
];

void main() {
  test('monta pais e filhos mutáveis respeitando a ordem do contrato', () {
    final arvore = montarArvoreCategoriasRadar(_categorias);

    expect(arvore.map((no) => no.categoria.slug), ['eletronicos', 'eletro']);
    expect(arvore.first.filhos.map((no) => no.categoria.slug), [
      'celulares',
      'cabos',
    ]);
  });

  testWidgets('pai é salvo diretamente e desmarcar filha preserva a irmã', (
    at,
  ) async {
    var diretas = <String>{};
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ArvoreCategoriasRadar(
              categorias: _categorias,
              modo: ModoSeletorCategoriasRadar.acompanhar,
              marcadas: diretas,
              aoMudar: (novaSelecao) => setState(() => diretas = novaSelecao),
            ),
          ),
        ),
      ),
    );

    await at.tap(find.text('Eletrônicos'));
    await at.pump();
    expect(diretas, {'eletronicos'});

    await at.tap(find.text('Cabos'));
    await at.pump();
    expect(diretas, {'celulares'});
  });

  testWidgets('filtro temporário mantém somente uma categoria ativa', (
    at,
  ) async {
    var selecionadas = <String>{};
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.escuro(),
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ArvoreCategoriasRadar(
              categorias: _categorias,
              modo: ModoSeletorCategoriasRadar.filtrar,
              marcadas: selecionadas,
              aoMudar: (novaSelecao) =>
                  setState(() => selecionadas = novaSelecao),
            ),
          ),
        ),
      ),
    );

    await at.tap(find.text('Celulares'));
    await at.pump();
    expect(selecionadas, {'celulares'});

    await at.tap(find.text('Cabos'));
    await at.pump();
    expect(selecionadas, {'cabos'});
  });

  testWidgets('pai recolhe filhos e anuncia seleção parcial', (at) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: ArvoreCategoriasRadar(
            categorias: _categorias,
            modo: ModoSeletorCategoriasRadar.acompanhar,
            marcadas: const {'celulares'},
            aoMudar: (_) {},
          ),
        ),
      ),
    );

    expect(
      at.getSemantics(find.text('Eletrônicos')).label,
      contains('parcialmente selecionada'),
    );
    await at.tap(find.byKey(const ValueKey('expandir-eletronicos')));
    await at.pumpAndSettle();
    expect(find.text('Cabos'), findsNothing);
    await at.tap(find.byKey(const ValueKey('expandir-eletronicos')));
    await at.pumpAndSettle();
    expect(find.text('Cabos'), findsOneWidget);
  });

  testWidgets('nome longo não estoura em 320 px com texto ampliado', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(320, 640);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final categorias = [
      _categoria(
        slug: 'acessorios-para-celulares-e-smartphones',
        nome:
            'Acessórios para câmeras, celulares e smartphones com nomes extensos',
      ),
    ];
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.escuro(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: ArvoreCategoriasRadar(
            categorias: categorias,
            modo: ModoSeletorCategoriasRadar.acompanhar,
            marcadas: const {},
            aoMudar: (_) {},
          ),
        ),
      ),
    );

    expect(at.takeException(), isNull);
  });

  testWidgets('árvore longa rola e reabre no topo', (at) async {
    final categorias = [
      for (var indice = 0; indice < 24; indice++)
        _categoria(
          slug: 'categoria-$indice',
          nome: 'Categoria $indice com nome longo',
          ordem: indice,
        ),
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
                selecionadasIniciais: const {},
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
    final rolagem = find.descendant(
      of: lista,
      matching: find.byType(Scrollable),
    );
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
