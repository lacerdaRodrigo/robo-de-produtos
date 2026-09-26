import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import 'controlador_catalogo_pichau.dart';
import 'link_pichau.dart';
import 'modelos_pichau.dart';

/// Catálogo interno da Pichau, acessível pela área Explorar.
///
/// A tela só renderiza o retrato entregue pela API. Busca e paginação pedem
/// outro recorte desse retrato e nunca iniciam coleta na fonte externa.
class PaginaPichau extends StatefulWidget {
  const PaginaPichau({
    super.key,
    required this.api,
    this.administrador = false,
    this.ativa = true,
    this.aoVoltar,
  });

  final Api api;
  final bool administrador;
  final bool ativa;
  final VoidCallback? aoVoltar;

  @override
  State<PaginaPichau> createState() => _EstadoPaginaPichau();
}

class _EstadoPaginaPichau extends State<PaginaPichau> {
  late final ControladorCatalogoPichau _controlador = ControladorCatalogoPichau(
    buscar:
        ({
          required String q,
          required String aba,
          required String disponibilidade,
          required String ordenar,
          required String precoMin,
          required String precoMax,
          required int pagina,
        }) => widget.api.catalogoPichau(
          q: q,
          aba: aba,
          disponibilidade: disponibilidade,
          ordenar: ordenar,
          precoMin: precoMin,
          precoMax: precoMax,
          pagina: pagina,
        ),
    alterarAcompanhamento:
        ({required String idExterno, required bool acompanhada}) =>
            widget.api.alterarAcompanhamentoPichau(
              idExterno: idExterno,
              acompanhada: acompanhada,
            ),
  );
  final _busca = TextEditingController();
  final _rolagem = ScrollController();

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
  }

  @override
  void didUpdateWidget(covariant PaginaPichau antigo) {
    super.didUpdateWidget(antigo);
    if (widget.ativa && !antigo.ativa) {
      _controlador.tentarNovamente();
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => _conteudo(context),
  );

  Widget _conteudo(BuildContext context) {
    final parcial =
        _controlador.qualidade == 'degradada' ||
        _controlador.ultimaTentativaEstado == 'parcial';
    final carregando =
        _controlador.carregandoInicial || _controlador.carregandoMais;
    final itens = _controlador.itens;
    final falha = _controlador.erroInicial != null;
    final falhaComRetrato = falha && itens.isNotEmpty;
    final estado = falha
        ? 'Falha recente'
        : parcial
        ? 'Parcial / atrasado'
        : _controlador.carregandoInicial
        ? 'Carregando'
        : _controlador.totalItens == 0
        ? 'Catálogo vazio'
        : 'Catálogo atualizado';
    return Column(
      children: [
        _CabecalhoPichau(
          aoVoltar: widget.aoVoltar ?? () => Navigator.maybePop(context),
          aoAtualizar: _controlador.tentarNovamente,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controlador.tentarNovamente,
            child: ListView(
              key: const Key('pagina-pichau'),
              controller: _rolagem,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsetsDirectional.fromSTEB(
                context.tokens.spacing.five,
                context.tokens.spacing.four,
                context.tokens.spacing.five,
                context.tokens.spacing.seven,
              ),
              children: [
                Text(
                  'PCs gamer',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: context.tokens.spacing.four),
                CampoBuscaRadar(
                  chaveCampo: const Key('busca-pichau'),
                  controlador: _busca,
                  dica: 'Nome, processador ou SKU',
                  aoAcionar: () => _controlador.mudarBusca(_busca.text),
                  aoMudar: _controlador.mudarBusca,
                ),
                SizedBox(height: context.tokens.spacing.three),
                AbasRadar(
                  key: const Key('abas-pichau'),
                  rotulos: AbaCatalogoPichau.values
                      .map((aba) => aba.rotulo)
                      .toList(),
                  plana: true,
                  selecionada: _controlador.aba.index,
                  aoSelecionar: (indice) =>
                      _controlador.mudarAba(AbaCatalogoPichau.values[indice]),
                ),
                SizedBox(height: context.tokens.spacing.four),
                _BarraCatalogoPichau(
                  total: _controlador.totalItens,
                  estado: estado,
                  carregando: carregando,
                  filtroAtivo:
                      _controlador.disponibilidade !=
                          DisponibilidadePichau.todas ||
                      _controlador.ordenacao != OrdenacaoPichau.preco ||
                      _controlador.precoMin.isNotEmpty ||
                      _controlador.precoMax.isNotEmpty,
                  aoFiltrar: _abrirFiltros,
                ),
                if (parcial || falhaComRetrato) ...[
                  const SizedBox(height: 12),
                  _AvisoQualidadePichau(falha: falhaComRetrato),
                ],
                if (_controlador.carregandoInicial && itens.isEmpty) ...[
                  const SizedBox(height: 22),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: context.tokens.spacing.six,
                    ),
                    child: const Carregando(
                      mensagem: 'Carregando catálogo Pichau…',
                    ),
                  ),
                ] else if (falha && itens.isEmpty) ...[
                  const SizedBox(height: 12),
                  EstadoFalha(
                    mensagem: 'Não foi possível carregar o catálogo Pichau.',
                    voltar: _controlador.tentarNovamente,
                  ),
                ] else if (itens.isEmpty) ...[
                  const SizedBox(height: 12),
                  EstadoVazio(
                    mensagem: _controlador.aba == AbaCatalogoPichau.acompanhadas
                        ? 'Nenhum PC Gamer está acompanhado ainda.'
                        : _controlador.busca.trim().isNotEmpty ||
                              _controlador.disponibilidade !=
                                  DisponibilidadePichau.todas ||
                              _controlador.precoMin.isNotEmpty ||
                              _controlador.precoMax.isNotEmpty
                        ? 'Nenhum PC Gamer corresponde aos filtros atuais.'
                        : 'Nenhum PC Gamer foi encontrado na última coleta completa.',
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  for (final produto in itens) ...[
                    CartaoPichau(
                      produto: produto,
                      alterando: _controlador.mutacoesPendentes.contains(
                        produto.idExterno,
                      ),
                      aoAlternarAcompanhamento: () =>
                          _alternarAcompanhamento(produto),
                      aoAbrirDetalhes: () => _abrirDetalhes(produto),
                    ),
                    if (produto != itens.last) const SizedBox(height: 10),
                  ],
                  if (carregando)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    ),
                  const SizedBox(height: 17),
                  PaginacaoRadar(
                    pagina: _controlador.pagina,
                    totalItens: _controlador.totalItens,
                    porPagina: _controlador.porPagina,
                    carregando: _controlador.carregandoMais,
                    erro: _controlador.erroMais,
                    aoIrParaPagina: _irParaPagina,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _irParaPagina(int pagina) async {
    await _controlador.irParaPagina(pagina);
    if (mounted && _controlador.pagina == pagina) {
      await rolarParaInicioPaginaRadar(_rolagem);
    }
  }

  Future<void> _alternarAcompanhamento(PichauProduto produto) async {
    final acompanhada = !produto.acompanhada;
    final sucesso = await _controlador.alternarAcompanhamento(produto);
    if (!mounted) return;
    mostrarMensagemRadar(
      context,
      sucesso
          ? acompanhada
                ? 'Produto adicionado às acompanhadas.'
                : 'Produto removido das acompanhadas.'
          : 'Não foi possível salvar o acompanhamento.',
      sucesso: sucesso,
    );
  }

  Future<void> _abrirFiltros() async {
    final filtros = await mostrarFolhaRadar<_FiltrosPichauResultado>(
      context,
      builder: (_) => _FolhaFiltrosPichau(
        disponibilidade: _controlador.disponibilidade,
        ordenacao: _controlador.ordenacao,
        precoMin: _controlador.precoMin,
        precoMax: _controlador.precoMax,
      ),
    );
    if (!mounted || filtros == null) return;
    await _controlador.aplicarFiltros(
      disponibilidade: filtros.disponibilidade,
      ordenacao: filtros.ordenacao,
      precoMin: filtros.precoMin,
      precoMax: filtros.precoMax,
    );
  }

  VoidCallback? _acaoAbrirProduto(PichauProduto produto) {
    final link = linkSeguroPichau(produto.urlProduto);
    if (link == null) return null;
    return () => _abrirProduto(link);
  }

  Future<void> _abrirProduto(Uri link) async {
    final abriu = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      mostrarMensagemRadar(
        context,
        'Não foi possível abrir a Pichau.',
        sucesso: false,
      );
    }
  }

  Future<void> _abrirHistorico(PichauProduto produto) async {
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.9,
      builder: (contexto) => FolhaRadar(
        titulo: 'Histórico de preço',
        descricao: '${produto.nome} · Pichau',
        child: Flexible(
          child: PaginaHistoricoPichau(api: widget.api, produto: produto),
        ),
      ),
    );
  }

  Future<void> _abrirDetalhes(PichauProduto produto) async {
    Future<void> abrirHistorico() async {
      Navigator.of(context).pop();
      await _abrirHistorico(produto);
    }

    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.92,
      builder: (contexto) => FolhaRadar(
        titulo: 'Detalhes',
        descricao: '${produto.marca ?? 'Pichau'} · ${produto.idExterno}',
        child: Flexible(
          child: _DetalhesPichau(
            produto: produto,
            aoAbrirHistorico: abrirHistorico,
            aoAbrirNoSite: _acaoAbrirProduto(produto),
          ),
        ),
      ),
    );
  }
}

class _FiltrosPichauResultado {
  const _FiltrosPichauResultado({
    required this.disponibilidade,
    required this.ordenacao,
    required this.precoMin,
    required this.precoMax,
  });

  final DisponibilidadePichau disponibilidade;
  final OrdenacaoPichau ordenacao;
  final String precoMin;
  final String precoMax;
}

class _FolhaFiltrosPichau extends StatefulWidget {
  const _FolhaFiltrosPichau({
    required this.disponibilidade,
    required this.ordenacao,
    required this.precoMin,
    required this.precoMax,
  });

  final DisponibilidadePichau disponibilidade;
  final OrdenacaoPichau ordenacao;
  final String precoMin;
  final String precoMax;

  @override
  State<_FolhaFiltrosPichau> createState() => _EstadoFolhaFiltrosPichau();
}

class _EstadoFolhaFiltrosPichau extends State<_FolhaFiltrosPichau> {
  late var _disponibilidade = widget.disponibilidade;
  late var _ordenacao = widget.ordenacao;
  late final _precoMin = TextEditingController(text: widget.precoMin);
  late final _precoMax = TextEditingController(text: widget.precoMax);
  String? _erro;

  @override
  void dispose() {
    _precoMin.dispose();
    _precoMax.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final estiloRotulo = Theme.of(context).textTheme.labelMedium;

    Widget rotulo(String texto) => Text(texto, style: estiloRotulo);

    Widget campoPreco({
      required Key key,
      required String rotuloTexto,
      required String dica,
      required TextEditingController controlador,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rotulo(rotuloTexto),
        SizedBox(height: tokens.spacing.one),
        TextField(
          key: key,
          controller: controlador,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          scrollPadding: EdgeInsets.only(bottom: tokens.sizes.touchTarget),
          decoration: InputDecoration(hintText: dica),
          onChanged: (_) {
            if (_erro != null) setState(() => _erro = null);
          },
        ),
      ],
    );

    final formulario = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        rotulo('Ordenar'),
        SizedBox(height: tokens.spacing.one),
        DropdownButtonFormField<OrdenacaoPichau>(
          key: const Key('filtro-ordenacao-pichau'),
          initialValue: _ordenacao,
          isExpanded: true,
          alignment: AlignmentDirectional.centerStart,
          decoration: const InputDecoration(),
          items: [
            for (final valor in OrdenacaoPichau.values)
              DropdownMenuItem(value: valor, child: Text(valor.rotulo)),
          ],
          onChanged: (valor) {
            if (valor != null) setState(() => _ordenacao = valor);
          },
        ),
        SizedBox(height: tokens.spacing.four),
        rotulo('Disponibilidade'),
        SizedBox(height: tokens.spacing.one),
        DropdownButtonFormField<DisponibilidadePichau>(
          key: const Key('filtro-disponibilidade-pichau'),
          initialValue: _disponibilidade,
          isExpanded: true,
          alignment: AlignmentDirectional.centerStart,
          decoration: const InputDecoration(),
          items: [
            for (final valor in DisponibilidadePichau.values)
              DropdownMenuItem(value: valor, child: Text(valor.rotulo)),
          ],
          onChanged: (valor) {
            if (valor != null) setState(() => _disponibilidade = valor);
          },
        ),
        SizedBox(height: tokens.spacing.four),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: campoPreco(
                key: const Key('filtro-preco-minimo-pichau'),
                rotuloTexto: 'Preço mínimo (R\$)',
                dica: '0,00',
                controlador: _precoMin,
              ),
            ),
            SizedBox(width: tokens.spacing.two),
            Expanded(
              child: campoPreco(
                key: const Key('filtro-preco-maximo-pichau'),
                rotuloTexto: 'Preço máximo (R\$)',
                dica: 'Sem limite',
                controlador: _precoMax,
              ),
            ),
          ],
        ),
        if (_erro != null) ...[
          SizedBox(height: tokens.spacing.two),
          Text(
            _erro!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CoresRadar.de(context).perigo,
            ),
          ),
        ],
        SizedBox(height: tokens.spacing.five),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const Key('limpar-filtros-pichau'),
                style: FilledButton.styleFrom(
                  backgroundColor: CoresRadar.de(context).superficieAlternativa,
                  foregroundColor: CoresRadar.de(context).texto,
                ),
                onPressed: () => setState(() {
                  _disponibilidade = DisponibilidadePichau.todas;
                  _ordenacao = OrdenacaoPichau.preco;
                  _precoMin.clear();
                  _precoMax.clear();
                }),
                child: const Text('Limpar'),
              ),
            ),
            SizedBox(width: tokens.spacing.two),
            Expanded(
              child: FilledButton(
                key: const Key('aplicar-filtros-pichau'),
                onPressed: () {
                  final erro = _validarFaixaPichau(
                    _precoMin.text,
                    _precoMax.text,
                  );
                  if (erro != null) {
                    setState(() => _erro = erro);
                    return;
                  }
                  Navigator.of(context).pop(
                    _FiltrosPichauResultado(
                      disponibilidade: _disponibilidade,
                      ordenacao: _ordenacao,
                      precoMin: _precoMin.text,
                      precoMax: _precoMax.text,
                    ),
                  );
                },
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ],
    );

    return FolhaRadar(
      titulo: 'Filtros · Pichau',
      descricao: '',
      mostrarVoltar: false,
      fecharComFundo: false,
      // Mantenha o mesmo pai enquanto o teclado entra ou sai. Se o tipo do
      // pai muda nesse frame, o TextField é reparentado e perde o foco antes
      // de o Android terminar de abrir o teclado.
      child: Flexible(
        child: SingleChildScrollView(
          key: const Key('formulario-filtros-pichau-rolavel'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const ClampingScrollPhysics(),
          child: formulario,
        ),
      ),
    );
  }
}

class _CabecalhoPichau extends StatelessWidget {
  const _CabecalhoPichau({required this.aoVoltar, required this.aoAtualizar});

  final VoidCallback aoVoltar;
  final VoidCallback aoAtualizar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tema = Theme.of(context);
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: cores.borda)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: tokens.spacing.two,
            end: tokens.spacing.two,
            top: tokens.spacing.one,
            bottom: tokens.spacing.one,
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('voltar-programas-pichau'),
                tooltip: 'Voltar para Explorar',
                onPressed: aoVoltar,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: tokens.spacing.one,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pichau',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Catálogo',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: cores.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                key: const Key('atualizar-pichau'),
                tooltip: 'Atualizar catálogo',
                onPressed: aoAtualizar,
                style: IconButton.styleFrom(
                  minimumSize: Size.square(tokens.sizes.touchTarget),
                  backgroundColor: cores.superficieAlternativa,
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartaoPichau extends StatelessWidget {
  const CartaoPichau({
    super.key,
    required this.produto,
    required this.aoAbrirDetalhes,
    this.alterando = false,
    this.aoAlternarAcompanhamento,
  });

  final PichauProduto produto;
  final VoidCallback aoAbrirDetalhes;
  final bool alterando;
  final VoidCallback? aoAlternarAcompanhamento;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tema = Theme.of(context);
    final tokens = context.tokens;
    final estadoTexto = produto.foraDoCatalogo
        ? 'Fora do catálogo'
        : produto.esgotado
        ? 'Esgotado'
        : 'Disponível';
    final identificador = produto.sku?.trim().isNotEmpty == true
        ? produto.sku!.trim()
        : produto.idExterno;
    final metadados = [
      if (produto.marca != null && produto.marca!.trim().isNotEmpty)
        produto.marca!.trim(),
      if (produto.categoria != null && produto.categoria!.trim().isNotEmpty)
        produto.categoria!.trim(),
    ].join(' · ');
    final cartao = produto.precoCartaoTexto == null
        ? null
        : 'Cartão ${produto.precoCartaoTexto}';
    final desconto = _rotuloDescontoPichau(produto.descontoPixTexto);
    final cartaoComplemento = [
      cartao,
      desconto,
    ].whereType<String>().join(' · ');

    return Semantics(
      label: 'PC Gamer ${produto.nome}, origem Pichau',
      child: CartaoRadar(
        padding: EdgeInsets.zero,
        corDestaque: produto.foraDoCatalogo || produto.esgotado
            ? cores.atencao
            : cores.acao,
        child: Padding(
          padding: EdgeInsets.all(tokens.spacing.four),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      identificador,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spacing.two),
                  Flexible(
                    child: Text(
                      estadoTexto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.three),
              Text(
                produto.nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (metadados.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spacing.two),
                  child: Text(
                    metadados,
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: cores.textoSuave,
                    ),
                  ),
                ),
              Divider(height: tokens.spacing.five, color: cores.borda),
              if (produto.precoOriginalTexto != null)
                Text(
                  produto.precoOriginalTexto!,
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: cores.textoSuave,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              MediaQuery.textScalerOf(context).scale(1) > 1
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          produto.precoPixTexto ?? 'Preço Pix indisponível',
                          style: tema.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        if (produto.precoPixTexto != null)
                          Text(
                            'no Pix',
                            style: tema.textTheme.labelMedium?.copyWith(
                              color: cores.textoSuave,
                            ),
                          ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            produto.precoPixTexto ?? 'Preço Pix indisponível',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                        ),
                        if (produto.precoPixTexto != null) ...[
                          SizedBox(width: tokens.spacing.one),
                          Text(
                            'no Pix',
                            style: tema.textTheme.labelMedium?.copyWith(
                              color: cores.textoSuave,
                            ),
                          ),
                        ],
                      ],
                    ),
              if (cartaoComplemento.isNotEmpty || produto.parcelamento != null)
                Padding(
                  padding: EdgeInsets.only(top: tokens.spacing.one),
                  child: Text(
                    cartaoComplemento.isNotEmpty
                        ? cartaoComplemento
                        : produto.parcelamento!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: cores.textoSuave,
                    ),
                  ),
                ),
              Divider(height: tokens.spacing.five, color: cores.borda),
              LayoutBuilder(
                builder: (context, limites) {
                  final acompanhar = OutlinedButton.icon(
                    key: Key('acompanhar-pichau-${produto.idExterno}'),
                    onPressed: !alterando ? aoAlternarAcompanhamento : null,
                    icon: alterando
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            produto.acompanhada
                                ? Icons.check_rounded
                                : Icons.notifications_none_outlined,
                          ),
                    label: Text(
                      produto.acompanhada ? 'Acompanhando' : 'Acompanhar',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(0, tokens.sizes.touchTarget),
                      foregroundColor: produto.acompanhada
                          ? cores.ganho
                          : cores.acao,
                      backgroundColor: produto.acompanhada
                          ? cores.ganho.withValues(alpha: 0.12)
                          : cores.acao.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: produto.acompanhada ? cores.ganho : cores.acao,
                      ),
                    ),
                  );
                  final detalhes = TextButton(
                    key: Key('detalhes-pichau-${produto.idExterno}'),
                    onPressed: aoAbrirDetalhes,
                    style: TextButton.styleFrom(
                      minimumSize: Size(0, tokens.sizes.touchTarget),
                      padding: EdgeInsetsDirectional.only(
                        start: tokens.spacing.two,
                        end: tokens.spacing.one,
                      ),
                      foregroundColor: cores.acao,
                    ),
                    child: MediaQuery.textScalerOf(context).scale(1) > 1
                        ? const Text('Detalhes')
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Detalhes'),
                              SizedBox(width: tokens.spacing.one),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  );
                  final empilhar =
                      MediaQuery.textScalerOf(context).scale(1) > 1;
                  return empilhar
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            acompanhar,
                            SizedBox(height: tokens.spacing.two),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: detalhes,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: acompanhar),
                            SizedBox(width: tokens.spacing.two),
                            detalhes,
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalhesPichau extends StatelessWidget {
  const _DetalhesPichau({
    required this.produto,
    required this.aoAbrirHistorico,
    required this.aoAbrirNoSite,
  });

  final PichauProduto produto;
  final VoidCallback aoAbrirHistorico;
  final VoidCallback? aoAbrirNoSite;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tema = Theme.of(context);
    final tokens = context.tokens;
    final estadoTexto = produto.foraDoCatalogo
        ? 'Fora do catálogo'
        : produto.esgotado
        ? 'Esgotado'
        : 'Disponível';
    final dados = <(String, String)>[
      if (produto.precoCartaoTexto != null)
        ('No cartão', produto.precoCartaoTexto!),
      if (produto.descontoPixTexto != null)
        ('Desconto no Pix', produto.descontoPixTexto!),
      if (produto.parcelamento != null) ('Parcelamento', produto.parcelamento!),
      if (produto.semJuros == true) ('Condição', 'Sem juros'),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IndicadorEstadoRadar(
            texto: estadoTexto,
            tom: produto.esgotado || produto.foraDoCatalogo
                ? TomRadar.atencao
                : TomRadar.ganho,
          ),
          SizedBox(height: tokens.spacing.three),
          Text(
            produto.nome,
            style: tema.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (produto.marca != null || produto.categoria != null)
            Padding(
              padding: EdgeInsets.only(top: tokens.spacing.two),
              child: Text(
                [produto.marca, produto.categoria]
                    .whereType<String>()
                    .where((texto) => texto.trim().isNotEmpty)
                    .join(' · '),
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
                ),
              ),
            ),
          SizedBox(height: tokens.spacing.four),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cores.superficieAlternativa,
              borderRadius: BorderRadius.circular(tokens.radii.lg),
            ),
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.four),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preço no Pix',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: cores.textoSuave,
                    ),
                  ),
                  if (produto.precoOriginalTexto != null)
                    Text(
                      produto.precoOriginalTexto!,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: cores.textoSuave,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    produto.precoPixTexto ?? 'Não informado',
                    style: tema.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (produto.atualizadoEm != null)
                    Text(
                      produto.atualizadoEm!,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: tokens.spacing.four),
          for (final dado in dados) ...[
            _FatoPichau(rotulo: dado.$1, valor: dado.$2),
            Divider(height: tokens.spacing.four, color: cores.borda),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: Key('historico-pichau-${produto.idExterno}'),
                  onPressed: aoAbrirHistorico,
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Histórico'),
                ),
              ),
              SizedBox(width: tokens.spacing.two),
              Expanded(
                child: FilledButton(
                  key: Key('abrir-pichau-${produto.idExterno}'),
                  onPressed: aoAbrirNoSite,
                  child: const Text('Abrir Pichau'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FatoPichau extends StatelessWidget {
  const _FatoPichau({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            rotulo,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
          ),
        ),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String? _rotuloDescontoPichau(String? texto) {
  final valor = texto?.trim();
  if (valor == null || valor.isEmpty) return null;
  final normalizado = valor.replaceAll(RegExp(r'\s+'), ' ');
  final minusculo = normalizado.toLowerCase();
  if (minusculo.contains('desconto')) {
    return minusculo.contains('pix') ? normalizado : '$normalizado no Pix';
  }
  final percentual = normalizado
      .replaceFirst(RegExp(r'\s+off$', caseSensitive: false), '')
      .replaceFirst(RegExp(r'\s+no\s+pix$', caseSensitive: false), '')
      .trim();
  return '$percentual de desconto no Pix';
}

class _BarraCatalogoPichau extends StatelessWidget {
  const _BarraCatalogoPichau({
    required this.total,
    required this.estado,
    required this.carregando,
    required this.filtroAtivo,
    required this.aoFiltrar,
  });

  final int total;
  final String estado;
  final bool carregando;
  final bool filtroAtivo;
  final VoidCallback aoFiltrar;

  @override
  Widget build(BuildContext context) {
    final totalTexto = total == 1 ? '1 produto' : '$total produtos';
    final tom = estado == 'Catálogo atualizado'
        ? TomRadar.ganho
        : estado == 'Parcial / atrasado' || estado == 'Falha recente'
        ? TomRadar.atencao
        : TomRadar.neutro;
    final resumo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          totalTexto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
          ),
        ),
      ],
    );
    final filtro = OutlinedButton.icon(
      key: const Key('filtrar-ordenar-pichau'),
      onPressed: aoFiltrar,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, context.tokens.sizes.touchTarget),
        padding: EdgeInsets.symmetric(horizontal: context.tokens.spacing.three),
        backgroundColor: filtroAtivo
            ? CoresRadar.de(context).acao.withValues(alpha: 0.1)
            : null,
      ),
      icon: const Icon(Icons.tune_rounded, size: 17),
      label: Text('Filtros${filtroAtivo ? ' (1)' : ''}'),
    );
    final linha = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: resumo),
        SizedBox(width: context.tokens.spacing.two),
        filtro,
      ],
    );
    final mostrarEstado = estado != 'Catálogo atualizado' || carregando;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, limites) => limites.maxWidth < 330
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    resumo,
                    SizedBox(height: context.tokens.spacing.two),
                    filtro,
                  ],
                )
              : linha,
        ),
        if (mostrarEstado) ...[
          SizedBox(height: context.tokens.spacing.two),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IndicadorEstadoRadar(
              texto: carregando && total > 0 ? 'Atualizando' : estado,
              tom: carregando && total > 0 ? TomRadar.acao : tom,
            ),
          ),
        ],
      ],
    );
  }
}

class _AvisoQualidadePichau extends StatelessWidget {
  const _AvisoQualidadePichau({required this.falha});

  final bool falha;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.atencao.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 17, color: cores.atencao),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                falha
                    ? 'A última tentativa da Pichau falhou. Mantivemos o último catálogo válido.'
                    : 'A coleta da Pichau está parcial ou atrasada. O último catálogo válido continua disponível.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cores.atencao,
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaginaHistoricoPichau extends StatefulWidget {
  const PaginaHistoricoPichau({
    super.key,
    required this.api,
    required this.produto,
  });

  final Api api;
  final PichauProduto produto;

  @override
  State<PaginaHistoricoPichau> createState() => _EstadoPaginaHistoricoPichau();
}

class _EstadoPaginaHistoricoPichau extends State<PaginaHistoricoPichau> {
  final _medicoes = <MedicaoPichau>[];
  HistoricoPichau? _resumo;
  Object? _erro;
  Object? _erroMais;
  var _carregando = true;
  var _carregandoMais = false;
  var _pagina = 0;
  var _temProxima = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool mais = false}) async {
    if (mais && (_carregandoMais || !_temProxima)) return;
    setState(() {
      if (mais) {
        _carregandoMais = true;
        _erroMais = null;
      } else {
        _carregando = true;
        _erro = null;
      }
    });
    try {
      final resposta = await widget.api.historicoPichau(
        idExterno: widget.produto.idExterno,
        pagina: mais ? _pagina + 1 : 1,
      );
      if (!mounted) return;
      setState(() {
        _resumo = resposta;
        if (mais) {
          _medicoes.addAll(resposta.medicoes);
        } else {
          _medicoes
            ..clear()
            ..addAll(resposta.medicoes);
        }
        _pagina = resposta.pagina;
        _temProxima = resposta.temProxima;
      });
    } catch (erro) {
      if (mounted) {
        setState(() {
          if (mais) {
            _erroMais = erro;
          } else {
            _erro = erro;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
          _carregandoMais = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const SizedBox(
        height: 180,
        child: Carregando(mensagem: 'Carregando histórico…'),
      );
    }
    if (_erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o histórico deste PC.',
        voltar: _carregar,
      );
    }

    final resumo = _resumo!;
    return ListView(
      key: const Key('historico-pichau-conteudo'),
      padding: const EdgeInsets.fromLTRB(1, 0, 1, 12),
      children: [
        if (resumo.minimoPixTexto != null || resumo.maximoPixTexto != null)
          _ResumoHistoricoPichau(
            minimo: resumo.minimoPixTexto,
            maximo: resumo.maximoPixTexto,
          ),
        const SizedBox(height: 10),
        Text(
          '${resumo.totalItens} ${resumo.totalItens == 1 ? 'medição' : 'medições'} nos últimos 30 dias',
          style: TextStyle(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_medicoes.isEmpty)
          const EstadoVazio(mensagem: 'Nenhuma medição de preço disponível.')
        else
          for (final medicao in _medicoes)
            _LinhaHistoricoPichau(medicao: medicao),
        const SizedBox(height: 10),
        Text(
          'O histórico é paginado e limitado à janela de 30 dias.',
          style: TextStyle(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        if (_carregandoMais)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_erroMais != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: FilledButton.tonal(
                onPressed: () => _carregar(mais: true),
                child: const Text('Tentar carregar mais medições'),
              ),
            ),
          )
        else if (_temProxima)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: OutlinedButton(
                onPressed: () => _carregar(mais: true),
                child: const Text('Carregar mais medições'),
              ),
            ),
          ),
      ],
    );
  }
}

class _LinhaHistoricoPichau extends StatelessWidget {
  const _LinhaHistoricoPichau({required this.medicao});

  final MedicaoPichau medicao;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cores.borda)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _momentoPichau(medicao.momento),
            style: TextStyle(
              color: cores.textoSuave,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          _MetricaPichau(
            rotulo: 'Preço Pix',
            valor: medicao.precoPixTexto ?? 'Não informado',
            cor: medicao.precoPixTexto == null ? cores.textoSuave : cores.ganho,
          ),
          const SizedBox(height: 4),
          _MetricaPichau(
            rotulo: 'Preço no cartão',
            valor: medicao.precoCartaoTexto ?? 'Não informado',
            cor: medicao.precoCartaoTexto == null
                ? cores.textoSuave
                : Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}

class _MetricaPichau extends StatelessWidget {
  const _MetricaPichau({
    required this.rotulo,
    required this.valor,
    required this.cor,
  });

  final String rotulo;
  final String valor;
  final Color cor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          rotulo,
          style: TextStyle(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 10,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        valor,
        textAlign: TextAlign.right,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _ResumoHistoricoPichau extends StatelessWidget {
  const _ResumoHistoricoPichau({required this.minimo, required this.maximo});

  final String? minimo;
  final String? maximo;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CoresRadar.de(context).superficieAlternativa,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _MetricaPichau(
              rotulo: 'Mínimo Pix',
              valor: minimo ?? 'Não informado',
              cor: CoresRadar.de(context).ganho,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricaPichau(
              rotulo: 'Máximo Pix',
              valor: maximo ?? 'Não informado',
              cor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}

List<String>? _partesDecimalPichau(String valor) {
  final texto = valor.trim().replaceAll(',', '.');
  if (texto.isEmpty) return null;
  if (!RegExp(r'^\d+(?:\.\d+)?$').hasMatch(texto)) return null;
  final partes = texto.split('.');
  final inteiro = partes.first.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final fracao = partes.length == 2
      ? partes.last.replaceFirst(RegExp(r'0+$'), '')
      : '';
  return [inteiro, fracao];
}

int _compararDecimaisPichau(List<String> primeiro, List<String> segundo) {
  if (primeiro.first.length != segundo.first.length) {
    return primeiro.first.length.compareTo(segundo.first.length);
  }
  final parteInteira = primeiro.first.compareTo(segundo.first);
  if (parteInteira != 0) return parteInteira;
  final tamanho = primeiro.last.length > segundo.last.length
      ? primeiro.last.length
      : segundo.last.length;
  final primeiraFracao = primeiro.last.padRight(tamanho, '0');
  final segundaFracao = segundo.last.padRight(tamanho, '0');
  return primeiraFracao.compareTo(segundaFracao);
}

String? _validarFaixaPichau(String minimo, String maximo) {
  final minimoInformado = minimo.trim().isNotEmpty;
  final maximoInformado = maximo.trim().isNotEmpty;
  final partesMinimo = minimoInformado
      ? _partesDecimalPichau(minimo)
      : const <String>[];
  final partesMaximo = maximoInformado
      ? _partesDecimalPichau(maximo)
      : const <String>[];
  if ((minimoInformado && partesMinimo == null) ||
      (maximoInformado && partesMaximo == null)) {
    return 'Use valores válidos para a faixa de preço.';
  }
  if (minimoInformado &&
      maximoInformado &&
      partesMinimo != null &&
      partesMaximo != null &&
      _compararDecimaisPichau(partesMinimo, partesMaximo) > 0) {
    return 'O preço máximo deve ser maior ou igual ao mínimo.';
  }
  return null;
}

String _momentoPichau(String? valor) {
  final data = DateTime.tryParse(valor ?? '')?.toLocal();
  if (data == null) {
    return valor?.trim().isNotEmpty == true ? valor! : 'Momento não informado';
  }
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final hora = data.hour.toString().padLeft(2, '0');
  final minuto = data.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year} · $hora:$minuto';
}
