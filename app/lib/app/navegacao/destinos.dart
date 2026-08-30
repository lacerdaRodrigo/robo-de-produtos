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

/// Quatro áreas principais aprovadas para a experiência compacta.
///
/// Alertas, conta e administração são utilidades e, por isso, não entram nesta
/// enumeração nem ocupam um quinto tópico do menu mobile.
enum DestinoCompacto {
  inicio(Icons.home_outlined, 'Início', 'Visão geral do seu radar'),
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
}
