import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/app/tema/tokens.dart';
import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/conta/pagina_aparencia.dart';
import 'package:app_robo/features/conta/pagina_perfil.dart';
import 'package:app_robo/features/conta/paginas_conta.dart';

Api _apiFake(List<http.Request> requisicoes) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      requisicoes.add(requisicao);
      return http.Response(jsonEncode(<String, Object?>{}), 200);
    }),
  ),
);

Api _apiComResposta(
  List<http.Request> requisicoes,
  Future<http.Response> Function(http.Request) responder,
) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      requisicoes.add(requisicao);
      return responder(requisicao);
    }),
  ),
);

Future<void> _abrir(
  WidgetTester tester,
  Widget tela, {
  Size tamanho = const Size(390, 844),
  double escalaTexto = 1,
  ThemeData? tema,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = tamanho;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const <Locale>[Locale('pt', 'BR')],
      theme: tema ?? TemaRadar.claro(),
      home: tela,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _revelar(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(
      finder,
      220,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );

Widget _perfil({String? identificacao}) => PaginaPerfil(
  api: _apiFake(<http.Request>[]),
  identificacao: identificacao,
  administrador: false,
  aoAbrirAcompanhamentos: () {},
  aoAbrirNotificacoes: () {},
  aoAbrirAparencia: () {},
  aoAbrirAjuda: () {},
  aoAbrirProblema: () {},
  aoAbrirRelatos: () {},
  aoAbrirPrivacidade: () {},
);

class _PaginaAnterior extends StatefulWidget {
  const _PaginaAnterior({required this.rota});

  final Widget Function() rota;

  @override
  State<_PaginaAnterior> createState() => _EstadoPaginaAnterior();
}

class _EstadoPaginaAnterior extends State<_PaginaAnterior> {
  var _contador = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Estado anterior: $_contador',
            key: const Key('estado-anterior'),
          ),
          TextButton(
            key: const Key('alterar-estado-anterior'),
            onPressed: () => setState(() => _contador++),
            child: const Text('Alterar estado'),
          ),
          TextButton(
            key: const Key('abrir-rota-secundaria'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => widget.rota()),
            ),
            child: const Text('Abrir rota'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _abrirComOrigem(
  WidgetTester tester,
  Widget Function() rota, {
  Size tamanho = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = tamanho;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: TemaRadar.claro(),
      home: _PaginaAnterior(rota: rota),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('alterar-estado-anterior')));
  await tester.pumpAndSettle();
}

Future<void> _verificarRetornos(
  WidgetTester tester,
  Widget Function() rota,
) async {
  await _abrirComOrigem(tester, rota);
  for (final usarBotaoVisivel in [true, false]) {
    await tester.tap(find.byKey(const Key('abrir-rota-secundaria')));
    await tester.pumpAndSettle();
    final voltar = find.byTooltip('Voltar');
    expect(voltar, findsOneWidget);
    if (usarBotaoVisivel) {
      await tester.tap(voltar);
      await tester.pumpAndSettle();
    } else {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(find.text('Estado anterior: 1'), findsOneWidget);
    expect(find.byKey(const Key('abrir-rota-secundaria')), findsOneWidget);
  }
}

void main() {
  testWidgets('Perfil agrupa rotas e mostra somente identificação real', (
    tester,
  ) async {
    for (final largura in [320.0, 360.0, 390.0, 430.0]) {
      await _abrir(
        tester,
        _perfil(identificacao: 'rodrigo@example.com'),
        tamanho: Size(largura, 844),
        escalaTexto: 1.3,
      );

      expect(find.text('SUA CONTA'), findsOneWidget);
      expect(find.text('Olá.'), findsOneWidget);
      expect(find.text('rodrigo@example.com'), findsOneWidget);
      expect(find.text('Olá, Rodrigo.'), findsNothing);
      expect(find.text('Acesso padrão'), findsNothing);
      expect(find.text('Contagem indisponível'), findsOneWidget);
      expect(find.text('Escolha o que quer receber'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('SUA CONTA')).dx,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('marca-cabecalho-radar'))).dx,
        ),
      );
      expect(find.byKey(const Key('perfil-grupo-conta')), findsOneWidget);
      expect(find.byKey(const Key('perfil-grupo-suporte')), findsOneWidget);
      expect(find.byKey(const Key('perfil-acompanhamentos')), findsOneWidget);
      expect(find.byKey(const Key('perfil-notificacoes')), findsOneWidget);
      expect(find.byKey(const Key('perfil-ajuda')), findsOneWidget);
      expect(find.byKey(const Key('perfil-problema')), findsOneWidget);
      expect(find.text('Relatar problema'), findsOneWidget);
      expect(find.byKey(const Key('perfil-relatos')), findsOneWidget);
      expect(find.byKey(const Key('perfil-privacidade')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Perfil em $largura dp');
    }
  });

  testWidgets('iniciais do avatar são decorativas na árvore semântica', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    addTearDown(semantica.dispose);

    await _abrir(tester, _perfil(identificacao: 'rodrigo@example.com'));

    expect(find.bySemanticsLabel('R'), findsNothing);
    expect(find.bySemanticsLabel('Olá.'), findsOneWidget);
    expect(find.bySemanticsLabel('rodrigo@example.com'), findsOneWidget);
  });

  testWidgets(
    'Perfil reflete preferência de avisos sem afirmar permissão do aparelho',
    (tester) async {
      final requisicoes = <http.Request>[];
      final api = _apiComResposta(requisicoes, (requisicao) async {
        if (requisicao.url.path == '/api/alertas/preferencias') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'push_global': true,
              'preco': true,
              'cashback': false,
              'pontuacao': true,
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      await _abrir(
        tester,
        PaginaPerfil(
          api: api,
          administrador: false,
          aoAbrirAcompanhamentos: () {},
          aoAbrirNotificacoes: () {},
          aoAbrirAparencia: () {},
          aoAbrirAjuda: () {},
          aoAbrirProblema: () {},
          aoAbrirRelatos: () {},
          aoAbrirPrivacidade: () {},
        ),
      );

      expect(find.text('Preferência de avisos ativa'), findsOneWidget);
      expect(find.text('Ativadas nesta demonstração'), findsNothing);
      expect(
        requisicoes.map((request) => request.url.path),
        contains('/api/alertas/preferencias'),
      );
    },
  );

  testWidgets('Meus relatos distingue vazio de falha e mantém retorno', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final api = _apiComResposta(
      requisicoes,
      (_) async => http.Response('{"erro":{"codigo":"inesperado"}}', 500),
    );
    await _verificarRetornos(tester, () => PaginaMeusRelatos(api: api));
    expect(
      find.text('Não foi possível carregar seus relatos agora.'),
      findsOneWidget,
    );
    expect(find.textContaining('Nenhum relato por aqui.'), findsNothing);
    expect(
      requisicoes.map((request) => request.url.path),
      everyElement('/api/relatos-problema'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Meus relatos mostra dados reais, pagina e copia protocolo', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final api = _apiComResposta(requisicoes, (requisicao) async {
      final pagina = requisicao.url.queryParameters['pagina'];
      final primeira = pagina == '1';
      final itens = primeira
          ? List.generate(
              20,
              (indice) => <String, Object?>{
                'id': '${519 + indice}',
                'categoria': 'dados',
                'mensagem': indice == 0
                    ? 'O catálogo não atualizou.'
                    : 'Relato de teste ${indice + 1}.',
                'criado_em': '2026-09-28T16:30:00.000Z',
              },
            )
          : [
              <String, Object?>{
                'id': '539',
                'categoria': 'dados',
                'mensagem': 'A campanha apareceu duas vezes.',
                'criado_em': '2026-09-27T16:30:00.000Z',
              },
            ];
      return http.Response(
        jsonEncode({
          'itens': itens,
          'pagina': int.parse(pagina ?? '1'),
          'por_pagina': 20,
          'total_itens': 21,
          'total_paginas': 2,
          'tem_proxima': primeira,
        }),
        200,
      );
    });
    await _abrir(
      tester,
      PaginaMeusRelatos(api: api),
      tamanho: const Size(320, 840),
      escalaTexto: 1.2,
    );

    expect(find.text('Meus relatos'), findsOneWidget);
    expect(find.text('O catálogo não atualizou.'), findsOneWidget);
    expect(find.text('519'), findsOneWidget);
    expect(find.textContaining('28 de set. de 2026'), findsOneWidget);
    final copiar = find.byKey(const Key('copiar-relato-519'));
    await tester.ensureVisible(copiar);
    await tester.tap(copiar);
    await tester.pumpAndSettle();
    expect(find.text('Protocolo copiado.'), findsOneWidget);

    final proxima = find.byTooltip('Próxima página');
    await tester.ensureVisible(proxima);
    await tester.tap(proxima);
    await tester.pumpAndSettle();
    expect(find.text('A campanha apareceu duas vezes.'), findsOneWidget);
    expect(find.text('520'), findsOneWidget);
    expect(
      requisicoes.map((request) => request.url.queryParameters['pagina']),
      ['1', '2'],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Aparência apresenta opções V15 e movimento em telas estreitas', (
    tester,
  ) async {
    await _abrir(
      tester,
      const PaginaAparencia(),
      tamanho: const Size(320, 640),
      escalaTexto: 1.5,
    );

    expect(find.text('Do seu jeito.'), findsOneWidget);
    expect(find.text('Seguir o sistema'), findsOneWidget);
    expect(find.text('Acompanha a aparência do aparelho.'), findsOneWidget);
    final sistema = find.byKey(const Key('aparencia-opcao-system'));
    final superficieSelecionada = tester.widget<Material>(
      find.descendant(of: sistema, matching: find.byType(Material)).first,
    );
    expect(
      superficieSelecionada.color,
      tester.element(sistema).tokens.colors.acaoFundo,
    );
    final formaSelecionada =
        superficieSelecionada.shape! as RoundedRectangleBorder;
    expect(
      formaSelecionada.side.color,
      CoresRadar.de(tester.element(sistema)).acao,
    );
    expect(
      find.descendant(of: sistema, matching: find.byType(Positioned)),
      findsNothing,
    );
    expect(find.text('Luz suave, leitura confortável.'), findsOneWidget);
    final descricaoEscuro = find.text('Grafite, contraste e menos brilho.');
    await _revelar(tester, descricaoEscuro);
    expect(descricaoEscuro, findsOneWidget);
    final movimento = find.text('Movimento');
    await _revelar(tester, movimento);
    expect(movimento, findsOneWidget);
    expect(find.text('Reduzir animações'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Aparência usa a cor de ação suave do ThemeExtension', (
    tester,
  ) async {
    const corAcaoFundo = Color(0xFF173A55);
    final temaBase = TemaRadar.claro();
    final extensoes = temaBase.extensions.values
        .map((extensao) {
          if (extensao is AppTokens) {
            return extensao.copyWith(
              colors: extensao.colors.copyWith(acaoFundo: corAcaoFundo),
            );
          }
          return extensao;
        })
        .toList(growable: false);

    await _abrir(
      tester,
      const PaginaAparencia(),
      tema: temaBase.copyWith(extensions: extensoes),
    );

    final sistema = find.byKey(const Key('aparencia-opcao-system'));
    final superficieSelecionada = tester.widget<Material>(
      find.descendant(of: sistema, matching: find.byType(Material)).first,
    );
    expect(superficieSelecionada.color, corAcaoFundo);
  });

  testWidgets('Aparência oferece retorno visível e por back do sistema', (
    tester,
  ) async {
    await _verificarRetornos(tester, () => const PaginaAparencia());
    expect(tester.takeException(), isNull);
  });

  testWidgets('telas secundárias de conta mantêm a navegação inferior V15', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final api = _apiFake(requisicoes);
    final telas = <Widget Function(ValueChanged<DestinoCompacto>)>[
      (aoNavegar) => PaginaAparencia(aoNavegar: aoNavegar),
      (aoNavegar) => PaginaAjuda(api: api, aoNavegar: aoNavegar),
      (aoNavegar) => PaginaPrivacidade(api: api, aoNavegar: aoNavegar),
      (aoNavegar) => PaginaRelatoProblema(api: api, aoNavegar: aoNavegar),
    ];

    for (final construirTela in telas) {
      DestinoCompacto? destino;
      await _abrir(
        tester,
        construirTela((valor) => destino = valor),
        tamanho: const Size(390, 844),
      );

      expect(find.byKey(const Key('barra-inferior-v15')), findsOneWidget);
      await tester.tap(find.byKey(const Key('barra-explorar')));
      await tester.pumpAndSettle();
      expect(destino, DestinoCompacto.explorar);
      expect(tester.takeException(), isNull);
    }
    expect(requisicoes, isEmpty);
  });

  testWidgets('Ajuda expande respostas e retorna ao mesmo contexto', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final api = _apiFake(requisicoes);
    await _abrirComOrigem(
      tester,
      () => PaginaAjuda(api: api),
      tamanho: const Size(320, 3000),
    );
    await tester.tap(find.byKey(const Key('abrir-rota-secundaria')));
    await tester.pumpAndSettle();

    expect(find.text('Pode perguntar.'), findsOneWidget);
    final pergunta = find.text('Por que o preço pode mudar no destino?');
    await tester.ensureVisible(pergunta);
    await tester.tap(pergunta);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('O aplicativo mostra o último valor recebido'),
      findsOneWidget,
    );

    final abrirRelato = find.byKey(const Key('ajuda-abrir-relato'));
    await tester.tap(abrirRelato);
    await tester.pumpAndSettle();
    expect(find.text('O que aconteceu?'), findsOneWidget);
    expect(requisicoes, isEmpty);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Pode perguntar.'), findsOneWidget);
    expect(
      find.textContaining('O aplicativo mostra o último valor recebido'),
      findsOneWidget,
    );
    expect(requisicoes, isEmpty);

    await tester.tap(find.byKey(const Key('voltar-pagina-conta')));
    await tester.pumpAndSettle();
    expect(find.text('Estado anterior: 1'), findsOneWidget);
    expect(find.byKey(const Key('abrir-rota-secundaria')), findsOneWidget);
    expect(requisicoes, isEmpty);
  });

  testWidgets('Privacidade preserva prazos reais e abre o suporte', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final api = _apiFake(requisicoes);
    await _abrir(
      tester,
      PaginaPrivacidade(api: api),
      tamanho: const Size(320, 3000),
      escalaTexto: 1.3,
    );

    expect(find.text('Você no controle.'), findsOneWidget);
    expect(find.textContaining('90 dias'), findsOneWidget);
    expect(find.textContaining('180 dias'), findsOneWidget);
    expect(
      find.textContaining('permissão do aparelho é opcional'),
      findsOneWidget,
    );
    expect(find.textContaining('Nesta demonstração'), findsNothing);
    expect(find.textContaining('@'), findsNothing);
    expect(find.text('Relatar uma dúvida de privacidade'), findsOneWidget);

    final abrirRelato = find.byKey(const Key('privacidade-abrir-relato'));
    await tester.tap(abrirRelato);
    await tester.pumpAndSettle();
    expect(find.text('O que aconteceu?'), findsOneWidget);
    expect(requisicoes, isEmpty);
  });

  testWidgets('Privacidade oferece retorno visível e por back do sistema', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final api = _apiFake(requisicoes);
    await _verificarRetornos(tester, () => PaginaPrivacidade(api: api));
    expect(requisicoes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Relato mantém campos e categorias sem enviar', (tester) async {
    final requisicoes = <http.Request>[];
    final api = _apiFake(requisicoes);
    await _abrir(
      tester,
      PaginaRelatoProblema(api: api),
      tamanho: const Size(320, 640),
      escalaTexto: 1.5,
    );

    expect(find.text('O que aconteceu?'), findsOneWidget);
    expect(
      find.text('Conte o problema e onde você o encontrou.'),
      findsOneWidget,
    );
    expect(find.text('Dados do catálogo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('categoria-relato')));
    await tester.pumpAndSettle();
    for (final assunto in const [
      'Dados do catálogo',
      'Acesso à conta',
      'Notificações',
      'Privacidade',
      'Outro',
    ]) {
      expect(find.text(assunto), findsWidgets);
    }
    await tester.tap(find.text('Outro'));
    await tester.pumpAndSettle();
    final descricao = tester.widget<TextField>(
      find.byKey(const Key('descricao-relato')),
    );
    expect(descricao.maxLength, 2000);
    expect(find.byKey(const Key('enviar-relato')), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(requisicoes, isEmpty);
  });

  testWidgets('Relato oferece retorno visível e por back sem enviar', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    final api = _apiFake(requisicoes);
    await _verificarRetornos(tester, () => PaginaRelatoProblema(api: api));
    expect(requisicoes, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Relato confirmado abre Meus relatos com protocolo da API', (
    tester,
  ) async {
    final requisicoes = <http.Request>[];
    const mensagem = 'Quero corrigir os dados do catálogo.';
    final api = _apiComResposta(requisicoes, (requisicao) async {
      if (requisicao.method == 'POST') {
        expect(requisicao.url.path, '/api/relatos-problema');
        expect(requisicao.body, contains('"categoria":"catalog"'));
        return http.Response('{"registrado":true,"id":"519"}', 201);
      }
      return http.Response(
        jsonEncode(<String, Object?>{
          'itens': [
            {
              'id': '519',
              'categoria': 'catalog',
              'mensagem': mensagem,
              'criado_em': '2026-09-29T12:00:00Z',
            },
          ],
          'pagina': 1,
          'por_pagina': 20,
          'total_itens': 1,
          'total_paginas': 1,
          'tem_proxima': false,
        }),
        200,
      );
    });
    await _abrir(tester, PaginaRelatoProblema(api: api));

    await tester.enterText(find.byKey(const Key('descricao-relato')), mensagem);
    await tester.tap(find.byKey(const Key('enviar-relato')));
    await tester.pumpAndSettle();

    expect(find.text('Seu retorno importa.'), findsOneWidget);
    expect(find.byKey(const Key('protocolo-relato-519')), findsOneWidget);
    expect(find.text(mensagem), findsOneWidget);
    expect(
      requisicoes.map((requisicao) => requisicao.url.path),
      containsAll(['/api/relatos-problema', '/api/relatos-problema']),
    );
    expect(tester.takeException(), isNull);
  });
}
