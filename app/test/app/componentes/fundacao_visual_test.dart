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
        await at.tap(find.text('Acompanhadas'));
        await at.pump();

        expect(tocouCartao, isTrue);
        expect(termo, 'netshoes');
        expect(aba, 1);
        expect(find.text('Atualizado'), findsOneWidget);
        expect(at.takeException(), isNull);
      },
    );
  }
}
