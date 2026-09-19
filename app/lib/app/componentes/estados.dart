import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tema/tokens.dart';

/// Widgets de estado reutilizáveis (PLANO §10.3): loading, vazio, vazio de
/// dados e falha têm apresentação própria, honesta — nunca uma tela branca.
class Carregando extends StatelessWidget {
  const Carregando({super.key, this.mensagem = 'Carregando…'});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      label: mensagem,
      excludeSemantics: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: tokens.spacing.three),
            Text(mensagem),
          ],
        ),
      ),
    );
  }
}

class EstadoVazio extends StatelessWidget {
  const EstadoVazio({super.key, required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      label: mensagem,
      excludeSemantics: true,
      child: Center(
        child: Container(
          margin: EdgeInsets.all(tokens.spacing.four),
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacing.four,
            vertical: tokens.spacing.five,
          ),
          decoration: BoxDecoration(
            color: cores.superficieAlternativa,
            border: Border.all(color: cores.borda),
            borderRadius: BorderRadius.circular(tokens.radii.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/illustrations/no-results.svg',
                width: tokens.sizes.illustrationWidth,
                height: tokens.sizes.illustrationHeight,
                semanticsLabel: 'Nenhum resultado',
              ),
              SizedBox(height: tokens.spacing.three),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cores.textoSuave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EstadoFalha extends StatelessWidget {
  const EstadoFalha({super.key, required this.mensagem, this.voltar});

  final String mensagem;
  final VoidCallback? voltar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final corErro = cores.perigo;
    return Semantics(
      liveRegion: true,
      label: mensagem,
      child: Center(
        child: Container(
          margin: EdgeInsets.all(tokens.spacing.four),
          padding: EdgeInsets.all(tokens.spacing.five),
          decoration: BoxDecoration(
            color: cores.perigoFundo,
            border: Border.all(color: corErro.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(tokens.radii.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/illustrations/offline.svg',
                width: tokens.sizes.illustrationWidth,
                height: tokens.sizes.illustrationHeight,
                semanticsLabel: 'Falha de conexão',
              ),
              SizedBox(height: tokens.spacing.three),
              Text(mensagem, textAlign: TextAlign.center),
              if (voltar != null) ...[
                SizedBox(height: tokens.spacing.four),
                FilledButton.tonal(
                  onPressed: voltar,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
