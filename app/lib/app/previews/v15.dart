import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
import '../tema/tema.dart';

/// Prévia isolada da fundação visual V15, sem dados de catálogo ou API.
@Preview(
  name: 'Fundação V15 · claro',
  group: 'Radar V15',
  size: Size(390, 844),
  brightness: Brightness.light,
)
Widget radarV15ClaroPreview() => _radarV15Preview(TemaRadar.claro());

/// Mantém a mesma anatomia para conferência rápida do contraste escuro.
@Preview(
  name: 'Fundação V15 · escuro',
  group: 'Radar V15',
  size: Size(390, 844),
  brightness: Brightness.dark,
)
Widget radarV15EscuroPreview() => _radarV15Preview(TemaRadar.escuro());

Widget _radarV15Preview(ThemeData tema) => MaterialApp(
  theme: tema,
  home: Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CabecalhoSecaoRadar(
            sobrelinha: 'Seu radar',
            titulo: 'Boas escolhas começam aqui.',
            descricao: 'Uma fundação compartilhada para cada origem.',
          ),
          const SizedBox(height: 24),
          CartaoRadar(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado do radar', style: tema.textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text('Cartão, ação e estado sem depender de uma cor.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: null,
                  child: Text(
                    'Ação principal',
                    style: tema.textTheme.labelLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const EstadoVazio(
            mensagem: 'A ilustração é de estado, não de catálogo.',
          ),
        ],
      ),
    ),
  ),
);
