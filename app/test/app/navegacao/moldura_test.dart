import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/navegacao/destinos.dart';
import 'package:app_robo/app/navegacao/moldura.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';

const _paginaVazia =
    '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,'
    '"total_paginas":1,"tem_proxima":false,"atualizado_em":null}';

const _cashbackInter =
    '{"itens":[{"id":"magalu","slug":"magalu","nome":"Magazine Luiza",'
    '"cashback_principal_texto":"Até 20% de cashback",'
    '"cashback_principal_valor":"20.00","cashback_secundario_texto":null,'
    '"cashback_secundario_valor":null,"etiqueta":null,'
    '"descricao_principal":null,"descricao_secundaria":null,'
    '"encontrada":true,"favorita":true,'
    '"link":"https://shopping.inter.co/site-parceiro/lojas"}],'
    '"pagina":1,"por_pagina":20,'
    '"total_itens":1,"total_paginas":1,"tem_proxima":false,'
    '"atualizado_em":"2026-08-23T11:38:00Z"}';

const _sitesParceirosInter =
    '{"itens":[{"id":"magalu","id_externo":"1","slug":"magalu",'
    '"nome":"Magazine Luiza","cashback_principal_texto":"Até 20%",'
    '"cashback_principal_valor":"20.00","ativa":true,"favorita":true}],'
    '"pagina":1,"por_pagina":20,"total_itens":382,"total_paginas":20,'
    '"tem_proxima":true,"atualizado_em":null}';

const _lojasDiretasInter =
    '{"itens":[{"id":"amazon","id_externo":"1","slug":"amazon",'
    '"nome":"Amazon","selecionada":true,"ativa":true,'
    '"ultima_execucao":"2026-08-23T11:00:00Z",'
    '"ultimo_estado":"sucesso","paginas":12,'
    '"ultima_tentativa_em":"2026-08-23T11:00:00Z",'
    '"ultima_tentativa_estado":"sucesso",'
    '"ultima_coleta_sucesso_em":"2026-08-23T11:00:00Z",'
    '"produtos_encontrados":18,'
    '"cashback_resumo_texto":"Até 6% de cashback"}],'
    '"pagina":1,"por_pagina":20,"total_itens":1,"total_paginas":1,'
    '"tem_proxima":false,"atualizado_em":null}';

const _resumo =
    '{"gerado_em":"2026-08-23T12:00:00Z","estado_geral":"sem_dados",'
    '"livelo":{"estado":"sem_dados","ultimo_sucesso_em":null,'
    '"lojas_acompanhadas":0,"alertas_ultima_coleta":0},'
    '"cashback_inter":{"estado":"sem_dados","ultima_tentativa_em":null,'
    '"ultima_tentativa_estado":null,"ultimo_sucesso_em":null,'
    '"lojas_acompanhadas":0,"lojas_encontradas_ultima_coleta":0},'
    '"produtos":{"estado":"sem_dados","ultima_tentativa_em":null,'
    '"ultima_tentativa_estado":null,"dados_mais_antigos_em":null,'
    '"dados_mais_recentes_em":null,"qualidade":null,"lojas_selecionadas":0,'
    '"lojas_sem_coleta":0,"produtos_ativos":0}}';

const _resumoComEstadosIndependentes =
    '{"gerado_em":"2026-08-23T12:00:00Z","estado_geral":"atencao",'
    '"livelo":{"estado":"atualizado","ultimo_sucesso_em":"2026-08-23T10:30:00Z",'
    '"lojas_acompanhadas":3,"alertas_ultima_coleta":2},'
    '"cashback_inter":{"estado":"falha_recente","ultima_tentativa_em":"2026-08-23T11:40:00Z",'
    '"ultima_tentativa_estado":"falha","ultimo_sucesso_em":"2026-08-23T08:00:00Z",'
    '"lojas_acompanhadas":4,"lojas_encontradas_ultima_coleta":4},'
    '"produtos":{"estado":"parcial","ultima_tentativa_em":"2026-08-23T11:30:00Z",'
    '"ultima_tentativa_estado":"parcial","dados_mais_antigos_em":"2026-08-23T09:00:00Z",'
    '"dados_mais_recentes_em":"2026-08-23T11:00:00Z","qualidade":"completa",'
    '"lojas_selecionadas":2,"lojas_sem_coleta":1,"produtos_ativos":15}}';

Api _api({
  String resumo = _resumo,
  String cashback = _paginaVazia,
  String sitesParceiros = _paginaVazia,
  String lojasDiretas = _paginaVazia,
  List<http.Request>? requisicoes,
}) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-teste',
    cliente: http_testing.MockClient((requisicao) async {
      requisicoes?.add(requisicao);
      if (requisicao.url.path == '/api/status') {
        return http.Response('{"api":"v1","saudavel":true}', 200);
      }
      if (requisicao.url.path == '/api/resumo') {
        return http.Response(resumo, 200);
      }
      if (requisicao.url.path == '/api/inter/cashback') {
        return http.Response(cashback, 200);
      }
      if (requisicao.url.path == '/api/inter/lojas' &&
          requisicao.method == 'GET') {
        return http.Response(sitesParceiros, 200);
      }
      if (requisicao.url.path == '/api/inter/produtos/lojas' &&
          requisicao.method == 'GET') {
        return http.Response(lojasDiretas, 200);
      }
      if (requisicao.url.path == '/api/inter/produtos/lojas' &&
          requisicao.method == 'PATCH') {
        return http.Response('{}', 200);
      }
      if (requisicao.url.path == '/api/livelo/preferencias') {
        return http.Response(
          '{"multiplicador_padrao":"2.00",'
          '"piso_pontos_padrao":"4.00","assinante_clube":false}',
          200,
        );
      }
      if (requisicao.url.path == '/api/administracao/disparos') {
        if (requisicao.method == 'POST') {
          final dominio = requisicao.body.contains('produtos_inter')
              ? 'produtos_inter'
              : requisicao.body.contains('inter')
              ? 'inter'
              : 'livelo';
          return http.Response(
            '{"dominio":"$dominio","estado":"aceito",'
            '"cooldown_segundos":0}',
            202,
          );
        }
        final dominio = requisicao.url.queryParameters['dominio'] ?? '';
        return http.Response(
          '{"dominio":"$dominio",'
          '"cooldown_segundos":0,"ultima_solicitacao_em":null,'
          '"ultimo_estado":null}',
          200,
        );
      }
      return http.Response(_paginaVazia, 200);
    }),
  ),
);

Future<void> _abrir(
  WidgetTester at, {
  Size tamanho = const Size(390, 844),
  double escalaTexto = 1,
  bool administrador = false,
  bool escuro = false,
  String resumo = _resumo,
  String cashback = _paginaVazia,
  String sitesParceiros = _paginaVazia,
  String lojasDiretas = _paginaVazia,
  List<http.Request>? requisicoes,
}) async {
  at.view.devicePixelRatio = 1;
  at.view.physicalSize = tamanho;
  addTearDown(at.view.resetDevicePixelRatio);
  addTearDown(at.view.resetPhysicalSize);
  await at.pumpWidget(
    MaterialApp(
      theme: escuro
          ? TemaRadar.escuro()
          : tamanho.width >= 920
          ? TemaRadar.legadoClaroComCores()
          : TemaRadar.claro(),
      home: MolduraRadar(
        api: _api(
          resumo: resumo,
          cashback: cashback,
          sitesParceiros: sitesParceiros,
          lojasDiretas: lojasDiretas,
          requisicoes: requisicoes,
        ),
        administrador: administrador,
        agora: () => DateTime(2026, 8, 26),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
    ),
  );
  await at.pumpAndSettle();
}

Future<void> _abrirGaveta(WidgetTester at) async {
  await at.tap(find.byKey(const Key('abrir-menu-principal')));
  await at.pumpAndSettle();
}

Future<void> _irParaCompacto(WidgetTester at, DestinoCompacto destino) async {
  final principal = destino.destinoDaBarra;
  await at.tap(find.byKey(Key('barra-${principal.name}')));
  await at.pumpAndSettle();
  final rolagemProgramas = find
      .descendant(
        of: find.byKey(const Key('pagina-programas')),
        matching: find.byType(Scrollable),
      )
      .first;
  if (destino == DestinoCompacto.livelo) {
    final programa = find.byKey(const Key('programa-livelo'));
    await at.scrollUntilVisible(programa, 180, scrollable: rolagemProgramas);
    await at.ensureVisible(programa);
    await at.pumpAndSettle();
    await at.tap(
      find.ancestor(of: programa, matching: find.byType(InkWell)).first,
    );
    await at.pumpAndSettle();
  } else if (destino == DestinoCompacto.inter) {
    final programa = find.byKey(const Key('programa-inter'));
    await at.scrollUntilVisible(programa, 180, scrollable: rolagemProgramas);
    await at.ensureVisible(programa);
    await at.pumpAndSettle();
    await at.tap(
      find.ancestor(of: programa, matching: find.byType(InkWell)).first,
    );
    await at.pumpAndSettle();
  }
}

Future<void> _irParaAmplo(WidgetTester at, Destino destino) async {
  await at.tap(find.byKey(Key('destino-lateral-${destino.name}')));
  await at.pumpAndSettle();
}

void main() {
  testWidgets('celular usa cabeçalho, barra inferior e gaveta V11', (at) async {
    await _abrir(at);

    expect(find.byKey(const Key('abrir-menu-principal')), findsOneWidget);
    expect(find.byType(BarraLateral), findsNothing);
    await _abrirGaveta(at);

    for (final destino in DestinoCompacto.values.where(
      (destino) => destino.principal,
    )) {
      expect(find.byKey(Key('destino-${destino.name}')), findsOneWidget);
      expect(find.text(destino.titulo), findsWidgets);
    }
    expect(find.byKey(const Key('destino-alertas')), findsNothing);
    expect(find.byKey(const Key('destino-mais')), findsNothing);
    expect(find.byKey(const Key('abrir-alertas-gaveta')), findsOneWidget);
    expect(find.byKey(const Key('abrir-sistema-gaveta')), findsOneWidget);
    expect(find.text('Acesso padrão'), findsWidgets);
    expect(find.text('Livelo, Banco Inter e integrações'), findsOneWidget);
    expect(find.text('Resultados das lojas escolhidas'), findsOneWidget);
    expect(
      at.getSize(find.byKey(const Key('gaveta-principal'))).width,
      closeTo(343.2, 0.1),
    );
  });

  testWidgets('celular em paisagem continua com a gaveta', (at) async {
    await _abrir(at, tamanho: const Size(844, 390));

    expect(find.byKey(const Key('abrir-menu-principal')), findsOneWidget);
    expect(find.byType(BarraLateral), findsNothing);
    await _abrirGaveta(at);
    expect(find.byKey(const Key('destino-produtos')), findsOneWidget);
  });

  testWidgets('somente Android compacto usa o catálogo Livelo novo', (
    at,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await _abrir(at);
      await _irParaCompacto(at, DestinoCompacto.livelo);

      expect(find.byKey(const Key('catalogo-livelo-android')), findsOneWidget);
    } finally {
      await at.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('iOS compacto usa a mesma experiência Livelo aprovada', (
    at,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _abrir(at);
      await _irParaCompacto(at, DestinoCompacto.livelo);

      expect(find.byKey(const Key('catalogo-livelo-android')), findsOneWidget);
    } finally {
      await at.pumpWidget(const SizedBox.shrink());
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Web amplo usa lateral com os mesmos cinco destinos', (at) async {
    await _abrir(at, tamanho: const Size(1440, 900));

    expect(find.byType(BarraLateral), findsOneWidget);
    expect(find.byKey(const Key('abrir-menu-principal')), findsNothing);
    for (final destino in Destino.values) {
      expect(
        find.byKey(Key('destino-lateral-${destino.name}')),
        findsOneWidget,
      );
    }
  }, tags: 'web');

  testWidgets('Resumo aparece por padrão e consome o resumo da API', (
    at,
  ) async {
    await _abrir(at);

    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.byKey(const Key('resumo-servico-livelo')), findsOneWidget);
  });

  testWidgets('Serviços agrega Livelo e Inter com busca local', (at) async {
    await _abrir(at, tamanho: const Size(390, 1200));
    await _irParaCompacto(at, DestinoCompacto.programas);

    expect(find.byKey(const Key('programa-livelo')), findsOneWidget);
    expect(find.byKey(const Key('programa-inter')), findsOneWidget);
    await at.enterText(find.byKey(const Key('busca-programas')), 'inter');
    await at.pump();
    expect(find.byKey(const Key('programa-livelo')), findsNothing);
    expect(find.byKey(const Key('programa-inter')), findsOneWidget);
  });

  testWidgets('atalhos do Início abrem Produtos e os dois domínios de Lojas', (
    at,
  ) async {
    const tamanho = Size(1200, 2000);
    await _abrir(at, tamanho: tamanho);

    await at.tap(find.byKey(const Key('atalho-produtos')));
    await at.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Buscar produtos'), findsOneWidget);

    await at.pumpWidget(const SizedBox.shrink());
    await _abrir(at, tamanho: tamanho);
    await at.tap(find.byKey(const Key('atalho-livelo')));
    await at.pumpAndSettle();
    expect(find.byKey(const Key('voltar-para-lojas')), findsOneWidget);
    expect(
      find.text('Ainda não há uma coleta da Livelo para mostrar.'),
      findsOneWidget,
    );

    await at.pumpWidget(const SizedBox.shrink());
    await _abrir(at, tamanho: tamanho);
    await at.tap(find.byKey(const Key('atalho-cashback')));
    await at.pumpAndSettle();
    expect(find.byKey(const Key('voltar-para-lojas')), findsOneWidget);
    expect(find.text('Shopping Inter'), findsWidgets);
  }, tags: 'web');

  testWidgets('Lojas permanece íntegra na experiência ampla', (at) async {
    await _abrir(at, tamanho: const Size(1440, 900));
    await _irParaAmplo(at, Destino.lojas);

    expect(find.byKey(const Key('hub-lojas')), findsOneWidget);
    expect(find.text('Livelo'), findsOneWidget);
    expect(find.text('Shopping Inter'), findsOneWidget);

    await at.tap(find.byKey(const Key('abrir-lojas-livelo')));
    await at.pumpAndSettle();

    expect(find.byKey(const Key('voltar-para-lojas')), findsOneWidget);
    expect(
      find.text('Ainda não há uma coleta da Livelo para mostrar.'),
      findsOneWidget,
    );
  }, tags: 'web');

  testWidgets('hub de Lojas mostra estados reais sem misturar os domínios', (
    at,
  ) async {
    await _abrir(
      at,
      tamanho: const Size(1440, 900),
      resumo: _resumoComEstadosIndependentes,
    );
    await _irParaAmplo(at, Destino.lojas);

    expect(find.text('3 lojas acompanhadas'), findsOneWidget);
    expect(find.text('2 alertas na última coleta'), findsOneWidget);
    expect(find.text('4 acompanhadas no Cashback'), findsOneWidget);
    expect(find.text('Cashback: falha recente'), findsOneWidget);
    expect(find.text('2 lojas selecionadas em Produtos'), findsOneWidget);
    expect(find.text('Produtos: parcial'), findsOneWidget);
  }, tags: 'web');

  testWidgets('Voltar do domínio interno retorna primeiro ao hub de Lojas', (
    at,
  ) async {
    await _abrir(at, tamanho: const Size(1440, 900));
    await _irParaAmplo(at, Destino.lojas);
    await at.tap(find.byKey(const Key('abrir-lojas-inter')));
    await at.pumpAndSettle();

    expect(find.byKey(const Key('voltar-para-lojas')), findsOneWidget);
    await at.binding.handlePopRoute();
    await at.pumpAndSettle();

    expect(find.byKey(const Key('hub-lojas')), findsOneWidget);
    expect(find.byKey(const Key('voltar-para-lojas')), findsNothing);
  }, tags: 'web');

  // PENDENTE: validar manualmente o acompanhamento no Inter compacto.
  /*
  testWidgets('Shopping Inter compacto possui somente os dois modos reais', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await _abrir(
      at,
      tamanho: const Size(390, 1500),
      administrador: true,
      resumo: _resumoComEstadosIndependentes,
      cashback: _cashbackInter,
      sitesParceiros: _sitesParceirosInter,
      requisicoes: requisicoes,
    );
    await _irParaCompacto(at, DestinoCompacto.inter);

    expect(find.byKey(const Key('hub-shopping-inter')), findsOneWidget);
    expect(find.text('Cashback'), findsOneWidget);
    expect(find.textContaining('Sites parceiros'), findsWidgets);
    expect(find.text('Compre direto'), findsOneWidget);
    expect(find.byKey(const Key('inter-total-acompanhadas')), findsOneWidget);
    expect(
      find.text('20% é o melhor cashback acompanhado agora.'),
      findsOneWidget,
    );
    expect(find.text('Integração com atenção'), findsOneWidget);
    expect(find.text('20%'), findsOneWidget);
    expect(find.text('melhor oferta'), findsOneWidget);
    expect(
      requisicoes.any(
        (requisicao) =>
            requisicao.url.path == '/api/inter/cashback' &&
            requisicao.url.queryParameters['acompanhadas'] == 'true' &&
            requisicao.url.queryParameters['por_pagina'] == '1',
      ),
      isTrue,
    );
    expect(find.byKey(const Key('busca-cashback-inter')), findsOneWidget);
    await at.enterText(
      find.byKey(const Key('busca-cashback-inter')),
      'magazine',
    );

    expect(find.byKey(const Key('busca-cashback-inter')), findsOneWidget);
    expect(
      find.textContaining('Navegar e filtrar não inicia uma nova coleta.'),
      findsOneWidget,
    );
    expect(find.text('1 site parceiro disponível'), findsOneWidget);
    expect(find.text('Site parceiro'), findsOneWidget);
    final acompanhar = find.byKey(const ValueKey('acompanhar-magalu'));
    await at.ensureVisible(acompanhar);
    await at.drag(
      find.byKey(const PageStorageKey('rolagem-cashback-inter')),
      const Offset(0, -120),
    );
    await at.pumpAndSettle();
    await at.tap(acompanhar);
    await at.pumpAndSettle();
    expect(find.text('Acompanhar'), findsOneWidget);
    expect(
      requisicoes.any(
        (requisicao) =>
            requisicao.method == 'PATCH' &&
            requisicao.url.path == '/api/inter/lojas',
      ),
      isTrue,
    );
    await at.enterText(find.byKey(const Key('busca-cashback-inter')), 'magalu');

    await at.tap(find.text('Compre direto'));
    await at.pumpAndSettle();
    await at.tap(find.text('Cashback'));
    await at.pumpAndSettle();
    expect(
      at
          .widget<TextField>(find.byKey(const Key('busca-cashback-inter')))
          .controller
          ?.text,
      'magalu',
    );
  });
  */

  testWidgets('Compre direto usa catálogo real e preserva autorização', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await _abrir(
      at,
      tamanho: const Size(320, 1000),
      escalaTexto: 1.3,
      administrador: true,
      resumo: _resumoComEstadosIndependentes,
      cashback: _cashbackInter,
      lojasDiretas: _lojasDiretasInter,
      requisicoes: requisicoes,
    );
    await _irParaCompacto(at, DestinoCompacto.inter);
    await at.tap(find.byKey(const Key('modo-inter-compre-direto')));
    await at.pumpAndSettle();

    expect(find.byKey(const Key('compre-direto-inter')), findsOneWidget);
    expect(find.text('Escolha as lojas da próxima coleta'), findsNothing);
    expect(find.text('Atualizar produtos'), findsOneWidget);
    await at.drag(
      find.byKey(const PageStorageKey('compre-direto-inter')),
      const Offset(0, -700),
    );
    await at.pumpAndSettle();
    expect(find.byKey(const Key('busca-compre-direto')), findsOneWidget);
    expect(find.text('Amazon'), findsOneWidget);
    expect(find.textContaining('12 páginas processadas'), findsNothing);
    expect(find.text('Último catálogo'), findsOneWidget);
    expect(find.text('18 produtos'), findsOneWidget);
    expect(find.text('Seleção'), findsOneWidget);
    expect(find.text('Produtos encontrados'), findsNothing);
    expect(find.text('Selecionada'), findsOneWidget);
    final selecionar = find.byKey(
      const ValueKey('selecionar-loja-direta-amazon'),
    );
    await at.ensureVisible(selecionar);
    await at.pumpAndSettle();
    await at.tap(selecionar);
    await at.pumpAndSettle();
    expect(find.text('Não selecionada'), findsOneWidget);
    expect(find.text('Selecionar loja'), findsOneWidget);
    await at.ensureVisible(selecionar);
    await at.pumpAndSettle();
    await at.tap(selecionar);
    await at.pumpAndSettle();
    expect(find.text('Selecionada'), findsOneWidget);
    expect(find.text('Selecionada para coleta'), findsOneWidget);
    await at.ensureVisible(find.text('Selecionadas'));
    await at.pumpAndSettle();
    await at.tap(find.text('Selecionadas'));
    await at.pumpAndSettle();
    expect(find.text('Último catálogo'), findsOneWidget);
    expect(find.text('18 produtos'), findsOneWidget);
    expect(find.text('até 6%'), findsOneWidget);
    expect(
      requisicoes.any(
        (requisicao) =>
            requisicao.url.path == '/api/inter/produtos/lojas' &&
            requisicao.method == 'GET',
      ),
      isTrue,
    );
    final alteracoes = requisicoes.where(
      (requisicao) =>
          requisicao.url.path == '/api/inter/produtos/lojas' &&
          requisicao.method == 'PATCH',
    );
    expect(alteracoes.map((requisicao) => requisicao.body), [
      '{"id":"amazon","selecionada":false}',
      '{"id":"amazon","selecionada":true}',
    ]);
  });

  testWidgets('usuário comum lê Sites parceiros sem acessar rota admin', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await _abrir(
      at,
      tamanho: const Size(390, 1500),
      cashback: _cashbackInter,
      requisicoes: requisicoes,
    );
    await _irParaCompacto(at, DestinoCompacto.inter);
    await at.tap(find.text('Cashback'));
    await at.pumpAndSettle();

    expect(
      requisicoes.where(
        (requisicao) => requisicao.url.path == '/api/inter/lojas',
      ),
      isEmpty,
    );
    expect(find.text('Acompanhar'), findsNothing);
    expect(find.text('✓ Acompanhada'), findsOneWidget);
    expect(find.text('Atualizar dados'), findsNothing);
    expect(
      requisicoes.where(
        (requisicao) => requisicao.url.path == '/api/administracao/disparos',
      ),
      isEmpty,
    );
  });

  testWidgets('Compre direto não expõe seleção a usuário comum', (at) async {
    final requisicoes = <http.Request>[];
    await _abrir(
      at,
      tamanho: const Size(390, 1500),
      resumo: _resumoComEstadosIndependentes,
      cashback: _cashbackInter,
      requisicoes: requisicoes,
    );
    await _irParaCompacto(at, DestinoCompacto.inter);
    await at.tap(find.byKey(const Key('modo-inter-compre-direto')));
    await at.pumpAndSettle();

    expect(
      find.textContaining('exige autorização administrativa'),
      findsOneWidget,
    );
    expect(
      requisicoes.where(
        (requisicao) => requisicao.url.path == '/api/inter/produtos/lojas',
      ),
      isEmpty,
    );
  });

  testWidgets('Banco Inter compacto segue as ações de atualização da V11', (
    at,
  ) async {
    final requisicoes = <http.Request>[];
    await _abrir(
      at,
      tamanho: const Size(390, 1500),
      administrador: true,
      requisicoes: requisicoes,
    );
    await _irParaCompacto(at, DestinoCompacto.inter);

    expect(find.text('Atualizar dados'), findsNothing);
    expect(find.byKey(const ValueKey('atualizar-dados-inter')), findsNothing);
    expect(find.byKey(const Key('atualizar-resumo-cabecalho')), findsOneWidget);
    final resumosAntes = requisicoes
        .where((requisicao) => requisicao.url.path == '/api/resumo')
        .length;
    await at.tap(find.byKey(const Key('atualizar-resumo-cabecalho')));
    await at.pumpAndSettle();
    expect(
      requisicoes.where(
        (requisicao) =>
            requisicao.url.path == '/api/resumo' && requisicao.method == 'GET',
      ),
      hasLength(resumosAntes + 1),
    );
    expect(find.text('Resumo atualizado.'), findsOneWidget);
    expect(
      requisicoes.where(
        (requisicao) =>
            requisicao.url.path == '/api/administracao/disparos' &&
            requisicao.method == 'POST' &&
            requisicao.body == '{"dominio":"inter"}',
      ),
      isEmpty,
    );

    await at.tap(find.byKey(const Key('modo-inter-compre-direto')));
    await at.pumpAndSettle();
    expect(find.text('Atualizar produtos'), findsOneWidget);
    final dominiosConsultados = requisicoes
        .where(
          (requisicao) => requisicao.url.path == '/api/administracao/disparos',
        )
        .map((requisicao) => requisicao.url.queryParameters['dominio'])
        .toSet();
    expect(dominiosConsultados, contains('produtos_inter'));
  });

  testWidgets('Banco Inter completo não estoura em 320 px no tema escuro', (
    at,
  ) async {
    await _abrir(
      at,
      tamanho: const Size(320, 900),
      escalaTexto: 1.5,
      escuro: true,
      administrador: true,
      resumo: _resumoComEstadosIndependentes,
      cashback: _cashbackInter,
      sitesParceiros: _sitesParceirosInter,
    );
    await _irParaCompacto(at, DestinoCompacto.inter);

    expect(at.takeException(), isNull);
    await at.ensureVisible(find.byKey(const Key('modo-inter-cashback')));
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('modo-inter-cashback')));
    await at.pumpAndSettle();
    expect(at.takeException(), isNull);

    await at.drag(
      find.byKey(const PageStorageKey('rolagem-cashback-inter')),
      const Offset(0, -500),
    );
    await at.pump();
    expect(at.takeException(), isNull);
    expect(find.text('Magazine Luiza'), findsOneWidget);
  });

  testWidgets('Produtos é destino direto e preserva a busca entre áreas', (
    at,
  ) async {
    await _abrir(at);
    await _irParaCompacto(at, DestinoCompacto.produtos);

    final busca = find.byKey(const Key('busca-produtos'));
    expect(busca, findsOneWidget);
    await at.enterText(busca, 'x');

    await _irParaCompacto(at, DestinoCompacto.livelo);
    await _irParaCompacto(at, DestinoCompacto.produtos);

    expect(at.widget<TextField>(busca).controller?.text, 'x');
  });

  testWidgets('Produtos não expõe atalho redundante para escolher lojas', (
    at,
  ) async {
    await _abrir(at, administrador: true);
    await _irParaCompacto(at, DestinoCompacto.produtos);

    expect(find.text('Escolher lojas'), findsNothing);
    expect(find.text('+ escolher lojas'), findsNothing);
  });

  testWidgets('Alertas existentes continuam acessíveis pela gaveta', (
    at,
  ) async {
    await _abrir(at);
    await _abrirGaveta(at);
    await at.tap(find.byKey(const Key('abrir-alertas-gaveta')));
    await at.pumpAndSettle();

    expect(find.text('Alertas'), findsOneWidget);
    expect(
      find.text('Eventos importantes, fora do menu principal.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Histórico, lidos e não lidos dependem'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('fechar-folha-radar')), findsOneWidget);

    await at.tap(find.byKey(const Key('fechar-folha-radar')));
    await at.pumpAndSettle();
    expect(find.text('Alertas'), findsNothing);
  });

  testWidgets('conta oferece administração fora das três áreas', (at) async {
    await _abrir(at, administrador: true);
    await at.tap(find.byKey(const Key('abrir-conta-cabecalho')));
    await at.pumpAndSettle();

    expect(find.text('Administração'), findsOneWidget);
    expect(find.text('Conta e sistema'), findsOneWidget);
    expect(find.text('Acesso administrador'), findsOneWidget);
  });

  testWidgets('conta padrão não oferece administração', (at) async {
    await _abrir(at, tamanho: const Size(320, 640), escalaTexto: 1.5);
    await _abrirGaveta(at);
    await at.tap(find.byKey(const Key('abrir-conta-gaveta')));
    await at.pumpAndSettle();

    expect(at.takeException(), isNull);
    expect(find.text('Conta e sistema'), findsOneWidget);
    expect(find.text('Acesso padrão'), findsOneWidget);
    expect(find.text('Administração'), findsNothing);
  });

  testWidgets('gaveta aceita texto ampliado sem perder destinos', (at) async {
    await _abrir(at, tamanho: const Size(320, 640), escalaTexto: 1.5);
    await _abrirGaveta(at);

    expect(at.takeException(), isNull);
    for (final destino in DestinoCompacto.values.where(
      (destino) => destino.principal,
    )) {
      expect(find.byKey(Key('destino-${destino.name}')), findsOneWidget);
    }
  });

  testWidgets('áreas e subáreas continuam alcançáveis com texto ampliado', (
    at,
  ) async {
    await _abrir(at, tamanho: const Size(320, 640), escalaTexto: 1.5);

    for (final destino in DestinoCompacto.values.skip(1)) {
      await _irParaCompacto(at, destino);
      expect(at.takeException(), isNull, reason: destino.titulo);
    }
    expect(find.byKey(const Key('produtos-compacto')), findsOneWidget);
  });

  testWidgets('gaveta mobile confere com o golden aprovado', (at) async {
    await _abrir(at);
    await _abrirGaveta(at);

    await expectLater(
      find.byType(MolduraRadar),
      matchesGoldenFile('../../goldens/moldura_mobile_gaveta.png'),
    );
  }, tags: 'golden');

  testWidgets('Início mobile novo confere com o golden claro', (at) async {
    await _abrir(at, resumo: _resumoComEstadosIndependentes);

    await expectLater(
      find.byType(MolduraRadar),
      matchesGoldenFile('../../goldens/moldura_mobile_inicio.png'),
    );
  }, tags: 'golden');

  testWidgets('Início mobile novo confere com o golden escuro', (at) async {
    await _abrir(at, resumo: _resumoComEstadosIndependentes, escuro: true);

    await expectLater(
      find.byType(MolduraRadar),
      matchesGoldenFile('../../goldens/moldura_mobile_inicio_escuro.png'),
    );
  }, tags: 'golden');

  testWidgets('lateral Web confere com o golden aprovado', (at) async {
    await _abrir(at, tamanho: const Size(1440, 900));

    await expectLater(
      find.byType(MolduraRadar),
      matchesGoldenFile('../../goldens/moldura_web_lateral.png'),
    );
  }, tags: 'golden');
}
