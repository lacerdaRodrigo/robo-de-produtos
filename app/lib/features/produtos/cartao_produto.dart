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
    this.aoAcompanhar,
    this.compacto = false,
    this.mostrarLoja = true,
    this.destaque = false,
  });

  final ProdutoDireto produto;
  final VoidCallback aoAbrirHistorico;
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
    final brilhoEscuro = tema.brightness == Brightness.dark;
    final cashback = produto.cashbackTexto;
    final cashbackPercentual = produto.cashbackPercentualTexto;
    final categoria = [
      produto.categoria,
      produto.marca,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');
    final detalhes = [
      if (cashback != null && cashback.trim().isNotEmpty) '$cashback de volta',
      if (produto.estoque != null)
        produto.estoque! > 0 ? 'Em estoque' : 'Esgotado',
      if (produto.etiquetas.isNotEmpty) produto.etiquetas.first,
    ].join('   ·   ');
    final parcelamento = _parcelamentoCompacto(produto.parcelamento);
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
            if (destaque)
              Container(
                margin: const EdgeInsets.fromLTRB(13, 12, 13, 0),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: brilhoEscuro
                      ? Tokens.ganhoFundoEscuro
                      : Tokens.successSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'MENOR PREÇO ATUAL',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: cores.ganho,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .2,
                  ),
                ),
              ),
            if (mostrarLoja)
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 0),
                child: Row(
                  children: [
                    _MonogramaLoja(nome: produto.lojaNome),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produto.lojaNome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.labelMedium?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Atualizado ${dataHoraProduto(produto.atualizadaEm)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: cores.textoSuave,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (aoAcompanhar != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        key: ValueKey(
                          'alerta-produto-${produto.lojaSlug}-${produto.idExterno}',
                        ),
                        tooltip: produto.acompanhado
                            ? 'Deixar de acompanhar ${produto.nome}'
                            : 'Acompanhar ${produto.nome}',
                        onPressed: aoAcompanhar,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        style: IconButton.styleFrom(
                          foregroundColor: produto.acompanhado
                              ? cores.acao
                              : cores.textoSuave,
                          backgroundColor: produto.acompanhado
                              ? (brilhoEscuro
                                    ? Tokens.acaoFundoEscuro
                                    : Tokens.acaoFundo)
                              : cores.superficieAlternativa,
                          side: BorderSide(
                            color: produto.acompanhado
                                ? cores.acao
                                : cores.borda,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          produto.acompanhado
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_none_outlined,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: cores.acao.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            _iconeProduto(produto),
                            size: 19,
                            color: cores.acao,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (categoria.isNotEmpty)
                              Text(
                                categoria.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.textTheme.labelSmall?.copyWith(
                                  color: cores.acao,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .2,
                                ),
                              ),
                            Text(
                              produto.nome,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tema.textTheme.titleSmall?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            if (!mostrarLoja)
                              Text(
                                '${produto.lojaNome} · Banco Inter',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.textTheme.labelSmall?.copyWith(
                                  color: cores.textoSuave,
                                  fontSize: 8,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (cashbackPercentual != null &&
                          cashbackPercentual.trim().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: brilhoEscuro
                                ? Tokens.ganhoFundoEscuro
                                : Tokens.successSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: Text(
                              cashbackPercentual,
                              style: tema.textTheme.labelSmall?.copyWith(
                                color: cores.ganho,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (produto.precoLiquidoTexto != null) ...[
                    const SizedBox(height: 13),
                    _PainelPrecosCompacto(
                      atual: produto.precoAtualTexto,
                      liquido: produto.precoLiquidoTexto,
                    ),
                  ] else ...[
                    const SizedBox(height: 13),
                    _PrecoCompacto(
                      rotulo: 'Preço atual',
                      valor: produto.precoAtualTexto,
                    ),
                  ],
                  if (detalhes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      detalhes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: cores.textoSuave,
                        fontSize: 8,
                      ),
                    ),
                  ],
                  if (parcelamento != null || aoAbrirNoShopping != null) ...[
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, limites) {
                        final empilhar =
                            limites.maxWidth < 330 ||
                            MediaQuery.textScalerOf(context).scale(12) > 14;
                        final acoes = Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'Ver histórico',
                              child: OutlinedButton(
                                onPressed: aoAbrirHistorico,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 35),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  foregroundColor: cores.marca,
                                  side: BorderSide(color: cores.borda),
                                  textStyle: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Histórico'),
                              ),
                            ),
                            if (aoAbrirNoShopping != null) ...[
                              const SizedBox(width: 7),
                              FilledButton(
                                onPressed: aoAbrirNoShopping,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 35),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  backgroundColor: cores.acao,
                                  foregroundColor: tema.colorScheme.onPrimary,
                                  textStyle: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Abrir oferta'),
                              ),
                            ],
                          ],
                        );
                        final parcela = parcelamento == null
                            ? const SizedBox.shrink()
                            : Text(
                                parcelamento,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tema.textTheme.labelSmall?.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              );
                        if (empilhar) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (parcelamento != null) parcela,
                              if (parcelamento != null)
                                const SizedBox(height: 7),
                              Align(
                                alignment: Alignment.centerRight,
                                child: acoes,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            if (parcelamento != null) Expanded(child: parcela),
                            if (parcelamento != null) const SizedBox(width: 8),
                            acoes,
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _parcelamentoCompacto(String? valor) {
  if (valor == null || valor.trim().isEmpty) return null;
  return valor.startsWith('Em ') ? valor.substring(3) : valor;
}

IconData _iconeProduto(ProdutoDireto produto) {
  final texto = '${produto.categoria ?? ''} ${produto.nome}'.toLowerCase();
  if (texto.contains('celular') ||
      texto.contains('smartphone') ||
      texto.contains('iphone')) {
    return Icons.smartphone_outlined;
  }
  if (texto.contains('notebook') ||
      texto.contains('computador') ||
      texto.contains('monitor')) {
    return Icons.laptop_mac_outlined;
  }
  if (texto.contains('casa') || texto.contains('móvel')) {
    return Icons.chair_outlined;
  }
  return Icons.category_outlined;
}

class _MonogramaLoja extends StatelessWidget {
  const _MonogramaLoja({required this.nome});

  final String nome;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final iniciais = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((parte) => parte.isNotEmpty)
        .take(2)
        .map((parte) => parte.substring(0, 1).toUpperCase())
        .join();
    return Container(
      width: 29,
      height: 29,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cores.acao.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        iniciais,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cores.acao,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PainelPrecosCompacto extends StatelessWidget {
  const _PainelPrecosCompacto({required this.atual, required this.liquido});

  final String atual;
  final String? liquido;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: cores.borda),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Expanded(
              child: _PrecoCompacto(rotulo: 'Preço atual', valor: atual),
            ),
            if (liquido != null)
              Expanded(
                child: _PrecoCompacto(
                  rotulo: 'Após cashback',
                  valor: liquido!,
                  liquido: true,
                  fundo: escuro ? Tokens.ganhoFundoEscuro : Tokens.ganhoFundo,
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
    this.fundo,
  });

  final String rotulo;
  final String valor;
  final bool liquido;
  final Color? fundo;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            fundo ??
            (liquido
                ? (Theme.of(context).brightness == Brightness.dark
                      ? Tokens.ganhoFundoEscuro
                      : Tokens.ganhoFundo)
                : cores.superficieAlternativa),
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
