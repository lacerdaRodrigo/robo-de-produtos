import 'package:flutter/material.dart';

import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';

class CartaoProduto extends StatelessWidget {
  const CartaoProduto({
    super.key,
    required this.produto,
    required this.aoAbrirHistorico,
  });

  final ProdutoDireto produto;
  final VoidCallback aoAbrirHistorico;

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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  produto.precoAtualTexto,
                  style: tema.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Após cashback: ${produto.precoLiquidoTexto}',
                    style: tema.textTheme.titleSmall?.copyWith(
                      color: Tokens.ganho,
                      fontWeight: FontWeight.bold,
                    ),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: aoAbrirHistorico,
                  icon: const Icon(Icons.timeline_outlined),
                  label: const Text('Ver histórico'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
