import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/livelo/controlador_painel_livelo.dart';

PontuacaoLivelo loja(String nome, {bool alerta = false}) => PontuacaoLivelo(
  nome: nome,
  categoria: 'Moda',
  pontosAtuais: '6',
  pontosBase: '2',
  pontosClube: null,
  valorDeDisparo: '4',
  moeda: 'R\$',
  prefixoAte: false,
  emPromocao: true,
  alertou: alerta,
  campanha: 'PROMOTION',
  descricaoCampanha: null,
  fimPromocao: null,
);

Pagina<PontuacaoLivelo> respostaPagina(
  List<PontuacaoLivelo> itens, {
  int numero = 1,
  int? total,
  bool proxima = false,
  String? atualizadaEm = '2026-08-22T12:00:00Z',
}) => Pagina<PontuacaoLivelo>(
  itens: itens,
  pagina: numero,
  porPagina: 20,
  totalItens: total ?? itens.length,
  totalPaginas: proxima ? numero + 1 : numero,
  temProxima: proxima,
  atualizadoEm: atualizadaEm,
);

void main() {
  test('carrega a primeira página e seus metadados', () async {
    final controlador = ControladorPainelLivelo(
      buscar: ({required q, required ordenar, required pagina}) async =>
          pagina == 1
          ? respostaPagina([loja('Renner')], total: 2, proxima: true)
          : throw StateError(''),
    );

    await controlador.carregarInicial();

    expect(controlador.itens.single.nome, 'Renner');
    expect(controlador.totalItens, 2);
    expect(controlador.temProxima, isTrue);
    expect(controlador.carregandoInicial, isFalse);
    controlador.dispose();
  });

  test(
    'carrega mais, deduplica pelo nome canônico e para na última página',
    () async {
      final controlador = ControladorPainelLivelo(
        buscar: ({required q, required ordenar, required pagina}) async {
          if (pagina == 1) {
            return respostaPagina(
              [loja('Renner'), loja('C&A')],
              total: 3,
              proxima: true,
            );
          }
          return respostaPagina(
            [loja('C&A'), loja('Petz')],
            numero: 2,
            total: 3,
          );
        },
      );

      await controlador.carregarInicial();
      await controlador.carregarMais();
      await controlador.carregarMais();

      expect(controlador.itens.map((item) => item.nome), [
        'Renner',
        'C&A',
        'Petz',
      ]);
      expect(controlador.temProxima, isFalse);
      controlador.dispose();
    },
  );

  test('bloqueia duas chamadas simultâneas de paginação', () async {
    final mais = Completer<Pagina<PontuacaoLivelo>>();
    var chamadas = 0;
    final controlador = ControladorPainelLivelo(
      buscar: ({required q, required ordenar, required pagina}) {
        chamadas++;
        if (pagina == 1) {
          return Future.value(
            respostaPagina([loja('Renner')], total: 2, proxima: true),
          );
        }
        return mais.future;
      },
    );

    await controlador.carregarInicial();
    unawaited(controlador.carregarMais());
    unawaited(controlador.carregarMais());
    expect(chamadas, 2);
    mais.complete(respostaPagina([loja('Petz')], numero: 2, total: 2));
    await Future<void>.delayed(Duration.zero);
    expect(controlador.itens, hasLength(2));
    controlador.dispose();
  });

  test('busca aguarda 350 ms e reinicia a sequência', () async {
    final consultas = <String>[];
    final controlador = ControladorPainelLivelo(
      buscar: ({required q, required ordenar, required pagina}) async {
        consultas.add('$q/$ordenar/$pagina');
        return respostaPagina([loja(q.isEmpty ? 'Renner' : q)]);
      },
    );

    await controlador.carregarInicial();
    controlador.mudarBusca('pet');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(consultas, hasLength(1));
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(consultas, ['/pontos/1', 'pet/pontos/1']);
    expect(controlador.itens.single.nome, 'pet');
    controlador.dispose();
  });

  test('ordenação reseta itens e resposta antiga é ignorada', () async {
    final primeira = Completer<Pagina<PontuacaoLivelo>>();
    final controlador = ControladorPainelLivelo(
      buscar: ({required q, required ordenar, required pagina}) {
        if (ordenar == 'pontos') {
          return primeira.future;
        }
        return Future.value(respostaPagina([loja('Alerta')], total: 1));
      },
    );

    unawaited(controlador.carregarInicial());
    await controlador.mudarOrdenacao(OrdenacaoLivelo.alerta);
    primeira.complete(respostaPagina([loja('Resposta antiga')]));
    await Future<void>.delayed(Duration.zero);

    expect(controlador.itens.single.nome, 'Alerta');
    expect(controlador.ordenacao, OrdenacaoLivelo.alerta);
    controlador.dispose();
  });

  test('erro adicional preserva itens e permite retry', () async {
    var deveFalhar = true;
    final controlador = ControladorPainelLivelo(
      buscar: ({required q, required ordenar, required pagina}) async {
        if (pagina == 1) {
          return respostaPagina([loja('Renner')], total: 2, proxima: true);
        }
        if (deveFalhar) {
          deveFalhar = false;
          throw StateError('sem rede');
        }
        return respostaPagina([loja('Petz')], numero: 2, total: 2);
      },
    );

    await controlador.carregarInicial();
    await controlador.carregarMais();
    expect(controlador.itens.map((item) => item.nome), ['Renner']);
    expect(controlador.erroMais, isNotNull);
    await controlador.carregarMais();
    expect(controlador.itens.map((item) => item.nome), ['Renner', 'Petz']);
    expect(controlador.erroMais, isNull);
    controlador.dispose();
  });
}
