import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/componentes/fundacao_visual.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';
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
  String? linkB,
}) => ControladorCatalogoLivelo(
  buscar:
      ({
        required q,
        required aba,
        required categoria,
        required ordenar,
        required pagina,
        required somentePontuacaoComumAmpliada,
      }) async => dados.montarPagina(
        [
          dados.parceiro(
            'A',
            nome: 'Loja Clube',
            acompanhada: true,
            alerta: true,
          ),
          dados.parceiro('B', nome: 'Loja Comum', link: linkB),
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
          ),
        ),
      ),
    ),
  );
  await at.pumpAndSettle();
}

Future<void> _dispararAtualizacao(WidgetTester at) async {
  final atualizar = find.byTooltip('Atualizar catálogo');
  await at.ensureVisible(atualizar);
  await at.pump();
  await at.tap(atualizar);
  await at.pump();
  await at.pump(const Duration(milliseconds: 300));
  await at.pump();
}

void _expectSuperficieOfertaV15(
  WidgetTester at,
  Finder cartao,
  EdgeInsetsGeometry padding,
) {
  const tokens = AppTokens.claro();
  final cartaoWidget = at.widget<CartaoRadar>(cartao);
  expect(cartaoWidget.padding, padding);
  expect(cartaoWidget.comSombra, isFalse);
  expect(cartaoWidget.corDestaque, isNull);

  final superficies = find.descendant(
    of: cartao,
    matching: find.byType(Material),
  );
  final superficie = at.widget<Material>(superficies.first);
  expect(superficie.color, tokens.colors.superficie);
  final forma = superficie.shape! as RoundedRectangleBorder;
  expect(forma.borderRadius, BorderRadius.circular(tokens.radii.lg));
  expect(forma.side.color, tokens.colors.borda);
  expect(forma.side.width, 1);
}

void main() {
  testWidgets('busca Livelo só consulta depois de enviar o termo', (at) async {
    final consultas = <String>[];
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
            required somentePontuacaoComumAmpliada,
          }) async {
            consultas.add(q);
            return dados.montarPagina([]);
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);
    expect(consultas, ['']);

    await at.enterText(
      find.byKey(const Key('busca-catalogo-livelo')),
      'natura',
    );
    await at.pumpAndSettle();
    expect(consultas, ['']);

    await at.tap(find.byTooltip('Pesquisar'));
    await at.pumpAndSettle();
    expect(consultas, ['', 'natura']);
  });

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
            required somentePontuacaoComumAmpliada,
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
            required somentePontuacaoComumAmpliada,
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
            required somentePontuacaoComumAmpliada,
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
            required somentePontuacaoComumAmpliada,
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

  testWidgets('catálogo abre sem resumo e preserva cartões ricos', (at) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador, api: _apiDisparo(<http.Request>[]));

    expect(find.text('Última coleta concluída'), findsNothing);
    expect(find.textContaining('melhor acompanhada agora'), findsNothing);
    expect(find.textContaining('Coleta:'), findsNothing);
    expect(find.text('Livelo'), findsOneWidget);
    expect(find.text('Catálogo'), findsOneWidget);
    expect(find.byKey(const Key('voltar-programas-livelo')), findsOneWidget);
    expect(find.text('Lojas'), findsOneWidget);
    expect(find.text('No radar'), findsOneWidget);
    expect(find.text('Lojas parceiras e pontos por real gasto.'), findsNothing);
    expect(
      at.getSize(find.byKey(const Key('aba-radar-0'))).width,
      at.getSize(find.byKey(const Key('aba-radar-1'))).width,
    );
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.byTooltip('Atualizar catálogo'), findsOneWidget);
    expect(find.byTooltip('Pesquisar'), findsOneWidget);
    expect(find.text('Alertas'), findsNothing);
    expect(find.text('Monitoramento da coleta'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Lojas'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'Marketplace'), findsNothing);
    expect(
      find.widgetWithText(TextField, 'Qual loja você procura?'),
      findsOneWidget,
    );
    final busca = at.getTopLeft(
      find.widgetWithText(TextField, 'Qual loja você procura?'),
    );
    final abas = at.getTopLeft(find.text('Lojas'));
    expect(busca.dy, lessThan(abas.dy));
    await at.drag(
      find.byKey(const Key('catalogo-livelo-android')),
      const Offset(0, -700),
    );
    await at.pumpAndSettle();
    expect(find.text('Loja Clube'), findsOneWidget);
    expect(find.text('Acompanhando'), findsWidgets);
    expect(find.text('Pontuação ampliada'), findsNWidgets(2));
    expect(find.text('Base 1 pts'), findsNWidgets(2));
    expect(find.text('Histórico'), findsNWidgets(2));
    expect(find.text('Ir à Livelo'), findsNWidgets(2));
    expect(
      at.getTopLeft(find.byKey(const Key('acompanhar-A'))).dx,
      lessThan(at.getTopLeft(find.byKey(const Key('detalhes-A'))).dx),
    );
  });

  testWidgets('filtros aplicam juntos e ficam ocultos nas acompanhadas', (
    at,
  ) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);

    await at.tap(find.byKey(const Key('filtrar-ordenar-livelo')));
    await at.pumpAndSettle();
    expect(find.text('Filtros · Livelo'), findsOneWidget);
    expect(find.byKey(const Key('voltar-folha-radar')), findsNothing);
    expect(find.byKey(const Key('fechar-folha-radar')), findsOneWidget);
    expect(find.text('Limpar'), findsOneWidget);
    expect(find.text('Aplicar filtros'), findsOneWidget);

    await at.tap(find.byKey(const Key('categoria-filtro-livelo')));
    await at.pumpAndSettle();
    await at.tap(find.text('Marketplace').last);
    await at.pumpAndSettle();
    await at.tap(find.text('Aplicar filtros'));
    await at.pumpAndSettle();

    expect(controlador.categoria, 'Marketplace');
    expect(controlador.ordenacao, OrdenacaoCatalogoLivelo.nome);
    final botaoFiltro = at.widget<OutlinedButton>(
      find.byKey(const Key('filtrar-ordenar-livelo')),
    );
    expect(botaoFiltro.style?.backgroundColor?.resolve({}), Tokens.actionSoft);

    await at.tap(find.byKey(const Key('aba-radar-1')));
    await at.pumpAndSettle();
    expect(find.text('Suas lojas favoritas'), findsOneWidget);
    expect(find.byKey(const Key('filtrar-ordenar-livelo')), findsNothing);
  });

  testWidgets('filtros expõem pontuação comum e fim da campanha', (at) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);

    await at.tap(find.byKey(const Key('filtrar-ordenar-livelo')));
    await at.pumpAndSettle();
    final pontuacao = find.byKey(const Key('filtro-pontuacao-ampliada-livelo'));
    expect(find.text('Somente pontuação comum ampliada'), findsOneWidget);
    await at.tap(find.byKey(const Key('ordenacao-filtro-livelo')));
    await at.pumpAndSettle();
    expect(find.text('Fim da campanha'), findsOneWidget);
    await at.tap(find.text('Fim da campanha'));
    await at.pumpAndSettle();
    await at.tap(pontuacao);
    await at.pumpAndSettle();
    await at.tap(find.text('Aplicar filtros'));
    await at.pumpAndSettle();

    expect(controlador.somentePontuacaoComumAmpliada, isTrue);
    expect(controlador.ordenacao, OrdenacaoCatalogoLivelo.validade);
    expect(at.takeException(), isNull);
  });

  testWidgets('Limpar Livelo aplica os padrões e mantém a folha aberta', (
    at,
  ) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);
    await at.tap(find.byKey(const Key('filtrar-ordenar-livelo')));
    await at.pumpAndSettle();

    await at.tap(find.byKey(const Key('categoria-filtro-livelo')));
    await at.pumpAndSettle();
    await at.tap(find.text('Marketplace').last);
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('ordenacao-filtro-livelo')));
    await at.pumpAndSettle();
    await at.tap(find.text('Fim da campanha'));
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('filtro-pontuacao-ampliada-livelo')));
    await at.pumpAndSettle();

    await at.tap(find.text('Limpar'));
    await at.pumpAndSettle();

    expect(find.text('Filtros · Livelo'), findsOneWidget);
    expect(controlador.categoria, isEmpty);
    expect(controlador.ordenacao, OrdenacaoCatalogoLivelo.nome);
    expect(controlador.somentePontuacaoComumAmpliada, isFalse);
    expect(find.text('Todas as categorias'), findsOneWidget);
    expect(at.takeException(), isNull);
  });

  testWidgets('qualidade reduzida não recria o card de resumo', (at) async {
    final controlador = ControladorCatalogoLivelo(
      buscar:
          ({
            required q,
            required aba,
            required categoria,
            required ordenar,
            required pagina,
            required somentePontuacaoComumAmpliada,
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

    expect(find.text('Dados com qualidade reduzida'), findsNothing);
    expect(
      find.textContaining('Exibindo a última coleta válida.'),
      findsNothing,
    );
    expect(
      find.widgetWithText(TextField, 'Qual loja você procura?'),
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

  testWidgets('cartão Livelo segue a hierarquia do protótipo', (at) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador);
    await at.drag(
      find.byKey(const Key('catalogo-livelo-android')),
      const Offset(0, -700),
    );
    await at.pumpAndSettle();

    final cartao = find.byKey(const Key('cartao-livelo-A'));
    _expectSuperficieOfertaV15(at, cartao, const EdgeInsetsDirectional.all(20));
    expect(find.byKey(const Key('alerta-A')), findsNothing);
    expect(
      find.descendant(of: cartao, matching: find.text('Marketplace')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cartao, matching: find.text('2,9')),
      findsOneWidget,
    );
    final beneficio = find.descendant(of: cartao, matching: find.text('2,9'));
    expect(at.widget<Text>(beneficio).style?.fontWeight, FontWeight.w800);
    expect(at.widget<Text>(beneficio).style?.letterSpacing, -1);
    expect(at.widget<Text>(beneficio).style?.height, 1.2);
    expect(at.widget<Text>(beneficio).style?.fontSize, 30);
    expect(
      find.descendant(of: cartao, matching: find.text('pontos / R\$ 1')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cartao, matching: find.text('Base 1 pts')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cartao, matching: find.text('Pontuação ampliada')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cartao, matching: find.text('Condições')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cartao, matching: find.text('Histórico')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cartao, matching: find.text('Ir à Livelo')),
      findsOneWidget,
    );
    final historico = find.descendant(
      of: cartao,
      matching: find.text('Histórico'),
    );
    final irALivelo = find.descendant(
      of: cartao,
      matching: find.text('Ir à Livelo'),
    );
    expect(
      at.getRect(historico).center.dy,
      closeTo(at.getRect(irALivelo).center.dy, 1),
    );
  });

  testWidgets(
    'condições abrem confirmação da Livelo e o histórico continua separado',
    (at) async {
      final controlador = _controlador(linkB: 'https://www.livelo.com.br');
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
              r'{"id_externo":"B","medicoes":[{"momento":"2026-08-29T17:00:00Z","pontos_atuais":"5","pontos_base":"1","pontos_clube":"10","moeda":"R$"},{"momento":"2026-08-28T17:00:00Z","pontos_atuais":"5","pontos_base":"1","pontos_clube":"10","moeda":"R$"},{"momento":"2026-08-27T17:00:00Z","pontos_atuais":"5","pontos_base":"1","pontos_clube":"10","moeda":"R$"},{"momento":"2026-08-26T17:00:00Z","pontos_atuais":"5","pontos_base":"1","pontos_clube":"10","moeda":"R$"},{"momento":"2026-08-25T17:00:00Z","pontos_atuais":"5","pontos_base":"1","pontos_clube":"10","moeda":"R$"},{"momento":"2026-08-24T17:00:00Z","pontos_atuais":"4","pontos_base":"1","pontos_clube":"10","moeda":"R$"}]}',
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

      await at.tap(find.byKey(const Key('detalhes-B')));
      await at.pumpAndSettle();

      expect(find.text('Loja Comum'), findsWidgets);
      expect(find.text('Condições da oferta'), findsNWidgets(2));
      expect(find.text('Pontuação comum'), findsOneWidget);
      expect(find.text('Campanha'), findsOneWidget);
      final abrirLivelo = find.byKey(const Key('abrir-livelo-B'));
      expect(abrirLivelo, findsOneWidget);
      expect(at.widget<FilledButton>(abrirLivelo).onPressed, isNotNull);
      expect(find.text('Ver histórico'), findsNothing);
      expect(
        requisicoes.where(
          (requisicao) => requisicao.url.path.endsWith('/historico'),
        ),
        isEmpty,
      );

      await at.tap(abrirLivelo);
      await at.pumpAndSettle();
      expect(find.text('Abrir Livelo?'), findsOneWidget);
      expect(
        find.text(
          'Você será levado ao site oficial para conferir preços e condições.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('ficar-aqui-livelo')), findsOneWidget);
      expect(find.byKey(const Key('continuar-livelo')), findsOneWidget);

      await at.tap(find.byKey(const Key('ficar-aqui-livelo')));
      await at.pumpAndSettle();
      await at.tap(find.byKey(const Key('historico-B')));
      await at.pumpAndSettle();

      expect(find.byKey(const Key('folha-historico-livelo')), findsOneWidget);
      expect(find.text('Histórico · Loja Comum'), findsOneWidget);
      expect(
        find.text('Últimas medições · até 30 registros · somente leitura'),
        findsOneWidget,
      );
      expect(find.text('5 pts/R\$ 1'), findsNWidgets(5));
      expect(find.text('Clube: 10 pts/R\$ 1'), findsNWidgets(5));
      expect(find.text('Completa'), findsNWidgets(5));
      await at.scrollUntilVisible(
        find.byTooltip('Próxima página'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('1 de 2'), findsOneWidget);
      expect(find.byTooltip('Próxima página'), findsOneWidget);
      expect(
        at
            .widget<IconButton>(
              find.byKey(const Key('historico-pagina-proxima')),
            )
            .onPressed,
        isNotNull,
      );
      await at.ensureVisible(find.byKey(const Key('historico-pagina-proxima')));
      await at.pumpAndSettle();
      await at.tap(find.byKey(const Key('historico-pagina-proxima')));
      await at.pumpAndSettle();
      expect(find.text('2 de 2'), findsOneWidget);
      expect(find.text('4 pts/R\$ 1'), findsOneWidget);
      expect(
        requisicoes.map((requisicao) => requisicao.url.path),
        contains('/api/livelo/catalogo/B/historico'),
      );
    },
  );

  testWidgets('360 dp mantém contagem e filtros na mesma linha V15', (
    at,
  ) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador, tamanho: const Size(360, 800));

    final linha = find.byKey(const Key('linha-resumo-resultados-livelo'));
    final contagem = find.descendant(of: linha, matching: find.text('2 lojas'));
    final botao = find.descendant(
      of: linha,
      matching: find.byKey(const Key('filtrar-ordenar-livelo')),
    );

    expect(linha, findsOneWidget);
    expect(contagem, findsOneWidget);
    expect(botao, findsOneWidget);
    expect(at.getSize(botao).height, greaterThanOrEqualTo(48));

    final rectLinha = at.getRect(linha);
    final rectContagem = at.getRect(contagem);
    final rectBotao = at.getRect(botao);
    expect(rectLinha.top, greaterThanOrEqualTo(0));
    expect(rectLinha.bottom, lessThanOrEqualTo(800));
    expect(rectBotao.top, lessThanOrEqualTo(rectContagem.center.dy));
    expect(rectBotao.bottom, greaterThanOrEqualTo(rectContagem.center.dy));
    expect(at.takeException(), isNull);
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

  testWidgets('ações Livelo quebram em 200% sem overflow', (at) async {
    final controlador = _controlador();
    addTearDown(controlador.dispose);
    await _abrir(at, controlador, tamanho: const Size(320, 640), escala: 2);

    final cartao = find.byKey(const Key('cartao-livelo-A'));
    final historico = find.descendant(
      of: cartao,
      matching: find.text('Histórico'),
    );
    final abrirLivelo = find.descendant(
      of: cartao,
      matching: find.text('Ir à Livelo'),
    );
    await at.ensureVisible(abrirLivelo);
    await at.pumpAndSettle();

    final limiteCartao = at.getRect(cartao);
    final limiteHistorico = at.getRect(historico);
    final limiteLivelo = at.getRect(abrirLivelo);
    expect(limiteLivelo.top, greaterThanOrEqualTo(limiteHistorico.bottom));
    expect(limiteHistorico.left, greaterThanOrEqualTo(limiteCartao.left));
    expect(limiteHistorico.right, lessThanOrEqualTo(limiteCartao.right));
    expect(limiteLivelo.left, greaterThanOrEqualTo(limiteCartao.left));
    expect(limiteLivelo.right, lessThanOrEqualTo(limiteCartao.right));
    expect(at.takeException(), isNull);
  });
}
