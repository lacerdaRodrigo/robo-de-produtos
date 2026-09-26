import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../administracao/botao_disparo.dart';
import '../produtos/link_shopping_inter.dart';
import 'cartao_cashback_inter.dart';
import 'controlador_cashback_inter.dart';
import 'formato_cashback_inter.dart';

/// Consulta somente leitura dos Sites parceiros do Inter (Fase 4.3).
class PaginaCashbackInter extends StatefulWidget {
  const PaginaCashbackInter({
    super.key,
    required this.api,
    this.controlador,
    this.administrador = false,
    this.incorporada = false,
    this.mostrarAtualizacao = true,
    this.sliversAntesDoCashback = const [],
    this.chaveRolagemCompacta,
    this.aoAlterarAcompanhamento,
    this.aoVariarAcompanhadas,
    this.aoAtualizar,
    this.abrirUrlExterna,
    this.totalCatalogo,
    this.totalAcompanhadas,
  });

  final Api api;
  final ControladorCashbackInter? controlador;
  final bool administrador;
  final bool incorporada;
  final bool mostrarAtualizacao;

  /// Conteúdo que deve rolar antes da busca na experiência mobile integrada.
  final List<Widget> sliversAntesDoCashback;
  final Key? chaveRolagemCompacta;
  final VoidCallback? aoAlterarAcompanhamento;
  final ValueChanged<int>? aoVariarAcompanhadas;
  final Future<void> Function()? aoAtualizar;
  final Future<bool> Function(Uri uri)? abrirUrlExterna;
  final int? totalCatalogo;
  final int? totalAcompanhadas;

  @override
  State<PaginaCashbackInter> createState() => _EstadoPaginaCashbackInter();
}

class _EstadoPaginaCashbackInter extends State<PaginaCashbackInter>
    with WidgetsBindingObserver {
  static const _itensPorPagina = 10;

  late final ControladorCashbackInter _controlador =
      widget.controlador ??
      ControladorCashbackInter(
        buscar: ({required q, required ordenar, required pagina}) =>
            widget.api.painelCashbackInter(
              q: q,
              ordenar: ordenar,
              pagina: pagina,
              porPagina: _itensPorPagina,
              acompanhamentoPessoal: !widget.administrador,
            ),
        buscarComCategoria:
            ({
              required q,
              required ordenar,
              required categoria,
              required pagina,
            }) => widget.api.painelCashbackInter(
              q: q,
              ordenar: ordenar,
              categoria: categoria,
              pagina: pagina,
              porPagina: _itensPorPagina,
              acompanhamentoPessoal: !widget.administrador,
            ),
        buscarAcompanhadas: ({required q, required ordenar, required pagina}) =>
            widget.api.painelCashbackInter(
              q: q,
              ordenar: ordenar,
              pagina: pagina,
              porPagina: _itensPorPagina,
              apenasAcompanhadas: true,
              acompanhamentoPessoal: !widget.administrador,
            ),
        buscarAcompanhadasComCategoria:
            ({
              required q,
              required ordenar,
              required categoria,
              required pagina,
            }) => widget.api.painelCashbackInter(
              q: q,
              ordenar: ordenar,
              categoria: categoria,
              pagina: pagina,
              porPagina: _itensPorPagina,
              apenasAcompanhadas: true,
              acompanhamentoPessoal: !widget.administrador,
            ),
      );
  late final bool _externo = widget.controlador != null;
  late final _campoBusca = TextEditingController(text: _controlador.busca);
  final _rolagem = ScrollController();
  final _acompanhamentoAlterado = <String, bool>{};
  final _alterandoAcompanhamento = <String>{};
  final _salvamentosAcompanhamento = <String, Future<void>>{};
  var _categorias = const <CategoriaCashbackInter>[];
  Object? _erroCategorias;
  late var _filtroCompacto =
      _controlador.filtro == FiltroCashbackInter.acompanhadas ? 1 : 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controlador.carregarInicial();
    unawaited(_carregarCategorias());
  }

  Future<void> _carregarCategorias() async {
    try {
      final categorias = await widget.api.categoriasCashbackInter();
      if (!mounted) return;
      setState(() {
        _categorias = categorias;
        _erroCategorias = null;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() => _erroCategorias = erro);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _campoBusca.dispose();
    _rolagem.dispose();
    if (!_externo) _controlador.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_atualizarDados());
    }
  }

  Future<void> _atualizarDados() async {
    final tarefas = <Future<void>>[_controlador.tentarNovamente()];
    final atualizarResumo = widget.aoAtualizar;
    if (atualizarResumo != null) tarefas.add(atualizarResumo());
    await Future.wait(tarefas);
  }

  void _alternarAcompanhamento(CashbackInter loja) {
    if (_alterandoAcompanhamento.contains(loja.id)) {
      return;
    }
    final tinhaAlteracao = _acompanhamentoAlterado.containsKey(loja.id);
    final valorAnterior = _acompanhamentoAlterado[loja.id];
    final acompanhada = !_estaAcompanhada(loja);
    setState(() {
      _alterandoAcompanhamento.add(loja.id);
      _acompanhamentoAlterado[loja.id] = acompanhada;
    });
    widget.aoVariarAcompanhadas?.call(acompanhada ? 1 : -1);
    _salvamentosAcompanhamento[loja.id] = _salvarAcompanhamento(
      loja: loja,
      acompanhada: acompanhada,
      tinhaAlteracao: tinhaAlteracao,
      valorAnterior: valorAnterior,
    );
  }

  Future<void> _salvarAcompanhamento({
    required CashbackInter loja,
    required bool acompanhada,
    required bool tinhaAlteracao,
    required bool? valorAnterior,
  }) async {
    try {
      if (widget.administrador) {
        await widget.api.alterarFavoritaInter(
          id: loja.id,
          favorita: acompanhada,
        );
      } else {
        await widget.api.alterarAcompanhamentoPessoalCashback(
          id: loja.id,
          ativo: acompanhada,
        );
      }
      if (!mounted) return;
      _controlador.sincronizarAcompanhamento(loja, acompanhada);
      mostrarMensagemRadar(
        context,
        acompanhada
            ? 'Loja adicionada ao acompanhamento.'
            : 'Loja removida do acompanhamento.',
      );
      widget.aoAlterarAcompanhamento?.call();
    } catch (_) {
      if (mounted) {
        setState(() {
          if (tinhaAlteracao) {
            _acompanhamentoAlterado[loja.id] = valorAnterior!;
          } else {
            _acompanhamentoAlterado.remove(loja.id);
          }
        });
        widget.aoVariarAcompanhadas?.call(acompanhada ? -1 : 1);
        mostrarMensagemRadar(
          context,
          'Não foi possível salvar o acompanhamento.',
          sucesso: false,
        );
      }
    } finally {
      _salvamentosAcompanhamento.remove(loja.id);
      if (mounted) {
        setState(() => _alterandoAcompanhamento.remove(loja.id));
      }
    }
  }

  bool _estaAcompanhada(CashbackInter loja) =>
      _acompanhamentoAlterado[loja.id] ?? loja.favorita;

  Future<void> _selecionarFiltroCompacto(int indice) async {
    setState(() => _filtroCompacto = indice);
    final salvamentosPendentes = _salvamentosAcompanhamento.values.toList();
    if (salvamentosPendentes.isNotEmpty) {
      await Future.wait(salvamentosPendentes);
    }
    if (!mounted || _filtroCompacto != indice) return;
    await _controlador.mudarConsulta(
      filtro: indice == 1
          ? FiltroCashbackInter.acompanhadas
          : FiltroCashbackInter.todas,
      ordenacao: OrdenacaoCashbackInter.cashback,
    );
  }

  Future<void> _abrirParceiro(CashbackInter loja) async {
    final link = linkAbsolutoSeguroShoppingInter(loja.link);
    if (link == null) return;
    final abriu =
        await (widget.abrirUrlExterna?.call(link) ??
            launchUrl(link, mode: LaunchMode.externalApplication));
    if (!abriu && mounted) {
      mostrarMensagemRadar(
        context,
        'Não foi possível abrir o Banco Inter.',
        sucesso: false,
      );
    }
  }

  VoidCallback? _acaoAbrirParceiro(CashbackInter loja) =>
      linkAbsolutoSeguroShoppingInter(loja.link) == null
      ? null
      : () => _abrirParceiro(loja);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => _conteudo(context),
  );

  Widget _conteudo(BuildContext context) {
    final cores = CoresRadar.de(context);
    final margem = widget.incorporada ? 18.0 : 24.0;
    final atrasada = coletaInterAtrasada(
      _controlador.atualizadoEm,
      DateTime.now(),
    );

    if (widget.incorporada) {
      return _conteudoCompacto(context, margem);
    }

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            'Sites parceiros',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (widget.mostrarAtualizacao)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margem),
            child: BotaoDisparo(
              api: widget.api,
              dominio: 'inter',
              administrador: widget.administrador,
              rotulo: 'Atualizar Cashback',
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: margem),
          child: CampoBuscaRadar(
            controlador: _campoBusca,
            chaveCampo: const Key('busca-cashback-inter'),
            dica: 'Buscar por loja',
            aoMudar: _controlador.mudarBusca,
            somenteBusca: true,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(margem, 12, margem, 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final ordenacao in OrdenacaoCashbackInter.values)
                ChoiceChip(
                  label: Text(ordenacao.rotulo),
                  selected: _controlador.ordenacao == ordenacao,
                  onSelected: (_) => _controlador.mudarOrdenacao(ordenacao),
                ),
            ],
          ),
        ),
        if (_controlador.atualizadoEm != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margem, vertical: 4),
            child: Text(
              'Última coleta: ${dataHoraInter(_controlador.atualizadoEm)}'
              '${atrasada ? ' · dados atrasados' : ''}',
              style: TextStyle(color: atrasada ? cores.atencao : null),
            ),
          ),
        if (_controlador.atualizadoEm != null && !_controlador.carregando)
          Padding(
            padding: EdgeInsets.fromLTRB(margem, 4, margem, 8),
            child: Text('${_controlador.totalItens} lojas encontradas'),
          ),
        if (_controlador.ultimaTentativaFalhou &&
            _controlador.atualizadoEm != null)
          Padding(
            padding: EdgeInsets.fromLTRB(margem, 4, margem, 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                'A última sincronização do Inter falhou. '
                'Exibindo a última coleta válida.',
                style: TextStyle(color: cores.perigo),
              ),
            ),
          ),
        Expanded(child: _corpo()),
      ],
    );
    return SafeArea(child: conteudo);
  }

  Widget _conteudoCompacto(
    BuildContext context,
    double margem,
  ) => RefreshIndicator(
    key: const Key('puxar-atualizar-cashback-inter'),
    onRefresh: _atualizarDados,
    child: CustomScrollView(
      key: widget.chaveRolagemCompacta ?? const Key('cashback-inter-compacto'),
      controller: _rolagem,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        ...widget.sliversAntesDoCashback,
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            margem,
            context.tokens.spacing.four,
            margem,
            context.tokens.spacing.two,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Lojas com cashback',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: margem),
          sliver: SliverToBoxAdapter(
            child: CampoBuscaRadar(
              controlador: _campoBusca,
              chaveCampo: const Key('busca-cashback-inter'),
              dica: 'Qual loja você procura?',
              aoMudar: _controlador.mudarBusca,
              aoAcionar: () => _controlador.mudarBusca(_campoBusca.text),
            ),
          ),
        ),
        ..._estadoCompacto(margem),
        ..._corpoCompacto(),
      ],
    ),
  );

  List<Widget> _corpoCompacto() {
    if (_controlador.carregando) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Carregando(mensagem: 'Carregando cashback do Inter…'),
        ),
      ];
    }
    if (_controlador.erro != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoFalha(
            mensagem: 'Não foi possível carregar o cashback do Inter.',
            voltar: _controlador.tentarNovamente,
          ),
        ),
      ];
    }
    if (_controlador.atualizadoEm == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _controlador.ultimaTentativaFalhou
              ? EstadoFalha(
                  mensagem:
                      'A última sincronização do Inter falhou. '
                      'Ainda não há dados válidos para mostrar.',
                  voltar: _controlador.tentarNovamente,
                )
              : const EstadoVazio(
                  mensagem: 'O Inter ainda não foi sincronizado.',
                ),
        ),
      ];
    }
    final lojas = _lojasCompactas();
    if (lojas.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoVazio(
            mensagem: _filtroCompacto == 1
                ? 'Nenhuma loja está acompanhada ainda.'
                : _controlador.busca.trim().isEmpty
                ? 'Nenhuma loja do Inter foi encontrada.'
                : 'Nenhuma loja encontrada para “${_controlador.busca.trim()}”.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 112),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            for (final loja in lojas)
              CartaoCashbackInter(
                loja: loja,
                compacto: true,
                acompanhada: _estaAcompanhada(loja),
                alterando: _alterandoAcompanhamento.contains(loja.id),
                atualizadoEm: _controlador.atualizadoEm,
                podeAdministrar: widget.administrador,
                aoAcompanhar: () => _alternarAcompanhamento(loja),
                aoAbrirParceiro: _acaoAbrirParceiro(loja),
              ),
            const SizedBox(height: 4),
            _paginacao(),
          ]),
        ),
      ),
    ];
  }

  List<CashbackInter> _lojasCompactas() => _filtroCompacto == 1
      ? _controlador.itens.where(_estaAcompanhada).toList(growable: false)
      : _controlador.itens;

  List<Widget> _estadoCompacto(double margem) {
    if (_controlador.atualizadoEm == null || _controlador.carregando) {
      return const [];
    }
    final cores = CoresRadar.de(context);
    final atrasada = coletaInterAtrasada(
      _controlador.atualizadoEm,
      DateTime.now(),
    );
    final falhou = _controlador.ultimaTentativaFalhou;
    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(margem, 10, margem, 0),
        sliver: SliverToBoxAdapter(
          child: _FiltrosCompactosInter(
            selecionado: _filtroCompacto,
            aoSelecionar: _selecionarFiltroCompacto,
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(margem, 4, margem, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BarraResultadosCashbackInter(
                total: _controlador.totalItens,
                aoFiltrar: _abrirFiltros,
              ),
              if (falhou || atrasada) ...[
                const SizedBox(height: 10),
                Semantics(
                  liveRegion: falhou,
                  child: Text(
                    falhou
                        ? 'A última sincronização falhou; exibindo a última coleta válida.'
                        : 'Última coleta: ${dataHoraInter(_controlador.atualizadoEm)} · dados atrasados',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: falhou ? cores.perigo : cores.atencao,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  Widget _corpo() {
    if (_controlador.carregando) {
      return const Carregando(mensagem: 'Carregando cashback do Inter…');
    }
    if (_controlador.erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o cashback do Inter.',
        voltar: _controlador.tentarNovamente,
      );
    }
    if (_controlador.atualizadoEm == null) {
      if (_controlador.ultimaTentativaFalhou) {
        return EstadoFalha(
          mensagem:
              'A última sincronização do Inter falhou. '
              'Ainda não há dados válidos para mostrar.',
          voltar: _controlador.tentarNovamente,
        );
      }
      return const EstadoVazio(mensagem: 'O Inter ainda não foi sincronizado.');
    }
    if (_controlador.totalItens == 0) {
      return EstadoVazio(
        mensagem: _controlador.busca.trim().isEmpty
            ? 'Nenhuma loja do Inter foi encontrada.'
            : 'Nenhuma loja encontrada para “${_controlador.busca.trim()}”.',
      );
    }
    return LayoutBuilder(
      builder: (context, limites) {
        final colunas = limites.maxWidth >= 900 ? 2 : 1;
        final margem = widget.incorporada ? 20.0 : 24.0;
        return ListView(
          controller: _rolagem,
          padding: EdgeInsets.fromLTRB(margem, 8, margem, 32),
          children: [
            if (colunas == 1)
              for (final loja in _controlador.itens)
                CartaoCashbackInter(
                  loja: loja,
                  compacto: widget.incorporada,
                  acompanhada: _estaAcompanhada(loja),
                  alterando: _alterandoAcompanhamento.contains(loja.id),
                  podeAdministrar: widget.administrador,
                  aoAcompanhar: () => _alternarAcompanhamento(loja),
                  aoAbrirParceiro: _acaoAbrirParceiro(loja),
                )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final loja in _controlador.itens)
                    SizedBox(
                      width: (limites.maxWidth - 16) / 2,
                      child: CartaoCashbackInter(
                        loja: loja,
                        compacto: widget.incorporada,
                        acompanhada: _estaAcompanhada(loja),
                        alterando: _alterandoAcompanhamento.contains(loja.id),
                        podeAdministrar: widget.administrador,
                        aoAcompanhar: () => _alternarAcompanhamento(loja),
                        aoAbrirParceiro: _acaoAbrirParceiro(loja),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            _paginacao(),
          ],
        );
      },
    );
  }

  Widget _paginacao() {
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
    final filtros = await mostrarFolhaRadar<_FiltrosCashbackInterResultado>(
      context,
      alturaMaxima: 0.62,
      builder: (_) => FolhaRadar(
        titulo: 'Filtros · Sites parceiros',
        descricao: '',
        mostrarVoltar: false,
        child: Flexible(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: _FiltrosCashbackInter(
              selecionada: _controlador.ordenacao,
              categoriaSelecionada: _controlador.categoria,
              categorias: _categorias,
              erroCategorias: _erroCategorias,
            ),
          ),
        ),
      ),
    );
    if (mounted && filtros != null) {
      await _controlador.mudarFiltros(
        ordenacao: filtros.ordenacao,
        categoria: filtros.categoria,
      );
    }
  }
}

class _FiltrosCompactosInter extends StatelessWidget {
  const _FiltrosCompactosInter({
    required this.selecionado,
    required this.aoSelecionar,
  });

  final int selecionado;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) => AbasRadar(
    key: const Key('filtros-cashback-inter'),
    rotulos: const ['Todos', 'No radar'],
    plana: true,
    selecionada: selecionado,
    aoSelecionar: aoSelecionar,
  );
}

class _BarraResultadosCashbackInter extends StatelessWidget {
  const _BarraResultadosCashbackInter({
    required this.total,
    required this.aoFiltrar,
  });

  final int total;
  final VoidCallback aoFiltrar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return Container(
      key: const Key('barra-resultados-cashback-inter'),
      padding: EdgeInsets.only(top: tokens.spacing.three),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$total ${total == 1 ? 'loja encontrada' : 'lojas encontradas'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
            ),
          ),
          OutlinedButton.icon(
            key: const Key('abrir-filtros-cashback-inter'),
            onPressed: aoFiltrar,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Filtros'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, tokens.sizes.touchTarget),
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.three),
              foregroundColor: cores.texto,
              side: BorderSide(color: cores.borda),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(tokens.radii.md),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltrosCashbackInter extends StatefulWidget {
  const _FiltrosCashbackInter({
    required this.selecionada,
    required this.categoriaSelecionada,
    required this.categorias,
    required this.erroCategorias,
  });

  final OrdenacaoCashbackInter selecionada;
  final String? categoriaSelecionada;
  final List<CategoriaCashbackInter> categorias;
  final Object? erroCategorias;

  @override
  State<_FiltrosCashbackInter> createState() => _EstadoFiltrosCashbackInter();
}

class _EstadoFiltrosCashbackInter extends State<_FiltrosCashbackInter> {
  late OrdenacaoCashbackInter _ordenacao = widget.selecionada;
  static const _categoriaTodas = '';
  late String _categoria = widget.categoriaSelecionada ?? _categoriaTodas;

  String _rotuloOrdenacao(OrdenacaoCashbackInter valor) =>
      valor == OrdenacaoCashbackInter.nome ? 'Nome da loja' : valor.rotulo;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    final tema = Theme.of(context);
    final estiloRotulo = tema.textTheme.bodySmall?.copyWith(
      color: cores.texto,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Ordenar', style: estiloRotulo),
        SizedBox(height: tokens.spacing.one),
        Semantics(
          label: 'Ordenar',
          value: _rotuloOrdenacao(_ordenacao),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: tokens.sizes.field),
            child: DropdownButtonFormField<OrdenacaoCashbackInter>(
              key: const Key('filtro-ordenacao-cashback-inter'),
              initialValue: _ordenacao,
              isExpanded: true,
              alignment: AlignmentDirectional.centerStart,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: tokens.sizes.icon,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.four,
                  vertical: tokens.spacing.three,
                ),
              ),
              items: [
                for (final valor in OrdenacaoCashbackInter.values)
                  DropdownMenuItem(
                    value: valor,
                    child: Text(_rotuloOrdenacao(valor)),
                  ),
              ],
              onChanged: (valor) {
                if (valor != null) setState(() => _ordenacao = valor);
              },
            ),
          ),
        ),
        SizedBox(height: tokens.spacing.four),
        Text('Categoria', style: estiloRotulo),
        SizedBox(height: tokens.spacing.one),
        Semantics(
          label: 'Categoria',
          value: _rotuloCategoria,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: tokens.sizes.field),
            child: DropdownButtonFormField<String>(
              key: const Key('filtro-categoria-cashback-inter'),
              initialValue: _categoria,
              isExpanded: true,
              alignment: AlignmentDirectional.centerStart,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: tokens.sizes.icon,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: tokens.spacing.four,
                  vertical: tokens.spacing.three,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: _categoriaTodas,
                  child: Text('Todas as categorias'),
                ),
                for (final categoria in widget.categorias)
                  DropdownMenuItem(
                    key: ValueKey('opcao-categoria-${categoria.codigo}'),
                    value: categoria.codigo,
                    child: Text(categoria.nome),
                  ),
              ],
              onChanged: (valor) {
                if (valor != null) setState(() => _categoria = valor);
              },
            ),
          ),
        ),
        if (widget.erroCategorias != null)
          Padding(
            padding: EdgeInsetsDirectional.only(top: tokens.spacing.two),
            child: Text(
              'Não foi possível carregar as categorias. Tente novamente.',
              style: tema.textTheme.bodySmall?.copyWith(color: cores.perigo),
            ),
          ),
        SizedBox(height: tokens.spacing.four),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const Key('limpar-filtros-cashback-inter'),
                onPressed: () => Navigator.of(context).pop(
                  const _FiltrosCashbackInterResultado(
                    ordenacao: OrdenacaoCashbackInter.cashback,
                    categoria: null,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: cores.superficieAlternativa,
                  foregroundColor: cores.texto,
                  minimumSize: Size(0, tokens.sizes.touchTarget),
                ),
                child: const Text('Limpar'),
              ),
            ),
            SizedBox(width: tokens.spacing.three),
            Expanded(
              child: FilledButton(
                key: const Key('aplicar-filtros-cashback-inter'),
                onPressed: () => Navigator.of(context).pop(
                  _FiltrosCashbackInterResultado(
                    ordenacao: _ordenacao,
                    categoria: _categoria.isEmpty ? null : _categoria,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: cores.acao,
                  foregroundColor: cores.marcaTexto,
                  minimumSize: Size(0, tokens.sizes.touchTarget),
                ),
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String get _rotuloCategoria {
    if (_categoria.isEmpty) return 'Todas as categorias';
    for (final categoria in widget.categorias) {
      if (categoria.codigo == _categoria) return categoria.nome;
    }
    return _categoria;
  }
}

class _FiltrosCashbackInterResultado {
  const _FiltrosCashbackInterResultado({
    required this.ordenacao,
    required this.categoria,
  });

  final OrdenacaoCashbackInter ordenacao;
  final String? categoria;
}
