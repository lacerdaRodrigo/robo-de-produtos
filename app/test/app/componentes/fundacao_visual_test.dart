import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/componentes/fundacao_visual.dart';
import 'package:app_robo/app/tema/tema.dart';

void main() {
  for (final escuro in <bool>[false, true]) {
    testWidgets(
      'fundação visual funciona no tema ${escuro ? 'escuro' : 'claro'}',
      (at) async {
        final busca = TextEditingController();
        addTearDown(busca.dispose);
        var tocouCartao = false;
        var aba = 0;
        var termo = '';
        var acionouBusca = false;

        await at.pumpWidget(
          MaterialApp(
            theme: TemaRadar.claro(),
            darkTheme: TemaRadar.escuro(),
            themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
            home: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const CabecalhoSecaoRadar(
                    sobrelinha: 'Seu radar',
                    titulo: 'Livelo',
                    descricao: 'Lojas, pontos e alertas em uma área.',
                  ),
                  const SizedBox(height: 12),
                  CartaoRadar(
                    key: const Key('cartao-fundacao'),
                    aoTocar: () => tocouCartao = true,
                    child: const IndicadorEstadoRadar(
                      texto: 'Atualizado',
                      tom: TomRadar.ganho,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CampoBuscaRadar(
                    controlador: busca,
                    dica: 'Buscar loja',
                    aoMudar: (valor) => termo = valor,
                    aoAcionar: () => acionouBusca = true,
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, atualizar) => AbasRadar(
                      rotulos: const ['Catálogo', 'Acompanhadas', 'Alertas'],
                      selecionada: aba,
                      aoSelecionar: (valor) => atualizar(() => aba = valor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FolhaRadar(
                    titulo: 'Conta e sistema',
                    descricao: 'Utilidades fora da navegação principal.',
                    child: Text('Administração'),
                  ),
                ],
              ),
            ),
          ),
        );

        await at.tap(find.byKey(const Key('cartao-fundacao')));
        await at.enterText(find.byType(TextField), 'netshoes');
        await at.tap(find.byTooltip('Pesquisar'));
        await at.tap(find.text('Acompanhadas'));
        await at.pump();

        expect(tocouCartao, isTrue);
        expect(termo, 'netshoes');
        expect(acionouBusca, isTrue);
        expect(aba, 1);
        expect(find.text('Atualizado'), findsOneWidget);
        expect(at.takeException(), isNull);
      },
    );
  }

  testWidgets('folha mobile V11 bloqueia e desfoca o conteúdo ao fundo', (
    at,
  ) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              key: const Key('abrir-folha-teste'),
              onPressed: () => mostrarFolhaRadar<void>(
                context,
                builder: (_) => const FolhaRadar(
                  titulo: 'Filtrar lojas',
                  descricao: 'Escolha uma opção.',
                  child: Text('Conteúdo do filtro'),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await at.tap(find.byKey(const Key('abrir-folha-teste')));
    await at.pumpAndSettle();

    expect(find.byKey(const Key('folha-radar-modal')), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byKey(const Key('voltar-folha-radar')), findsOneWidget);
    expect(find.byKey(const Key('fechar-folha-radar')), findsOneWidget);
  });

  testWidgets('paginação só aparece a partir do décimo primeiro cartão', (
    at,
  ) async {
    var paginaEscolhida = 0;

    Widget pagina(int total) => MaterialApp(
      theme: TemaRadar.claro(),
      home: Scaffold(
        body: PaginacaoRadar(
          pagina: 1,
          totalItens: total,
          porPagina: 10,
          carregando: false,
          aoIrParaPagina: (destino) async => paginaEscolhida = destino,
        ),
      ),
    );

    await at.pumpWidget(pagina(9));
    expect(find.byKey(const Key('paginacao-radar-2')), findsNothing);

    await at.pumpWidget(pagina(10));
    expect(find.byKey(const Key('paginacao-radar-2')), findsNothing);

    await at.pumpWidget(pagina(11));
    expect(find.byKey(const Key('paginacao-radar-2')), findsOneWidget);
    await at.tap(find.byKey(const Key('paginacao-radar-2')));
    expect(paginaEscolhida, 2);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginacaoRadar(
            pagina: 1,
            totalItens: 1000,
            porPagina: 10,
            carregando: false,
            aoIrParaPagina: (_) async {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('paginacao-radar-1')), findsOneWidget);
    expect(find.byKey(const Key('paginacao-radar-2')), findsOneWidget);
    expect(find.byKey(const Key('paginacao-radar-3')), findsOneWidget);
    expect(find.byKey(const Key('paginacao-radar-100')), findsOneWidget);
    expect(find.text('…'), findsOneWidget);
  });
}
