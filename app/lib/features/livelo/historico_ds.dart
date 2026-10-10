import '../../core/api/api.dart';
import '../../design_system/design_system.dart';
import 'formato_livelo.dart';

/// Histórico da Livelo para a `FolhaHistorico` única. A API devolve até 30
/// medições de uma vez; a folha pagina localmente de 5 em 5.
FonteHistorico fonteHistoricoLivelo({
  required Api api,
  required String idExterno,
}) => FonteHistoricoLocal(
  nota: 'Últimas medições · até 30 registros · somente leitura',
  carregarTudo: () async {
    final historico = await api.historicoLivelo(idExterno);
    final linhas = [
      for (final m in historico.medicoes)
        LinhaHistorico(
          momento: dataHoraHistoricoLivelo(m.momento),
          valorPrincipal: pontosHistoricoLivelo(m.pontos, moeda: m.moeda),
          status: 'Completa',
          secundarios: [
            if (pontosClubeSuperaComum(m.pontosClube, m.pontos))
              'Clube ${pontosHistoricoLivelo(m.pontosClube, moeda: m.moeda)}',
          ],
        ),
    ];
    return (linhas, const <MetricaHistorico>[]);
  },
);
