import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/versao_app.dart';
import '../../features/administracao/pagina_administracao.dart';
import '../../features/produtos/pagina_produtos.dart';
import '../identidade/logo_radar.dart';
import '../paginas/inicio.dart';
import '../paginas/lojas.dart';
import '../paginas/lugar.dart';
import '../tema/tokens.dart';
import 'destinos.dart';

/// Moldura adaptativa do Radar.
///
/// Janelas compactas usam cabeçalho + gaveta e janelas a partir de 920 px usam
/// a lateral fixa. O mesmo [IndexedStack] permanece vivo nos dois modos para
/// preservar buscas, filtros, rotas internas e posição útil.
class MolduraRadar extends StatefulWidget {
  const MolduraRadar({super.key, required this.api, this.administrador = true});

  final Api api;
  final bool administrador;

  @override
  State<MolduraRadar> createState() => _EstadoMolduraRadar();
}

class _EstadoMolduraRadar extends State<MolduraRadar> {
  static const _larguraLayoutAmplo = 920.0;

  final _scaffold = GlobalKey<ScaffoldState>();
  final _lojas = GlobalKey<EstadoPaginaLojas>();
  Destino _selecionado = Destino.inicio;

  void _selecionar(Destino destino) {
    if (_selecionado == destino) return;
    setState(() => _selecionado = destino);
  }

  void _abrirFonte(FonteLojas fonte) {
    _selecionar(Destino.lojas);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lojas.currentState?.abrirFonte(fonte);
    });
  }

  List<Widget> get _paineis => <Widget>[
    PaginaInicio(
      api: widget.api,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        final amplo = limites.maxWidth >= _larguraLayoutAmplo;
        final conteudo = IndexedStack(
          key: const Key('moldura-paineis'),
          index: _selecionado.index,
          children: _paineis,
        );

        if (amplo) {
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

        return Scaffold(
          key: _scaffold,
          appBar: _CabecalhoCompacto(
            aoAbrirMenu: () => _scaffold.currentState?.openDrawer(),
            aoAbrirAlertas: () => _selecionar(Destino.alertas),
          ),
          drawer: GavetaRadar(
            selecionado: _selecionado,
            administrador: widget.administrador,
            aoSelecionar: _selecionar,
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
    required this.aoAbrirMenu,
    required this.aoAbrirAlertas,
  });

  final VoidCallback aoAbrirMenu;
  final VoidCallback aoAbrirAlertas;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
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
      title: const _AssinaturaCompacta(),
      centerTitle: true,
      actions: [
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
  const _AssinaturaCompacta();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Radar de Benefícios',
      header: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LogoRadar(tamanho: 32),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              'Radar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Tokens.marca,
                fontWeight: FontWeight.w900,
              ),
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
  });

  final Destino selecionado;
  final bool administrador;
  final ValueChanged<Destino> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: const Key('gaveta-principal'),
      width: MediaQuery.sizeOf(context).width.clamp(280.0, 320.0),
      shape: const RoundedRectangleBorder(),
      backgroundColor: Tokens.marcaProfunda,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 10, 22),
              child: Row(
                children: [
                  const LogoRadar(tamanho: 44, sobreFundoEscuro: true),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Radar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final destino in Destino.values)
                    _ItemNavegacao(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: _RodapeVersao(administrador: administrador),
            ),
          ],
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          administrador ? 'Acesso administrador' : 'Acesso padrão',
          style: const TextStyle(color: Color(0xFF93AABD), fontSize: 12),
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
                style: const TextStyle(color: Color(0xFF93AABD), fontSize: 11),
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
