import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../../core/autenticacao/autenticador.dart';
import '../../core/versao_app.dart';
import '../../features/administracao/pagina_administracao.dart';
import '../../features/alertas/gerenciador_notificacoes.dart';
import '../../features/alertas/pagina_alertas.dart';
import '../../features/conta/paginas_conta.dart';
import '../../features/conta/pagina_aparencia.dart';
import '../../features/conta/pagina_laboratorio.dart';
import '../../features/conta/pagina_perfil.dart';
import '../../features/inter/pagina_hub_shopping_inter.dart';
import '../../features/livelo/pagina_catalogo_livelo_android.dart';
import '../../features/pichau/pagina_pichau.dart';
import '../../features/produtos/pagina_produtos.dart';
import '../autenticacao/pagina_entrar.dart';
import '../componentes/fundacao_visual.dart';
import '../identidade/logo_radar.dart';
import '../paginas/inicio.dart';
import '../paginas/lojas.dart';
import '../paginas/lugar.dart';
import '../paginas/meu_radar.dart';
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
    this.aoSessaoExpirada,
    this.autenticador,
    this.identificacaoConta,
    this.notificacoesAtivas = false,
  });

  final Api api;
  final bool administrador;
  final DateTime Function()? agora;
  final Future<void> Function()? aoSair;
  final Future<void> Function()? aoSessaoExpirada;
  final Autenticador? autenticador;
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
  GerenciadorNotificacoes? _notificacoes;
  bool _dialogSessaoAberto = false;
  bool _rotaSecundariaAberta = false;

  @override
  void initState() {
    super.initState();
    widget.api.cliente.aoSessaoExpirada = _sinalizarSessaoExpirada;
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
    widget.api.cliente.aoSessaoExpirada = null;
    unawaited(_notificacoes?.dispose() ?? Future<void>.value());
    super.dispose();
  }

  void _sinalizarSessaoExpirada() {
    if (!mounted || _dialogSessaoAberto) return;
    _dialogSessaoAberto = true;
    unawaited(
      showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final autenticador = widget.autenticador;
          if (autenticador != null) {
            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                ),
                child: PaginaEntrar(
                  autenticador: autenticador,
                  aoConcluir: () => Navigator.of(context).pop(true),
                ),
              ),
            );
          }
          return AlertDialog(
            title: const Text('Sessão expirada'),
            content: const Text(
              'Entre novamente para continuar acompanhando suas ofertas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Agora não'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Entrar novamente'),
              ),
            ],
          );
        },
      ).then((reautenticar) async {
        _dialogSessaoAberto = false;
        if (reautenticar == true && widget.autenticador == null) {
          await widget.aoSessaoExpirada?.call();
        }
      }),
    );
  }

  void _selecionar(Destino destino) {
    if (_selecionado == destino) return;
    setState(() => _selecionado = destino);
  }

  void _selecionarCompacto(DestinoCompacto destino) {
    final destinoReal = destino == DestinoCompacto.programas
        ? DestinoCompacto.explorar
        : destino;
    if (_selecionadoCompacto == destinoReal) return;
    setState(() {
      _visitadosCompactos.add(destinoReal);
      _selecionadoCompacto = destinoReal;
    });
  }

  void _voltarCompacto() {
    final destino = switch (_selecionadoCompacto) {
      DestinoCompacto.inicio => null,
      DestinoCompacto.explorar ||
      DestinoCompacto.radar ||
      DestinoCompacto.perfil => DestinoCompacto.inicio,
      DestinoCompacto.programas ||
      DestinoCompacto.livelo ||
      DestinoCompacto.inter ||
      DestinoCompacto.pichau => DestinoCompacto.explorar,
    };
    if (destino != null) _selecionarCompacto(destino);
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
      aoAbrirProgramas: () => _selecionarCompacto(DestinoCompacto.explorar),
      aoAbrirLivelo: () => _selecionarCompacto(DestinoCompacto.livelo),
      aoAbrirCashback: () => _selecionarCompacto(DestinoCompacto.inter),
      aoAbrirPichau: () => _selecionarCompacto(DestinoCompacto.pichau),
      aoAbrirAlertas: () => unawaited(_abrirAlertas()),
      aoAbrirRadar: () => _selecionarCompacto(DestinoCompacto.radar),
      aoAbrirProdutos: _abrirProdutosNoInter,
    ),
    _visitadosCompactos.contains(DestinoCompacto.explorar)
        ? PaginaProgramas(
            key: const PageStorageKey('programas-compacto'),
            aoAbrirLivelo: () => _selecionarCompacto(DestinoCompacto.livelo),
            aoAbrirInter: () => _selecionarCompacto(DestinoCompacto.inter),
            aoAbrirPichau: () => _selecionarCompacto(DestinoCompacto.pichau),
          )
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.radar)
        ? PaginaMeuRadar(
            key: const PageStorageKey('meu-radar-compacto'),
            api: widget.api,
            ativa: _selecionadoCompacto == DestinoCompacto.radar,
            aoExplorar: () => _selecionarCompacto(DestinoCompacto.explorar),
            aoAbrirAlertas: () => unawaited(_abrirAlertas()),
          )
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.perfil)
        ? _paginaPerfilCompacta()
        : const SizedBox.shrink(),
    const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.livelo)
        ? PaginaCatalogoLiveloAndroid(
            key: const PageStorageKey('livelo-catalogo-nativo'),
            api: widget.api,
            administrador: widget.administrador,
            aoAbrirAlertas: _abrirAlertas,
            aoVoltar: () => _selecionarCompacto(DestinoCompacto.explorar),
          )
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.inter)
        ? _PaginaProgramaInterna(
            chaveVoltar: const Key('voltar-programas-inter'),
            aoVoltar: () => _selecionarCompacto(DestinoCompacto.explorar),
            mostrarCabecalho: false,
            child: PaginaHubShoppingInter(
              key: _inter,
              api: widget.api,
              administrador: widget.administrador,
              experienciaCompacta: true,
              ativa: _selecionadoCompacto == DestinoCompacto.inter,
              aoVoltar: () => _selecionarCompacto(DestinoCompacto.explorar),
            ),
          )
        : const SizedBox.shrink(),
    _visitadosCompactos.contains(DestinoCompacto.pichau)
        ? _PaginaProgramaInterna(
            chaveVoltar: const Key('voltar-programas-pichau'),
            aoVoltar: () => _selecionarCompacto(DestinoCompacto.explorar),
            mostrarCabecalho: false,
            child: PaginaPichau(
              key: const PageStorageKey('pichau-catalogo-nativo'),
              api: widget.api,
              administrador: widget.administrador,
              ativa: _selecionadoCompacto == DestinoCompacto.pichau,
              aoVoltar: () => _selecionarCompacto(DestinoCompacto.explorar),
            ),
          )
        : const SizedBox.shrink(),
  ];

  Widget _paginaPerfilCompacta() => PaginaPerfil(
    key: const PageStorageKey('perfil-compacto'),
    api: widget.api,
    administrador: widget.administrador,
    identificacao: widget.identificacaoConta,
    aoAbrirAcompanhamentos: () => _selecionarCompacto(DestinoCompacto.radar),
    aoAbrirNotificacoes: () => _abrirRotaSecundaria<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaginaPreferenciasAlertas(
          api: widget.api,
          destinoSelecionado: _selecionadoCompacto.destinoDaBarra,
          aoNavegar: _navegarDeRotaSecundaria,
        ),
      ),
    ),
    aoAbrirAparencia: () => _abrirRotaSecundaria<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaginaAparencia(
          destinoSelecionado: _selecionadoCompacto.destinoDaBarra,
          aoNavegar: _navegarDeRotaSecundaria,
        ),
      ),
    ),
    aoAbrirAjuda: () => unawaited(_abrirAjuda()),
    aoAbrirProblema: () => unawaited(_abrirProblema()),
    aoAbrirRelatos: () => unawaited(_abrirMeusRelatos()),
    aoAbrirPrivacidade: () => unawaited(_abrirPrivacidade()),
    aoAbrirLaboratorio: () => _abrirRotaSecundaria<void>(
      MaterialPageRoute<void>(builder: (_) => const PaginaLaboratorio()),
    ),
    aoAdministrar: widget.administrador
        ? () => _abrirRotaSecundaria<void>(
            MaterialPageRoute<void>(
              builder: (_) =>
                  PaginaAdministracao(api: widget.api, administrador: true),
            ),
          )
        : null,
    aoSair: widget.aoSair == null ? null : _confirmarSaida,
  );

  Future<void> _confirmarSaida() async {
    final sair = await mostrarFolhaRadar<bool>(
      context,
      builder: (contexto) => FolhaRadar(
        titulo: 'Sair do Radar?',
        descricao:
            'Seus acompanhamentos ficam salvos. Os avisos deste aparelho serão desativados.',
        mostrarVoltar: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: const Key('cancelar-saida'),
                onPressed: () => Navigator.of(contexto).pop(false),
                child: const Text('Cancelar'),
              ),
            ),
            SizedBox(width: contexto.tokens.spacing.two),
            Expanded(
              child: FilledButton(
                key: const Key('confirmar-saida'),
                onPressed: () => Navigator.of(contexto).pop(true),
                child: const Text('Sair'),
              ),
            ),
          ],
        ),
      ),
    );
    if (sair != true || !mounted) return;
    await _notificacoes?.removerAtual();
    await widget.aoSair?.call();
  }

  void _abrirProdutosNoInter() {
    _selecionarCompacto(DestinoCompacto.inter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inter.currentState?.abrirProdutos();
    });
  }

  Future<void> _abrirAlertas({String? coleta}) => _abrirRotaSecundaria<void>(
    MaterialPageRoute<void>(
      builder: (_) => PaginaAlertas(
        api: widget.api,
        coletaInicial: coleta,
        destinoSelecionado: _selecionadoCompacto.destinoDaBarra,
        aoNavegar: _navegarDaCentral,
        aoAbrirItem: _abrirOrigemDoAlerta,
      ),
    ),
  );

  void _abrirOrigemDoAlerta(AlertaApp alerta) {
    final destino = switch (alerta.origem) {
      'livelo' => DestinoCompacto.livelo,
      'inter_cashback' || 'inter_produto' => DestinoCompacto.inter,
      'pichau' => DestinoCompacto.pichau,
      _ => null,
    };
    if (destino == null) {
      mostrarMensagemRadar(
        context,
        'A origem deste alerta não está disponível.',
      );
      return;
    }
    _navegarDaCentral(destino);
  }

  void _navegarDaCentral(DestinoCompacto destino) {
    Navigator.of(context).pop();
    _selecionarCompacto(destino);
  }

  Future<void> _abrirAjuda() => _abrirRotaSecundaria<void>(
    MaterialPageRoute<void>(
      builder: (_) => PaginaAjuda(
        api: widget.api,
        destinoSelecionado: _selecionadoCompacto.destinoDaBarra,
        aoNavegar: _navegarDeRotaSecundaria,
      ),
    ),
  );

  Future<void> _abrirPrivacidade() => _abrirRotaSecundaria<void>(
    MaterialPageRoute<void>(
      builder: (_) => PaginaPrivacidade(
        api: widget.api,
        destinoSelecionado: _selecionadoCompacto.destinoDaBarra,
        aoNavegar: _navegarDeRotaSecundaria,
      ),
    ),
  );

  Future<void> _abrirProblema() => _abrirRotaSecundaria<void>(
    MaterialPageRoute<void>(
      builder: (_) => PaginaRelatoProblema(
        api: widget.api,
        destinoSelecionado: _selecionadoCompacto.destinoDaBarra,
        aoNavegar: _navegarDeRotaSecundaria,
      ),
    ),
  );

  Future<void> _abrirMeusRelatos() => _abrirRotaSecundaria<void>(
    MaterialPageRoute<void>(
      builder: (_) => PaginaMeusRelatos(
        api: widget.api,
        destinoSelecionado: _selecionadoCompacto.destinoDaBarra,
        aoNavegar: _navegarDeRotaSecundaria,
      ),
    ),
  );

  void _navegarDeRotaSecundaria(DestinoCompacto destino) {
    Navigator.of(context).popUntil((rota) => rota.isFirst);
    _selecionarCompacto(destino);
  }

  Future<T?> _abrirRotaSecundaria<T>(Route<T> rota) async {
    setState(() => _rotaSecundariaAberta = true);
    try {
      return await Navigator.of(context).push<T>(rota);
    } finally {
      if (mounted) setState(() => _rotaSecundariaAberta = false);
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

        return PopScope<void>(
          canPop:
              _rotaSecundariaAberta ||
              _selecionadoCompacto == DestinoCompacto.inicio,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_rotaSecundariaAberta) {
              Navigator.of(context).pop();
              return;
            }
            if (_selecionadoCompacto == DestinoCompacto.inter &&
                _inter.currentState?.voltarRotaInterna() == true) {
              return;
            }
            _voltarCompacto();
          },
          child: Scaffold(
            body: conteudo,
            bottomNavigationBar: BarraInferiorRadar(
              selecionado: _selecionadoCompacto.destinoDaBarra,
              aoSelecionar: _selecionarCompacto,
            ),
          ),
        );
      },
    );
  }
}

class _PaginaProgramaInterna extends StatelessWidget {
  const _PaginaProgramaInterna({
    required this.chaveVoltar,
    required this.aoVoltar,
    required this.child,
    this.mostrarCabecalho = true,
  });

  final Key chaveVoltar;
  final VoidCallback aoVoltar;
  final Widget child;
  final bool mostrarCabecalho;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cabecalho = !mostrarCabecalho
        ? const SizedBox.shrink()
        : Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spacing.two,
                end: tokens.spacing.two,
                top: tokens.spacing.one,
              ),
              child: TextButton.icon(
                key: chaveVoltar,
                onPressed: aoVoltar,
                icon: Icon(Icons.arrow_back, size: tokens.sizes.icon),
                label: const Text('Explorar'),
              ),
            ),
          );

    return Column(
      children: [
        cabecalho,
        Expanded(child: child),
      ],
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
      color: Tokens.ink,
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
