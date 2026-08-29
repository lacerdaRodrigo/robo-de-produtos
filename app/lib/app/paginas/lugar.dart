import 'package:flutter/material.dart';

import '../componentes/estados.dart';

/// Lugar-ocupante para destinos que ainda não têm tela própria (Fase 4.2+).
/// Mostra o nome da área e avisa que está em construção.
class PaginaEmBreve extends StatelessWidget {
  const PaginaEmBreve({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(titulo, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const Expanded(
          child: EstadoVazio(mensagem: 'Ainda não implementado nesta fase.'),
        ),
      ],
    );
  }
}
