import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/navegacao/destinos.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';
import 'controlador_alertas.dart';
import 'formatacao_alertas.dart';
import 'gerenciador_notificacoes.dart';
import 'modelo_item_alerta.dart';
import 'pagina_detalhe_alerta.dart';

class PaginaAlertas extends StatefulWidget {
  const PaginaAlertas({
    super.key,
    required this.api,
    this.coletaInicial,
    this.destinoSelecionado = DestinoCompacto.inicio,
    this.aoNavegar,
    this.aoAbrirItem,
    this.solicitarPermissaoNotificacoes,
  });

  final Api api;
  final String? coletaInicial;
  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;
  final ValueChanged<AlertaApp>? aoAbrirItem;
  final Future<AuthorizationStatus?> Function()? solicitarPermissaoNotificacoes;

  @override
  State<PaginaAlertas> createState() => _EstadoPaginaAlertas();
}

class _EstadoPaginaAlertas extends State<PaginaAlertas> {
  late final ControladorAlertas _controlador = ControladorAlertas(
    api: widget.api,
    coletaInicial: widget.coletaInicial,
  );
  final Set<String> _itensAbrindo = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_controlador.iniciar());
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _preferencias() {
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaginaPreferenciasAlertas(
          api: widget.api,
          destinoSelecionado: widget.destinoSelecionado,
          aoNavegar: widget.aoNavegar,
          solicitarPermissaoNotificacoes: widget.solicitarPermissaoNotificacoes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compacto = MediaQuery.sizeOf(context).width < 920;
    return PopScope<void>(
      canPop: true,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _controlador,
          builder: (context, _) => _conteudo(),
        ),
        bottomNavigationBar: compacto
            ? BarraInferiorRadar(
                selecionado: widget.destinoSelecionado,
                aoSelecionar: (destino) {
                  if (widget.aoNavegar != null) {
                    widget.aoNavegar!(destino);
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _conteudo() {
    final tokens = context.tokens;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _controlador.carregar,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spacing.four,
                tokens.spacing.five,
                tokens.spacing.four,
                tokens.spacing.two,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      key: const Key('voltar-alertas'),
                      tooltip: 'Voltar',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    SizedBox(width: tokens.spacing.one),
                    Expanded(
                      child: Text(
                        'Mudou. Você viu.',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: CoresRadar.de(context).superficieAlternativa,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        key: const Key('preferencias-alertas'),
                        tooltip: 'Preferências de alertas',
                        icon: const Icon(Icons.tune_rounded),
                        onPressed: _preferencias,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spacing.four,
                end: tokens.spacing.four,
                bottom: tokens.spacing.two,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Mudanças nos itens que você acompanha.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CoresRadar.de(context).textoSuave,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.four),
              sliver: SliverToBoxAdapter(
                child: AbasRadar(
                  key: const Key('abas-alertas'),
                  rotulos: const ['Todos', 'Não lidos'],
                  selecionada: _controlador.aba == 'nao_lidos' ? 1 : 0,
                  plana: true,
                  aoSelecionar: (indice) => unawaited(
                    _controlador.mudarAba(indice == 1 ? 'nao_lidos' : 'todos'),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spacing.four,
                tokens.spacing.two,
                tokens.spacing.four,
                tokens.spacing.two,
              ),
              sliver: SliverToBoxAdapter(child: _linhaFiltro()),
            ),
            SliverPadding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spacing.four,
                end: tokens.spacing.four,
                bottom: tokens.spacing.one,
              ),
              sliver: SliverToBoxAdapter(child: _marcarTodos()),
            ),
            ..._corpo(),
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spacing.four,
                tokens.spacing.two,
                tokens.spacing.four,
                tokens.spacing.eight,
              ),
              sliver: SliverToBoxAdapter(
                child: PaginacaoRadar(
                  pagina: _controlador.pagina,
                  totalItens: _controlador.totalItens,
                  porPagina: _controlador.porPagina,
                  carregando: _controlador.carregando,
                  erro: _controlador.erro,
                  aoIrParaPagina: _controlador.irParaPagina,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaFiltro() {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Últimos 90 dias',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
            ),
          ),
        ),
        OutlinedButton.icon(
          key: const Key('filtrar-alertas'),
          onPressed: _abrirFiltros,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Filtrar'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: tokens.spacing.three),
          ),
        ),
      ],
    );
  }

  Widget _marcarTodos() => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton(
      key: const Key('marcar-todos-alertas'),
      onPressed: _controlador.itens.any((item) => !item.lido)
          ? _marcarTodosComoLidos
          : null,
      child: const Text('Marcar todos como lidos'),
    ),
  );

  Future<void> _marcarTodosComoLidos() async {
    try {
      await _controlador.marcarTodos();
      if (mounted) {
        mostrarMensagemRadar(context, 'Todos os alertas foram lidos.');
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagemRadar(
          context,
          'Não foi possível marcar os alertas.',
          sucesso: false,
        );
      }
    }
  }

  Future<void> _abrirItem(AlertaApp alerta) async {
    if (_itensAbrindo.contains(alerta.id)) return;
    setState(() => _itensAbrindo.add(alerta.id));
    try {
      final alertaAtual = _controlador.itens.firstWhere(
        (item) => item.id == alerta.id,
        orElse: () => alerta,
      );
      if (!alertaAtual.lido) {
        try {
          await _controlador.marcar(alertaAtual);
        } catch (_) {
          if (mounted) {
            mostrarMensagemRadar(
              context,
              'Não foi possível marcar como lido.',
              sucesso: false,
            );
          }
        }
      }

      final resposta = await widget.api.resolverItemAlerta(alertaId: alerta.id);
      final detalhe = ItemResolvidoAlerta.parse(resposta);
      if (!mounted) return;
      final aoNavegarDoDetalhe = widget.aoNavegar == null
          ? null
          : (DestinoCompacto destino) {
              Navigator.of(context, rootNavigator: true).pop();
              widget.aoNavegar!(destino);
            };
      unawaited(
        Navigator.of(context, rootNavigator: true).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PaginaDetalheAlerta(
              api: widget.api,
              detalhe: detalhe,
              destinoSelecionado: widget.destinoSelecionado,
              aoNavegar: aoNavegarDoDetalhe,
            ),
          ),
        ),
      );
    } on ErroDeApi catch (erro) {
      if (!mounted) return;
      if (erro.status == 404) {
        final fallback = widget.aoAbrirItem;
        if (fallback != null) {
          fallback(alerta);
        } else {
          mostrarMensagemRadar(
            context,
            'Este item não está mais disponível.',
            sucesso: false,
          );
        }
        return;
      }
      _mostrarFalhaAoAbrir(alerta);
    } catch (_) {
      if (mounted) _mostrarFalhaAoAbrir(alerta);
    } finally {
      if (mounted) setState(() => _itensAbrindo.remove(alerta.id));
    }
  }

  void _mostrarFalhaAoAbrir(AlertaApp alerta) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Não foi possível abrir o item agora.'),
          action: SnackBarAction(
            label: 'Tentar novamente',
            onPressed: () => unawaited(_abrirItem(alerta)),
          ),
        ),
      );
  }

  Future<void> _abrirFiltros() async {
    final filtros = await mostrarFolhaRadar<_FiltrosAlertasResultado>(
      context,
      alturaMaxima: 0.68,
      builder: (_) => _FolhaFiltrosAlertas(
        origemInicial: _controlador.filtroOrigem,
        tipoInicial: _controlador.filtroTipo,
      ),
    );
    if (!mounted || filtros == null) return;
    await _controlador.aplicarFiltros(
      origem: filtros.origem,
      tipo: filtros.tipo,
    );
  }

  List<Widget> _corpo() {
    if (_controlador.carregando && _controlador.itens.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Carregando(mensagem: 'Carregando alertas…'),
        ),
      ];
    }
    if (_controlador.erro != null && _controlador.itens.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoFalha(
            mensagem: _controlador.erro is ErroDeRede
                ? 'Sem conexão. A Central precisa de internet para atualizar.'
                : 'Não foi possível carregar a Central agora.',
            voltar: _controlador.carregar,
          ),
        ),
      ];
    }
    if (_controlador.itens.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoVazio(
            mensagem: 'Nenhum alerta corresponde a este filtro.',
          ),
        ),
      ];
    }
    final tokens = context.tokens;
    return [
      if (_controlador.parcial)
        SliverPadding(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spacing.four,
            0,
            tokens.spacing.four,
            tokens.spacing.three,
          ),
          sliver: SliverToBoxAdapter(
            child: _aviso(
              'A atualização foi parcial; o último resultado válido continua visível.',
              TomRadar.atencao,
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.four),
        sliver: SliverList.separated(
          itemCount: _controlador.itens.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            thickness: 1,
            color: CoresRadar.de(context).borda,
          ),
          itemBuilder: (context, indice) => _CartaoAlerta(
            alerta: _controlador.itens[indice],
            abrindo: _itensAbrindo.contains(_controlador.itens[indice].id),
            aoAbrir: () => unawaited(_abrirItem(_controlador.itens[indice])),
            aoMarcar: () async {
              try {
                await _controlador.marcar(_controlador.itens[indice]);
              } catch (_) {
                if (!mounted) return;
                mostrarMensagemRadar(
                  this.context,
                  'Não foi possível atualizar a leitura.',
                  sucesso: false,
                );
              }
            },
          ),
        ),
      ),
    ];
  }

  Widget _aviso(String mensagem, TomRadar tom) => DecoratedBox(
    decoration: BoxDecoration(
      color: tom == TomRadar.atencao
          ? Tokens.atencaoFundo
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(context.tokens.radii.md),
    ),
    child: Padding(
      padding: EdgeInsets.all(context.tokens.spacing.three),
      child: Text(
        mensagem,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: CoresRadar.de(context).atencao),
      ),
    ),
  );
}

class _CartaoAlerta extends StatelessWidget {
  const _CartaoAlerta({
    required this.alerta,
    required this.aoMarcar,
    required this.abrindo,
    this.aoAbrir,
  });
  final AlertaApp alerta;
  final VoidCallback aoMarcar;
  final bool abrindo;
  final VoidCallback? aoAbrir;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final valorAnterior = alerta.valorAnterior == null
        ? null
        : _valorAlerta(alerta.valorAnterior!, alerta.tipo, alerta.unidade);
    final valorAtual = _valorAlerta(
      alerta.valorAtual,
      alerta.tipo,
      alerta.unidade,
    );
    return Semantics(
      container: true,
      label: '${_tituloAlerta(alerta)}: ${alerta.entidadeNome}',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.five),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: tokens.spacing.two),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: alerta.lido ? Colors.transparent : cores.acao,
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(dimension: tokens.spacing.one),
              ),
            ),
            SizedBox(width: tokens.spacing.three),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_rotuloOrigem(alerta.origem)} · ${_rotuloData(alerta.criadoEm)}',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: cores.textoSuave),
                  ),
                  SizedBox(height: tokens.spacing.two),
                  Text(
                    _tituloAlerta(alerta),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.one),
                  Text(
                    alerta.entidadeNome,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                  ),
                  SizedBox(height: tokens.spacing.three),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: tokens.spacing.two,
                    children: [
                      if (valorAnterior != null)
                        Text(
                          valorAnterior,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: cores.textoSuave,
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                      Icon(
                        Icons.arrow_forward,
                        size: tokens.spacing.four,
                        color: cores.textoSuave,
                      ),
                      Text(
                        valorAtual,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: cores.ganho,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spacing.one),
                  Wrap(
                    spacing: tokens.spacing.two,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: abrindo ? null : aoAbrir,
                        child: Text(abrindo ? 'Abrindo…' : 'Ver item'),
                      ),
                      if (alerta.lido)
                        Text(
                          'Lido',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: cores.textoSuave),
                        )
                      else
                        TextButton(
                          onPressed: aoMarcar,
                          child: const Text('Marcar lido'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolhaFiltrosAlertas extends StatefulWidget {
  const _FolhaFiltrosAlertas({
    required this.origemInicial,
    required this.tipoInicial,
  });

  final String? origemInicial;
  final String tipoInicial;

  @override
  State<_FolhaFiltrosAlertas> createState() => _EstadoFolhaFiltrosAlertas();
}

class _EstadoFolhaFiltrosAlertas extends State<_FolhaFiltrosAlertas> {
  late String _origem = widget.origemInicial ?? 'todos';
  late String _tipo = widget.tipoInicial;

  @override
  Widget build(BuildContext context) => FolhaRadar(
    titulo: 'Filtrar mudanças',
    descricao: '',
    mostrarVoltar: false,
    child: Flexible(
      child: ListView(
        shrinkWrap: true,
        children: [
          const Text('Origem'),
          SizedBox(height: context.tokens.spacing.one),
          DropdownButtonFormField<String>(
            key: const Key('origem-alertas'),
            initialValue: _origem,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'todos', child: Text('Todas as origens')),
              DropdownMenuItem(
                value: 'inter_cashback',
                child: Text('Sites parceiros'),
              ),
              DropdownMenuItem(
                value: 'inter_produto',
                child: Text('Compre direto'),
              ),
              DropdownMenuItem(value: 'livelo', child: Text('Livelo')),
              DropdownMenuItem(value: 'pichau', child: Text('Pichau')),
            ],
            onChanged: (valor) {
              if (valor != null) setState(() => _origem = valor);
            },
          ),
          SizedBox(height: context.tokens.spacing.four),
          const Text('Tipo de mudança'),
          SizedBox(height: context.tokens.spacing.one),
          DropdownButtonFormField<String>(
            key: const Key('tipo-alertas'),
            initialValue: _tipo,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 'todos', child: Text('Todos')),
              DropdownMenuItem(value: 'preco', child: Text('Preço')),
              DropdownMenuItem(value: 'cashback', child: Text('Cashback')),
              DropdownMenuItem(value: 'pontuacao', child: Text('Pontos')),
            ],
            onChanged: (valor) {
              if (valor != null) setState(() => _tipo = valor);
            },
          ),
          SizedBox(height: context.tokens.spacing.four),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('aplicar-filtros-alertas'),
              onPressed: () => Navigator.of(context).pop(
                _FiltrosAlertasResultado(
                  origem: _origem == 'todos' ? null : _origem,
                  tipo: _tipo,
                ),
              ),
              child: const Text('Aplicar'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FiltrosAlertasResultado {
  const _FiltrosAlertasResultado({required this.origem, required this.tipo});

  final String? origem;
  final String tipo;
}

class PaginaPreferenciasAlertas extends StatefulWidget {
  const PaginaPreferenciasAlertas({
    super.key,
    required this.api,
    required this.destinoSelecionado,
    this.aoNavegar,
    this.solicitarPermissaoNotificacoes,
  });

  final Api api;
  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;
  final Future<AuthorizationStatus?> Function()? solicitarPermissaoNotificacoes;

  @override
  State<PaginaPreferenciasAlertas> createState() =>
      _EstadoPaginaPreferenciasAlertas();
}

class _EstadoPaginaPreferenciasAlertas
    extends State<PaginaPreferenciasAlertas> {
  PreferenciasAlertas? _valor;
  var _carregando = true;
  var _erroAoCarregar = false;
  var _salvando = false;

  @override
  void initState() {
    super.initState();
    unawaited(_carregar());
  }

  Future<void> _carregar() async {
    if (_carregando && _valor != null) return;
    setState(() {
      _carregando = true;
      _erroAoCarregar = false;
    });
    try {
      final preferencias = await widget.api.preferenciasAlertas();
      if (mounted) setState(() => _valor = preferencias);
    } catch (_) {
      if (mounted) setState(() => _erroAoCarregar = true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _alternar(
    PreferenciasAlertas Function(PreferenciasAlertas) propor,
  ) async {
    final confirmado = _valor;
    if (confirmado == null || _salvando) return;
    final proposto = propor(confirmado);
    setState(() {
      _valor = proposto;
      _salvando = true;
    });
    try {
      final salvo = await widget.api.salvarPreferenciasAlertas(proposto);
      if (mounted) setState(() => _valor = salvo);
    } catch (_) {
      if (!mounted) return;
      setState(() => _valor = confirmado);
      mostrarMensagemRadar(
        context,
        'Não foi possível salvar as preferências.',
        sucesso: false,
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _abrirPermissao() => mostrarFolhaRadar<void>(
    context,
    alturaMaxima: 0.82,
    builder: (_) => _FolhaPermissaoAlertas(
      api: widget.api,
      solicitarPermissao: widget.solicitarPermissaoNotificacoes,
    ),
  );

  void _navegar(DestinoCompacto destino) {
    if (widget.aoNavegar == null) {
      Navigator.of(context).maybePop();
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();
    widget.aoNavegar!(destino);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final compacto = MediaQuery.sizeOf(context).width < 920;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        leading: IconButton(
          key: const Key('voltar-notificacoes-alertas'),
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: _carregando
          ? const Carregando(mensagem: 'Carregando preferências…')
          : _erroAoCarregar || _valor == null
          ? EstadoFalha(
              mensagem: 'Não foi possível carregar as preferências agora.',
              voltar: _carregar,
            )
          : SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: ListView(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      tokens.spacing.five,
                      tokens.spacing.seven,
                      tokens.spacing.five,
                      tokens.spacing.six,
                    ),
                    children: [
                      Text(
                        'Só o que importa.',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: tokens.spacing.three),
                      Text(
                        'A Central continua disponível mesmo sem notificações no aparelho.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CoresRadar.de(context).textoSuave,
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: tokens.spacing.six),
                      _linhaPreferencia(
                        titulo: 'Notificações no aparelho',
                        descricao: 'Receber avisos de novas mudanças.',
                        chave: 'preferencia-push-global',
                        valor: _valor!.pushGlobal,
                        alterar: (valor) => _alternar(
                          (atual) => atual.copiarCom(pushGlobal: valor),
                        ),
                      ),
                      _linhaPreferencia(
                        titulo: 'Preço',
                        descricao: 'Aumento ou redução do preço.',
                        chave: 'preferencia-preco',
                        valor: _valor!.preco,
                        alterar: (valor) =>
                            _alternar((atual) => atual.copiarCom(preco: valor)),
                      ),
                      _linhaPreferencia(
                        titulo: 'Cashback',
                        descricao: 'Mudanças no benefício publicado.',
                        chave: 'preferencia-cashback',
                        valor: _valor!.cashback,
                        alterar: (valor) => _alternar(
                          (atual) => atual.copiarCom(cashback: valor),
                        ),
                      ),
                      _linhaPreferencia(
                        titulo: 'Pontos',
                        descricao: 'Mudanças na pontuação comum.',
                        chave: 'preferencia-pontuacao',
                        valor: _valor!.pontuacao,
                        alterar: (valor) => _alternar(
                          (atual) => atual.copiarCom(pontuacao: valor),
                        ),
                      ),
                      SizedBox(height: tokens.spacing.four),
                      OutlinedButton.icon(
                        key: const Key('permissao-notificacoes-alertas'),
                        onPressed: _abrirPermissao,
                        icon: const Icon(Icons.notifications_active_outlined),
                        label: const Text('Rever permissão do aparelho'),
                      ),
                      SizedBox(height: tokens.spacing.five),
                      Text(
                        'Acompanhar um item e permitir notificações são escolhas separadas.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CoresRadar.de(context).textoSuave,
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: compacto
          ? BarraInferiorRadar(
              selecionado: widget.destinoSelecionado,
              aoSelecionar: _navegar,
            )
          : null,
    );
  }

  Widget _linhaPreferencia({
    required String titulo,
    required String descricao,
    required String chave,
    required bool valor,
    required ValueChanged<bool> alterar,
  }) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    final habilitado = !_salvando;
    void alternar() {
      if (habilitado) alterar(!valor);
    }

    return Column(
      children: [
        Semantics(
          key: Key(chave),
          label: titulo,
          hint: descricao,
          value: valor ? 'Ativado' : 'Desativado',
          toggled: valor,
          enabled: habilitado,
          onTap: habilitado ? alternar : null,
          child: ExcludeSemantics(
            child: InkWell(
              excludeFromSemantics: true,
              onTap: habilitado ? alternar : null,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spacing.four),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: tokens.spacing.one),
                          Text(
                            descricao,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: cores.textoSuave),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: tokens.spacing.four),
                    Switch(
                      value: valor,
                      onChanged: habilitado ? alterar : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: cores.borda),
      ],
    );
  }
}

class _FolhaPermissaoAlertas extends StatefulWidget {
  const _FolhaPermissaoAlertas({required this.api, this.solicitarPermissao});

  final Api api;
  final Future<AuthorizationStatus?> Function()? solicitarPermissao;

  @override
  State<_FolhaPermissaoAlertas> createState() => _EstadoFolhaPermissaoAlertas();
}

class _EstadoFolhaPermissaoAlertas extends State<_FolhaPermissaoAlertas> {
  late final GerenciadorNotificacoes _gerenciador = GerenciadorNotificacoes(
    api: widget.api,
    aoAbrirCentral: (_) {},
  );
  var _ocupado = false;
  String? _resultado;

  Future<void> _permitir() async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _resultado = null;
    });
    final solicitar =
        widget.solicitarPermissao ?? _gerenciador.solicitarPermissao;
    final status = await solicitar();
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _resultado = _mensagemStatus(status);
    });
  }

  String _mensagemStatus(AuthorizationStatus? status) => switch (status) {
    AuthorizationStatus.authorized =>
      'Permissão concedida. Você pode revisar as preferências na Central de Alertas.',
    AuthorizationStatus.provisional =>
      'Permissão provisória concedida. A Central continua disponível.',
    AuthorizationStatus.denied =>
      'Notificações não foram permitidas. A Central de Alertas continua disponível.',
    AuthorizationStatus.notDetermined =>
      'A decisão ficou pendente. Você pode tentar novamente quando quiser.',
    null => 'Não foi possível acessar a permissão neste dispositivo agora.',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    final textoEscalado = MediaQuery.textScalerOf(context).scale(14) >= 24;
    final agoraNao = OutlinedButton(
      key: const Key('agora-nao-permissao-alertas'),
      onPressed: _ocupado ? null : () => Navigator.of(context).maybePop(),
      child: const Text('Agora não'),
    );
    final permitir = FilledButton(
      key: const Key('permitir-permissao-alertas'),
      onPressed: _ocupado ? null : _permitir,
      child: Text(_ocupado ? 'Abrindo pedido…' : 'Permitir'),
    );

    return FolhaRadar(
      titulo: 'Mudou. Te avisamos.',
      descricao: '',
      mostrarVoltar: false,
      child: Flexible(
        child: ListView(
          shrinkWrap: true,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens.radii.md),
              child: ExcludeSemantics(
                child: Image.asset(
                  'assets/illustrations/acompanhamentos.png',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, 0.1),
                ),
              ),
            ),
            SizedBox(height: tokens.spacing.four),
            Text(
              'Receba avisos sobre os itens que você acompanha. A Central funciona mesmo se você preferir não receber.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cores.textoSuave,
                height: 1.6,
              ),
            ),
            SizedBox(height: tokens.spacing.two),
            Text(
              'Você pode rever essa escolha nas preferências da Central de Alertas. Negar o push não impede o acesso ao histórico.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
            ),
            SizedBox(height: tokens.spacing.four),
            if (textoEscalado)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  agoraNao,
                  SizedBox(height: tokens.spacing.three),
                  permitir,
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: agoraNao),
                  SizedBox(width: tokens.spacing.three),
                  Expanded(child: permitir),
                ],
              ),
            if (_resultado != null) ...[
              SizedBox(height: tokens.spacing.four),
              Text(
                _resultado!,
                key: const Key('resultado-permissao-alertas'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _tituloAlerta(AlertaApp alerta) => switch (alerta.tipo) {
  TipoAlertaApp.preco =>
    alerta.origem == 'pichau'
        ? alerta.direcao == 'reducao'
              ? 'O preço Pix caiu'
              : 'O preço Pix subiu'
        : alerta.direcao == 'reducao'
        ? 'O preço caiu'
        : 'O preço subiu',
  TipoAlertaApp.cashback =>
    alerta.direcao == 'reducao' ? 'O cashback diminuiu' : 'O cashback aumentou',
  TipoAlertaApp.pontuacao =>
    alerta.direcao == 'reducao'
        ? 'Menos pontos na loja'
        : 'Mais pontos na loja',
};

String _valorAlerta(String valor, TipoAlertaApp tipo, String unidade) {
  if (tipo == TipoAlertaApp.preco) return formatarValorAlerta(valor, tipo);
  final compacto = _compactarNumero(valor);
  return switch (unidade) {
    'pontos_por_real' => '$compacto pts/R\$ 1',
    'percentual' => '$compacto%',
    _ => [compacto, unidade].where((item) => item.isNotEmpty).join(' '),
  };
}

String _compactarNumero(String valor) {
  final entrada = valor.trim();
  final partes = RegExp(r'^(-?)(\d+)(?:\.(\d+))?$').firstMatch(entrada);
  if (partes == null) return valor;
  final sinal = partes.group(1)!;
  final inteiro = partes.group(2)!;
  final fracao = (partes.group(3) ?? '').replaceFirst(RegExp(r'0+$'), '');
  return '$sinal$inteiro${fracao.isEmpty ? '' : ',$fracao'}';
}

String _rotuloData(String valor) {
  final data = DateTime.tryParse(valor)?.toLocal();
  if (data == null) return valor;
  final agora = DateTime.now();
  final hoje =
      data.year == agora.year &&
      data.month == agora.month &&
      data.day == agora.day;
  final hora =
      '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  if (hoje) return 'Hoje, $hora';
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes, $hora';
}

String _rotuloOrigem(String origem) => switch (origem) {
  'livelo' => 'Livelo',
  'inter_cashback' => 'Sites parceiros',
  'inter_produto' => 'Compre direto',
  'pichau' => 'Pichau',
  _ => origem,
};
