import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
import '../componentes/menu_conta.dart';
import '../tema/tokens.dart';

/// Visão compacta dos acompanhamentos já conhecidos pelo resumo da API.
///
/// A API atual entrega contagens por fonte, mas ainda não entrega uma página
/// consolidada de itens. Por isso esta tela não inventa nomes, preços ou
/// links: mostra o retrato real disponível e oferece a entrada para cada
/// catálogo. O contrato que falta fica documentado em `docs/planos`.
class PaginaMeuRadar extends StatefulWidget {
  const PaginaMeuRadar({
    super.key,
    required this.api,
    required this.aoExplorar,
    required this.aoAbrirAlertas,
    this.ativa = true,
  });

  final Api api;
  final VoidCallback aoExplorar;
  final VoidCallback aoAbrirAlertas;
  final bool ativa;

  @override
  State<PaginaMeuRadar> createState() => _PaginaMeuRadarState();
}

class _PaginaMeuRadarState extends State<PaginaMeuRadar> {
  ResumoInicio? _resumo;
  Object? _erro;
  var _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(covariant PaginaMeuRadar antigo) {
    super.didUpdateWidget(antigo);
    if (widget.ativa && !antigo.ativa) _carregar(silencioso: true);
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso && mounted) setState(() => _carregando = true);
    try {
      final resumo = await widget.api.resumo();
      if (!mounted) return;
      setState(() {
        _resumo = resumo;
        _erro = null;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumo = _resumo;
    if (resumo == null && _carregando) {
      return const Carregando(mensagem: 'Carregando seu radar…');
    }
    if (resumo == null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar seus acompanhamentos.',
        voltar: _carregar,
      );
    }

    final total =
        resumo.livelo.lojasAcompanhadas +
        resumo.cashbackInter.lojasAcompanhadas +
        resumo.pichau.acompanhadas;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        key: const Key('pagina-meu-radar'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          context.tokens.spacing.four,
          context.tokens.spacing.five,
          context.tokens.spacing.four,
          context.tokens.spacing.eight,
        ),
        children: [
          const CabecalhoSecaoRadar(
            sobrelinha: 'Seu radar',
            titulo: 'O que merece sua atenção.',
            descricao:
                'Acompanhe mudanças de lojas, cashback e produtos a partir dos catálogos.',
          ),
          SizedBox(height: context.tokens.spacing.five),
          _ResumoAcompanhamentos(total: total),
          SizedBox(height: context.tokens.spacing.five),
          if (total == 0)
            _EstadoSemAcompanhamentos(aoExplorar: widget.aoExplorar)
          else ...[
            Text(
              'Por fonte',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: context.tokens.spacing.three),
            _FonteAcompanhamento(
              titulo: 'Livelo',
              detalhe: '${resumo.livelo.lojasAcompanhadas} lojas acompanhadas',
              aoTocar: widget.aoExplorar,
            ),
            SizedBox(height: context.tokens.spacing.three),
            _FonteAcompanhamento(
              titulo: 'Banco Inter',
              detalhe:
                  '${resumo.cashbackInter.lojasAcompanhadas} lojas com cashback',
              aoTocar: widget.aoExplorar,
            ),
            SizedBox(height: context.tokens.spacing.three),
            _FonteAcompanhamento(
              titulo: 'Pichau',
              detalhe: '${resumo.pichau.acompanhadas} produtos acompanhados',
              aoTocar: widget.aoExplorar,
            ),
          ],
          SizedBox(height: context.tokens.spacing.five),
          CartaoRadar(
            aoTocar: widget.aoAbrirAlertas,
            padding: EdgeInsets.all(context.tokens.spacing.four),
            child: LinhaContaRadar(
              icone: Icons.notifications_none_outlined,
              titulo: 'Central de alertas',
              descricao: 'Veja as mudanças registradas nos itens acompanhados.',
            ),
          ),
          if (_erro != null) ...[
            SizedBox(height: context.tokens.spacing.three),
            Text(
              'O retrato exibido é o último dado válido disponível.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CoresRadar.de(context).textoSuave,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResumoAcompanhamentos extends StatelessWidget {
  const _ResumoAcompanhamentos({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(context.tokens.radii.xl),
        border: Border.all(color: cores.borda),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.tokens.spacing.five),
        child: Row(
          children: [
            Icon(Icons.bookmark_added_outlined, color: cores.acao, size: 30),
            SizedBox(width: context.tokens.spacing.three),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    total == 1
                        ? 'acompanhamento no resumo'
                        : 'acompanhamentos no resumo',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
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

class _EstadoSemAcompanhamentos extends StatelessWidget {
  const _EstadoSemAcompanhamentos({required this.aoExplorar});

  final VoidCallback aoExplorar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return CartaoRadar(
      padding: EdgeInsets.all(context.tokens.spacing.five),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/illustrations/acompanhamentos.png',
            height: 124,
            fit: BoxFit.contain,
            semanticLabel: 'Ilustração de acompanhamentos',
          ),
          Icon(Icons.bookmark_border, color: cores.acao, size: 34),
          SizedBox(height: context.tokens.spacing.three),
          Text(
            'Seu radar ainda está vazio.',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: context.tokens.spacing.one),
          Text(
            'Explore uma fonte e acompanhe o que você quer revisar depois.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cores.textoSuave),
          ),
          SizedBox(height: context.tokens.spacing.four),
          FilledButton.icon(
            onPressed: aoExplorar,
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Explorar fontes'),
          ),
        ],
      ),
    );
  }
}

class _FonteAcompanhamento extends StatelessWidget {
  const _FonteAcompanhamento({
    required this.titulo,
    required this.detalhe,
    required this.aoTocar,
  });

  final String titulo;
  final String detalhe;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return CartaoRadar(
      aoTocar: aoTocar,
      padding: EdgeInsets.all(context.tokens.spacing.four),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: context.tokens.spacing.one),
                Text(
                  detalhe,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CoresRadar.de(context).textoSuave,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 17),
        ],
      ),
    );
  }
}
