/// Erro de domínio da API v1, já normalizado no cliente.
///
/// O corpo de erro da API é `{ "erro": { "codigo", "mensagem" } }`
/// (contrato da API v1). Nunca vaza URL de banco nem segredo — o servidor
/// é quem garante isso; aqui a gente só transporta o código e a mensagem.
class ErroDeApi implements Exception {
  ErroDeApi(this.status, this.codigo, this.mensagem, {this.retryAfterSeconds});

  /// Status HTTP do erro.
  final int status;

  /// Código de domínio devolvido pela API (`validacao`, `nao-achei`, ...).
  final String codigo;

  /// Mensagem legível para o usuário.
  final String mensagem;

  /// Espera informada pelo servidor; não substitui a validação no backend.
  final int? retryAfterSeconds;

  @override
  String toString() => 'ErroDeApi($status: $codigo)';
}

/// Falhou sozinho na camada de rede/cliente, sem corpo de API.
class ErroDeRede implements Exception {
  ErroDeRede(this.motivo);

  final String motivo;

  @override
  String toString() => 'ErroDeRede($motivo)';
}

/// A chamada privada foi tentada sem uma sessão Firebase utilizável.
class ErroDeAutenticacao implements Exception {
  ErroDeAutenticacao(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'ErroDeAutenticacao';
}
