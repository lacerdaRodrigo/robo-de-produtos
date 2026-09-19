import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
import '../tema/tokens.dart';

/// Catálogo compacto das integrações reais do Radar.
///
/// A busca é local porque esta lista contém apenas os poucos programas
/// conectados; os catálogos abertos a partir daqui continuam server-side.
class PaginaProgramas extends StatefulWidget {
  const PaginaProgramas({
    super.key,
    required this.api,
    required this.aoAbrirLivelo,
    required this.aoAbrirInter,
    required this.aoAbrirPichau,
    this.ativa = true,
  });

  final Api api;
  final VoidCallback aoAbrirLivelo;
  final VoidCallback aoAbrirInter;
  final VoidCallback aoAbrirPichau;
  final bool ativa;

  @override
  State<PaginaProgramas> createState() => _EstadoPaginaProgramas();
}

class _EstadoPaginaProgramas extends State<PaginaProgramas> {
  final _busca = TextEditingController();
  ResumoInicio? _resumo;
  Object? _erro;
  var _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(covariant PaginaProgramas antigo) {
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
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final termo = _busca.text.trim().toLowerCase();
    final programas = <_ProgramaRadar>[
      _ProgramaRadar(
        chave: const Key('programa-livelo'),
        titulo: 'Livelo',
        descricao: 'Pontos, lojas acompanhadas e histórico',
        tipo: 'Pontos',
        capacidades: const ['Catálogo', 'Pontuação', 'Histórico'],
        termos: 'livelo pontos lojas historico campanhas',
        estado: _resumo == null ? null : _rotuloEstado(_resumo!.livelo.estado),
        detalhe: _resumo == null
            ? null
            : '${_resumo!.livelo.lojasAcompanhadas} acompanhadas',
        aoTocar: widget.aoAbrirLivelo,
      ),
      _ProgramaRadar(
        chave: const Key('programa-inter'),
        titulo: 'Banco Inter',
        descricao: 'Cashback, Sites parceiros e Compre direto',
        tipo: 'Cashback + produtos',
        capacidades: const ['Sites parceiros', 'Cashback', 'Compre direto'],
        termos: 'banco inter cashback sites parceiros compre direto produtos',
        estado: _resumo == null
            ? null
            : _rotuloEstado(_resumo!.cashbackInter.estado),
        detalhe: _resumo == null
            ? null
            : '${_resumo!.cashbackInter.lojasAcompanhadas} acompanhadas',
        aoTocar: widget.aoAbrirInter,
      ),
      _ProgramaRadar(
        chave: const Key('programa-pichau'),
        titulo: 'Pichau',
        descricao: 'Catálogo de PCs Gamer com preços e disponibilidade',
        tipo: 'PC Gamer',
        capacidades: const ['Catálogo PC Gamer', 'Pix + cartão', 'Estoque'],
        termos: 'pichau pc gamer computadores catalogo preços disponibilidade',
        estado: _resumo == null ? null : _rotuloEstado(_resumo!.pichau.estado),
        detalhe: _resumo == null
            ? null
            : '${_resumo!.pichau.produtosAtivos} produtos disponíveis',
        aoTocar: widget.aoAbrirPichau,
      ),
    ];
    final visiveis = programas
        .where((programa) => programa.termos.contains(termo))
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        key: const Key('pagina-programas'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          const CabecalhoSecaoRadar(
            sobrelinha: 'Descubra novas possibilidades',
            titulo: 'Uma compra. Mais possibilidades.',
            descricao:
                'Explore fontes, encontre oportunidades e escolha onde continuar.',
          ),
          const SizedBox(height: 22),
          CampoBuscaRadar(
            chaveCampo: const Key('busca-programas'),
            controlador: _busca,
            dica: 'Pesquisar fonte',
            aoMudar: (_) => setState(() {}),
            somenteBusca: true,
          ),
          if (_carregando) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_erro != null && _resumo == null) ...[
            const SizedBox(height: 14),
            EstadoFalha(
              mensagem:
                  'Não foi possível carregar os resumos. As fontes continuam disponíveis.',
              voltar: _carregar,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fontes disponíveis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${visiveis.length}',
                style: TextStyle(
                  color: CoresRadar.de(context).textoSuave,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visiveis.isEmpty)
            const EstadoVazio(mensagem: 'Nenhuma fonte encontrada.')
          else
            for (var indice = 0; indice < visiveis.length; indice++) ...[
              _CartaoPrograma(programa: visiveis[indice]),
              if (indice != visiveis.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _ProgramaRadar {
  const _ProgramaRadar({
    required this.chave,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.capacidades,
    required this.termos,
    required this.estado,
    required this.detalhe,
    required this.aoTocar,
  });

  final Key chave;
  final String titulo;
  final String descricao;
  final String tipo;
  final List<String> capacidades;
  final String termos;
  final String? estado;
  final String? detalhe;
  final VoidCallback aoTocar;
}

class _CartaoPrograma extends StatelessWidget {
  const _CartaoPrograma({required this.programa});

  final _ProgramaRadar programa;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final icone = switch (programa.titulo) {
      'Livelo' => Icons.auto_awesome_outlined,
      'Pichau' => Icons.desktop_windows_outlined,
      _ => Icons.storefront_outlined,
    };
    return CartaoRadar(
      aoTocar: programa.aoTocar,
      padding: EdgeInsets.all(tokens.spacing.five),
      child: Semantics(
        button: true,
        label: 'Abrir ${programa.titulo}: ${programa.descricao}',
        child: Column(
          key: programa.chave,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: cores.acao.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(tokens.radii.md),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(tokens.spacing.three),
                    child: Icon(icone, color: cores.acao),
                  ),
                ),
                SizedBox(width: tokens.spacing.three),
                Expanded(
                  child: Text(
                    programa.tipo,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cores.textoSuave,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: tokens.spacing.two),
                Icon(Icons.arrow_forward, color: cores.acao),
              ],
            ),
            SizedBox(height: tokens.spacing.five),
            Text(
              programa.titulo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: tokens.spacing.two),
            Text(
              programa.descricao,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cores.textoSuave),
            ),
            SizedBox(height: tokens.spacing.four),
            Wrap(
              spacing: tokens.spacing.one,
              runSpacing: tokens.spacing.one,
              children: [
                for (final capacidade in programa.capacidades)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cores.superficieAlternativa,
                      borderRadius: BorderRadius.circular(tokens.radii.md),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spacing.two,
                        vertical: tokens.spacing.one,
                      ),
                      child: Text(
                        capacidade,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cores.textoSuave,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (programa.estado != null) ...[
              SizedBox(height: tokens.spacing.three),
              Text(
                '${programa.detalhe} · ${programa.estado}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cores.textoSuave,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _rotuloEstado(EstadoResumo estado) => switch (estado) {
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
