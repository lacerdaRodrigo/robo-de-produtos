import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';

class CartaoProduto extends StatelessWidget {
  const CartaoProduto({
    super.key,
    required this.produto,
    required this.aoAbrirDetalhes,
    this.aoAbrirHistorico,
    this.aoAbrirNoShopping,
    this.aoAcompanhar,
    this.compacto = false,
    this.mostrarLoja = true,
    this.destaque = false,
  });

  final ProdutoDireto produto;
  final VoidCallback aoAbrirDetalhes;
  final VoidCallback? aoAbrirHistorico;
  final VoidCallback? aoAbrirNoShopping;
  final VoidCallback? aoAcompanhar;
  final bool compacto;
  final bool mostrarLoja;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    if (compacto) return _compacto(context);
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final precoCheioDiferente =
        produto.precoCheioTexto != null &&
        produto.precoCheioTexto != produto.precoAtualTexto;
    return Semantics(
      label: 'Produto ${produto.nome}, da loja ${produto.lojaNome}',
      child: CartaoRadar(
        corDestaque: cores.acao,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produto.nome, style: tema.textTheme.titleMedium),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(produto.lojaNome),
                      ),
                    ],
                  ),
                ),
                if (aoAcompanhar != null)
                  IconButton(
                    key: ValueKey(
                      'alerta-produto-${produto.lojaSlug}-${produto.idExterno}',
                    ),
                    tooltip: produto.acompanhado
                        ? 'Deixar de acompanhar ${produto.nome}'
                        : 'Acompanhar ${produto.nome}',
                    onPressed: aoAcompanhar,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      produto.acompanhado
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_outlined,
                    ),
                  ),
              ],
            ),
            if (produto.marca != null || produto.categoria != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    produto.marca,
                    produto.categoria,
                  ].whereType<String>().join(' · '),
                ),
              ),
            if (precoCheioDiferente)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  produto.precoCheioTexto!,
                  style: tema.textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            _ValorComercial(
              rotulo: 'Preço atual',
              valor: produto.precoAtualTexto,
              estilo: tema.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (produto.descontoTexto != null ||
                produto.descontoPercentualTexto != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  [
                    produto.descontoTexto,
                    produto.descontoPercentualTexto,
                  ].whereType<String>().join(' · '),
                ),
              ),
            if (produto.cashbackTexto != null ||
                produto.cashbackPercentualTexto != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  [
                    produto.cashbackTexto,
                    produto.cashbackPercentualTexto,
                  ].whereType<String>().join(' · '),
                  style: tema.textTheme.titleSmall?.copyWith(
                    color: cores.ganho,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (produto.precoLiquidoTexto != null)
              _ValorComercial(
                rotulo: 'Após cashback',
                valor: produto.precoLiquidoTexto!,
                estilo: tema.textTheme.headlineSmall?.copyWith(
                  color: cores.ganho,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (produto.parcelamento != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(produto.parcelamento!),
              ),
            if (produto.estoque != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Estoque informado: ${produto.estoque}'),
              ),
            if (produto.etiquetas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final etiqueta in produto.etiquetas)
                      Chip(label: Text(etiqueta)),
                  ],
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: aoAbrirHistorico ?? aoAbrirDetalhes,
                  icon: const Icon(Icons.timeline_outlined),
                  label: const Text('Ver histórico'),
                ),
                if (aoAbrirNoShopping != null)
                  FilledButton.tonalIcon(
                    onPressed: aoAbrirNoShopping,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir no Shopping Inter'),
                  ),
                if (aoAcompanhar != null)
                  OutlinedButton.icon(
                    onPressed: aoAcompanhar,
                    icon: Icon(
                      produto.acompanhado
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_outlined,
                    ),
                    label: Text(
                      produto.acompanhado ? 'Acompanhando' : 'Acompanhar',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _compacto(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final disponibilidade = _disponibilidadeProduto(produto);
    final cashback = [
      produto.cashbackPercentualTexto,
      produto.cashbackTexto,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');
    final marcaCategoria = [
      produto.marca,
      produto.categoria,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');
    final precoCheioDiferente =
        produto.precoCheioTexto != null &&
        produto.precoCheioTexto != produto.precoAtualTexto;
    return Semantics(
      label:
          'Oferta ${produto.nome}, da loja ${produto.lojaNome}, '
          'no Banco Inter',
      child: CartaoRadar(
        padding: EdgeInsets.zero,
        corDestaque: cores.acao,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                tokens.spacing.five,
                tokens.spacing.five,
                tokens.spacing.five,
                tokens.spacing.four,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          produto.lojaNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: cores.textoSuave,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.spacing.two),
                      Expanded(
                        child: Text(
                          disponibilidade,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: cores.textoSuave,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: tokens.spacing.three),
                  Text(
                    produto.nome,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (marcaCategoria.isNotEmpty)
                    Text(
                      marcaCategoria,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                  SizedBox(height: tokens.spacing.three),
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
                  if (cashback.isNotEmpty)
                    Text(
                      '$cashback de cashback',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                  if (produto.precoLiquidoTexto != null)
                    Text(
                      'Estimativa após cashback: ${produto.precoLiquidoTexto}',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                  SizedBox(height: tokens.spacing.three),
                  Divider(height: 1, color: cores.borda),
                  SizedBox(height: tokens.spacing.two),
                  Row(
                    children: [
                      if (aoAcompanhar != null)
                        Expanded(
                          child: TextButton.icon(
                            key: ValueKey(
                              'alerta-produto-${produto.lojaSlug}-${produto.idExterno}',
                            ),
                            onPressed: aoAcompanhar,
                            icon: Icon(
                              produto.acompanhado
                                  ? Icons.check
                                  : Icons.notifications_none_outlined,
                              size: 16,
                            ),
                            label: Text(
                              produto.acompanhado
                                  ? 'Acompanhando'
                                  : 'Acompanhar',
                            ),
                            style: TextButton.styleFrom(
                              alignment: AlignmentDirectional.centerStart,
                              foregroundColor: cores.acao,
                              backgroundColor: produto.acompanhado
                                  ? cores.perigoFundo
                                  : cores.superficieAlternativa,
                              padding: EdgeInsetsDirectional.symmetric(
                                horizontal: tokens.spacing.two,
                              ),
                              minimumSize: Size(0, tokens.sizes.touchTarget),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  tokens.radii.md,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      Tooltip(
                        message: 'Ver detalhes',
                        child: TextButton.icon(
                          onPressed: aoAbrirDetalhes,
                          key: const ValueKey('detalhes-produto'),
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text('Detalhes'),
                          style: TextButton.styleFrom(
                            foregroundColor: cores.acao,
                            minimumSize: Size(0, tokens.sizes.touchTarget),
                            padding: EdgeInsetsDirectional.only(
                              start: tokens.spacing.two,
                            ),
                          ),
                        ),
                      ),
                    ],
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

String _disponibilidadeProduto(ProdutoDireto produto) =>
    produto.estoque == 0 ? 'Esgotado' : 'Disponível';

class _ValorComercial extends StatelessWidget {
  const _ValorComercial({
    required this.rotulo,
    required this.valor,
    required this.estilo,
  });

  final String rotulo;
  final String valor;
  final TextStyle? estilo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: Theme.of(context).textTheme.labelMedium),
        Text(valor, style: estilo),
      ],
    ),
  );
}
