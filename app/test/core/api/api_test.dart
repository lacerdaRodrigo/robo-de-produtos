import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/api/modelos.dart';

const baseUrl = 'http://localhost:3000';

const _itens = <Map<String, Object?>>[
  {
    'id_externo': '1',
    'nome': 'Camiseta',
    'marca': 'Nike',
    'categoria': 'Moda',
    'caminho': '/produto/1',
    'preco_cheio_texto': 'R\$ 1.099,00',
    'preco_cheio_valor': '1099',
    'preco_atual_texto': 'R\$ 999,00',
    'preco_atual_valor': '999',
    'desconto_texto': 'R\$ 100,00',
    'desconto_percentual_texto': '9%',
    'cashback_texto': 'R\$ 60,00',
    'cashback_percentual_texto': '6%',
    'preco_liquido_texto': 'R\$ 939,00',
    'parcelamento': 'em até 10x',
    'estoque': 4,
    'etiquetas': <String>['Frete grátis'],
    'loja_slug': 'casas-bahia',
    'loja_nome': 'Casas Bahia',
    'atualizada_em': '2026-08-19T00:00:00Z',
  },
];

Api apiQueResponde(String corpoHttp) {
  return Api(
    paginaPadrao: 20,
    cliente: ClienteApi(
      baseUrl: baseUrl,
      provedorToken: () async => 'token-teste',
      cliente: http_testing.MockClient(
        (_) async => http.Response(corpoHttp, 200),
      ),
    ),
  );
}

void main() {
  test('buscarProdutos converte a página e os itens', () async {
    final corpo = jsonEncode({
      'itens': _itens,
      'pagina': 1,
      'por_pagina': 20,
      'total_itens': 45,
      'total_paginas': 3,
      'tem_proxima': true,
      'atualizado_em': '2026-08-19T00:00:00Z',
      'qualidade': 'completa',
    });
    final api = apiQueResponde(corpo);

    final pagina = await api.buscarProdutos('camiseta');

    expect(pagina.itens, hasLength(1));
    expect(pagina.itens.single.nome, 'Camiseta');
    expect(pagina.itens.single.precoAtualValor, '999');
    expect(pagina.itens.single.lojaNome, 'Casas Bahia');
    expect(pagina.itens.single.ativo, isNull);
    expect(pagina.totalItens, 45);
    expect(pagina.totalPaginas, 3);
    expect(pagina.temProxima, isTrue);
    expect(pagina.qualidade, 'completa');
  });

  test('buscarProdutos envia categoria externa exata na consulta', () async {
    final consultas = <Uri>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          consultas.add(requisicao.url);
          return http.Response(
            '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,"total_paginas":1,"tem_proxima":false}',
            200,
          );
        }),
      ),
    );

    await api.buscarProdutos(
      'tv',
      marca: 'Samsung',
      loja: 'casas-bahia',
      categoria: 'Smart TV',
    );

    expect(consultas.single.queryParameters['marca'], 'Samsung');
    expect(consultas.single.queryParameters['loja'], 'casas-bahia');
    expect(consultas.single.queryParameters['categoria'], 'Smart TV');
    expect(consultas.single.queryParameters.containsKey('categoria_radar'), isFalse);
    expect(consultas.single.queryParameters['q'], 'tv');
  });

  test('buscarProdutos envia Sem categoria como filtro separado', () async {
    final consultas = <Uri>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          consultas.add(requisicao.url);
          return http.Response(
            '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,"total_paginas":1,"tem_proxima":false}',
            200,
          );
        }),
      ),
    );

    await api.buscarProdutos('tv', semCategoria: true);

    expect(consultas.single.queryParameters['sem_categoria'], 'true');
    expect(consultas.single.queryParameters.containsKey('categoria'), isFalse);
  });

  test('categorias do Inter leem e salvam valores externos', () async {
    final requisicoes = <http.Request>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          requisicoes.add(requisicao);
          return http.Response(
            jsonEncode({
              'configurada': true,
              'itens': [
                {
                  'valor': 'Eletrônicos',
                  'nome': 'Eletrônicos',
                  'selecionada': true,
                },
                {'valor': null, 'nome': 'Sem categoria', 'selecionada': true},
              ],
            }),
            200,
          );
        }),
      ),
    );

    final lidas = await api.categoriasInter();
    final salvas = await api.salvarCategoriasInter(
      ['Eletrônicos'],
      semCategoria: true,
    );

    expect(lidas.valoresSelecionados, {'Eletrônicos', null});
    expect(salvas.valoresSelecionados, {'Eletrônicos', null});
    expect(requisicoes[0].url.path, '/api/inter/produtos/categorias');
    expect(requisicoes[0].method, 'GET');
    expect(requisicoes[1].method, 'PATCH');
    expect(jsonDecode(requisicoes[1].body), {
      'categorias': ['Eletrônicos'],
      'sem_categoria': true,
    });
  });

  test('página vazia não inventa itens', () async {
    final api = apiQueResponde(
      '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,"total_paginas":1,"tem_proxima":false}',
    );

    final pagina = await api.buscarProdutos('nada');

    expect(pagina.vazia, isTrue);
    expect(pagina.totalItens, 0);
    expect(pagina.temProxima, isFalse);
  });

  test('status converte o marcador de saudável', () async {
    final api = apiQueResponde(
      '{"api":"v1","produto":"Radar de Benefícios","saudavel":true}',
    );

    final status = await api.status();

    expect(status.api, 'v1');
    expect(status.saudavel, isTrue);
  });

  test('resumo converte estados, horários e contagens por domínio', () async {
    Uri? consulta;
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          consulta = requisicao.url;
          return http.Response(
            jsonEncode({
              'gerado_em': '2026-08-23T12:00:00.000Z',
              'estado_geral': 'atencao',
              'livelo': {
                'estado': 'atualizado',
                'ultima_tentativa_em': '2026-08-23T08:30:00.000Z',
                'qualidade': 'completa',
                'ultimo_sucesso_em': '2026-08-23T08:00:00.000Z',
                'lojas_acompanhadas': 126,
                'alertas_ultima_coleta': 2,
              },
              'cashback_inter': {
                'estado': 'falha_recente',
                'ultima_tentativa_em': '2026-08-23T11:00:00.000Z',
                'ultima_tentativa_estado': 'falha',
                'ultimo_sucesso_em': '2026-08-23T07:00:00.000Z',
                'lojas_acompanhadas': 4,
                'lojas_encontradas_ultima_coleta': 3,
              },
              'produtos': {
                'estado': 'degradado',
                'ultima_tentativa_em': '2026-08-23T06:00:00.000Z',
                'ultima_tentativa_estado': 'sucesso',
                'dados_mais_antigos_em': '2026-08-23T06:05:00.000Z',
                'dados_mais_recentes_em': '2026-08-23T06:30:00.000Z',
                'qualidade': 'degradada',
                'lojas_selecionadas': 3,
                'lojas_sem_coleta': 0,
                'produtos_ativos': 3310,
              },
            }),
            200,
          );
        }),
      ),
    );

    final resposta = await api.resumo();

    expect(consulta!.path, '/api/resumo');
    expect(resposta.estadoGeral, EstadoResumo.atencao);
    expect(resposta.livelo.alertasUltimaColeta, 2);
    expect(resposta.livelo.ultimaTentativaEm, isNotNull);
    expect(resposta.livelo.qualidade, 'completa');
    expect(resposta.cashbackInter.estado, EstadoResumo.falhaRecente);
    expect(resposta.cashbackInter.ultimoSucessoEm, isNotNull);
    expect(resposta.produtos.estado, EstadoResumo.degradado);
    expect(resposta.produtos.produtosAtivos, 3310);
  });

  test(
    'resumo trata estado desconhecido e contagem hostil com segurança',
    () async {
      final api = apiQueResponde(
        '{"gerado_em":"x","estado_geral":"novo",'
        '"livelo":{"estado":"novo","lojas_acompanhadas":-2},'
        '"cashback_inter":{"estado":"novo","lojas_acompanhadas":"ruim"},'
        '"produtos":{"estado":"novo","produtos_ativos":-1}}',
      );

      final resposta = await api.resumo();

      expect(resposta.estadoGeral, EstadoResumo.indisponivel);
      expect(resposta.livelo.lojasAcompanhadas, 0);
      expect(resposta.cashbackInter.lojasAcompanhadas, 0);
      expect(resposta.produtos.produtosAtivos, 0);
    },
  );

  test('perfil converte autorização e papel', () async {
    final api = apiQueResponde(
      '{"id":"42","email":"piloto@example.com","papel":"admin"}',
    );

    final perfil = await api.perfil();

    expect(perfil.email, 'piloto@example.com');
    expect(perfil.administrador, isTrue);
  });

  test('painelLivelo preserva decimais e envia a paginação', () async {
    Uri? consulta;
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          consulta = requisicao.url;
          return http.Response(
            jsonEncode({
              'itens': [
                {
                  'nome': 'Casas Bahia',
                  'categoria': 'Marketplace',
                  'pontos_atuais': '2.90',
                  'pontos_base': '1.00',
                  'pontos_clube': null,
                  'valor_de_disparo': '4.00',
                  'moeda': 'R\$',
                  'prefixo_ate': true,
                  'em_promocao': true,
                  'alertou': true,
                  'campanha': 'PROMOTION_CLUB',
                  'descricao_campanha': 'Condições',
                  'fim_promocao': '2026-08-22T23:59:00Z',
                },
              ],
              'pagina': 2,
              'por_pagina': 20,
              'total_itens': 21,
              'total_paginas': 2,
              'tem_proxima': false,
              'atualizado_em': '2026-08-22T12:00:00Z',
            }),
            200,
          );
        }),
      ),
    );

    final resposta = await api.painelLivelo(
      q: 'casa',
      ordenar: 'alerta',
      pagina: 2,
    );

    expect(consulta!.path, '/api/livelo/painel');
    expect(consulta!.queryParameters, {
      'q': 'casa',
      'ordenar': 'alerta',
      'pagina': '2',
      'por_pagina': '20',
    });
    expect(resposta.itens.single.pontosAtuais, '2.90');
    expect(resposta.itens.single.pontosClube, isNull);
    expect(resposta.itens.single.alertou, isTrue);
  });

  test('catálogo Livelo envia filtros e acompanhamento mínimo', () async {
    final requisicoes = <http.Request>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          requisicoes.add(requisicao);
          if (requisicao.method == 'PATCH') {
            return http.Response(
              '{"id_externo":"NAT","acompanhada":true,'
              '"aplicada_na_proxima_coleta":true}',
              200,
            );
          }
          return http.Response(
            '{"itens":[],"resumo":{"ultima_coleta":null,'
            '"ultima_tentativa_em":"2026-08-28T12:05:00Z",'
            '"qualidade":"degradada",'
            '"parceiros_lidos":0,"total_catalogo":0,"acompanhadas":0,'
            '"alertas":0,"melhor_oferta":null},"categorias":[],'
            '"pagina":2,"por_pagina":20,"total_itens":0,'
            '"total_paginas":1,"tem_proxima":false}',
            200,
          );
        }),
      ),
    );

    final catalogo = await api.catalogoLivelo(
      q: 'natura',
      aba: 'acompanhadas',
      categoria: 'Beleza',
      ordenar: 'nome',
      pagina: 2,
    );
    await api.alterarAcompanhamentoLivelo(idExterno: 'NAT', acompanhada: true);
    await api.alterarAlertaLivelo(idExterno: 'NAT', ativo: true);

    expect(catalogo.resumo.qualidade, 'degradada');
    expect(catalogo.resumo.ultimaTentativaEm, '2026-08-28T12:05:00Z');

    expect(requisicoes.first.url.path, '/api/livelo/catalogo');
    expect(requisicoes.first.url.queryParameters, {
      'q': 'natura',
      'aba': 'acompanhadas',
      'categoria': 'Beleza',
      'ordenar': 'nome',
      'pagina': '2',
      'por_pagina': '20',
    });
    expect(requisicoes[1].url.path, '/api/livelo/catalogo/NAT/acompanhamento');
    expect(requisicoes[1].body, '{"acompanhada":true}');
    expect(requisicoes[2].url.path, '/api/livelo/catalogo/NAT/alerta');
    expect(requisicoes[2].body, '{"ativo":true}');
  });

  test('painelCashbackInter preserva a oferta textual e a paginação', () async {
    Uri? consulta;
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          consulta = requisicao.url;
          return http.Response(
            jsonEncode({
              'itens': [
                {
                  'id': 'inter-1',
                  'slug': 'loja',
                  'nome': 'Loja & Cia',
                  'cashback_principal_texto': 'Até 12% de cashback',
                  'cashback_principal_valor': '12.00',
                  'cashback_secundario_texto': null,
                  'cashback_secundario_valor': null,
                  'etiqueta': 'Oferta especial',
                  'descricao_principal': 'Em itens selecionados',
                  'descricao_secundaria': null,
                  'encontrada': true,
                  'favorita': false,
                },
              ],
              'pagina': 1,
              'por_pagina': 20,
              'total_itens': 1,
              'total_paginas': 1,
              'tem_proxima': false,
              'atualizado_em': '2026-08-22T12:00:00Z',
              'ultima_tentativa_em': '2026-08-22T14:00:00Z',
              'ultima_tentativa_estado': 'falha',
            }),
            200,
          );
        }),
      ),
    );

    final resposta = await api.painelCashbackInter(
      q: 'c&a',
      ordenar: 'nome',
      pagina: 2,
      apenasAcompanhadas: true,
      porPagina: 1,
    );

    expect(consulta!.path, '/api/inter/cashback');
    expect(consulta!.queryParameters, {
      'q': 'c&a',
      'ordenar': 'nome',
      'pagina': '2',
      'por_pagina': '1',
      'acompanhadas': 'true',
    });
    expect(resposta.itens.single.cashbackPrincipalTexto, 'Até 12% de cashback');
    expect(resposta.itens.single.cashbackPrincipalValor, '12.00');
    expect(resposta.itens.single.encontrada, isTrue);
    expect(resposta.itens.single.favorita, isFalse);
    expect(resposta.ultimaTentativaEstado, 'falha');
  });

  test(
    'historicoProduto preserva NUMERIC textual e paginação própria',
    () async {
      Uri? consulta;
      final api = Api(
        paginaPadrao: 20,
        cliente: ClienteApi(
          baseUrl: baseUrl,
          provedorToken: () async => 'token-teste',
          cliente: http_testing.MockClient((requisicao) async {
            consulta = requisicao.url;
            return http.Response(
              jsonEncode({
                'produto': {..._itens.single, 'ativo': false},
                'minimo': '900.00',
                'maximo': '1200.00',
                'medicoes': [
                  {
                    'momento': '2026-08-22T12:00:00Z',
                    'preco_atual_valor': '999.00',
                    'cashback_valor': '60.00',
                    'preco_liquido_valor': '939.00',
                  },
                ],
                'pagina': 2,
                'por_pagina': 30,
                'total_itens': 60,
                'total_paginas': 2,
                'tem_proxima': false,
              }),
              200,
            );
          }),
        ),
      );

      final resposta = await api.historicoProduto(
        loja: 'casas-bahia',
        produto: '1',
        pagina: 2,
      );

      expect(consulta!.path, '/api/inter/produtos/historico');
      expect(consulta!.queryParameters, {
        'loja': 'casas-bahia',
        'produto': '1',
        'pagina': '2',
        'por_pagina': '30',
      });
      expect(resposta.minimo, '900.00');
      expect(resposta.medicoes.single.precoLiquidoValor, '939.00');
      expect(resposta.produto.ativo, isFalse);
    },
  );

  test(
    'historicoLivelo usa o ID externo do parceiro e preserva pontuação textual',
    () async {
      Uri? consulta;
      final api = Api(
        paginaPadrao: 20,
        cliente: ClienteApi(
          baseUrl: baseUrl,
          provedorToken: () async => 'token-teste',
          cliente: http_testing.MockClient((requisicao) async {
            consulta = requisicao.url;
            return http.Response(
              jsonEncode({
                'id_externo': 'NTR',
                'medicoes': [
                  {
                    'momento': '2026-08-29T17:00:00Z',
                    'pontos_atuais': '12.50',
                    'pontos_base': '1.00',
                    'pontos_clube': null,
                    'moeda': 'R\$',
                  },
                ],
              }),
              200,
            );
          }),
        ),
      );

      final resposta = await api.historicoLivelo('NTR');

      expect(consulta!.path, '/api/livelo/catalogo/NTR/historico');
      expect(resposta.medicoes.single.pontos, '12.50');
    },
  );

  test(
    'catálogos administrativos usam páginas e PATCH com o estado desejado',
    () async {
      final requisicoes = <http.Request>[];
      final api = Api(
        paginaPadrao: 20,
        cliente: ClienteApi(
          baseUrl: baseUrl,
          provedorToken: () async => 'token-teste',
          cliente: http_testing.MockClient((requisicao) async {
            requisicoes.add(requisicao);
            if (requisicao.url.path == '/api/inter/lojas') {
              return http.Response(
                jsonEncode({
                  'itens': [
                    {
                      'id': 'parceira-1',
                      'id_externo': '1',
                      'slug': 'loja',
                      'nome': 'Loja parceira',
                      'cashback_principal_texto': '5%',
                      'cashback_principal_valor': '5.00',
                      'ativa': true,
                      'favorita': false,
                    },
                  ],
                  'pagina': 2,
                  'por_pagina': 20,
                  'total_itens': 21,
                  'total_paginas': 2,
                  'tem_proxima': false,
                }),
                200,
              );
            }
            if (requisicao.url.path == '/api/inter/produtos/lojas' &&
                requisicao.method == 'GET') {
              return http.Response(
                jsonEncode({
                  'itens': [
                    {
                      'id': 'direta-1',
                      'id_externo': 'direta-externa-1',
                      'slug': 'direta',
                      'nome': 'Loja direta',
                      'selecionada': true,
                      'ativa': true,
                      'ultima_execucao': '2026-08-30T15:00:00Z',
                      'ultimo_estado': 'sucesso',
                      'paginas': 12,
                      'ultima_tentativa_em': '2026-08-30T14:50:00Z',
                      'ultima_tentativa_estado': 'falha',
                      'ultima_coleta_sucesso_em': '2026-08-29T15:00:00Z',
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
            }
            if (requisicao.method == 'PATCH') {
              return http.Response('{"id":"direta-1","selecionada":true}', 200);
            }
            return http.Response(
              '{"itens":[],"pagina":1,"por_pagina":20,"total_itens":0,"total_paginas":1,"tem_proxima":false}',
              200,
            );
          }),
        ),
      );

      final parceiras = await api.lojasInter(q: 'loja', pagina: 2);
      await api.alterarFavoritaInter(id: 'parceira-1', favorita: true);
      final diretas = await api.lojasDiretas(
        ordenar: 'cashback',
        filtro: 'acompanhadas',
      );
      await api.alterarSelecaoLojaDireta(id: 'direta-1', selecionada: true);

      expect(parceiras.itens.single.cashbackPrincipalValor, '5.00');
      expect(parceiras.itens.single.favorita, isFalse);
      expect(diretas.itens.single.ultimaExecucao, '2026-08-30T15:00:00Z');
      expect(diretas.itens.single.ultimoEstado, 'sucesso');
      expect(diretas.itens.single.paginas, 12);
      expect(diretas.itens.single.ultimaTentativaEstado, 'falha');
      expect(diretas.itens.single.produtosEncontrados, 18);
      expect(diretas.itens.single.cashbackResumoTexto, 'Até 6% de cashback');
      expect(requisicoes[0].url.queryParameters['q'], 'loja');
      expect(requisicoes[0].url.queryParameters['pagina'], '2');
      expect(requisicoes[1].method, 'PATCH');
      expect(requisicoes[1].body, '{"id":"parceira-1","favorita":true}');
      expect(requisicoes[2].url.queryParameters['ordenar'], 'cashback');
      expect(requisicoes[2].url.queryParameters['filtro'], 'acompanhadas');
      expect(requisicoes[3].method, 'PATCH');
      expect(requisicoes[3].body, '{"id":"direta-1","selecionada":true}');
    },
  );

  test('consulta e solicita disparo por contrato fechado', () async {
    final requisicoes = <http.Request>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          requisicoes.add(requisicao);
          if (requisicao.method == 'POST') {
            return http.Response(
              '{"dominio":"livelo","estado":"aceito","cooldown_segundos":300}',
              202,
            );
          }
          return http.Response(
            '{"dominio":"livelo","cooldown_segundos":0,"ultima_solicitacao_em":null,"ultimo_estado":null}',
            200,
          );
        }),
      ),
    );

    final estado = await api.estadoDisparo('livelo');
    final resposta = await api.solicitarDisparo(
      dominio: 'livelo',
      chaveIdempotencia: 'chave-valida-123456',
    );

    expect(estado.cooldownSegundos, 0);
    expect(resposta.estado, 'aceito');
    expect(requisicoes[0].url.queryParameters['dominio'], 'livelo');
    expect(requisicoes[1].headers['idempotency-key'], 'chave-valida-123456');
  });

  test('administração Livelo preserva texto e usa rotas por recurso', () async {
    final requisicoes = <http.Request>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          requisicoes.add(requisicao);
          if (requisicao.url.path == '/api/livelo/preferencias') {
            return http.Response(
              '{"multiplicador_padrao":"2.90","piso_pontos_padrao":"4.00","assinante_clube":true}',
              200,
            );
          }
          if (requisicao.method == 'POST') {
            return http.Response(
              '{"id":"42","nome":"Loja Nova","categoria":"Viagem","apelidos":["Loja N"],"multiplicador":"3.00","piso_pontos":"5.00"}',
              201,
            );
          }
          if (requisicao.method == 'PATCH' || requisicao.method == 'DELETE') {
            return http.Response('{}', 200);
          }
          return http.Response(
            '{"itens":[{"id":"7","nome":"Loja","categoria":"Casa","multiplicador":"2.90","piso_pontos":null,"apelidos":["Loja BR"]}],"pagina":1,"por_pagina":20,"total_itens":1,"total_paginas":1,"tem_proxima":false}',
            200,
          );
        }),
      ),
    );

    final pagina = await api.lojasLivelo(q: 'casa');
    final preferencias = await api.preferenciasLivelo();
    final criada = await api.cadastrarLojaLivelo(
      nome: 'Loja Nova',
      categoria: 'Viagem',
      apelidos: const ['Loja N'],
      multiplicador: '3.00',
      piso: '5.00',
    );
    await api.alterarRegraLojaLivelo(
      id: '7',
      multiplicador: null,
      piso: '6.00',
    );
    await api.salvarPreferenciasLivelo(
      multiplicador: '2.90',
      piso: '4.00',
      assinanteClube: false,
    );
    await api.removerLojaLivelo('7');

    expect(pagina.itens.single.multiplicador, '2.90');
    expect(pagina.itens.single.piso, isNull);
    expect(preferencias.multiplicador, '2.90');
    expect(criada.piso, '5.00');
    expect(requisicoes.first.url.queryParameters['q'], 'casa');
    expect(requisicoes[2].body, contains('"multiplicador":"3.00"'));
    expect(requisicoes[3].url.path, '/api/livelo/lojas/7');
    expect(requisicoes[3].body, '{"multiplicador":null,"piso":"6.00"}');
    expect(requisicoes[4].body, contains('"assinante_clube":false'));
    expect(requisicoes[5].method, 'DELETE');
  });

  test('zona de perigo consulta resumo e envia somente a frase', () async {
    final requisicoes = <http.Request>[];
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: baseUrl,
        provedorToken: () async => 'token-teste',
        cliente: http_testing.MockClient((requisicao) async {
          requisicoes.add(requisicao);
          if (requisicao.method == 'POST') {
            return http.Response('{"dominio":"livelo","concluida":true}', 200);
          }
          return http.Response(
            '{"dominio":"livelo","frase_confirmacao":"APAGAR LIVELO",'
            '"contagens":{"lojas":2,"pontuacoes":10}}',
            200,
          );
        }),
      ),
    );

    final resumo = await api.resumoLimpeza('livelo');
    await api.executarLimpeza(dominio: 'livelo', frase: 'APAGAR LIVELO');

    expect(resumo.fraseConfirmacao, 'APAGAR LIVELO');
    expect(resumo.contagens, {'lojas': 2, 'pontuacoes': 10});
    expect(requisicoes[0].url.path, '/api/administracao/limpeza/livelo');
    expect(requisicoes[1].method, 'POST');
    expect(requisicoes[1].body, '{"frase":"APAGAR LIVELO"}');
  });
}
