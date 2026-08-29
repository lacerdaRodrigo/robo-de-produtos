import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/livelo/controlador_catalogo_livelo.dart';
import 'package:app_robo/features/livelo/pagina_catalogo_livelo_android.dart';

import 'controlador_catalogo_livelo_test.dart' as dados;

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    cliente: http_testing.MockClient((_) async => http.Response('{}', 500)),
  ),
);

ControladorCatalogoLivelo _controlador({
  Future<void> Function({required String idExterno, required bool acompanhada})?
  alterar,
}) => ControladorCatalogoLivelo(
  buscar:
      ({
        required q,
        required aba,
        required categoria,
        required ordenar,
        required pagina,
      }) async => dados.montarPagina(
        [
          dados.parceiro(
            'A',
            nome: 'Loja Clube',
            acompanhada: true,
            alerta: true,
          ),
          dados.parceiro('B', nome: 'Loja Comum'),
        ],
        total: 2,
        resumoDaPagina: dados.resumo(acompanhadas: 1, alertas: 1),
      ),
  alterarAcompanhamento:
      alterar ?? ({required idExterno, required acompanhada}) async {},
);

Future<void> _abrir(
  WidgetTester at,
  ControladorCatalogoLivelo controlador, {
  Brightness brilho = Brightness.light,
  Size tamanho = const Size(390, 844),
  double escala = 1,
}) async {
  at.view.devicePixelRatio = 1;
  at.view.physicalSize = tamanho;
  addTearDown(at.view.resetDevicePixelRatio);
  addTearDown(at.view.resetPhysicalSize);
  await at.pumpWidget(
    MaterialApp(
      theme: brilho == Brightness.dark ? TemaRadar.escuro() : TemaRadar.claro(),
      home: MediaQuery(
        data: MediaQueryData(
          size: tamanho,
          textScaler: TextScaler.linear(escala),
        ),
        child: Scaffold(
          body: PaginaCatalogoLiveloAndroid(
            api: _api(),
            administrador: true,
            controlador: controlador,
            agora: () => DateTime.utc(2026, 8, 28, 15),
          ),
        ),
      ),
    ),
  );
  await at.pumpAndSettle();
}

void main() {
  testWidgets('hero, abas, busca, categorias e cartões usam dados reais', (
    at,
  ) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);

    expect(find.textContaining('12 pontos por R\$ 1'), findsOneWidget);
    expect(find.text('Melhor Loja'), findsOneWidget);
    expect(find.text('Lojas'), findsOneWidget);
    expect(find.text('Acompanhadas'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Buscar loja ou categoria'),
      findsOneWidget,
    );
    await at.drag(
      find.byKey(const Key('catalogo-livelo-android')),
      const Offset(0, -700),
    );
    await at.pumpAndSettle();
    expect(find.text('Marketplace'), findsWidgets);
    expect(find.text('Loja Clube'), findsOneWidget);
    expect(find.text('Acompanhando'), findsOneWidget);
    expect(find.text('Alerta ativo'), findsOneWidget);
  });

  testWidgets('mutação mostra pendência, bloqueia repetição e informa falha', (
    at,
  ) async {
    final pendente = Completer<void>();
    final controlador = _controlador(
      alterar: ({required idExterno, required acompanhada}) => pendente.future,
    );
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);

    await at.drag(
      find.byKey(const Key('catalogo-livelo-android')),
      const Offset(0, -900),
    );
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('acompanhar-B')));
    await at.pump();
    expect(find.text('Salvando…'), findsOneWidget);

    pendente.completeError(StateError('falhou'));
    await at.pumpAndSettle();
    expect(
      find.textContaining('estado anterior foi restaurado'),
      findsOneWidget,
    );
    expect(controlador.itens.last.acompanhada, isFalse);
  });

  testWidgets(
    'parar de acompanhar envia false e devolve o cartão ao estado disponível',
    (at) async {
      final chamadas = <bool>[];
      final controlador = _controlador(
        alterar: ({required idExterno, required acompanhada}) async {
          chamadas.add(acompanhada);
        },
      );
      addTearDown(controlador.dispose);
      await _abrir(at, controlador);

      await at.drag(
        find.byKey(const Key('catalogo-livelo-android')),
        const Offset(0, -700),
      );
      await at.pumpAndSettle();
      await at.tap(find.byKey(const Key('acompanhar-A')));
      await at.pumpAndSettle();

      expect(chamadas, [false]);
      expect(controlador.itens.first.acompanhada, isFalse);
      expect(
        find.descendant(
          of: find.byKey(const Key('acompanhar-A')),
          matching: find.text('Acompanhar'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('sino ativa e desativa alerta somente para acompanhada', (
    at,
  ) async {
    final chamadas = <bool>[];
    final controlador = _controlador();
    final comAlerta = ControladorCatalogoLivelo(
      buscar: controlador.buscar,
      alterarAcompanhamento: controlador.alterarAcompanhamento,
      alterarAlerta: ({required idExterno, required ativo}) async {
        chamadas.add(ativo);
      },
    );
    addTearDown(controlador.dispose);
    addTearDown(comAlerta.dispose);
    await _abrir(at, comAlerta);
    await at.drag(
      find.byKey(const Key('catalogo-livelo-android')),
      const Offset(0, -700),
    );
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('alerta-A')));
    await at.pumpAndSettle();
    expect(chamadas, [true]);
    expect(comAlerta.itens.first.alertaAtivo, isTrue);
    await at.tap(find.byKey(const Key('alerta-A')));
    await at.pumpAndSettle();
    expect(chamadas, [true, false]);
    expect(comAlerta.itens.first.alertaAtivo, isFalse);
  });

  testWidgets('320 px e texto a 150% continuam roláveis sem overflow', (
    at,
  ) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador, tamanho: const Size(320, 640), escala: 1.5);

    expect(at.takeException(), isNull);
    expect(find.byKey(const Key('catalogo-livelo-android')), findsOneWidget);
    await at.drag(
      find.byKey(const Key('catalogo-livelo-android')),
      const Offset(0, -300),
    );
    await at.pump();
    expect(at.takeException(), isNull);
  });

  testWidgets('golden Android claro', (at) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);
    await expectLater(
      find.byKey(const Key('catalogo-livelo-android')),
      matchesGoldenFile('../../goldens/catalogo_livelo_android_claro.png'),
    );
  });

  testWidgets('golden Android escuro', (at) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador, brilho: Brightness.dark);
    await expectLater(
      find.byKey(const Key('catalogo-livelo-android')),
      matchesGoldenFile('../../goldens/catalogo_livelo_android_escuro.png'),
    );
  });
}
