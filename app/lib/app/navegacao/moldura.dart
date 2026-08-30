import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../../core/versao_app.dart';
import '../../features/administracao/pagina_administracao.dart';
import '../../features/livelo/pagina_painel_livelo.dart';
import '../../features/livelo/pagina_catalogo_livelo_android.dart';
import '../../features/produtos/pagina_produtos.dart';
import '../componentes/fundacao_visual.dart';
import '../identidade/logo_radar.dart';
import '../paginas/inicio.dart';
import '../paginas/lojas.dart';
import '../paginas/lugar.dart';
import '../tema/tokens.dart';
import 'destinos.dart';

/// Moldura adaptativa do Radar.
///
/// Janelas compactas usam cabeçalho + gaveta e janelas a partir de 920 px usam
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
  });

  final Api api;
  final bool administrador;
  final DateTime Function()? agora;
  final Future<void> Function()? aoSair;
  final String? identificacaoConta;

  @override
  State<MolduraRadar> createState() => _EstadoMolduraRadar();
}

class _EstadoMolduraRadar extends State<MolduraRadar> {
  static const _larguraLayoutAmplo = 920.0;

  final _scaffold = GlobalKey<ScaffoldState>();
  final _lojas = GlobalKey<EstadoPaginaLojas>();
  final Set<DestinoCompacto> _visitadosCompactos = {DestinoCompacto.inicio};
  Destino _selecionado = Destino.inicio;
  DestinoCompacto _selecionadoCompacto = DestinoCompacto.inicio;

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
      aoAbrirLivelo: () => _selecionarCompacto(DestinoCompacto.livelo),
      aoAbrirCashback: () => _selecionarCompacto(DestinoCompacto.inter),
      aoAbrirProdutos: () => _selecionarCompacto(DestinoCompacto.produtos),
    ),
    _visitadosCompactos.contains(DestinoCompacto.livelo)
        ? (!kIsWeb
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
                ))
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.inter)
        ? PaginaHubShoppingInter(
            key: const PageStorageKey('inter-compacto'),
            api: widget.api,
            administrador: widget.administrador,
            experienciaCompacta: true,
            ativa: _selecionadoCompacto == DestinoCompacto.inter,
          )
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.produtos)
        ? PaginaProdutos(
            key: const PageStorageKey('produtos-compacto'),
            api: widget.api,
            administrador: widget.administrador,
            incorporada: true,
            experienciaCompacta: true,
            aoEscolherLojas: () => _selecionarCompacto(DestinoCompacto.inter),
          )
        : const SizedBox.shrink(),
  ];

  Future<void> _abrirAlertas() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (contexto) => _FolhaAlertas(
      api: widget.api,
      aoAbrirLivelo: () {
        Navigator.of(contexto).pop();
        _selecionarCompacto(DestinoCompacto.livelo);
      },
      aoAbrirInter: () {
        Navigator.of(contexto).pop();
        _selecionarCompacto(DestinoCompacto.inter);
      },
    ),
  );

  Future<void> _abrirConta() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (contexto) => _FolhaConta(
      administrador: widget.administrador,
      identificacaoConta: widget.identificacaoConta,
      podeSair: widget.aoSair != null,
      aoAdministrar: widget.administrador
          ? () {
              Navigator.of(contexto).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      PaginaAdministracao(api: widget.api, administrador: true),
                ),
              );
            }
          : null,
      aoSair: widget.aoSair == null
          ? null
          : () async {
              Navigator.of(contexto).pop();
              await widget.aoSair!();
            },
    ),
  );

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
          key: _scaffold,
          appBar: _CabecalhoCompacto(
            titulo: _selecionadoCompacto.titulo,
            aoAbrirMenu: () => _scaffold.currentState?.openDrawer(),
            aoAbrirAlertas: _abrirAlertas,
          ),
          drawer: GavetaRadar(
            selecionado: _selecionadoCompacto,
            administrador: widget.administrador,
            aoSelecionar: _selecionarCompacto,
            aoAbrirAlertas: _abrirAlertas,
            aoAbrirConta: _abrirConta,
            identificacaoConta: widget.identificacaoConta,
          ),
          body: conteudo,
        );
      },
    );
  }
}

class _CabecalhoCompacto extends StatelessWidget
    implements PreferredSizeWidget {
  const _CabecalhoCompacto({
    required this.titulo,
    required this.aoAbrirMenu,
    required this.aoAbrirAlertas,
  });

  final String titulo;
  final VoidCallback aoAbrirMenu;
  final VoidCallback aoAbrirAlertas;

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: tema.colorScheme.surface,
      foregroundColor: tema.colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: Border(bottom: BorderSide(color: cores.borda)),
      leadingWidth: 59,
      leading: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: IconButton(
          key: const Key('abrir-menu-principal'),
          tooltip: 'Abrir menu principal',
          onPressed: aoAbrirMenu,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(42),
            maximumSize: const Size.square(42),
            padding: EdgeInsets.zero,
            backgroundColor: cores.superficieAlternativa,
            side: BorderSide(color: cores.borda),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.menu),
        ),
      ),
      title: _AssinaturaCompacta(titulo: titulo),
      titleSpacing: 0,
      centerTitle: false,
      actions: [
        if (!kIsWeb)
          const SizedBox.square(
            dimension: 38,
            child: ControleAparenciaRadar.icone(),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: SizedBox.square(
            dimension: 38,
            child: IconButton(
              key: const Key('abrir-alertas-cabecalho'),
              tooltip: 'Abrir alertas',
              onPressed: aoAbrirAlertas,
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssinaturaCompacta extends StatelessWidget {
  const _AssinaturaCompacta({required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Radar de Benefícios',
      header: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoRadar(tamanho: 34, sobreFundoEscuro: escuro),
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
                    color: escuro ? Tokens.textoEscuro : Tokens.marca,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CoresRadar.de(context).textoSuave,
                    height: 1,
                  ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      '4 ESPAÇOS PRINCIPAIS',
                      style: TextStyle(
                        color: CoresRadar.de(context).textoSuave,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  for (final destino in DestinoCompacto.values)
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Tokens.marcaProfunda,
        gradient: RadialGradient(
          center: const Alignment(1, -1),
          radius: 2.1,
          colors: <Color>[
            Tokens.ciano.withValues(alpha: 0.38),
            Tokens.marcaProfunda,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(19, 14, 19, 21),
          child: Column(
            children: [
              Row(
                children: [
                  const LogoRadar(tamanho: 42, sobreFundoEscuro: true),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radar de Benefícios',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Pontos, cashback e preços',
                          style: TextStyle(
                            color: Color(0xFFA9C0D2),
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
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(42),
                      maximumSize: const Size.square(42),
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
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
                color: Colors.white.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: const Key('abrir-conta-gaveta'),
                  contentPadding: const EdgeInsets.all(11),
                  textColor: Colors.white,
                  iconColor: const Color(0xFFA9C0D2),
                  leading: CircleAvatar(
                    radius: 20.5,
                    backgroundColor: Tokens.ciano,
                    foregroundColor: Tokens.marcaProfunda,
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
                    style: const TextStyle(
                      color: Color(0xFFA9C0D2),
                      fontSize: 9,
                    ),
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

class _FolhaAlertas extends StatefulWidget {
  const _FolhaAlertas({
    required this.api,
    required this.aoAbrirLivelo,
    required this.aoAbrirInter,
  });

  final Api api;
  final VoidCallback aoAbrirLivelo;
  final VoidCallback aoAbrirInter;

  @override
  State<_FolhaAlertas> createState() => _EstadoFolhaAlertas();
}

class _EstadoFolhaAlertas extends State<_FolhaAlertas> {
  late Future<ResumoInicio> _resumo;

  @override
  void initState() {
    super.initState();
    _resumo = widget.api.resumo();
  }

  void _tentarNovamente() => setState(() => _resumo = widget.api.resumo());

  @override
  Widget build(BuildContext context) {
    return FolhaRadar(
      titulo: 'Alertas',
      descricao: 'Eventos importantes, fora do menu principal.',
      child: FutureBuilder<ResumoInicio>(
        future: _resumo,
        builder: (context, estado) {
          if (estado.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (!estado.hasData) {
            return Column(
              children: [
                const Text('Não foi possível consultar os estados agora.'),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _tentarNovamente,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            );
          }
          final resumo = estado.data!;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.62,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                CartaoRadar(
                  aoTocar: widget.aoAbrirLivelo,
                  padding: const EdgeInsets.all(12),
                  child: _LinhaFolha(
                    icone: Icons.card_giftcard_outlined,
                    titulo: resumo.livelo.alertasUltimaColeta == 0
                        ? 'Nenhum alerta na última coleta Livelo'
                        : '${resumo.livelo.alertasUltimaColeta} alertas na última coleta Livelo',
                    descricao:
                        '${resumo.livelo.lojasAcompanhadas} lojas acompanhadas · ${_rotuloEstadoResumo(resumo.livelo.estado)}',
                    mostrarSeta: false,
                  ),
                ),
                const SizedBox(height: 10),
                CartaoRadar(
                  aoTocar: widget.aoAbrirInter,
                  padding: const EdgeInsets.all(12),
                  child: _LinhaFolha(
                    icone: Icons.account_balance_outlined,
                    titulo: 'Banco Inter',
                    descricao:
                        'Cashback: ${_rotuloEstadoResumo(resumo.cashbackInter.estado)} · produtos: ${_rotuloEstadoResumo(resumo.produtos.estado)}',
                    mostrarSeta: false,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Histórico, lidos e não lidos dependem de um endpoint próprio e ainda não são exibidos.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CoresRadar.de(context).textoSuave,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FolhaConta extends StatelessWidget {
  const _FolhaConta({
    required this.administrador,
    required this.podeSair,
    required this.aoAdministrar,
    required this.aoSair,
    this.identificacaoConta,
  });

  final bool administrador;
  final bool podeSair;
  final VoidCallback? aoAdministrar;
  final Future<void> Function()? aoSair;
  final String? identificacaoConta;

  @override
  Widget build(BuildContext context) {
    return FolhaRadar(
      titulo: 'Conta e sistema',
      descricao: 'Utilidades não ocupam um tema principal.',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              administrador ? 'Acesso administrador' : 'Acesso padrão',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CoresRadar.de(context).textoSuave,
              ),
            ),
            const SizedBox(height: 8),
            if (aoAdministrar != null) ...[
              CartaoRadar(
                aoTocar: aoAdministrar,
                padding: const EdgeInsets.all(12),
                child: const _LinhaFolha(
                  icone: Icons.settings_outlined,
                  titulo: 'Administração',
                  descricao: 'Preferências, disparos e fontes selecionadas',
                  mostrarSeta: true,
                ),
              ),
            ],
            const SizedBox(height: 10),
            const CartaoRadar(
              padding: EdgeInsets.all(12),
              child: _LinhaFolha(
                icone: Icons.shield_outlined,
                titulo: 'Segurança e acesso',
                descricao: 'Sessão, convite e permissões',
              ),
            ),
            const SizedBox(height: 10),
            const CartaoRadar(
              padding: EdgeInsets.all(12),
              child: _LinhaFolha(
                icone: Icons.add,
                titulo: 'Integrações',
                descricao: 'Pronto para novos bancos e programas',
              ),
            ),
            if (podeSair) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('sair-conta'),
                onPressed: aoSair,
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinhaFolha extends StatelessWidget {
  const _LinhaFolha({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.mostrarSeta = true,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool mostrarSeta;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: cores.superficieAlternativa,
            borderRadius: BorderRadius.circular(13),
          ),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icone, color: cores.acao),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                descricao,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
              ),
            ],
          ),
        ),
        if (mostrarSeta) ...[
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ],
    );
  }
}

String _rotuloEstadoResumo(EstadoResumo estado) => switch (estado) {
  EstadoResumo.atualizado => 'atualizado',
  EstadoResumo.atencao => 'atenção',
  EstadoResumo.atrasado => 'atrasado',
  EstadoResumo.atualizando => 'atualizando',
  EstadoResumo.falhaRecente => 'falha recente',
  EstadoResumo.parcial => 'parcial',
  EstadoResumo.degradado => 'degradado',
  EstadoResumo.semDados => 'sem dados',
  EstadoResumo.indisponivel => 'indisponível',
};
