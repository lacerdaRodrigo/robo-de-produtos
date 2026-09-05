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
import 'seletor_categorias_inter.dart';

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
  String? _rotuloCategoriaAtiva;
  bool _carregandoCategorias = false;

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
                  child: widget.experienciaCompacta
                      ? CampoBuscaRadar(
                          controlador: _campoBusca,
                          dica: 'Buscar produtos',
                          aoMudar: _controlador.mudarTermo,
                        )
                      : TextField(
                          controller: _campoBusca,
                          onChanged: _controlador.mudarTermo,
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            labelText: 'Buscar produtos',
                            hintText: 'Ex.: celular Motorola Edge 60 Pro',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
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
                            setState(() => _rotuloCategoriaAtiva = null);
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
              escopo: _controlador.filtros.escopoOpcional,
              aoAbrir: _abrirEscopoContextual,
              aoLimpar: () => _controlador.mudarFiltros(
                _controlador.filtros.copiarCom(escopo: ''),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _filtrosCompactos()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
          sliver: SliverToBoxAdapter(
            child: _ControleCategoriaTemporaria(
              rotulo: _rotuloCategoriaAtiva,
              carregando: _carregandoCategorias,
              aoAbrir: _abrirCategoriaNestaTela,
            ),
          ),
        ),
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
    if (_controlador.carregandoMais) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_controlador.erroMais != null) {
      return Center(
        child: FilledButton.tonal(
          onPressed: _controlador.carregarMais,
          child: const Text('Tentar carregar mais'),
        ),
      );
    }
    if (_controlador.temProxima) {
      return Center(
        child: FilledButton(
          onPressed: _controlador.carregarMais,
          child: const Text('Carregar mais'),
        ),
      );
    }
    return const Center(child: Text('Todos os resultados foram carregados.'));
  }

  Future<void> _abrirFiltros() async {
    final novos = await showModalBottomSheet<FiltrosProdutos>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      builder: (_) => _FiltrosProdutosSheet(
        api: widget.api,
        filtros: _controlador.filtros,
        podeLerLojasSelecionadas: widget.administrador,
      ),
    );
    if (mounted && novos != null) {
      setState(() => _rotuloCategoriaAtiva = novos.categoriaOpcional);
      _controlador.mudarFiltros(novos);
    }
  }

  Future<void> _abrirCategoriaNestaTela() async {
    if (_carregandoCategorias) return;
    setState(() => _carregandoCategorias = true);
    CatalogoCategoriasInterUsuario catalogo;
    try {
      catalogo = await widget.api.categoriasInter();
    } catch (_) {
      if (!mounted) return;
      mostrarMensagemRadar(
        context,
        'Não foi possível carregar as categorias do catálogo.',
        sucesso: false,
      );
      return;
    } finally {
      if (mounted) setState(() => _carregandoCategorias = false);
    }
    if (!mounted) return;
    final selecao = await mostrarSelecaoCategoriaTemporaria(
      context,
      categorias: catalogo.itens,
      categoriaAtual: _controlador.filtros.categoriaOpcional,
      semCategoriaAtual: _controlador.filtros.semCategoria,
    );
    if (selecao == null || !mounted) return;

    final rotulo = selecao.semCategoria ? 'Sem categoria' : selecao.categoria;
    setState(() => _rotuloCategoriaAtiva = rotulo);
    _controlador.mudarFiltros(
      _controlador.filtros.copiarCom(
        categoria: selecao.categoria ?? '',
        semCategoria: selecao.semCategoria,
      ),
    );
    mostrarMensagemRadar(
      context,
      'Filtro temporário aplicado ao catálogo salvo.',
    );
  }

  Future<void> _abrirEscopoContextual() async {
    const opcoes = <(String, String)>[
      ('celulares', 'Celulares e smartphones'),
      ('tv-imagem', 'TV e imagem'),
      ('computadores', 'Computadores'),
      ('audio', 'Áudio'),
      ('linha-branca', 'Casa · Linha branca'),
      ('eletroportateis', 'Casa · Eletroportáteis'),
      ('moveis', 'Casa · Móveis'),
      ('utilidades', 'Casa · Mesa e utilidades'),
      ('maquiagem', 'Beleza · Maquiagem'),
      ('cabelos', 'Beleza · Cabelos'),
      ('pele', 'Beleza · Pele e banho'),
      ('perfumaria', 'Beleza · Perfumaria'),
      ('alimentos', 'Mercado · Alimentos'),
      ('bebidas', 'Mercado · Bebidas'),
      ('snacks', 'Mercado · Doces e snacks'),
      ('suplementos', 'Mercado · Suplementos'),
      ('bebe', 'Bebês e infantil'),
      ('brinquedos', 'Brinquedos'),
      ('pet', 'Pet'),
      ('esporte', 'Esporte e lazer'),
      ('ferramentas', 'Ferramentas e construção'),
      ('auto', 'Auto'),
      ('moda', 'Moda'),
      ('outros-novas-categorias', 'Outros / novas categorias'),
    ];
    final escopo = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            'Escolha uma área',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text('Escolha um assunto e descreva o que procura.'),
          const SizedBox(height: 14),
          for (final opcao in opcoes)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, opcao.$1),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(opcao.$2),
                ),
              ),
            ),
        ],
      ),
    );
    if (escopo == null || !mounted) return;
    _controlador.mudarFiltros(_controlador.filtros.copiarCom(escopo: escopo));
  }
}

class _EntradaEscopoProdutos extends StatelessWidget {
  const _EntradaEscopoProdutos({
    required this.escopo,
    required this.aoAbrir,
    required this.aoLimpar,
  });

  final String? escopo;
  final VoidCallback aoAbrir;
  final VoidCallback aoLimpar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CoresRadar.de(context).superficieAlternativa,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CoresRadar.de(context).borda),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            escopo == null
                ? 'Comece por uma área'
                : 'Busca contextual · $escopo',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: escopo == null ? aoAbrir : aoLimpar,
          child: Text(escopo == null ? 'Explorar' : 'Limpar'),
        ),
      ],
    ),
  );
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
          'A lista anterior foi preservada.',
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
                        'ou os filtros.',
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

class _ControleCategoriaTemporaria extends StatelessWidget {
  const _ControleCategoriaTemporaria({
    required this.rotulo,
    required this.carregando,
    required this.aoAbrir,
  });

  final String? rotulo;
  final bool carregando;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final filtroAtivo = rotulo != null;
    final escuro = tema.brightness == Brightness.dark;
    final corFundo = (escuro ? Tokens.acaoFundoEscuro : Tokens.actionSoft);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cores.borda),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categoria nesta tela',
                  style: tema.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Filtro temporário · não altera categorias acompanhadas',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: cores.textoSuave,
                    fontSize: 8,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            key: const Key('categoria-nesta-tela'),
            onPressed: carregando ? null : aoAbrir,
            style: OutlinedButton.styleFrom(
              foregroundColor: filtroAtivo ? cores.acao : cores.textoSuave,
              backgroundColor: filtroAtivo ? corFundo : null,
              side: BorderSide(
                color: filtroAtivo
                    ? cores.acao.withValues(alpha: 0.5)
                    : cores.borda,
              ),
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 11),
            ),
            icon: carregando
                ? const SizedBox.square(
                    dimension: 13,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right, size: 17),
            label: Text(
              filtroAtivo ? rotulo! : 'Todas',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
            ),
            iconAlignment: IconAlignment.end,
          ),
        ],
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
  });

  final Api api;
  final FiltrosProdutos filtros;
  final bool podeLerLojasSelecionadas;

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
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Escolha a loja. Só a faixa de preço é editável.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CoresRadar.de(context).textoSuave,
              ),
            ),
            const SizedBox(height: 20),
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
