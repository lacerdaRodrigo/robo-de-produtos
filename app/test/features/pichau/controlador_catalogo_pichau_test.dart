import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/features/pichau/controlador_catalogo_pichau.dart';
import 'package:app_robo/features/pichau/modelos_pichau.dart';

Map<String, dynamic> _produto({bool acompanhada = false}) => {
  'id_externo': 'PG-1',
  'nome': 'PC Gamer PG-1',
  'url_produto': 'https://www.pichau.com.br/produto/pg-1',
  'presente_no_catalogo': true,
  'disponibilidade': 'disponivel',
  'preco_pix_texto': 'R\$ 4.000,00',
  'acompanhada': acompanhada,
};

PaginaCatalogoPichau _pagina({bool acompanhada = false}) =>
    PaginaCatalogoPichau.parse({
      'itens': [_produto(acompanhada: acompanhada)],
      'pagina': 1,
      'por_pagina': 20,
      'total_itens': 1,
      'total_paginas': 1,
      'tem_proxima': false,
      'resumo': {'total_catalogo': 1, 'acompanhadas': acompanhada ? 1 : 0},
    });

void main() {
  test('envia busca, aba, disponibilidade e ordenação para a API', () async {
    final consultas = <Map<String, Object>>[];
    final controlador = ControladorCatalogoPichau(
      buscar:
          ({
            required q,
            required aba,
            required disponibilidade,
            required ordenar,
            required pagina,
          }) async {
            consultas.add({
              'q': q,
              'aba': aba,
              'disponibilidade': disponibilidade,
              'ordenar': ordenar,
              'pagina': pagina,
            });
            return _pagina();
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);

    await controlador.carregarInicial();
    await controlador.aplicarFiltros(
      disponibilidade: DisponibilidadePichau.esgotados,
      ordenacao: OrdenacaoPichau.desconto,
    );
    await controlador.mudarAba(AbaCatalogoPichau.acompanhadas);

    expect(consultas.last, {
      'q': '',
      'aba': 'acompanhadas',
      'disponibilidade': 'esgotados',
      'ordenar': 'desconto',
      'pagina': 1,
    });
  });

  test(
    'faz acompanhamento de forma otimista e retorna ao estado anterior em erro',
    () async {
      var falhar = false;
      final controlador = ControladorCatalogoPichau(
        buscar:
            ({
              required q,
              required aba,
              required disponibilidade,
              required ordenar,
              required pagina,
            }) async => _pagina(),
        alterarAcompanhamento:
            ({required idExterno, required acompanhada}) async {
              if (falhar) throw StateError('falha');
            },
      );
      addTearDown(controlador.dispose);
      await controlador.carregarInicial();

      expect(
        await controlador.alternarAcompanhamento(controlador.itens.single),
        isTrue,
      );
      expect(controlador.itens.single.acompanhada, isTrue);
      expect(controlador.resumo?.acompanhadas, 1);

      falhar = true;
      expect(
        await controlador.alternarAcompanhamento(controlador.itens.single),
        isFalse,
      );
      expect(controlador.itens.single.acompanhada, isTrue);
      expect(controlador.resumo?.acompanhadas, 1);
    },
  );

  test('remove da aba acompanhadas depois de confirmação da API', () async {
    final controlador = ControladorCatalogoPichau(
      buscar:
          ({
            required q,
            required aba,
            required disponibilidade,
            required ordenar,
            required pagina,
          }) async => _pagina(acompanhada: true),
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);
    await controlador.mudarAba(AbaCatalogoPichau.acompanhadas);

    expect(
      await controlador.alternarAcompanhamento(controlador.itens.single),
      isTrue,
    );
    expect(controlador.itens, isEmpty);
    expect(controlador.totalItens, 0);
    expect(controlador.resumo?.acompanhadas, 0);
  });

  test('preserva o último retrato quando uma nova tentativa falha', () async {
    var falhar = false;
    final controlador = ControladorCatalogoPichau(
      buscar:
          ({
            required q,
            required aba,
            required disponibilidade,
            required ordenar,
            required pagina,
          }) async {
            if (falhar) throw StateError('indisponível');
            return _pagina();
          },
      alterarAcompanhamento:
          ({required idExterno, required acompanhada}) async {},
    );
    addTearDown(controlador.dispose);
    await controlador.carregarInicial();
    falhar = true;
    await controlador.tentarNovamente();

    expect(controlador.itens, hasLength(1));
    expect(controlador.erroInicial, isNotNull);
  });
}
