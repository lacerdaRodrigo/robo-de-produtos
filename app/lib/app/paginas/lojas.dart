import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../../features/administracao/botao_disparo.dart';
import '../../features/inter/pagina_cashback_inter.dart';
import '../../features/livelo/pagina_painel_livelo.dart';
import '../../features/produtos/pagina_produtos.dart';
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
  });

  final Api api;
  final bool administrador;

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
      onPopWithResult: (_) => _navegador.currentState?.pop(),
      child: Navigator(
        key: _navegador,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/lojas/shopping-inter'),
          builder: (_) => _HubShoppingInter(
            api: widget.api,
            administrador: widget.administrador,
            aoAbrir: _abrir,
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
  });

  final Api api;
  final bool administrador;
  final ValueChanged<_ModalidadeInter> aoAbrir;

  @override
  State<_HubShoppingInter> createState() => _EstadoHubShoppingInterConteudo();
}

class _EstadoHubShoppingInterConteudo extends State<_HubShoppingInter> {
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
      builder: (context, estado) => SafeArea(
        child: ListView(
          key: const Key('hub-shopping-inter'),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
          children: [
            Text(
              'Shopping Inter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Escolha entre cashback dos Sites parceiros e produtos do Compre direto.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF60758A)),
            ),
            if (estado.connectionState != ConnectionState.done) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(),
            ],
            if (estado.hasError) ...[
              const SizedBox(height: 20),
              _FalhaResumo(aoTentarNovamente: _tentarNovamente),
            ],
            const SizedBox(height: 24),
            _AcessoModalidadeInter(
              chaveAcao: const Key('abrir-cashback-inter'),
              icone: Icons.percent_outlined,
              cor: const Color(0xFF087E8B),
              titulo: 'Cashback — Sites parceiros',
              descricao:
                  'Acompanhe as lojas parceiras e as condições de cashback do Inter.',
              resumo: _ResumoModalidade.cashback(estado.data?.cashbackInter),
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
              cor: Tokens.marcaClara,
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
          ],
        ),
      ),
    );
  }
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
            botaoAtualizacao,
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              key: chaveAcao,
              onPressed: aoAbrir,
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                titulo.startsWith('Cashback')
                    ? 'Ver Cashback'
                    : 'Buscar produtos',
              ),
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
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF60758A)),
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
            cor: Tokens.marcaClara,
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
            cor: const Color(0xFF087E8B),
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
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF4E5),
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Tokens.atencao),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Não foi possível carregar os resumos. Você ainda pode abrir cada fonte.',
            ),
          ),
          TextButton(onPressed: aoTentarNovamente, child: const Text('Tentar')),
        ],
      ),
    ),
  );
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: ganho ? const Color(0xFFE3F3E8) : const Color(0xFFF0F4F7),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      texto,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: ganho ? Tokens.ganho : const Color(0xFF4D6274),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
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
