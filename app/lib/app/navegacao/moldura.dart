import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/versao_app.dart';
import '../../features/administracao/pagina_administracao.dart';
import '../../features/alertas/gerenciador_notificacoes.dart';
import '../../features/alertas/pagina_alertas.dart';
import '../../features/conta/paginas_conta.dart';
import '../../features/conta/pagina_aparencia.dart';
import '../../features/conta/pagina_laboratorio.dart';
import '../../features/conta/pagina_perfil.dart';
import '../../features/livelo/pagina_painel_livelo.dart';
import '../../features/livelo/pagina_catalogo_livelo_android.dart';
import '../../features/pichau/pagina_pichau.dart';
import '../../features/produtos/pagina_produtos.dart';
import '../componentes/fundacao_visual.dart';
import '../identidade/logo_radar.dart';
import '../paginas/inicio.dart';
import '../paginas/lojas.dart';
import '../paginas/lugar.dart';
import '../paginas/programas.dart';
import '../tema/tokens.dart';
import 'destinos.dart';

/// Moldura adaptativa do Radar.
///
/// Janelas compactas usam cabeçalho + perfil e janelas a partir de 920 px usam
/// a lateral fixa preservada. Cada modo mantém seu [IndexedStack] para conservar
/// buscas, filtros, rotas internas e posição útil entre seus destinos.
class MolduraRadar extends StatefulWidget {
  const MolduraRadar({
    super.key,
    required this.api,
    this.administrador = true,
    this.agora,
    this.aoSair,
    this.identificacaoConta,
    this.notificacoesAtivas = false,
  });

  final Api api;
  final bool administrador;
  final DateTime Function()? agora;
  final Future<void> Function()? aoSair;
  final String? identificacaoConta;
  final bool notificacoesAtivas;

  @override
  State<MolduraRadar> createState() => _EstadoMolduraRadar();
}

class _EstadoMolduraRadar extends State<MolduraRadar> {
  static const _larguraLayoutAmplo = 920.0;

  final _lojas = GlobalKey<EstadoPaginaLojas>();
  final _inter = GlobalKey<EstadoPaginaHubShoppingInter>();
  final Set<DestinoCompacto> _visitadosCompactos = {DestinoCompacto.inicio};
  Destino _selecionado = Destino.inicio;
  DestinoCompacto _selecionadoCompacto = DestinoCompacto.inicio;
  var _atualizandoResumoCabecalho = false;
  GerenciadorNotificacoes? _notificacoes;

  @override
  void initState() {
    super.initState();
    if (widget.notificacoesAtivas) {
      _notificacoes = GerenciadorNotificacoes(
        api: widget.api,
        aoAbrirCentral: (coleta) => _abrirAlertas(coleta: coleta),
      );
      unawaited(_notificacoes!.iniciar());
    }
  }

  @override
  void dispose() {
    unawaited(_notificacoes?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  void _selecionar(Destino destino) {
    if (_selecionado == destino) return;
    setState(() => _selecionado = destino);
  }

  void _selecionarCompacto(DestinoCompacto destino) {
    if (_selecionadoCompacto == destino) return;
    setState(() {
      _visitadosCompactos.add(destino);
      _selecionadoCompacto = destino;
    });
  }

  void _abrirFonte(FonteLojas fonte) {
    _selecionar(Destino.lojas);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lojas.currentState?.abrirFonte(fonte);
    });
  }

  List<Widget> get _paineisAmplos => <Widget>[
    PaginaInicio(
      api: widget.api,
      agora: widget.agora,
      ativa: _selecionado == Destino.inicio,
      aoAbrirLojas: () => _selecionar(Destino.lojas),
      aoAbrirLivelo: () => _abrirFonte(FonteLojas.livelo),
      aoAbrirProdutos: () => _selecionar(Destino.produtos),
      aoAbrirCashback: () => _abrirFonte(FonteLojas.cashbackInter),
    ),
    PaginaLojas(
      key: _lojas,
      api: widget.api,
      administrador: widget.administrador,
      ativa: _selecionado == Destino.lojas,
    ),
    PaginaProdutos(
      api: widget.api,
      administrador: widget.administrador,
      incorporada: true,
    ),
    const PaginaEmBreve(titulo: 'Alertas'),
    PaginaAdministracao(
      api: widget.api,
      administrador: widget.administrador,
      incorporada: true,
    ),
  ];

  List<Widget> get _paineisCompactos => <Widget>[
    PaginaInicio(
      key: const PageStorageKey('inicio-compacto'),
      api: widget.api,
      agora: widget.agora,
      experienciaCompacta: true,
      ativa: _selecionadoCompacto == DestinoCompacto.inicio,
      aoAbrirProgramas: () => _selecionarCompacto(DestinoCompacto.programas),
      aoAbrirLivelo: () => _selecionarCompacto(DestinoCompacto.livelo),
      aoAbrirCashback: () => _selecionarCompacto(DestinoCompacto.inter),
      aoAbrirPichau: () => _selecionarCompacto(DestinoCompacto.pichau),
      aoAbrirAlertas: () => unawaited(_abrirAlertas()),
      aoAbrirProdutos: _abrirProdutosNoInter,
    ),
    _visitadosCompactos.contains(DestinoCompacto.programas)
        ? PaginaProgramas(
            key: const PageStorageKey('programas-compacto'),
            api: widget.api,
            ativa: _selecionadoCompacto == DestinoCompacto.programas,
            aoAbrirLivelo: () => _selecionarCompacto(DestinoCompacto.livelo),
            aoAbrirInter: () => _selecionarCompacto(DestinoCompacto.inter),
            aoAbrirPichau: () => _selecionarCompacto(DestinoCompacto.pichau),
          )
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.livelo)
        ? _PaginaProgramaInterna(
            chaveVoltar: const Key('voltar-programas-livelo'),
            aoVoltar: () => _selecionarCompacto(DestinoCompacto.programas),
            child: !kIsWeb
                ? PaginaCatalogoLiveloAndroid(
                    key: const PageStorageKey('livelo-catalogo-nativo'),
                    api: widget.api,
                    administrador: widget.administrador,
                    aoAbrirAlertas: _abrirAlertas,
                  )
                : PaginaPainelLivelo(
                    key: const PageStorageKey('livelo-compacto'),
                    api: widget.api,
                    administrador: widget.administrador,
                    experienciaCompacta: true,
                  ),
          )
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.inter)
        ? _PaginaProgramaInterna(
            chaveVoltar: const Key('voltar-programas-inter'),
            aoVoltar: () => _selecionarCompacto(DestinoCompacto.programas),
            child: PaginaHubShoppingInter(
              key: _inter,
              api: widget.api,
              administrador: widget.administrador,
              experienciaCompacta: true,
              ativa: _selecionadoCompacto == DestinoCompacto.inter,
            ),
          )
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.pichau)
        ? _PaginaProgramaInterna(
            chaveVoltar: const Key('voltar-programas-pichau'),
            aoVoltar: () => _selecionarCompacto(DestinoCompacto.programas),
            child: PaginaPichau(
              key: const PageStorageKey('pichau-catalogo-nativo'),
              api: widget.api,
              administrador: widget.administrador,
              ativa: _selecionadoCompacto == DestinoCompacto.pichau,
            ),
          )
        : const SizedBox.shrink(),
  ];

  void _abrirProdutosNoInter() {
    _selecionarCompacto(DestinoCompacto.inter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inter.currentState?.abrirProdutos();
    });
  }

  Future<void> _abrirAlertas({String? coleta}) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => PaginaAlertas(api: widget.api, coletaInicial: coleta),
        ),
      );

  Future<void> _abrirAjuda() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => PaginaAjuda(api: widget.api)),
  );

  Future<void> _abrirPrivacidade() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => PaginaPrivacidade(api: widget.api)),
  );

  Future<void> _abrirProblema() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PaginaRelatoProblema(api: widget.api),
    ),
  );

  Future<void> _abrirConta() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PaginaPerfil(
        administrador: widget.administrador,
        identificacao: widget.identificacaoConta,
        aoAbrirAlertas: () => unawaited(_abrirAlertas()),
        aoAbrirAparencia: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const PaginaAparencia()),
        ),
        aoAbrirAjuda: () => unawaited(_abrirAjuda()),
        aoAbrirProblema: () => unawaited(_abrirProblema()),
        aoAbrirPrivacidade: () => unawaited(_abrirPrivacidade()),
        aoAbrirLaboratorio: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const PaginaLaboratorio()),
        ),
        aoAdministrar: widget.administrador
            ? () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PaginaAdministracao(
                    api: widget.api,
                    administrador: true,
                    somenteZonaDePerigo: true,
                  ),
                ),
              )
            : null,
        aoSair: widget.aoSair == null
            ? null
            : () async {
                await _notificacoes?.removerAtual();
                await widget.aoSair!();
              },
      ),
    ),
  );

  Future<void> _atualizarResumoCabecalho() async {
    if (_atualizandoResumoCabecalho) return;
    setState(() => _atualizandoResumoCabecalho = true);
    try {
      await widget.api.resumo();
      if (!mounted) return;
      mostrarMensagemRadar(context, 'Resumo atualizado.');
    } on Object {
      if (!mounted) return;
      mostrarMensagemRadar(
        context,
        'Não foi possível atualizar o resumo.',
        sucesso: false,
      );
    } finally {
      if (mounted) setState(() => _atualizandoResumoCabecalho = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final amplo = limites.maxWidth >= _larguraLayoutAmplo;

        if (amplo) {
          final conteudo = IndexedStack(
            key: const Key('moldura-paineis-amplos'),
            index: _selecionado.index,
            children: _paineisAmplos,
          );
          return Scaffold(
            body: Row(
              children: [
                BarraLateral(
                  selecionado: _selecionado,
                  administrador: widget.administrador,
                  aoSelecionar: _selecionar,
                ),
                Expanded(child: conteudo),
              ],
            ),
          );
        }

        final conteudo = IndexedStack(
          key: const Key('moldura-paineis-compactos'),
          index: _selecionadoCompacto.index,
          children: _paineisCompactos,
        );

        return Scaffold(
          appBar: _CabecalhoCompacto(
            aoAbrirConta: _abrirConta,
            aoAtualizarResumo: _atualizarResumoCabecalho,
            atualizandoResumo: _atualizandoResumoCabecalho,
          ),
          body: conteudo,
          bottomNavigationBar: _BarraInferiorRadar(
            selecionado: _selecionadoCompacto.destinoDaBarra,
            aoSelecionar: _selecionarCompacto,
          ),
        );
      },
    );
  }
}

class _CabecalhoCompacto extends StatelessWidget
    implements PreferredSizeWidget {
  const _CabecalhoCompacto({
    required this.aoAbrirConta,
    required this.aoAtualizarResumo,
    required this.atualizandoResumo,
  });

  final VoidCallback aoAbrirConta;
  final VoidCallback aoAtualizarResumo;
  final bool atualizandoResumo;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: tema.scaffoldBackgroundColor,
      foregroundColor: tema.colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: cores.borda)),
      automaticallyImplyLeading: false,
      title: const _AssinaturaCompacta(),
      titleSpacing: 18,
      centerTitle: false,
      actions: [
        IconButton(
          key: const Key('atualizar-resumo-cabecalho'),
          tooltip: 'Atualizar resumo',
          onPressed: atualizandoResumo ? null : aoAtualizarResumo,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
            maximumSize: const Size.square(48),
            padding: EdgeInsets.zero,
            backgroundColor: tema.cardColor,
            side: BorderSide(color: cores.borda),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radii.md),
            ),
          ),
          icon: atualizandoResumo
              ? const SizedBox.square(
                  dimension: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
        SizedBox(width: tokens.spacing.two),
        IconButton(
          key: const Key('abrir-conta-cabecalho'),
          tooltip: 'Abrir perfil',
          onPressed: aoAbrirConta,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(48),
            maximumSize: const Size.square(48),
            padding: EdgeInsets.zero,
            backgroundColor: tema.cardColor,
            side: BorderSide(color: cores.borda),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radii.md),
            ),
          ),
          icon: const Icon(Icons.person_outline),
        ),
        SizedBox(width: tokens.spacing.four),
      ],
    );
  }
}

class _BarraInferiorRadar extends StatelessWidget {
  const _BarraInferiorRadar({
    required this.selecionado,
    required this.aoSelecionar,
  });

  final DestinoCompacto selecionado;
  final ValueChanged<DestinoCompacto> aoSelecionar;

  static const _destinos = <DestinoCompacto>[
    DestinoCompacto.inicio,
    DestinoCompacto.programas,
  ];

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final tema = Theme.of(context);
    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(
        tokens.spacing.four,
        0,
        tokens.spacing.four,
        tokens.spacing.four,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cores.marca,
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[SombraRadar.para(tema.brightness)],
        ),
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              for (final destino in _destinos)
                Expanded(
                  child: _DestinoBarraInferior(
                    destino: destino,
                    selecionado: selecionado == destino,
                    aoTocar: () => aoSelecionar(destino),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinoBarraInferior extends StatelessWidget {
  const _DestinoBarraInferior({
    required this.destino,
    required this.selecionado,
    required this.aoTocar,
  });

  final DestinoCompacto destino;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return Semantics(
      selected: selecionado,
      button: true,
      label: destino.titulo,
      child: InkWell(
        key: Key('barra-${destino.name}'),
        borderRadius: BorderRadius.circular(16),
        onTap: aoTocar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: EdgeInsets.all(tokens.spacing.one),
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.two),
          decoration: BoxDecoration(
            color: selecionado ? Tokens.mark : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                destino.icone,
                size: 21,
                color: selecionado ? Tokens.markInk : cores.textoSuave,
              ),
              const SizedBox(height: 3),
              Text(
                destino.titulo,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selecionado ? Tokens.markInk : cores.textoSuave,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginaProgramaInterna extends StatelessWidget {
  const _PaginaProgramaInterna({
    required this.chaveVoltar,
    required this.aoVoltar,
    required this.child,
  });

  final Key chaveVoltar;
  final VoidCallback aoVoltar;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.tokens.spacing.two,
            context.tokens.spacing.one,
            context.tokens.spacing.two,
            0,
          ),
          child: TextButton.icon(
            key: chaveVoltar,
            onPressed: aoVoltar,
            icon: const Icon(Icons.arrow_back, size: 17),
            label: const Text('Serviços'),
          ),
        ),
      ),
      Expanded(child: child),
    ],
  );
}

class _AssinaturaCompacta extends StatelessWidget {
  const _AssinaturaCompacta();

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return Semantics(
      label: 'Radar de Benefícios',
      header: true,
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cores.marca,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(tokens.radii.md),
                topRight: Radius.circular(tokens.radii.md),
                bottomRight: Radius.circular(tokens.radii.md),
                bottomLeft: Radius.circular(tokens.spacing.one),
              ),
            ),
            child: Text(
              'R',
              style: TextStyle(
                color: cores.marcaTexto,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Radar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cores.ganho,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 7),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'API protegida',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cores.ganho,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GavetaRadar extends StatelessWidget {
  const GavetaRadar({
    super.key,
    required this.selecionado,
    required this.administrador,
    required this.aoSelecionar,
    required this.aoAbrirAlertas,
    required this.aoAbrirConta,
    this.identificacaoConta,
  });

  final DestinoCompacto selecionado;
  final bool administrador;
  final ValueChanged<DestinoCompacto> aoSelecionar;
  final VoidCallback aoAbrirAlertas;
  final VoidCallback aoAbrirConta;
  final String? identificacaoConta;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: const Key('gaveta-principal'),
      width: (MediaQuery.sizeOf(context).width * 0.88)
          .clamp(0.0, 360.0)
          .toDouble(),
      shape: const RoundedRectangleBorder(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _TopoGaveta(
              administrador: administrador,
              identificacaoConta: identificacaoConta,
              aoAbrirConta: aoAbrirConta,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 17, 13, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
                    child: Text(
                      'NAVEGAÇÃO PRINCIPAL',
                      style: TextStyle(
                        color: CoresRadar.de(context).textoSuave,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final destino in DestinoCompacto.values.where(
                    (destino) => destino.principal,
                  ))
                    _ItemNavegacaoCompacto(
                      key: Key('destino-${destino.name}'),
                      destino: destino,
                      selecionado: destino == selecionado,
                      aoTocar: () {
                        Navigator.of(context).pop();
                        aoSelecionar(destino);
                      },
                    ),
                ],
              ),
            ),
          ),
          if (MediaQuery.sizeOf(context).height < 700 ||
              MediaQuery.textScalerOf(context).scale(16) > 19.2)
            SliverToBoxAdapter(
              child: _RodapeGaveta(
                administrador: administrador,
                aoAbrirAlertas: aoAbrirAlertas,
                aoAbrirConta: aoAbrirConta,
              ),
            )
          else
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _RodapeGaveta(
                  administrador: administrador,
                  aoAbrirAlertas: aoAbrirAlertas,
                  aoAbrirConta: aoAbrirConta,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopoGaveta extends StatelessWidget {
  const _TopoGaveta({
    required this.administrador,
    required this.identificacaoConta,
    required this.aoAbrirConta,
  });

  final bool administrador;
  final String? identificacaoConta;
  final VoidCallback aoAbrirConta;

  @override
  Widget build(BuildContext context) {
    final identificacao = identificacaoConta ?? 'Conta do Radar';
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final escuro = tema.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tema.scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: cores.borda)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19, 14, 19, 21),
          child: Column(
            children: [
              Row(
                children: [
                  LogoRadar(tamanho: 42, sobreFundoEscuro: escuro),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Radar de Benefícios',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Pontos, cashback e preços',
                          style: TextStyle(
                            color: cores.textoSuave,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('fechar-menu-principal'),
                    tooltip: 'Fechar menu principal',
                    onPressed: () => Navigator.of(context).pop(),
                    color: cores.textoSuave,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(42),
                      maximumSize: const Size.square(42),
                      backgroundColor: cores.superficieAlternativa,
                      side: BorderSide(color: cores.borda),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Material(
                color: tema.cardColor,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: cores.borda),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: const Key('abrir-conta-gaveta'),
                  contentPadding: const EdgeInsets.all(11),
                  textColor: tema.colorScheme.onSurface,
                  iconColor: cores.textoSuave,
                  leading: CircleAvatar(
                    radius: 20.5,
                    backgroundColor: escuro
                        ? Tokens.acaoFundoEscuro
                        : Tokens.acaoFundo,
                    foregroundColor: cores.acao,
                    child: Text(
                      _iniciaisConta(identificacao),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  title: Text(
                    identificacao,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    administrador ? 'Acesso administrador' : 'Acesso padrão',
                    style: TextStyle(color: cores.textoSuave, fontSize: 9),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.of(context).pop();
                    aoAbrirConta();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RodapeGaveta extends StatelessWidget {
  const _RodapeGaveta({
    required this.administrador,
    required this.aoAbrirAlertas,
    required this.aoAbrirConta,
  });

  final bool administrador;
  final VoidCallback aoAbrirAlertas;
  final VoidCallback aoAbrirConta;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: cores.borda)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(17, 8, 17, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb) const ControleAparenciaRadar.linha(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _BotaoUtilidadeGaveta(
                      chave: const Key('abrir-alertas-gaveta'),
                      icone: Icons.notifications_outlined,
                      rotulo: 'Alertas',
                      aoTocar: () {
                        Navigator.of(context).pop();
                        aoAbrirAlertas();
                      },
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _BotaoUtilidadeGaveta(
                      chave: const Key('abrir-sistema-gaveta'),
                      icone: Icons.settings_outlined,
                      rotulo: administrador ? 'Administração' : 'Conta',
                      aoTocar: () {
                        Navigator.of(context).pop();
                        aoAbrirConta();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _RodapeVersao(administrador: administrador),
            ],
          ),
        ),
      ),
    );
  }
}

String _iniciaisConta(String identificacao) {
  final partes = identificacao
      .trim()
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((parte) => parte.isNotEmpty)
      .take(2)
      .toList(growable: false);
  if (partes.isEmpty) return 'R';
  return partes.map((parte) => parte.characters.first).join().toUpperCase();
}

class _BotaoUtilidadeGaveta extends StatelessWidget {
  const _BotaoUtilidadeGaveta({
    required this.chave,
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
  });

  final Key chave;
  final IconData icone;
  final String rotulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return OutlinedButton.icon(
      key: chave,
      style: OutlinedButton.styleFrom(
        foregroundColor: cores.textoSuave,
        side: BorderSide(color: cores.borda),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      onPressed: aoTocar,
      icon: Icon(icone, size: 18),
      label: Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _RodapeVersao extends StatelessWidget {
  const _RodapeVersao({required this.administrador});

  final bool administrador;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Radar de Benefícios',
          style: const TextStyle(color: Color(0xFF8195A5), fontSize: 10),
        ),
        FutureBuilder<String>(
          future: VersaoApp.versao(),
          builder: (context, estado) {
            final texto = estado.hasData && estado.data != '—'
                ? 'v${estado.data}'
                : '';
            if (texto.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                texto,
                style: const TextStyle(color: Color(0xFF8195A5), fontSize: 10),
              ),
            );
          },
        ),
      ],
    );
  }
}

class BarraLateral extends StatelessWidget {
  const BarraLateral({
    super.key,
    required this.selecionado,
    required this.administrador,
    required this.aoSelecionar,
  });

  final Destino selecionado;
  final bool administrador;
  final ValueChanged<Destino> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('barra-lateral-principal'),
      color: Tokens.marcaProfunda,
      child: SafeArea(
        child: SizedBox(
          width: 244,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 24, 22, 28),
                child: Row(
                  children: [
                    LogoRadar(tamanho: 44, sobreFundoEscuro: true),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Radar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final destino in Destino.values)
                      _ItemNavegacao(
                        key: Key('destino-lateral-${destino.name}'),
                        destino: destino,
                        selecionado: destino == selecionado,
                        aoTocar: () => aoSelecionar(destino),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: _RodapeVersao(administrador: administrador),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemNavegacao extends StatelessWidget {
  const _ItemNavegacao({
    super.key,
    required this.destino,
    required this.selecionado,
    required this.aoTocar,
  });

  final Destino destino;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selecionado,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: ListTile(
          selected: selecionado,
          selectedColor: Colors.white,
          textColor: const Color(0xFFC6D5E2),
          iconColor: const Color(0xFFC6D5E2),
          selectedTileColor: Colors.white.withValues(alpha: 0.13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          leading: Icon(destino.icone),
          title: Text(
            destino.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: aoTocar,
        ),
      ),
    );
  }
}

class _ItemNavegacaoCompacto extends StatelessWidget {
  const _ItemNavegacaoCompacto({
    super.key,
    required this.destino,
    required this.selecionado,
    required this.aoTocar,
  });

  final DestinoCompacto destino;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final cores = CoresRadar.de(context);
    final texto = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      selected: selecionado,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          minTileHeight: 66,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          selected: selecionado,
          selectedColor: cores.acao,
          textColor: texto,
          iconColor: texto,
          selectedTileColor: escuro ? Tokens.acaoFundoEscuro : Tokens.acaoFundo,
          shape: RoundedRectangleBorder(
            side: selecionado
                ? BorderSide(color: cores.acao.withValues(alpha: 0.22))
                : BorderSide.none,
            borderRadius: BorderRadius.circular(16),
          ),
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: selecionado
                  ? Theme.of(context).colorScheme.surface
                  : cores.superficieAlternativa,
              borderRadius: BorderRadius.circular(13),
            ),
            child: SizedBox.square(
              dimension: 43,
              child: Icon(destino.icone, size: 22),
            ),
          ),
          title: Text(
            destino.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            destino.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cores.textoSuave, fontSize: 8),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: aoTocar,
        ),
      ),
    );
  }
}
