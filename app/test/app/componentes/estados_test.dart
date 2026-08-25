import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/componentes/estados.dart';
import 'package:app_robo/app/tema/tema.dart';

void main() {
  Widget envolto(Widget filho) =>
      MaterialApp(theme: TemaRadar.claro(), home: filho);

  testWidgets('Carregando mostra indicador e mensagem', (at) async {
    await at.pumpWidget(envolto(const Carregando(mensagem: 'Buscando…')));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Buscando…'), findsOneWidget);
  });

  testWidgets('EstadoVazio mostra a mensagem', (at) async {
    await at.pumpWidget(envolto(const EstadoVazio(mensagem: 'Nada por aqui')));
    expect(find.text('Nada por aqui'), findsOneWidget);
  });

  testWidgets('EstadoFalha mostra erro e botão de retry', (at) async {
    await at.pumpWidget(
      envolto(const EstadoFalha(mensagem: 'Deu ruim', voltar: null)),
    );
    expect(find.text('Deu ruim'), findsOneWidget);
  });

  testWidgets('EstadoFalha com retry chama a ação', (at) async {
    var cliques = 0;
    await at.pumpWidget(
      envolto(EstadoFalha(mensagem: 'Deu ruim', voltar: () => cliques++)),
    );

    await at.tap(find.text('Tentar novamente'));
    expect(cliques, 1);
  });
}
