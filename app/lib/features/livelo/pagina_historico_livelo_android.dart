import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/identidade/logo_radar.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import 'formato_livelo.dart';

/// Histórico de leitura do parceiro do catálogo atual.
class PaginaHistoricoLiveloAndroid extends StatefulWidget {
  const PaginaHistoricoLiveloAndroid({
    super.key,
    required this.api,
    required this.parceiro,
    this.aoAbrirAlertas,
  });

  final Api api;
  final ParceiroCatalogoLivelo parceiro;
  final VoidCallback? aoAbrirAlertas;

  @override
  State<PaginaHistoricoLiveloAndroid> createState() =>
      _EstadoPaginaHistoricoLiveloAndroid();
}

class _EstadoPaginaHistoricoLiveloAndroid
    extends State<PaginaHistoricoLiveloAndroid> {
  HistoricoLivelo? _historico;
  Object? _erro;
  var _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final historico = await widget.api.historicoLivelo(
        widget.parceiro.idExterno,
      );
      if (mounted) setState(() => _historico = historico);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Tokens.fundo,
    appBar: _CabecalhoHistorico(aoAbrirAlertas: widget.aoAbrirAlertas),
    body: _corpo(),
  );

  Widget _corpo() {
    if (_carregando) return const Carregando(mensagem: 'Carregando histórico…');
    if (_erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o histórico desta loja.',
        voltar: _carregar,
      );
    }
    final medicoes = _historico!.medicoes;
    if (medicoes.isEmpty) {
      return EstadoVazio(
        mensagem:
            'Ainda não há medições históricas para ${widget.parceiro.nome}.',
      );
    }
    final atual = pontosLivelo(
      widget.parceiro.pontosAtuais,
      moeda: widget.parceiro.moeda,
    );
    return ListView(
      key: const Key('historico-livelo-android'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        const IndicadorEstadoRadar(
          texto: 'Pontuação salva',
          tom: TomRadar.acao,
        ),
        const SizedBox(height: 8),
        CabecalhoSecaoRadar(
          titulo: 'Histórico',
          descricao: 'Últimas coletas registradas no banco.',
        ),
        const SizedBox(height: 3),
        Text(
          widget.parceiro.nome,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CoresRadar.de(context).textoSuave,
          ),
        ),
        const SizedBox(height: 20),
        CartaoRadar(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      atual,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    'Melhor atual',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: CoresRadar.de(context).ganho,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),
              for (var indice = 0; indice < medicoes.length; indice++) ...[
                _LinhaMedicao(medicao: medicoes[indice]),
                if (indice != medicoes.length - 1) const Divider(height: 22),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _AvisoHistorico(),
      ],
    );
  }
}

class _CabecalhoHistorico extends StatelessWidget
    implements PreferredSizeWidget {
  const _CabecalhoHistorico({this.aoAbrirAlertas});

  final VoidCallback? aoAbrirAlertas;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Tokens.marca,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        tooltip: 'Voltar para Livelo',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          const LogoRadar(tamanho: 30),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Radar',
                style: tema.textTheme.titleSmall?.copyWith(
                  color: Tokens.marca,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Histórico',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: CoresRadar.de(context).textoSuave,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        const ControleAparenciaRadar.icone(),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Abrir alertas',
          onPressed: aoAbrirAlertas,
          icon: const Icon(Icons.notifications_none_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _LinhaMedicao extends StatelessWidget {
  const _LinhaMedicao({required this.medicao});

  final MedicaoHistoricoLivelo medicao;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: cores.acao.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Icon(Icons.check, color: cores.acao, size: 19),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pontosLivelo(medicao.pontos, moeda: medicao.moeda),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                'Coleta concluída',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cores.textoSuave),
              ),
            ],
          ),
        ),
        Text(
          dataHoraLivelo(medicao.momento).replaceFirst(', ', ' · '),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cores.textoSuave),
        ),
      ],
    );
  }
}

class _AvisoHistorico extends StatelessWidget {
  const _AvisoHistorico();

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.ganho.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.ganho.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule, color: cores.ganho, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'O histórico está disponível para qualquer loja do catálogo e mostra somente medições salvas; navegar aqui não inicia nova coleta.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cores.ganho,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
