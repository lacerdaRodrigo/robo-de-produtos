import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../../features/inter/pagina_hub_shopping_inter.dart';
import '../../features/livelo/pagina_painel_livelo.dart';
import '../componentes/resumo_fonte.dart';
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
            FalhaResumo(aoTentarNovamente: aoTentarNovamente),
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
            cor: cores.acao,
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
      return const _ResumoFonte([ChipResumo('Resumo indisponível')]);
    }
    final temColeta = resumo.ultimoSucessoEm != null;
    return _ResumoFonte([
      ChipResumo('${resumo.lojasAcompanhadas} lojas acompanhadas', ganho: true),
      ChipResumo(
        temColeta
            ? '${resumo.alertasUltimaColeta} alertas na última coleta'
            : tituloEstadoResumo(resumo.estado),
        ganho: temColeta && resumo.alertasUltimaColeta > 0,
      ),
      ChipResumo(carimboResumo(resumo.ultimoSucessoEm, resumo.estado)),
    ]);
  }

  factory _ResumoFonte.inter({
    required ResumoCashbackInter? cashback,
    required ResumoProdutos? produtos,
  }) {
    if (cashback == null || produtos == null) {
      return const _ResumoFonte([ChipResumo('Resumo indisponível')]);
    }
    return _ResumoFonte([
      ChipResumo(
        '${cashback.lojasAcompanhadas} acompanhadas no Cashback',
        ganho: true,
      ),
      ChipResumo('Cashback: ${tituloEstadoResumo(cashback.estado)}'),
      ChipResumo(
        '${produtos.lojasSelecionadas} lojas selecionadas em Produtos',
      ),
      ChipResumo('Produtos: ${tituloEstadoResumo(produtos.estado)}'),
    ]);
  }
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
