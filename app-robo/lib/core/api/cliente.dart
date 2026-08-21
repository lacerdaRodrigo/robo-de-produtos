import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'erros.dart';

typedef ProvedorToken = Future<String?> Function();

/// Cliente HTTP mínimo da API v1 do Radar de Benefícios.
///
/// Recebe a `http.Client` de fora para os testes injetarem um falso (nunca
/// toca rede). A `baseUrl` vem do ambiente; em produção o Flutter fala com a
/// mesma origem da API (PLANO §4.2), evitando CORS e segredo no cliente.
class ClienteApi {
  ClienteApi({
    required this.baseUrl,
    required http.Client cliente,
    this.provedorToken,
    this.provedorAppCheck,
  }) : _http = cliente;

  final String baseUrl;
  final http.Client _http;
  final ProvedorToken? provedorToken;
  final ProvedorToken? provedorAppCheck;

  /// Valor monetário e demais campos chegam como string (PRD 5.4).
  Future<Map<String, dynamic>> obter(
    String caminho, {
    Map<String, String>? consulta,
    bool autenticado = true,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$caminho',
    ).replace(queryParameters: consulta);
    final cabecalhos = <String, String>{'accept': 'application/json'};
    if (autenticado) {
      final token = await provedorToken?.call();
      if (token == null || token.isEmpty) {
        throw ErroDeAutenticacao('Entre novamente para continuar.');
      }
      cabecalhos['authorization'] = 'Bearer $token';

      final appCheck = await provedorAppCheck?.call();
      if (appCheck != null && appCheck.isNotEmpty) {
        cabecalhos['x-firebase-appcheck'] = appCheck;
      }
    }

    final resposta = await _http
        .get(uri, headers: cabecalhos)
        .timeout(const Duration(seconds: 20));

    final Map<String, dynamic> corpo = _decodificar(resposta);

    if (resposta.statusCode >= 400) {
      final erro = corpo['erro'];
      final codigo = erro is Map
          ? (erro['codigo']?.toString() ?? 'inesperado')
          : 'inesperado';
      final mensagem = erro is Map
          ? (erro['mensagem']?.toString() ?? 'erro na API')
          : 'erro na API';
      throw ErroDeApi(resposta.statusCode, codigo, mensagem);
    }
    return corpo;
  }

  Map<String, dynamic> _decodificar(http.Response resposta) {
    if (resposta.body.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final corpo = jsonDecode(resposta.body);
      if (corpo is Map<String, dynamic>) {
        return corpo;
      }
    } on FormatException {
      throw ErroDeRede('resposta JSON inválida');
    }
    throw ErroDeRede('corpo da API fora do formato esperado');
  }
}
