import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../administracao/botao_disparo.dart';
import 'cartao_produto.dart';
import 'controlador_busca_produtos.dart';
import 'formato_produtos.dart';
import 'link_shopping_inter.dart';
import 'pagina_historico_produto.dart';

/// Busca local de produtos diretos. Nunca consulta o Inter durante a digitação.
class PaginaProdutos extends StatefulWidget {
  const PaginaProdutos({
    super.key,
    required this.api,
    this.controlador,
    this.administrador = false,
    this.incorporada = false,
    this.mostrarTituloInterno = true,
    this.experienciaCompacta = false,
  });

  final Api api;
  final ControladorBuscaProdutos? controlador;
  final bool administrador;
  final bool incorporada;
  final bool mostrarTituloInterno;
  final bool experienciaCompacta;

  @override
  State<PaginaProdutos> createState() => _EstadoPaginaProdutos();
}

class _EstadoPaginaProdutos extends State<PaginaProdutos> {
  static const _itensPorPagina = 10;

  late final ControladorBuscaProdutos _controlador =
      widget.controlador ??
      ControladorBuscaProdutos(
        buscar:
            ({
              required termo,
              required pagina,
              marca,
              categoria,
              escopo,
              required semCategoria,
              loja,
              precoMin,
              precoMax,
            }) => widget.api.buscarProdutos(
              termo,
              pagina: pagina,
              porPagina: _itensPorPagina,
              marca: marca,
              categoria: categoria,
              escopo: escopo,
              semCategoria: semCategoria,
              loja: loja,
              precoMin: precoMin,
              precoMax: precoMax,
            ),
      );
  late final bool _controladorExterno = widget.controlador != null;
  final _campoBusca = TextEditingController();
  final _rolagem = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.experienciaCompacta &&
        !_controladorExterno &&
        _controlador.podeBuscar) {
      _controlador.carregarPadrao();
    }
  }

  @override
  void dispose() {
    _campoBusca.dispose();
    _rolagem.dispose();
    if (!_controladorExterno) _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corpo = AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) => _conteudo(context),
    );
    if (widget.incorporada) return corpo;
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos no Inter')),
      body: corpo,
    );
  }

  Widget _conteudo(BuildContext context) {
    if (widget.experienciaCompacta) return _conteudoCompacto(context);
    final cores = CoresRadar.de(context);
    final atrasado = coletaProdutosAtrasada(
      _controlador.atualizadoEm,
      DateTime.now(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.incorporada && widget.mostrarTituloInterno)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.experienciaCompacta ? 20 : 24,
                      24,
                      widget.experienciaCompacta ? 20 : 24,
                      0,
                    ),
                    child: widget.experienciaCompacta
                        ? const CabecalhoSecaoRadar(
                            sobrelinha: 'Catálogo local',
                            titulo: 'Buscar produtos',
                            descricao:
                                'A busca usa somente o catálogo salvo das lojas selecionadas. Digitar não consulta o Inter ao vivo.',
                          )
                        : Text(
                            'Produtos',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.experienciaCompacta ? 20 : 24,
                    widget.incorporada && widget.mostrarTituloInterno ? 12 : 16,
                    widget.experienciaCompacta ? 20 : 24,
                    0,
                  ),
                  child: BotaoDisparo(
                    api: widget.api,
                    dominio: 'produtos_inter',
                    administrador: widget.administrador,
                    rotulo: 'Atualizar Produtos',
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.experienciaCompacta ? 20 : 24,
                    20,
                    widget.experienciaCompacta ? 20 : 24,
                    8,
                  ),
                  child: CampoBuscaRadar(
                    controlador: _campoBusca,
                    chaveCampo: const Key('busca-produtos-principal'),
                    dica: widget.experienciaCompacta
                        ? 'Buscar produtos'
                        : 'Ex.: celular Motorola Edge 60 Pro',
                    aoMudar: _controlador.mudarTermo,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.experienciaCompacta ? 20 : 24,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _abrirFiltros,
                        icon: const Icon(Icons.tune),
                        label: Text(
                          _controlador.filtros.estaVazio
                              ? 'Filtros'
                              : 'Filtros ativos',
                        ),
                      ),
                      if (!_controlador.filtros.estaVazio)
                        TextButton(
                          onPressed: () {
                            _controlador.mudarFiltros(const FiltrosProdutos());
                          },
                          child: const Text('Limpar filtros'),
                        ),
                    ],
                  ),
                ),
                if (_controlador.atualizadoEm != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.experienciaCompacta ? 20 : 24,
                      12,
                      widget.experienciaCompacta ? 20 : 24,
                      0,
                    ),
                    child: Text(
                      'Atualização mais antiga destes resultados: '
                      '${dataHoraProduto(_controlador.atualizadoEm)}'
                      '${atrasado ? ' · dados atrasados' : ''}',
                      style: TextStyle(color: atrasado ? cores.atencao : null),
                    ),
                  ),
                if (_controlador.qualidade == 'degradada')
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      'Uma das lojas teve coleta degradada; produtos ausentes não foram removidos.',
                    ),
                  ),
                if (_avisoDaTentativa() case final aviso?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(aviso),
                  ),
                if (_controlador.termoValido &&
                    !_controlador.carregando &&
                    _controlador.erro == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            '${_controlador.totalItens} produtos · página '
                            '${_controlador.pagina} · ${_controlador.porPagina} por página',
                          ),
                        ),
                        Chip(label: Text(_rotuloQualidade())),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(flex: 3, child: _corpo()),
      ],
    );
  }

  Widget _conteudoCompacto(BuildContext context) {
    final cores = CoresRadar.de(context);
    final atrasado = coletaProdutosAtrasada(
      _controlador.atualizadoEm,
      DateTime.now(),
    );
    final avisoTentativa = _controlador.erro == null
        ? _avisoDaTentativa()
        : null;
    return CustomScrollView(
      key: const Key('produtos-compacto'),
      controller: _rolagem,
      slivers: [
        if (widget.mostrarTituloInterno)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 22, 18, 20),
            sliver: SliverToBoxAdapter(
              child: CabecalhoSecaoRadar(
                sobrelinha: 'Compre direto',
                titulo: 'Produtos',
                descricao:
                    'Pesquise ofertas salvas nas lojas que você selecionou. '
                    'Cada oferta mantém sua própria origem.',
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            18,
            widget.mostrarTituloInterno ? 0 : 18,
            18,
            16,
          ),
          sliver: SliverToBoxAdapter(
            child: _BuscaProdutosCompacta(
              controlador: _campoBusca,
              aoMudar: _controlador.mudarTermo,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          sliver: SliverToBoxAdapter(
            child: _EntradaEscopoProdutos(
              escopos: _controlador.filtros.escoposAtivos,
              rotulos: _controlador.filtros.escoposAtivos
                  .map(_rotuloDoEscopo)
                  .map((rotulo) => rotulo ?? '')
                  .toList(growable: false),
              aoAbrir: _abrirEscopoContextual,
              aoRemover: (escopo) {
                _controlador.mudarFiltros(
                  _controlador.filtros.copiarCom(
                    escopos: _controlador.filtros.escoposAtivos
                        .where((ativo) => ativo != escopo)
                        .toList(growable: false),
                  ),
                );
              },
              aoLimpar: () => _controlador.mudarFiltros(
                _controlador.filtros.copiarCom(escopos: const []),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _filtrosCompactos()),
        if (_controlador.atualizadoEm != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Atualização mais antiga destes resultados: '
                '${dataHoraProduto(_controlador.atualizadoEm)}'
                '${atrasado ? ' · dados atrasados' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: atrasado ? cores.atencao : cores.textoSuave,
                ),
              ),
            ),
          ),
        if (_controlador.qualidade == 'degradada')
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 8, 18, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Uma das lojas teve coleta degradada; produtos ausentes não foram removidos.',
              ),
            ),
          ),
        if (avisoTentativa != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
            sliver: SliverToBoxAdapter(child: Text(avisoTentativa)),
          ),
        if (_controlador.preservandoResultados)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            sliver: SliverToBoxAdapter(
              child: _AvisoFalhaBuscaProdutos(
                tentarNovamente: _controlador.tentarNovamente,
              ),
            ),
          ),
        if (_controlador.podeBuscar &&
            !_controlador.carregando &&
            (_controlador.erro == null || _controlador.preservandoResultados))
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 11),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _controlador.preservandoResultados
                          ? '${_controlador.itens.length} '
                                '${_controlador.itens.length == 1 ? 'oferta preservada' : 'ofertas preservadas'}'
                          : '${_controlador.totalItens} resultados encontrados',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!_controlador.preservandoResultados)
                    Text(
                      'Página ${_controlador.pagina}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cores.textoSuave,
                        fontSize: 9,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ..._corpoCompacto(),
        const SliverToBoxAdapter(child: SizedBox(height: 38)),
      ],
    );
  }

  String? _avisoDaTentativa() => switch (_controlador.ultimaTentativaEstado) {
    'iniciada' => 'As lojas destes resultados estão sendo atualizadas.',
    'parcial' => 'A atualização das lojas destes resultados foi parcial.',
    'falha' =>
      'A atualização destas lojas falhou; exibindo o último catálogo válido.',
    _ => null,
  };

  String _rotuloQualidade() => switch (_controlador.qualidade) {
    'completa' => 'Catálogo completo',
    'degradada' => 'Catálogo degradado',
    _ => 'Qualidade indisponível',
  };

  Widget _filtrosCompactos() => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _ChipProduto(
          texto: 'Todas selecionadas',
          ativo: _controlador.filtros.lojaOpcional == null,
          aoTocar: () => _controlador.mudarFiltros(
            _controlador.filtros.copiarCom(loja: ''),
          ),
        ),
        if (_controlador.filtros.lojaOpcional != null) ...[
          const SizedBox(width: 7),
          _ChipProduto(
            texto: _controlador.filtros.lojaOpcional!,
            ativo: true,
            aoTocar: () {},
          ),
        ],
        const SizedBox(width: 7),
        _ChipProduto(
          texto: _controlador.filtros.estaVazio ? 'Filtros' : 'Filtros ativos',
          icone: Icons.tune_rounded,
          aoTocar: _abrirFiltros,
        ),
      ],
    ),
  );

  List<Widget> _corpoCompacto() {
    if (!_controlador.podeBuscar) {
      return const [
        SliverToBoxAdapter(
          child: EstadoVazio(
            mensagem:
                'Digite pelo menos 2 caracteres para pesquisar no catálogo.',
          ),
        ),
      ];
    }
    if (_controlador.carregando && _controlador.itens.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Carregando(mensagem: 'Buscando produtos no catálogo…'),
          ),
        ),
      ];
    }
    if (_controlador.erro != null && _controlador.itens.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EstadoFalha(
            mensagem: 'Não foi possível buscar produtos agora.',
            voltar: _controlador.tentarNovamente,
          ),
        ),
      ];
    }
    if (_controlador.totalItens == 0) {
      return const [
        SliverToBoxAdapter(
          child: EstadoVazio(
            mensagem: 'Nenhum produto encontrado com esses filtros.',
          ),
        ),
      ];
    }
    final grupos = <String, List<ProdutoDireto>>{};
    for (final produto in _controlador.itens) {
      grupos.putIfAbsent(produto.lojaNome, () => []).add(produto);
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: grupos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 17),
          itemBuilder: (context, indice) {
            final entrada = grupos.entries.elementAt(indice);
            return _GrupoProdutosCompacto(
              key: ValueKey('grupo-produtos-${entrada.key}'),
              loja: entrada.key,
              produtos: entrada.value,
              construirCartao: (produto) =>
                  _cartao(produto, compacto: true, mostrarLoja: false),
            );
          },
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(18),
        sliver: SliverToBoxAdapter(child: _paginacao()),
      ),
    ];
  }

  Widget _corpo() {
    final cores = CoresRadar.de(context);
    if (!_controlador.termoValido) {
      return const EstadoVazio(
        mensagem: 'Digite pelo menos 2 caracteres para pesquisar no catálogo.',
      );
    }
    if (_controlador.carregando && _controlador.itens.isEmpty) {
      return const Carregando(mensagem: 'Buscando produtos no catálogo…');
    }
    if (_controlador.erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível buscar produtos agora.',
        voltar: _controlador.tentarNovamente,
      );
    }
    if (_controlador.totalItens == 0) {
      return const EstadoVazio(
        mensagem: 'Nenhum produto encontrado com esses filtros.',
      );
    }
    final grupos = <String, List<ProdutoDireto>>{};
    for (final produto in _controlador.itens) {
      grupos.putIfAbsent(produto.lojaNome, () => []).add(produto);
    }
    return LayoutBuilder(
      builder: (context, limites) {
        final duasColunas = limites.maxWidth >= 900;
        return ListView(
          controller: _rolagem,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            for (final entrada in grupos.entries) ...[
              Text(entrada.key, style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Atualizado: ${dataHoraProduto(entrada.value.first.atualizadaEm)}',
                style: TextStyle(
                  color:
                      coletaProdutosAtrasada(
                        entrada.value.first.atualizadaEm,
                        DateTime.now(),
                      )
                      ? cores.atencao
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              if (duasColunas)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final produto in entrada.value)
                      SizedBox(
                        width: (limites.maxWidth - 16) / 2,
                        child: _cartao(produto),
                      ),
                  ],
                )
              else
                for (final produto in entrada.value) _cartao(produto),
              const SizedBox(height: 16),
            ],
            _paginacao(),
          ],
        );
      },
    );
  }

  Widget _cartao(
    ProdutoDireto produto, {
    bool compacto = false,
    bool mostrarLoja = true,
  }) {
    final link = linkSeguroShoppingInter(produto.caminho);
    return CartaoProduto(
      produto: produto,
      compacto: compacto,
      mostrarLoja: mostrarLoja,
      aoAbrirHistorico: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PaginaHistoricoProduto(api: widget.api, produto: produto),
          ),
        );
      },
      aoAbrirNoShopping: link == null ? null : () => _abrirNoShopping(link),
    );
  }

  Future<void> _abrirNoShopping(Uri link) async {
    final abriu = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o Shopping Inter.'),
        ),
      );
    }
  }

  Widget _paginacao() {
    if (_controlador.erro != null) return const SizedBox.shrink();
    return PaginacaoRadar(
      pagina: _controlador.pagina,
      totalItens: _controlador.totalItens,
      porPagina: _controlador.porPagina,
      carregando: _controlador.carregandoMais,
      erro: _controlador.erroMais,
      aoIrParaPagina: _irParaPagina,
    );
  }

  Future<void> _irParaPagina(int pagina) async {
    await _controlador.irParaPagina(pagina);
    if (!mounted || _controlador.pagina != pagina) return;
    await rolarParaInicioPaginaRadar(_rolagem);
  }

  Future<void> _abrirFiltros() async {
    final novos = await mostrarFolhaRadar<FiltrosProdutos>(
      context,
      alturaMaxima: 0.5,
      builder: (_) => FolhaRadar(
        titulo: 'Filtrar produtos',
        descricao: 'Refine o catálogo salvo do Compre direto.',
        child: Flexible(
          child: _FiltrosProdutosSheet(
            api: widget.api,
            filtros: _controlador.filtros,
            podeLerLojasSelecionadas: widget.administrador,
            mostrarCabecalho: false,
          ),
        ),
      ),
    );
    if (mounted && novos != null) {
      _controlador.mudarFiltros(novos);
    }
  }

  Future<void> _abrirEscopoContextual() async {
    final area = await _escolherNivelDeEscopo(
      titulo: 'Escolha uma área',
      descricao: 'Depois você escolhe o tipo de produto.',
      opcoes: [
        ..._areasDeEntradaProdutos,
        const _OpcaoNavegacaoEscopo(
          'outros-novas-categorias',
          'Outros / novas categorias',
          'Itens ainda sem recorte próprio',
        ),
      ],
    );
    if (area == null || area.id == _idVoltarEscopo || !mounted) return;

    final escopo = switch (area.id) {
      'eletronicos' => await _escolherSubgrupo(
        titulo: 'Eletrônicos',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo('celulares', 'Celulares e smartphones', null, [
            _OpcaoNavegacaoEscopo('celulares-android', 'Android'),
            _OpcaoNavegacaoEscopo('celulares-smartphones', 'Smartphones'),
          ]),
          _OpcaoNavegacaoEscopo('tv-imagem', 'TV e imagem', null, [
            _OpcaoNavegacaoEscopo('tv-smart', 'Smart TVs'),
            _OpcaoNavegacaoEscopo('tv-convencional', 'TVs'),
            _OpcaoNavegacaoEscopo('suportes-tv', 'Suportes para TV'),
          ]),
          _OpcaoNavegacaoEscopo('computadores', 'Computadores', null, [
            _OpcaoNavegacaoEscopo('notebooks', 'Notebooks'),
            _OpcaoNavegacaoEscopo('tablets', 'Tablets'),
            _OpcaoNavegacaoEscopo('monitores', 'Monitores'),
            _OpcaoNavegacaoEscopo('e-readers', 'E-readers'),
          ]),
          _OpcaoNavegacaoEscopo('audio', 'Áudio', null, [
            _OpcaoNavegacaoEscopo('caixas-acusticas', 'Caixas acústicas'),
            _OpcaoNavegacaoEscopo('fones', 'Fones e headsets'),
            _OpcaoNavegacaoEscopo('som-portatil', 'Som portátil'),
            _OpcaoNavegacaoEscopo('soundbars', 'Soundbars'),
          ]),
        ],
      ),
      'casa' => await _escolherEscopoDeCasa(),
      'beleza' => await _escolherSubgrupo(
        titulo: 'Beleza e cuidados',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo('maquiagem', 'Maquiagem', null, [
            _OpcaoNavegacaoEscopo('bases', 'Bases'),
            _OpcaoNavegacaoEscopo('batons', 'Batons'),
            _OpcaoNavegacaoEscopo('blushes', 'Blushes'),
            _OpcaoNavegacaoEscopo('glosses', 'Glosses'),
            _OpcaoNavegacaoEscopo('olhos', 'Olhos'),
            _OpcaoNavegacaoEscopo('esmaltes', 'Esmaltes'),
          ]),
          _OpcaoNavegacaoEscopo('cabelos', 'Cabelos', null, [
            _OpcaoNavegacaoEscopo('shampoos', 'Shampoos'),
            _OpcaoNavegacaoEscopo('condicionadores', 'Condicionadores'),
            _OpcaoNavegacaoEscopo(
              'tratamento-cabelos',
              'Tratamento e finalização',
            ),
            _OpcaoNavegacaoEscopo('cabelos-aparelhos', 'Aparelhos para cabelo'),
          ]),
          _OpcaoNavegacaoEscopo('pele', 'Pele e banho', null, [
            _OpcaoNavegacaoEscopo('cuidados-faciais', 'Cuidados faciais'),
            _OpcaoNavegacaoEscopo('corpo-banho', 'Corpo e banho'),
            _OpcaoNavegacaoEscopo('protetores-solares', 'Protetor solar'),
          ]),
          _OpcaoNavegacaoEscopo('perfumaria', 'Perfumaria', null, [
            _OpcaoNavegacaoEscopo('perfumes', 'Perfumes'),
            _OpcaoNavegacaoEscopo('desodorantes', 'Desodorantes'),
          ]),
          _OpcaoNavegacaoEscopo(
            'cuidados-pessoais',
            'Cuidados pessoais',
            null,
            [
              _OpcaoNavegacaoEscopo('depilacao', 'Depilação'),
              _OpcaoNavegacaoEscopo('higiene-feminina', 'Higiene feminina'),
            ],
          ),
        ],
      ),
      'saude-area' => await _escolherSubgrupo(
        titulo: 'Saúde e bem-estar',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo(
            'saude-primeiros-socorros',
            'Saúde e primeiros socorros',
            'Medicamentos, cuidados e equipamentos de saúde',
          ),
        ],
      ),
      'mercado' => await _escolherSubgrupo(
        titulo: 'Mercado',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo('alimentos', 'Alimentos', null, [
            _OpcaoNavegacaoEscopo('biscoitos', 'Biscoitos'),
            _OpcaoNavegacaoEscopo('chocolates', 'Chocolates'),
            _OpcaoNavegacaoEscopo('mercearia', 'Mercearia'),
          ]),
          _OpcaoNavegacaoEscopo('bebidas', 'Bebidas', null, [
            _OpcaoNavegacaoEscopo('bebidas-agua', 'Bebidas'),
            _OpcaoNavegacaoEscopo('chas-cafes', 'Chás e cafés'),
            _OpcaoNavegacaoEscopo('sucos-aguas', 'Sucos e águas'),
          ]),
          _OpcaoNavegacaoEscopo('snacks', 'Doces e snacks', null, [
            _OpcaoNavegacaoEscopo('balas-doces', 'Balas e doces'),
            _OpcaoNavegacaoEscopo('chicletes', 'Chicletes'),
            _OpcaoNavegacaoEscopo('salgadinhos', 'Salgadinhos'),
          ]),
          _OpcaoNavegacaoEscopo('suplementos', 'Suplementos', null, [
            _OpcaoNavegacaoEscopo(
              'suplementos-vitaminas',
              'Vitaminas e suplementos',
            ),
          ]),
        ],
      ),
      'infantil' => await _escolherSubgrupo(
        titulo: 'Bebês e brinquedos',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo('bebe', 'Bebês e infantil', null, [
            _OpcaoNavegacaoEscopo('mamadeiras', 'Mamadeiras'),
            _OpcaoNavegacaoEscopo('fraldas', 'Fraldas'),
            _OpcaoNavegacaoEscopo('bercos', 'Berços'),
            _OpcaoNavegacaoEscopo('amamentacao', 'Amamentação e troca'),
          ]),
          _OpcaoNavegacaoEscopo('brinquedos', 'Brinquedos', null, [
            _OpcaoNavegacaoEscopo('bonecas', 'Bonecas'),
            _OpcaoNavegacaoEscopo('bonecos', 'Bonecos'),
            _OpcaoNavegacaoEscopo('jogos', 'Jogos'),
            _OpcaoNavegacaoEscopo('pelucias', 'Pelúcias'),
          ]),
        ],
      ),
      'pet-area' => await _escolherSubgrupo(
        titulo: 'Pet',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo('pet', 'Pet', null, [
            _OpcaoNavegacaoEscopo('racao', 'Ração'),
            _OpcaoNavegacaoEscopo('saude-pet', 'Saúde pet'),
            _OpcaoNavegacaoEscopo('higiene-pet', 'Higiene pet'),
            _OpcaoNavegacaoEscopo('acessorios-pet', 'Acessórios pet'),
          ]),
        ],
      ),
      'esporte-area' => await _escolherSubgrupo(
        titulo: 'Esporte e lazer',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo('esporte', 'Esporte e lazer', null, [
            _OpcaoNavegacaoEscopo('bicicletas', 'Bicicletas'),
            _OpcaoNavegacaoEscopo('patinetes-patins', 'Patinetes e patins'),
            _OpcaoNavegacaoEscopo('fitness', 'Fitness'),
            _OpcaoNavegacaoEscopo('piscinas', 'Piscinas'),
          ]),
        ],
      ),
      'ferramentas-area' => await _escolherSubgrupo(
        titulo: 'Ferramentas e construção',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo(
            'ferramentas',
            'Ferramentas e construção',
            null,
            [
              _OpcaoNavegacaoEscopo('furadeiras', 'Furadeiras'),
              _OpcaoNavegacaoEscopo('parafusadeiras', 'Parafusadeiras'),
              _OpcaoNavegacaoEscopo(
                'ferramentas-basicas',
                'Ferramentas manuais e elétricas',
              ),
              _OpcaoNavegacaoEscopo('eletrica', 'Elétrica'),
              _OpcaoNavegacaoEscopo('torneiras', 'Torneiras'),
            ],
          ),
        ],
      ),
      'auto-area' => await _escolherSubgrupo(
        titulo: 'Auto',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo('auto', 'Auto', null, [
            _OpcaoNavegacaoEscopo('pneus', 'Pneus e rodas'),
            _OpcaoNavegacaoEscopo('limpeza-auto', 'Limpeza automotiva'),
          ]),
        ],
      ),
      'moda-area' => await _escolherSubgrupo(
        titulo: 'Moda',
        descricao: 'Escolha o tipo de produto.',
        opcoes: const [
          _OpcaoNavegacaoEscopo('moda', 'Moda', null, [
            _OpcaoNavegacaoEscopo('roupas', 'Roupas'),
            _OpcaoNavegacaoEscopo('calcados', 'Calçados'),
            _OpcaoNavegacaoEscopo('acessorios-moda', 'Acessórios'),
          ]),
        ],
      ),
      _ => area,
    };
    if (escopo == null || escopo.id == _idVoltarEscopo || !mounted) return;
    final ativos = _controlador.filtros.escoposAtivos;
    const outro = 'outros-novas-categorias';
    if ((escopo.id == outro && ativos.isNotEmpty) || ativos.contains(outro)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outros / novas categorias deve ser usado sozinho.'),
        ),
      );
      return;
    }
    _controlador.mudarFiltros(
      _controlador.filtros.copiarCom(escopos: [...ativos, escopo.id]),
    );
  }

  Future<_OpcaoNavegacaoEscopo?> _escolherEscopoDeCasa() async {
    return _escolherSubgrupo(
      titulo: 'Casa e cozinha',
      descricao: 'Escolha uma seção.',
      opcoes: const [
        _OpcaoNavegacaoEscopo(
          'eletrodomesticos',
          'Eletrodomésticos',
          'Escolha o tipo de eletrodoméstico.',
          [
            _OpcaoNavegacaoEscopo(
              'refrigeracao-lavanderia',
              'Refrigeração e lavanderia',
              'Escolha uma categoria de produto.',
              [
                _OpcaoNavegacaoEscopo(
                  'geladeiras',
                  'Geladeiras',
                  'Geladeiras, refrigeradores e frigobares',
                ),
                _OpcaoNavegacaoEscopo(
                  'freezers',
                  'Freezers',
                  'Freezers verticais e horizontais',
                ),
                _OpcaoNavegacaoEscopo(
                  'lavadoras',
                  'Lavadoras e secadoras',
                  'Máquinas de lavar, lava e seca e secadoras',
                ),
              ],
            ),
            _OpcaoNavegacaoEscopo(
              'fogoes-fornos',
              'Fogões e fornos',
              'Fogões, cooktops e fornos',
            ),
            _OpcaoNavegacaoEscopo('microondas', 'Micro-ondas'),
            _OpcaoNavegacaoEscopo(
              'limpeza-climatizacao',
              'Limpeza e climatização',
              'Aspiradores, ferros, ventiladores e ar-condicionado',
              [
                _OpcaoNavegacaoEscopo('limpeza-eletro', 'Limpeza e passar'),
                _OpcaoNavegacaoEscopo('climatizacao', 'Climatização'),
              ],
            ),
          ],
        ),
        _OpcaoNavegacaoEscopo(
          'cozinhas-jantar',
          'Cozinhas e jantar',
          'Cozinhas, balcões e mesas',
          [
            _OpcaoNavegacaoEscopo('cozinhas-modulares', 'Cozinhas'),
            _OpcaoNavegacaoEscopo('mesa-jantar', 'Mesas e jantar'),
          ],
        ),
        _OpcaoNavegacaoEscopo('eletroportateis', 'Eletroportáteis', null, [
          _OpcaoNavegacaoEscopo('fritadeiras', 'Fritadeiras'),
          _OpcaoNavegacaoEscopo('liquidificadores', 'Liquidificadores'),
          _OpcaoNavegacaoEscopo('cafeteiras', 'Cafeteiras'),
          _OpcaoNavegacaoEscopo('chaleiras', 'Chaleiras'),
          _OpcaoNavegacaoEscopo('mixers', 'Mixers'),
          _OpcaoNavegacaoEscopo('panelas-eletricas', 'Panelas elétricas'),
          _OpcaoNavegacaoEscopo('processadores', 'Processadores'),
        ]),
        _OpcaoNavegacaoEscopo('moveis', 'Móveis', null, [
          _OpcaoNavegacaoEscopo('sofas', 'Sofás'),
          _OpcaoNavegacaoEscopo('racks-paineis', 'Racks e painéis'),
          _OpcaoNavegacaoEscopo('guarda-roupas', 'Guarda-roupas'),
          _OpcaoNavegacaoEscopo('comodas', 'Cômodas'),
          _OpcaoNavegacaoEscopo('escritorio', 'Escritório'),
          _OpcaoNavegacaoEscopo('poltronas', 'Poltronas'),
          _OpcaoNavegacaoEscopo('quarto-camas', 'Quarto e camas'),
        ]),
        _OpcaoNavegacaoEscopo('utilidades', 'Mesa e utilidades', null, [
          _OpcaoNavegacaoEscopo('panelas', 'Panelas'),
          _OpcaoNavegacaoEscopo('copos', 'Copos'),
          _OpcaoNavegacaoEscopo('potes', 'Potes e tigelas'),
          _OpcaoNavegacaoEscopo('formas', 'Formas e assadeiras'),
          _OpcaoNavegacaoEscopo('organizacao', 'Organização'),
        ]),
        _OpcaoNavegacaoEscopo(
          'festas-decoracao',
          'Festas e decoração',
          'Artigos para festas, fantasias e enfeites',
        ),
      ],
    );
  }

  Future<_OpcaoNavegacaoEscopo?> _escolherSubgrupo({
    required String titulo,
    required String descricao,
    required List<_OpcaoNavegacaoEscopo> opcoes,
    bool mostrarVoltar = true,
  }) async {
    var opcao = await _escolherNivelDeEscopo(
      titulo: titulo,
      descricao: descricao,
      opcoes: opcoes,
      mostrarVoltar: mostrarVoltar,
    );
    while (opcao != null && mounted) {
      if (opcao.id == _idVoltarEscopo) return opcao;
      if (opcao.filhos == null) return opcao;
      final filho = await _escolherSubgrupo(
        titulo: opcao.rotulo,
        descricao: opcao.descricao ?? 'Escolha o tipo de produto.',
        opcoes: opcao.filhos!,
      );
      if (filho?.id == _idVoltarEscopo) {
        opcao = await _escolherNivelDeEscopo(
          titulo: titulo,
          descricao: descricao,
          opcoes: opcoes,
          mostrarVoltar: mostrarVoltar,
        );
        continue;
      }
      return filho;
    }
    return null;
  }

  Future<_OpcaoNavegacaoEscopo?> _escolherNivelDeEscopo({
    required String titulo,
    required String descricao,
    required List<_OpcaoNavegacaoEscopo> opcoes,
    bool mostrarVoltar = true,
  }) => mostrarFolhaRadar<_OpcaoNavegacaoEscopo>(
    context,
    alturaMaxima: 0.9,
    builder: (contexto) => FolhaRadar(
      titulo: titulo,
      descricao: descricao,
      mostrarVoltar: mostrarVoltar,
      aoVoltar: mostrarVoltar
          ? () => Navigator.pop(
              contexto,
              const _OpcaoNavegacaoEscopo(_idVoltarEscopo, ''),
            )
          : null,
      child: Flexible(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(3, 0, 3, 28),
          children: [
            for (final opcao in opcoes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(contexto, opcao),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(opcao.rotulo),
                        if (opcao.descricao != null)
                          Text(
                            opcao.descricao!,
                            style: Theme.of(contexto).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  String? _rotuloDoEscopo(String? escopo) => switch (escopo) {
    'celulares' => 'Eletrônicos · Celulares e smartphones',
    'tv-imagem' => 'Eletrônicos · TV e imagem',
    'computadores' => 'Eletrônicos · Computadores',
    'audio' => 'Eletrônicos · Áudio',
    'geladeiras' => 'Casa · Eletrodomésticos · Refrigeração · Geladeiras',
    'freezers' => 'Casa · Eletrodomésticos · Refrigeração · Freezers',
    'lavadoras' =>
      'Casa · Eletrodomésticos · Lavanderia · Lavadoras e secadoras',
    'fogoes-fornos' => 'Casa · Eletrodomésticos · Fogões e fornos',
    'microondas' => 'Casa · Eletrodomésticos · Micro-ondas',
    'eletroportateis' => 'Casa · Eletroportáteis',
    'moveis' => 'Casa · Móveis',
    'utilidades' => 'Casa · Mesa e utilidades',
    'maquiagem' => 'Beleza · Maquiagem',
    'cabelos' => 'Beleza · Cabelos',
    'pele' => 'Beleza · Pele e banho',
    'perfumaria' => 'Beleza · Perfumaria',
    'cabelos-aparelhos' => 'Beleza · Cabelos · Aparelhos para cabelo',
    'depilacao' => 'Beleza · Cuidados pessoais · Depilação',
    'higiene-feminina' => 'Beleza · Cuidados pessoais · Higiene feminina',
    'saude-primeiros-socorros' => 'Saúde · Primeiros socorros e cuidados',
    'cozinhas-modulares' => 'Casa · Cozinhas e jantar · Cozinhas',
    'mesa-jantar' => 'Casa · Cozinhas e jantar · Mesas e jantar',
    'quarto-camas' => 'Casa · Móveis · Quarto e camas',
    'limpeza-eletro' => 'Casa · Eletrodomésticos · Limpeza e passar',
    'climatizacao' => 'Casa · Eletrodomésticos · Climatização',
    'festas-decoracao' => 'Casa · Festas e decoração',
    'alimentos' => 'Mercado · Alimentos',
    'bebidas' => 'Mercado · Bebidas',
    'snacks' => 'Mercado · Doces e snacks',
    'suplementos' => 'Mercado · Suplementos',
    'bebe' => 'Bebês e brinquedos · Bebês e infantil',
    'brinquedos' => 'Bebês e brinquedos · Brinquedos',
    'pet' => 'Pet · Alimentação, higiene e acessórios',
    'esporte' => 'Esporte e lazer · Fitness, bikes e lazer',
    'ferramentas' => 'Ferramentas e construção · Ferramentas e casa',
    'auto' => 'Auto · Pneus e acessórios',
    'moda' => 'Moda · Roupas, calçados e acessórios',
    'outros-novas-categorias' => 'Outros / novas categorias',
    _ => escopo,
  };
}

class _OpcaoNavegacaoEscopo {
  const _OpcaoNavegacaoEscopo(
    this.id,
    this.rotulo, [
    this.descricao,
    this.filhos,
  ]);

  final String id;
  final String rotulo;
  final String? descricao;
  final List<_OpcaoNavegacaoEscopo>? filhos;
}

const _idVoltarEscopo = '__voltar__';

const _areasDeEntradaProdutos = <_OpcaoNavegacaoEscopo>[
  _OpcaoNavegacaoEscopo(
    'eletronicos',
    'Eletrônicos',
    'Celulares, TV, computadores e áudio',
  ),
  _OpcaoNavegacaoEscopo(
    'casa',
    'Casa e cozinha',
    'Eletrodomésticos, móveis e utilidades',
  ),
  _OpcaoNavegacaoEscopo(
    'beleza',
    'Beleza e cuidados',
    'Maquiagem, cabelos e perfumaria',
  ),
  _OpcaoNavegacaoEscopo(
    'mercado',
    'Mercado',
    'Alimentos, bebidas e suplementos',
  ),
  _OpcaoNavegacaoEscopo(
    'saude-area',
    'Saúde e bem-estar',
    'Cuidados de saúde, farmácia e primeiros socorros',
  ),
  _OpcaoNavegacaoEscopo(
    'infantil',
    'Bebês e brinquedos',
    'Itens infantis e diversão',
  ),
  _OpcaoNavegacaoEscopo('pet-area', 'Pet', 'Alimentação, higiene e acessórios'),
  _OpcaoNavegacaoEscopo(
    'esporte-area',
    'Esporte e lazer',
    'Fitness, bikes e lazer',
  ),
  _OpcaoNavegacaoEscopo(
    'ferramentas-area',
    'Ferramentas e construção',
    'Construção e casa',
  ),
  _OpcaoNavegacaoEscopo('auto-area', 'Auto', 'Pneus e acessórios'),
  _OpcaoNavegacaoEscopo('moda-area', 'Moda', 'Roupas, calçados e acessórios'),
];

class _EntradaEscopoProdutos extends StatelessWidget {
  const _EntradaEscopoProdutos({
    required this.escopos,
    required this.rotulos,
    required this.aoAbrir,
    required this.aoRemover,
    required this.aoLimpar,
  });

  final List<String> escopos;
  final List<String> rotulos;
  final VoidCallback aoAbrir;
  final ValueChanged<String> aoRemover;
  final VoidCallback aoLimpar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: tema.cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: cores.borda),
        boxShadow: <BoxShadow>[SombraRadar.para(tema.brightness)],
      ),
      child: LayoutBuilder(
        builder: (context, limites) {
          final icone = Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tema.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.category_outlined, color: cores.marca, size: 21),
          );
          final temEscopos = escopos.isNotEmpty;
          final texto = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  !temEscopos
                      ? 'Comece por uma área'
                      : escopos.length == 1
                      ? 'Busca contextual · ${rotulos.first}'
                      : 'Busca contextual · ${escopos.length} áreas',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  !temEscopos
                      ? 'Refine a busca por tipo de produto.'
                      : 'Recortes aplicados ao catálogo salvo.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: cores.textoSuave,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          );
          final explorar = FilledButton.tonalIcon(
            onPressed: aoAbrir,
            icon: Icon(Icons.arrow_forward, size: 17),
            label: Text(temEscopos ? 'Adicionar área' : 'Explorar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          if (!temEscopos) {
            final vertical =
                limites.maxWidth < 360 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.2;
            if (vertical) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [icone, const SizedBox(width: 10), texto]),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: explorar),
                ],
              );
            }
            return Row(
              children: [icone, const SizedBox(width: 10), texto, explorar],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [icone, const SizedBox(width: 10), texto]),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (var indice = 0; indice < escopos.length; indice++)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: limites.maxWidth - 30,
                      ),
                      child: InputChip(
                        key: Key('escopo-produtos-${escopos[indice]}'),
                        label: Text(
                          rotulos[indice],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () => aoRemover(escopos[indice]),
                        deleteIcon: const Icon(Icons.close, size: 17),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _AcoesEscopoProdutos(
                explorar: explorar,
                aoLimpar: aoLimpar,
                empilhar:
                    limites.maxWidth < 360 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.2,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AcoesEscopoProdutos extends StatelessWidget {
  const _AcoesEscopoProdutos({
    required this.explorar,
    required this.aoLimpar,
    required this.empilhar,
  });

  final Widget explorar;
  final VoidCallback aoLimpar;
  final bool empilhar;

  @override
  Widget build(BuildContext context) {
    final limpar = FilledButton.tonalIcon(
      key: const Key('limpar-escopos-produtos'),
      onPressed: aoLimpar,
      icon: const Icon(Icons.close, size: 17),
      label: const Text('Limpar'),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (empilhar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [explorar, const SizedBox(height: 8), limpar],
      );
    }
    return Row(
      children: [
        Expanded(child: explorar),
        const SizedBox(width: 8),
        Expanded(child: limpar),
      ],
    );
  }
}

class _AvisoFalhaBuscaProdutos extends StatelessWidget {
  const _AvisoFalhaBuscaProdutos({required this.tentarNovamente});

  final VoidCallback tentarNovamente;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    return Semantics(
      liveRegion: true,
      label:
          'Não foi possível atualizar esta busca. '
          'A lista anterior foi preservada e pode não pertencer ao recorte atual.',
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tema.cardColor,
          border: Border.all(color: cores.perigo.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(15),
          boxShadow: <BoxShadow>[SombraRadar.para(tema.brightness)],
        ),
        child: LayoutBuilder(
          builder: (context, limites) {
            final mensagem = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 18, color: cores.perigo),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Não foi possível atualizar esta busca',
                        style: tema.textTheme.labelMedium?.copyWith(
                          color: cores.perigo,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'A lista anterior foi preservada sem perder o termo '
                        'ou os filtros; ela pode não pertencer ao recorte atual.',
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: cores.textoSuave,
                          fontSize: 9,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
            final botao = OutlinedButton(
              onPressed: tentarNovamente,
              child: const Text('Tentar novamente'),
            );
            final empilhar =
                limites.maxWidth < 330 ||
                MediaQuery.textScalerOf(context).scale(10) > 12;
            if (empilhar) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  mensagem,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: botao),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: mensagem),
                const SizedBox(width: 10),
                botao,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GrupoProdutosCompacto extends StatelessWidget {
  const _GrupoProdutosCompacto({
    super.key,
    required this.loja,
    required this.produtos,
    required this.construirCartao,
  });

  final String loja;
  final List<ProdutoDireto> produtos;
  final Widget Function(ProdutoDireto produto) construirCartao;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final iniciais = loja
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => parte[0].toUpperCase())
        .join();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Tokens.superficieForteEscura
                    : Tokens.plumSoft,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Text(
                iniciais.isEmpty ? '?' : iniciais,
                style: TextStyle(
                  color: cores.marca,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loja,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Atualizado em ${dataHoraProduto(produtos.first.atualizadaEm)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cores.textoSuave,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cores.superficieAlternativa,
                borderRadius: BorderRadius.circular(RaioRadar.pilula),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(
                  '${produtos.length} ${produtos.length == 1 ? 'oferta' : 'ofertas'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cores.textoSuave,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var indice = 0; indice < produtos.length; indice++) ...[
          construirCartao(produtos[indice]),
          if (indice != produtos.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _FiltrosProdutosSheet extends StatefulWidget {
  const _FiltrosProdutosSheet({
    required this.api,
    required this.filtros,
    required this.podeLerLojasSelecionadas,
    this.mostrarCabecalho = true,
  });

  final Api api;
  final FiltrosProdutos filtros;
  final bool podeLerLojasSelecionadas;
  final bool mostrarCabecalho;

  @override
  State<_FiltrosProdutosSheet> createState() => _EstadoFiltrosProdutosSheet();
}

class _EstadoFiltrosProdutosSheet extends State<_FiltrosProdutosSheet> {
  late final _precoMin = TextEditingController(text: widget.filtros.precoMin);
  late final _precoMax = TextEditingController(text: widget.filtros.precoMax);
  var _lojas = const <LojaDireto>[];
  late String _loja = widget.filtros.loja;
  var _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
  }

  @override
  void dispose() {
    _precoMin.dispose();
    _precoMax.dispose();
    super.dispose();
  }

  Future<void> _carregarOpcoes() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lojas = widget.podeLerLojasSelecionadas
          ? await _carregarLojasSelecionadas()
          : const <LojaDireto>[];
      if (!mounted) return;
      setState(() => _lojas = lojas);
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar as opções de filtro.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<List<LojaDireto>> _carregarLojasSelecionadas() async {
    final lojas = <LojaDireto>[];
    var pagina = 1;
    while (true) {
      final resposta = await widget.api.lojasDiretas(
        filtro: 'acompanhadas',
        pagina: pagina,
      );
      lojas.addAll(resposta.itens.where((loja) => loja.selecionada));
      if (!resposta.temProxima) return lojas;
      pagina++;
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.mostrarCabecalho) ...[
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Escolha a loja. Só a faixa de preço é editável.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CoresRadar.de(context).textoSuave,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erro != null)
              _erroOpcoes()
            else ...[
              if (widget.podeLerLojasSelecionadas) ...[
                _tituloSecao('Lojas', '${_lojas.length} para coleta'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipLoja(
                      key: const Key('filtro-loja-todas'),
                      nome: 'Todas as lojas',
                      selecionada: _loja.trim().isEmpty,
                      aoSelecionar: () => setState(() => _loja = ''),
                    ),
                    for (final loja in _lojas)
                      _chipLoja(
                        key: Key('filtro-loja-${loja.slug}'),
                        nome: loja.nome,
                        selecionada: _loja == loja.slug,
                        aoSelecionar: () => setState(() => _loja = loja.slug),
                      ),
                  ],
                ),
                if (_lojas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('Nenhuma loja está selecionada para coleta.'),
                  ),
                const SizedBox(height: 20),
              ],
              _tituloSecao('Faixa de preço', 'opcional'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('filtro-preco-minimo'),
                      controller: _precoMin,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Mínimo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      key: const Key('filtro-preco-maximo'),
                      controller: _precoMax,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Máximo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _aplicar,
                child: const Text('Aplicar filtros'),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _tituloSecao(String titulo, String descricao) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(titulo, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 2),
      Text(
        descricao,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: CoresRadar.de(context).textoSuave,
        ),
      ),
    ],
  );

  Widget _chipLoja({
    required Key key,
    required String nome,
    required bool selecionada,
    required VoidCallback aoSelecionar,
  }) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final claro = tema.brightness == Brightness.light;
    return ChoiceChip(
      key: key,
      label: Text(nome),
      selected: selecionada,
      onSelected: (_) => aoSelecionar(),
      selectedColor: claro ? Colors.white : Tokens.superficieEscura,
      backgroundColor: claro
          ? Tokens.superficieAlternativa
          : Tokens.superficieAlternativaEscura,
      checkmarkColor: cores.acao,
      side: BorderSide(color: selecionada ? cores.acao : cores.borda),
      labelStyle: TextStyle(
        color: selecionada ? cores.acao : cores.textoSuave,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _erroOpcoes() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_erro!, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _carregarOpcoes,
        icon: const Icon(Icons.refresh),
        label: const Text('Tentar novamente'),
      ),
    ],
  );

  void _aplicar() => Navigator.of(context).pop(
    FiltrosProdutos(
      categoria: widget.filtros.categoria,
      escopos: widget.filtros.escopos,
      semCategoria: widget.filtros.semCategoria,
      loja: _loja,
      precoMin: _precoMin.text,
      precoMax: _precoMax.text,
    ),
  );
}

class _BuscaProdutosCompacta extends StatelessWidget {
  const _BuscaProdutosCompacta({
    required this.controlador,
    required this.aoMudar,
  });

  final TextEditingController controlador;
  final ValueChanged<String> aoMudar;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Tokens.acaoFundoEscuro
          : Tokens.acaoFundo,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: CoresRadar.de(context).borda),
    ),
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O que você procura?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Digitar aqui pesquisa o último catálogo salvo; não consulta o Inter ao vivo.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),
          CampoBuscaRadar(
            controlador: controlador,
            dica: 'Ex.: Motorola Edge 60 Pro',
            aoMudar: aoMudar,
            chaveCampo: const Key('busca-produtos'),
            aoAcionar: () => aoMudar(controlador.text),
          ),
        ],
      ),
    ),
  );
}

class _ChipProduto extends StatelessWidget {
  const _ChipProduto({
    required this.texto,
    required this.aoTocar,
    this.ativo = false,
    this.icone,
  });

  final String texto;
  final VoidCallback aoTocar;
  final bool ativo;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return TextButton.icon(
      onPressed: aoTocar,
      icon: icone == null ? const SizedBox.shrink() : Icon(icone, size: 16),
      label: Text(texto),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 37),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        backgroundColor: ativo
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Tokens.acaoFundoEscuro
                  : Tokens.acaoFundo)
            : Theme.of(context).colorScheme.surface,
        foregroundColor: ativo ? cores.acao : cores.textoSuave,
        side: BorderSide(color: ativo ? cores.acao : cores.borda),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
