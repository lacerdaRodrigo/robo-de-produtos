import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/inter/cartao_cashback_inter.dart';
import 'package:app_robo/features/inter/controlador_cashback_inter.dart';
import 'package:app_robo/features/inter/pagina_cashback_inter.dart';

CashbackInter _loja({
  String nome = 'Magazine Luiza',
  bool encontrada = true,
  bool favorita = false,
  String? secundaria = '2% de cashback',
}) => CashbackInter(
  id: nome.toLowerCase(),
  slug: nome.toLowerCase(),
  nome: nome,
  cashbackPrincipalTexto: 'Até 12% de cashback',
  cashbackPrincipalValor: '12.00',
  cashbackSecundarioTexto: secundaria,
  cashbackSecundarioValor: secundaria == null ? null : '2.00',
  etiqueta: 'Oferta especial',
  descricaoPrincipal: 'Em itens selecionados',
  descricaoSecundaria: secundaria == null ? null : 'Para não-correntistas',
  encontrada: encontrada,
  favorita: favorita,
);

Pagina<CashbackInter> _pagina(
  List<CashbackInter> itens, {
  int? total,
  bool proxima = false,
  String? atualizadaEm = '2026-08-22T12:00:00Z',
  String? ultimaTentativaEstado,
}) => Pagina(
  itens: itens,
  pagina: 1,
  porPagina: 20,
  totalItens: total ?? itens.length,
  totalPaginas: proxima ? 2 : 1,
  temProxima: proxima,
  atualizadoEm: atualizadaEm,
  ultimaTentativaEstado: ultimaTentativaEstado,
);

Api _api() => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    cliente: http_testing.MockClient((_) async => http.Response('{}', 500)),
  ),
);

Widget _tela(ControladorCashbackInter controlador) => MaterialApp(
  theme: TemaRadar.claro(),
  home: Scaffold(
    body: PaginaCashbackInter(api: _api(), controlador: controlador),
  ),
);

Widget _telaCompacta(ControladorCashbackInter controlador) => MaterialApp(
  theme: TemaRadar.claro(),
  home: Scaffold(
    body: PaginaCashbackInter(
      api: _api(),
      controlador: controlador,
      incorporada: true,
    ),
  ),
);

void main() {
  testWidgets('mostra carregamento, filtros, cartão e condições secundárias', (
    at,
  ) async {
    final resposta = Completer<Pagina<CashbackInter>>();
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) =>
          resposta.future,
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    expect(find.text('Carregando cashback do Inter…'), findsOneWidget);

    resposta.complete(_pagina([_loja()]));
    await at.pumpAndSettle();

    expect(find.text('Maior cashback'), findsOneWidget);
    expect(find.text('Nome A–Z'), findsOneWidget);
    expect(find.text('Magazine Luiza'), findsOneWidget);
    expect(find.text('Até 12% de cashback'), findsOneWidget);
    expect(find.text('Cliente Inter Shopping'), findsOneWidget);
    expect(find.text('Oferta especial'), findsOneWidget);
    expect(find.text('Não-correntista'), findsOneWidget);
    await at.tap(find.text('Não-correntista'));
    await at.pumpAndSettle();
    expect(find.textContaining('Para não-correntistas'), findsOneWidget);
    expect(controlador.temProxima, isFalse);
  });

  testWidgets('separa falha recente, atraso e loja ausente', (at) async {
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina(
            [_loja(nome: 'Loja ausente', encontrada: false, secundaria: null)],
            atualizadaEm: '2020-01-01T00:00:00Z',
            ultimaTentativaEstado: 'falha',
          ),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();

    expect(find.textContaining('dados atrasados'), findsOneWidget);
    expect(
      find.text(
        'A última sincronização do Inter falhou. Exibindo a última coleta válida.',
      ),
      findsOneWidget,
    );
    expect(find.text('Não encontrada na última coleta'), findsOneWidget);
  });

  testWidgets(
    'Cashback compacto mostra o catálogo inteiro e filtra acompanhadas',
    (at) async {
      final controlador = ControladorCashbackInter(
        buscar: ({required q, required ordenar, required pagina}) async =>
            _pagina([
              _loja(nome: 'Animale'),
              _loja(nome: 'Aramis', favorita: true),
            ]),
      );
      addTearDown(controlador.dispose);

      await at.pumpWidget(_telaCompacta(controlador));
      await at.pumpAndSettle();

      expect(find.text('Animale'), findsOneWidget);
      expect(find.text('Aramis'), findsOneWidget);

      await at.tap(find.text('Acompanhadas'));
      await at.pumpAndSettle();

      expect(find.text('Animale'), findsNothing);
      expect(find.text('Aramis'), findsOneWidget);
      expect(find.text('Acompanhada'), findsOneWidget);
    },
  );

  testWidgets('distingue falha sem retrato, sem coleta e busca vazia', (
    at,
  ) async {
    var chamadas = 0;
    final controlador = ControladorCashbackInter(
      debounce: Duration.zero,
      buscar: ({required q, required ordenar, required pagina}) async {
        chamadas++;
        if (chamadas == 1) {
          return _pagina(
            [],
            atualizadaEm: null,
            ultimaTentativaEstado: 'falha',
          );
        }
        if (chamadas == 2) return _pagina([], atualizadaEm: null);
        return _pagina([], total: 0);
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();
    expect(
      find.text(
        'A última sincronização do Inter falhou. Ainda não há dados válidos para mostrar.',
      ),
      findsOneWidget,
    );

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    expect(find.text('O Inter ainda não foi sincronizado.'), findsOneWidget);

    await controlador.tentarNovamente();
    await at.pumpAndSettle();
    await at.enterText(find.byType(TextField), 'inexistente');
    await at.pumpAndSettle();
    expect(
      find.text('Nenhuma loja encontrada para “inexistente”.'),
      findsOneWidget,
    );
  });

  testWidgets('cartão ausente não se transforma em cashback zero', (at) async {
    await at.pumpWidget(
      MaterialApp(
        theme: TemaRadar.claro(),
        home: Scaffold(
          body: CartaoCashbackInter(loja: _loja(encontrada: false)),
        ),
      ),
    );

    expect(find.text('Não encontrada na última coleta'), findsOneWidget);
    expect(
      find.text('A loja continua acompanhada; a fonte não a retornou.'),
      findsOneWidget,
    );
    expect(find.text('0% de cashback'), findsNothing);
  });

  testWidgets('falha inicial oferece nova tentativa', (at) async {
    var chamadas = 0;
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        chamadas++;
        if (chamadas == 1) throw StateError('sem rede');
        return _pagina([_loja()]);
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();
    expect(
      find.text('Não foi possível carregar o cashback do Inter.'),
      findsOneWidget,
    );

    await at.tap(find.text('Tentar novamente'));
    await at.pumpAndSettle();
    expect(find.text('Magazine Luiza'), findsOneWidget);
  });

  testWidgets('paginação manual mostra carregamento, retry e duas colunas', (
    at,
  ) async {
    at.view.devicePixelRatio = 1;
    at.view.physicalSize = const Size(1100, 1600);
    addTearDown(at.view.resetDevicePixelRatio);
    addTearDown(at.view.resetPhysicalSize);
    var falha = true;
    final paginaDois = Completer<Pagina<CashbackInter>>();
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        if (pagina == 1) {
          return _pagina(
            [_loja(), _loja(nome: 'Renner')],
            total: 3,
            proxima: true,
          );
        }
        if (falha) {
          falha = false;
          throw StateError('sem rede');
        }
        return paginaDois.future;
      },
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();
    expect(find.byType(Wrap), findsNWidgets(2));
    await at.tap(find.text('Carregar mais'));
    await at.pumpAndSettle();
    expect(find.text('Tentar carregar mais'), findsOneWidget);

    await at.tap(find.text('Tentar carregar mais'));
    await at.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    paginaDois.complete(_pagina([_loja(nome: 'C&A')], total: 3));
    await at.pumpAndSettle();
    expect(find.text('C&A'), findsOneWidget);
  });

  testWidgets('página de Cashback mantém o foco nos Sites parceiros', (
    at,
  ) async {
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          _pagina([], atualizadaEm: null),
    );
    addTearDown(controlador.dispose);

    await at.pumpWidget(_tela(controlador));
    await at.pumpAndSettle();

    expect(find.text('Cashback — Sites parceiros'), findsOneWidget);
    expect(find.byTooltip('Produtos no Inter'), findsNothing);
  });
}
