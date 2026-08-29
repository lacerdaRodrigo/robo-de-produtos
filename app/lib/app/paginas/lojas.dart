import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../../features/administracao/botao_disparo.dart';
import '../../features/administracao/controlador_catalogo_administracao.dart';
import '../../features/inter/pagina_cashback_inter.dart';
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
      _ModalidadeInter.cashback => (
        'Cashback — Sites parceiros',
        PaginaCashbackInter(
          api: widget.api,
          administrador: widget.administrador,
          incorporada: true,
        ),
      ),
      _ModalidadeInter.produtos => (
        'Produtos — Compre direto',
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

enum _ModalidadeInter { cashback, produtos }

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
  var _aba = 0;

  @override
  void initState() {
    super.initState();
    _resumo = widget.api.resumo();
  }

  void _tentarNovamente() => setState(() => _resumo = widget.api.resumo());

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
            aba: _aba,
            resumo: estado.data,
            carregandoResumo: estado.connectionState != ConnectionState.done,
            erroResumo: estado.hasError,
            aoTentarResumo: _tentarNovamente,
            aoSelecionarAba: (aba) => setState(() => _aba = aba),
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
              _HeroInter(resumo: estado.data),
              const SizedBox(height: 12),
              _AbasInter(
                selecionada: _aba,
                aoSelecionar: (aba) => setState(() => _aba = aba),
              ),
              const SizedBox(height: 16),
              if (_aba == 0) ...[
                _AcessoModalidadeInter(
                  chaveAcao: const Key('abrir-cashback-inter'),
                  icone: Icons.percent_outlined,
                  cor: cores.integracaoInter,
                  titulo: 'Cashback — Sites parceiros',
                  descricao:
                      'Acompanhe as lojas parceiras e as condições de cashback do Inter.',
                  resumo: _ResumoModalidade.cashback(
                    estado.data?.cashbackInter,
                  ),
                  botaoAtualizacao: BotaoDisparo(
                    api: widget.api,
                    dominio: 'inter',
                    administrador: widget.administrador,
                    rotulo: 'Atualizar Cashback',
                  ),
                  aoAbrir: () => widget.aoAbrir(_ModalidadeInter.cashback),
                ),
                const SizedBox(height: 14),
                _AcessoModalidadeInter(
                  chaveAcao: const Key('abrir-produtos-inter'),
                  icone: Icons.inventory_2_outlined,
                  cor: cores.acao,
                  titulo: 'Produtos — Compre direto',
                  descricao:
                      'Pesquise o catálogo já coletado das lojas diretas selecionadas.',
                  resumo: _ResumoModalidade.produtos(estado.data?.produtos),
                  botaoAtualizacao: BotaoDisparo(
                    api: widget.api,
                    dominio: 'produtos_inter',
                    administrador: widget.administrador,
                    rotulo: 'Atualizar Produtos',
                  ),
                  aoAbrir: () => widget.aoAbrir(_ModalidadeInter.produtos),
                ),
              ] else if (_aba == 1)
                _ResumoInter(resumo: estado.data?.cashbackInter)
              else
                _AtualizacoesInter(resumo: estado.data),
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
    required this.aba,
    required this.resumo,
    required this.carregandoResumo,
    required this.erroResumo,
    required this.aoTentarResumo,
    required this.aoSelecionarAba,
  });

  final Api api;
  final bool administrador;
  final int aba;
  final ResumoInicio? resumo;
  final bool carregandoResumo;
  final bool erroResumo;
  final VoidCallback aoTentarResumo;
  final ValueChanged<int> aoSelecionarAba;

  @override
  Widget build(BuildContext context) {
    final cabecalho = _cabecalho();
    if (aba == 0) {
      return SafeArea(
        child: PaginaCashbackInter(
          api: api,
          administrador: administrador,
          incorporada: true,
          mostrarAtualizacao: false,
          chaveRolagemCompacta: const Key('hub-shopping-inter'),
          sliversAntesDoCashback: cabecalho,
        ),
      );
    }
    return SafeArea(
      child: _CatalogoSitesParceiros(
        api: api,
        administrador: administrador,
        chaveRolagem: const Key('hub-shopping-inter'),
        sliversAntesDoCatalogo: cabecalho,
      ),
    );
  }

  List<Widget> _cabecalho() => [
    SliverToBoxAdapter(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: CabecalhoSecaoRadar(
              sobrelinha: 'Shopping e cashback',
              titulo: 'Banco Inter',
              descricao:
                  'Escolha as lojas e acompanhe o cashback sem espalhar ações pelo menu.',
            ),
          ),
          if (carregandoResumo) const LinearProgressIndicator(),
          if (erroResumo)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _FalhaResumo(aoTentarNovamente: aoTentarResumo),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _HeroInter(resumo: resumo),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: _AbasInter(
              compacta: true,
              selecionada: aba,
              aoSelecionar: aoSelecionarAba,
            ),
          ),
        ],
      ),
    ),
  ];
}

class _HeroInter extends StatelessWidget {
  const _HeroInter({required this.resumo});

  final ResumoInicio? resumo;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final cashback = resumo?.cashbackInter.lojasAcompanhadas ?? 0;
    final produtos = resumo?.produtos.lojasSelecionadas ?? 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF08283F), Color(0xFF07556D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '● Integração saudável',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Suas lojas do Inter estão\nem um único lugar.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sites parceiros e produtos diretos continuam com coletas separadas.',
              style: TextStyle(color: Color(0xFFD7E9F2), height: 1.3),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _MetricaInter(valor: '$cashback', rotulo: 'acompanhadas'),
                const SizedBox(width: 8),
                _MetricaInter(valor: '$produtos', rotulo: 'produtos'),
                const SizedBox(width: 8),
                _MetricaInter(
                  valor: '—',
                  rotulo: 'melhor oferta',
                  cor: cores.ganho,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricaInter extends StatelessWidget {
  const _MetricaInter({required this.valor, required this.rotulo, this.cor});

  final String valor;
  final String rotulo;
  final Color? cor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 8, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: TextStyle(
                color: cor ?? Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              style: const TextStyle(color: Color(0xFFB5D3E1), fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AbasInter extends StatelessWidget {
  const _AbasInter({
    required this.selecionada,
    required this.aoSelecionar,
    this.compacta = false,
  });

  final int selecionada;
  final ValueChanged<int> aoSelecionar;
  final bool compacta;

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
          rotulo: compacta ? 'Cashback' : 'Escolher lojas',
          ativa: selecionada == 0,
          aoTocar: () => aoSelecionar(0),
        ),
        if (compacta)
          _AbaInter(
            rotulo: 'Sites parceiros',
            ativa: selecionada == 1,
            aoTocar: () => aoSelecionar(1),
          )
        else ...[
          _AbaInter(
            rotulo: 'Cashback',
            ativa: selecionada == 1,
            aoTocar: () => aoSelecionar(1),
          ),
          _AbaInter(
            rotulo: 'Atualizações',
            ativa: selecionada == 2,
            aoTocar: () => aoSelecionar(2),
          ),
        ],
      ],
    ),
  );
}

class _CatalogoSitesParceiros extends StatefulWidget {
  const _CatalogoSitesParceiros({
    required this.api,
    required this.administrador,
    this.sliversAntesDoCatalogo = const [],
    this.chaveRolagem,
  });

  final Api api;
  final bool administrador;
  final List<Widget> sliversAntesDoCatalogo;
  final Key? chaveRolagem;

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
    try {
      final favorita = !loja.favorita;
      await widget.api.alterarFavoritaInter(id: loja.id, favorita: favorita);
      _controlador.substituir(loja.id, loja.copiarCom(favorita: favorita));
    } finally {
      if (mounted) setState(() => _alterando.remove(loja.id));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => CustomScrollView(
      key: widget.chaveRolagem ?? const Key('catalogo-sites-parceiros-inter'),
      slivers: [
        ...widget.sliversAntesDoCatalogo,
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          sliver: SliverToBoxAdapter(child: _avisoCatalogo(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          sliver: SliverToBoxAdapter(child: _filtros(context)),
        ),
        if (!_controlador.carregandoInicial && _controlador.erroInicial == null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${_controlador.total} sites parceiros disponíveis',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CoresRadar.de(context).textoSuave,
                  fontWeight: FontWeight.w700,
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
      color: const Color(0xFFD7F8E5),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Tokens.ganho.withValues(alpha: 0.35)),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront_outlined, color: Tokens.ganho, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Este é o catálogo completo de Sites parceiros retornado pelo robô.\n'
              'Selecionar uma loja não inicia uma nova coleta.',
              style: TextStyle(color: Tokens.ganho, fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _filtros(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _FiltroCatalogo(
          rotulo: 'Todas as lojas',
          ativo: _filtro == 0,
          aoTocar: () => setState(() => _filtro = 0),
        ),
        const SizedBox(width: 8),
        _FiltroCatalogo(
          rotulo: 'Maior cashback',
          ativo: _filtro == 1,
          aoTocar: () => setState(() => _filtro = 1),
        ),
        const SizedBox(width: 8),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            for (final loja in lojas)
              _CartaoSiteParceiro(
                loja: loja,
                alterando: _alterando.contains(loja.id),
                podeAdministrar: widget.administrador,
                aoAcompanhar: () => _alternar(loja),
              ),
            if (_controlador.temProxima)
              Center(
                child: TextButton(
                  onPressed: _controlador.carregarMais,
                  child: const Text('Carregar mais'),
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
        (a, b) => (b.cashbackPrincipalValor ?? '').compareTo(
          a.cashbackPrincipalValor ?? '',
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
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      backgroundColor: ativo ? const Color(0xFFE1F1FF) : Colors.white,
      foregroundColor: ativo ? Tokens.marca : CoresRadar.de(context).textoSuave,
      shape: StadiumBorder(
        side: BorderSide(
          color: ativo ? Tokens.marca : CoresRadar.de(context).borda,
        ),
      ),
    ),
    child: Text(
      rotulo,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: CartaoRadar(
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
                    color: const Color(0xFFDDF3FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _iniciais(loja.nome),
                    style: const TextStyle(
                      color: Tokens.marca,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loja.nome,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Site parceiro · cashback publicado',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: cores.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  loja.ativa ? cashback : 'Indisponível',
                  style: tema.textTheme.titleSmall?.copyWith(
                    color: loja.ativa ? Tokens.ganho : cores.textoSuave,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Tokens.ganho, size: 7),
                      const SizedBox(width: 6),
                      Text(
                        loja.ativa
                            ? 'Disponível no catálogo'
                            : 'Indisponível no catálogo',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: cores.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
                if (alterando)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: podeAdministrar && loja.ativa
                        ? aoAcompanhar
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD7F8E5),
                      foregroundColor: Tokens.ganho,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    icon: Icon(
                      loja.favorita
                          ? Icons.check_circle_outline
                          : Icons.add_circle_outline,
                      size: 16,
                    ),
                    label: Text(loja.favorita ? 'Acompanhada' : 'Acompanhar'),
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
          backgroundColor: ativa ? Colors.white : Colors.transparent,
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
