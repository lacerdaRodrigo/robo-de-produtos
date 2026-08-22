import '../../core/formato.dart';

/// Texto visível da pontuação. Não calcula nem converte o decimal recebido.
String pontosLivelo(String? valor, {String moeda = 'R\$'}) {
  final pontos = decimal(valor);
  if (pontos == null) {
    return '—';
  }
  return '$pontos pontos por $moeda 1';
}

/// Rótulos que explicam os dois tipos de campanha do Clube (RN23).
String? rotuloClube(String? campanha) {
  switch (campanha?.trim().toUpperCase()) {
    case 'CLUB':
      return 'Exclusivo para assinantes Clube';
    case 'PROMOTION_CLUB':
      return 'Assinantes Clube ganham mais';
    default:
      return null;
  }
}

DateTime? instanteApi(String? iso) {
  if (iso == null) {
    return null;
  }
  return DateTime.tryParse(iso)?.toUtc();
}

/// Uma coleta com mais de 12 h é honesta e visualmente marcada como atrasada.
bool coletaAtrasada(String? iso, DateTime agora) {
  final instante = instanteApi(iso);
  if (instante == null) {
    return false;
  }
  return agora.toUtc().difference(instante) > const Duration(hours: 12);
}

/// Data/hora fixa no fuso de Brasília, independente do fuso do aparelho.
String dataHoraLivelo(String? iso) {
  final instante = instanteApi(iso);
  if (instante == null) {
    return 'Nenhuma coleta registrada';
  }
  final brasilia = instante.subtract(const Duration(hours: 3));
  String dois(int numero) => numero.toString().padLeft(2, '0');
  return '${dois(brasilia.day)}/${dois(brasilia.month)}/${brasilia.year}, '
      '${dois(brasilia.hour)}:${dois(brasilia.minute)}';
}

String validadeLivelo(String? iso) {
  final instante = instanteApi(iso);
  if (instante == null) {
    return '';
  }
  final brasilia = instante.subtract(const Duration(hours: 3));
  return 'Válido até ${brasilia.day.toString().padLeft(2, '0')}/'
      '${brasilia.month.toString().padLeft(2, '0')}/${brasilia.year}';
}
