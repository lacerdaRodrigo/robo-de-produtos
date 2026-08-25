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

/// Valor NUMERIC do histórico, sem converter para double.
String? valorMonetario(String? valor) => moeda(valor);
