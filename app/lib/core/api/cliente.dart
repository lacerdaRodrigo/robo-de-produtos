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
    final uri = Uri.parse('$baseUrl$caminho')
        .replace(queryParameters: consulta);
    final cabecalhos = await _cabecalhos(autenticado: autenticado);

    final resposta = await _http
        .get(uri, headers: cabecalhos)
        .timeout(const Duration(seconds: 20));

    return _processar(resposta);
  }

  /// Envia uma mutação JSON autenticada para a API v1.
  ///
  /// O app não conhece banco, workflow ou URL externa: ele apenas remete o
  /// estado final desejado. A API revalida papel, App Check e limites antes de
  /// qualquer alteração administrativa.
  Future<Map<String, dynamic>> alterar(
    String caminho, {
    required Map<String, Object?> corpo,
  }) async {
    final uri = Uri.parse('$baseUrl$caminho');
    final cabecalhos = await _cabecalhos();
    cabecalhos['content-type'] = 'application/json';
    final resposta = await _http
        .patch(uri, headers: cabecalhos, body: jsonEncode(corpo))
        .timeout(const Duration(seconds: 20));
    return _processar(resposta);
  }

  /// Cria uma solicitação JSON autenticada na API v1.
  ///
  /// [cabecalhosExtras] é usado pela chave de idempotência de operações que
  /// podem ser reenviadas pelo sistema operacional após perder a conexão.
  Future<Map<String, dynamic>> criar(
    String caminho, {
    required Map<String, Object?> corpo,
    Map<String, String>? cabecalhosExtras,
  }) async {
    final uri = Uri.parse('$baseUrl$caminho');
    final cabecalhos = await _cabecalhos();
    cabecalhos['content-type'] = 'application/json';
    cabecalhos.addAll(cabecalhosExtras ?? const <String, String>{});
    final resposta = await _http
        .post(uri, headers: cabecalhos, body: jsonEncode(corpo))
        .timeout(const Duration(seconds: 20));
    return _processar(resposta);
  }

  /// Remove um recurso administrativo identificado pela própria API.
  Future<Map<String, dynamic>> remover(String caminho) async {
    final uri = Uri.parse('$baseUrl$caminho');
    final cabecalhos = await _cabecalhos();
    final resposta = await _http
        .delete(uri, headers: cabecalhos)
        .timeout(const Duration(seconds: 20));
    return _processar(resposta);
  }

  Future<Map<String, String>> _cabecalhos({bool autenticado = true}) async {
    final cabecalhos = <String, String>{'accept': 'application/json'};
    if (!autenticado) return cabecalhos;

    final token = await provedorToken?.call();
    if (token == null || token.isEmpty) {
      throw ErroDeAutenticacao('Entre novamente para continuar.');
    }
    cabecalhos['authorization'] = 'Bearer $token';

    String? appCheck;
    try {
      appCheck = await provedorAppCheck?.call();
    } catch (_) {
      // Erros nativos do provider podem conter detalhes internos. Para o app,
      // a falha continua sendo um erro normal e seguro da camada de cliente.
      throw ErroDeRede('Não foi possível validar este aplicativo.');
    }
    if (appCheck != null && appCheck.isNotEmpty) {
      cabecalhos['x-firebase-appcheck'] = appCheck;
    }
    return cabecalhos;
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

  Map<String, dynamic> _processar(http.Response resposta) {
    Map<String, dynamic> corpo;
    try {
      corpo = _decodificar(resposta);
    } on ErroDeRede {
      if (resposta.statusCode < 400) rethrow;
      throw ErroDeApi(
        resposta.statusCode,
        resposta.statusCode >= 500 ? 'inesperado' : 'resposta-invalida',
        resposta.statusCode >= 500
            ? 'Erro interno do servidor.'
            : 'A API devolveu uma resposta inválida.',
        retryAfterSeconds: _inteiroPositivo(resposta.headers['retry-after']),
      );
    }

    if (resposta.statusCode < 400) return corpo;

    final erro = corpo['erro'];
    final codigo = erro is Map
        ? (erro['codigo']?.toString() ?? 'inesperado')
        : 'inesperado';
    final mensagem = erro is Map
        ? (erro['mensagem']?.toString() ?? 'erro na API')
        : 'erro na API';
    final retryAfter = _inteiroPositivo(
      erro is Map ? erro['retry_after_seconds'] : null,
    );
    throw ErroDeApi(
      resposta.statusCode,
      codigo,
      mensagem,
      retryAfterSeconds:
          retryAfter ??
          _inteiroPositivo(corpo['retry_after_seconds']) ??
          _inteiroPositivo(resposta.headers['retry-after']),
    );
  }

  int? _inteiroPositivo(Object? valor) {
    final numero = valor is num
        ? valor.ceil()
        : double.tryParse(valor?.toString() ?? '')?.ceil();
    return numero != null && numero > 0 ? numero : null;
  }
}
