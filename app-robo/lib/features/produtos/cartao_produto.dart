import 'package:flutter/material.dart';

import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';

class CartaoProduto extends StatelessWidget {
  const CartaoProduto({
    super.key,
    required this.produto,
    required this.aoAbrirHistorico,
    this.aoAbrirNoShopping,
  });

  final ProdutoDireto produto;
  final VoidCallback aoAbrirHistorico;
  final VoidCallback? aoAbrirNoShopping;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final precoCheioDiferente =
        produto.precoCheioTexto != null &&
        produto.precoCheioTexto != produto.precoAtualTexto;
    return Semantics(
      label: 'Produto ${produto.nome}, da loja ${produto.lojaNome}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(produto.nome, style: tema.textTheme.titleMedium),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(produto.lojaNome),
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
                      color: Tokens.ganho,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (produto.precoLiquidoTexto != null)
                _ValorComercial(
                  rotulo: 'Após cashback',
                  valor: produto.precoLiquidoTexto!,
                  estilo: tema.textTheme.headlineSmall?.copyWith(
                    color: Tokens.ganho,
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
                    onPressed: aoAbrirHistorico,
                    icon: const Icon(Icons.timeline_outlined),
                    label: const Text('Ver histórico'),
                  ),
                  if (aoAbrirNoShopping != null)
                    FilledButton.tonalIcon(
                      onPressed: aoAbrirNoShopping,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir no Shopping Inter'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
