import 'cliente.dart';
import 'modelos.dart';
import 'pagina.dart';

/// API v1 exposta para o Flutter (FASE1-Contrato-API §4).
///
/// Cada método monta a URL, chama o cliente e converte para o modelo. A
/// O status é público. As demais leituras levam o ID token e, quando ativo,
/// o token do App Check pelo `ClienteApi` (PLANO, Fase 3B).
class ApiV1 {
  ApiV1({required this.cliente, required this.paginaPadrao});

  final ClienteApi cliente;
  final int paginaPadrao;

  Future<StatusApi> status() async {
    final corpo = await cliente.obter('/api/v1/status', autenticado: false);
    return StatusApi.parse(corpo);
  }

  Future<PerfilUsuario> perfil() async {
    final corpo = await cliente.obter('/api/v1/perfil');
    return PerfilUsuario.parse(corpo);
  }

  /// Painel paginado da Livelo (Fase 4.2B).
  ///
  /// `alerta` é um filtro no servidor, embora apareça como opção de
  /// ordenação na interface para preservar o contrato HTTP já publicado.
  Future<Pagina<PontuacaoLivelo>> painelLivelo({
    String q = '',
    String ordenar = 'pontos',
    int pagina = 1,
  }) async {
    final corpo = await cliente.obter(
      '/api/v1/livelo/painel',
      consulta: <String, String>{
        'q': q,
        'ordenar': ordenar,
        'pagina': '$pagina',
        'por_pagina': '$paginaPadrao',
      },
    );
    return Pagina.parse(corpo, PontuacaoLivelo.parse);
  }

  /// Cashback dos Sites parceiros do Inter (PRD-V3), sempre lido da API.
  Future<Pagina<CashbackInter>> painelCashbackInter({
    String q = '',
    String ordenar = 'cashback',
    int pagina = 1,
  }) async {
    final corpo = await cliente.obter(
      '/api/v1/inter/cashback',
      consulta: <String, String>{
        'q': q,
        'ordenar': ordenar,
        'pagina': '$pagina',
        'por_pagina': '$paginaPadrao',
      },
    );
    return Pagina.parse(corpo, CashbackInter.parse);
  }

  /// Busca de produtos paginada (V4). `q` obrigatório, 2–100 caracteres.
  Future<Pagina<ProdutoDireto>> buscarProdutos(
    String termo, {
    int pagina = 1,
    int? porPagina,
    String? marca,
    String? categoria,
    String? loja,
    String? precoMin,
    String? precoMax,
  }) async {
    final corpo = await cliente.obter(
      '/api/v1/inter/produtos',
      consulta: <String, String>{
        'q': termo,
        'pagina': '$pagina',
        'por_pagina': '${porPagina ?? paginaPadrao}',
        'marca': ?marca,
        'categoria': ?categoria,
        'loja': ?loja,
        'preco_min': ?precoMin,
        'preco_max': ?precoMax,
      },
    );
    return Pagina.parse(corpo, ProdutoDireto.parse);
  }

  /// Histórico paginado de um produto dentro de uma loja direta específica.
  Future<HistoricoProdutoDireto> historicoProduto({
    required String loja,
    required String produto,
    int pagina = 1,
    int porPagina = 30,
  }) async {
    final corpo = await cliente.obter(
      '/api/v1/inter/produtos/historico',
      consulta: <String, String>{
        'loja': loja,
        'produto': produto,
        'pagina': '$pagina',
        'por_pagina': '$porPagina',
      },
    );
    return HistoricoProdutoDireto.parse(corpo);
  }
}
