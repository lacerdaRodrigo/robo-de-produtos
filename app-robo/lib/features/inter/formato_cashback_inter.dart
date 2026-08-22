/// Formatação e regras de apresentação exclusivas do cashback Inter.
///
/// O domínio não reutiliza a regra de atraso da Livelo: para o Inter, o PRD-V3
/// define 24 horas (RN46 e §15.4), enquanto a Livelo usa 12 horas.
DateTime? instanteInter(String? iso) {
  if (iso == null) {
    return null;
  }
  return DateTime.tryParse(iso)?.toUtc();
}

bool coletaInterAtrasada(String? iso, DateTime agora) {
  final instante = instanteInter(iso);
  if (instante == null) {
    return false;
  }
  return agora.toUtc().difference(instante) > const Duration(hours: 24);
}

/// Data/hora da execução em Brasília, independente do fuso do aparelho.
String dataHoraInter(String? iso) {
  final instante = instanteInter(iso);
  if (instante == null) {
    return 'Nenhuma coleta registrada';
  }
  final brasilia = instante.subtract(const Duration(hours: 3));
  String dois(int numero) => numero.toString().padLeft(2, '0');
  return '${dois(brasilia.day)}/${dois(brasilia.month)}/${brasilia.year}, '
      '${dois(brasilia.hour)}:${dois(brasilia.minute)}';
}
