/// Converte a URL recebida da API em um destino externo permitido.
///
/// O aplicativo não monta caminho de produto nem aceita esquemas locais.
Uri? linkSeguroPichau(String destino) {
  final uri = Uri.tryParse(destino.trim());
  if (uri == null || !uri.hasAuthority) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  return uri;
}
