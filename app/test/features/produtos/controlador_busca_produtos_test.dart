import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/core/api/pagina.dart';
import 'package:app_robo/features/produtos/controlador_busca_produtos.dart';

ProdutoDireto _produto(String id, {String loja = 'casas-bahia'}) =>
    ProdutoDireto(
      idExterno: id,
      nome: 'Produto $id',
      marca: 'Motorola',
      categoria: 'Celular',
      caminho: 'produto/$id',
      precoCheioTexto: 'R\$ 2.000,00',
      precoCheioValor: '2000',
      precoAtualTexto: 'R\$ 1.800,00',
      precoAtualValor: '1800',
      descontoTexto: null,
      descontoPercentualTexto: null,
      cashbackTexto: null,
      cashbackPercentualTexto: null,
      precoLiquidoTexto: null,
      parcelamento: null,
      estoque: null,
      etiquetas: const [],
      lojaSlug: loja,
      lojaNome: loja == 'casas-bahia' ? 'Casas Bahia' : 'Ponto',
      atualizadaEm: '2026-08-22T12:00:00Z',
    );

Pagina<ProdutoDireto> _pagina(
  List<ProdutoDireto> itens, {
  int numero = 1,
  int? total,
  bool proxima = false,
  String atualizadoEm = '2026-08-22T12:00:00Z',
  String qualidade = 'completa',
  String? ultimaTentativaEm,
  String? ultimaTentativaEstado,
}) => Pagina(
  itens: itens,
  pagina: numero,
  porPagina: 20,
  totalItens: total ?? itens.length,
  totalPaginas: proxima ? numero + 1 : numero,
  temProxima: proxima,
  atualizadoEm: atualizadoEm,
  qualidade: qualidade,
  ultimaTentativaEm: ultimaTentativaEm,
  ultimaTentativaEstado: ultimaTentativaEstado,
);

void main() {
  test(
    'não pesquisa termo curto e aguarda o debounce antes da primeira página',
    () async {
      final chamadas = <String>[];
      final controlador = ControladorBuscaProdutos(
        buscar:
            ({
              required termo,
              required pagina,
              marca,
              categoria,
              categoriaRadar,
              loja,
              precoMin,
              precoMax,
            }) async {
              chamadas.add('$termo/$pagina');
              return _pagina([_produto('1')]);
            },
      );
      addTearDown(controlador.dispose);

      controlador.mudarTermo('a');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(chamadas, isEmpty);

      controlador.mudarTermo('edge');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(chamadas, ['edge/1']);
    },
  );

  test('pagina, deduplica por loja e ID e para na última página', () async {
    final controlador = ControladorBuscaProdutos(
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            categoriaRadar,
            loja,
            precoMin,
            precoMax,
          }) async {
            if (pagina == 1) {
              return _pagina(
                [_produto('1'), _produto('2')],
                total: 3,
                proxima: true,
              );
            }
            return _pagina([_produto('2'), _produto('3')], numero: 2, total: 3);
          },
      debounce: Duration.zero,
    );
    addTearDown(controlador.dispose);

    controlador.mudarTermo('edge');
    await Future<void>.delayed(Duration.zero);
    await controlador.carregarMais();
    await controlador.carregarMais();

    expect(controlador.itens.map((item) => item.idExterno), ['1', '2', '3']);
    expect(controlador.temProxima, isFalse);
  });

  test('filtros reiniciam a busca e resposta antiga é ignorada', () async {
    final primeira = Completer<Pagina<ProdutoDireto>>();
    final filtrosRecebidos = <String?>[];
    final controlador = ControladorBuscaProdutos(
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            categoriaRadar,
            loja,
            precoMin,
            precoMax,
          }) {
            filtrosRecebidos.add(marca);
            if (marca == 'Motorola') {
              return Future.value(_pagina([_produto('novo')]));
            }
            return primeira.future;
          },
      debounce: Duration.zero,
    );
    addTearDown(controlador.dispose);

    controlador.mudarTermo('edge');
    await Future<void>.delayed(Duration.zero);
    controlador.mudarFiltros(const FiltrosProdutos(marca: 'Motorola'));
    primeira.complete(_pagina([_produto('antigo')]));
    await Future<void>.delayed(Duration.zero);

    expect(filtrosRecebidos, [null, 'Motorola']);
    expect(controlador.itens.single.idExterno, 'novo');
  });

  test(
    'categoria Radar reinicia na página um e preserva os outros filtros',
    () async {
      final consultas = <(int, String?, String?, String?)>[];
      final controlador = ControladorBuscaProdutos(
        buscar:
            ({
              required termo,
              required pagina,
              marca,
              categoria,
              categoriaRadar,
              loja,
              precoMin,
              precoMax,
            }) async {
              consultas.add((pagina, marca, loja, categoriaRadar));
              return _pagina(
                [_produto('$pagina-${categoriaRadar ?? 'todas'}')],
                numero: pagina,
                total: 2,
                proxima: pagina == 1 && categoriaRadar == null,
              );
            },
        debounce: Duration.zero,
      );
      addTearDown(controlador.dispose);

      controlador.mudarTermo('edge');
      await Future<void>.delayed(Duration.zero);
      await controlador.carregarMais();
      controlador.mudarFiltros(
        const FiltrosProdutos(
          marca: 'Motorola',
          loja: 'casas-bahia',
          categoriaRadar: 'acessorios-celulares',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(consultas.last, (
        1,
        'Motorola',
        'casas-bahia',
        'acessorios-celulares',
      ));
      expect(controlador.pagina, 1);
      expect(
        controlador.filtros.categoriaRadarOpcional,
        'acessorios-celulares',
      );
    },
  );

  test('erro da página adicional preserva a lista e permite retry', () async {
    var falha = true;
    final controlador = ControladorBuscaProdutos(
      buscar:
          ({
            required termo,
            required pagina,
            marca,
            categoria,
            categoriaRadar,
            loja,
            precoMin,
            precoMax,
          }) async {
            if (pagina == 1) {
              return _pagina([_produto('1')], total: 2, proxima: true);
            }
            if (falha) {
              falha = false;
              throw StateError('sem rede');
            }
            return _pagina([_produto('2')], numero: 2, total: 2);
          },
      debounce: Duration.zero,
    );
    addTearDown(controlador.dispose);

    controlador.mudarTermo('edge');
    await Future<void>.delayed(Duration.zero);
    await controlador.carregarMais();
    expect(controlador.itens, hasLength(1));
    expect(controlador.erroMais, isNotNull);
    await controlador.carregarMais();
    expect(controlador.itens, hasLength(2));
    expect(controlador.erroMais, isNull);
  });

  test(
    'falha da primeira página preserva último resultado e retry substitui',
    () async {
      var chamada = 0;
      final controlador = ControladorBuscaProdutos(
        buscar:
            ({
              required termo,
              required pagina,
              marca,
              categoria,
              categoriaRadar,
              loja,
              precoMin,
              precoMax,
            }) async {
              chamada++;
              if (chamada == 2) throw StateError('sem rede');
              return _pagina([
                _produto(chamada == 1 ? 'anterior' : 'atualizado'),
              ]);
            },
        debounce: Duration.zero,
      );
      addTearDown(controlador.dispose);

      controlador.mudarTermo('edge');
      await Future<void>.delayed(Duration.zero);
      expect(controlador.itens.single.idExterno, 'anterior');

      controlador.mudarFiltros(const FiltrosProdutos(marca: 'Motorola'));
      await Future<void>.delayed(Duration.zero);
      expect(controlador.preservandoResultados, isTrue);
      expect(controlador.itens.single.idExterno, 'anterior');

      await controlador.tentarNovamente();
      expect(controlador.preservandoResultados, isFalse);
      expect(controlador.erro, isNull);
      expect(controlador.itens.single.idExterno, 'atualizado');
    },
  );

  test(
    'resposta vazia só substitui a lista depois de consulta válida',
    () async {
      var chamadas = 0;
      final controlador = ControladorBuscaProdutos(
        buscar:
            ({
              required termo,
              required pagina,
              marca,
              categoria,
              categoriaRadar,
              loja,
              precoMin,
              precoMax,
            }) async {
              chamadas++;
              return chamadas == 1
                  ? _pagina([_produto('anterior')])
                  : _pagina(const []);
            },
        debounce: Duration.zero,
      );
      addTearDown(controlador.dispose);

      controlador.mudarTermo('edge');
      await Future<void>.delayed(Duration.zero);
      expect(controlador.itens.single.idExterno, 'anterior');

      controlador.mudarFiltros(const FiltrosProdutos(marca: 'Motorola'));
      await Future<void>.delayed(Duration.zero);
      expect(controlador.erro, isNull);
      expect(controlador.itens, isEmpty);
    },
  );

  test(
    'consolida frescor e qualidade das lojas das páginas carregadas',
    () async {
      final controlador = ControladorBuscaProdutos(
        buscar:
            ({
              required termo,
              required pagina,
              marca,
              categoria,
              categoriaRadar,
              loja,
              precoMin,
              precoMax,
            }) async => pagina == 1
            ? _pagina(
                [_produto('1')],
                total: 2,
                proxima: true,
                atualizadoEm: '2026-08-30T10:00:00Z',
                ultimaTentativaEm: '2026-08-30T11:00:00Z',
                ultimaTentativaEstado: 'sucesso',
              )
            : _pagina(
                [_produto('2', loja: 'ponto')],
                numero: 2,
                total: 2,
                atualizadoEm: '2026-08-29T08:00:00Z',
                qualidade: 'degradada',
                ultimaTentativaEm: '2026-08-30T12:00:00Z',
                ultimaTentativaEstado: 'falha',
              ),
        debounce: Duration.zero,
      );
      addTearDown(controlador.dispose);

      controlador.mudarTermo('edge');
      await Future<void>.delayed(Duration.zero);
      await controlador.carregarMais();

      expect(controlador.pagina, 2);
      expect(controlador.atualizadoEm, '2026-08-29T08:00:00Z');
      expect(controlador.qualidade, 'degradada');
      expect(controlador.ultimaTentativaEm, '2026-08-30T12:00:00Z');
      expect(controlador.ultimaTentativaEstado, 'parcial');
    },
  );
}
