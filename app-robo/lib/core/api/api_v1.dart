import 'cliente.dart';
import 'modelos.dart';
import 'pagina.dart';

/// API v1 exposta para o Flutter (FASE1-Contrato-API §4).
///
/// Cada método monta a URL, chama o cliente e converte para o modelo. A
/// autenticação real (Firebase) entra via `ClienteApi`/token quando o setup
/// estiver pronto (Fase 3); hoje estas leituras são públicas.
class ApiV1 {
  ApiV1({required this.cliente, required this.paginaPadrao});

  final ClienteApi cliente;
  final int paginaPadrao;

  Future<StatusApi> status() async {
    final corpo = await cliente.obter('/api/v1/status');
    return StatusApi.parse(corpo);
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
