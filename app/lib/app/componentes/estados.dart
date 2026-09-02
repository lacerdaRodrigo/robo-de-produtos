import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Widgets de estado reutilizáveis (PLANO §10.3): loading, vazio, vazio de
/// dados e falha têm apresentação própria, honesta — nunca uma tela branca.
class Carregando extends StatelessWidget {
  const Carregando({super.key, this.mensagem = 'Carregando…'});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: mensagem,
      excludeSemantics: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
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
    return Semantics(
      liveRegion: true,
      label: mensagem,
      excludeSemantics: true,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: cores.superficieAlternativa,
            border: Border.all(color: cores.borda),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: cores.textoSuave),
              const SizedBox(height: 12),
              Text(
                mensagem,
                textAlign: TextAlign.center,
                style: TextStyle(color: cores.textoSuave),
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
    final corErro = Theme.of(context).colorScheme.error;
    return Semantics(
      liveRegion: true,
      label: mensagem,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(18),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: corErro.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: corErro, size: 40),
              const SizedBox(height: 12),
              Text(mensagem, textAlign: TextAlign.center),
              if (voltar != null) ...[
                const SizedBox(height: 16),
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
