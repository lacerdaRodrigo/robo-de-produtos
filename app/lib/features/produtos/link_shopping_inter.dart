/// Reconstrói o destino comercial sob o host fixo do Shopping Inter.
///
/// O caminho vem da API e é tratado como hostil: URL absoluta, autoridade ou
/// segmentos de navegação são recusados. Nenhum conteúdo externo é exibido no
/// app; o usuário só pode optar por abrir um HTTPS no domínio esperado.
Uri? linkSeguroShoppingInter(String caminho) {
  final limpo = caminho.trim();
  final caminhoSemConsulta = limpo.split('?').first;
  final temNavegacao = _temSegmentoNavegacaoInvalido(
    caminhoSemConsulta.split('/'),
  );
  if (temNavegacao) return null;

  final origem = Uri.tryParse(limpo);
  if (origem == null ||
      origem.hasScheme ||
      origem.hasAuthority ||
      origem.pathSegments.isEmpty ||
      origem.pathSegments.any(
        (segmento) => segmento.isEmpty || segmento == '.' || segmento == '..',
      )) {
    return null;
  }
  return Uri(
    scheme: 'https',
    host: 'shopping.inter.co',
    pathSegments: origem.pathSegments,
    queryParameters: origem.queryParametersAll.isEmpty
        ? null
        : origem.queryParametersAll,
  );
}

/// Aceita um destino absoluto fornecido pela API somente quando ele permanece
/// em HTTPS no host comercial já aprovado do Shopping Inter.
Uri? linkAbsolutoSeguroShoppingInter(String? destino) {
  final bruto = destino?.trim() ?? '';
  final uri = Uri.tryParse(bruto);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'shopping.inter.co' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      _temSegmentoNavegacaoInvalido(uri.pathSegments)) {
    return null;
  }
  return uri;
}

bool _temSegmentoNavegacaoInvalido(Iterable<String> segmentos) {
  try {
    return segmentos.any((segmento) {
      final decodificado = Uri.decodeComponent(segmento);
      return decodificado == '.' || decodificado == '..';
    });
  } on FormatException {
    return true;
  } on ArgumentError {
    return true;
  }
}
