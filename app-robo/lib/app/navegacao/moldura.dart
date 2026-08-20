import 'package:flutter/material.dart';

import '../../core/api/api_v1.dart';
import '../paginas/inicio.dart';
import '../paginas/lugar.dart';
import '../tema/tokens.dart';
import 'destinos.dart';

/// Moldura de navegação do Radar (PLANO §10.4). Nesta fase web se monta como
/// barra lateral azul-marino fixa; o corpo usa `IndexedStack` para preservar
/// o estado de cada área ao trocar de aba.
///
/// A barra inferior do móvel entra na fase de plataformas; este é o foco web.
class MolduraRadar extends StatefulWidget {
  const MolduraRadar({super.key, required this.api});

  final ApiV1 api;

  @override
  State<MolduraRadar> createState() => _EstadoMolduraRadar();
}

class _EstadoMolduraRadar extends State<MolduraRadar> {
  Destino _selecionado = Destino.inicio;

  late final List<Widget> _paineis = <Widget>[
    PaginaInicio(api: widget.api),
    const PaginaEmBreve(titulo: 'Livelo'),
    const PaginaEmBreve(titulo: 'Inter'),
    const PaginaEmBreve(titulo: 'Alertas'),
    const PaginaEmBreve(titulo: 'Mais'),
  ];

  void _selecionar(Destino destino) {
    setState(() => _selecionado = destino);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          BarraLateral(selecionado: _selecionado, aoSelecionar: _selecionar),
          Expanded(
            child: IndexedStack(index: _selecionado.index, children: _paineis),
          ),
        ],
      ),
    );
  }
}

class BarraLateral extends StatelessWidget {
  const BarraLateral({
    super.key,
    required this.selecionado,
    required this.aoSelecionar,
  });

  final Destino selecionado;
  final ValueChanged<Destino> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Tokens.marca,
      child: SafeArea(
        child: SizedBox(
          width: 220,
          height: double.infinity,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Radar de Benefícios',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final destino in Destino.values)
                    ItemDaBarra(
                      destino: destino,
                      selecionado: destino == selecionado,
                      aoTocar: () => aoSelecionar(destino),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ItemDaBarra extends StatelessWidget {
  const ItemDaBarra({
    super.key,
    required this.destino,
    required this.selecionado,
    required this.aoTocar,
  });

  final Destino destino;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final corFondo = selecionado
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: corFondo,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(destino.icone, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(destino.titulo, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
