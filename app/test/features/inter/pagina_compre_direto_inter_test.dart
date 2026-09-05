import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/administracao/controlador_catalogo_administracao.dart';
import 'package:app_robo/features/inter/controlador_categorias_acompanhadas.dart';
import 'package:app_robo/features/inter/pagina_compre_direto_inter.dart';

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    cliente: http_testing.MockClient((_) async => http.Response('{}', 500)),
  ),
);

LojaDireto _loja({
  String id = 'amazon',
  String nome = 'Amazon',
  int? produtos = 18,
  String? cashback = 'Até 6% de cashback',
  String estado = 'sucesso',
}) => LojaDireto(
  id: id,
  idExterno: '1',
  slug: id,
  nome: nome,
  selecionada: true,
  ativa: true,
  ultimaExecucao: '2026-08-23T11:00:00Z',
  ultimoEstado: estado,
  paginas: 12,
  ultimaTentativaEm: '2026-08-30T12:00:00Z',
  ultimaTentativaEstado: estado,
  ultimaColetaSucessoEm: '2026-08-23T11:00:00Z',
  produtosEncontrados: produtos,
  cashbackResumoTexto: cashback,
);

Pagina<LojaDireto> _pagina() => Pagina(
  itens: [_loja()],
  pagina: 1,
  porPagina: 20,
  totalItens: 1,
  totalPaginas: 1,
  temProxima: false,
);

CatalogoCategoriasInterUsuario _categorias({bool selecionada = false}) =>
    CatalogoCategoriasInterUsuario(
      configurada: selecionada,
      itens: [
        CategoriaInter(
          valor: 'Eletrônicos',
          nome: 'Eletrônicos',
          selecionada: selecionada,
        ),
        const CategoriaInter(valor: 'Cabos', nome: 'Cabos', selecionada: false),
        const CategoriaInter(
          valor: null,
          nome: 'Sem categoria',
          selecionada: false,
        ),
      ],
    );

void main() {
  testWidgets('duas abas mostram o último catálogo e a seleção nos cards', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(320, 800);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorCatalogoAdministracao<LojaDireto>(
      buscar: ({required q, required pagina}) async => _pagina(),
      identificar: (loja) => loja.id,
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.escuro(),
        home: Scaffold(
          body: PaginaCompreDiretoInter(
            api: _api(),
            administrador: true,
            sliversAntes: const [],
            controlador: controlador,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Maior cashback'), findsNothing);
    expect(find.text('Selecionadas'), findsOneWidget);
    expect(find.text('Disponíveis para seleção'), findsOneWidget);
    expect(find.text('até 6%'), findsOneWidget);
    expect(find.text('Último catálogo'), findsOneWidget);
    expect(find.text('18 produtos'), findsOneWidget);
    expect(find.text('Seleção'), findsOneWidget);
    expect(find.text('Selecionada'), findsOneWidget);
    expect(find.text('Selecionada para coleta'), findsOneWidget);
    expect(find.text('Produtos encontrados'), findsNothing);
    expect(find.text('Último snapshot válido'), findsNothing);
    await at.ensureVisible(find.text('Selecionadas'));
    await at.pumpAndSettle();
    await at.tap(find.text('Selecionadas'));
    await at.pumpAndSettle();
    expect(find.text('Selecionadas para a próxima coleta'), findsOneWidget);
    expect(find.text('Último catálogo'), findsOneWidget);
    expect(find.text('18 produtos'), findsOneWidget);
    expect(find.text('Selecionada para coleta'), findsOneWidget);
    expect(find.text('até 6%'), findsOneWidget);
    expect(at.takeException(), isNull);
  });

  testWidgets('ausência de snapshot e coleta vazia permanecem diferentes', (
    at,
  ) async {
    final controlador = ControladorCatalogoAdministracao<LojaDireto>(
      buscar: ({required q, required pagina}) async => Pagina(
        itens: [
          _loja(id: 'sem', nome: 'Sem coleta', produtos: null, cashback: null),
          _loja(id: 'vazia', nome: 'Coleta vazia', produtos: 0, cashback: null),
        ],
        pagina: 1,
        porPagina: 20,
        totalItens: 2,
        totalPaginas: 1,
        temProxima: false,
      ),
      identificar: (loja) => loja.id,
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaCompreDiretoInter(
            api: _api(),
            administrador: true,
            sliversAntes: const [],
            controlador: controlador,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();
    expect(find.text('Após a primeira coleta'), findsOneWidget);
    expect(find.text('0 produtos'), findsOneWidget);
    expect(find.text('Disponível'), findsNWidgets(2));
    expect(find.text('Cashback indisponível'), findsNothing);
  });

  testWidgets('filtro real é enviado à API antes da paginação', (at) async {
    final consultas = <Uri>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          consultas.add(requisicao.url);
          return http.Response(
            jsonEncode({
              'itens': [
                {
                  'id': 'amazon',
                  'id_externo': '1',
                  'slug': 'amazon',
                  'nome': 'Amazon',
                  'selecionada': true,
                  'ativa': true,
                  'ultima_tentativa_estado': 'sucesso',
                  'ultima_coleta_sucesso_em': '2026-08-23T11:00:00Z',
                  'produtos_encontrados': 18,
                  'cashback_resumo_texto': 'Até 6% de cashback',
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
        }),
      ),
    );

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaCompreDiretoInter(
            api: api,
            administrador: true,
            sliversAntes: const [],
          ),
        ),
      ),
    );
    await at.pumpAndSettle();
    await at.tap(find.text('Selecionadas'));
    await at.pumpAndSettle();

    final consultasLojas = consultas
        .where((uri) => uri.path == '/api/inter/produtos/lojas')
        .toList();
    expect(consultasLojas[0].queryParameters['ordenar'], 'nome');
    expect(consultasLojas[0].queryParameters['filtro'], 'todas');
    expect(consultasLojas[0].queryParameters['por_pagina'], '10');
    expect(consultasLojas[1].queryParameters['ordenar'], 'nome');
    expect(consultasLojas[1].queryParameters['filtro'], 'acompanhadas');
    expect(consultasLojas[1].queryParameters['por_pagina'], '10');
  });

  testWidgets('puxar e voltar ao app atualizam as lojas do Compre direto', (
    at,
  ) async {
    var consultas = 0;
    var atualizacoesResumo = 0;
    final controlador = ControladorCatalogoAdministracao<LojaDireto>(
      buscar: ({required q, required pagina}) async {
        consultas++;
        return _pagina();
      },
      identificar: (loja) => loja.id,
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaCompreDiretoInter(
            api: _api(),
            administrador: true,
            sliversAntes: const [],
            controlador: controlador,
            aoAtualizar: () async => atualizacoesResumo++,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();
    expect(consultas, 1);

    await at.drag(
      find.byKey(const PageStorageKey('compre-direto-inter')),
      const Offset(0, 360),
    );
    await at.pumpAndSettle();
    expect(consultas, 2);
    expect(atualizacoesResumo, 1);

    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    at.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await at.pumpAndSettle();
    expect(consultas, 3);
    expect(atualizacoesResumo, 2);
  });

  testWidgets('configura categorias sem alterar a seleção de lojas', (
    at,
  ) async {
    Set<String?>? salvas;
    final categorias = ControladorCategoriasAcompanhadas(
      carregar: () async => _categorias(),
      salvar: (valores, {required semCategoria}) async {
        salvas = <String?>{...valores, if (semCategoria) null};
        return _categorias(selecionada: true);
      },
    );
    final lojas = ControladorCatalogoAdministracao<LojaDireto>(
      buscar: ({required q, required pagina}) async => _pagina(),
      identificar: (loja) => loja.id,
    );
    addTearDown(categorias.dispose);
    addTearDown(lojas.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaCompreDiretoInter(
            api: _api(),
            administrador: true,
            sliversAntes: const [],
            controlador: lojas,
            controladorCategorias: categorias,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();

    expect(find.text('Categorias acompanhadas'), findsOneWidget);
    await at.tap(find.byKey(const Key('configurar-categorias-acompanhadas')));
    await at.pumpAndSettle();
    await at.tap(find.text('Eletrônicos').last);
    await at.tap(find.byKey(const Key('confirmar-acompanhar')));
    await at.pumpAndSettle();

    expect(salvas, {'Eletrônicos'});
    expect(lojas.itens.single.selecionada, isTrue);
  });

  testWidgets('cancelar categorias não persiste seleção transitória', (
    at,
  ) async {
    var salvamentos = 0;
    final categorias = ControladorCategoriasAcompanhadas(
      carregar: () async => _categorias(),
      salvar: (_, {required semCategoria}) async {
        salvamentos++;
        return _categorias();
      },
    );
    final lojas = ControladorCatalogoAdministracao<LojaDireto>(
      buscar: ({required q, required pagina}) async => _pagina(),
      identificar: (loja) => loja.id,
    );
    addTearDown(categorias.dispose);
    addTearDown(lojas.dispose);

    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: PaginaCompreDiretoInter(
            api: _api(),
            administrador: true,
            sliversAntes: const [],
            controlador: lojas,
            controladorCategorias: categorias,
          ),
        ),
      ),
    );
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('configurar-categorias-acompanhadas')));
    await at.pumpAndSettle();
    await at.tap(find.text('Eletrônicos').last);
    await at.tap(find.text('Cancelar'));
    await at.pumpAndSettle();

    expect(salvamentos, 0);
    expect(categorias.valoresSelecionados, isEmpty);
  });
}
