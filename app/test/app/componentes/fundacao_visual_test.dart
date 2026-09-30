import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/componentes/fundacao_visual.dart';
import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';

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
                    titulo: 'Conta e aparência',
                    descricao: 'Utilidades que funcionam no aplicativo.',
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
        expect(
          at.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
          isFalse,
        );
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

  testWidgets('busca segue raio, sombra e seta simples da V15', (tester) async {
    final busca = TextEditingController();
    addTearDown(busca.dispose);
    String? termoEnviado;
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: CampoBuscaRadar(
            chaveCampo: const Key('busca-v15'),
            controlador: busca,
            dica: 'Qual loja você procura?',
            aoMudar: (_) {},
            aoAcionar: () => termoEnviado = busca.text,
          ),
        ),
      ),
    );

    final campo = tester.widget<TextField>(find.byKey(const Key('busca-v15')));
    expect(
      (campo.decoration!.border! as OutlineInputBorder).borderRadius,
      BorderRadius.circular(TemaRadar.claro().extension<AppTokens>()!.radii.md),
    );
    final componente = tester.widget<CampoBuscaRadar>(
      find.byType(CampoBuscaRadar),
    );
    expect(componente.comSombra, isFalse);
    final iconeBusca = find.byIcon(Icons.arrow_forward_rounded);
    final acao = tester.widget<IconButton>(
      find.ancestor(of: iconeBusca, matching: find.byType(IconButton)).first,
    );
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byTooltip('Pesquisar'),
              matching: find.byType(Icon),
            ),
          )
          .icon,
      Icons.arrow_forward_rounded,
    );
    expect(acao.style?.backgroundColor?.resolve({}), isNull);

    await tester.enterText(find.byKey(const Key('busca-v15')), 'Natura');
    await tester.tap(find.byTooltip('Pesquisar'));
    await tester.pump();
    expect(termoEnviado, 'Natura');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
  });

  testWidgets('cartão V15 pode usar superfície sem sombra', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: CartaoRadar(
            key: const Key('cartao-sem-sombra'),
            comSombra: false,
            child: const Text('Origem'),
          ),
        ),
      ),
    );

    final cartao = tester.widget<CartaoRadar>(
      find.byKey(const Key('cartao-sem-sombra')),
    );
    expect(cartao.comSombra, isFalse);
    final superficie = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const Key('cartao-sem-sombra')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((superficie.decoration as BoxDecoration).boxShadow, isEmpty);
  });

  testWidgets('barra inferior usa métricas V15 e aciona os quatro destinos', (
    tester,
  ) async {
    DestinoCompacto? destinoAcionado;
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: BarraInferiorRadar(
            selecionado: DestinoCompacto.explorar,
            aoSelecionar: (destino) => destinoAcionado = destino,
          ),
        ),
      ),
    );

    final barra = tester.widget<NavigationBar>(
      find.byKey(const Key('barra-inferior-v15')),
    );
    expect(barra.selectedIndex, 1);
    expect(barra.height, 71);
    for (final widget in barra.destinations) {
      final destino = widget as NavigationDestination;
      final icone = destino.icon as Icon;
      final iconeSelecionado = destino.selectedIcon! as Icon;
      expect(iconeSelecionado.icon, icone.icon);
    }
    expect(
      tester
          .widget<Icon>(
            find
                .descendant(
                  of: find.byKey(const Key('barra-inicio')),
                  matching: find.byType(Icon),
                )
                .first,
          )
          .size,
      22,
    );

    for (final destino in const [
      DestinoCompacto.inicio,
      DestinoCompacto.explorar,
      DestinoCompacto.radar,
      DestinoCompacto.perfil,
    ]) {
      await tester.tap(find.byKey(Key('barra-${destino.name}')));
      await tester.pumpAndSettle();
      expect(destinoAcionado, destino);
    }
  });

  testWidgets('barra compacta se adapta a 320 px com texto a 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    DestinoCompacto? destinoAcionado;
    await tester.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: BarraInferiorRadar(
            selecionado: DestinoCompacto.radar,
            aoSelecionar: (destino) => destinoAcionado = destino,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('barra-inferior-v15-compacta')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    for (final destino in const [
      DestinoCompacto.inicio,
      DestinoCompacto.explorar,
      DestinoCompacto.radar,
      DestinoCompacto.perfil,
    ]) {
      final destinoFinder = find.byKey(Key('barra-${destino.name}'));
      expect(tester.getSize(destinoFinder).height, greaterThanOrEqualTo(54));
      expect(
        find.descendant(of: destinoFinder, matching: find.text(destino.titulo)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: destinoFinder, matching: find.byType(Icon)),
            )
            .icon,
        destino.icone,
      );
    }

    await tester.tap(find.byKey(const Key('barra-perfil')));
    expect(destinoAcionado, DestinoCompacto.perfil);
    expect(tester.takeException(), isNull);
  });

  testWidgets('folha mobile V15 bloqueia e desfoca o conteúdo ao fundo', (
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
