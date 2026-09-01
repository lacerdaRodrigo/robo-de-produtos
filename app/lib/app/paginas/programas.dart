import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
import '../tema/tokens.dart';

/// Agregador compacto das integrações reais do Radar.
///
/// A busca é local porque esta lista contém apenas os poucos programas
/// conectados; os catálogos abertos a partir daqui continuam server-side.
class PaginaProgramas extends StatefulWidget {
  const PaginaProgramas({
    super.key,
    required this.api,
    required this.aoAbrirLivelo,
    required this.aoAbrirInter,
    this.ativa = true,
  });

  final Api api;
  final VoidCallback aoAbrirLivelo;
  final VoidCallback aoAbrirInter;
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
        termos: 'livelo pontos lojas historico campanhas',
        icone: Icons.card_giftcard_outlined,
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
        termos: 'banco inter cashback sites parceiros compre direto produtos',
        icone: Icons.account_balance_outlined,
        estado: _resumo == null
            ? null
            : _rotuloEstado(_resumo!.cashbackInter.estado),
        detalhe: _resumo == null
            ? null
            : '${_resumo!.cashbackInter.lojasAcompanhadas} acompanhadas',
        aoTocar: widget.aoAbrirInter,
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
            sobrelinha: 'Catálogos conectados',
            titulo: 'Programas',
            descricao:
                'Acesse pontos, cashback e parceiros sem aumentar a navegação principal.',
          ),
          const SizedBox(height: 22),
          CampoBuscaRadar(
            chaveCampo: const Key('busca-programas'),
            controlador: _busca,
            dica: 'Buscar programa ou parceiro',
            aoMudar: (_) => setState(() {}),
          ),
          if (_carregando) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_erro != null && _resumo == null) ...[
            const SizedBox(height: 14),
            EstadoFalha(
              mensagem:
                  'Não foi possível carregar os resumos. Os programas continuam disponíveis.',
              voltar: _carregar,
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Programas disponíveis',
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
            const EstadoVazio(mensagem: 'Nenhum programa encontrado.')
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
    required this.termos,
    required this.icone,
    required this.estado,
    required this.detalhe,
    required this.aoTocar,
  });

  final Key chave;
  final String titulo;
  final String descricao;
  final String termos;
  final IconData icone;
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
    return CartaoRadar(
      aoTocar: programa.aoTocar,
      padding: EdgeInsets.zero,
      child: Padding(
        key: programa.chave,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Tokens.acaoFundoEscuro
                    : Tokens.acaoFundo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(programa.icone, color: cores.acao),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    programa.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    programa.descricao,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                  ),
                  if (programa.estado != null) ...[
                    const SizedBox(height: 8),
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
            Icon(Icons.chevron_right, color: cores.textoSuave),
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
