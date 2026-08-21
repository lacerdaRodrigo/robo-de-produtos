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
}
