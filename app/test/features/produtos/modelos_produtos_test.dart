import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/api/modelos.dart';
import 'package:app_robo/features/produtos/formato_produtos.dart';

void main() {
  test('histórico preserva NUMERIC como texto e medição paginada', () {
    final historico = HistoricoProdutoDireto.parse({
      'produto': {
        'id_externo': 'edge-60',
        'nome': 'Motorola Edge 60 Pro',
        'marca': 'Motorola',
        'categoria': 'Celular',
        'caminho': 'produto/edge-60',
        'preco_cheio_texto': 'R\$ 4.000,00',
        'preco_cheio_valor': '4000.00',
        'preco_atual_texto': 'R\$ 3.688,89',
        'preco_atual_valor': '3688.89',
        'desconto_texto': null,
        'desconto_percentual_texto': null,
        'cashback_texto': '9% de cashback',
        'cashback_percentual_texto': '9%',
        'preco_liquido_texto': 'R\$ 3.356,89',
        'parcelamento': null,
        'estoque': 4,
        'etiquetas': ['Oferta'],
        'loja_slug': 'casas-bahia',
        'loja_nome': 'Casas Bahia',
        'atualizada_em': '2026-08-22T12:00:00Z',
        'ativo': false,
      },
      'minimo': '3500.00',
      'maximo': '4000.00',
      'medicoes': [
        {
          'momento': '2026-08-22T12:00:00Z',
          'preco_atual_valor': '3688.89',
          'cashback_valor': '332.00',
          'preco_liquido_valor': '3356.89',
        },
      ],
      'pagina': 1,
      'por_pagina': 30,
      'total_itens': 90,
      'tem_proxima': true,
    });

    expect(historico.minimo, '3500.00');
    expect(historico.medicoes.single.cashbackValor, '332.00');
    expect(historico.temProxima, isTrue);
    expect(historico.produto.ativo, isFalse);
  });

  test('coleta de produtos atrasa somente após 12 horas e mostra Brasília', () {
    final agora = DateTime.utc(2026, 8, 23);
    expect(coletaProdutosAtrasada('2026-08-22T12:00:00Z', agora), isFalse);
    expect(coletaProdutosAtrasada('2026-08-22T11:59:00Z', agora), isTrue);
    expect(dataHoraProduto('2026-08-22T15:30:00Z'), '22/08/2026, 12:30');
  });

  test('loja direta aceita booleanos compatíveis do contrato HTTP', () {
    final loja = LojaDireto.parse({
      'id': 12,
      'id_externo': 'parceiro-12',
      'slug': 'casas-bahia',
      'nome': 'Casas Bahia',
      'selecionada': '1',
      'ativa': 'on',
      'ultima_execucao': '2026-08-30T15:00:00Z',
      'ultimo_estado': 'sucesso',
      'paginas': 12,
      'ultima_tentativa_em': '2026-08-30T14:55:00Z',
      'ultima_tentativa_estado': 'falha',
      'ultima_coleta_sucesso_em': '2026-08-29T15:00:00Z',
      'produtos_encontrados': 0,
      'cashback_resumo_texto': 'Até 6% de cashback',
    });

    expect(loja.id, '12');
    expect(loja.idExterno, 'parceiro-12');
    expect(loja.selecionada, isTrue);
    expect(loja.ativa, isTrue);
    expect(loja.ultimaExecucao, '2026-08-30T15:00:00Z');
    expect(loja.ultimoEstado, 'sucesso');
    expect(loja.paginas, 12);
    expect(loja.ultimaTentativaEstado, 'falha');
    expect(loja.ultimaColetaSucessoEm, '2026-08-29T15:00:00Z');
    expect(loja.produtosEncontrados, 0);
    expect(loja.cashbackResumoTexto, 'Até 6% de cashback');
    expect(loja.copiarCom(selecionada: false).ultimoEstado, 'sucesso');
    expect(
      loja.copiarCom(selecionada: false).cashbackResumoTexto,
      'Até 6% de cashback',
    );
  });

  test('metadados opcionais ausentes não inventam estado', () {
    final produto = ProdutoDireto.parse({
      'id_externo': '1',
      'nome': 'Produto',
      'caminho': '/produto/1',
      'preco_atual_texto': 'R\$ 10,00',
      'preco_atual_valor': '10.00',
      'loja_slug': 'loja',
      'loja_nome': 'Loja',
      'atualizada_em': '2026-08-30T15:00:00Z',
    });
    final loja = LojaDireto.parse({
      'id': '1',
      'id_externo': 'externa',
      'slug': 'loja',
      'nome': 'Loja',
      'selecionada': false,
      'ativa': true,
    });

    expect(produto.ativo, isNull);
    expect(loja.ultimaExecucao, isNull);
    expect(loja.ultimoEstado, isNull);
    expect(loja.paginas, isNull);
    expect(loja.ultimaTentativaEstado, isNull);
    expect(loja.ultimaColetaSucessoEm, isNull);
    expect(loja.produtosEncontrados, isNull);
    expect(loja.cashbackResumoTexto, isNull);
  });

  test('categorias Radar preservam identidade, hierarquia e cobertura', () {
    final catalogo = CatalogoCategoriasRadarUsuario.parse({
      'configurada': true,
      'itens': [
        {
          'id': 42,
          'slug': 'acessorios-celulares',
          'nome': 'Acessórios para celulares',
          'categoria_pai_slug': 'eletronicos',
          'ordem': 4,
          'selecionada': false,
          'acompanhada': true,
        },
      ],
    });

    final categoria = catalogo.itens.single;
    expect(catalogo.configurada, isTrue);
    expect(categoria.id, '42');
    expect(categoria.slug, 'acessorios-celulares');
    expect(categoria.categoriaPaiSlug, 'eletronicos');
    expect(categoria.ordem, 4);
    expect(catalogo.slugsSelecionadosDiretos, isEmpty);
    expect(catalogo.slugsAcompanhados, {'acessorios-celulares'});
  });

  test('contrato incompleto de categorias falha sem inventar seleção', () {
    expect(
      () => CatalogoCategoriasRadarUsuario.parse({
        'configurada': true,
        'itens': [
          {
            'id': '1',
            'slug': 'cabos',
            'nome': 'Cabos',
            'categoria_pai_slug': null,
            'ordem': 1,
            'selecionada': true,
          },
        ],
      }),
      throwsFormatException,
    );
  });
}
