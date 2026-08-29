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

/// Uma medição de preço do histórico de 30 dias de um produto direto.
///
/// Valores NUMERIC permanecem texto até a apresentação (PRD-V4 RNF29).
class MedicaoProdutoDireto {
  const MedicaoProdutoDireto({
    required this.momento,
    required this.precoAtualValor,
    required this.cashbackValor,
    required this.precoLiquidoValor,
  });

  factory MedicaoProdutoDireto.parse(Map<String, dynamic> objeto) {
    return MedicaoProdutoDireto(
      momento: _texto(objeto['momento']),
      precoAtualValor: _texto(objeto['preco_atual_valor']),
      cashbackValor: _textoOpcional(objeto['cashback_valor']),
      precoLiquidoValor: _textoOpcional(objeto['preco_liquido_valor']),
    );
  }

  final String momento;
  final String precoAtualValor;
  final String? cashbackValor;
  final String? precoLiquidoValor;
}

/// Resposta do histórico de um produto em uma loja (PRD-V4 RF46/RN78).
class HistoricoProdutoDireto {
  const HistoricoProdutoDireto({
    required this.produto,
    required this.minimo,
    required this.maximo,
    required this.medicoes,
    required this.pagina,
    required this.porPagina,
    required this.totalItens,
    required this.temProxima,
  });

  factory HistoricoProdutoDireto.parse(Map<String, dynamic> objeto) {
    final medicoes =
        (objeto['medicoes'] as List<dynamic>?)
            ?.map(
              (item) =>
                  MedicaoProdutoDireto.parse(item as Map<String, dynamic>),
            )
            .toList(growable: false) ??
        const <MedicaoProdutoDireto>[];
    return HistoricoProdutoDireto(
      produto: ProdutoDireto.parse(objeto['produto'] as Map<String, dynamic>),
      minimo: _textoOpcional(objeto['minimo']),
      maximo: _textoOpcional(objeto['maximo']),
      medicoes: medicoes,
      pagina: (objeto['pagina'] as num?)?.toInt() ?? 1,
      porPagina: (objeto['por_pagina'] as num?)?.toInt() ?? 30,
      totalItens: (objeto['total_itens'] as num?)?.toInt() ?? medicoes.length,
      temProxima: objeto['tem_proxima'] as bool? ?? false,
    );
  }

  final ProdutoDireto produto;
  final String? minimo;
  final String? maximo;
  final List<MedicaoProdutoDireto> medicoes;
  final int pagina;
  final int porPagina;
  final int totalItens;
  final bool temProxima;
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

  LojaDireto copiarCom({bool? selecionada}) => LojaDireto(
    id: id,
    idExterno: idExterno,
    slug: slug,
    nome: nome,
    selecionada: selecionada ?? this.selecionada,
    ativa: ativa,
  );
}

/// Loja disponível no catálogo dos Sites parceiros do Inter.
///
/// A oferta continua textual porque cashback é dado financeiro; a seleção de
/// favorita é um estado administrativo, não um cálculo no aplicativo.
class LojaCatalogoInter {
  const LojaCatalogoInter({
    required this.id,
    required this.idExterno,
    required this.slug,
    required this.nome,
    required this.cashbackPrincipalTexto,
    required this.cashbackPrincipalValor,
    required this.ativa,
    required this.favorita,
  });

  factory LojaCatalogoInter.parse(Map<String, dynamic> objeto) =>
      LojaCatalogoInter(
        id: _texto(objeto['id']),
        idExterno: _texto(objeto['id_externo']),
        slug: _texto(objeto['slug']),
        nome: _texto(objeto['nome']),
        cashbackPrincipalTexto: _texto(objeto['cashback_principal_texto']),
        cashbackPrincipalValor: _textoOpcional(
          objeto['cashback_principal_valor'],
        ),
        ativa: _booleano(objeto['ativa']),
        favorita: _booleano(objeto['favorita']),
      );

  final String id;
  final String idExterno;
  final String slug;
  final String nome;
  final String cashbackPrincipalTexto;
  final String? cashbackPrincipalValor;
  final bool ativa;
  final bool favorita;

  LojaCatalogoInter copiarCom({bool? favorita}) => LojaCatalogoInter(
    id: id,
    idExterno: idExterno,
    slug: slug,
    nome: nome,
    cashbackPrincipalTexto: cashbackPrincipalTexto,
    cashbackPrincipalValor: cashbackPrincipalValor,
    ativa: ativa,
    favorita: favorita ?? this.favorita,
  );
}

/// Loja Livelo disponível para administração.
///
/// Limiares continuam como texto decimal. `null` significa herdar a
/// preferência global, não ausência acidental nem zero.
class LojaLiveloAdministrativa {
  const LojaLiveloAdministrativa({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.multiplicador,
    required this.piso,
    required this.apelidos,
  });

  factory LojaLiveloAdministrativa.parse(Map<String, dynamic> objeto) =>
      LojaLiveloAdministrativa(
        id: _texto(objeto['id']),
        nome: _texto(objeto['nome']),
        categoria: _texto(objeto['categoria']),
        multiplicador: _textoOpcional(objeto['multiplicador']),
        piso: _textoOpcional(objeto['piso_pontos']),
        apelidos:
            (objeto['apelidos'] as List<dynamic>?)
                ?.map(_texto)
                .where((valor) => valor.isNotEmpty)
                .toList(growable: false) ??
            const <String>[],
      );

  final String id;
  final String nome;
  final String categoria;
  final String? multiplicador;
  final String? piso;
  final List<String> apelidos;

  LojaLiveloAdministrativa comRegra({
    required String? multiplicador,
    required String? piso,
  }) => LojaLiveloAdministrativa(
    id: id,
    nome: nome,
    categoria: categoria,
    multiplicador: multiplicador,
    piso: piso,
    apelidos: apelidos,
  );
}

class PreferenciasLiveloAdministrativas {
  const PreferenciasLiveloAdministrativas({
    required this.multiplicador,
    required this.piso,
    required this.assinanteClube,
  });

  factory PreferenciasLiveloAdministrativas.parse(
    Map<String, dynamic> objeto,
  ) => PreferenciasLiveloAdministrativas(
    multiplicador: _texto(objeto['multiplicador_padrao']),
    piso: _texto(objeto['piso_pontos_padrao']),
    assinanteClube: _booleano(objeto['assinante_clube']),
  );

  final String multiplicador;
  final String piso;
  final bool assinanteClube;
}

class ResumoLimpezaAdministrativa {
  const ResumoLimpezaAdministrativa({
    required this.dominio,
    required this.fraseConfirmacao,
    required this.contagens,
  });

  factory ResumoLimpezaAdministrativa.parse(Map<String, dynamic> objeto) {
    final contagensBrutas = objeto['contagens'];
    final contagens = <String, int>{};
    if (contagensBrutas is Map) {
      for (final entrada in contagensBrutas.entries) {
        final valor = entrada.value;
        if (valor is num) {
          contagens[entrada.key.toString()] = valor.toInt();
        }
      }
    }
    return ResumoLimpezaAdministrativa(
      dominio: _texto(objeto['dominio']),
      fraseConfirmacao: _texto(objeto['frase_confirmacao']),
      contagens: Map<String, int>.unmodifiable(contagens),
    );
  }

  final String dominio;
  final String fraseConfirmacao;
  final Map<String, int> contagens;
}

/// Oferta persistida dos Sites parceiros do Inter (PRD-V3 RN32–RN40).
///
/// Percentuais permanecem em texto: o aplicativo exibe o texto da fonte e
/// nunca usa `double` para reconstruir uma oferta financeira.
class CashbackInter {
  const CashbackInter({
    required this.id,
    required this.slug,
    required this.nome,
    required this.cashbackPrincipalTexto,
    required this.cashbackPrincipalValor,
    required this.cashbackSecundarioTexto,
    required this.cashbackSecundarioValor,
    required this.etiqueta,
    required this.descricaoPrincipal,
    required this.descricaoSecundaria,
    required this.encontrada,
    required this.favorita,
  });

  factory CashbackInter.parse(Map<String, dynamic> objeto) => CashbackInter(
    id: _texto(objeto['id']),
    slug: _texto(objeto['slug']),
    nome: _texto(objeto['nome']),
    cashbackPrincipalTexto: _textoOpcional(objeto['cashback_principal_texto']),
    cashbackPrincipalValor: _textoOpcional(objeto['cashback_principal_valor']),
    cashbackSecundarioTexto: _textoOpcional(
      objeto['cashback_secundario_texto'],
    ),
    cashbackSecundarioValor: _textoOpcional(
      objeto['cashback_secundario_valor'],
    ),
    etiqueta: _textoOpcional(objeto['etiqueta']),
    descricaoPrincipal: _textoOpcional(objeto['descricao_principal']),
    descricaoSecundaria: _textoOpcional(objeto['descricao_secundaria']),
    encontrada: _booleano(objeto['encontrada']),
    favorita: _booleano(objeto['favorita']),
  );

  final String id;
  final String slug;
  final String nome;
  final String? cashbackPrincipalTexto;
  final String? cashbackPrincipalValor;
  final String? cashbackSecundarioTexto;
  final String? cashbackSecundarioValor;
  final String? etiqueta;
  final String? descricaoPrincipal;
  final String? descricaoSecundaria;
  final bool encontrada;
  final bool favorita;
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

enum EstadoResumo {
  atualizado,
  atencao,
  atrasado,
  atualizando,
  falhaRecente,
  parcial,
  degradado,
  semDados,
  indisponivel;

  factory EstadoResumo.parse(Object? valor) => switch (valor?.toString()) {
    'atualizado' => atualizado,
    'atencao' => atencao,
    'atrasado' => atrasado,
    'atualizando' => atualizando,
    'falha_recente' => falhaRecente,
    'parcial' => parcial,
    'degradado' => degradado,
    'sem_dados' => semDados,
    _ => indisponivel,
  };
}

class ResumoLivelo {
  const ResumoLivelo({
    required this.estado,
    required this.ultimoSucessoEm,
    required this.lojasAcompanhadas,
    required this.alertasUltimaColeta,
    required this.agendamento,
  });

  factory ResumoLivelo.parse(Map<String, dynamic> objeto) => ResumoLivelo(
    estado: EstadoResumo.parse(objeto['estado']),
    ultimoSucessoEm: _textoOpcional(objeto['ultimo_sucesso_em']),
    lojasAcompanhadas: _inteiroNaoNegativo(objeto['lojas_acompanhadas']),
    alertasUltimaColeta: _inteiroNaoNegativo(objeto['alertas_ultima_coleta']),
    agendamento: AgendamentoLivelo.parse(_mapa(objeto['agendamento'])),
  );

  final EstadoResumo estado;
  final String? ultimoSucessoEm;
  final int lojasAcompanhadas;
  final int alertasUltimaColeta;
  final AgendamentoLivelo agendamento;
}

class AgendamentoLivelo {
  const AgendamentoLivelo({required this.estado, required this.referenciaEm});
  factory AgendamentoLivelo.parse(Map<String, dynamic> objeto) =>
      AgendamentoLivelo(
        estado: _texto(objeto['estado']),
        referenciaEm: _texto(objeto['referencia_em']),
      );
  final String estado;
  final String referenciaEm;
  bool get aguardando => estado == 'aguardando';
}

class AtividadeRecente {
  const AtividadeRecente({
    required this.dominio,
    required this.estado,
    required this.momento,
  });
  factory AtividadeRecente.parse(Map<String, dynamic> objeto) =>
      AtividadeRecente(
        dominio: _texto(objeto['dominio']),
        estado: _texto(objeto['estado']),
        momento: _textoOpcional(objeto['momento']),
      );
  final String dominio;
  final String estado;
  final String? momento;
}

class ResumoCashbackInter {
  const ResumoCashbackInter({
    required this.estado,
    required this.ultimaTentativaEm,
    required this.ultimaTentativaEstado,
    required this.ultimoSucessoEm,
    required this.lojasAcompanhadas,
    required this.lojasEncontradasUltimaColeta,
  });

  factory ResumoCashbackInter.parse(Map<String, dynamic> objeto) =>
      ResumoCashbackInter(
        estado: EstadoResumo.parse(objeto['estado']),
        ultimaTentativaEm: _textoOpcional(objeto['ultima_tentativa_em']),
        ultimaTentativaEstado: _textoOpcional(
          objeto['ultima_tentativa_estado'],
        ),
        ultimoSucessoEm: _textoOpcional(objeto['ultimo_sucesso_em']),
        lojasAcompanhadas: _inteiroNaoNegativo(objeto['lojas_acompanhadas']),
        lojasEncontradasUltimaColeta: _inteiroNaoNegativo(
          objeto['lojas_encontradas_ultima_coleta'],
        ),
      );

  final EstadoResumo estado;
  final String? ultimaTentativaEm;
  final String? ultimaTentativaEstado;
  final String? ultimoSucessoEm;
  final int lojasAcompanhadas;
  final int lojasEncontradasUltimaColeta;
}

class ResumoProdutos {
  const ResumoProdutos({
    required this.estado,
    required this.ultimaTentativaEm,
    required this.ultimaTentativaEstado,
    required this.dadosMaisAntigosEm,
    required this.dadosMaisRecentesEm,
    required this.qualidade,
    required this.lojasSelecionadas,
    required this.lojasSemColeta,
    required this.produtosAtivos,
  });

  factory ResumoProdutos.parse(Map<String, dynamic> objeto) => ResumoProdutos(
    estado: EstadoResumo.parse(objeto['estado']),
    ultimaTentativaEm: _textoOpcional(objeto['ultima_tentativa_em']),
    ultimaTentativaEstado: _textoOpcional(objeto['ultima_tentativa_estado']),
    dadosMaisAntigosEm: _textoOpcional(objeto['dados_mais_antigos_em']),
    dadosMaisRecentesEm: _textoOpcional(objeto['dados_mais_recentes_em']),
    qualidade: _textoOpcional(objeto['qualidade']),
    lojasSelecionadas: _inteiroNaoNegativo(objeto['lojas_selecionadas']),
    lojasSemColeta: _inteiroNaoNegativo(objeto['lojas_sem_coleta']),
    produtosAtivos: _inteiroNaoNegativo(objeto['produtos_ativos']),
  );

  final EstadoResumo estado;
  final String? ultimaTentativaEm;
  final String? ultimaTentativaEstado;
  final String? dadosMaisAntigosEm;
  final String? dadosMaisRecentesEm;
  final String? qualidade;
  final int lojasSelecionadas;
  final int lojasSemColeta;
  final int produtosAtivos;
}

class ResumoInicio {
  const ResumoInicio({
    required this.geradoEm,
    required this.estadoGeral,
    required this.livelo,
    required this.cashbackInter,
    required this.produtos,
    this.atividadeRecente = const [],
  });

  factory ResumoInicio.parse(Map<String, dynamic> objeto) => ResumoInicio(
    geradoEm: _texto(objeto['gerado_em']),
    estadoGeral: EstadoResumo.parse(objeto['estado_geral']),
    livelo: ResumoLivelo.parse(_mapa(objeto['livelo'])),
    cashbackInter: ResumoCashbackInter.parse(_mapa(objeto['cashback_inter'])),
    produtos: ResumoProdutos.parse(_mapa(objeto['produtos'])),
    atividadeRecente:
        (objeto['atividade_recente'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(AtividadeRecente.parse)
            .toList(growable: false) ??
        const [],
  );

  final String geradoEm;
  final EstadoResumo estadoGeral;
  final ResumoLivelo livelo;
  final ResumoCashbackInter cashbackInter;
  final ResumoProdutos produtos;
  final List<AtividadeRecente> atividadeRecente;
}

class PerfilUsuario {
  const PerfilUsuario({
    required this.id,
    required this.email,
    required this.papel,
  });

  factory PerfilUsuario.parse(Map<String, dynamic> objeto) {
    return PerfilUsuario(
      id: _texto(objeto['id']),
      email: _texto(objeto['email']),
      papel: _texto(objeto['papel']),
    );
  }

  final String id;
  final String email;
  final String papel;

  bool get administrador => papel == 'admin';
}

/// Estado da última solicitação manual de coleta, não da coleta em si.
class EstadoDisparoAdministrativo {
  const EstadoDisparoAdministrativo({
    required this.dominio,
    required this.cooldownSegundos,
    required this.ultimaSolicitacaoEm,
    required this.ultimoEstado,
  });

  factory EstadoDisparoAdministrativo.parse(Map<String, dynamic> objeto) =>
      EstadoDisparoAdministrativo(
        dominio: _texto(objeto['dominio']),
        cooldownSegundos: (objeto['cooldown_segundos'] as num?)?.toInt() ?? 0,
        ultimaSolicitacaoEm: _textoOpcional(objeto['ultima_solicitacao_em']),
        ultimoEstado: _textoOpcional(objeto['ultimo_estado']),
      );

  final String dominio;
  final int cooldownSegundos;
  final String? ultimaSolicitacaoEm;
  final String? ultimoEstado;
}

/// Resposta de uma solicitação aceita ou ainda em reserva no servidor.
class ResultadoDisparoAdministrativo {
  const ResultadoDisparoAdministrativo({
    required this.dominio,
    required this.estado,
    required this.cooldownSegundos,
  });

  factory ResultadoDisparoAdministrativo.parse(Map<String, dynamic> objeto) =>
      ResultadoDisparoAdministrativo(
        dominio: _texto(objeto['dominio']),
        estado: _texto(objeto['estado']),
        cooldownSegundos: (objeto['cooldown_segundos'] as num?)?.toInt() ?? 0,
      );

  final String dominio;
  final String estado;
  final int cooldownSegundos;
}

/// Uma loja do painel Livelo, como retornada pela API v1.
///
/// Campos decimais permanecem texto do início ao fim. O Postgres entrega
/// `NUMERIC` como string e convertê-lo para `double` no cliente reabriria a
/// perda de precisão que o domínio Python evita com `Decimal`.
class PontuacaoLivelo {
  const PontuacaoLivelo({
    required this.nome,
    required this.categoria,
    required this.pontosAtuais,
    required this.pontosBase,
    required this.pontosClube,
    required this.valorDeDisparo,
    required this.moeda,
    required this.prefixoAte,
    required this.emPromocao,
    required this.alertou,
    required this.campanha,
    required this.descricaoCampanha,
    required this.fimPromocao,
  });

  factory PontuacaoLivelo.parse(Map<String, dynamic> objeto) {
    return PontuacaoLivelo(
      nome: _texto(objeto['nome']),
      categoria: _textoOpcional(objeto['categoria']),
      pontosAtuais: _textoOpcional(objeto['pontos_atuais']),
      pontosBase: _textoOpcional(objeto['pontos_base']),
      pontosClube: _textoOpcional(objeto['pontos_clube']),
      valorDeDisparo: _textoOpcional(objeto['valor_de_disparo']),
      moeda: _texto(objeto['moeda']),
      prefixoAte: _booleano(objeto['prefixo_ate']),
      emPromocao: _booleano(objeto['em_promocao']),
      alertou: _booleano(objeto['alertou']),
      campanha: _textoOpcional(objeto['campanha']),
      descricaoCampanha: _textoOpcional(objeto['descricao_campanha']),
      fimPromocao: _textoOpcional(objeto['fim_promocao']),
    );
  }

  /// Nome canônico é a identidade única entre páginas da Livelo.
  final String nome;
  final String? categoria;
  final String? pontosAtuais;
  final String? pontosBase;
  final String? pontosClube;
  final String? valorDeDisparo;
  final String moeda;
  final bool prefixoAte;
  final bool emPromocao;
  final bool alertou;
  final String? campanha;
  final String? descricaoCampanha;
  final String? fimPromocao;
}

class MedicaoHistoricoLivelo {
  const MedicaoHistoricoLivelo({
    required this.momento,
    required this.pontos,
    required this.moeda,
  });
  factory MedicaoHistoricoLivelo.parse(Map<String, dynamic> objeto) =>
      MedicaoHistoricoLivelo(
        momento: _texto(objeto['momento']),
        pontos: _textoOpcional(objeto['pontos_atuais']),
        moeda: _texto(objeto['moeda']),
      );
  final String momento;
  final String? pontos;
  final String moeda;
}

class HistoricoLivelo {
  const HistoricoLivelo({required this.medicoes});
  factory HistoricoLivelo.parse(Map<String, dynamic> objeto) => HistoricoLivelo(
    medicoes:
        (objeto['medicoes'] as List<dynamic>?)
            ?.map(
              (item) =>
                  MedicaoHistoricoLivelo.parse(item as Map<String, dynamic>),
            )
            .toList(growable: false) ??
        const [],
  );
  final List<MedicaoHistoricoLivelo> medicoes;
}

/// Parceiro da última coleta válida da Livelo, acompanhado ou não.
class ParceiroCatalogoLivelo {
  const ParceiroCatalogoLivelo({
    required this.idExterno,
    required this.nome,
    required this.categorias,
    required this.pontosAtuais,
    required this.pontosAnteriores,
    required this.pontosBase,
    required this.pontosClube,
    required this.moeda,
    required this.prefixoAte,
    required this.emPromocao,
    required this.campanha,
    required this.descricaoCampanha,
    required this.inicioPromocao,
    required this.fimPromocao,
    required this.acompanhada,
    this.alertaAtivo = false,
    required this.alerta,
    this.link,
  });

  factory ParceiroCatalogoLivelo.parse(Map<String, dynamic> objeto) =>
      ParceiroCatalogoLivelo(
        idExterno: _texto(objeto['id_externo']),
        nome: _texto(objeto['nome']),
        categorias:
            (objeto['categorias'] as List<dynamic>?)
                ?.map(_texto)
                .where((item) => item.isNotEmpty)
                .toList(growable: false) ??
            const <String>['Outros'],
        pontosAtuais: _texto(objeto['pontos_atuais']),
        pontosAnteriores: _textoOpcional(objeto['pontos_anteriores']),
        pontosBase: _textoOpcional(objeto['pontos_base']),
        pontosClube: _textoOpcional(objeto['pontos_clube']),
        moeda: _texto(objeto['moeda']),
        prefixoAte: _booleano(objeto['prefixo_ate']),
        emPromocao: _booleano(objeto['em_promocao']),
        campanha: _textoOpcional(objeto['campanha']),
        descricaoCampanha: _textoOpcional(objeto['descricao_campanha']),
        inicioPromocao: _textoOpcional(objeto['inicio_promocao']),
        fimPromocao: _textoOpcional(objeto['fim_promocao']),
        link: _textoOpcional(objeto['link']),
        acompanhada: _booleano(objeto['acompanhada']),
        alertaAtivo: _booleano(objeto['alerta_ativo']),
        alerta: _booleano(objeto['alerta']),
      );

  final String idExterno;
  final String nome;
  final List<String> categorias;
  final String pontosAtuais;
  final String? pontosAnteriores;
  final String? pontosBase;
  final String? pontosClube;
  final String moeda;
  final bool prefixoAte;
  final bool emPromocao;
  final String? campanha;
  final String? descricaoCampanha;
  final String? inicioPromocao;
  final String? fimPromocao;
  final bool acompanhada;
  final bool alertaAtivo;
  final bool alerta;
  final String? link;

  ParceiroCatalogoLivelo copiarCom({
    bool? acompanhada,
    bool? alertaAtivo,
    bool? alerta,
  }) => ParceiroCatalogoLivelo(
    idExterno: idExterno,
    nome: nome,
    categorias: categorias,
    pontosAtuais: pontosAtuais,
    pontosAnteriores: pontosAnteriores,
    pontosBase: pontosBase,
    pontosClube: pontosClube,
    moeda: moeda,
    prefixoAte: prefixoAte,
    emPromocao: emPromocao,
    campanha: campanha,
    descricaoCampanha: descricaoCampanha,
    inicioPromocao: inicioPromocao,
    fimPromocao: fimPromocao,
    acompanhada: acompanhada ?? this.acompanhada,
    alertaAtivo: alertaAtivo ?? this.alertaAtivo,
    alerta: alerta ?? this.alerta,
    link: link,
  );
}

class MelhorOfertaLivelo {
  const MelhorOfertaLivelo({
    required this.idExterno,
    required this.nome,
    required this.pontosAtuais,
    required this.moeda,
    required this.prefixoAte,
  });

  factory MelhorOfertaLivelo.parse(Map<String, dynamic> objeto) =>
      MelhorOfertaLivelo(
        idExterno: _texto(objeto['id_externo']),
        nome: _texto(objeto['nome']),
        pontosAtuais: _texto(objeto['pontos_atuais']),
        moeda: _texto(objeto['moeda']),
        prefixoAte: _booleano(objeto['prefixo_ate']),
      );

  final String idExterno;
  final String nome;
  final String pontosAtuais;
  final String moeda;
  final bool prefixoAte;
}

class ResumoCatalogoLivelo {
  const ResumoCatalogoLivelo({
    required this.ultimaColeta,
    required this.parceirosLidos,
    required this.totalCatalogo,
    required this.acompanhadas,
    required this.alertas,
    this.alertasAtivos = 0,
    required this.melhorOferta,
  });

  factory ResumoCatalogoLivelo.parse(Map<String, dynamic> objeto) {
    final melhor = objeto['melhor_oferta'];
    return ResumoCatalogoLivelo(
      ultimaColeta: _textoOpcional(objeto['ultima_coleta']),
      parceirosLidos: _inteiroNaoNegativo(objeto['parceiros_lidos']),
      totalCatalogo: _inteiroNaoNegativo(objeto['total_catalogo']),
      acompanhadas: _inteiroNaoNegativo(objeto['acompanhadas']),
      alertas: _inteiroNaoNegativo(objeto['alertas']),
      alertasAtivos: _inteiroNaoNegativo(objeto['alertas_ativos']),
      melhorOferta: melhor is Map<String, dynamic>
          ? MelhorOfertaLivelo.parse(melhor)
          : null,
    );
  }

  final String? ultimaColeta;
  final int parceirosLidos;
  final int totalCatalogo;
  final int acompanhadas;
  final int alertas;
  final int alertasAtivos;
  final MelhorOfertaLivelo? melhorOferta;

  ResumoCatalogoLivelo copiarCom({
    int? acompanhadas,
    int? alertas,
    int? alertasAtivos,
  }) {
    final novasAcompanhadas = acompanhadas ?? this.acompanhadas;
    final novosAlertas = alertas ?? this.alertas;
    final novosAlertasAtivos = alertasAtivos ?? this.alertasAtivos;
    return ResumoCatalogoLivelo(
      ultimaColeta: ultimaColeta,
      parceirosLidos: parceirosLidos,
      totalCatalogo: totalCatalogo,
      acompanhadas: novasAcompanhadas < 0 ? 0 : novasAcompanhadas,
      alertas: novosAlertas < 0 ? 0 : novosAlertas,
      alertasAtivos: novosAlertasAtivos < 0 ? 0 : novosAlertasAtivos,
      melhorOferta: melhorOferta,
    );
  }
}

class PaginaCatalogoLivelo {
  const PaginaCatalogoLivelo({
    required this.itens,
    required this.resumo,
    required this.categorias,
    required this.pagina,
    required this.porPagina,
    required this.totalItens,
    required this.totalPaginas,
    required this.temProxima,
  });

  factory PaginaCatalogoLivelo.parse(Map<String, dynamic> objeto) =>
      PaginaCatalogoLivelo(
        itens:
            (objeto['itens'] as List<dynamic>?)
                ?.map(
                  (item) => ParceiroCatalogoLivelo.parse(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList(growable: false) ??
            const <ParceiroCatalogoLivelo>[],
        resumo: ResumoCatalogoLivelo.parse(_mapa(objeto['resumo'])),
        categorias:
            (objeto['categorias'] as List<dynamic>?)
                ?.map(_texto)
                .where((item) => item.isNotEmpty)
                .toList(growable: false) ??
            const <String>[],
        pagina: (objeto['pagina'] as num?)?.toInt() ?? 1,
        porPagina: (objeto['por_pagina'] as num?)?.toInt() ?? 20,
        totalItens: (objeto['total_itens'] as num?)?.toInt() ?? 0,
        totalPaginas: (objeto['total_paginas'] as num?)?.toInt() ?? 1,
        temProxima: _booleano(objeto['tem_proxima']),
      );

  final List<ParceiroCatalogoLivelo> itens;
  final ResumoCatalogoLivelo resumo;
  final List<String> categorias;
  final int pagina;
  final int porPagina;
  final int totalItens;
  final int totalPaginas;
  final bool temProxima;
}

String _texto(Object? valor) => valor?.toString() ?? '';

String? _textoOpcional(Object? valor) {
  final texto = valor?.toString().trim();
  return texto == null || texto.isEmpty ? null : texto;
}

bool _booleano(Object? valor) {
  if (valor is bool) {
    return valor;
  }
  final texto = valor?.toString().trim().toLowerCase() ?? '';
  return texto == 'true' || texto == '1' || texto == 'on';
}

int _inteiroNaoNegativo(Object? valor) {
  final convertido = valor is num
      ? valor.toInt()
      : int.tryParse(valor?.toString() ?? '') ?? 0;
  return convertido < 0 ? 0 : convertido;
}

Map<String, dynamic> _mapa(Object? valor) =>
    valor is Map<String, dynamic> ? valor : <String, dynamic>{};
