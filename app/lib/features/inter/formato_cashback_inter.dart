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

/// Texto curto do instante salvo, sem confundir o retrato com uma coleta ao vivo.
String tempoColetaInter(String? iso, DateTime agora) {
  final instante = instanteInter(iso);
  if (instante == null) return 'Condição publicada pelo Inter';
  final diferenca = agora.toUtc().difference(instante);
  if (diferenca.isNegative || diferenca.inMinutes < 1) {
    return 'Cashback atualizado agora';
  }
  if (diferenca.inMinutes < 60) {
    return 'Cashback há ${diferenca.inMinutes} min';
  }
  if (diferenca.inHours < 24) return 'Cashback há ${diferenca.inHours} h';
  final brasilia = instante.subtract(const Duration(hours: 3));
  String dois(int numero) => numero.toString().padLeft(2, '0');
  return 'Cashback em ${dois(brasilia.day)}/${dois(brasilia.month)}, '
      '${dois(brasilia.hour)}:${dois(brasilia.minute)}';
}

/// Percentual compacto para métricas, preservando o decimal textual da API.
String? percentualCompactoInter(String? valor) {
  final correspondencia = RegExp(
    r'^(\d+)(?:[.,](\d+))?$',
  ).firstMatch(valor?.trim() ?? '');
  if (correspondencia == null) return null;
  final inteiro = correspondencia.group(1)!;
  final fracao = (correspondencia.group(2) ?? '').replaceFirst(
    RegExp(r'0+$'),
    '',
  );
  return fracao.isEmpty ? '$inteiro%' : '$inteiro,$fracao%';
}

/// Compara valores decimais da API sem converter cashback para `double`.
int compararDecimaisInter(String? esquerdo, String? direito) {
  final a = _decimalExato(esquerdo);
  final b = _decimalExato(direito);
  if (a == null) return b == null ? 0 : -1;
  if (b == null) return 1;
  final escala = a.$2 > b.$2 ? a.$2 : b.$2;
  final valorA = a.$1 * BigInt.from(10).pow(escala - a.$2);
  final valorB = b.$1 * BigInt.from(10).pow(escala - b.$2);
  return valorA.compareTo(valorB);
}

(BigInt, int)? _decimalExato(String? valor) {
  final correspondencia = RegExp(
    r'^([+-]?)(\d+)(?:[.,](\d+))?$',
  ).firstMatch(valor?.trim() ?? '');
  if (correspondencia == null) return null;
  final fracao = correspondencia.group(3) ?? '';
  final sinal = correspondencia.group(1) == '-' ? -BigInt.one : BigInt.one;
  final inteiro = BigInt.parse('${correspondencia.group(2)}$fracao') * sinal;
  return (inteiro, fracao.length);
}
