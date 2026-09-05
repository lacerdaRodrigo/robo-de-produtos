import '../../core/formato.dart';

DateTime? instanteProduto(String? iso) =>
    iso == null ? null : DateTime.tryParse(iso)?.toUtc();

/// PRD-V4 MS18: o catálogo de produtos atrasa após 12 horas.
bool coletaProdutosAtrasada(String? iso, DateTime agora) {
  final instante = instanteProduto(iso);
  return instante != null &&
      agora.toUtc().difference(instante) > const Duration(hours: 12);
}

String dataHoraProduto(String? iso) {
  final instante = instanteProduto(iso);
  if (instante == null) return 'Nenhuma coleta registrada';
  final brasilia = instante.subtract(const Duration(hours: 3));
  String dois(int numero) => numero.toString().padLeft(2, '0');
  return '${dois(brasilia.day)}/${dois(brasilia.month)}/${brasilia.year}, '
      '${dois(brasilia.hour)}:${dois(brasilia.minute)}';
}

String dataHistoricoProduto(String? iso) {
  final instante = instanteProduto(iso);
  if (instante == null) return 'Data não informada';
  final brasilia = instante.subtract(const Duration(hours: 3));
  const meses = <String>[
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  return '${brasilia.day} ${meses[brasilia.month - 1]} ${brasilia.year}';
}

/// Valor NUMERIC do histórico, sem converter para double.
String? valorMonetario(String? valor) => moeda(valor);
