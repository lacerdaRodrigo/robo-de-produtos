import '../../core/formato.dart';

/// Texto visível da pontuação. Não calcula nem converte o decimal recebido.
String pontosLivelo(String? valor, {String moeda = 'R\$'}) {
  final pontos = decimal(valor);
  if (pontos == null) {
    return '—';
  }
  return '$pontos pontos por $moeda 1';
}

/// Parte numérica da pontuação para a hierarquia visual do cartão.
String valorPontosLivelo(String? valor) => decimal(valor) ?? '—';

/// Texto curto para cada linha do histórico, sem recalcular a pontuação.
String pontosHistoricoLivelo(String? valor, {String moeda = 'R\$'}) {
  final pontos = decimal(valor);
  if (pontos == null) {
    return 'Sem medição';
  }
  return '$pontos pts/$moeda 1';
}

/// Carimbo curto da coleta real exibida no catálogo.
String atualizacaoCatalogoLivelo(String? iso, {DateTime? agora}) {
  final instante = instanteApi(iso);
  if (instante == null) return 'Sem atualização';
  final local = instante.subtract(const Duration(hours: 3));
  final referencia = (agora ?? DateTime.now()).toUtc().subtract(
    const Duration(hours: 3),
  );
  String dois(int valor) => valor.toString().padLeft(2, '0');
  final hora = '${dois(local.hour)}:${dois(local.minute)}';
  if (_mesmoDia(local, referencia)) return 'Hoje, $hora';
  if (_mesmoDia(local, referencia.subtract(const Duration(days: 1)))) {
    return 'Ontem, $hora';
  }
  return '${dois(local.day)}/${dois(local.month)}, $hora';
}

/// Validade curta para a etiqueta principal do cartão Livelo.
String validadeBreveLivelo(String? iso, {DateTime? agora}) {
  final instante = instanteApi(iso);
  if (instante == null) return '';
  final local = instante.subtract(const Duration(hours: 3));
  final referencia = (agora ?? DateTime.now()).toUtc().subtract(
    const Duration(hours: 3),
  );
  String dois(int valor) => valor.toString().padLeft(2, '0');
  final hora = '${dois(local.hour)}:${dois(local.minute)}';
  if (_mesmoDia(local, referencia)) return 'Termina hoje, $hora';
  if (_mesmoDia(local, referencia.add(const Duration(days: 1)))) {
    return 'Até amanhã, $hora';
  }
  return 'Até ${dois(local.day)}/${dois(local.month)}, $hora';
}

bool _mesmoDia(DateTime primeiro, DateTime segundo) =>
    primeiro.year == segundo.year &&
    primeiro.month == segundo.month &&
    primeiro.day == segundo.day;

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
