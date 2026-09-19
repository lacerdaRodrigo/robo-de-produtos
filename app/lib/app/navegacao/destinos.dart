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

/// Destinos do `IndexedStack` compacto.
///
/// Os quatro primeiros destinos são a navegação principal da V15. Os demais
/// permanecem nomeados para que as rotas internas dos catálogos possam manter
/// sua posição e seus controladores ao entrar e sair de Explorar.
enum DestinoCompacto {
  inicio(Icons.home_outlined, 'Início', 'Visão geral do seu radar'),
  explorar(
    Icons.explore_outlined,
    'Explorar',
    'Encontre lojas, pontos e cashback',
  ),
  radar(Icons.bookmark_border, 'Meu radar', 'Itens que você acompanha'),
  perfil(Icons.person_outline, 'Perfil', 'Conta, aparência e privacidade'),
  // Alias histórico de entrada em Explorar. Nunca aparece na barra.
  programas(
    Icons.space_dashboard_outlined,
    'Explorar',
    'Lojas, pontos e cashback',
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

  bool get principal => switch (this) {
    inicio || explorar || radar || perfil => true,
    _ => false,
  };

  DestinoCompacto get destinoDaBarra => switch (this) {
    programas || livelo || inter || pichau => explorar,
    _ => this,
  };
}
