import 'package:flutter/material.dart';

import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';
import 'formato_produtos.dart';

class PaginaDetalheProduto extends StatefulWidget {
  const PaginaDetalheProduto({
    super.key,
    required this.produto,
    required this.aoAbrirHistorico,
    this.aoAcompanhar,
    this.aoAbrirNoShopping,
  });

  final ProdutoDireto produto;
  final VoidCallback aoAbrirHistorico;
  final Future<bool> Function()? aoAcompanhar;
  final VoidCallback? aoAbrirNoShopping;

  @override
  State<PaginaDetalheProduto> createState() => _EstadoPaginaDetalheProduto();
}

class _EstadoPaginaDetalheProduto extends State<PaginaDetalheProduto> {
  late var _acompanhado = widget.produto.acompanhado;
  var _salvandoAcompanhamento = false;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final produto = widget.produto;
    final status = _statusProduto(produto);
    final marcaCategoria = [
      produto.marca,
      produto.categoria,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');
    final cashback = [
      produto.cashbackPercentualTexto,
      produto.cashbackTexto,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          key: const Key('voltar-detalhe-produto'),
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalhes', style: tema.textTheme.titleMedium),
            Text(
              produto.lojaNome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.labelSmall?.copyWith(
                color: cores.textoSuave,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.aoAcompanhar != null)
            IconButton(
              key: const Key('acompanhar-detalhe-produto'),
              tooltip: _acompanhado
                  ? 'Deixar de acompanhar ${produto.nome}'
                  : 'Acompanhar ${produto.nome}',
              onPressed: _salvandoAcompanhamento
                  ? null
                  : _alternarAcompanhamento,
              icon: Icon(
                _acompanhado
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spacing.five,
          tokens.spacing.two,
          tokens.spacing.five,
          tokens.spacing.seven,
        ),
        children: [
          _SeloStatus(texto: status),
          SizedBox(height: tokens.spacing.three),
          Text(
            produto.nome,
            style: tema.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          if (marcaCategoria.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.two),
            Text(
              marcaCategoria,
              style: tema.textTheme.bodySmall?.copyWith(
                color: cores.textoSuave,
              ),
            ),
          ],
          SizedBox(height: tokens.spacing.five),
          _PainelPrecoDetalhe(produto: produto),
          SizedBox(height: tokens.spacing.five),
          if (cashback.isNotEmpty)
            _FatoDetalhe(rotulo: 'Cashback', valor: cashback),
          if (produto.precoLiquidoTexto != null)
            _FatoDetalhe(
              rotulo: 'Estimativa após cashback',
              valor: produto.precoLiquidoTexto!,
            ),
          _FatoDetalhe(rotulo: 'Loja', valor: produto.lojaNome),
          SizedBox(height: tokens.spacing.three),
          Text(
            produto.parcelamento == null
                ? 'Parcelamento não informado.'
                : 'Parcelamento disponível: ${produto.parcelamento}.',
            style: tema.textTheme.bodySmall?.copyWith(color: cores.textoSuave),
          ),
          SizedBox(height: tokens.spacing.three),
          if (cashback.isNotEmpty) const _AvisoCashbackDetalhe(),
          SizedBox(height: tokens.spacing.three),
          Row(
            children: [
              if (widget.aoAcompanhar != null)
                Expanded(
                  child: TextButton.icon(
                    key: const Key('acompanhar-detalhe-acao'),
                    onPressed: _salvandoAcompanhamento
                        ? null
                        : _alternarAcompanhamento,
                    icon: Icon(
                      _acompanhado ? Icons.check : Icons.notifications_none,
                      size: tokens.sizes.icon,
                    ),
                    label: Text(_acompanhado ? 'Acompanhando' : 'Acompanhar'),
                    style: TextButton.styleFrom(
                      minimumSize: Size(0, tokens.sizes.touchTarget),
                      foregroundColor: cores.acao,
                      backgroundColor: cores.acao.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radii.md),
                      ),
                    ),
                  ),
                ),
              if (widget.aoAcompanhar != null)
                SizedBox(width: tokens.spacing.two),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('historico-detalhe-produto'),
                  onPressed: widget.aoAbrirHistorico,
                  icon: Icon(Icons.history, size: tokens.sizes.icon),
                  label: const Text('Histórico'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(0, tokens.sizes.touchTarget),
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: tokens.spacing.two,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spacing.five),
          if (widget.aoAbrirNoShopping != null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('abrir-inter-detalhe-produto'),
                onPressed: widget.aoAbrirNoShopping,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir Inter'),
                style: FilledButton.styleFrom(
                  minimumSize: Size(double.infinity, tokens.sizes.touchTarget),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _alternarAcompanhamento() async {
    final callback = widget.aoAcompanhar;
    if (callback == null || _salvandoAcompanhamento) return;
    setState(() {
      _salvandoAcompanhamento = true;
      _acompanhado = !_acompanhado;
    });
    final sucesso = await callback();
    if (!mounted) return;
    setState(() {
      _salvandoAcompanhamento = false;
      if (!sucesso) _acompanhado = !_acompanhado;
    });
  }
}

class _SeloStatus extends StatelessWidget {
  const _SeloStatus({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final ativo = texto == 'Disponível';
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (ativo ? cores.ganho : cores.atencao).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: tokens.spacing.two,
            vertical: tokens.spacing.one,
          ),
          child: Text(
            texto,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ativo ? cores.ganho : cores.atencao,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PainelPrecoDetalhe extends StatelessWidget {
  const _PainelPrecoDetalhe({required this.produto});

  final ProdutoDireto produto;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final precoCheioDiferente =
        produto.precoCheioTexto != null &&
        produto.precoCheioTexto != produto.precoAtualTexto;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.acao.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(tokens.radii.lg),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(tokens.spacing.five),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preço de compra',
              style: tema.textTheme.labelSmall?.copyWith(
                color: cores.textoSuave,
              ),
            ),
            if (precoCheioDiferente)
              Text(
                produto.precoCheioTexto!,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            Text(
              produto.precoAtualTexto,
              style: tema.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: tokens.spacing.one),
            Text(
              dataHoraProduto(produto.atualizadaEm),
              style: tema.textTheme.bodySmall?.copyWith(
                color: cores.textoSuave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FatoDetalhe extends StatelessWidget {
  const _FatoDetalhe({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return Container(
      padding: EdgeInsetsDirectional.symmetric(vertical: tokens.spacing.three),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cores.borda)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: tema.textTheme.bodySmall?.copyWith(
                color: cores.textoSuave,
              ),
            ),
          ),
          SizedBox(width: tokens.spacing.four),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: tema.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoCashbackDetalhe extends StatelessWidget {
  const _AvisoCashbackDetalhe();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(tokens.radii.md),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(tokens.spacing.four),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: cores.texto,
              size: tokens.sizes.icon,
            ),
            SizedBox(width: tokens.spacing.two),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sobre o cashback',
                    style: tema.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.one),
                  Text(
                    'A estimativa após cashback depende das condições e da '
                    'elegibilidade. O valor cobrado é o preço de compra.',
                    style: tema.textTheme.bodySmall,
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

String _statusProduto(ProdutoDireto produto) {
  if (produto.ativo == false) return 'Fora do catálogo';
  if (produto.estoque == 0) return 'Esgotado';
  return 'Disponível';
}
