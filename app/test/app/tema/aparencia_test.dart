import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/app.dart';
import 'package:app_robo/app/navegacao/moldura.dart';
import 'package:app_robo/app/tema/aparencia.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';

const _resumoVazio =
    '{"gerado_em":"2026-08-23T12:00:00Z","estado_geral":"sem_dados",'
    '"livelo":{"estado":"sem_dados"},'
    '"cashback_inter":{"estado":"sem_dados"},'
    '"produtos":{"estado":"sem_dados"}}';

class _PreferenciasMemoria implements PreferenciasAparencia {
  ThemeMode? salvo;
  bool falharAoSalvar = false;

  @override
  Future<ThemeMode?> carregar() async => salvo;

  @override
  Future<void> salvar(ThemeMode modo) async {
    if (falharAoSalvar) throw StateError('falha controlada');
    salvo = modo;
  }
}

class _PreferenciasLentas extends _PreferenciasMemoria {
  final resposta = Completer<ThemeMode?>();

  @override
  Future<ThemeMode?> carregar() => resposta.future;
}

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient(
      (requisicao) async => http.Response(
        requisicao.url.path == '/api/resumo'
            ? _resumoVazio
            : '{"api":"v1","saudavel":true}',
        200,
      ),
    ),
  ),
);

void main() {
  test('primeira execução mantém a aparência do sistema', () async {
    final preferencias = _PreferenciasMemoria();
    final controlador = ControladorAparencia(preferencias: preferencias);
    addTearDown(controlador.dispose);

    await controlador.carregar();

    expect(controlador.modo, ThemeMode.system);
  });

  test('preferência salva é restaurada sem inventar outro estado', () async {
    final preferencias = _PreferenciasMemoria()..salvo = ThemeMode.dark;
    final controlador = ControladorAparencia(preferencias: preferencias);
    addTearDown(controlador.dispose);

    await controlador.carregar();

    expect(controlador.modo, ThemeMode.dark);
  });

  test('alternância é imediata e reaparece em outro controlador', () async {
    final preferencias = _PreferenciasMemoria();
    final primeiro = ControladorAparencia(preferencias: preferencias);
    addTearDown(primeiro.dispose);

    expect(await primeiro.alternar(Brightness.light), isTrue);
    expect(primeiro.modo, ThemeMode.dark);
    expect(preferencias.salvo, ThemeMode.dark);

    final reaberto = ControladorAparencia(preferencias: preferencias);
    addTearDown(reaberto.dispose);
    await reaberto.carregar();
    expect(reaberto.modo, ThemeMode.dark);
  });

  test('falha de persistência não desfaz a escolha da sessão', () async {
    final preferencias = _PreferenciasMemoria()..falharAoSalvar = true;
    final controlador = ControladorAparencia(preferencias: preferencias);
    addTearDown(controlador.dispose);

    expect(await controlador.alternar(Brightness.light), isFalse);
    expect(controlador.modo, ThemeMode.dark);
  });

  test('leitura atrasada não sobrescreve escolha feita na sessão', () async {
    final preferencias = _PreferenciasLentas();
    final controlador = ControladorAparencia(preferencias: preferencias);
    addTearDown(controlador.dispose);

    final carregamento = controlador.carregar();
    await controlador.alternar(Brightness.light);
    preferencias.resposta.complete(ThemeMode.light);
    await carregamento;

    expect(controlador.modo, ThemeMode.dark);
  });

  testWidgets('controle do cabeçalho alterna o mobile claro e escuro', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(390, 844);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final preferencias = _PreferenciasMemoria();
    final controlador = ControladorAparencia(
      preferencias: preferencias,
      modoInicial: ThemeMode.light,
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      RadarApp.semAutenticacaoParaTeste(
        api: _api(),
        controladorAparencia: controlador,
      ),
    );
    await at.pumpAndSettle();

    expect(
      Theme.of(at.element(find.byKey(const Key('resumo-inicio')))).brightness,
      Brightness.light,
    );
    await at.tap(find.byKey(const Key('alternar-tema-cabecalho')));
    await at.pumpAndSettle();

    expect(
      Theme.of(at.element(find.byKey(const Key('resumo-inicio')))).brightness,
      Brightness.dark,
    );
    expect(preferencias.salvo, ThemeMode.dark);

    await at.tap(find.byKey(const Key('abrir-menu-principal')));
    await at.pumpAndSettle();
    final linhaAparencia = find.byKey(const Key('alternar-tema-gaveta'));
    final chaveAparencia = find.descendant(
      of: linhaAparencia,
      matching: find.byType(Switch),
    );
    expect(linhaAparencia, findsOneWidget);
    expect(at.widget<Switch>(chaveAparencia).value, isTrue);
    expect(
      at.getSemantics(linhaAparencia).label,
      contains('Ativar tema claro'),
    );
  });

  testWidgets('layout amplo preserva o tema claro', (at) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(1440, 900);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorAparencia(
      preferencias: _PreferenciasMemoria(),
      modoInicial: ThemeMode.dark,
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      RadarApp.semAutenticacaoParaTeste(
        api: _api(),
        controladorAparencia: controlador,
      ),
    );
    await at.pumpAndSettle();

    expect(find.byType(BarraLateral), findsOneWidget);
    expect(
      Theme.of(at.element(find.byType(BarraLateral))).brightness,
      Brightness.light,
    );
    expect(find.byKey(const Key('alternar-tema-cabecalho')), findsNothing);
  });
}
