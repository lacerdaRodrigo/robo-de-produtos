import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';
import 'formato_livelo.dart';

class CartaoCatalogoLivelo extends StatelessWidget {
  const CartaoCatalogoLivelo({
    super.key,
    required this.parceiro,
    required this.pendente,
    required this.podeAdministrar,
    required this.aoAlternar,
  });

  final ParceiroCatalogoLivelo parceiro;
  final bool pendente;
  final bool podeAdministrar;
  final VoidCallback aoAlternar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final clube = rotuloClube(parceiro.campanha);
    return Semantics(
      label: 'Parceiro Livelo ${parceiro.nome}',
      child: CartaoRadar(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Iniciais(nome: parceiro.nome),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parceiro.nome,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        parceiro.categorias.join(' · '),
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: cores.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                pontosLivelo(parceiro.pontosAtuais, moeda: parceiro.moeda),
                textAlign: TextAlign.end,
                style: tema.textTheme.titleSmall?.copyWith(
                  color: cores.acao,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (parceiro.pontosBase != null)
                  _Selo(
                    texto:
                        'Normal ${pontosLivelo(parceiro.pontosBase, moeda: parceiro.moeda)}',
                  ),
                if (parceiro.pontosClube != null)
                  _Selo(
                    texto:
                        'Clube ${pontosLivelo(parceiro.pontosClube, moeda: parceiro.moeda)}',
                    tom: TomRadar.acao,
                  ),
                if (parceiro.emPromocao)
                  const _Selo(texto: 'Promoção', tom: TomRadar.ganho),
                if (clube != null) _Selo(texto: clube, tom: TomRadar.acao),
                if (parceiro.alerta)
                  const _Selo(texto: 'Alerta ativo', tom: TomRadar.perigo),
              ],
            ),
            if (parceiro.fimPromocao != null) ...[
              const SizedBox(height: 10),
              IndicadorEstadoRadar(
                texto: validadeLivelo(parceiro.fimPromocao),
                tom: TomRadar.atencao,
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: parceiro.acompanhada
                  ? OutlinedButton.icon(
                      key: Key('acompanhar-${parceiro.idExterno}'),
                      onPressed: podeAdministrar && !pendente
                          ? aoAlternar
                          : null,
                      icon: pendente
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(pendente ? 'Salvando…' : 'Acompanhando'),
                    )
                  : FilledButton.tonalIcon(
                      key: Key('acompanhar-${parceiro.idExterno}'),
                      onPressed: podeAdministrar && !pendente
                          ? aoAlternar
                          : null,
                      icon: pendente
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(pendente ? 'Salvando…' : 'Acompanhar'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Iniciais extends StatelessWidget {
  const _Iniciais({required this.nome});
  final String nome;

  @override
  Widget build(BuildContext context) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty);
    final iniciais = partes
        .take(2)
        .map((item) => item.substring(0, 1))
        .join()
        .toUpperCase();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CoresRadar.de(context).superficieAlternativa,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        iniciais.isEmpty ? '•' : iniciais,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: CoresRadar.de(context).acao,
          fontWeight: FontWeight.w900,
        ),
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
    final cor = switch (tom) {
      TomRadar.acao => CoresRadar.de(context).acao,
      TomRadar.ganho => CoresRadar.de(context).ganho,
      TomRadar.atencao => CoresRadar.de(context).atencao,
      TomRadar.perigo => CoresRadar.de(context).perigo,
      TomRadar.neutro => CoresRadar.de(context).textoSuave,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 12)),
    );
  }
}
