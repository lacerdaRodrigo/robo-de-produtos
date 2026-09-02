import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../../features/administracao/botao_disparo.dart';
import '../../features/administracao/controlador_catalogo_administracao.dart';
import '../../features/inter/controlador_cashback_inter.dart';
import '../../features/inter/pagina_compre_direto_inter.dart';
import '../../features/inter/pagina_cashback_inter.dart';
import '../../features/inter/formato_cashback_inter.dart';
import '../../features/livelo/pagina_painel_livelo.dart';
import '../../features/produtos/pagina_produtos.dart';
import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
import '../tema/tokens.dart';

enum FonteLojas { livelo, cashbackInter }

/// Hub das fontes de lojas. Os resumos vêm somente da API e conservam os
/// relógios de Livelo, Cashback Inter e Produtos separados.
class PaginaLojas extends StatefulWidget {
  const PaginaLojas({
    super.key,
    required this.api,
    required this.administrador,
    required this.ativa,
  });

  final Api api;
  final bool administrador;
  final bool ativa;

  @override
  State<PaginaLojas> createState() => EstadoPaginaLojas();
}

class EstadoPaginaLojas extends State<PaginaLojas> {
  final _navegador = GlobalKey<NavigatorState>();

  void abrirFonte(FonteLojas fonte) {
    final navegador = _navegador.currentState;
    if (navegador == null) return;
    navegador.popUntil((rota) => rota.isFirst);
    final (titulo, pagina) = switch (fonte) {
      FonteLojas.livelo => (
        'Livelo',
        PaginaPainelLivelo(
          api: widget.api,
          administrador: widget.administrador,
        ),
      ),
      FonteLojas.cashbackInter => (
        'Shopping Inter',
        PaginaHubShoppingInter(
          api: widget.api,
          administrador: widget.administrador,
        ),
      ),
    };
    navegador.push(
      MaterialPageRoute<void>(
        builder: (_) => _PaginaInternaLojas(titulo: titulo, pagina: pagina),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<void>(
      enabled: widget.ativa,
      onPopWithResult: (_) => _navegador.currentState?.pop(),
      child: Navigator(
        key: _navegador,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/lojas'),
          builder: (context) => _HubLojas(api: widget.api, aoAbrir: abrirFonte),
        ),
      ),
    );
  }
}

/// Hub interno do Shopping Inter. Ele compartilha apenas a navegação: Cashback
/// e Produtos continuam usando controladores e workflows próprios.
class PaginaHubShoppingInter extends StatefulWidget {
  const PaginaHubShoppingInter({
    super.key,
    required this.api,
    required this.administrador,
    this.experienciaCompacta = false,
    this.ativa = true,
  });

  final Api api;
  final bool administrador;
  final bool experienciaCompacta;
  final bool ativa;

  @override
  State<PaginaHubShoppingInter> createState() => _EstadoHubShoppingInter();
}

class _EstadoHubShoppingInter extends State<PaginaHubShoppingInter> {
  final _navegador = GlobalKey<NavigatorState>();

  void _abrir(_ModalidadeInter modalidade) {
    final navegador = _navegador.currentState;
    if (navegador == null) return;
    final (titulo, pagina) = switch (modalidade) {
      _ModalidadeInter.sitesParceiros => (
        'Sites parceiros',
        PaginaCashbackInter(
          api: widget.api,
          administrador: widget.administrador,
          incorporada: true,
        ),
      ),
      _ModalidadeInter.compreDireto => (
        'Compre direto',
        PaginaProdutos(
          api: widget.api,
          administrador: widget.administrador,
          incorporada: true,
          mostrarTituloInterno: false,
        ),
      ),
    };
    navegador.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _PaginaInternaShoppingInter(titulo: titulo, pagina: pagina),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<void>(
      enabled: widget.ativa,
      onPopWithResult: (_) => _navegador.currentState?.pop(),
      child: Navigator(
        key: _navegador,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/lojas/shopping-inter'),
          builder: (_) => _HubShoppingInter(
            api: widget.api,
            administrador: widget.administrador,
            aoAbrir: _abrir,
            experienciaCompacta: widget.experienciaCompacta,
          ),
        ),
      ),
    );
  }
}

enum _ModalidadeInter { sitesParceiros, compreDireto }

class _HubShoppingInter extends StatefulWidget {
  const _HubShoppingInter({
    required this.api,
    required this.administrador,
    required this.aoAbrir,
    required this.experienciaCompacta,
  });

  final Api api;
  final bool administrador;
  final ValueChanged<_ModalidadeInter> aoAbrir;
  final bool experienciaCompacta;

  @override
  State<_HubShoppingInter> createState() => _EstadoHubShoppingInterConteudo();
}

class _EstadoHubShoppingInterConteudo extends State<_HubShoppingInter> {
  late Future<ResumoInicio> _resumo;
  var _ordenacaoDiretas = 'nome';
  var _filtroDiretas = 'todas';
  late final ControladorCashbackInter _cashback = ControladorCashbackInter(
    buscar: ({required q, required ordenar, required pagina}) =>
        widget.api.painelCashbackInter(q: q, ordenar: ordenar, pagina: pagina),
    buscarAcompanhadas: ({required q, required ordenar, required pagina}) =>
        widget.api.painelCashbackInter(
          q: q,
          ordenar: ordenar,
          pagina: pagina,
          apenasAcompanhadas: true,
        ),
  );
  late final ControladorCatalogoAdministracao<LojaDireto> _diretas =
      ControladorCatalogoAdministracao<LojaDireto>(
        buscar: ({required q, required pagina}) => widget.api.lojasDiretas(
          q: q,
          pagina: pagina,
          ordenar: _ordenacaoDiretas,
          filtro: _filtroDiretas,
        ),
        identificar: (loja) => loja.id,
      );
  String? _melhorOferta;
  var _aba = 0;
  var _variacaoAcompanhadas = 0;

  @override
  void initState() {
    super.initState();
    _resumo = widget.api.resumo();
    _carregarMelhorOferta();
  }

  Future<void> _carregarMelhorOferta() async {
    try {
      final pagina = await widget.api.painelCashbackInter(
        apenasAcompanhadas: true,
        porPagina: 1,
      );
      String? oferta;
      for (final loja in pagina.itens) {
        if (!loja.favorita || !loja.encontrada) continue;
        oferta = percentualCompactoInter(loja.cashbackPrincipalValor);
        if (oferta != null) break;
      }
      if (mounted) setState(() => _melhorOferta = oferta);
    } on Object {
      if (mounted) setState(() => _melhorOferta = null);
    }
  }

  @override
  void dispose() {
    _cashback.dispose();
    _diretas.dispose();
    super.dispose();
  }

  Future<void> _atualizarResumo() async {
    final resumo = widget.api.resumo();
    final melhorOferta = _carregarMelhorOferta();
    setState(() {
      _variacaoAcompanhadas = 0;
      _resumo = resumo;
    });
    try {
      await resumo;
    } on Object {
      // O FutureBuilder apresenta a falha e mantém a ação de tentar novamente.
    }
    await melhorOferta;
  }

  void _mudarConsultaDiretas({
    required String ordenar,
    required String filtro,
  }) {
    _ordenacaoDiretas = ordenar;
    _filtroDiretas = filtro;
  }

  void _tentarNovamente() => unawaited(_atualizarResumo());

  void _variarAcompanhadas(int variacao) {
    setState(() => _variacaoAcompanhadas += variacao);
  }

  int? _totalAcompanhadas(ResumoInicio? resumo) => resumo == null
      ? null
      : (resumo.cashbackInter.lojasAcompanhadas + _variacaoAcompanhadas).clamp(
          0,
          1 << 31,
        );

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return FutureBuilder<ResumoInicio>(
      future: _resumo,
      builder: (context, estado) {
        if (widget.experienciaCompacta) {
          return _BancoInterCompacto(
            api: widget.api,
            administrador: widget.administrador,
            controladorCashback: _cashback,
            controladorDiretas: _diretas,
            aba: _aba,
            resumo: estado.data,
            melhorOferta: _melhorOferta,
            carregandoResumo: estado.connectionState != ConnectionState.done,
            erroResumo: estado.hasError,
            totalAcompanhadas: _totalAcompanhadas(estado.data),
            aoTentarResumo: _tentarNovamente,
            aoAtualizarResumo: _atualizarResumo,
            ordenacaoDiretas: _ordenacaoDiretas,
            filtroDiretas: _filtroDiretas,
            aoMudarConsultaDiretas: _mudarConsultaDiretas,
            aoSelecionarAba: (aba) => setState(() => _aba = aba),
            aoAlterarAcompanhamento: _carregarMelhorOferta,
            aoVariarAcompanhadas: _variarAcompanhadas,
          );
        }
        return SafeArea(
          child: ListView(
            key: const Key('hub-shopping-inter'),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            children: [
              if (widget.experienciaCompacta)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: CabecalhoSecaoRadar(
                    sobrelinha: 'Shopping e cashback',
                    titulo: 'Banco Inter',
                    descricao:
                        'Escolha as lojas e acompanhe o cashback sem espalhar ações pelo menu.',
                  ),
                )
              else ...[
                Text(
                  'Shopping Inter',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Escolha entre cashback dos Sites parceiros e produtos do Compre direto.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: cores.textoSuave),
                ),
              ],
              if (estado.connectionState != ConnectionState.done) ...[
                const SizedBox(height: 20),
                const LinearProgressIndicator(),
              ],
              if (estado.hasError) ...[
                const SizedBox(height: 20),
                _FalhaResumo(aoTentarNovamente: _tentarNovamente),
              ],
              const SizedBox(height: 12),
              _HeroInter(
                resumo: estado.data,
                totalAcompanhadas: _totalAcompanhadas(estado.data),
              ),
              const SizedBox(height: 12),
              _AbasInter(
                selecionada: _aba,
                aoSelecionar: (aba) => setState(() => _aba = aba),
              ),
              const SizedBox(height: 16),
              if (_aba == 0) ...[
                _AcessoModalidadeInter(
                  chaveAcao: const Key('abrir-sites-parceiros-inter'),
                  icone: Icons.percent_outlined,
                  cor: cores.integracaoInter,
                  titulo: 'Sites parceiros',
                  descricao:
                      'Consulte cashback, acompanhe lojas e abra o destino no Banco Inter.',
                  resumo: _ResumoModalidade.cashback(
                    estado.data?.cashbackInter,
                  ),
                  botaoAtualizacao: BotaoDisparo(
                    api: widget.api,
                    dominio: 'inter',
                    administrador: widget.administrador,
                    rotulo: 'Atualizar Cashback',
                  ),
                  aoAbrir: () =>
                      widget.aoAbrir(_ModalidadeInter.sitesParceiros),
                ),
                const SizedBox(height: 16),
                _ResumoInter(resumo: estado.data?.cashbackInter),
              ] else ...[
                _AcessoModalidadeInter(
                  chaveAcao: const Key('abrir-produtos-inter'),
                  icone: Icons.inventory_2_outlined,
                  cor: cores.acao,
                  titulo: 'Compre direto',
                  descricao:
                      'Selecione lojas para coletar produtos exibidos na área Produtos.',
                  resumo: _ResumoModalidade.produtos(estado.data?.produtos),
                  botaoAtualizacao: BotaoDisparo(
                    api: widget.api,
                    dominio: 'produtos_inter',
                    administrador: widget.administrador,
                    rotulo: 'Atualizar Produtos',
                  ),
                  aoAbrir: () => widget.aoAbrir(_ModalidadeInter.compreDireto),
                ),
                const SizedBox(height: 16),
                _AtualizacoesInter(resumo: estado.data),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BancoInterCompacto extends StatelessWidget {
  const _BancoInterCompacto({
    required this.api,
    required this.administrador,
    required this.controladorCashback,
    required this.controladorDiretas,
    required this.aba,
    required this.resumo,
    required this.melhorOferta,
    required this.carregandoResumo,
    required this.erroResumo,
    required this.totalAcompanhadas,
    required this.aoTentarResumo,
    required this.aoAtualizarResumo,
    required this.ordenacaoDiretas,
    required this.filtroDiretas,
    required this.aoMudarConsultaDiretas,
    required this.aoSelecionarAba,
    required this.aoAlterarAcompanhamento,
    required this.aoVariarAcompanhadas,
  });

  final Api api;
  final bool administrador;
  final ControladorCashbackInter controladorCashback;
  final ControladorCatalogoAdministracao<LojaDireto> controladorDiretas;
  final int aba;
  final ResumoInicio? resumo;
  final String? melhorOferta;
  final bool carregandoResumo;
  final bool erroResumo;
  final int? totalAcompanhadas;
  final VoidCallback aoTentarResumo;
  final Future<void> Function() aoAtualizarResumo;
  final String ordenacaoDiretas;
  final String filtroDiretas;
  final void Function({required String ordenar, required String filtro})
  aoMudarConsultaDiretas;
  final ValueChanged<int> aoSelecionarAba;
  final VoidCallback aoAlterarAcompanhamento;
  final ValueChanged<int> aoVariarAcompanhadas;

  @override
  Widget build(BuildContext context) {
    final cabecalho = _cabecalho();
    return SafeArea(
      child: aba == 1
          ? PaginaCompreDiretoInter(
              key: const Key('compre-direto-inter'),
              api: api,
              administrador: administrador,
              controlador: controladorDiretas,
              sliversAntes: cabecalho,
              aoAtualizar: aoAtualizarResumo,
              ordenacaoInicial: ordenacaoDiretas,
              filtroInicial: filtroDiretas,
              aoMudarConsulta: aoMudarConsultaDiretas,
            )
          : PaginaCashbackInter(
              key: const Key('hub-shopping-inter'),
              api: api,
              controlador: controladorCashback,
              administrador: administrador,
              incorporada: true,
              mostrarAtualizacao: false,
              chaveRolagemCompacta: const PageStorageKey(
                'rolagem-cashback-inter',
              ),
              sliversAntesDoCashback: cabecalho,
              aoAtualizar: aoAtualizarResumo,
              aoAlterarAcompanhamento: aoAlterarAcompanhamento,
              aoVariarAcompanhadas: aoVariarAcompanhadas,
            ),
    );
  }

  List<Widget> _cabecalho() => [
    SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18, 22, 18, 20),
            child: _CabecalhoBancoInter(
              api: api,
              administrador: administrador,
              dominio: aba == 1 ? 'produtos_inter' : 'inter',
            ),
          ),
          if (carregandoResumo) const LinearProgressIndicator(),
          if (erroResumo)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
              child: _FalhaResumo(aoTentarNovamente: aoTentarResumo),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: _HeroInter(
              resumo: resumo,
              melhorOferta: melhorOferta,
              totalAcompanhadas: totalAcompanhadas,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 15),
            child: AbasRadar(
              rotulos: const ['Cashback', 'Compre direto'],
              selecionada: aba,
              aoSelecionar: aoSelecionarAba,
            ),
          ),
          if (aba == 1)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 13),
              child: _NotaSelecaoDireta(),
            ),
          if (aba == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _AvisoCatalogoInter(),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: controladorCashback,
                    builder: (context, _) {
                      if (controladorCashback.carregando ||
                          controladorCashback.erro != null) {
                        return const SizedBox.shrink();
                      }
                      final total = controladorCashback.totalItens;
                      return Text(
                        total == 1
                            ? '1 site parceiro disponível'
                            : '$total sites parceiros disponíveis',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: CoresRadar.de(context).textoSuave,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  ];
}

class _CabecalhoBancoInter extends StatelessWidget {
  const _CabecalhoBancoInter({
    required this.api,
    required this.administrador,
    required this.dominio,
  });

  final Api api;
  final bool administrador;
  final String dominio;

  Widget _botao() => BotaoDisparo(
    key: ValueKey('atualizar-dados-$dominio'),
    api: api,
    dominio: dominio,
    administrador: administrador,
    rotulo: 'Atualizar dados',
    destaque: true,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, restricoes) {
      final acaoLateral = administrador && restricoes.maxWidth >= 340;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabecalhoSecaoRadar(
            sobrelinha: 'Serviço',
            titulo: 'Banco Inter',
            descricao:
                'Consulte cashback ou escolha quais lojas terão produtos coletados.',
            acao: acaoLateral ? _botao() : null,
          ),
          if (administrador && !acaoLateral) ...[
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: _botao()),
          ],
        ],
      );
    },
  );
}

class _AvisoCatalogoInter extends StatelessWidget {
  const _AvisoCatalogoInter();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Tokens.ganhoFundoEscuro
          : Tokens.ganhoFundo,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Tokens.ganho.withValues(alpha: 0.35)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.storefront_outlined,
            color: CoresRadar.de(context).ganho,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este catálogo de Sites parceiros usa o último retrato válido. '
              'Navegar e filtrar não inicia uma nova coleta.',
              style: TextStyle(
                color: CoresRadar.de(context).ganho,
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

class _NotaSelecaoDireta extends StatelessWidget {
  const _NotaSelecaoDireta();

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Tokens.superficieForteEscura
            : Tokens.plumSoft,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: cores.marca.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: cores.marca, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escolha as lojas da próxima coleta',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecionar apenas salva a escolha. A coleta começa pelo fluxo de atualização existente.',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cores.textoSuave,
                      fontSize: 9,
                      height: 1.45,
                    ),
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

class _HeroInter extends StatelessWidget {
  const _HeroInter({
    required this.resumo,
    this.melhorOferta,
    this.totalAcompanhadas,
  });

  final ResumoInicio? resumo;
  final String? melhorOferta;
  final int? totalAcompanhadas;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final cashback =
        resumo == null ||
            resumo!.cashbackInter.estado == EstadoResumo.indisponivel
        ? '—'
        : '${totalAcompanhadas ?? resumo!.cashbackInter.lojasAcompanhadas}';
    final produtos =
        resumo == null || resumo!.produtos.estado == EstadoResumo.indisponivel
        ? '—'
        : '${resumo!.produtos.produtosAtivos}';
    final (estadoIntegracao, corEstado) = _estadoHeroInter(context, resumo);
    return CartaoRadar(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: corEstado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: corEstado,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox.square(dimension: 7),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      estadoIntegracao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: corEstado,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            melhorOferta == null
                ? 'Cashback, parceiros e produtos em áreas separadas.'
                : '$melhorOferta é o melhor cashback acompanhado agora.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 23,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sites parceiros e Compre direto continuam com regras e coletas independentes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cores.textoSuave,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _MetricaInter(
                key: const Key('inter-total-acompanhadas'),
                valor: cashback,
                rotulo: 'acompanhadas',
              ),
              const SizedBox(width: 7),
              _MetricaInter(valor: produtos, rotulo: 'produtos'),
              const SizedBox(width: 7),
              _MetricaInter(
                valor: melhorOferta ?? '—',
                rotulo: 'melhor oferta',
                cor: cores.ganho,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

(String, Color) _estadoHeroInter(BuildContext context, ResumoInicio? resumo) {
  final cores = CoresRadar.de(context);
  if (resumo == null) return ('Consultando integração', cores.atencao);
  final estados = <EstadoResumo>{
    resumo.cashbackInter.estado,
    resumo.produtos.estado,
  };
  if (estados.every((estado) => estado == EstadoResumo.atualizado)) {
    return ('Integração saudável', cores.ganho);
  }
  if (estados.contains(EstadoResumo.atualizando)) {
    return ('Integração atualizando', cores.atencao);
  }
  if (estados.every(
    (estado) =>
        estado == EstadoResumo.semDados || estado == EstadoResumo.indisponivel,
  )) {
    return ('Integração sem dados', cores.textoSuave);
  }
  return ('Integração com atenção', cores.atencao);
}

class _MetricaInter extends StatelessWidget {
  const _MetricaInter({
    super.key,
    required this.valor,
    required this.rotulo,
    this.cor,
  });

  final String valor;
  final String rotulo;
  final Color? cor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: CoresRadar.de(context).superficieAlternativa,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(9, 11, 9, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                color: cor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: CoresRadar.de(context).textoSuave,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AbasInter extends StatelessWidget {
  const _AbasInter({required this.selecionada, required this.aoSelecionar});

  final int selecionada;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CoresRadar.de(context).superficieAlternativa,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: CoresRadar.de(context).borda),
    ),
    child: Row(
      children: [
        _AbaInter(
          rotulo: 'Sites parceiros',
          ativa: selecionada == 0,
          aoTocar: () => aoSelecionar(0),
        ),
        _AbaInter(
          rotulo: 'Compre direto',
          ativa: selecionada == 1,
          aoTocar: () => aoSelecionar(1),
        ),
      ],
    ),
  );
}

class _CatalogoSitesParceiros extends StatefulWidget {
  const _CatalogoSitesParceiros({
    required this.api,
    required this.administrador,
  });

  final Api api;
  final bool administrador;

  @override
  State<_CatalogoSitesParceiros> createState() =>
      _EstadoCatalogoSitesParceiros();
}

class _EstadoCatalogoSitesParceiros extends State<_CatalogoSitesParceiros> {
  late final _controlador = ControladorCatalogoAdministracao<LojaCatalogoInter>(
    buscar: ({required q, required pagina}) =>
        widget.api.lojasInter(q: q, pagina: pagina),
    identificar: (loja) => loja.id,
  );
  final _campoBusca = TextEditingController();
  final _alterando = <String>{};
  var _filtro = 0;

  @override
  void initState() {
    super.initState();
    _controlador.carregarPrimeira();
  }

  @override
  void dispose() {
    _campoBusca.dispose();
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _alternar(LojaCatalogoInter loja) async {
    if (!widget.administrador || _alterando.contains(loja.id)) return;
    setState(() => _alterando.add(loja.id));
    final favorita = !loja.favorita;
    _controlador.substituir(loja.id, loja.copiarCom(favorita: favorita));
    try {
      await widget.api.alterarFavoritaInter(id: loja.id, favorita: favorita);
      if (mounted) {
        mostrarMensagemRadar(
          context,
          favorita
              ? 'Loja adicionada ao acompanhamento.'
              : 'Loja removida do acompanhamento.',
        );
      }
    } catch (_) {
      _controlador.substituir(loja.id, loja);
      if (mounted) {
        mostrarMensagemRadar(
          context,
          'Não foi possível salvar o acompanhamento.',
          sucesso: false,
        );
      }
    } finally {
      if (mounted) setState(() => _alterando.remove(loja.id));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => CustomScrollView(
      key: const Key('catalogo-sites-parceiros-inter'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 13),
          sliver: SliverToBoxAdapter(child: _avisoCatalogo(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverToBoxAdapter(
            child: CampoBuscaRadar(
              controlador: _campoBusca,
              chaveCampo: const Key('busca-sites-parceiros-inter'),
              dica: 'Buscar entre os sites parceiros',
              aoMudar: _controlador.mudarBusca,
              acao: IconButton(
                tooltip: 'Ordenar por maior cashback',
                onPressed: () => setState(() => _filtro = 1),
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(child: _filtros(context)),
        if (!_controlador.carregandoInicial && _controlador.erroInicial == null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${_controlador.total} sites parceiros disponíveis',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CoresRadar.de(context).textoSuave,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ..._conteudoSlivers(),
      ],
    ),
  );

  Widget _avisoCatalogo(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? Tokens.ganhoFundoEscuro
          : Tokens.ganhoFundo,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Tokens.ganho.withValues(alpha: 0.35)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.storefront_outlined,
            color: CoresRadar.de(context).ganho,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este é o catálogo completo de Sites parceiros retornado pelo robô. '
              'Selecionar uma loja não inicia uma nova coleta.',
              style: TextStyle(
                color: CoresRadar.de(context).ganho,
                fontSize: 10,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filtros(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(18, 11, 18, 0),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _FiltroCatalogo(
          rotulo: 'Todas as lojas',
          ativo: _filtro == 0,
          aoTocar: () => setState(() => _filtro = 0),
        ),
        const SizedBox(width: 7),
        _FiltroCatalogo(
          rotulo: 'Maior cashback',
          ativo: _filtro == 1,
          aoTocar: () => setState(() => _filtro = 1),
        ),
        const SizedBox(width: 7),
        _FiltroCatalogo(
          rotulo: 'Acompanhadas',
          ativo: _filtro == 2,
          aoTocar: () => setState(() => _filtro = 2),
        ),
      ],
    ),
  );

  List<Widget> _conteudoSlivers() {
    if (_controlador.carregandoInicial) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_controlador.erroInicial != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoFalha(
            mensagem: 'Não foi possível carregar os sites parceiros.',
            voltar: _controlador.carregarPrimeira,
          ),
        ),
      ];
    }
    final lojas = _lojasFiltradas();
    if (lojas.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoVazio(mensagem: 'Nenhum site parceiro foi encontrado.'),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 38),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            for (final loja in lojas)
              _CartaoSiteParceiro(
                loja: loja,
                alterando: _alterando.contains(loja.id),
                podeAdministrar: widget.administrador,
                aoAcompanhar: () => _alternar(loja),
              ),
            if (_controlador.carregandoMais)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_controlador.erroMais != null)
              Center(
                child: OutlinedButton(
                  onPressed: _controlador.carregarMais,
                  child: const Text('Tentar carregar mais'),
                ),
              )
            else if (_controlador.temProxima)
              Center(
                child: OutlinedButton(
                  onPressed: _controlador.carregarMais,
                  child: const Text('Carregar mais'),
                ),
              )
            else
              Text(
                'Todos os sites parceiros foram carregados.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CoresRadar.de(context).textoSuave,
                  fontSize: 10,
                ),
              ),
          ]),
        ),
      ),
    ];
  }

  List<LojaCatalogoInter> _lojasFiltradas() {
    var lojas = List<LojaCatalogoInter>.of(_controlador.itens);
    if (_filtro == 2) lojas = lojas.where((loja) => loja.favorita).toList();
    if (_filtro == 1) {
      lojas.sort(
        (a, b) => compararDecimaisInter(
          b.cashbackPrincipalValor,
          a.cashbackPrincipalValor,
        ),
      );
    }
    return lojas;
  }
}

class _FiltroCatalogo extends StatelessWidget {
  const _FiltroCatalogo({
    required this.rotulo,
    required this.ativo,
    required this.aoTocar,
  });

  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: aoTocar,
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 37),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      backgroundColor: ativo
          ? (Theme.of(context).brightness == Brightness.dark
                ? Tokens.acaoFundoEscuro
                : Tokens.acaoFundo)
          : Theme.of(context).colorScheme.surface,
      foregroundColor: ativo
          ? CoresRadar.de(context).acao
          : CoresRadar.de(context).textoSuave,
      shape: StadiumBorder(
        side: BorderSide(
          color: ativo
              ? CoresRadar.de(context).acao
              : CoresRadar.de(context).borda,
        ),
      ),
    ),
    child: Text(
      rotulo,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class _CartaoSiteParceiro extends StatelessWidget {
  const _CartaoSiteParceiro({
    required this.loja,
    required this.alterando,
    required this.podeAdministrar,
    required this.aoAcompanhar,
  });

  final LojaCatalogoInter loja;
  final bool alterando;
  final bool podeAdministrar;
  final VoidCallback aoAcompanhar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final cashback = loja.cashbackPrincipalTexto.isEmpty
        ? 'Oferta disponível'
        : loja.cashbackPrincipalTexto;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoRadar(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Theme.of(context).brightness == Brightness.dark
                            ? Tokens.acaoFundoEscuro
                            : Tokens.acaoFundo,
                        Theme.of(context).brightness == Brightness.dark
                            ? Tokens.cianoFundoEscuro
                            : Tokens.cianoFundo,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _iniciais(loja.nome),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFDFF8FF)
                          : Tokens.marca,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loja.nome,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Catálogo do Inter',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: cores.textoSuave,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    loja.ativa ? cashback : 'Indisponível',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: loja.ativa ? cores.ganho : cores.textoSuave,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Divider(height: 1),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: cores.ganho, size: 7),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          loja.ativa
                              ? 'Disponível no catálogo'
                              : 'Indisponível no catálogo',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: cores.textoSuave,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: podeAdministrar && loja.ativa && !alterando
                      ? aoAcompanhar
                      : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 35),
                    backgroundColor: loja.favorita
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Tokens.ganhoFundoEscuro
                              : Tokens.ganhoFundo)
                        : Colors.transparent,
                    foregroundColor: loja.favorita ? cores.ganho : cores.acao,
                    side: BorderSide(
                      color: loja.favorita ? Colors.transparent : cores.acao,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (alterando) ...[
                        const SizedBox.square(
                          dimension: 13,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 6),
                      ] else if (loja.favorita) ...[
                        const Icon(Icons.check, size: 13),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        alterando
                            ? 'Salvando…'
                            : loja.favorita
                            ? 'Acompanhada'
                            : 'Acompanhar',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}

class _AbaInter extends StatelessWidget {
  const _AbaInter({
    required this.rotulo,
    required this.ativa,
    required this.aoTocar,
  });

  final String rotulo;
  final bool ativa;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: TextButton(
        onPressed: aoTocar,
        style: TextButton.styleFrom(
          backgroundColor: ativa
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          foregroundColor: ativa
              ? Tokens.marcaClara
              : CoresRadar.de(context).textoSuave,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: Text(rotulo, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ),
  );
}

class _ResumoInter extends StatelessWidget {
  const _ResumoInter({required this.resumo});

  final ResumoCashbackInter? resumo;

  @override
  Widget build(BuildContext context) => CartaoRadar(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cashback',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'O percentual aparece como publicado pelo Inter. O Radar não mistura cashback com pontuação Livelo.',
        ),
        const SizedBox(height: 16),
        Text(
          '${resumo?.lojasAcompanhadas ?? 0} sites acompanhados',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class _AtualizacoesInter extends StatelessWidget {
  const _AtualizacoesInter({required this.resumo});

  final ResumoInicio? resumo;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CartaoRadar(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.check_circle_outline),
          title: const Text('Cashback concluído'),
          subtitle: Text(
            '${resumo?.cashbackInter.lojasEncontradasUltimaColeta ?? 0} lojas sincronizadas.',
          ),
        ),
      ),
      const SizedBox(height: 12),
      CartaoRadar(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sync),
          title: const Text('Produtos em andamento'),
          subtitle: Text(
            '${resumo?.produtos.produtosAtivos ?? 0} produtos ativos no catálogo.',
          ),
        ),
      ),
    ],
  );
}

class _AcessoModalidadeInter extends StatelessWidget {
  const _AcessoModalidadeInter({
    required this.chaveAcao,
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
    required this.resumo,
    required this.botaoAtualizacao,
    required this.aoAbrir,
  });

  final Key chaveAcao;
  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;
  final _ResumoModalidade resumo;
  final Widget botaoAtualizacao;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icone, color: cor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(descricao),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: resumo.itens),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: botaoAtualizacao),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    key: chaveAcao,
                    onPressed: aoAbrir,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      titulo.startsWith('Cashback')
                          ? 'Ver Cashback'
                          : 'Buscar produtos',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoModalidade {
  const _ResumoModalidade(this.itens);

  final List<Widget> itens;

  factory _ResumoModalidade.cashback(ResumoCashbackInter? resumo) {
    if (resumo == null) {
      return const _ResumoModalidade([_ChipResumo('Resumo indisponível')]);
    }
    return _ResumoModalidade([
      _ChipResumo(
        '${resumo.lojasAcompanhadas} lojas acompanhadas',
        ganho: true,
      ),
      _ChipResumo(_tituloEstado(resumo.estado)),
      _ChipResumo(_carimbo(resumo.ultimoSucessoEm, resumo.estado)),
    ]);
  }

  factory _ResumoModalidade.produtos(ResumoProdutos? resumo) {
    if (resumo == null) {
      return const _ResumoModalidade([_ChipResumo('Resumo indisponível')]);
    }
    return _ResumoModalidade([
      _ChipResumo('${resumo.lojasSelecionadas} lojas selecionadas'),
      _ChipResumo('${resumo.produtosAtivos} produtos ativos', ganho: true),
      _ChipResumo(_carimbo(resumo.dadosMaisRecentesEm, resumo.estado)),
      _ChipResumo(_tituloEstado(resumo.estado)),
    ]);
  }
}

class _PaginaInternaShoppingInter extends StatelessWidget {
  const _PaginaInternaShoppingInter({
    required this.titulo,
    required this.pagina,
  });

  final String titulo;
  final Widget pagina;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('voltar-para-shopping-inter'),
                    tooltip: 'Voltar para Shopping Inter',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: pagina),
      ],
    );
  }
}

class _HubLojas extends StatefulWidget {
  const _HubLojas({required this.api, required this.aoAbrir});

  final Api api;
  final ValueChanged<FonteLojas> aoAbrir;

  @override
  State<_HubLojas> createState() => _EstadoHubLojas();
}

class _EstadoHubLojas extends State<_HubLojas> {
  late Future<ResumoInicio> _resumo;

  @override
  void initState() {
    super.initState();
    _resumo = widget.api.resumo();
  }

  void _tentarNovamente() => setState(() => _resumo = widget.api.resumo());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResumoInicio>(
      future: _resumo,
      builder: (context, estado) => _ConteudoHubLojas(
        resumo: estado.data,
        carregando: estado.connectionState != ConnectionState.done,
        falhou: estado.hasError,
        aoTentarNovamente: _tentarNovamente,
        aoAbrir: widget.aoAbrir,
      ),
    );
  }
}

class _ConteudoHubLojas extends StatelessWidget {
  const _ConteudoHubLojas({
    required this.resumo,
    required this.carregando,
    required this.falhou,
    required this.aoTentarNovamente,
    required this.aoAbrir,
  });

  final ResumoInicio? resumo;
  final bool carregando;
  final bool falhou;
  final VoidCallback aoTentarNovamente;
  final ValueChanged<FonteLojas> aoAbrir;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return SafeArea(
      child: ListView(
        key: const Key('hub-lojas'),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        children: [
          Text('Lojas', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Escolha a fonte primeiro. Cada uma mantém suas próprias regras e ações.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cores.textoSuave),
          ),
          if (carregando) ...[
            const SizedBox(height: 20),
            const LinearProgressIndicator(),
          ],
          if (falhou) ...[
            const SizedBox(height: 20),
            _FalhaResumo(aoTentarNovamente: aoTentarNovamente),
          ],
          const SizedBox(height: 24),
          _AcessoFonte(
            key: const Key('abrir-lojas-livelo'),
            icone: Icons.star_outline,
            cor: cores.acao,
            titulo: 'Livelo',
            descricao:
                'Acompanhe pontos por real, promoções, Clube e sua regra de alerta.',
            resumo: _ResumoFonte.livelo(resumo?.livelo),
            aoAbrir: () => aoAbrir(FonteLojas.livelo),
          ),
          const SizedBox(height: 14),
          _AcessoFonte(
            key: const Key('abrir-lojas-inter'),
            icone: Icons.shopping_bag_outlined,
            cor: cores.integracaoInter,
            titulo: 'Shopping Inter',
            descricao:
                'Entre em Cashback dos Sites parceiros ou Produtos do Compre direto.',
            resumo: _ResumoFonte.inter(
              cashback: resumo?.cashbackInter,
              produtos: resumo?.produtos,
            ),
            aoAbrir: () => aoAbrir(FonteLojas.cashbackInter),
          ),
        ],
      ),
    );
  }
}

class _FalhaResumo extends StatelessWidget {
  const _FalhaResumo({required this.aoTentarNovamente});

  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Material(
      color: cores.atencao.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: cores.atencao),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Não foi possível carregar os resumos. Você ainda pode abrir cada fonte.',
              ),
            ),
            TextButton(
              onPressed: aoTentarNovamente,
              child: const Text('Tentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AcessoFonte extends StatelessWidget {
  const _AcessoFonte({
    super.key,
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
    required this.resumo,
    required this.aoAbrir,
  });

  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;
  final _ResumoFonte resumo;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoAbrir,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icone, color: cor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 14),
              Text(descricao),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: resumo.itens),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumoFonte {
  const _ResumoFonte(this.itens);

  final List<Widget> itens;

  factory _ResumoFonte.livelo(ResumoLivelo? resumo) {
    if (resumo == null) {
      return const _ResumoFonte([_ChipResumo('Resumo indisponível')]);
    }
    final temColeta = resumo.ultimoSucessoEm != null;
    return _ResumoFonte([
      _ChipResumo(
        '${resumo.lojasAcompanhadas} lojas acompanhadas',
        ganho: true,
      ),
      _ChipResumo(
        temColeta
            ? '${resumo.alertasUltimaColeta} alertas na última coleta'
            : _tituloEstado(resumo.estado),
        ganho: temColeta && resumo.alertasUltimaColeta > 0,
      ),
      _ChipResumo(_carimbo(resumo.ultimoSucessoEm, resumo.estado)),
    ]);
  }

  factory _ResumoFonte.inter({
    required ResumoCashbackInter? cashback,
    required ResumoProdutos? produtos,
  }) {
    if (cashback == null || produtos == null) {
      return const _ResumoFonte([_ChipResumo('Resumo indisponível')]);
    }
    return _ResumoFonte([
      _ChipResumo(
        '${cashback.lojasAcompanhadas} acompanhadas no Cashback',
        ganho: true,
      ),
      _ChipResumo('Cashback: ${_tituloEstado(cashback.estado)}'),
      _ChipResumo(
        '${produtos.lojasSelecionadas} lojas selecionadas em Produtos',
      ),
      _ChipResumo('Produtos: ${_tituloEstado(produtos.estado)}'),
    ]);
  }
}

class _ChipResumo extends StatelessWidget {
  const _ChipResumo(this.texto, {this.ganho = false});

  final String texto;
  final bool ganho;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final cor = ganho ? cores.ganho : cores.textoSuave;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _tituloEstado(EstadoResumo estado) => switch (estado) {
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

String _carimbo(String? instante, EstadoResumo estado) {
  if (instante == null) return _tituloEstado(estado);
  final data = DateTime.tryParse(instante)?.toLocal();
  if (data == null) return _tituloEstado(estado);
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final hora = data.hour.toString().padLeft(2, '0');
  final minuto = data.minute.toString().padLeft(2, '0');
  return 'Último sucesso $dia/$mes às $hora:$minuto';
}

class _PaginaInternaLojas extends StatelessWidget {
  const _PaginaInternaLojas({required this.titulo, required this.pagina});

  final String titulo;
  final Widget pagina;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('voltar-para-lojas'),
                    tooltip: 'Voltar para Lojas',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: pagina),
      ],
    );
  }
}
