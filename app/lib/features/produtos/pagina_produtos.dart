import 'dart:async';

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
import 'pagina_detalhe_produto.dart';
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
    this.sliversAntes = const [],
    this.totalLojasSelecionadas,
    this.navegadorParaDetalhes,
  });

  final Api api;
  final ControladorBuscaProdutos? controlador;
  final bool administrador;
  final bool incorporada;
  final bool mostrarTituloInterno;
  final bool experienciaCompacta;
  final List<Widget> sliversAntes;
  final int? totalLojasSelecionadas;
  final GlobalKey<NavigatorState>? navegadorParaDetalhes;

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
        buscarComOpcoes:
            ({
              required termo,
              required pagina,
              required ordenar,
              required apenasAcompanhados,
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
              ordenar: ordenar,
              apenasAcompanhados: apenasAcompanhados,
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
  final _navegadorInterno = GlobalKey<NavigatorState>();
  final _acompanhamentos = <String, bool>{};
  final _mudancasAcompanhamento = _AcompanhamentoNotifier();

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
    _mudancasAcompanhamento.dispose();
    if (!_controladorExterno) _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corpo = AnimatedBuilder(
      animation: Listenable.merge([_controlador, _mudancasAcompanhamento]),
      builder: (context, _) => _conteudo(context),
    );
    final navegadorCatalogo = Navigator(
      key: _navegadorInterno,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'catalogo-produtos'),
        builder: (_) => corpo,
      ),
    );
    final catalogo = widget.navegadorParaDetalhes == null
        ? NavigatorPopHandler<void>(
            onPopWithResult: (_) => _navegadorInterno.currentState?.pop(),
            child: navegadorCatalogo,
          )
        : navegadorCatalogo;
    if (widget.incorporada || widget.experienciaCompacta) return catalogo;
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos no Inter')),
      body: catalogo,
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
    return CustomScrollView(
      key: const Key('produtos-compacto'),
      controller: _rolagem,
      slivers: [
        ...widget.sliversAntes,
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            context.tokens.spacing.five,
            context.tokens.spacing.six,
            context.tokens.spacing.five,
            context.tokens.spacing.two,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Produtos por loja',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            context.tokens.spacing.five,
            0,
            context.tokens.spacing.five,
            context.tokens.spacing.two,
          ),
          sliver: SliverToBoxAdapter(
            child: CampoBuscaRadar(
              controlador: _campoBusca,
              aoMudar: _controlador.mudarTermo,
              aoAcionar: () => _controlador.mudarTermo(_campoBusca.text),
              dica: 'Produto, marca ou modelo',
              chaveCampo: const Key('busca-produtos'),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.only(
            start: context.tokens.spacing.five,
            end: context.tokens.spacing.five,
          ),
          sliver: SliverToBoxAdapter(
            child: AbasRadar(
              rotulos: const ['Todos', 'No radar'],
              plana: true,
              selecionada: _controlador.apenasAcompanhados ? 1 : 0,
              aoSelecionar: (indice) =>
                  _controlador.mudarAcompanhados(indice == 1),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            context.tokens.spacing.five,
            context.tokens.spacing.two,
            context.tokens.spacing.five,
            context.tokens.spacing.two,
          ),
          sliver: SliverToBoxAdapter(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    '${_controlador.totalItens} produtos',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CoresRadar.de(context).textoSuave,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  key: const Key('filtros-produtos'),
                  onPressed: _abrirFiltros,
                  icon: const Icon(Icons.tune, size: 17),
                  label: const Text('Filtros'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, context.tokens.sizes.touchTarget),
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: context.tokens.spacing.three,
                    ),
                    foregroundColor: CoresRadar.de(context).texto,
                    side: BorderSide(color: CoresRadar.de(context).borda),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.tokens.radii.md,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_controlador.atualizadoEm != null && _controlador.erro == null)
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              start: context.tokens.spacing.five,
              end: context.tokens.spacing.five,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Atualizado ${dataHoraProduto(_controlador.atualizadoEm)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CoresRadar.de(context).textoSuave,
                ),
              ),
            ),
          ),
        ..._corpoCompacto(context),
        SliverToBoxAdapter(
          child: SizedBox(height: context.tokens.spacing.seven),
        ),
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

  List<Widget> _corpoCompacto(BuildContext context) {
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
    final widgets = <Widget>[];
    for (final grupo in grupos.entries) {
      final primeiro = grupo.value.first;
      widgets.add(
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: context.tokens.spacing.two,
            bottom: context.tokens.spacing.two,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  grupo.key,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Flexible(
                child: Text(
                  dataHoraProduto(primeiro.atualizadaEm),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CoresRadar.de(context).textoSuave,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      for (final produto in grupo.value) {
        widgets.add(_cartao(produto, compacto: true, mostrarLoja: false));
      }
    }
    return [
      if (_controlador.erro != null)
        SliverPadding(
          padding: EdgeInsetsDirectional.only(
            start: context.tokens.spacing.five,
            end: context.tokens.spacing.five,
            bottom: context.tokens.spacing.two,
          ),
          sliver: SliverToBoxAdapter(
            child: _AvisoFalhaBuscaProdutos(
              quantidadePreservada: _controlador.itens.length,
              tentarNovamente: _controlador.tentarNovamente,
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.tokens.spacing.five,
        ),
        sliver: SliverList.separated(
          itemCount: widgets.length,
          separatorBuilder: (_, _) =>
              SizedBox(height: context.tokens.spacing.two),
          itemBuilder: (_, indice) => widgets[indice],
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
    bool destaque = false,
  }) {
    final link = linkSeguroShoppingInter(produto.caminho);
    final chave = _chaveAcompanhamento(produto);
    final produtoAtual = produto.copiarCom(
      acompanhado: _acompanhamentos[chave] ?? produto.acompanhado,
    );
    return CartaoProduto(
      produto: produtoAtual,
      compacto: compacto,
      mostrarLoja: mostrarLoja,
      destaque: destaque,
      aoAbrirDetalhes: () => _abrirDetalhes(produtoAtual),
      aoAbrirHistorico: () => _abrirHistorico(produtoAtual),
      aoAbrirNoShopping: link == null ? null : () => _abrirNoShopping(link),
      aoAcompanhar: () {
        unawaited(_alternarAcompanhamento(produto));
      },
    );
  }

  String _chaveAcompanhamento(ProdutoDireto produto) =>
      '${produto.lojaSlug}/${produto.idExterno}';

  Future<bool> _alternarAcompanhamento(ProdutoDireto produto) async {
    final chave = _chaveAcompanhamento(produto);
    final atual = _acompanhamentos[chave] ?? produto.acompanhado;
    final novo = !atual;
    _acompanhamentos[chave] = novo;
    _mudancasAcompanhamento.mudou();
    try {
      await widget.api.alterarAcompanhamentoProduto(
        loja: produto.lojaSlug,
        idExterno: produto.idExterno,
        ativo: novo,
      );
      if (mounted) {
        mostrarMensagemRadar(
          context,
          novo
              ? 'Produto adicionado à Central de Alertas.'
              : 'Produto removido da Central de Alertas.',
        );
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      _acompanhamentos[chave] = atual;
      _mudancasAcompanhamento.mudou();
      mostrarMensagemRadar(
        context,
        'Não foi possível salvar o acompanhamento.',
        sucesso: false,
      );
      return false;
    }
  }

  Future<void> _abrirDetalhes(ProdutoDireto produto) async {
    final navigator =
        widget.navegadorParaDetalhes?.currentState ??
        _navegadorInterno.currentState;
    if (navigator == null) return;
    final link = linkSeguroShoppingInter(produto.caminho);
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaginaDetalheProduto(
          produto: produto,
          aoAbrirHistorico: () => _abrirHistorico(produto),
          aoAcompanhar: () => _alternarAcompanhamento(produto),
          aoAbrirNoShopping: link == null ? null : () => _abrirNoShopping(link),
        ),
      ),
    );
  }

  Future<void> _abrirHistorico(ProdutoDireto produto) async {
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.9,
      builder: (contexto) => FolhaRadar(
        titulo: 'Histórico de preço',
        descricao: '${produto.nome} · ${produto.lojaNome}',
        child: Flexible(
          child: PaginaHistoricoProduto(api: widget.api, produto: produto),
        ),
      ),
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
      alturaMaxima: 0.84,
      builder: (_) => FolhaRadar(
        titulo: 'Filtros · Compre direto',
        descricao: 'Ajuste a ordem e o recorte do catálogo salvo.',
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
}

class _AvisoFalhaBuscaProdutos extends StatelessWidget {
  const _AvisoFalhaBuscaProdutos({
    required this.quantidadePreservada,
    required this.tentarNovamente,
  });

  final int quantidadePreservada;
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
                      Text(
                        '$quantidadePreservada ${quantidadePreservada == 1 ? 'oferta' : 'ofertas'} preservada${quantidadePreservada == 1 ? '' : 's'}',
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: cores.textoSuave,
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

class _AcompanhamentoNotifier extends ChangeNotifier {
  void mudou() => notifyListeners();
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
  var _categorias = const <CategoriaInter>[];
  late String _ordenar = widget.filtros.ordenar;
  late String _loja = widget.filtros.loja;
  late String _categoria = widget.filtros.categoria;
  late bool _semCategoria = widget.filtros.semCategoria;
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
      final lojas = await _carregarLojas(
        filtro: widget.podeLerLojasSelecionadas ? 'todas' : 'acompanhadas',
      );
      CatalogoCategoriasInterUsuario? catalogo;
      try {
        catalogo = await widget.api.categoriasInter();
      } catch (_) {
        // A lista de lojas continua utilizável se as categorias falharem.
      }
      if (!mounted) return;
      setState(() {
        _lojas = lojas;
        _categorias = catalogo?.itens ?? const <CategoriaInter>[];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível carregar as opções de filtro.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<List<LojaDireto>> _carregarLojas({required String filtro}) async {
    final lojas = <LojaDireto>[];
    var pagina = 1;
    while (true) {
      final resposta = await widget.api.lojasDiretas(
        filtro: filtro,
        pagina: pagina,
      );
      lojas.addAll(resposta.itens);
      if (!resposta.temProxima) return lojas;
      pagina++;
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.mostrarCabecalho) ...[
              Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Escolha a ordem, a loja, a categoria e a faixa de preço.',
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
              _tituloSecao('Ordenar', 'como os produtos aparecem'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('filtro-ordenar'),
                isExpanded: true,
                initialValue: _ordenar,
                items: const [
                  DropdownMenuItem(
                    value: 'preco',
                    child: Text('Menor preço por loja'),
                  ),
                  DropdownMenuItem(value: 'nome', child: Text('Nome por loja')),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => _ordenar = valor);
                },
              ),
              const SizedBox(height: 16),
              _tituloSecao('Loja', 'opcional'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('filtro-loja'),
                isExpanded: true,
                initialValue: _lojas.any((loja) => loja.slug == _loja)
                    ? _loja
                    : '',
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas as lojas'),
                  ),
                  for (final loja in _lojas)
                    DropdownMenuItem(value: loja.slug, child: Text(loja.nome)),
                ],
                onChanged: (valor) {
                  if (valor != null) setState(() => _loja = valor);
                },
              ),
              const SizedBox(height: 16),
              _tituloSecao('Categoria', 'opcional'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('filtro-categoria'),
                isExpanded: true,
                initialValue: _valorCategoriaSelecionada,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas as categorias'),
                  ),
                  for (final categoria in _categorias)
                    DropdownMenuItem(
                      value: categoria.semCategoria
                          ? _valorSemCategoria
                          : categoria.valor,
                      child: Text(categoria.nome),
                    ),
                ],
                onChanged: (valor) {
                  if (valor == null) return;
                  setState(() {
                    _semCategoria = valor == _valorSemCategoria;
                    _categoria = _semCategoria ? '' : valor;
                  });
                },
              ),
              const SizedBox(height: 16),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('limpar-filtros-produtos'),
                      onPressed: _limpar,
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _aplicar,
                      child: const Text('Aplicar filtros'),
                    ),
                  ),
                ],
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
      ordenar: _ordenar,
      categoria: _categoria,
      escopos: widget.filtros.escopos,
      semCategoria: _semCategoria,
      loja: _loja,
      precoMin: _precoMin.text,
      precoMax: _precoMax.text,
    ),
  );

  void _limpar() {
    setState(() {
      _ordenar = 'preco';
      _loja = '';
      _categoria = '';
      _semCategoria = false;
      _precoMin.clear();
      _precoMax.clear();
    });
  }

  static const _valorSemCategoria = '__sem_categoria__';

  String get _valorCategoriaSelecionada {
    if (_semCategoria) return _valorSemCategoria;
    if (_categoria.isNotEmpty &&
        _categorias.any((categoria) => categoria.valor == _categoria)) {
      return _categoria;
    }
    return '';
  }
}
