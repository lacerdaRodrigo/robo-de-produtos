import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../administracao/botao_disparo.dart';
import 'cartao_catalogo_livelo.dart';
import 'controlador_catalogo_livelo.dart';
import 'formato_livelo.dart';
import 'pagina_historico_livelo_android.dart';

class PaginaCatalogoLiveloAndroid extends StatefulWidget {
  const PaginaCatalogoLiveloAndroid({
    super.key,
    required this.api,
    required this.administrador,
    this.aoAbrirAlertas,
    this.controlador,
    this.agora,
  });

  final Api api;
  final bool administrador;
  final VoidCallback? aoAbrirAlertas;
  final ControladorCatalogoLivelo? controlador;
  final DateTime Function()? agora;

  @override
  State<PaginaCatalogoLiveloAndroid> createState() =>
      _EstadoPaginaCatalogoLiveloAndroid();
}

class _EstadoPaginaCatalogoLiveloAndroid
    extends State<PaginaCatalogoLiveloAndroid> {
  static const _intervaloAcompanhamento = Duration(seconds: 30);
  static const _maximoTentativasAcompanhamento = 21;
  static const _maximoFalhasConsecutivas = 3;

  late final ControladorCatalogoLivelo _controlador =
      widget.controlador ??
      ControladorCatalogoLivelo(
        buscar:
            ({
              required q,
              required aba,
              required categoria,
              required ordenar,
              required pagina,
            }) => widget.api.catalogoLivelo(
              q: q,
              aba: aba,
              categoria: categoria,
              ordenar: ordenar,
              pagina: pagina,
            ),
        alterarAcompanhamento: ({required idExterno, required acompanhada}) =>
            widget.api.alterarAcompanhamentoLivelo(
              idExterno: idExterno,
              acompanhada: acompanhada,
            ),
        alterarAlerta: ({required idExterno, required ativo}) =>
            widget.api.alterarAlertaLivelo(idExterno: idExterno, ativo: ativo),
      );
  late final bool _controladorExterno = widget.controlador != null;
  final _busca = TextEditingController();
  final _rolagem = ScrollController();
  ResumoInicio? _resumoInicio;
  Timer? _timerMonitoramento;
  Timer? _atualizacaoSilenciosa;
  bool _resumoConsultando = false;
  bool _retratoAtualizando = false;
  int _versaoAcompanhamento = 0;
  int _tentativasAcompanhamento = 0;
  int _falhasConsecutivas = 0;

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
    _carregarResumoInicio();
    _timerMonitoramento = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _carregarResumoInicio() async {
    if (_resumoConsultando) return;
    _resumoConsultando = true;
    try {
      final resumo = await widget.api.resumo();
      if (mounted) setState(() => _resumoInicio = resumo);
    } catch (_) {
      // O catálogo continua útil com o último retrato mesmo se o resumo falhar.
    } finally {
      _resumoConsultando = false;
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
    _timerMonitoramento?.cancel();
    _encerrarAcompanhamento();
    if (!_controladorExterno) _controlador.dispose();
    super.dispose();
  }

  Future<void> _alternar(ParceiroCatalogoLivelo parceiro) async {
    final acompanhava = parceiro.acompanhada;
    final sucesso = await _controlador.alternarAcompanhamento(parceiro);
    if (!mounted) return;
    if (sucesso) {
      mostrarMensagemRadar(
        context,
        acompanhava
            ? 'Loja removida do acompanhamento.'
            : 'Loja adicionada ao acompanhamento.',
      );
      return;
    }
    mostrarMensagemRadar(
      context,
      'Não foi possível salvar. O estado anterior foi restaurado.',
      sucesso: false,
    );
  }

  Future<void> _alternarAlerta(ParceiroCatalogoLivelo parceiro) async {
    final sucesso = await _controlador.alternarAlerta(parceiro);
    if (!mounted) return;
    mostrarMensagemRadar(
      context,
      sucesso
          ? (parceiro.alertaAtivo
                ? 'Alerta desativado para esta loja.'
                : 'Alerta ativado para esta loja.')
          : 'Não foi possível salvar o alerta.',
      sucesso: sucesso,
    );
  }

  Future<void> _abrirHistorico(ParceiroCatalogoLivelo parceiro) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaginaHistoricoLiveloAndroid(
          api: widget.api,
          parceiro: parceiro,
          aoAbrirAlertas: widget.aoAbrirAlertas,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => CustomScrollView(
      key: const Key('catalogo-livelo-android'),
      controller: _rolagem,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
          sliver: SliverToBoxAdapter(
            child: CabecalhoSecaoRadar(
              sobrelinha: 'Programa de pontos',
              titulo: 'Livelo',
              descricao:
                  'Tudo da Livelo fica aqui: catálogo, acompanhadas, campanhas e alertas.',
            ),
          ),
        ),
        if (_controlador.resumo != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            sliver: SliverToBoxAdapter(
              child: _HeroCatalogo(
                resumo: _controlador.resumo!,
                agora: (widget.agora ?? DateTime.now)(),
              ),
            ),
          ),
        if (_resumoInicio != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            sliver: SliverToBoxAdapter(
              child: _SecaoMonitoramentoLivelo(
                agendamento: _resumoInicio!.livelo.agendamento,
                agora: (widget.agora ?? DateTime.now)(),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 15),
          sliver: SliverToBoxAdapter(
            child: AbasRadar(
              rotulos: AbaCatalogoLivelo.values
                  .map((aba) => aba.rotulo)
                  .toList(),
              selecionada: _controlador.aba.index,
              aoSelecionar: (indice) =>
                  _controlador.mudarAba(AbaCatalogoLivelo.values[indice]),
              acao: BotaoDisparo(
                api: widget.api,
                dominio: 'livelo',
                administrador: widget.administrador,
                rotulo: 'Atualizar',
                aoAceitar: _acompanharNovaColeta,
                compacto: true,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
          sliver: SliverToBoxAdapter(
            child: CampoBuscaRadar(
              controlador: _busca,
              dica: 'Buscar loja ou categoria',
              aoMudar: _controlador.mudarBusca,
              acao: IconButton(
                tooltip: 'Abrir filtros',
                onPressed: _abrirFiltros,
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
          ),
        ),
        if (_controlador.categorias.isNotEmpty)
          SliverToBoxAdapter(child: _categorias()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          sliver: SliverToBoxAdapter(
            child: _ResumoResultados(
              total: _controlador.totalItens,
              ordenacao: _controlador.ordenacao,
            ),
          ),
        ),
        ..._corpo(),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    ),
  );

  void _acompanharNovaColeta() {
    _encerrarAcompanhamento();
    final versao = _versaoAcompanhamento;
    _tentativasAcompanhamento = 0;
    _falhasConsecutivas = 0;
    unawaited(_atualizarRetratoSilencioso(versao));
    _atualizacaoSilenciosa = Timer.periodic(_intervaloAcompanhamento, (_) {
      unawaited(_atualizarRetratoSilencioso(versao));
    });
  }

  Future<void> _atualizarRetratoSilencioso(int versao) async {
    if (_retratoAtualizando || versao != _versaoAcompanhamento) return;
    _retratoAtualizando = true;
    _tentativasAcompanhamento += 1;
    try {
      await _carregarResumoInicio();
      if (!mounted || versao != _versaoAcompanhamento) return;
      final resultado = await _controlador.atualizarSilenciosamente();
      if (!mounted || versao != _versaoAcompanhamento) return;
      switch (resultado) {
        case ResultadoAtualizacaoSilenciosa.alterada:
          _encerrarAcompanhamento();
          mostrarMensagemRadar(context, 'Atualização concluída.');
          break;
        case ResultadoAtualizacaoSilenciosa.degradada:
          _encerrarAcompanhamento();
          mostrarMensagemRadar(
            context,
            'Atualização com qualidade reduzida. '
            'Mantivemos a última coleta válida.',
            sucesso: false,
          );
          break;
        case ResultadoAtualizacaoSilenciosa.falha:
          _falhasConsecutivas += 1;
          if (_falhasConsecutivas >= _maximoFalhasConsecutivas) {
            _encerrarAcompanhamento();
            mostrarMensagemRadar(
              context,
              'Não foi possível acompanhar a atualização. '
              'Ela pode continuar em segundo plano.',
              sucesso: false,
            );
          }
          break;
        case ResultadoAtualizacaoSilenciosa.inalterada:
          _falhasConsecutivas = 0;
          break;
      }
      if (versao == _versaoAcompanhamento &&
          _tentativasAcompanhamento >= _maximoTentativasAcompanhamento) {
        _encerrarAcompanhamento();
        mostrarMensagemRadar(
          context,
          'A conclusão ainda não foi confirmada. '
          'A atualização pode continuar em segundo plano.',
          sucesso: false,
        );
      }
    } finally {
      _retratoAtualizando = false;
    }
  }

  void _encerrarAcompanhamento() {
    _atualizacaoSilenciosa?.cancel();
    _atualizacaoSilenciosa = null;
    _versaoAcompanhamento += 1;
  }

  Future<void> _abrirFiltros() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    builder: (contexto) => FolhaRadar(
      titulo: 'Filtrar catálogo',
      descricao: 'A ordem e a categoria mudam somente os resultados já salvos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<OrdenacaoCatalogoLivelo>(
            initialValue: _controlador.ordenacao,
            decoration: const InputDecoration(labelText: 'Ordenar por'),
            onChanged: (valor) {
              if (valor == null) return;
              _controlador.mudarOrdenacao(valor);
              Navigator.of(contexto).pop();
            },
            items: [
              for (final valor in OrdenacaoCatalogoLivelo.values)
                DropdownMenuItem(value: valor, child: Text(valor.rotulo)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Categoria', style: Theme.of(contexto).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _controlador.categoria.isEmpty,
                onSelected: (_) {
                  _controlador.mudarCategoria('');
                  Navigator.of(contexto).pop();
                },
              ),
              for (final categoria in _controlador.categorias)
                ChoiceChip(
                  label: Text(categoria),
                  selected: _controlador.categoria == categoria,
                  onSelected: (_) {
                    _controlador.mudarCategoria(categoria);
                    Navigator.of(contexto).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _categorias() => SizedBox(
    height: MediaQuery.textScalerOf(context).scale(37).clamp(42, 56),
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      scrollDirection: Axis.horizontal,
      children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: _controlador.categoria.isEmpty,
          onSelected: (_) => _controlador.mudarCategoria(''),
        ),
        for (final categoria in _controlador.categorias) ...[
          const SizedBox(width: 7),
          ChoiceChip(
            label: Text(categoria),
            selected: _controlador.categoria == categoria,
            onSelected: (_) => _controlador.mudarCategoria(categoria),
          ),
        ],
      ],
    ),
  );

  List<Widget> _corpo() {
    if (_controlador.carregandoInicial) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Carregando(mensagem: 'Carregando catálogo Livelo…'),
          ),
        ),
      ];
    }
    if (_controlador.erroInicial != null) {
      return [
        SliverToBoxAdapter(
          child: EstadoFalha(
            mensagem: 'Não foi possível carregar o catálogo Livelo.',
            voltar: _controlador.tentarNovamente,
          ),
        ),
      ];
    }
    final resumo = _controlador.resumo;
    if (resumo == null || resumo.ultimaColeta == null) {
      return const [
        SliverToBoxAdapter(
          child: EstadoVazio(
            mensagem: 'O catálogo Livelo ainda não foi sincronizado.',
          ),
        ),
      ];
    }
    if (_controlador.totalItens == 0) {
      final mensagem = switch (_controlador.aba) {
        AbaCatalogoLivelo.acompanhadas =>
          'Nenhuma loja está acompanhada. Escolha uma na aba Lojas.',
        AbaCatalogoLivelo.alertas =>
          'Nenhuma loja acompanhada cruzou a régua na última coleta.',
        AbaCatalogoLivelo.lojas =>
          _controlador.busca.trim().isNotEmpty ||
                  _controlador.categoria.isNotEmpty
              ? 'Nenhuma loja corresponde aos filtros atuais.'
              : 'A última coleta não publicou parceiros válidos.',
      };
      return [SliverToBoxAdapter(child: EstadoVazio(mensagem: mensagem))];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: _controlador.itens.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, indice) {
            final parceiro = _controlador.itens[indice];
            return CartaoCatalogoLivelo(
              parceiro: parceiro,
              pendente: _controlador.mutacoesPendentes.contains(
                parceiro.idExterno,
              ),
              alertaPendente: _controlador.mutacoesPendentes.contains(
                'alerta:${parceiro.idExterno}',
              ),
              podeAdministrar: widget.administrador,
              aoAlternar: () => _alternar(parceiro),
              aoAlternarAlerta: () => _alternarAlerta(parceiro),
              aoHistorico: () => _abrirHistorico(parceiro),
            );
          },
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverToBoxAdapter(child: _paginacao()),
      ),
    ];
  }

  Widget _paginacao() {
    if (_controlador.carregandoMais) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controlador.erroMais != null) {
      return FilledButton.tonalIcon(
        onPressed: _controlador.carregarMais,
        icon: const Icon(Icons.refresh),
        label: const Text('Tentar carregar mais'),
      );
    }
    if (_controlador.temProxima) {
      return FilledButton(
        onPressed: _controlador.carregarMais,
        child: const Text('Carregar mais'),
      );
    }
    return const Center(child: Text('Todos os resultados foram carregados.'));
  }
}

class _HeroCatalogo extends StatelessWidget {
  const _HeroCatalogo({required this.resumo, required this.agora});
  final ResumoCatalogoLivelo resumo;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final melhor = resumo.melhorOferta;
    final atrasada = coletaAtrasada(resumo.ultimaColeta, agora);
    final degradada = resumo.qualidade == 'degradada';
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Tokens.marcaProfunda, Tokens.marcaMedia],
                ),
              ),
            ),
          ),
          Positioned(
            right: -52,
            bottom: -100,
            child: _ArcosDoHero(cor: Colors.white.withValues(alpha: 0.07)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SeloHeroLivelo(
                  texto: degradada
                      ? 'Dados com qualidade reduzida'
                      : atrasada
                      ? 'Dados atrasados'
                      : 'Última coleta concluída',
                  atencao: degradada || atrasada,
                ),
                const SizedBox(height: 12),
                if (degradada) ...[
                  const Text(
                    'A última atualização foi incompleta. '
                    'Exibindo a última coleta válida.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  melhor == null
                      ? 'Nenhuma loja acompanhada agora.'
                      : '${pontosLivelo(melhor.pontosAtuais, moeda: melhor.moeda)} é a melhor acompanhada agora.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                if (melhor != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    melhor.nome,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ] else ...[
                  const SizedBox(height: 7),
                  const Text(
                    'Escolha uma loja na aba Lojas para acompanhar a pontuação atual.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Coleta: ${dataHoraLivelo(resumo.ultimaColeta)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 18),
                _MetricasCatalogo(resumo: resumo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonitoramentoLivelo extends StatelessWidget {
  const _MonitoramentoLivelo({required this.agendamento, required this.agora});
  final AgendamentoLivelo agendamento;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final referencia = DateTime.tryParse(agendamento.referenciaEm)?.toLocal();
    final diferenca = referencia?.difference(agora.toLocal());
    final horario = referencia == null
        ? null
        : '${referencia.hour.toString().padLeft(2, '0')}:${referencia.minute.toString().padLeft(2, '0')}';
    final texto = agendamento.aguardando
        ? 'Aguardando o robô · atraso de ${_duracao(diferenca == null ? null : -diferenca)}'
        : (diferenca == null ||
              diferenca.isNegative ||
              diferenca == Duration.zero)
        ? 'Aguardando o robô · atraso de ${_duracao(diferenca == null ? null : -diferenca)}'
        : 'Próxima coleta Livelo: ${horario ?? '—'} (em ${_duracao(diferenca)})';
    return CartaoRadar(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texto,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            agendamento.aguardando ||
                    diferenca == null ||
                    diferenca.isNegative ||
                    diferenca == Duration.zero
                ? 'Janela ${horario ?? '—'} · a primeira execução concluída encerra o atraso.'
                : 'Prevista pelo cron às ${horario ?? '—'} · horário de Brasília.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
            ),
          ),
          const SizedBox(height: 10),
          _FaixaMonitoramento(aguardando: agendamento.aguardando),
        ],
      ),
    );
  }
}

class _SecaoMonitoramentoLivelo extends StatelessWidget {
  const _SecaoMonitoramentoLivelo({
    required this.agendamento,
    required this.agora,
  });

  final AgendamentoLivelo agendamento;
  final DateTime agora;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Monitoramento da coleta',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.7,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        'Previsão e atraso são estados diferentes',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: CoresRadar.de(context).textoSuave,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 12),
      _MonitoramentoLivelo(agendamento: agendamento, agora: agora),
    ],
  );
}

class _FaixaMonitoramento extends StatelessWidget {
  const _FaixaMonitoramento({required this.aguardando});
  final bool aguardando;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.ganho.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cores.ganho.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.schedule_outlined, color: cores.ganho, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                aguardando
                    ? 'A primeira coleta concluída reinicia o timer.'
                    : 'Depois da janela, o cartão passa a mostrar o atraso do robô.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cores.ganho,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeloHeroLivelo extends StatelessWidget {
  const _SeloHeroLivelo({required this.texto, required this.atencao});

  final String texto;
  final bool atencao;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(RaioRadar.pilula),
      border: Border.all(color: Colors.white.withValues(alpha: 0.17)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 7,
            color: atencao ? Tokens.atencaoEscuro : Tokens.ganhoEscuro,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFDFF8FF),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _duracao(Duration? duracao) {
  if (duracao == null) return '—';
  final segundos = duracao.inSeconds.clamp(0, 1 << 31).toInt();
  if (segundos < 60) return 'menos de 1 min';
  final minutos = segundos ~/ 60;
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (horas == 0) return '$minutos min';
  return resto == 0 ? '$horas h' : '$horas h $resto min';
}

class _ArcosDoHero extends StatelessWidget {
  const _ArcosDoHero({required this.cor});

  final Color cor;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 235,
    height: 235,
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: cor, width: 28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(29),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cor, width: 28),
          ),
        ),
      ),
    ),
  );
}

class _MetricasCatalogo extends StatelessWidget {
  const _MetricasCatalogo({required this.resumo});
  final ResumoCatalogoLivelo resumo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, limites) {
      final metricas = [
        _Metrica(valor: '${resumo.acompanhadas}', rotulo: 'acompanhadas'),
        _Metrica(valor: '${resumo.alertasAtivos}', rotulo: 'alertas ativos'),
        _Metrica(valor: '${resumo.totalCatalogo}', rotulo: 'no catálogo'),
      ];
      if (limites.maxWidth < 240) {
        return Column(
          children: [
            for (var indice = 0; indice < metricas.length; indice++) ...[
              metricas[indice],
              if (indice != metricas.length - 1) const SizedBox(height: 8),
            ],
          ],
        );
      }
      return Row(
        children: [
          for (var indice = 0; indice < metricas.length; indice++) ...[
            Expanded(child: metricas[indice]),
            if (indice != metricas.length - 1) const SizedBox(width: 8),
          ],
        ],
      );
    },
  );
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.valor, required this.rotulo});
  final String valor;
  final String rotulo;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: Column(
      children: [
        Text(
          valor,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          rotulo,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white70, fontSize: 10),
        ),
      ],
    ),
  );
}

class _ResumoResultados extends StatelessWidget {
  const _ResumoResultados({required this.total, required this.ordenacao});

  final int total;
  final OrdenacaoCatalogoLivelo ordenacao;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(Icons.tune_rounded, size: 17, color: CoresRadar.de(context).acao),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          '$total resultados · ${ordenacao.rotulo}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
          ),
        ),
      ),
    ],
  );
}
