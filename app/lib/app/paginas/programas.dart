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
            sobrelinha: 'Catálogo do aplicativo',
            titulo: 'Serviços',
            descricao:
                'Pesquise um serviço e entre para encontrar as lojas disponíveis nele.',
          ),
          const SizedBox(height: 22),
          CampoBuscaRadar(
            chaveCampo: const Key('busca-programas'),
            controlador: _busca,
            dica: 'Pesquisar serviço',
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
                  'Serviços disponíveis',
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
            const EstadoVazio(mensagem: 'Nenhum serviço encontrado.')
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
    return CartaoRadar(
      aoTocar: programa.aoTocar,
      padding: EdgeInsets.zero,
      child: Padding(
        key: programa.chave,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Tokens.superficieForteEscura
                        : Tokens.plumSoft,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    programa.titulo == 'Livelo' ? 'LI' : 'BI',
                    style: TextStyle(
                      color: cores.marca,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Tokens.acaoFundoEscuro
                        : Tokens.actionSoft,
                    borderRadius: BorderRadius.circular(RaioRadar.pilula),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    child: Text(
                      programa.tipo,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cores.acao,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              programa.titulo,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              programa.descricao,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cores.textoSuave,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final capacidade in programa.capacidades)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cores.superficieAlternativa,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        capacidade,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cores.textoSuave,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (programa.estado != null) ...[
              const SizedBox(height: 10),
              Text(
                '${programa.detalhe} · ${programa.estado}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cores.textoSuave,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Divider(height: 1, color: cores.borda),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Abrir serviço',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Tokens.acaoForteEscura
                          : Tokens.actionStrong,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: cores.acao),
              ],
            ),
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
