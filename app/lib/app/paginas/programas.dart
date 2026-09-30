import 'package:flutter/material.dart';

import '../componentes/fundacao_visual.dart';
import '../tema/tokens.dart';

/// Catálogo compacto das integrações reais do Radar.
///
/// A lista reúne somente as fontes conectadas; os catálogos abertos a partir
/// daqui continuam consultando seus próprios dados server-side.
class PaginaProgramas extends StatelessWidget {
  const PaginaProgramas({
    super.key,
    required this.aoAbrirLivelo,
    required this.aoAbrirInter,
    required this.aoAbrirPichau,
  });

  final VoidCallback aoAbrirLivelo;
  final VoidCallback aoAbrirInter;
  final VoidCallback aoAbrirPichau;

  @override
  Widget build(BuildContext context) {
    final programas = <_ProgramaRadar>[
      _ProgramaRadar(
        chave: const Key('programa-inter'),
        titulo: 'Banco Inter',
        descricao: 'Cashback em lojas e compra de produtos.',
        tipo: '02 experiências',
        aoTocar: aoAbrirInter,
      ),
      _ProgramaRadar(
        chave: const Key('programa-livelo'),
        titulo: 'Livelo',
        descricao: 'Lojas parceiras e pontos por real gasto.',
        tipo: 'Pontos',
        aoTocar: aoAbrirLivelo,
      ),
      _ProgramaRadar(
        chave: const Key('programa-pichau'),
        titulo: 'Pichau',
        descricao: 'PCs gamer com preço Pix e cartão.',
        tipo: 'Tecnologia',
        aoTocar: aoAbrirPichau,
      ),
    ];

    return SafeArea(
      top: true,
      bottom: false,
      child: ListView(
        key: const Key('pagina-programas'),
        padding: EdgeInsetsDirectional.only(
          start: context.tokens.spacing.five,
          top: context.tokens.spacing.four,
          end: context.tokens.spacing.five,
          bottom: context.tokens.spacing.six,
        ),
        children: [
          const _CabecalhoExplorar(),
          SizedBox(height: context.tokens.spacing.six),
          for (var indice = 0; indice < programas.length; indice++) ...[
            _CartaoPrograma(programa: programas[indice]),
            if (indice != programas.length - 1)
              SizedBox(height: context.tokens.spacing.three),
          ],
        ],
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
    required this.aoTocar,
  });

  final Key chave;
  final String titulo;
  final String descricao;
  final String tipo;
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
      comSombra: false,
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
                    color: cores.acaoFundo,
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
          ],
        ),
      ),
    );
  }
}
