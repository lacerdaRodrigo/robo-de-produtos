import 'package:flutter/material.dart';

/// Destinos preservados na navegação ampla durante a migração do mobile.
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

/// Destinos preservados no `IndexedStack` compacto.
///
/// Somente Início e Serviços aparecem na barra inferior. Livelo, Inter e
/// Pichau são subáreas de Serviços, e Produtos agora é uma subárea do Banco
/// Inter para preservar a origem do catálogo no mobile.
enum DestinoCompacto {
  inicio(Icons.home_outlined, 'Resumo', 'Visão geral do seu radar'),
  programas(
    Icons.space_dashboard_outlined,
    'Serviços',
    'Livelo, Banco Inter e integrações',
  ),
  livelo(Icons.card_giftcard_outlined, 'Livelo', 'Lojas, pontos e alertas'),
  inter(
    Icons.account_balance_outlined,
    'Banco Inter',
    'Escolha lojas e veja cashback',
  ),
  pichau(Icons.computer_outlined, 'Pichau', 'Catálogo de PCs Gamer');

  const DestinoCompacto(this.icone, this.titulo, this.descricao);

  final IconData icone;
  final String titulo;
  final String descricao;

  bool get principal => this == inicio || this == programas;

  DestinoCompacto get destinoDaBarra => switch (this) {
    livelo || inter || pichau => programas,
    _ => this,
  };
}
