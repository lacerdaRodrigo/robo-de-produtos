import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';
import 'formato_produtos.dart';

class CartaoProduto extends StatelessWidget {
  const CartaoProduto({
    super.key,
    required this.produto,
    required this.aoAbrirHistorico,
    this.aoAbrirNoShopping,
    this.compacto = false,
    this.mostrarLoja = true,
  });

  final ProdutoDireto produto;
  final VoidCallback aoAbrirHistorico;
  final VoidCallback? aoAbrirNoShopping;
  final bool compacto;
  final bool mostrarLoja;

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

  Widget _compacto(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final detalhes = [
      produto.cashbackPercentualTexto,
      produto.parcelamento,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');
    final precos = <Widget>[
      _PrecoCompacto(rotulo: 'Preço atual', valor: produto.precoAtualTexto),
      if (produto.precoLiquidoTexto != null)
        _PrecoCompacto(
          rotulo: 'Após cashback',
          valor: produto.precoLiquidoTexto!,
          liquido: true,
        ),
    ];
    return Semantics(
      label:
          'Oferta ${produto.nome}, da loja ${produto.lojaNome}, '
          'no Banco Inter',
      child: CartaoRadar(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (mostrarLoja)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cores.superficieAlternativa,
                  border: Border(bottom: BorderSide(color: cores.borda)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: cores.ganho),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          produto.lojaNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        dataHoraProduto(produto.atualizadaEm),
                        style: tema.textTheme.labelSmall?.copyWith(
                          color: cores.textoSuave,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (produto.marca != null || produto.categoria != null) ...[
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final tag in [produto.marca, produto.categoria])
                          if (tag != null && tag.trim().isNotEmpty)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: cores.superficieAlternativa,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 4,
                                ),
                                child: Text(
                                  tag,
                                  style: tema.textTheme.labelSmall?.copyWith(
                                    color: cores.textoSuave,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (produto.etiquetas.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Tokens.atencaoFundoEscuro
                            : Tokens.atencaoFundo,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        produto.etiquetas.first.toUpperCase(),
                        style: TextStyle(
                          color: cores.atencao,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  Text(
                    produto.nome,
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 5, color: cores.marca),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${produto.lojaNome} · Banco Inter',
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: cores.textoSuave,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (produto.cashbackPercentualTexto != null ||
                      produto.cashbackTexto != null) ...[
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Tokens.ganhoFundoEscuro
                            : Tokens.positiveSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(
                          [
                            produto.cashbackPercentualTexto,
                            produto.cashbackTexto,
                          ].whereType<String>().join(' · '),
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: cores.ganho,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 11),
                  LayoutBuilder(
                    builder: (context, limites) {
                      final empilhar =
                          limites.maxWidth < 250 ||
                          MediaQuery.textScalerOf(context).scale(15) > 19.5;
                      if (empilhar) {
                        return Column(
                          children: [
                            for (var i = 0; i < precos.length; i++) ...[
                              precos[i],
                              if (i != precos.length - 1)
                                const SizedBox(height: 9),
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (var i = 0; i < precos.length; i++) ...[
                            Expanded(child: precos[i]),
                            if (i != precos.length - 1)
                              const SizedBox(width: 9),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          detalhes,
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: cores.textoSuave,
                            fontSize: 8,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Ver histórico',
                        onPressed: aoAbrirHistorico,
                        icon: const Icon(Icons.timeline_outlined, size: 18),
                      ),
                      if (aoAbrirNoShopping != null)
                        FilledButton.icon(
                          onPressed: aoAbrirNoShopping,
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('Ver no Inter'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
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

class _PrecoCompacto extends StatelessWidget {
  const _PrecoCompacto({
    required this.rotulo,
    required this.valor,
    this.liquido = false,
  });

  final String rotulo;
  final String valor;
  final bool liquido;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: liquido
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Tokens.ganhoFundoEscuro
                  : Tokens.ganhoFundo)
            : cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: liquido ? cores.ganho : cores.textoSuave,
                fontSize: 8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: liquido ? cores.ganho : null,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
