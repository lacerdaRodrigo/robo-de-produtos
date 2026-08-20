/// Modelos de domínio que o Flutter lê da API v1.
///
/// Conversão manual de JSON de propósito: sem geração de código nem
/// dependência de serialização (PLANO §11 escolhe bibliotecas na fase própria).
/// Valores monetários chegam como string, nunca `double` (PRD 5.4}.
class ProdutoDireto {
  const ProdutoDireto({
    required this.idExterno,
    required this.nome,
    required this.marca,
    required this.categoria,
    required this.caminho,
    required this.precoCheioTexto,
    required this.precoCheioValor,
    required this.precoAtualTexto,
    required this.precoAtualValor,
    required this.descontoTexto,
    required this.descontoPercentualTexto,
    required this.cashbackTexto,
    required this.cashbackPercentualTexto,
    required this.precoLiquidoTexto,
    required this.parcelamento,
    required this.estoque,
    required this.etiquetas,
    required this.lojaSlug,
    required this.lojaNome,
    required this.atualizadaEm,
  });

  factory ProdutoDireto.parse(Map<String, dynamic> objeto) {
    return ProdutoDireto(
      idExterno: _texto(objeto['id_externo']),
      nome: _texto(objeto['nome']),
      marca: objeto['marca'] as String?,
      categoria: objeto['categoria'] as String?,
      caminho: _texto(objeto['caminho']),
      precoCheioTexto: objeto['preco_cheio_texto'] as String?,
      precoCheioValor: objeto['preco_cheio_valor'] as String?,
      precoAtualTexto: _texto(objeto['preco_atual_texto']),
      precoAtualValor: _texto(objeto['preco_atual_valor']),
      descontoTexto: objeto['desconto_texto'] as String?,
      descontoPercentualTexto: objeto['desconto_percentual_texto'] as String?,
      cashbackTexto: objeto['cashback_texto'] as String?,
      cashbackPercentualTexto: objeto['cashback_percentual_texto'] as String?,
      precoLiquidoTexto: objeto['preco_liquido_texto'] as String?,
      parcelamento: objeto['parcelamento'] as String?,
      estoque: (objeto['estoque'] as num?)?.toInt(),
      etiquetas:
          (objeto['etiquetas'] as List<dynamic>?)?.map(_texto).toList() ??
          const [],
      lojaSlug: _texto(objeto['loja_slug']),
      lojaNome: _texto(objeto['loja_nome']),
      atualizadaEm: _texto(objeto['atualizada_em']),
    );
  }

  final String idExterno;
  final String nome;
  final String? marca;
  final String? categoria;
  final String caminho;

  /// Preço cheio (texto exibido + valor em string decimal).
  final String? precoCheioTexto;
  final String? precoCheioValor;

  /// Preço atual — sempre presentes; ausência nunca vira zero (RN).
  final String precoAtualTexto;
  final String precoAtualValor;

  final String? descontoTexto;
  final String? descontoPercentualTexto;
  final String? cashbackTexto;
  final String? cashbackPercentualTexto;
  final String? precoLiquidoTexto;
  final String? parcelamento;
  final int? estoque;
  final List<String> etiquetas;
  final String lojaSlug;
  final String lojaNome;
  final String atualizadaEm;
}

class LojaDireto {
  const LojaDireto({
    required this.id,
    required this.idExterno,
    required this.slug,
    required this.nome,
    required this.selecionada,
    required this.ativa,
  });

  factory LojaDireto.parse(Map<String, dynamic> objeto) {
    return LojaDireto(
      id: _texto(objeto['id']),
      idExterno: _texto(objeto['id_externo']),
      slug: _texto(objeto['slug']),
      nome: _texto(objeto['nome']),
      selecionada: _booleano(objeto['selecionada']),
      ativa: _booleano(objeto['ativa']),
    );
  }

  final String id;
  final String idExterno;
  final String slug;
  final String nome;
  final bool selecionada;
  final bool ativa;
}

class StatusApi {
  const StatusApi({required this.api, required this.saudavel});

  factory StatusApi.parse(Map<String, dynamic> objeto) {
    return StatusApi(
      api: _texto(objeto['api']),
      saudavel: _booleano(objeto['saudavel']),
    );
  }

  final String api;
  final bool saudavel;
}

String _texto(Object? valor) => valor?.toString() ?? '';

bool _booleano(Object? valor) {
  if (valor is bool) {
    return valor;
  }
  final texto = valor?.toString().trim().toLowerCase() ?? '';
  return texto == 'true' || texto == '1' || texto == 'on';
}
