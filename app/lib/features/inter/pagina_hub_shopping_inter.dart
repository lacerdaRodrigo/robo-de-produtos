import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/componentes/resumo_fonte.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../administracao/botao_disparo.dart';
import '../produtos/pagina_produtos.dart';
import 'pagina_cashback_inter.dart';

/// Hub interno do Shopping Inter. Ele compartilha apenas a navegação: Cashback
/// e Produtos continuam usando controladores e workflows próprios.
class PaginaHubShoppingInter extends StatefulWidget {
  const PaginaHubShoppingInter({
    super.key,
    required this.api,
    required this.administrador,
    this.experienciaCompacta = false,
    this.ativa = true,
    this.abrirEmCompreDireto = false,
    this.aoVoltar,
  });

  final Api api;
  final bool administrador;
  final bool experienciaCompacta;
  final bool ativa;
  final bool abrirEmCompreDireto;
  final VoidCallback? aoVoltar;

  @override
  EstadoPaginaHubShoppingInter createState() => EstadoPaginaHubShoppingInter();
}

class EstadoPaginaHubShoppingInter extends State<PaginaHubShoppingInter> {
  final _navegador = GlobalKey<NavigatorState>();
  _ModalidadeInter? _modalidadePendente;

  void abrirProdutos() => _abrir(_ModalidadeInter.compreDireto);

  bool voltarRotaInterna() {
    final navegador = _navegador.currentState;
    if (navegador == null || !navegador.canPop()) return false;
    navegador.pop();
    return true;
  }

  void _abrir(_ModalidadeInter modalidade) {
    final navegador = _navegador.currentState;
    if (navegador == null) {
      _modalidadePendente = modalidade;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _modalidadePendente == null) return;
        final pendente = _modalidadePendente!;
        _modalidadePendente = null;
        _abrir(pendente);
      });
      return;
    }
    final (titulo, subtitulo, pagina, acao) = switch (modalidade) {
      _ModalidadeInter.sitesParceiros => (
        'Sites parceiros',
        'Banco Inter',
        PaginaCashbackInter(
          api: widget.api,
          administrador: widget.administrador,
          incorporada: true,
        ),
        BotaoDisparo(
          api: widget.api,
          dominio: 'inter',
          administrador: widget.administrador,
          rotulo: 'Atualizar Cashback',
          somenteIcone: true,
        ),
      ),
      _ModalidadeInter.compreDireto => (
        'Compre direto',
        'Banco Inter',
        PaginaProdutos(
          api: widget.api,
          administrador: widget.administrador,
          incorporada: true,
          experienciaCompacta: true,
          mostrarTituloInterno: false,
          navegadorParaDetalhes: _navegador,
        ),
        null,
      ),
    };
    navegador.push(
      MaterialPageRoute<void>(
        builder: (_) => _PaginaInternaShoppingInter(
          titulo: titulo,
          subtitulo: subtitulo,
          acao: acao,
          pagina: pagina,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navegador = Navigator(
      key: _navegador,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/lojas/shopping-inter'),
        builder: (_) => _HubShoppingInter(
          api: widget.api,
          administrador: widget.administrador,
          aoAbrir: _abrir,
          experienciaCompacta: widget.experienciaCompacta,
          abaInicial: widget.abrirEmCompreDireto ? 1 : 0,
          aoVoltar: widget.aoVoltar,
        ),
      ),
    );
    if (widget.aoVoltar != null) {
      // A Moldura compacta possui o único controlador do back do sistema.
      // Não monte outro NavigatorPopHandler, pois ambos receberiam o mesmo
      // gesto e poderiam consumir detalhe e catálogo em sequência.
      return navegador;
    }
    return NavigatorPopHandler<void>(
      enabled: widget.ativa,
      onPopWithResult: (_) => _navegador.currentState?.pop(),
      child: navegador,
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
    required this.abaInicial,
    this.aoVoltar,
  });

  final Api api;
  final bool administrador;
  final ValueChanged<_ModalidadeInter> aoAbrir;
  final bool experienciaCompacta;
  final int abaInicial;
  final VoidCallback? aoVoltar;

  @override
  State<_HubShoppingInter> createState() => _EstadoHubShoppingInterConteudo();
}

class _EstadoHubShoppingInterConteudo extends State<_HubShoppingInter> {
  late Future<ResumoInicio> _resumo;
  late var _aba = widget.abaInicial;

  @override
  void initState() {
    super.initState();
    _resumo = widget.api.resumo();
  }

  Future<void> _atualizarResumo() async {
    final resumo = widget.api.resumo();
    setState(() => _resumo = resumo);
    try {
      await resumo;
    } on Object {
      // O FutureBuilder apresenta a falha e mantém a ação de tentar novamente.
    }
  }

  void _tentarNovamente() => unawaited(_atualizarResumo());

  int? _totalAcompanhadas(ResumoInicio? resumo) =>
      resumo?.cashbackInter.lojasAcompanhadas;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return FutureBuilder<ResumoInicio>(
      future: _resumo,
      builder: (context, estado) {
        if (widget.experienciaCompacta) {
          return _BancoInterCompacto(
            carregandoResumo: estado.connectionState != ConnectionState.done,
            erroResumo: estado.hasError,
            aoTentarResumo: _tentarNovamente,
            aoAbrirModalidade: widget.aoAbrir,
            aoVoltar: widget.aoVoltar,
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
                FalhaResumo(aoTentarNovamente: _tentarNovamente),
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
                  cor: cores.acao,
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
    required this.carregandoResumo,
    required this.erroResumo,
    required this.aoTentarResumo,
    required this.aoAbrirModalidade,
    this.aoVoltar,
  });

  final bool carregandoResumo;
  final bool erroResumo;
  final VoidCallback aoTentarResumo;
  final ValueChanged<_ModalidadeInter> aoAbrirModalidade;
  final VoidCallback? aoVoltar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SafeArea(
      top: false,
      child: CustomScrollView(
        key: const Key('hub-shopping-inter'),
        slivers: [
          SliverToBoxAdapter(
            child: _CabecalhoNavegacaoInter(aoVoltar: aoVoltar),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spacing.five,
                end: tokens.spacing.five,
                top: tokens.spacing.four,
                bottom: tokens.spacing.six,
              ),
              child: const _CabecalhoBancoInter(),
            ),
          ),
          if (carregandoResumo)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          if (erroResumo)
            SliverPadding(
              padding: EdgeInsetsDirectional.only(
                start: tokens.spacing.five,
                end: tokens.spacing.five,
                top: tokens.spacing.two,
              ),
              sliver: SliverToBoxAdapter(
                child: FalhaResumo(aoTentarNovamente: aoTentarResumo),
              ),
            ),
          SliverPadding(
            padding: EdgeInsetsDirectional.only(
              start: tokens.spacing.five,
              end: tokens.spacing.five,
              bottom: tokens.spacing.six,
            ),
            sliver: SliverToBoxAdapter(
              child: _AbasModoInter(
                aoSelecionar: (aba) => aoAbrirModalidade(
                  aba == 0
                      ? _ModalidadeInter.sitesParceiros
                      : _ModalidadeInter.compreDireto,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AbasModoInter extends StatelessWidget {
  const _AbasModoInter({required this.aoSelecionar});

  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _AbaModoInter(
        key: const Key('modo-inter-cashback'),
        rotulo: 'Sites parceiros',
        descricao:
            'Descubra o cashback das lojas, confira as condições e acompanhe as mudanças.',
        icone: Icons.storefront_outlined,
        contador: null,
        selecionada: false,
        aoTocar: () => aoSelecionar(0),
      ),
      SizedBox(height: context.tokens.spacing.three),
      _AbaModoInter(
        key: const Key('modo-inter-compre-direto'),
        rotulo: 'Compre direto',
        descricao:
            'Encontre produtos, compare preços e consulte o histórico de cada oferta.',
        icone: Icons.shopping_bag_outlined,
        contador: null,
        selecionada: false,
        aoTocar: () => aoSelecionar(1),
      ),
    ],
  );
}

class _AbaModoInter extends StatelessWidget {
  const _AbaModoInter({
    Key? key,
    required this.rotulo,
    required this.descricao,
    required this.icone,
    required this.contador,
    required this.selecionada,
    required this.aoTocar,
  }) : _chaveCartao = key;

  final Key? _chaveCartao;
  final String rotulo;
  final String descricao;
  final IconData icone;
  final int? contador;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final contagem = contador == null ? null : '$contador no radar';
    return CartaoRadar(
      key: _chaveCartao,
      aoTocar: aoTocar,
      padding: EdgeInsets.all(context.tokens.spacing.five),
      comSombra: false,
      corDestaque: selecionada ? cores.acao : null,
      child: Semantics(
        selected: selecionada,
        button: true,
        onTap: aoTocar,
        onTapHint: 'Abrir $rotulo',
        label: '$rotulo. $descricao${contagem == null ? '' : '. $contagem'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: cores.acao.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                      context.tokens.radii.md,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(context.tokens.spacing.three),
                    child: Icon(icone, color: cores.acao),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: selecionada ? cores.acao : cores.textoSuave,
                ),
              ],
            ),
            SizedBox(height: context.tokens.spacing.four),
            Text(
              rotulo,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: context.tokens.spacing.one),
            Text(
              descricao,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cores.textoSuave),
            ),
            if (contagem != null) ...[
              SizedBox(height: context.tokens.spacing.three),
              Text(
                contagem,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selecionada ? cores.acao : cores.textoSuave,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CabecalhoNavegacaoInter extends StatelessWidget {
  const _CabecalhoNavegacaoInter({this.aoVoltar});

  final VoidCallback? aoVoltar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tokens = context.tokens;
    return Material(
      color: tema.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spacing.one,
            tokens.spacing.one / 2,
            tokens.spacing.four,
            tokens.spacing.one / 2,
          ),
          child: Row(
            children: [
              IconButton(
                key: const Key('voltar-programas-inter'),
                tooltip: 'Voltar para Explorar',
                onPressed: aoVoltar ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
              ),
              SizedBox(width: tokens.spacing.one),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Banco Inter',
                      style: tema.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Escolha a experiência',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: CoresRadar.de(context).textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CabecalhoBancoInter extends StatelessWidget {
  const _CabecalhoBancoInter();

  @override
  Widget build(BuildContext context) => const CabecalhoSecaoRadar(
    titulo: 'Como você quer comprar?',
    descricao: 'Dois caminhos, cada um com seus benefícios.',
  );
}

class _HeroInter extends StatelessWidget {
  const _HeroInter({required this.resumo, this.totalAcompanhadas});

  final ResumoInicio? resumo;
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
            'Cashback, parceiros e produtos em áreas separadas.',
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
                valor: '—',
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
              ? Tokens.action
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
      return const _ResumoModalidade([ChipResumo('Resumo indisponível')]);
    }
    return _ResumoModalidade([
      ChipResumo('${resumo.lojasAcompanhadas} lojas acompanhadas', ganho: true),
      ChipResumo(tituloEstadoResumo(resumo.estado)),
      ChipResumo(carimboResumo(resumo.ultimoSucessoEm, resumo.estado)),
    ]);
  }

  factory _ResumoModalidade.produtos(ResumoProdutos? resumo) {
    if (resumo == null) {
      return const _ResumoModalidade([ChipResumo('Resumo indisponível')]);
    }
    return _ResumoModalidade([
      ChipResumo('${resumo.lojasSelecionadas} lojas selecionadas'),
      ChipResumo('${resumo.produtosAtivos} produtos ativos', ganho: true),
      ChipResumo(carimboResumo(resumo.dadosMaisRecentesEm, resumo.estado)),
      ChipResumo(tituloEstadoResumo(resumo.estado)),
    ]);
  }
}

class _PaginaInternaShoppingInter extends StatelessWidget {
  const _PaginaInternaShoppingInter({
    required this.titulo,
    required this.pagina,
    this.subtitulo,
    this.acao,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? acao;
  final Widget pagina;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  tokens.spacing.one,
                  tokens.spacing.four,
                  tokens.spacing.four,
                  tokens.spacing.one / 2,
                ),
                child: Row(
                  key: const Key('cabecalho-interno-shopping-inter'),
                  children: [
                    IconButton(
                      key: const Key('voltar-para-shopping-inter'),
                      tooltip: 'Voltar para Shopping Inter',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (subtitulo != null)
                            Text(
                              subtitulo!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    if (acao != null) ...[
                      SizedBox(width: tokens.spacing.one),
                      acao!,
                    ],
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: context.tokens.colors.borda),
          Expanded(child: pagina),
        ],
      ),
    );
  }
}
