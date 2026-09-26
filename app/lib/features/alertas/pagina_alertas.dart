import 'dart:async';

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
import 'pagina_permissao_notificacoes.dart';

class PaginaAlertas extends StatefulWidget {
  const PaginaAlertas({
    super.key,
    required this.api,
    this.coletaInicial,
    this.aoNavegar,
    this.aoAbrirItem,
  });

  final Api api;
  final String? coletaInicial;
  final ValueChanged<DestinoCompacto>? aoNavegar;
  final ValueChanged<AlertaApp>? aoAbrirItem;

  @override
  State<PaginaAlertas> createState() => _EstadoPaginaAlertas();
}

class _EstadoPaginaAlertas extends State<PaginaAlertas> {
  late final ControladorAlertas _controlador = ControladorAlertas(
    api: widget.api,
    coletaInicial: widget.coletaInicial,
  );

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

  Future<void> _preferencias() async {
    late final PreferenciasAlertas preferencias;
    try {
      preferencias = await widget.api.preferenciasAlertas();
    } catch (_) {
      if (!mounted) return;
      mostrarMensagemRadar(
        context,
        'Não foi possível carregar as preferências agora.',
        sucesso: false,
      );
      return;
    }
    if (!mounted) return;
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.78,
      builder: (_) =>
          _FolhaPreferenciasAlertas(api: widget.api, iniciais: preferencias),
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
            ? _BarraInferiorAlertas(
                aoSelecionar: (destino) {
                  if (widget.aoNavegar != null) {
                    widget.aoNavegar!(destino);
                  } else if (destino == DestinoCompacto.inicio) {
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
                  selecionada: _controlador.filtro == 'nao_lidos' ? 1 : 0,
                  plana: true,
                  aoSelecionar: (indice) => unawaited(
                    _controlador.mudarFiltro(
                      indice == 1 ? 'nao_lidos' : 'todos',
                    ),
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

  Future<void> _abrirFiltros() => mostrarFolhaRadar<void>(
    context,
    alturaMaxima: 0.68,
    builder: (_) => _FolhaFiltrosAlertas(
      filtroInicial: _controlador.filtro == 'nao_lidos'
          ? 'todos'
          : _controlador.filtro,
      aoAplicar: (filtro) {
        Navigator.of(context).pop();
        unawaited(_controlador.mudarFiltro(filtro));
      },
    ),
  );

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
            aoAbrir: widget.aoAbrirItem == null
                ? null
                : () => widget.aoAbrirItem!(_controlador.itens[indice]),
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
    this.aoAbrir,
  });
  final AlertaApp alerta;
  final VoidCallback aoMarcar;
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
                        onPressed:
                            aoAbrir ??
                            () => mostrarMensagemRadar(
                              context,
                              'Abra a origem do item em Explorar.',
                            ),
                        child: const Text('Ver item'),
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
    required this.filtroInicial,
    required this.aoAplicar,
  });

  final String filtroInicial;
  final ValueChanged<String> aoAplicar;

  @override
  State<_FolhaFiltrosAlertas> createState() => _EstadoFolhaFiltrosAlertas();
}

class _EstadoFolhaFiltrosAlertas extends State<_FolhaFiltrosAlertas> {
  late String _filtro = widget.filtroInicial;

  @override
  Widget build(BuildContext context) => FolhaRadar(
    titulo: 'Filtrar mudanças',
    descricao: 'Escolha o tipo de mudança que quer acompanhar.',
    child: Flexible(
      child: RadioGroup<String>(
        groupValue: _filtro,
        onChanged: (valor) {
          if (valor == null) return;
          setState(() => _filtro = valor);
        },
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final filtro in const [
              'todos',
              'preco',
              'cashback',
              'pontuacao',
            ])
              RadioListTile<String>(
                value: filtro,
                title: Text(_rotuloFiltro(filtro)),
              ),
            SizedBox(height: context.tokens.spacing.two),
            FilledButton(
              onPressed: () => widget.aoAplicar(_filtro),
              child: const Text('Aplicar filtro'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FolhaPreferenciasAlertas extends StatefulWidget {
  const _FolhaPreferenciasAlertas({required this.api, required this.iniciais});
  final Api api;
  final PreferenciasAlertas iniciais;

  @override
  State<_FolhaPreferenciasAlertas> createState() =>
      _EstadoFolhaPreferenciasAlertas();
}

class _EstadoFolhaPreferenciasAlertas extends State<_FolhaPreferenciasAlertas> {
  late PreferenciasAlertas _valor = widget.iniciais;
  var _salvando = false;

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await widget.api.salvarPreferenciasAlertas(_valor);
      if (mounted) {
        mostrarMensagemRadar(context, 'Preferências salvas.');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagemRadar(
          context,
          'Não foi possível salvar as preferências.',
          sucesso: false,
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => FolhaRadar(
    titulo: 'Preferências de alertas',
    descricao: 'Push é opcional; o histórico permanece acessível.',
    child: Flexible(
      child: ListView(
        shrinkWrap: true,
        children: [
          _chave(
            'Receber notificações',
            'Resumo por coleta válida',
            _valor.pushGlobal,
            (value) =>
                setState(() => _valor = _valor.copiarCom(pushGlobal: value)),
          ),
          _chave(
            'Alterações de preço',
            null,
            _valor.preco,
            (value) => setState(() => _valor = _valor.copiarCom(preco: value)),
          ),
          _chave(
            'Alterações de cashback',
            null,
            _valor.cashback,
            (value) =>
                setState(() => _valor = _valor.copiarCom(cashback: value)),
          ),
          _chave(
            'Alterações de pontuação',
            null,
            _valor.pontuacao,
            (value) =>
                setState(() => _valor = _valor.copiarCom(pontuacao: value)),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('permissao-notificacoes-alertas'),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => PaginaPermissaoNotificacoes(api: widget.api),
              ),
            ),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Permissão de notificações'),
          ),
          SizedBox(height: context.tokens.spacing.two),
          FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: Text(_salvando ? 'Salvando…' : 'Salvar preferências'),
          ),
        ],
      ),
    ),
  );

  Widget _chave(
    String titulo,
    String? descricao,
    bool valor,
    ValueChanged<bool> aoMudar,
  ) => SwitchListTile(
    title: Text(titulo),
    subtitle: descricao == null ? null : Text(descricao),
    value: valor,
    onChanged: aoMudar,
    contentPadding: EdgeInsets.zero,
  );
}

String _rotuloFiltro(String filtro) => switch (filtro) {
  'todos' => 'Todos',
  'preco' => 'Preço',
  'cashback' => 'Cashback',
  'pontuacao' => 'Pontuação',
  _ => 'Não lidos',
};
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
  'inter_cashback' => 'Inter Sites parceiros',
  'inter_produto' => 'Inter Compre direto',
  'pichau' => 'Pichau',
  _ => origem,
};

class _BarraInferiorAlertas extends StatelessWidget {
  const _BarraInferiorAlertas({required this.aoSelecionar});

  final ValueChanged<DestinoCompacto> aoSelecionar;

  static const _destinos = <DestinoCompacto>[
    DestinoCompacto.inicio,
    DestinoCompacto.explorar,
    DestinoCompacto.radar,
    DestinoCompacto.perfil,
  ];

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: NavigationBar(
      key: const Key('barra-inferior-v15'),
      selectedIndex: 0,
      onDestinationSelected: (indice) => aoSelecionar(_destinos[indice]),
      destinations: [
        for (final destino in _destinos)
          NavigationDestination(
            key: Key('barra-${destino.name}'),
            icon: Icon(destino.icone),
            selectedIcon: Icon(_iconeSelecionado(destino)),
            label: destino.titulo,
          ),
      ],
    ),
  );

  static IconData _iconeSelecionado(DestinoCompacto destino) =>
      switch (destino) {
        DestinoCompacto.inicio => Icons.home,
        DestinoCompacto.explorar => Icons.explore,
        DestinoCompacto.radar => Icons.bookmark,
        DestinoCompacto.perfil => Icons.person,
        _ => destino.icone,
      };
}
