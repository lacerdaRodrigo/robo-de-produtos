import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/componentes/fundacao_visual.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/livelo/controlador_painel_livelo.dart';
import 'package:app_robo/features/livelo/pagina_painel_livelo.dart';

PontuacaoLivelo _loja({
  String nome = 'Casas Bahia',
  bool alerta = false,
  String? pontos = '2.90',
  String? descricao = 'Condições válidas para compras selecionadas.',
}) => PontuacaoLivelo(
  nome: nome,
  categoria: 'Marketplace',
  pontosAtuais: pontos,
  pontosBase: pontos == null ? null : '1.00',
  pontosClube: pontos == null ? null : '3.00',
  valorDeDisparo: pontos == null ? null : '4.00',
  moeda: 'R\$',
  prefixoAte: true,
  emPromocao: true,
  alertou: alerta,
  campanha: 'PROMOTION_CLUB',
  descricaoCampanha: descricao,
  fimPromocao: '2026-08-22T23:59:00Z',
);

Pagina<PontuacaoLivelo> _pagina(
  List<PontuacaoLivelo> itens, {
  int total = 1,
  int porPagina = 20,
  bool proxima = false,
  String? atualizadaEm = '2026-08-22T12:00:00Z',
}) => Pagina<PontuacaoLivelo>(
  itens: itens,
  pagina: 1,
  porPagina: porPagina,
  totalItens: total,
  totalPaginas: proxima ? 2 : 1,
  temProxima: proxima,
  atualizadoEm: atualizadaEm,
);

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    cliente: http_testing.MockClient((_) async => http.Response('{}', 500)),
  ),
);

Widget _tela(ControladorPainelLivelo controlador) => MaterialApp(
  theme: TemaRadar.claro(),
  home: Scaffold(
    body: PaginaPainelLivelo(api: _api(), controlador: controlador),
  ),
);

void main() {
  testWidgets('mostra carregamento e depois o cartão completo', (at) async {
    final resposta = Completer<Pagina<PontuacaoLivelo>>();
    final controlador = ControladorPainelLivelo(
      buscar: ({required q, required ordenar, required pagina}) =>
          resposta.future,
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    expect(find.text('Carregando painel Livelo…'), findsOneWidget);

    resposta.complete(_pagina([_loja(alerta: true)]));
    await at.pumpAndSettle();

    expect(find.byType(CampoBuscaRadar), findsOneWidget);
    expect(find.text('Casas Bahia'), findsOneWidget);
    expect(find.text('2,9 pontos por R\$ 1'), findsOneWidget);
    expect(find.text('Alerta ativo'), findsOneWidget);
    expect(find.text('Condições da campanha'), findsOneWidget);
  });

  testWidgets('distingue falha, nenhuma coleta, catálogo vazio e busca vazia', (
    at,
  ) async {
    var chamadas = 0;
    final controlador = ControladorPainelLivelo(
      debounce: Duration.zero,
      buscar: ({required q, required ordenar, required pagina}) async {
        chamadas++;
        if (chamadas == 1) throw StateError('falhou');
        if (chamadas == 2) return _pagina([], atualizadaEm: null, total: 0);
        if (chamadas == 3) return _pagina([], total: 0);
        return _pagina([], total: 0);
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar o painel Livelo.'),
      findsOneWidget,
    );

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    expect(
      find.text('Ainda não há uma coleta da Livelo para mostrar.'),
      findsOneWidget,
    );

    await controlador.tentarNovamente();
    await at.pumpAndSettle();
    expect(find.text('Nenhuma loja está cadastrada ainda.'), findsOneWidget);

    await at.enterText(find.byType(TextField), 'inexistente');
    await at.pumpAndSettle();
    expect(
      find.text('Nenhuma loja encontrada para “inexistente”.'),
      findsOneWidget,
    );
  });

  testWidgets('mostra atraso, loja ausente, filtros e paginação manual', (
    at,
  ) async {
    var paginaPedida = 0;
    final controlador = ControladorPainelLivelo(
      buscar: ({required q, required ordenar, required pagina}) async {
        paginaPedida++;
        if (pagina == 1) {
          return _pagina(
            [_loja(nome: 'Ausente', pontos: null)],
            total: 11,
            porPagina: 10,
            proxima: true,
            atualizadaEm: '2020-01-01T00:00:00Z',
          );
        }
        return Pagina<PontuacaoLivelo>(
          itens: [_loja(nome: 'Renner')],
          pagina: 2,
          porPagina: 10,
          totalItens: 11,
          totalPaginas: 2,
          temProxima: false,
          atualizadoEm: '2020-01-01T00:00:00Z',
        );
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();

    expect(find.textContaining('dados atrasados'), findsOneWidget);
    expect(find.text('Não encontrada na última coleta'), findsOneWidget);
    expect(find.byKey(const Key('paginacao-radar-2')), findsOneWidget);
    expect(find.text('Maior pontuação'), findsOneWidget);
    expect(find.text('Em alerta'), findsOneWidget);
    expect(find.text('Nome A–Z'), findsOneWidget);

    await at.ensureVisible(find.byKey(const Key('paginacao-radar-2')));
    await at.tap(find.byKey(const Key('paginacao-radar-2')));
    await at.pumpAndSettle();
    expect(find.text('Renner'), findsOneWidget);
    expect(controlador.temProxima, isFalse);
    expect(paginaPedida, 2);
  });

  testWidgets('tela larga mantém cartões em duas colunas', (at) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(1100, 800);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    final controlador = ControladorPainelLivelo(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina([_loja(nome: 'Renner'), _loja(nome: 'Petz')], total: 2),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();

    expect(find.text('Renner'), findsOneWidget);
    expect(find.text('Petz'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
  });
}
