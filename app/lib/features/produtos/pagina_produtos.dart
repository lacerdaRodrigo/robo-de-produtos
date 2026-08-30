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
    this.aoEscolherLojas,
  });

  final Api api;
  final ControladorBuscaProdutos? controlador;
  final bool administrador;
  final bool incorporada;
  final bool mostrarTituloInterno;
  final bool experienciaCompacta;
  final VoidCallback? aoEscolherLojas;

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
              loja,
              precoMin,
              precoMax,
            }) => widget.api.buscarProdutos(
              termo,
              pagina: pagina,
              marca: marca,
              categoria: categoria,
              loja: loja,
              precoMin: precoMin,
              precoMax: precoMax,
            ),
      );
  late final bool _controladorExterno = widget.controlador != null;
  final _campoBusca = TextEditingController();

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
                      'Catálogo mais recente: ${dataHoraProduto(_controlador.atualizadoEm)}'
                      '${atrasado ? ' · dados atrasados' : ''}',
                      style: TextStyle(color: atrasado ? cores.atencao : null),
                    ),
                  ),
                if (_controlador.qualidade == 'degradada')
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      'A última coleta foi degradada; produtos ausentes não foram removidos.',
                    ),
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
                        Chip(
                          label: Text(
                            _controlador.qualidade == 'degradada'
                                ? 'Catálogo degradado'
                                : 'Catálogo completo',
                          ),
                        ),
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
    return CustomScrollView(
      key: const Key('produtos-compacto'),
      slivers: [
        if (widget.mostrarTituloInterno)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 22, 18, 20),
            sliver: SliverToBoxAdapter(
              child: CabecalhoSecaoRadar(
                sobrelinha: 'Catálogo local',
                titulo: 'Buscar produtos',
                descricao:
                    'Os resultados vêm apenas das lojas que você selecionou no Banco Inter.',
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
        SliverToBoxAdapter(child: _filtrosCompactos()),
        if (_controlador.atualizadoEm != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Catálogo mais recente: ${dataHoraProduto(_controlador.atualizadoEm)}'
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
                'A última coleta foi degradada; produtos ausentes não foram removidos.',
              ),
            ),
          ),
        if (_controlador.termoValido &&
            !_controlador.carregando &&
            _controlador.erro == null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 11),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_controlador.totalItens} resultados encontrados',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
        if (widget.aoEscolherLojas != null) ...[
          const SizedBox(width: 7),
          _ChipProduto(
            texto: '+ escolher lojas',
            aoTocar: widget.aoEscolherLojas!,
          ),
        ],
      ],
    ),
  );

  List<Widget> _corpoCompacto() {
    if (!_controlador.termoValido) {
      return const [
        SliverToBoxAdapter(
          child: EstadoVazio(
            mensagem:
                'Digite pelo menos 2 caracteres para pesquisar no catálogo.',
          ),
        ),
      ];
    }
    if (_controlador.carregando) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Carregando(mensagem: 'Buscando produtos no catálogo…'),
          ),
        ),
      ];
    }
    if (_controlador.erro != null) {
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
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: _controlador.itens.length,
          separatorBuilder: (_, _) => const SizedBox(height: 11),
          itemBuilder: (context, indice) =>
              _cartao(_controlador.itens[indice], compacto: true),
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
    if (_controlador.carregando) {
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

  Widget _cartao(ProdutoDireto produto, {bool compacto = false}) {
    final link = linkSeguroShoppingInter(produto.caminho);
    return CartaoProduto(
      produto: produto,
      compacto: compacto,
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
    final filtros = _controlador.filtros;
    final marca = TextEditingController(text: filtros.marca);
    final categoria = TextEditingController(text: filtros.categoria);
    final loja = TextEditingController(text: filtros.loja);
    final precoMin = TextEditingController(text: filtros.precoMin);
    final precoMax = TextEditingController(text: filtros.precoMax);
    final novos = await showModalBottomSheet<FiltrosProdutos>(
      context: context,
      isScrollControlled: true,
      builder: (contexto) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(contexto).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filtros', style: Theme.of(contexto).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: marca,
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                TextField(
                  controller: categoria,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                TextField(
                  controller: loja,
                  decoration: const InputDecoration(labelText: 'Loja (slug)'),
                ),
                TextField(
                  controller: precoMin,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Preço mínimo'),
                ),
                TextField(
                  controller: precoMax,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Preço máximo'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(contexto).pop(
                    FiltrosProdutos(
                      marca: marca.text,
                      categoria: categoria.text,
                      loja: loja.text,
                      precoMin: precoMin.text,
                      precoMax: precoMax.text,
                    ),
                  ),
                  child: const Text('Aplicar filtros'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Os campos ainda pertencem à animação de saída do bottom sheet depois
    // que o Future retorna. Eles são descartados junto do modal; destruí-los
    // aqui faria o Flutter tentar reconstruir um TextField já sem controller.
    if (mounted && novos != null) _controlador.mudarFiltros(novos);
  }
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
