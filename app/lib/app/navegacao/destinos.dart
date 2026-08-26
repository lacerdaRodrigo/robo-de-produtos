import 'package:flutter/material.dart';

/// Destinos fixos da navegação principal do redesign.
///
/// Integrações continuam separadas internamente: [lojas] apenas organiza o
/// acesso a Livelo e Shopping Inter, e [produtos] abre a busca local da API.
enum Destino {
  inicio(Icons.home_outlined, 'Início'),
  lojas(Icons.storefront_outlined, 'Lojas'),
  produtos(Icons.search, 'Produtos'),
  alertas(Icons.notifications_outlined, 'Alertas'),
  mais(Icons.more_horiz, 'Mais');

  const Destino(this.icone, this.titulo);

  final IconData icone;
  final String titulo;
}
