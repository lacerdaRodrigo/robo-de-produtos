/// Reconstrói o destino comercial sob o host fixo do Shopping Inter.
///
/// O caminho vem da API e é tratado como hostil: URL absoluta, autoridade ou
/// segmentos de navegação são recusados. Nenhum conteúdo externo é exibido no
/// app; o usuário só pode optar por abrir um HTTPS no domínio esperado.
Uri? linkSeguroShoppingInter(String caminho) {
  final limpo = caminho.trim();
  final caminhoSemConsulta = limpo.split('?').first;
  final temNavegacao = caminhoSemConsulta.split('/').any((segmento) {
    final decodificado = Uri.decodeComponent(segmento);
    return decodificado == '.' || decodificado == '..';
  });
  final origem = Uri.tryParse(limpo);
  if (origem == null ||
      origem.hasScheme ||
      origem.hasAuthority ||
      temNavegacao ||
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
  final uri = Uri.tryParse(destino?.trim() ?? '');
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != 'shopping.inter.co' ||
      uri.userInfo.isNotEmpty ||
      uri.hasPort ||
      uri.pathSegments.any((segmento) {
        final decodificado = Uri.decodeComponent(segmento);
        return decodificado == '.' || decodificado == '..';
      })) {
    return null;
  }
  return uri;
}
