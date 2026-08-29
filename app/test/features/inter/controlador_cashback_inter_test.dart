import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/inter/controlador_cashback_inter.dart';

CashbackInter loja(String id, String nome) => CashbackInter(
  id: id,
  slug: nome.toLowerCase(),
  nome: nome,
  cashbackPrincipalTexto: 'Até 10% de cashback',
  cashbackPrincipalValor: '10',
  cashbackSecundarioTexto: null,
  cashbackSecundarioValor: null,
  etiqueta: null,
  descricaoPrincipal: null,
  descricaoSecundaria: null,
  encontrada: true,
);

Pagina<CashbackInter> respostaPagina(
  List<CashbackInter> itens, {
  int numero = 1,
  int? total,
  bool proxima = false,
  String? atualizadaEm = '2026-08-22T12:00:00Z',
  String? ultimaTentativaEstado,
}) => Pagina(
  itens: itens,
  pagina: numero,
  porPagina: 20,
  totalItens: total ?? (proxima ? 3 : itens.length),
  totalPaginas: proxima ? numero + 1 : numero,
  temProxima: proxima,
  atualizadoEm: atualizadaEm,
  ultimaTentativaEstado: ultimaTentativaEstado,
);

void main() {
  test('carrega, pagina e deduplica pelo ID estável da loja', () async {
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        if (pagina == 1) {
          return respostaPagina([
            loja('1', 'C&A'),
            loja('2', 'Renner'),
          ], proxima: true);
        }
        return respostaPagina([
          loja('2', 'Renner'),
          loja('3', 'Magalu'),
        ], numero: 2);
      },
    );

    await controlador.carregarInicial();
    await controlador.carregarMais();

    expect(controlador.itens.map((item) => item.id), ['1', '2', '3']);
    expect(controlador.temProxima, isFalse);
    controlador.dispose();
  });

  test('busca usa debounce e ordenação reinicia a consulta', () async {
    final consultas = <String>[];
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        consultas.add('$q/$ordenar/$pagina');
        return respostaPagina([loja('1', 'C&A')]);
      },
    );

    await controlador.carregarInicial();
    controlador.mudarBusca('ca');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await controlador.mudarOrdenacao(OrdenacaoCashbackInter.nome);

    expect(consultas, ['/cashback/1', 'ca/cashback/1', 'ca/nome/1']);
    controlador.dispose();
  });

  test('descarta resposta antiga quando a ordenação muda', () async {
    final primeira = Completer<Pagina<CashbackInter>>();
    var chamadas = 0;
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) {
        chamadas++;
        if (ordenar == 'nome') {
          return Future.value(respostaPagina([loja('novo', 'Alfabética')]));
        }
        return primeira.future;
      },
    );

    unawaited(controlador.carregarInicial());
    await controlador.mudarOrdenacao(OrdenacaoCashbackInter.nome);
    primeira.complete(respostaPagina([loja('antigo', 'Resposta antiga')]));
    await Future<void>.delayed(Duration.zero);

    expect(controlador.itens.single.nome, 'Alfabética');
    expect(chamadas, 2);
    controlador.dispose();
  });

  test('erro adicional preserva itens e retry tenta a mesma página', () async {
    var falha = true;
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async {
        if (pagina == 1) {
          return respostaPagina([loja('1', 'C&A')], total: 2, proxima: true);
        }
        if (falha) {
          falha = false;
          throw StateError('sem rede');
        }
        return respostaPagina([loja('2', 'Magalu')], numero: 2, total: 2);
      },
    );

    await controlador.carregarInicial();
    await controlador.carregarMais();
    expect(controlador.itens, hasLength(1));
    expect(controlador.erroMais, isNotNull);
    await controlador.carregarMais();
    expect(controlador.itens.map((item) => item.nome), ['C&A', 'Magalu']);
    expect(controlador.temProxima, isFalse);
    controlador.dispose();
  });

  test('preserva a última tentativa separada da coleta válida', () async {
    final controlador = ControladorCashbackInter(
      buscar: ({required q, required ordenar, required pagina}) async =>
          respostaPagina([loja('1', 'C&A')], ultimaTentativaEstado: 'falha'),
    );

    await controlador.carregarInicial();

    expect(controlador.atualizadoEm, '2026-08-22T12:00:00Z');
    expect(controlador.ultimaTentativaFalhou, isTrue);
    controlador.dispose();
  });
}
