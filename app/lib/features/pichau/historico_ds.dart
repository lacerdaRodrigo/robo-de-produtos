import '../../core/api/api.dart';
import '../../design_system/design_system.dart';
import 'modelos_pichau.dart';

/// Histórico da Pichau para a `FolhaHistorico` única.
class FonteHistoricoPichau implements FonteHistorico {
  FonteHistoricoPichau({required this.api, required this.produto});

  final Api api;
  final PichauProduto produto;

  static const porPagina = 5;

  @override
  Future<PaginaHistorico> carregar(int pagina) async {
    final r = await api.historicoPichau(
      idExterno: produto.idExterno,
      pagina: pagina,
      porPagina: porPagina,
    );
    final total = r.totalItens == 0
        ? 1
        : (r.totalItens + porPagina - 1) ~/ porPagina;
    return PaginaHistorico(
      pagina: r.pagina,
      totalPaginas: total,
      temProxima: r.temProxima,
      nota: 'Últimos 30 dias · ${r.totalItens} medições',
      resumo: [
        if (r.minimoPixTexto case final minimo?)
          MetricaHistorico('Menor Pix em 30 dias', minimo),
        if (r.maximoPixTexto case final maximo?)
          MetricaHistorico('Maior Pix em 30 dias', maximo),
      ],
      linhas: [
        for (final m in r.medicoes)
          LinhaHistorico(
            momento: DsFormato.momentoCompacto(m.momento),
            valorPrincipal: m.precoPixTexto ?? 'Sem medição',
            destaque:
                r.minimoPixTexto != null && m.precoPixTexto == r.minimoPixTexto,
            status: m.precoPixTexto == null
                ? 'Fora do catálogo'
                : (m.precoPixTexto == r.minimoPixTexto
                      ? 'Menor do período'
                      : null),
            secundarios: [
              if (m.precoCartaoTexto case final cartao?) 'Cartão $cartao',
            ],
          ),
      ],
    );
  }
}
