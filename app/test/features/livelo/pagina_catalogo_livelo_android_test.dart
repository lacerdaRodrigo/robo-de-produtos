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

Api _apiDisparo(List<http.Request> requisicoes) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      requisicoes.add(requisicao);
      if (requisicao.method == 'POST') {
        return http.Response(
          '{"dominio":"livelo","estado":"aceito",'
          '"cooldown_segundos":0}',
          202,
        );
      }
      if (requisicao.url.path == '/api/administracao/disparos') {
        return http.Response(
          '{"dominio":"livelo","cooldown_segundos":0,'
          '"ultima_solicitacao_em":null,"ultimo_estado":null}',
          200,
        );
      }
      if (requisicao.url.path == '/api/resumo') {
        return http.Response('{}', 500);
      }
      return http.Response('{}', 404);
    }),
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
  Api? api,
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
            api: api ?? _api(),
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

Future<void> _dispararAtualizacao(WidgetTester at) async {
  await at.ensureVisible(find.text('Atualizar'));
  await at.pump();
  await at.tap(find.text('Atualizar'));
  await at.pump();
  await at.pump(const Duration(milliseconds: 300));
  await at.pump();
}

void main() {
  testWidgets('polling encerra ao receber novo retrato', (at) async {
    var consultas = 0;
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async {
            consultas += 1;
            return dados.montarPagina(
              [dados.parceiro('A')],
              resumoDaPagina: dados.resumo(
                ultimaColeta: consultas == 1
                    ? '2026-08-28T12:00:00Z'
                    : '2026-08-28T12:05:00Z',
              ),
            );
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);
    final requisicoes = <http.Request>[];
    await _abrir(at, controlador, api: _apiDisparo(requisicoes));

    await _dispararAtualizacao(at);

    expect(find.text('Atualização concluída.'), findsOneWidget);
    expect(controlador.resumo?.ultimaColeta, '2026-08-28T12:05:00Z');
    expect(consultas, 2);
    await at.pump(const Duration(minutes: 1));
    expect(consultas, 2);
  });

  testWidgets('polling para após dez minutos sem inventar falha backend', (
    at,
  ) async {
    var consultas = 0;
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async {
            consultas += 1;
            return dados.montarPagina([dados.parceiro('A')]);
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);
    final requisicoes = <http.Request>[];
    await _abrir(at, controlador, api: _apiDisparo(requisicoes));

    await _dispararAtualizacao(at);
    for (var tentativa = 0; tentativa < 20; tentativa++) {
      await at.pump(const Duration(seconds: 30));
      await at.pump();
    }

    expect(
      find.textContaining('A atualização pode continuar em segundo plano.'),
      findsOneWidget,
    );
    expect(consultas, 22);
    expect(
      requisicoes.where((requisicao) => requisicao.method == 'POST').length,
      1,
    );
    expect(
      requisicoes.where(
        (requisicao) =>
            requisicao.method == 'PATCH' || requisicao.method == 'DELETE',
      ),
      isEmpty,
    );
    await at.pump(const Duration(minutes: 1));
    expect(consultas, 22);
  });

  testWidgets('três erros consecutivos encerram o polling', (at) async {
    var consultas = 0;
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async {
            consultas += 1;
            if (consultas > 1) throw StateError('sem rede');
            return dados.montarPagina([dados.parceiro('A')]);
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);
    await _abrir(at, controlador, api: _apiDisparo(<http.Request>[]));

    await _dispararAtualizacao(at);
    await at.pump(const Duration(seconds: 30));
    await at.pump();
    await at.pump();
    await at.pump(const Duration(seconds: 30));
    await at.pump();
    await at.pump();
    await at.pump(const Duration(milliseconds: 300));

    expect(consultas, 4);
    expect(
      find.textContaining('pode continuar em segundo plano'),
      findsOneWidget,
    );
    await at.pump(const Duration(minutes: 1));
    expect(consultas, 4);
  });

  testWidgets('dispose cancela polling e novo disparo substitui o anterior', (
    at,
  ) async {
    var consultas = 0;
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async {
            consultas += 1;
            return dados.montarPagina([dados.parceiro('A')]);
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);
    await _abrir(at, controlador, api: _apiDisparo(<http.Request>[]));

    await _dispararAtualizacao(at);
    await _dispararAtualizacao(at);
    expect(consultas, 3);

    await at.pump(const Duration(seconds: 30));
    await at.pump();
    expect(consultas, 4, reason: 'somente o polling mais recente permanece');

    await at.pumpWidget(const SizedBox.shrink());
    await at.pump(const Duration(minutes: 1));
    expect(consultas, 4);
  });

  testWidgets('hero, abas essenciais, busca e cartões usam dados reais', (
    at,
  ) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);

    expect(find.textContaining('12 pontos por R\$ 1'), findsOneWidget);
    expect(find.text('Melhor Loja'), findsOneWidget);
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Acompanhando'), findsWidgets);
    expect(find.text('Alertas'), findsNothing);
    expect(find.text('Monitoramento da coleta'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Marketplace'), findsNothing);
    expect(
      find.widgetWithText(TextField, 'Buscar loja ou categoria'),
      findsOneWidget,
    );
    await at.drag(
      find.byKey(const Key('catalogo-livelo-android')),
      const Offset(0, -700),
    );
    await at.pumpAndSettle();
    expect(find.text('Loja Clube'), findsOneWidget);
    expect(find.text('Acompanhando'), findsWidgets);
    expect(find.text('Alerta ativo'), findsOneWidget);
  });

  testWidgets('RN29 mostra qualidade reduzida sem expor código técnico', (
    at,
  ) async {
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
          }) async => dados.montarPagina(
            [dados.parceiro('A')],
            resumoDaPagina: dados.resumo(
              ultimaColeta: '2026-08-28T12:00:00Z',
              ultimaTentativaEm: '2026-08-28T12:05:00Z',
              qualidade: 'degradada',
            ),
          ),
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);

    expect(find.text('Dados com qualidade reduzida'), findsOneWidget);
    expect(
      find.textContaining('Exibindo a última coleta válida.'),
      findsOneWidget,
    );
    expect(find.textContaining('RN29'), findsNothing);
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

  testWidgets(
    'qualquer loja do catálogo abre seu histórico, mesmo sem acompanhamento',
    (at) async {
      final controlador = _controlador();
      addTearDown(controlador.dispose);
      final requisicoes = <http.Request>[];
      final api = Api(
        paginaPadrao: 20,
        cliente: ClienteApi(
          baseUrl: 'http://localhost:3000',
          provedorToken: () async => 'token-teste',
          cliente: http_testing.MockClient((requisicao) async {
            requisicoes.add(requisicao);
            return http.Response(
              r'{"id_externo":"B","medicoes":[{"momento":"2026-08-29T17:00:00Z","pontos_atuais":"5","pontos_base":"1","pontos_clube":null,"moeda":"R$"}]}',
              200,
            );
          }),
        ),
      );
      await at.pumpWidget(
        MaterialApp(
          theme: TemaRadar.claro(),
          home: Scaffold(
            body: PaginaCatalogoLiveloAndroid(
              api: api,
              administrador: true,
              controlador: controlador,
            ),
          ),
        ),
      );
      await at.pumpAndSettle();
      await at.drag(
        find.byKey(const Key('catalogo-livelo-android')),
        const Offset(0, -700),
      );
      await at.pumpAndSettle();

      await at.tap(find.byKey(const Key('historico-B')));
      await at.pumpAndSettle();

      expect(find.text('Loja Comum'), findsOneWidget);
      expect(find.text('5 pontos por R\$ 1'), findsOneWidget);
      expect(
        requisicoes.map((requisicao) => requisicao.url.path),
        contains('/api/livelo/catalogo/B/historico'),
      );
    },
  );

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
  }, tags: 'golden');

  testWidgets('golden Android escuro', (at) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador, brilho: Brightness.dark);
    await expectLater(
      find.byKey(const Key('catalogo-livelo-android')),
      matchesGoldenFile('../../goldens/catalogo_livelo_android_escuro.png'),
    );
  }, tags: 'golden');
}
