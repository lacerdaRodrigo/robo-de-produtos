import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../administracao/botao_disparo.dart';
import 'cartao_catalogo_livelo.dart';
import 'controlador_catalogo_livelo.dart';
import 'formato_livelo.dart';
import 'pagina_historico_livelo_android.dart';

class PaginaCatalogoLiveloAndroid extends StatefulWidget {
  const PaginaCatalogoLiveloAndroid({
    super.key,
    required this.api,
    required this.administrador,
    this.aoAbrirAlertas,
    this.aoVoltar,
    this.controlador,
  });

  final Api api;
  final bool administrador;
  final VoidCallback? aoAbrirAlertas;
  final VoidCallback? aoVoltar;
  final ControladorCatalogoLivelo? controlador;

  @override
  State<PaginaCatalogoLiveloAndroid> createState() =>
      _EstadoPaginaCatalogoLiveloAndroid();
}

class _EstadoPaginaCatalogoLiveloAndroid
    extends State<PaginaCatalogoLiveloAndroid> {
  static const _itensPorPagina = 10;
  static const _intervaloAcompanhamento = Duration(seconds: 30);
  static const _maximoTentativasAcompanhamento = 21;
  static const _maximoFalhasConsecutivas = 3;
  static const _abasVisiveis = [
    AbaCatalogoLivelo.lojas,
    AbaCatalogoLivelo.acompanhadas,
  ];

  late final ControladorCatalogoLivelo _controlador =
      widget.controlador ??
      ControladorCatalogoLivelo(
        buscar:
            ({
              required q,
              required aba,
              required categoria,
              required ordenar,
              required pagina,
            }) => widget.api.catalogoLivelo(
              q: q,
              aba: aba,
              categoria: categoria,
              ordenar: ordenar,
              pagina: pagina,
              porPagina: _itensPorPagina,
              acompanhamentoPessoal: !widget.administrador,
            ),
        alterarAcompanhamento: ({required idExterno, required acompanhada}) =>
            widget.administrador
            ? widget.api.alterarAcompanhamentoLivelo(
                idExterno: idExterno,
                acompanhada: acompanhada,
              )
            : widget.api.alterarAcompanhamentoPessoalLivelo(
                idExterno: idExterno,
                ativo: acompanhada,
              ),
        alterarAlerta: ({required idExterno, required ativo}) =>
            widget.api.alterarAlertaLivelo(idExterno: idExterno, ativo: ativo),
      );
  late final bool _controladorExterno = widget.controlador != null;
  final _busca = TextEditingController();
  final _rolagem = ScrollController();
  Timer? _atualizacaoSilenciosa;
  bool _retratoAtualizando = false;
  int _versaoAcompanhamento = 0;
  int _tentativasAcompanhamento = 0;
  int _falhasConsecutivas = 0;

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
  }

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
    _encerrarAcompanhamento();
    if (!_controladorExterno) _controlador.dispose();
    super.dispose();
  }

  Future<void> _alternar(ParceiroCatalogoLivelo parceiro) async {
    final acompanhava = parceiro.acompanhada;
    final sucesso = await _controlador.alternarAcompanhamento(parceiro);
    if (!mounted) return;
    if (sucesso) {
      mostrarMensagemRadar(
        context,
        acompanhava
            ? 'Loja removida do acompanhamento.'
            : 'Loja adicionada ao acompanhamento.',
      );
      return;
    }
    mostrarMensagemRadar(
      context,
      'Não foi possível salvar. O estado anterior foi restaurado.',
      sucesso: false,
    );
  }

  Future<void> _abrirHistorico(ParceiroCatalogoLivelo parceiro) async {
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.9,
      builder: (_) =>
          PaginaHistoricoLiveloAndroid(api: widget.api, parceiro: parceiro),
    );
  }

  Future<void> _abrirDetalhes(ParceiroCatalogoLivelo parceiro) async {
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.9,
      builder: (contexto) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(contexto).height * 0.9,
        ),
        child: FolhaRadar(
          titulo: parceiro.nome,
          descricao: 'Condições da oferta',
          child: Flexible(
            child: SingleChildScrollView(
              child: _DetalhesParceiroLivelo(
                parceiro: parceiro,
                aoAbrirLivelo: () {
                  Navigator.of(contexto).pop();
                  unawaited(_confirmarAberturaLivelo(parceiro));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarAberturaLivelo(ParceiroCatalogoLivelo parceiro) async {
    final uri = Uri.tryParse(parceiro.link ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    final continuar = await mostrarFolhaRadar<bool>(
      context,
      alturaMaxima: 0.62,
      builder: (_) => FolhaRadar(
        titulo: 'Abrir Livelo?',
        descricao: '',
        child: Flexible(
          child: SingleChildScrollView(
            child: _ConfirmacaoAberturaLivelo(
              aoFicarAqui: () => Navigator.of(context).pop(false),
              aoContinuar: () => Navigator.of(context).pop(true),
            ),
          ),
        ),
      ),
    );
    if (continuar != true || !mounted) return;
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      mostrarMensagemRadar(
        context,
        'Não foi possível abrir o site da Livelo.',
        sucesso: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) {
      final tokens = context.tokens;
      return CustomScrollView(
        key: const Key('catalogo-livelo-android'),
        controller: _rolagem,
        slivers: [
          SliverSafeArea(
            top: true,
            bottom: false,
            sliver: SliverPadding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spacing.five,
                top: tokens.spacing.four,
                end: tokens.spacing.five,
                bottom: tokens.spacing.four,
              ),
              sliver: SliverToBoxAdapter(
                child: _CabecalhoCatalogoLivelo(
                  aoVoltar: widget.aoVoltar,
                  atualizar: BotaoDisparo(
                    key: const Key('atualizar-catalogo-livelo'),
                    api: widget.api,
                    dominio: 'livelo',
                    administrador: widget.administrador,
                    rotulo: 'Atualizar catálogo',
                    aoAceitar: _acompanharNovaColeta,
                    somenteIcone: true,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.spacing.five,
              end: tokens.spacing.five,
              bottom: tokens.spacing.four,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Lojas e pontos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.spacing.five,
              end: tokens.spacing.five,
              bottom: tokens.spacing.two,
            ),
            sliver: SliverToBoxAdapter(
              child: CampoBuscaRadar(
                key: const Key('busca-catalogo-livelo'),
                controlador: _busca,
                dica: 'Qual loja você procura?',
                aoMudar: _controlador.mudarBusca,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.five),
            sliver: SliverToBoxAdapter(
              child: AbasRadar(
                rotulos: const ['Lojas', 'No radar'],
                plana: true,
                selecionada: _abasVisiveis
                    .indexOf(_controlador.aba)
                    .clamp(0, 1),
                aoSelecionar: (indice) =>
                    _controlador.mudarAba(_abasVisiveis[indice]),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.spacing.five,
              top: tokens.spacing.one,
              end: tokens.spacing.five,
              bottom: tokens.spacing.three,
            ),
            sliver: SliverToBoxAdapter(
              child: _ResumoResultados(
                total: _controlador.totalItens,
                contexto: _contextoResultados,
                mostrarFiltro: _controlador.aba == AbaCatalogoLivelo.lojas,
                filtroAtivo:
                    _controlador.categoria.isNotEmpty ||
                    _controlador.ordenacao != OrdenacaoCatalogoLivelo.nome,
                aoFiltrar: _abrirFiltros,
              ),
            ),
          ),
          ..._corpo(),
          SliverToBoxAdapter(child: SizedBox(height: tokens.spacing.eight)),
        ],
      );
    },
  );

  String get _contextoResultados {
    if (_controlador.aba == AbaCatalogoLivelo.acompanhadas) {
      return 'Suas lojas favoritas';
    }
    if (_controlador.categoria.isNotEmpty) return _controlador.categoria;
    if (_controlador.busca.trim().isNotEmpty) return 'Busca no catálogo';
    return 'Catálogo completo';
  }

  void _acompanharNovaColeta() {
    _encerrarAcompanhamento();
    final versao = _versaoAcompanhamento;
    _tentativasAcompanhamento = 0;
    _falhasConsecutivas = 0;
    unawaited(_atualizarRetratoSilencioso(versao));
    _atualizacaoSilenciosa = Timer.periodic(_intervaloAcompanhamento, (_) {
      unawaited(_atualizarRetratoSilencioso(versao));
    });
  }

  Future<void> _atualizarRetratoSilencioso(int versao) async {
    if (_retratoAtualizando || versao != _versaoAcompanhamento) return;
    _retratoAtualizando = true;
    _tentativasAcompanhamento += 1;
    try {
      final resultado = await _controlador.atualizarSilenciosamente();
      if (!mounted || versao != _versaoAcompanhamento) return;
      switch (resultado) {
        case ResultadoAtualizacaoSilenciosa.alterada:
          _encerrarAcompanhamento();
          mostrarMensagemRadar(context, 'Atualização concluída.');
          break;
        case ResultadoAtualizacaoSilenciosa.degradada:
          _encerrarAcompanhamento();
          mostrarMensagemRadar(
            context,
            'Atualização com qualidade reduzida. '
            'Mantivemos a última coleta válida.',
            sucesso: false,
          );
          break;
        case ResultadoAtualizacaoSilenciosa.falha:
          _falhasConsecutivas += 1;
          if (_falhasConsecutivas >= _maximoFalhasConsecutivas) {
            _encerrarAcompanhamento();
            mostrarMensagemRadar(
              context,
              'Não foi possível acompanhar a atualização. '
              'Ela pode continuar em segundo plano.',
              sucesso: false,
            );
          }
          break;
        case ResultadoAtualizacaoSilenciosa.inalterada:
          _falhasConsecutivas = 0;
          break;
      }
      if (versao == _versaoAcompanhamento &&
          _tentativasAcompanhamento >= _maximoTentativasAcompanhamento) {
        _encerrarAcompanhamento();
        mostrarMensagemRadar(
          context,
          'A conclusão ainda não foi confirmada. '
          'A atualização pode continuar em segundo plano.',
          sucesso: false,
        );
      }
    } finally {
      _retratoAtualizando = false;
    }
  }

  void _encerrarAcompanhamento() {
    _atualizacaoSilenciosa?.cancel();
    _atualizacaoSilenciosa = null;
    _versaoAcompanhamento += 1;
  }

  Future<void> _abrirFiltros() async {
    var ordenacao = _controlador.ordenacao;
    var categoria = _controlador.categoria;
    await mostrarFolhaRadar<void>(
      context,
      builder: (contexto) => StatefulBuilder(
        builder: (contexto, atualizar) => FolhaRadar(
          titulo: 'Filtrar todas as lojas',
          descricao: 'Refine o catálogo completo da Livelo.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('categoria-filtro-livelo'),
                initialValue: categoria,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoria'),
                onChanged: (valor) {
                  if (valor != null) atualizar(() => categoria = valor);
                },
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas as categorias'),
                  ),
                  for (final valor in _controlador.categorias)
                    DropdownMenuItem(value: valor, child: Text(valor)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OrdenacaoCatalogoLivelo>(
                key: const Key('ordenacao-filtro-livelo'),
                initialValue: ordenacao,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ordenar por'),
                onChanged: (valor) {
                  if (valor != null) atualizar(() => ordenacao = valor);
                },
                items: [
                  for (final valor in OrdenacaoCatalogoLivelo.values)
                    DropdownMenuItem(value: valor, child: Text(valor.rotulo)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(contexto).pop();
                        unawaited(
                          _controlador.aplicarFiltros(
                            categoria: '',
                            ordenacao: OrdenacaoCatalogoLivelo.nome,
                          ),
                        );
                      },
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(contexto).pop();
                        unawaited(
                          _controlador.aplicarFiltros(
                            categoria: categoria,
                            ordenacao: ordenacao,
                          ),
                        );
                      },
                      child: const Text('Ver lojas'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _corpo() {
    if (_controlador.carregandoInicial) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Carregando(mensagem: 'Carregando catálogo Livelo…'),
          ),
        ),
      ];
    }
    if (_controlador.erroInicial != null) {
      return [
        SliverToBoxAdapter(
          child: EstadoFalha(
            mensagem: 'Não foi possível carregar o catálogo Livelo.',
            voltar: _controlador.tentarNovamente,
          ),
        ),
      ];
    }
    final resumo = _controlador.resumo;
    if (resumo == null || resumo.ultimaColeta == null) {
      return const [
        SliverToBoxAdapter(
          child: EstadoVazio(
            mensagem: 'O catálogo Livelo ainda não foi sincronizado.',
          ),
        ),
      ];
    }
    if (_controlador.totalItens == 0) {
      final mensagem = switch (_controlador.aba) {
        AbaCatalogoLivelo.acompanhadas =>
          'Nenhuma loja está acompanhada. Escolha uma na aba Lojas.',
        AbaCatalogoLivelo.alertas =>
          'Nenhuma loja acompanhada cruzou a régua na última coleta.',
        AbaCatalogoLivelo.lojas =>
          _controlador.busca.trim().isNotEmpty ||
                  _controlador.categoria.isNotEmpty
              ? 'Nenhuma loja corresponde aos filtros atuais.'
              : 'A última coleta não publicou parceiros válidos.',
      };
      return [SliverToBoxAdapter(child: EstadoVazio(mensagem: mensagem))];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: _controlador.itens.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, indice) {
            final parceiro = _controlador.itens[indice];
            return CartaoCatalogoLivelo(
              parceiro: parceiro,
              pendente: _controlador.mutacoesPendentes.contains(
                parceiro.idExterno,
              ),
              podeAdministrar: widget.administrador,
              podeAcompanhar: true,
              atualizadoEm: resumo.ultimaColeta,
              aoAlternar: () => _alternar(parceiro),
              aoDetalhes: () => _abrirDetalhes(parceiro),
              aoHistorico: () => _abrirHistorico(parceiro),
              aoAbrirLivelo: () => _confirmarAberturaLivelo(parceiro),
            );
          },
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(child: _paginacao()),
      ),
    ];
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
}

class _CabecalhoCatalogoLivelo extends StatelessWidget {
  const _CabecalhoCatalogoLivelo({
    required this.aoVoltar,
    required this.atualizar,
  });

  final VoidCallback? aoVoltar;
  final Widget atualizar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          key: const Key('voltar-programas-livelo'),
          tooltip: 'Voltar para Explorar',
          onPressed: aoVoltar ?? () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        SizedBox(width: tokens.spacing.two),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Livelo', style: tema.textTheme.titleMedium),
              Text(
                'Catálogo',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
                ),
              ),
            ],
          ),
        ),
        atualizar,
      ],
    );
  }
}

class _ResumoResultados extends StatelessWidget {
  const _ResumoResultados({
    required this.total,
    required this.contexto,
    required this.mostrarFiltro,
    required this.filtroAtivo,
    required this.aoFiltrar,
  });

  final int total;
  final String contexto;
  final bool mostrarFiltro;
  final bool filtroAtivo;
  final VoidCallback aoFiltrar;

  @override
  Widget build(BuildContext context) {
    final resumo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$total ${total == 1 ? 'loja' : 'lojas'}',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (contexto != 'Catálogo completo') ...[
          const SizedBox(height: 3),
          Text(
            contexto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
    final botao = OutlinedButton.icon(
      key: const Key('filtrar-ordenar-livelo'),
      onPressed: aoFiltrar,
      style: OutlinedButton.styleFrom(
        foregroundColor: filtroAtivo
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Tokens.acaoForteEscura
                  : Tokens.actionStrong)
            : null,
        backgroundColor: filtroAtivo
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Tokens.acaoFundoEscuro
                  : Tokens.actionSoft)
            : null,
        side: filtroAtivo
            ? BorderSide(
                color: CoresRadar.de(context).acao.withValues(alpha: 0.48),
              )
            : null,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      icon: Icon(
        Icons.filter_list_rounded,
        size: 17,
        color: Theme.of(context).brightness == Brightness.dark
            ? Tokens.acaoForteEscura
            : Tokens.actionStrong,
      ),
      label: const Text('Filtros'),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 2, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CoresRadar.de(context).borda.withValues(alpha: 0.76),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, limites) {
          if (!mostrarFiltro) return resumo;
          final estreito =
              limites.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(10) > 12;
          if (estreito) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                resumo,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: botao),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: resumo),
              const SizedBox(width: 12),
              botao,
            ],
          );
        },
      ),
    );
  }
}

class _DetalhesParceiroLivelo extends StatelessWidget {
  const _DetalhesParceiroLivelo({
    required this.parceiro,
    required this.aoAbrirLivelo,
  });

  final ParceiroCatalogoLivelo parceiro;
  final VoidCallback aoAbrirLivelo;

  @override
  Widget build(BuildContext context) {
    final campanha = parceiro.campanha?.trim();
    final tokens = context.tokens;
    final cores = tokens.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Condições da oferta',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        SizedBox(height: tokens.spacing.two),
        Text(
          parceiro.descricaoCampanha?.trim().isNotEmpty == true
              ? parceiro.descricaoCampanha!.trim()
              : 'Confira produtos participantes, cupons elegíveis e prazo de crédito no regulamento da campanha.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: cores.textoSuave,
            height: 1.45,
          ),
        ),
        SizedBox(height: tokens.spacing.three),
        _LinhaDetalheLivelo(
          rotulo: 'Pontuação comum',
          valor: pontosLivelo(parceiro.pontosAtuais, moeda: parceiro.moeda),
        ),
        if (parceiro.pontosClube != null)
          _LinhaDetalheLivelo(
            rotulo: 'Clube Livelo',
            valor: pontosLivelo(parceiro.pontosClube, moeda: parceiro.moeda),
          ),
        if (parceiro.fimPromocao != null)
          _LinhaDetalheLivelo(
            rotulo: 'Validade',
            valor: validadeLivelo(parceiro.fimPromocao),
          ),
        if (campanha != null && campanha.isNotEmpty)
          _LinhaDetalheLivelo(rotulo: 'Campanha', valor: campanha),
        SizedBox(height: tokens.spacing.four),
        FilledButton.icon(
          key: Key('abrir-livelo-${parceiro.idExterno}'),
          onPressed: _linkHttpsValido(parceiro.link) ? aoAbrirLivelo : null,
          style: FilledButton.styleFrom(
            minimumSize: Size(0, tokens.sizes.touchTarget),
            backgroundColor: cores.acao,
            foregroundColor: cores.marcaTexto,
          ),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Abrir Livelo'),
        ),
      ],
    );
  }
}

class _ConfirmacaoAberturaLivelo extends StatelessWidget {
  const _ConfirmacaoAberturaLivelo({
    required this.aoFicarAqui,
    required this.aoContinuar,
  });

  final VoidCallback aoFicarAqui;
  final VoidCallback aoContinuar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = tokens.colors;
    final botoes = [
      Expanded(
        child: OutlinedButton(
          key: const Key('ficar-aqui-livelo'),
          onPressed: aoFicarAqui,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(0, tokens.sizes.touchTarget),
          ),
          child: const Text('Ficar aqui'),
        ),
      ),
      SizedBox(width: tokens.spacing.two),
      Expanded(
        child: FilledButton.icon(
          key: const Key('continuar-livelo'),
          onPressed: aoContinuar,
          style: FilledButton.styleFrom(
            minimumSize: Size(0, tokens.sizes.touchTarget),
            backgroundColor: cores.acao,
            foregroundColor: cores.marcaTexto,
          ),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Continuar'),
        ),
      ),
    ];
    return LayoutBuilder(
      builder: (context, limites) {
        final estreito = limites.maxWidth < 320;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Você será levado ao site oficial para conferir preços e condições.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: cores.textoSuave,
                height: 1.45,
              ),
            ),
            SizedBox(height: tokens.spacing.five),
            Text(
              'Os itens desta demonstração são ilustrativos. O link abre o portal da origem, sem simular uma oferta real.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cores.textoSuave,
                height: 1.45,
              ),
            ),
            SizedBox(height: tokens.spacing.five),
            if (estreito)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  botoes[0],
                  SizedBox(height: tokens.spacing.two),
                  botoes[2],
                ],
              )
            else
              Row(children: botoes),
          ],
        );
      },
    );
  }
}

bool _linkHttpsValido(String? link) {
  final uri = Uri.tryParse(link ?? '');
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

class _LinhaDetalheLivelo extends StatelessWidget {
  const _LinhaDetalheLivelo({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: CoresRadar.de(context).borda)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            rotulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
