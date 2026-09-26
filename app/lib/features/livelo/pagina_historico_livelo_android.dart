import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import 'formato_livelo.dart';

/// Histórico de leitura do parceiro do catálogo atual, exibido em folha V15.
class PaginaHistoricoLiveloAndroid extends StatefulWidget {
  const PaginaHistoricoLiveloAndroid({
    super.key,
    required this.api,
    required this.parceiro,
  });

  final Api api;
  final ParceiroCatalogoLivelo parceiro;

  @override
  State<PaginaHistoricoLiveloAndroid> createState() =>
      _EstadoPaginaHistoricoLiveloAndroid();
}

class _EstadoPaginaHistoricoLiveloAndroid
    extends State<PaginaHistoricoLiveloAndroid> {
  static const _itensPorPagina = 5;

  HistoricoLivelo? _historico;
  Object? _erro;
  var _carregando = true;
  var _pagina = 1;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final historico = await widget.api.historicoLivelo(
        widget.parceiro.idExterno,
      );
      if (mounted) {
        setState(() {
          _historico = historico;
          _pagina = 1;
        });
      }
    } catch (erro) {
      if (mounted) setState(() => _erro = erro);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => FolhaRadar(
    key: const Key('folha-historico-livelo'),
    titulo: 'Histórico · ${widget.parceiro.nome}',
    descricao: 'Últimas medições · até 30 registros · somente leitura',
    mostrarVoltar: false,
    child: Flexible(child: _corpo()),
  );

  Widget _corpo() {
    if (_carregando) {
      return const Center(child: Carregando(mensagem: 'Carregando histórico…'));
    }
    if (_erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o histórico desta loja.',
        voltar: _carregar,
      );
    }

    final medicoes = _historico!.medicoes;
    if (medicoes.isEmpty) {
      return EstadoVazio(
        mensagem:
            'Ainda não há medições históricas para ${widget.parceiro.nome}.',
      );
    }

    final inicio = (_pagina - 1) * _itensPorPagina;
    final fim = math.min(inicio + _itensPorPagina, medicoes.length);
    final pagina = medicoes.sublist(inicio, fim);
    final totalPaginas =
        (medicoes.length + _itensPorPagina - 1) ~/ _itensPorPagina;
    final tokens = context.tokens;

    return ListView(
      key: const Key('historico-livelo-android'),
      padding: EdgeInsetsDirectional.only(bottom: tokens.spacing.five),
      children: [
        for (final medicao in pagina) _LinhaMedicao(medicao: medicao),
        if (totalPaginas > 1) ...[
          SizedBox(height: tokens.spacing.three),
          _PaginacaoHistorico(
            pagina: _pagina,
            totalPaginas: totalPaginas,
            aoIrParaPagina: _irParaPagina,
          ),
        ],
      ],
    );
  }

  Future<void> _irParaPagina(int pagina) async {
    if (!mounted || pagina == _pagina) return;
    setState(() => _pagina = pagina);
  }
}

class _LinhaMedicao extends StatelessWidget {
  const _LinhaMedicao({required this.medicao});

  final MedicaoHistoricoLivelo medicao;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cores.borda)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: tokens.spacing.four),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dataHoraLivelo(medicao.momento).replaceFirst(', ', ' · '),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
            ),
            SizedBox(height: tokens.spacing.two),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    pontosHistoricoLivelo(medicao.pontos, moeda: medicao.moeda),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: tokens.spacing.two),
                const _StatusHistorico(),
              ],
            ),
            if (medicao.pontosClube != null) ...[
              SizedBox(height: tokens.spacing.one),
              Text(
                'Clube: ${pontosHistoricoLivelo(medicao.pontosClube, moeda: medicao.moeda)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusHistorico extends StatelessWidget {
  const _StatusHistorico();

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(tokens.radii.md),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.spacing.two,
          vertical: tokens.spacing.one,
        ),
        child: Text(
          'Completa',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: cores.textoSuave,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PaginacaoHistorico extends StatelessWidget {
  const _PaginacaoHistorico({
    required this.pagina,
    required this.totalPaginas,
    required this.aoIrParaPagina,
  });

  final int pagina;
  final int totalPaginas;
  final Future<void> Function(int pagina) aoIrParaPagina;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final anterior = pagina > 1;
    final proxima = pagina < totalPaginas;
    return Semantics(
      label: 'Paginação do histórico, página $pagina de $totalPaginas',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _botao(
            context,
            key: const Key('historico-pagina-anterior'),
            tooltip: 'Página anterior',
            icone: Icons.arrow_back,
            habilitado: anterior,
            aoTocar: () => aoIrParaPagina(pagina - 1),
          ),
          SizedBox(width: tokens.spacing.four),
          Text(
            '$pagina de $totalPaginas',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(width: tokens.spacing.four),
          _botao(
            context,
            key: const Key('historico-pagina-proxima'),
            tooltip: 'Próxima página',
            icone: Icons.arrow_forward,
            habilitado: proxima,
            aoTocar: () => aoIrParaPagina(pagina + 1),
          ),
        ],
      ),
    );
  }

  Widget _botao(
    BuildContext context, {
    required Key key,
    required String tooltip,
    required IconData icone,
    required bool habilitado,
    required VoidCallback aoTocar,
  }) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: habilitado ? aoTocar : null,
      icon: Icon(icone),
      style: IconButton.styleFrom(
        minimumSize: Size.square(tokens.sizes.touchTarget),
        maximumSize: Size.square(tokens.sizes.touchTarget),
        foregroundColor: cores.textoSuave,
        side: BorderSide(color: cores.borda),
        shape: const CircleBorder(),
      ),
    );
  }
}
