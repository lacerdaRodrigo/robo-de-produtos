import 'package:flutter/material.dart';

import '../../core/api/modelos.dart';
import '../tema/tokens.dart';

class FalhaResumo extends StatelessWidget {
  const FalhaResumo({super.key, required this.aoTentarNovamente});

  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Material(
      color: cores.atencao.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: cores.atencao),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Não foi possível carregar os resumos. Você ainda pode abrir cada fonte.',
              ),
            ),
            TextButton(
              onPressed: aoTentarNovamente,
              child: const Text('Tentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class ChipResumo extends StatelessWidget {
  const ChipResumo(this.texto, {super.key, this.ganho = false});

  final String texto;
  final bool ganho;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final cor = ganho ? cores.ganho : cores.textoSuave;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: cor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String tituloEstadoResumo(EstadoResumo estado) => switch (estado) {
  EstadoResumo.atualizado => 'atualizado',
  EstadoResumo.atencao => 'atenção',
  EstadoResumo.atrasado => 'atrasado',
  EstadoResumo.atualizando => 'atualizando',
  EstadoResumo.falhaRecente => 'falha recente',
  EstadoResumo.parcial => 'parcial',
  EstadoResumo.degradado => 'degradado',
  EstadoResumo.semDados => 'sem dados',
  EstadoResumo.indisponivel => 'indisponível',
};

String carimboResumo(String? instante, EstadoResumo estado) {
  if (instante == null) return tituloEstadoResumo(estado);
  final data = DateTime.tryParse(instante)?.toLocal();
  if (data == null) return tituloEstadoResumo(estado);
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final hora = data.hour.toString().padLeft(2, '0');
  final minuto = data.minute.toString().padLeft(2, '0');
  return 'Último sucesso $dia/$mes às $hora:$minuto';
}
