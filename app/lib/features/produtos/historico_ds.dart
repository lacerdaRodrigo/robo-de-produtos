import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../../core/formato.dart';
import '../../design_system/design_system.dart';

/// Histórico do Compre direto para a `FolhaHistorico` única.
class FonteHistoricoProduto implements FonteHistorico {
  FonteHistoricoProduto({required this.api, required this.produto});

  final Api api;
  final ProdutoDireto produto;

  static const porPagina = 5;

  @override
  Future<PaginaHistorico> carregar(int pagina) async {
    final r = await api.historicoProduto(
      loja: produto.lojaSlug,
      produto: produto.idExterno,
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
        if (moeda(r.minimo) case final minimo?)
          MetricaHistorico('Menor em 30 dias', minimo),
        if (moeda(r.maximo) case final maximo?)
          MetricaHistorico('Maior em 30 dias', maximo),
      ],
      linhas: [
        for (final m in r.medicoes)
          LinhaHistorico(
            momento: DsFormato.momentoCompacto(m.momento),
            valorPrincipal: moeda(m.precoAtualValor) ?? 'Sem medição',
            destaque: r.minimo != null && m.precoAtualValor == r.minimo,
            status: r.minimo != null && m.precoAtualValor == r.minimo
                ? 'Menor do período'
                : null,
            secundarios: [
              if (moeda(m.cashbackValor) case final cashback?)
                'Cashback $cashback',
              if (moeda(m.precoLiquidoValor) case final liquido?)
                'Após cashback $liquido',
            ],
          ),
      ],
    );
  }
}
