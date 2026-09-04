import 'cliente.dart';
import 'modelos.dart';
import 'pagina.dart';

/// API v1 exposta para o Flutter.
///
/// Cada método monta a URL, chama o cliente e converte para o modelo. A
/// O status é público. As demais leituras levam o ID token e, quando ativo,
/// o token do App Check pelo `ClienteApi` (PLANO, Fase 3B).
class Api {
  Api({required this.cliente, required this.paginaPadrao});

  final ClienteApi cliente;
  final int paginaPadrao;

  Future<StatusApi> status() async {
    final corpo = await cliente.obter('/api/status', autenticado: false);
    return StatusApi.parse(corpo);
  }

  /// Resumo agregado do Início, lido somente do Postgres pela API.
  Future<ResumoInicio> resumo() async {
    final corpo = await cliente.obter('/api/resumo');
    return ResumoInicio.parse(corpo);
  }

  Future<PerfilUsuario> perfil() async {
    final corpo = await cliente.obter('/api/perfil');
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
      '/api/livelo/painel',
      consulta: <String, String>{
        'q': q,
        'ordenar': ordenar,
        'pagina': '$pagina',
        'por_pagina': '$paginaPadrao',
      },
    );
    return Pagina.parse(corpo, PontuacaoLivelo.parse);
  }

  Future<PaginaCatalogoLivelo> catalogoLivelo({
    String q = '',
    String aba = 'todas',
    String categoria = '',
    String ordenar = 'pontos',
    int pagina = 1,
  }) async {
    final corpo = await cliente.obter(
      '/api/livelo/catalogo',
      consulta: <String, String>{
        'q': q,
        'aba': aba,
        'categoria': categoria,
        'ordenar': ordenar,
        'pagina': '$pagina',
        'por_pagina': '$paginaPadrao',
      },
    );
    return PaginaCatalogoLivelo.parse(corpo);
  }

  Future<void> alterarAcompanhamentoLivelo({
    required String idExterno,
    required bool acompanhada,
  }) async {
    await cliente.alterar(
      '/api/livelo/catalogo/$idExterno/acompanhamento',
      corpo: <String, Object?>{'acompanhada': acompanhada},
    );
  }

  Future<void> alterarAlertaLivelo({
    required String idExterno,
    required bool ativo,
  }) async {
    await cliente.alterar(
      '/api/livelo/catalogo/$idExterno/alerta',
      corpo: <String, Object?>{'ativo': ativo},
    );
  }

  Future<HistoricoLivelo> historicoLivelo(String idExterno) async {
    final corpo = await cliente.obter(
      '/api/livelo/catalogo/$idExterno/historico',
    );
    return HistoricoLivelo.parse(corpo);
  }

  /// Cashback dos Sites parceiros do Inter (PRD-V3), sempre lido da API.
  Future<Pagina<CashbackInter>> painelCashbackInter({
    String q = '',
    String ordenar = 'cashback',
    int pagina = 1,
    bool apenasAcompanhadas = false,
    int? porPagina,
  }) async {
    final corpo = await cliente.obter(
      '/api/inter/cashback',
      consulta: <String, String>{
        'q': q,
        'ordenar': ordenar,
        'pagina': '$pagina',
        'por_pagina': '${porPagina ?? paginaPadrao}',
        if (apenasAcompanhadas) 'acompanhadas': 'true',
      },
    );
    return Pagina.parse(corpo, CashbackInter.parse);
  }

  /// Busca de produtos paginada (V4). A categoria usa exatamente o valor
  /// externo recebido do Shopping Inter. `semCategoria` seleciona somente os
  /// produtos cuja origem não informou categoria.
  Future<Pagina<ProdutoDireto>> buscarProdutos(
    String termo, {
    int pagina = 1,
    int? porPagina,
    String? marca,
    String? categoria,
    bool semCategoria = false,
    String? loja,
    String? precoMin,
    String? precoMax,
  }) async {
    final corpo = await cliente.obter(
      '/api/inter/produtos',
      consulta: <String, String>{
        'q': termo,
        'pagina': '$pagina',
        'por_pagina': '${porPagina ?? paginaPadrao}',
        'marca': ?marca,
        'categoria': ?categoria,
        if (semCategoria) 'sem_categoria': 'true',
        'loja': ?loja,
        'preco_min': ?precoMin,
        'preco_max': ?precoMax,
      },
    );
    return Pagina.parse(corpo, ProdutoDireto.parse);
  }

  /// Categorias externas reais disponíveis no catálogo atual do Inter.
  Future<CatalogoCategoriasInterUsuario> categoriasInter() async {
    final corpo = await cliente.obter('/api/inter/produtos/categorias');
    return CatalogoCategoriasInterUsuario.parse(corpo);
  }

  /// Substitui as categorias externas acompanhadas; lista vazia = nenhum interesse.
  Future<CatalogoCategoriasInterUsuario> salvarCategoriasInter(
    List<String> categorias, {
    bool semCategoria = false,
  }) async {
    final corpo = await cliente.alterar(
      '/api/inter/produtos/categorias',
      corpo: <String, Object?>{
        'categorias': categorias,
        'sem_categoria': semCategoria,
      },
    );
    return CatalogoCategoriasInterUsuario.parse(corpo);
  }

  /// Histórico paginado de um produto dentro de uma loja direta específica.
  Future<HistoricoProdutoDireto> historicoProduto({
    required String loja,
    required String produto,
    int pagina = 1,
    int porPagina = 30,
  }) async {
    final corpo = await cliente.obter(
      '/api/inter/produtos/historico',
      consulta: <String, String>{
        'loja': loja,
        'produto': produto,
        'pagina': '$pagina',
        'por_pagina': '$porPagina',
      },
    );
    return HistoricoProdutoDireto.parse(corpo);
  }

  /// Catálogo administrativo dos Sites parceiros do Inter.
  Future<Pagina<LojaCatalogoInter>> lojasInter({
    String q = '',
    int pagina = 1,
  }) async {
    final corpo = await cliente.obter(
      '/api/inter/lojas',
      consulta: <String, String>{
        'q': q,
        'pagina': '$pagina',
        'por_pagina': '$paginaPadrao',
      },
    );
    return Pagina.parse(corpo, LojaCatalogoInter.parse);
  }

  /// Marca ou desmarca uma favorita sem disparar uma nova coleta.
  Future<void> alterarFavoritaInter({
    required String id,
    required bool favorita,
  }) async {
    await cliente.alterar(
      '/api/inter/lojas',
      corpo: <String, Object?>{'id': id, 'favorita': favorita},
    );
  }

  /// Catálogo administrativo das lojas do Compre direto do Inter.
  Future<Pagina<LojaDireto>> lojasDiretas({
    String q = '',
    int pagina = 1,
    String ordenar = 'nome',
    String filtro = 'todas',
  }) async {
    final corpo = await cliente.obter(
      '/api/inter/produtos/lojas',
      consulta: <String, String>{
        'q': q,
        'ordenar': ordenar,
        'filtro': filtro,
        'pagina': '$pagina',
        'por_pagina': '$paginaPadrao',
      },
    );
    return Pagina.parse(corpo, LojaDireto.parse);
  }

  /// Seleciona ou remove uma loja direta sem iniciar coleta.
  Future<void> alterarSelecaoLojaDireta({
    required String id,
    required bool selecionada,
  }) async {
    await cliente.alterar(
      '/api/inter/produtos/lojas',
      corpo: <String, Object?>{'id': id, 'selecionada': selecionada},
    );
  }

  Future<Pagina<LojaLiveloAdministrativa>> lojasLivelo({
    String q = '',
    int pagina = 1,
  }) async {
    final corpo = await cliente.obter(
      '/api/livelo/lojas',
      consulta: <String, String>{
        'q': q,
        'pagina': '$pagina',
        'por_pagina': '$paginaPadrao',
      },
    );
    return Pagina.parse(corpo, LojaLiveloAdministrativa.parse);
  }

  Future<PreferenciasLiveloAdministrativas> preferenciasLivelo() async {
    final corpo = await cliente.obter('/api/livelo/preferencias');
    return PreferenciasLiveloAdministrativas.parse(corpo);
  }

  Future<LojaLiveloAdministrativa> cadastrarLojaLivelo({
    required String nome,
    required String categoria,
    required List<String> apelidos,
    String? multiplicador,
    String? piso,
  }) async {
    final corpo = await cliente.criar(
      '/api/livelo/lojas',
      corpo: <String, Object?>{
        'nome': nome,
        'categoria': categoria,
        'apelidos': apelidos,
        'multiplicador': multiplicador,
        'piso': piso,
      },
    );
    return LojaLiveloAdministrativa.parse(corpo);
  }

  Future<void> alterarRegraLojaLivelo({
    required String id,
    String? multiplicador,
    String? piso,
  }) async {
    await cliente.alterar(
      '/api/livelo/lojas/$id',
      corpo: <String, Object?>{'multiplicador': multiplicador, 'piso': piso},
    );
  }

  Future<void> removerLojaLivelo(String id) async {
    await cliente.remover('/api/livelo/lojas/$id');
  }

  Future<PreferenciasLiveloAdministrativas> salvarPreferenciasLivelo({
    required String multiplicador,
    required String piso,
    required bool assinanteClube,
  }) async {
    final corpo = await cliente.alterar(
      '/api/livelo/preferencias',
      corpo: <String, Object?>{
        'multiplicador': multiplicador,
        'piso': piso,
        'assinante_clube': assinanteClube,
      },
    );
    return PreferenciasLiveloAdministrativas.parse(corpo);
  }

  Future<ResumoLimpezaAdministrativa> resumoLimpeza(String dominio) async {
    final corpo = await cliente.obter('/api/administracao/limpeza/$dominio');
    return ResumoLimpezaAdministrativa.parse(corpo);
  }

  Future<void> executarLimpeza({
    required String dominio,
    required String frase,
  }) async {
    await cliente.criar(
      '/api/administracao/limpeza/$dominio',
      corpo: <String, Object?>{'frase': frase},
    );
  }

  /// Consulta cooldown e última solicitação manual de um domínio fechado.
  Future<EstadoDisparoAdministrativo> estadoDisparo(String dominio) async {
    final corpo = await cliente.obter(
      '/api/administracao/disparos',
      consulta: <String, String>{'dominio': dominio},
    );
    return EstadoDisparoAdministrativo.parse(corpo);
  }

  /// Solicita uma coleta; a mesma [chaveIdempotencia] deve sobreviver a retry.
  Future<ResultadoDisparoAdministrativo> solicitarDisparo({
    required String dominio,
    required String chaveIdempotencia,
  }) async {
    final corpo = await cliente.criar(
      '/api/administracao/disparos',
      corpo: <String, Object?>{'dominio': dominio},
      cabecalhosExtras: <String, String>{'idempotency-key': chaveIdempotencia},
    );
    return ResultadoDisparoAdministrativo.parse(corpo);
  }
}
