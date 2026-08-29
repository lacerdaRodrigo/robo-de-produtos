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
      aoAbrirLivelo: () => _selecionarCompacto(DestinoCompacto.livelo),
      aoAbrirCashback: () => _selecionarCompacto(DestinoCompacto.inter),
      aoAbrirProdutos: () => _selecionarCompacto(DestinoCompacto.produtos),
    ),
    _visitadosCompactos.contains(DestinoCompacto.livelo)
        ? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
              ? PaginaCatalogoLiveloAndroid(
                  key: const PageStorageKey('livelo-catalogo-android'),
                  api: widget.api,
                  administrador: widget.administrador,
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
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final escuro = tema.brightness == Brightness.dark;
    final superficie = escuro ? tema.colorScheme.surface : Colors.white;
    return AppBar(
      backgroundColor: superficie,
      foregroundColor: tema.colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 1,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton.filledTonal(
          key: const Key('abrir-menu-principal'),
          tooltip: 'Abrir menu principal',
          onPressed: aoAbrirMenu,
          icon: const Icon(Icons.menu),
        ),
      ),
      title: _AssinaturaCompacta(titulo: titulo),
      centerTitle: true,
      actions: [
        if (!kIsWeb) const ControleAparenciaRadar.icone(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            key: const Key('abrir-alertas-cabecalho'),
            tooltip: 'Abrir alertas',
            onPressed: aoAbrirAlertas,
            icon: const Icon(Icons.notifications_outlined),
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
          LogoRadar(tamanho: 32, sobreFundoEscuro: escuro),
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
      width: MediaQuery.sizeOf(context).width.clamp(280.0, 320.0),
      shape: const RoundedRectangleBorder(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Tokens.marcaProfunda,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
                  child: Row(
                    children: [
                      const LogoRadar(tamanho: 44, sobreFundoEscuro: true),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Radar de Benefícios',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Pontos, cashback e preços',
                              style: TextStyle(
                                color: Color(0xFF93AABD),
                                fontSize: 11,
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
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                color: Tokens.marcaProfunda,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    key: const Key('abrir-conta-gaveta'),
                    textColor: Colors.white,
                    iconColor: const Color(0xFFC6D5E2),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF173B57),
                      foregroundColor: Colors.white,
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(identificacaoConta ?? 'Conta do Radar'),
                    subtitle: Text(
                      administrador ? 'Acesso administrador' : 'Acesso padrão',
                      style: const TextStyle(color: Color(0xFF93AABD)),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pop();
                      aoAbrirConta();
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: Text(
                        '4 ESPAÇOS PRINCIPAIS',
                        style: TextStyle(
                          color: Color(0xFF93AABD),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
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
              SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
              if (!kIsWeb)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFD3E0EA))),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: ControleAparenciaRadar.linha(
                      cor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFD7E3ED)
                          : const Color(0xFF173B57),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
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
                    const SizedBox(width: 8),
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
                child: _RodapeVersao(administrador: administrador),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      key: chave,
      style: OutlinedButton.styleFrom(
        foregroundColor: escuro
            ? const Color(0xFFC6D5E2)
            : const Color(0xFF526E83),
        side: BorderSide(
          color: escuro
              ? Colors.white.withValues(alpha: 0.14)
              : const Color(0xFFD3E0EA),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
    final texto = escuro ? const Color(0xFFD7E3ED) : Tokens.marca;
    return Semantics(
      selected: selecionado,
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: ListTile(
          selected: selecionado,
          selectedColor: escuro ? Colors.white : Tokens.marca,
          textColor: texto,
          iconColor: texto,
          selectedTileColor: escuro
              ? Colors.white.withValues(alpha: 0.12)
              : const Color(0xFFDDEEFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          leading: DecoratedBox(
            decoration: BoxDecoration(
              color: escuro
                  ? Colors.white.withValues(alpha: selecionado ? 0.12 : 0.06)
                  : (selecionado
                        ? const Color(0xFFDDEEFF)
                        : const Color(0xFFEDF4F8)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox.square(
              dimension: 42,
              child: Icon(destino.icone, size: 21),
            ),
          ),
          title: Text(
            destino.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            destino.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: escuro ? const Color(0xFF93AABD) : const Color(0xFF61788B),
              fontSize: 11,
            ),
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
      descricao:
          'Estados importantes do retrato atual, sem simular uma caixa de entrada.',
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
                  child: _LinhaFolha(
                    icone: Icons.card_giftcard_outlined,
                    titulo: resumo.livelo.alertasUltimaColeta == 0
                        ? 'Nenhum alerta na última coleta Livelo'
                        : '${resumo.livelo.alertasUltimaColeta} alertas na última coleta Livelo',
                    descricao:
                        '${resumo.livelo.lojasAcompanhadas} lojas acompanhadas · ${_rotuloEstadoResumo(resumo.livelo.estado)}',
                  ),
                ),
                const SizedBox(height: 10),
                CartaoRadar(
                  aoTocar: widget.aoAbrirInter,
                  child: _LinhaFolha(
                    icone: Icons.account_balance_outlined,
                    titulo: 'Banco Inter',
                    descricao:
                        'Cashback: ${_rotuloEstadoResumo(resumo.cashbackInter.estado)} · produtos: ${_rotuloEstadoResumo(resumo.produtos.estado)}',
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
              child: _LinhaFolha(
                icone: Icons.shield_outlined,
                titulo: 'Segurança e acesso',
                descricao: 'Sessão, convite e permissões',
              ),
            ),
            const SizedBox(height: 10),
            const CartaoRadar(
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
            dimension: 44,
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
