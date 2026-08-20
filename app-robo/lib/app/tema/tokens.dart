import 'package:flutter/material.dart';

/// Tokens de cor do Radar de Benefícios.
///
/// Direção aprovada no PLANO.md §10.2: "financeiro confiável" — azul-marinho
/// como marca, verde só para ganho, vermelho reservado a erro/zona de perigo.
///
/// Contraste ainda será medido antes de congelar o tema (PLANO §10.3); estes
/// são os valores iniciais aprovados.
abstract final class Tokens {
  // Marca e superfícies institucionais.
  static const Color marca = Color(0xFF102A43);
  static const Color marcaClara = Color(0xFF1769AA); // ação, links, foco

  // Ganho/sucesso — cashback, economia, meta atingida. Nunca para ação neutra.
  static const Color ganho = Color(0xFF16803C);

  // Atenção — dado envelhecendo.
  static const Color atencao = Color(0xFFB7791F);

  // Erro e zona de perigo.
  static const Color perigo = Color(0xFFC53030);

  // Fundo claro neutro.
  static const Color fundo = Color(0xFFF5F7FA);
}
