import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/design_system/design_system.dart';

class _FonteFake implements FonteHistorico {
  final paginasPedidas = <int>[];

  @override
  Future<PaginaHistorico> carregar(int pagina) async {
    paginasPedidas.add(pagina);
    return PaginaHistorico(
      pagina: pagina,
      totalPaginas: 2,
      resumo: const [MetricaHistorico('Menor em 30 dias', r'R$ 10,00')],
      linhas: [
        LinhaHistorico(momento: 'Hoje, 1$pagina:00', valorPrincipal: r'R$ 10,00'),
      ],
    );
  }
}

Widget _app(Widget filho, RegistroFiltros registro) => EscopoDs(
  filtros: registro,
  child: MaterialApp(
    theme: DsTema.claro(),
    home: Scaffold(body: Center(child: filho)),
  ),
);

void main() {
  testWidgets('FolhaHistorico pagina pela fonte do domínio', (t) async {
    final fonte = _FonteFake();
    final registro = RegistroFiltros(const {});
    addTearDown(registro.dispose);
    await t.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => FolhaHistorico.mostrar(
              context,
              subtitulo: 'Item · Origem',
              fonte: fonte,
            ),
            child: const Text('abrir'),
          ),
        ),
        registro,
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();

    expect(find.text('Histórico de preço'), findsOneWidget);
    expect(find.text('Hoje, 11:00'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);

    await t.tap(find.byTooltip('Próxima página'));
    await t.pumpAndSettle();
    expect(find.text('Hoje, 12:00'), findsOneWidget);
    expect(fonte.paginasPedidas, [1, 2]);
  });

  testWidgets('FolhaFiltros aplica no estado global do escopo', (t) async {
    final registro = RegistroFiltros(const {
      EscopoFiltro.pichau: EspecFiltros(
        origem: 'Pichau',
        secoes: [
          SecaoEscolha(
            id: 'disp',
            titulo: 'Disponibilidade',
            opcoes: [
              OpcaoFiltro('todas', 'Todos'),
              OpcaoFiltro('esgotados', 'Esgotados'),
            ],
          ),
        ],
      ),
    });
    addTearDown(registro.dispose);
    await t.pumpWidget(
      _app(
        DsCampoBusca(aoBuscar: (_) {}, escopoFiltros: EscopoFiltro.pichau),
        registro,
      ),
    );

    await t.tap(find.byTooltip('Filtros'));
    await t.pumpAndSettle();
    await t.tap(find.text('Esgotados'));
    await t.pump();
    expect(find.text('Pichau · 1 ativo'), findsOneWidget);

    await t.tap(find.text('Aplicar filtros'));
    await t.pumpAndSettle();
    expect(registro.de(EscopoFiltro.pichau).value.texto('disp'), 'esgotados');
    expect(find.byTooltip('Filtros, 1 ativo'), findsOneWidget);
  });
}
