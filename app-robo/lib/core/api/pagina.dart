/// Modelo de paginação da API v1.
///
/// Contrato idêntico ao `site/lib/api.ts` (FASE1-Contrato-API §4.3): o
/// servidor entrega `pagina`, `por_pagina`, `total_itens`, `total_paginas`,
/// `tem_proxima` e, opcionalmente, `atualizado_em`, qualidade e o estado da
/// última tentativa. O cliente
/// nunca corta total em silêncio: páginas são pedidas até `tem_proxima = false`.
class Pagina<T> {
  const Pagina({
    required this.itens,
    required this.pagina,
    required this.porPagina,
    required this.totalItens,
    required this.totalPaginas,
    required this.temProxima,
    this.atualizadoEm,
    this.qualidade,
    this.ultimaTentativaEm,
    this.ultimaTentativaEstado,
  });

  factory Pagina.parse(
    Map<String, dynamic> objeto,
    T Function(Map<String, dynamic>) leitor,
  ) {
    final itens =
        (objeto['itens'] as List<dynamic>?)
            ?.map((item) => leitor(item as Map<String, dynamic>))
            .toList(growable: false) ??
        <T>[];
    return Pagina(
      itens: itens,
      pagina: (objeto['pagina'] as num?)?.toInt() ?? 1,
      porPagina: (objeto['por_pagina'] as num?)?.toInt() ?? 20,
      totalItens: (objeto['total_itens'] as num?)?.toInt() ?? itens.length,
      totalPaginas: (objeto['total_paginas'] as num?)?.toInt() ?? 1,
      temProxima: (objeto['tem_proxima'] as bool?) ?? false,
      atualizadoEm: objeto['atualizado_em'] as String?,
      qualidade: objeto['qualidade'] as String?,
      ultimaTentativaEm: objeto['ultima_tentativa_em'] as String?,
      ultimaTentativaEstado: objeto['ultima_tentativa_estado'] as String?,
    );
  }

  final List<T> itens;
  final int pagina;
  final int porPagina;
  final int totalItens;
  final int totalPaginas;
  final bool temProxima;

  /// Época da última coleta (quando a API expõe). null = nunca sincronizado.
  final String? atualizadoEm;

  /// `completa` | `degradada` | null (RN86).
  final String? qualidade;

  /// Momento e estado da tentativa mais recente, quando o domínio expõe.
  /// Isso não substitui [atualizadoEm], que pertence ao último retrato válido.
  final String? ultimaTentativaEm;
  final String? ultimaTentativaEstado;

  bool get vazia => itens.isEmpty;
}
