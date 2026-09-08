/// Modelos somente leitura do catálogo Pichau.
///
/// O Flutter preserva valores comerciais como texto. A API continua sendo a
/// responsável por consultar e normalizar a fonte; o aplicativo não acessa a
/// Pichau diretamente.
class PichauProduto {
  const PichauProduto({
    required this.idExterno,
    required this.nome,
    required this.marca,
    required this.categoria,
    required this.urlProduto,
    required this.presenteNoCatalogo,
    required this.disponibilidade,
    required this.precoOriginalTexto,
    required this.precoPixTexto,
    required this.descontoPixTexto,
    required this.precoCartaoTexto,
    required this.parcelamento,
    required this.semJuros,
    required this.etiquetas,
    required this.atualizadoEm,
    this.acompanhada = false,
  });

  factory PichauProduto.parse(Map<String, dynamic> objeto) {
    return PichauProduto(
      idExterno: _textoPichau(objeto['id_externo']),
      nome: _textoPichau(objeto['nome']),
      marca: _textoOpcionalPichau(objeto['marca']),
      categoria: _textoOpcionalPichau(objeto['categoria_externa']),
      urlProduto: _textoPichau(objeto['url_produto']),
      presenteNoCatalogo: objeto['presente_no_catalogo'] as bool? ?? true,
      disponibilidade: _textoOpcionalPichau(objeto['disponibilidade']),
      precoOriginalTexto: _textoOpcionalPichau(objeto['preco_original_texto']),
      precoPixTexto: _textoOpcionalPichau(objeto['preco_pix_texto']),
      descontoPixTexto: _textoOpcionalPichau(objeto['desconto_pix_texto']),
      precoCartaoTexto: _textoOpcionalPichau(objeto['preco_cartao_texto']),
      parcelamento: _textoOpcionalPichau(objeto['parcelamento']),
      semJuros: objeto['sem_juros'] as bool?,
      etiquetas:
          (objeto['etiquetas'] as List<dynamic>?)
              ?.map(_textoPichau)
              .where((texto) => texto.isNotEmpty)
              .toList(growable: false) ??
          const <String>[],
      atualizadoEm: _textoOpcionalPichau(objeto['atualizado_em']),
      acompanhada: objeto['acompanhada'] as bool? ?? false,
    );
  }

  final String idExterno;
  final String nome;
  final String? marca;
  final String? categoria;
  final String urlProduto;
  final bool presenteNoCatalogo;
  final String? disponibilidade;
  final String? precoOriginalTexto;
  final String? precoPixTexto;
  final String? descontoPixTexto;
  final String? precoCartaoTexto;
  final String? parcelamento;
  final bool? semJuros;
  final List<String> etiquetas;
  final String? atualizadoEm;
  final bool acompanhada;

  bool get esgotado => disponibilidade == 'esgotado';
  bool get foraDoCatalogo => !presenteNoCatalogo;

  PichauProduto copiarCom({bool? acompanhada}) => PichauProduto(
    idExterno: idExterno,
    nome: nome,
    marca: marca,
    categoria: categoria,
    urlProduto: urlProduto,
    presenteNoCatalogo: presenteNoCatalogo,
    disponibilidade: disponibilidade,
    precoOriginalTexto: precoOriginalTexto,
    precoPixTexto: precoPixTexto,
    descontoPixTexto: descontoPixTexto,
    precoCartaoTexto: precoCartaoTexto,
    parcelamento: parcelamento,
    semJuros: semJuros,
    etiquetas: etiquetas,
    atualizadoEm: atualizadoEm,
    acompanhada: acompanhada ?? this.acompanhada,
  );
}

class ResumoCatalogoPichau {
  const ResumoCatalogoPichau({
    required this.totalCatalogo,
    required this.acompanhadas,
    this.ultimaColeta,
    this.qualidade,
  });

  factory ResumoCatalogoPichau.parse(
    Map<String, dynamic> objeto, {
    int totalCatalogoPadrao = 0,
    int acompanhadasPadrao = 0,
  }) => ResumoCatalogoPichau(
    totalCatalogo: _inteiroNaoNegativoPichau(
      objeto['total_catalogo'],
      fallback: totalCatalogoPadrao,
    ),
    acompanhadas: _inteiroNaoNegativoPichau(
      objeto['acompanhadas'],
      fallback: acompanhadasPadrao,
    ),
    ultimaColeta: _textoOpcionalPichau(
      objeto['ultima_coleta'] ?? objeto['ultimo_sucesso_em'],
    ),
    qualidade: _textoOpcionalPichau(objeto['qualidade']),
  );

  final int totalCatalogo;
  final int acompanhadas;
  final String? ultimaColeta;
  final String? qualidade;

  ResumoCatalogoPichau copiarCom({int? totalCatalogo, int? acompanhadas}) {
    final novoTotalAcompanhadas = acompanhadas ?? this.acompanhadas;
    return ResumoCatalogoPichau(
      totalCatalogo: totalCatalogo ?? this.totalCatalogo,
      acompanhadas: novoTotalAcompanhadas < 0 ? 0 : novoTotalAcompanhadas,
      ultimaColeta: ultimaColeta,
      qualidade: qualidade,
    );
  }
}

class PaginaCatalogoPichau {
  const PaginaCatalogoPichau({
    required this.itens,
    required this.resumo,
    required this.pagina,
    required this.porPagina,
    required this.totalItens,
    required this.totalPaginas,
    required this.temProxima,
    this.atualizadoEm,
    this.qualidade,
    this.ultimaTentativaEstado,
  });

  factory PaginaCatalogoPichau.parse(Map<String, dynamic> objeto) {
    final itens =
        (objeto['itens'] as List<dynamic>?)
            ?.map((item) => PichauProduto.parse(item as Map<String, dynamic>))
            .toList(growable: false) ??
        const <PichauProduto>[];
    final resumoBruto = objeto['resumo'];
    final resumo = ResumoCatalogoPichau.parse(
      resumoBruto is Map<String, dynamic> ? resumoBruto : const {},
      totalCatalogoPadrao:
          (objeto['total_itens'] as num?)?.toInt() ?? itens.length,
      acompanhadasPadrao: itens.where((item) => item.acompanhada).length,
    );
    return PaginaCatalogoPichau(
      itens: itens,
      resumo: resumo,
      pagina: (objeto['pagina'] as num?)?.toInt() ?? 1,
      porPagina: (objeto['por_pagina'] as num?)?.toInt() ?? 20,
      totalItens: (objeto['total_itens'] as num?)?.toInt() ?? itens.length,
      totalPaginas: (objeto['total_paginas'] as num?)?.toInt() ?? 1,
      temProxima: objeto['tem_proxima'] as bool? ?? false,
      atualizadoEm: _textoOpcionalPichau(objeto['atualizado_em']),
      qualidade: _textoOpcionalPichau(objeto['qualidade'] ?? resumo.qualidade),
      ultimaTentativaEstado: _textoOpcionalPichau(
        objeto['ultima_tentativa_estado'],
      ),
    );
  }

  final List<PichauProduto> itens;
  final ResumoCatalogoPichau resumo;
  final int pagina;
  final int porPagina;
  final int totalItens;
  final int totalPaginas;
  final bool temProxima;
  final String? atualizadoEm;
  final String? qualidade;
  final String? ultimaTentativaEstado;

  bool get vazia => itens.isEmpty;
}

class MedicaoPichau {
  const MedicaoPichau({
    required this.momento,
    required this.precoPixTexto,
    required this.precoCartaoTexto,
  });

  factory MedicaoPichau.parse(Map<String, dynamic> objeto) => MedicaoPichau(
    momento: _textoPichau(objeto['momento']),
    precoPixTexto: _textoOpcionalPichau(objeto['preco_pix_texto']),
    precoCartaoTexto: _textoOpcionalPichau(objeto['preco_cartao_texto']),
  );

  final String momento;
  final String? precoPixTexto;
  final String? precoCartaoTexto;
}

class HistoricoPichau {
  const HistoricoPichau({
    required this.produto,
    required this.minimoPixTexto,
    required this.maximoPixTexto,
    required this.medicoes,
    required this.pagina,
    required this.porPagina,
    required this.totalItens,
    required this.temProxima,
  });

  factory HistoricoPichau.parse(Map<String, dynamic> objeto) {
    final medicoes =
        (objeto['medicoes'] as List<dynamic>?)
            ?.map((item) => MedicaoPichau.parse(item as Map<String, dynamic>))
            .toList(growable: false) ??
        const <MedicaoPichau>[];
    final produto = objeto['produto'];
    return HistoricoPichau(
      produto: produto is Map<String, dynamic>
          ? PichauProduto.parse(produto)
          : null,
      minimoPixTexto: _textoOpcionalPichau(objeto['minimo_pix_texto']),
      maximoPixTexto: _textoOpcionalPichau(objeto['maximo_pix_texto']),
      medicoes: medicoes,
      pagina: (objeto['pagina'] as num?)?.toInt() ?? 1,
      porPagina: (objeto['por_pagina'] as num?)?.toInt() ?? 30,
      totalItens: (objeto['total_itens'] as num?)?.toInt() ?? medicoes.length,
      temProxima: objeto['tem_proxima'] as bool? ?? false,
    );
  }

  final PichauProduto? produto;
  final String? minimoPixTexto;
  final String? maximoPixTexto;
  final List<MedicaoPichau> medicoes;
  final int pagina;
  final int porPagina;
  final int totalItens;
  final bool temProxima;
}

String _textoPichau(Object? valor) => valor?.toString() ?? '';

String? _textoOpcionalPichau(Object? valor) {
  final texto = _textoPichau(valor).trim();
  return texto.isEmpty ? null : texto;
}

int _inteiroNaoNegativoPichau(Object? valor, {int fallback = 0}) {
  final numero = valor is num ? valor.toInt() : int.tryParse('$valor');
  return numero == null || numero < 0 ? fallback : numero;
}
