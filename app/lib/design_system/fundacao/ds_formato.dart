/// Formatação de apresentação compartilhada pelos componentes.
///
/// Dinheiro e pontos continuam em `core/formato.dart` (sem `double`).
abstract final class DsFormato {
  /// `Hoje, 14:05`, `Ontem, 22:10` ou `08/10, 14:02` no horário de Brasília
  /// (UTC−3), o mesmo critério já usado pela Livelo.
  static String momentoCompacto(String? iso, {DateTime? agora}) {
    final instante = iso == null ? null : DateTime.tryParse(iso)?.toUtc();
    if (instante == null) {
      final bruto = iso?.trim() ?? '';
      return bruto.isEmpty ? 'Momento não informado' : bruto;
    }
    const fuso = Duration(hours: 3);
    final local = instante.subtract(fuso);
    final hoje = (agora ?? DateTime.now()).toUtc().subtract(fuso);
    String dois(int v) => v.toString().padLeft(2, '0');
    final hora = '${dois(local.hour)}:${dois(local.minute)}';
    bool mesmoDia(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    if (mesmoDia(local, hoje)) return 'Hoje, $hora';
    if (mesmoDia(local, hoje.subtract(const Duration(days: 1)))) {
      return 'Ontem, $hora';
    }
    return '${dois(local.day)}/${dois(local.month)}, $hora';
  }
}
