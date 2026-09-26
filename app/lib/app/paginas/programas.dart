import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
import '../tema/tokens.dart';

/// Catálogo compacto das integrações reais do Radar.
///
/// A lista reúne somente as fontes conectadas; os catálogos abertos a partir
/// daqui continuam consultando seus próprios dados server-side.
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
  Widget build(BuildContext context) {
    final programas = <_ProgramaRadar>[
      _ProgramaRadar(
        chave: const Key('programa-livelo'),
        titulo: 'Livelo',
        descricao: 'Lojas parceiras e pontos por real gasto.',
        tipo: 'Pontos',
        capacidades: const ['Catálogo', 'Pontuação', 'Histórico'],
        estado: _resumo == null ? null : _rotuloEstado(_resumo!.livelo.estado),
        detalhe: _resumo == null
            ? null
            : '${_resumo!.livelo.lojasAcompanhadas} acompanhadas',
        aoTocar: widget.aoAbrirLivelo,
      ),
      _ProgramaRadar(
        chave: const Key('programa-inter'),
        titulo: 'Banco Inter',
        descricao: 'Cashback em lojas e compra de produtos.',
        tipo: 'Cashback + produtos',
        capacidades: const ['Sites parceiros', 'Cashback', 'Compre direto'],
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
        descricao: 'PCs gamer com preço Pix e cartão.',
        tipo: 'Tecnologia',
        capacidades: const ['Catálogo PC Gamer', 'Pix + cartão', 'Estoque'],
        estado: _resumo == null ? null : _rotuloEstado(_resumo!.pichau.estado),
        detalhe: _resumo == null
            ? null
            : '${_resumo!.pichau.produtosAtivos} produtos disponíveis',
        aoTocar: widget.aoAbrirPichau,
      ),
    ];

    return RefreshIndicator(
      onRefresh: _carregar,
      child: SafeArea(
        top: true,
        bottom: false,
        child: ListView(
          key: const Key('pagina-programas'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.only(
            start: context.tokens.spacing.five,
            top: context.tokens.spacing.four,
            end: context.tokens.spacing.five,
            bottom: context.tokens.spacing.six,
          ),
          children: [
            const _CabecalhoExplorar(),
            SizedBox(height: context.tokens.spacing.six),
            if (_carregando) ...[
              SizedBox(height: context.tokens.spacing.three),
              const LinearProgressIndicator(),
            ],
            if (_erro != null && _resumo == null) ...[
              SizedBox(height: context.tokens.spacing.three),
              EstadoFalha(
                mensagem:
                    'Não foi possível carregar os resumos. As fontes continuam disponíveis.',
                voltar: _carregar,
              ),
            ],
            for (var indice = 0; indice < programas.length; indice++) ...[
              _CartaoPrograma(programa: programas[indice]),
              if (indice != programas.length - 1)
                SizedBox(height: context.tokens.spacing.three),
            ],
          ],
        ),
      ),
    );
  }
}

class _CabecalhoExplorar extends StatelessWidget {
  const _CabecalhoExplorar();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CabecalhoMarcaRadar(
          key: Key('cabecalho-explorar'),
          rotulo: 'Explorar',
        ),
        SizedBox(height: tokens.spacing.six),
        Text(
          'ESCOLHA SEU CAMINHO',
          style: tema.textTheme.labelSmall?.copyWith(color: cores.textoSuave),
        ),
        SizedBox(height: tokens.spacing.two),
        Text(
          'Uma compra.\nMais possibilidades.',
          softWrap: true,
          style: tema.textTheme.headlineMedium,
        ),
        SizedBox(height: tokens.spacing.two),
        Text(
          'Encontre preços e benefícios por origem.',
          style: tema.textTheme.bodyMedium?.copyWith(color: cores.textoSuave),
        ),
      ],
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
    required this.estado,
    required this.detalhe,
    required this.aoTocar,
  });

  final Key chave;
  final String titulo;
  final String descricao;
  final String tipo;
  final List<String> capacidades;
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
