import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';
import 'formato_livelo.dart';

/// Card de uma loja da Livelo, seguindo a hierarquia do catálogo V15.
///
/// A pontuação é apresentada como veio da API. O card não cria uma regra de
/// pontuação nova nem transforma ausência em zero.
class CartaoCatalogoLivelo extends StatelessWidget {
  const CartaoCatalogoLivelo({
    super.key,
    required this.parceiro,
    required this.pendente,
    required this.podeAdministrar,
    this.podeAcompanhar = false,
    required this.atualizadoEm,
    required this.aoAlternar,
    required this.aoDetalhes,
    required this.aoHistorico,
    required this.aoAbrirLivelo,
  });

  final ParceiroCatalogoLivelo parceiro;
  final bool pendente;
  final bool podeAdministrar;
  final bool podeAcompanhar;
  final String? atualizadoEm;
  final VoidCallback aoAlternar;
  final VoidCallback aoDetalhes;
  final VoidCallback aoHistorico;
  final VoidCallback aoAbrirLivelo;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = tokens.colors;
    final categoria = parceiro.categorias
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(2)
        .join(' · ');
    final nomeCategoria = categoria.isEmpty ? 'Livelo' : categoria;
    final clube = rotuloClube(parceiro.campanha);
    final podeInteragir = podeAdministrar || podeAcompanhar;

    final botaoAcompanhar = _BotaoAcompanhar(
      chave: Key('acompanhar-${parceiro.idExterno}'),
      acompanhada: parceiro.acompanhada,
      pendente: pendente,
      habilitado: podeInteragir,
      aoAlternar: aoAlternar,
    );
    final botaoCondicoes = TextButton(
      key: Key('detalhes-${parceiro.idExterno}'),
      onPressed: aoDetalhes,
      style: TextButton.styleFrom(foregroundColor: cores.acao),
      child: const Text('Condições'),
    );

    return Semantics(
      label: 'Parceiro Livelo ${parceiro.nome}',
      child: CartaoRadar(
        key: Key('cartao-livelo-${parceiro.idExterno}'),
        padding: EdgeInsetsDirectional.all(tokens.spacing.four),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    nomeCategoria,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                  ),
                ),
                SizedBox(width: tokens.spacing.two),
                Flexible(
                  child: Text(
                    atualizacaoCatalogoLivelo(atualizadoEm),
                    textAlign: TextAlign.end,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spacing.three),
            Text(
              parceiro.nome,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: tokens.spacing.three),
            Wrap(
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.start,
              spacing: tokens.spacing.two,
              runSpacing: tokens.spacing.one,
              children: [
                Text(
                  valorPontosLivelo(parceiro.pontosAtuais),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cores.texto,
                  ),
                ),
                Text(
                  'pontos / ${parceiro.moeda} 1',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cores.textoSuave,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (parceiro.pontosBase != null) ...[
              SizedBox(height: tokens.spacing.one),
              Text(
                'Base ${valorPontosLivelo(parceiro.pontosBase)} pts'
                '${parceiro.pontosClube == null ? '' : ' · Clube ${valorPontosLivelo(parceiro.pontosClube)} pts'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
              ),
            ],
            if (_temSelos(parceiro, clube)) ...[
              SizedBox(height: tokens.spacing.three),
              Wrap(
                spacing: tokens.spacing.two,
                runSpacing: tokens.spacing.one,
                children: [
                  if (parceiro.emPromocao && clube == null)
                    const _Selo(
                      texto: 'Pontuação ampliada',
                      tom: TomRadar.ganho,
                    ),
                  if (parceiro.fimPromocao != null &&
                      parceiro.fimPromocao!.trim().isNotEmpty)
                    _Selo(
                      texto: validadeBreveLivelo(parceiro.fimPromocao),
                      tom: TomRadar.atencao,
                    ),
                  if (clube != null) _Selo(texto: clube, tom: TomRadar.acao),
                ],
              ),
            ],
            SizedBox(height: tokens.spacing.four),
            Divider(height: tokens.spacing.one, color: cores.borda),
            SizedBox(height: tokens.spacing.two),
            LayoutBuilder(
              builder: (context, limites) {
                final textoAmpliado =
                    MediaQuery.textScalerOf(context).scale(12) > 15;
                if (limites.maxWidth < 300 || textoAmpliado) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      botaoAcompanhar,
                      SizedBox(height: tokens.spacing.one),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: botaoCondicoes,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: botaoAcompanhar),
                    SizedBox(width: tokens.spacing.two),
                    botaoCondicoes,
                  ],
                );
              },
            ),
            SizedBox(height: tokens.spacing.one),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: Key('historico-${parceiro.idExterno}'),
                      onPressed: aoHistorico,
                      style: TextButton.styleFrom(foregroundColor: cores.acao),
                      icon: const Icon(Icons.history),
                      label: const Text('Histórico'),
                    ),
                  ),
                ),
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: _linkHttpsValido(parceiro.link)
                          ? aoAbrirLivelo
                          : null,
                      style: TextButton.styleFrom(foregroundColor: cores.acao),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Ir à Livelo'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _temSelos(ParceiroCatalogoLivelo item, String? clube) =>
      (item.emPromocao && clube == null) ||
      (item.fimPromocao != null && item.fimPromocao!.trim().isNotEmpty) ||
      clube != null;
}

class _BotaoAcompanhar extends StatelessWidget {
  const _BotaoAcompanhar({
    required this.chave,
    required this.acompanhada,
    required this.pendente,
    required this.habilitado,
    required this.aoAlternar,
  });

  final Key chave;
  final bool acompanhada;
  final bool pendente;
  final bool habilitado;
  final VoidCallback aoAlternar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = tokens.colors;
    final cor = cores.acao;
    final estilo = FilledButton.styleFrom(
      foregroundColor: cor,
      backgroundColor: cor.withValues(alpha: 0.14),
      minimumSize: Size(0, tokens.sizes.touchTarget),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: tokens.spacing.three,
      ),
    );
    return FilledButton.icon(
      key: chave,
      onPressed: habilitado && !pendente ? aoAlternar : null,
      style: estilo,
      icon: pendente
          ? SizedBox.square(
              dimension: tokens.sizes.icon,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(acompanhada ? Icons.check : Icons.add),
      label: Text(
        pendente
            ? 'Salvando…'
            : acompanhada
            ? 'Acompanhando'
            : 'Acompanhar',
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo({required this.texto, this.tom = TomRadar.neutro});

  final String texto;
  final TomRadar tom;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = tokens.colors;
    final cor = switch (tom) {
      TomRadar.acao => cores.acao,
      TomRadar.ganho => cores.ganho,
      TomRadar.atencao => cores.atencao,
      TomRadar.perigo => cores.perigo,
      TomRadar.neutro => cores.textoSuave,
    };
    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: tokens.spacing.two,
        vertical: tokens.spacing.one,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(tokens.radii.pill),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cor),
      ),
    );
  }
}

bool _linkHttpsValido(String? link) {
  final uri = Uri.tryParse(link ?? '');
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}
