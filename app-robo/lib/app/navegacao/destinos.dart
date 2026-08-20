import 'package:flutter/material.dart';

/// Destinos da navegação principal (PLANO §10.4). Nesta fase o app é só o
/// shell com esses destinos; as telas de cada área entram em 4.2+.
enum Destino {
  inicio(Icons.dashboard_outlined, 'Início'),
  livelo(Icons.star_outline, 'Livelo'),
  inter(Icons.shopping_cart_outlined, 'Inter'),
  alertas(Icons.notifications_outlined, 'Alertas'),
  mais(Icons.more_horiz, 'Mais');

  const Destino(this.icone, this.titulo);

  final IconData icone;
  final String titulo;
}
