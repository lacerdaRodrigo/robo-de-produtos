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
/// Somente Início, Programas e Produtos aparecem na barra inferior. Livelo e
/// Inter são subáreas de Programas, mas continuam como destinos próprios para
/// preservar busca, filtros, página e rolagem ao alternar de área.
enum DestinoCompacto {
  inicio(Icons.home_outlined, 'Início', 'Visão geral do seu radar'),
  programas(
    Icons.space_dashboard_outlined,
    'Programas',
    'Pontos, cashback e integrações',
  ),
  livelo(Icons.card_giftcard_outlined, 'Livelo', 'Lojas, pontos e alertas'),
  inter(
    Icons.account_balance_outlined,
    'Banco Inter',
    'Escolha lojas e veja cashback',
  ),
  produtos(Icons.search, 'Buscar produtos', 'Resultados das lojas escolhidas');

  const DestinoCompacto(this.icone, this.titulo, this.descricao);

  final IconData icone;
  final String titulo;
  final String descricao;

  bool get principal => this == inicio || this == programas || this == produtos;

  DestinoCompacto get destinoDaBarra => switch (this) {
    livelo || inter => programas,
    _ => this,
  };
}
