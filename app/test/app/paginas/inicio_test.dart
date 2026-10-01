import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/componentes/estados.dart';
import 'package:app_robo/app/componentes/fundacao_visual.dart';
import 'package:app_robo/app/paginas/inicio.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';

Map<String, Object?> resumo({
  String livelo = 'atualizado',
  String cashback = 'atualizado',
  String produtos = 'atualizado',
  String pichau = 'atualizado',
}) => {
  'gerado_em': '2026-08-23T12:00:00.000Z',
  'estado_geral':
      [
        livelo,
        cashback,
        produtos,
        pichau,
      ].every((estado) => estado == 'atualizado')
      ? 'atualizado'
      : 'atencao',
  'livelo': {
    'estado': livelo,
    'ultima_tentativa_em': '2026-08-23T10:30:00.000Z',
    'qualidade': livelo == 'degradado' ? 'degradada' : 'completa',
    'ultimo_sucesso_em': '2026-08-23T08:00:00.000Z',
    'lojas_acompanhadas': 126,
    'alertas_ultima_coleta': 2,
  },
  'cashback_inter': {
    'estado': cashback,
    'ultima_tentativa_em': '2026-08-23T07:00:00.000Z',
    'ultima_tentativa_estado': 'sucesso',
    'ultimo_sucesso_em': '2026-08-23T07:10:00.000Z',
    'lojas_acompanhadas': 4,
    'lojas_encontradas_ultima_coleta': 3,
  },
  'produtos': {
    'estado': produtos,
    'ultima_tentativa_em': '2026-08-23T06:00:00.000Z',
    'ultima_tentativa_estado': produtos == 'parcial' ? 'parcial' : 'sucesso',
    'dados_mais_antigos_em': '2026-08-23T06:05:00.000Z',
    'dados_mais_recentes_em': '2026-08-23T06:30:00.000Z',
    'qualidade': produtos == 'degradado' ? 'degradada' : 'completa',
    'lojas_selecionadas': 3,
    'lojas_sem_coleta': produtos == 'parcial' ? 1 : 0,
    'produtos_ativos': 3310,
  },
  'pichau': {
    'estado': pichau,
    'ultima_tentativa_em': '2026-08-23T07:00:00.000Z',
    'ultima_tentativa_estado': 'sucesso',
    'ultimo_sucesso_em': '2026-08-23T07:00:00.000Z',
    'qualidade': pichau == 'degradado' ? 'degradada' : 'completa',
    'produtos_ativos': 100,
    'produtos_esgotados': 4,
    'acompanhadas': 17,
  },
};

Map<String, Object?> resumoComDestaque() {
  final corpo = resumo();
  corpo['radar'] = <String, Object?>{
    'estado': 'atualizado',
    'total_acompanhamentos': 17,
    'por_origem': <String, int>{
      'livelo': 1,
      'inter_cashback': 4,
      'inter_produto': 8,
      'pichau': 4,
    },
    'alertas_nao_lidos': 1,
    'destaque': <String, Object?>{
      'alerta_id': 'alerta-natura',
      'origem': 'livelo',
      'tipo': 'pontuacao',
      'entidade_id': 'natura',
      'entidade_externa': 'natura',
      'nome': 'Natura',
      'valor_anterior': '4',
      'valor_atual': '8',
      'unidade': 'pontos_por_real',
      'direcao': 'aumento',
      'criado_em': '2026-08-23T11:00:00.000Z',
      'url_externa': 'https://www.livelo.com.br/natura',
    },
  };
  return corpo;
}

Api apiQueResponde(Future<http.Response> Function(http.Request) responder) =>
    Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient(responder),
      ),
    );

Future<void> abrir(
  WidgetTester at,
  Api api, {
  VoidCallback? aoAbrirLojas,
  VoidCallback? aoAbrirProgramas,
  VoidCallback? aoAbrirLivelo,
  VoidCallback? aoAbrirProdutos,
  VoidCallback? aoAbrirCashback,
  VoidCallback? aoAbrirPichau,
  VoidCallback? aoAbrirAlertas,
  Size tamanho = const Size(390, 844),
  double escalaTexto = 1,
  bool compacto = false,
  bool escuro = false,
  DateTime Function()? agora,
}) async {
  at.view.devicePixelRatio = 1;
  at.view.physicalSize = tamanho;
  addTearDown(at.view.resetDevicePixelRatio);
  addTearDown(at.view.resetPhysicalSize);
  await at.pumpWidget(
    MaterialApp(
      theme: TemaRadar.claro(),
      darkTheme: TemaRadar.escuro(),
      themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: PaginaInicio(
          api: api,
          aoAbrirLojas: aoAbrirLojas,
          aoAbrirProgramas: aoAbrirProgramas,
          aoAbrirLivelo: aoAbrirLivelo,
          aoAbrirProdutos: aoAbrirProdutos,
          aoAbrirCashback: aoAbrirCashback,
          aoAbrirPichau: aoAbrirPichau,
          aoAbrirAlertas: aoAbrirAlertas,
          agora: agora ?? () => DateTime(2026, 8, 23),
          experienciaCompacta: compacto,
        ),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('mostra carregamento antes do resumo', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await at.pumpAndSettle();
  });

  testWidgets('exibe métricas reais, recortes e estados independentes', (
    at,
  ) async {
    final api = apiQueResponde((requisicao) async {
      expect(requisicao.url.path, '/api/resumo');
      expect(requisicao.headers['authorization'], 'Bearer token-teste');
      return http.Response(jsonEncode(resumo()), 200);
    });
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.text('Seu radar hoje'), findsOneWidget);
    expect(find.text('Os quatro domínios estão atualizados.'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('3.310'), findsOneWidget);
    expect(find.text('Última coleta válida'), findsOneWidget);
    await at.scrollUntilVisible(find.text('Estado por domínio'), 300);
    await at.drag(
      find.byKey(const Key('resumo-inicio')),
      const Offset(0, -300),
    );
    await at.pumpAndSettle();
    expect(find.text('Atualizado'), findsNWidgets(3));
  });

  testWidgets('prioriza parcial e mantém os horários por domínio', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo(produtos: 'parcial')), 200),
    );
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.text('Produtos: parcial'), findsOneWidget);
    await at.scrollUntilVisible(find.text('Estado por domínio'), 400);
    expect(find.text('Parcial'), findsOneWidget);
    expect(find.textContaining('1 sem coleta'), findsOneWidget);
  });

  testWidgets('RN29 comunica qualidade reduzida e snapshot preservado', (
    at,
  ) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo(livelo: 'degradado')), 200),
    );
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.text('Livelo: degradado'), findsOneWidget);
    expect(
      find.textContaining('O último retrato válido foi preservado.'),
      findsOneWidget,
    );
    expect(find.textContaining('RN29'), findsNothing);
  });

  testWidgets('domínio indisponível usa traço em vez de zero inventado', (
    at,
  ) async {
    final corpo = resumo(livelo: 'indisponivel');
    final livelo = Map<String, Object?>.from(corpo['livelo']! as Map);
    livelo['ultimo_sucesso_em'] = null;
    corpo['livelo'] = livelo;
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(corpo), 200),
    );
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(find.text('Livelo: indisponível'), findsOneWidget);
  });

  testWidgets('sino da Home anuncia a Central e a contagem de não lidos', (
    at,
  ) async {
    final dadosResumo = resumoComDestaque();
    final radar = Map<String, Object?>.from(dadosResumo['radar']! as Map);
    radar['alertas_nao_lidos'] = 4;
    dadosResumo['radar'] = radar;
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(dadosResumo), 200),
    );

    await abrir(at, api, compacto: true, aoAbrirAlertas: () {});
    await at.pumpAndSettle();

    final sino = find.bySemanticsLabel('Alertas, 4 não lidos');
    expect(sino, findsOneWidget);
    final dadosSemanticos = at.getSemantics(sino).getSemanticsData();
    expect(dadosSemanticos.hasAction(SemanticsAction.tap), isTrue);
  });

  testWidgets('falha inicial mostra retry', (at) async {
    final api = apiQueResponde(
      (_) async =>
          http.Response('{"erro":{"codigo":"inesperado","mensagem":"x"}}', 500),
    );
    await abrir(at, api);
    await at.pumpAndSettle();

    expect(find.byType(EstadoFalha), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('falha ao atualizar preserva o último resumo', (at) async {
    var chamadas = 0;
    final api = apiQueResponde((_) async {
      chamadas++;
      if (chamadas == 1) return http.Response(jsonEncode(resumo()), 200);
      return http.Response(
        '{"erro":{"codigo":"inesperado","mensagem":"x"}}',
        500,
      );
    });
    await abrir(at, api);
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('atualizar-resumo')));
    await at.pumpAndSettle();

    expect(find.text('Seu radar hoje'), findsOneWidget);
    expect(
      find.text('A atualização falhou. Mantivemos o último resumo recebido.'),
      findsOneWidget,
    );
  });

  testWidgets('Início compacto evita polling e atualiza após TTL ao retomar', (
    at,
  ) async {
    var chamadas = 0;
    var agora = DateTime(2026, 8, 23);
    final api = apiQueResponde((_) async {
      chamadas++;
      return http.Response(jsonEncode(resumo()), 200);
    });
    await abrir(at, api, compacto: true, agora: () => agora);
    await at.pumpAndSettle();
    expect(chamadas, 1);
    await at.pump(const Duration(seconds: 30));
    await at.pumpAndSettle();
    expect(chamadas, 1);

    agora = agora.add(const Duration(minutes: 6));
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await at.pump();
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await at.pumpAndSettle();
    expect(chamadas, 2);

    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await at.pump();
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await at.pumpAndSettle();
    expect(chamadas, 2);
  });

  testWidgets('Home compacta usa as descrições estáticas da referência', (
    at,
  ) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api, compacto: true);
    await at.pumpAndSettle();

    expect(find.text('Boas escolhas começam aqui.'), findsOneWidget);
    final tema = Theme.of(at.element(find.text('Boas escolhas começam aqui.')));
    final sobrelinha = at.widget<Text>(find.text('SEU RADAR, SEU RITMO'));
    final titulo = at.widget<Text>(find.text('Boas escolhas começam aqui.'));
    final cabecalho = find.byKey(const Key('cabecalho-inicio-compacto'));
    final estado = at.widget<Text>(
      find.byKey(const Key('estado-resumo-compacto')),
    );
    final tituloSecao = at.widget<Text>(find.text('Explore as origens'));
    expect(
      sobrelinha.style,
      tema.textTheme.sobrelinhaInicio?.copyWith(
        color: tema.colorScheme.onSurfaceVariant,
      ),
    );
    expect(titulo.style, tema.textTheme.tituloHeroInicio);
    expect(
      estado.style,
      tema.textTheme.estadoInicio?.copyWith(
        color: tema.colorScheme.onSurfaceVariant,
      ),
    );
    expect(tituloSecao.style, tema.textTheme.tituloSecaoInicio);
    expect(sobrelinha.style?.fontSize, 12);
    expect(titulo.style?.fontSize, 32);
    expect(estado.style?.fontSize, 12);
    expect(
      at.getTopLeft(find.text('SEU RADAR, SEU RITMO')).dy -
          at.getBottomLeft(cabecalho).dy,
      24,
    );
    expect(
      at.getTopLeft(find.text('Boas escolhas começam aqui.')).dy -
          at.getBottomLeft(find.text('SEU RADAR, SEU RITMO')).dy,
      8,
    );
    expect(
      at.getTopLeft(find.byKey(const Key('estado-resumo-compacto'))).dy -
          at.getBottomLeft(find.text('Boas escolhas começam aqui.')).dy,
      12,
    );
    expect(
      at.getTopLeft(find.text('Explore as origens')).dy -
          at.getBottomLeft(find.byKey(const Key('estado-resumo-compacto'))).dy,
      32,
    );
    expect(find.text('Tudo atualizado'), findsNothing);
    expect(find.text('Atualizado com avisos'), findsNothing);
    expect(find.text('Explore as origens'), findsOneWidget);
    expect(find.byKey(const Key('origem-livelo')), findsOneWidget);
    expect(find.byKey(const Key('origem-inter')), findsOneWidget);
    expect(find.byKey(const Key('origem-pichau')), findsOneWidget);
    expect(find.text('Atividade recente'), findsNothing);
    expect(find.text('Cashback e produtos'), findsOneWidget);
    expect(find.text('Pontos em lojas'), findsOneWidget);
    expect(find.text('PCs gamer'), findsOneWidget);
    expect(find.text('4 lojas'), findsNothing);
    expect(find.text('100 produtos'), findsNothing);
    for (final chave in const [
      'origem-inter',
      'origem-livelo',
      'origem-pichau',
    ]) {
      final cartao = at.widget<CartaoRadar>(find.byKey(Key(chave)));
      expect(cartao.comSombra, isFalse);
    }
    expect(find.byKey(const Key('atualizar-resumo-cabecalho')), findsNothing);
  });

  for (final escuro in [false, true]) {
    testWidgets(
      'sino da Home usa superfície secundária no tema ${escuro ? 'escuro' : 'claro'}',
      (at) async {
        final api = apiQueResponde(
          (_) async => http.Response(jsonEncode(resumo()), 200),
        );
        await abrir(at, api, compacto: true, escuro: escuro);
        await at.pumpAndSettle();

        final sino = at.widget<IconButton>(
          find.byKey(const Key('abrir-alertas-cabecalho')),
        );
        final cores = Theme.of(
          at.element(find.byKey(const Key('abrir-alertas-cabecalho'))),
        ).extension<CoresRadar>()!;
        expect(
          sino.style?.backgroundColor?.resolve({}),
          cores.superficieAlternativa,
        );
        expect(sino.style?.foregroundColor?.resolve({}), cores.texto);
        expect(sino.style?.shape?.resolve({}), const CircleBorder());
      },
    );
  }

  testWidgets('cards compactos seguem largura V15 e altura pelo conteúdo', (
    at,
  ) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );

    for (final largura in [320.0, 360.0, 390.0, 430.0]) {
      await abrir(at, api, compacto: true, tamanho: Size(largura, 844));
      await at.pumpAndSettle();

      expect(
        at.getSize(find.byKey(const Key('trilho-origens'))).width,
        closeTo(largura, 0.1),
        reason: 'a área de rolagem chega às bordas em $largura dp',
      );
      final tamanhoCartao = at.getSize(find.byKey(const Key('origem-inter')));
      final larguraEsperada = largura * 0.43;
      expect(
        tamanhoCartao.width,
        closeTo(larguraEsperada < 132 ? 132 : larguraEsperada, 0.1),
        reason: 'largura do card em $largura dp',
      );
      expect(
        tamanhoCartao.height,
        greaterThan(0),
        reason: 'altura em $largura dp',
      );
      expect(at.takeException(), isNull, reason: 'layout em $largura dp');

      if (largura == 360) {
        final descricao = find.text('Cashback e produtos');
        final texto = at.widget<Text>(descricao);
        expect(texto.maxLines, isNull);
        expect(texto.overflow, isNull);
        expect(
          at.getSize(descricao).height,
          greaterThan(18),
          reason: 'a descrição quebra em duas linhas a 360 dp',
        );
      }
    }
  });

  testWidgets('cards compactos crescem em 320 dp com texto a 200%', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(
      at,
      api,
      compacto: true,
      tamanho: const Size(320, 640),
      escalaTexto: 2,
    );
    await at.pumpAndSettle();

    final cartaoFinder = find.byKey(const Key('origem-inter'));
    await at.scrollUntilVisible(
      cartaoFinder,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    final cartao = at.getRect(cartaoFinder);
    expect(at.getSize(cartaoFinder).width, greaterThan(132));
    expect(at.getSize(cartaoFinder).width, lessThan(160));
    expect(at.getSize(cartaoFinder).height, greaterThan(136));
    for (final descricao in [
      find.descendant(
        of: cartaoFinder,
        matching: find.text('Cashback e produtos'),
      ),
    ]) {
      final texto = at.widget<Text>(descricao);
      final retangulo = at.getRect(descricao);
      expect(texto.maxLines, isNull);
      expect(texto.overflow, isNull);
      expect(retangulo.left, greaterThanOrEqualTo(cartao.left));
      expect(retangulo.right, lessThanOrEqualTo(cartao.right));
      expect(retangulo.bottom, lessThanOrEqualTo(cartao.bottom));
    }
    expect(at.takeException(), isNull);
  });

  testWidgets('Home compacta mostra a contagem no sino sem cartão de alerta', (
    at,
  ) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumoComDestaque()), 200),
    );
    await abrir(at, api, compacto: true);
    await at.pumpAndSettle();

    expect(find.text('Natura'), findsNothing);
    expect(find.text('Ver alertas'), findsNothing);
    final badge = at.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isTrue);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Explore as origens'), findsOneWidget);
    expect(find.text('1 mudanças para conferir'), findsOneWidget);
    expect(
      find.byKey(const Key('indicador-mudancas-nao-lidas')),
      findsOneWidget,
    );
  });

  testWidgets('Home compacta mostra tudo lido sem o ponto de mudança', (
    at,
  ) async {
    final corpo = resumo();
    corpo['radar'] = <String, Object?>{
      'estado': 'atualizado',
      'alertas_nao_lidos': 0,
    };
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(corpo), 200),
    );
    await abrir(at, api, compacto: true);
    await at.pumpAndSettle();

    expect(find.text('Tudo lido por enquanto'), findsOneWidget);
    expect(find.byKey(const Key('indicador-mudancas-nao-lidas')), findsNothing);
  });

  testWidgets('card Pichau abre sua subárea de Explorar', (at) async {
    var abriu = false;
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api, compacto: true, aoAbrirPichau: () => abriu = true);
    await at.pumpAndSettle();
    await at.drag(
      find.byKey(const Key('trilho-origens')),
      const Offset(-220, 0),
    );
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('origem-pichau')));

    expect(abriu, isTrue);
  });

  testWidgets('Resumo não inventa coleta em andamento no Banco Inter', (
    at,
  ) async {
    final api = apiQueResponde(
      (_) async =>
          http.Response(jsonEncode(resumo(produtos: 'atualizando')), 200),
    );
    await abrir(at, api, compacto: false);
    await at.pumpAndSettle();

    await at.scrollUntilVisible(
      find.text('Atualizando'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Atualizando'), findsOneWidget);
    expect(find.textContaining('Há uma coleta em andamento'), findsNothing);
  });

  testWidgets('Início compacto não estoura em 320 px com texto ampliado', (
    at,
  ) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(
      at,
      api,
      compacto: true,
      tamanho: const Size(320, 640),
      escalaTexto: 1.5,
    );
    await at.pumpAndSettle();
    expect(at.takeException(), isNull);
    expect(at.takeException(), isNull);
  });

  testWidgets('quatro atalhos chamam jornadas reais', (at) async {
    final abertos = <String>[];
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(
      at,
      api,
      aoAbrirLojas: () => abertos.add('lojas'),
      aoAbrirLivelo: () => abertos.add('livelo'),
      aoAbrirProdutos: () => abertos.add('produtos'),
      aoAbrirCashback: () => abertos.add('cashback'),
      tamanho: const Size(1200, 2000),
    );
    await at.pumpAndSettle();

    for (final chave in [
      'atalho-lojas',
      'atalho-livelo',
      'atalho-produtos',
      'atalho-cashback',
    ]) {
      final atalho = find.byKey(Key(chave));
      await at.tap(atalho);
    }
    expect(abertos, ['lojas', 'livelo', 'produtos', 'cashback']);
  });

  testWidgets('layout amplo e texto ampliado não estouram', (at) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api, tamanho: const Size(1200, 900), escalaTexto: 1.5);
    await at.pumpAndSettle();

    expect(at.takeException(), isNull);
    expect(find.text('Produtos ativos'), findsOneWidget);
  });

  testWidgets('celular estreito com texto ampliado alcança todos os estados', (
    at,
  ) async {
    final api = apiQueResponde(
      (_) async => http.Response(jsonEncode(resumo()), 200),
    );
    await abrir(at, api, tamanho: const Size(320, 640), escalaTexto: 1.5);
    await at.pumpAndSettle();
    expect(at.takeException(), isNull, reason: 'topo do resumo');
    await at.scrollUntilVisible(find.text('Estado por domínio'), 300);

    expect(at.takeException(), isNull, reason: 'estados por domínio');
    expect(find.text('Estado por domínio'), findsOneWidget);
  });
}
