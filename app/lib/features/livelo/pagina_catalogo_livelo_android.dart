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
  });

  final Api api;
  final bool administrador;
  final VoidCallback? aoAbrirAlertas;
  final ControladorCatalogoLivelo? controlador;

  @override
  State<PaginaCatalogoLiveloAndroid> createState() =>
      _EstadoPaginaCatalogoLiveloAndroid();
}

class _EstadoPaginaCatalogoLiveloAndroid
    extends State<PaginaCatalogoLiveloAndroid> {
  static const _intervaloAcompanhamento = Duration(seconds: 30);
  static const _maximoTentativasAcompanhamento = 21;
  static const _maximoFalhasConsecutivas = 3;
  static const _abasVisiveis = [
    AbaCatalogoLivelo.lojas,
    AbaCatalogoLivelo.acompanhadas,
  ];

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
  Timer? _atualizacaoSilenciosa;
  bool _retratoAtualizando = false;
  int _versaoAcompanhamento = 0;
  int _tentativasAcompanhamento = 0;
  int _falhasConsecutivas = 0;

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
  }

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
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

  Future<void> _abrirDetalhes(ParceiroCatalogoLivelo parceiro) async {
    final abrirHistorico = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (contexto) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(contexto).height * 0.9,
        ),
        child: FolhaRadar(
          titulo: parceiro.nome,
          descricao: 'Dados do contrato Livelo',
          child: Flexible(
            child: SingleChildScrollView(
              child: _DetalhesParceiroLivelo(
                parceiro: parceiro,
                aoAbrirHistorico: () => Navigator.of(contexto).pop(true),
              ),
            ),
          ),
        ),
      ),
    );
    if (abrirHistorico == true && mounted) await _abrirHistorico(parceiro);
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
                  'Tudo da Livelo fica aqui: catálogo, acompanhadas e campanhas.',
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
              dica: 'Buscar loja',
              aoMudar: _controlador.mudarBusca,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverToBoxAdapter(
            child: AbasRadar(
              rotulos: _abasVisiveis.map((aba) => aba.rotulo).toList(),
              contadores: [
                _controlador.resumo?.totalCatalogo ?? 0,
                _controlador.resumo?.acompanhadas ?? 0,
              ],
              expandir: true,
              selecionada: _abasVisiveis.indexOf(_controlador.aba).clamp(0, 1),
              aoSelecionar: (indice) =>
                  _controlador.mudarAba(_abasVisiveis[indice]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 11),
          sliver: SliverToBoxAdapter(
            child: _ResumoResultados(
              total: _controlador.totalItens,
              contexto: _contextoResultados,
              mostrarFiltro: _controlador.aba == AbaCatalogoLivelo.lojas,
              filtroAtivo:
                  _controlador.categoria.isNotEmpty ||
                  _controlador.ordenacao != OrdenacaoCatalogoLivelo.nome,
              aoFiltrar: _abrirFiltros,
            ),
          ),
        ),
        ..._corpo(),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    ),
  );

  String get _contextoResultados {
    if (_controlador.aba == AbaCatalogoLivelo.acompanhadas) {
      return 'Suas lojas favoritas';
    }
    if (_controlador.categoria.isNotEmpty) return _controlador.categoria;
    if (_controlador.busca.trim().isNotEmpty) return 'Busca no catálogo';
    return 'Catálogo completo';
  }

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

  Future<void> _abrirFiltros() async {
    var ordenacao = _controlador.ordenacao;
    var categoria = _controlador.categoria;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      builder: (contexto) => StatefulBuilder(
        builder: (contexto, atualizar) => FolhaRadar(
          titulo: 'Filtrar todas as lojas',
          descricao: 'Refine o catálogo completo da Livelo.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('categoria-filtro-livelo'),
                initialValue: categoria,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Categoria'),
                onChanged: (valor) {
                  if (valor != null) atualizar(() => categoria = valor);
                },
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Todas as categorias'),
                  ),
                  for (final valor in _controlador.categorias)
                    DropdownMenuItem(value: valor, child: Text(valor)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OrdenacaoCatalogoLivelo>(
                key: const Key('ordenacao-filtro-livelo'),
                initialValue: ordenacao,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ordenar por'),
                onChanged: (valor) {
                  if (valor != null) atualizar(() => ordenacao = valor);
                },
                items: [
                  for (final valor in OrdenacaoCatalogoLivelo.values)
                    DropdownMenuItem(value: valor, child: Text(valor.rotulo)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(contexto).pop();
                        unawaited(
                          _controlador.aplicarFiltros(
                            categoria: '',
                            ordenacao: OrdenacaoCatalogoLivelo.nome,
                          ),
                        );
                      },
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(contexto).pop();
                        unawaited(
                          _controlador.aplicarFiltros(
                            categoria: categoria,
                            ordenacao: ordenacao,
                          ),
                        );
                      },
                      child: const Text('Ver lojas'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              aoDetalhes: () => _abrirDetalhes(parceiro),
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

class _ResumoResultados extends StatelessWidget {
  const _ResumoResultados({
    required this.total,
    required this.contexto,
    required this.mostrarFiltro,
    required this.filtroAtivo,
    required this.aoFiltrar,
  });

  final int total;
  final String contexto;
  final bool mostrarFiltro;
  final bool filtroAtivo;
  final VoidCallback aoFiltrar;

  @override
  Widget build(BuildContext context) {
    final resumo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$total ${total == 1 ? 'loja encontrada' : 'lojas encontradas'}',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          contexto,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 9,
          ),
        ),
      ],
    );
    final botao = OutlinedButton.icon(
      key: const Key('filtrar-ordenar-livelo'),
      onPressed: aoFiltrar,
      style: OutlinedButton.styleFrom(
        foregroundColor: filtroAtivo
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Tokens.acaoForteEscura
                  : Tokens.actionStrong)
            : null,
        backgroundColor: filtroAtivo
            ? (Theme.of(context).brightness == Brightness.dark
                  ? Tokens.acaoFundoEscuro
                  : Tokens.actionSoft)
            : null,
        side: filtroAtivo
            ? BorderSide(
                color: CoresRadar.de(context).acao.withValues(alpha: 0.48),
              )
            : null,
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      icon: Icon(
        Icons.filter_list_rounded,
        size: 17,
        color: Theme.of(context).brightness == Brightness.dark
            ? Tokens.acaoForteEscura
            : Tokens.actionStrong,
      ),
      label: const Text('Filtrar e ordenar'),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 2, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CoresRadar.de(context).borda.withValues(alpha: 0.76),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, limites) {
          if (!mostrarFiltro) return resumo;
          final estreito =
              limites.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(10) > 12;
          if (estreito) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                resumo,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: botao),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: resumo),
              const SizedBox(width: 12),
              botao,
            ],
          );
        },
      ),
    );
  }
}

class _DetalhesParceiroLivelo extends StatelessWidget {
  const _DetalhesParceiroLivelo({
    required this.parceiro,
    required this.aoAbrirHistorico,
  });

  final ParceiroCatalogoLivelo parceiro;
  final VoidCallback aoAbrirHistorico;

  @override
  Widget build(BuildContext context) {
    final campanha = parceiro.campanha?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LinhaDetalheLivelo(
          rotulo: 'Pontuação atual',
          valor: pontosLivelo(parceiro.pontosAtuais, moeda: parceiro.moeda),
        ),
        if (parceiro.pontosBase != null)
          _LinhaDetalheLivelo(
            rotulo: 'Pontuação base',
            valor: pontosLivelo(parceiro.pontosBase, moeda: parceiro.moeda),
          ),
        if (parceiro.pontosClube != null)
          _LinhaDetalheLivelo(
            rotulo: 'Clube Livelo',
            valor: pontosLivelo(parceiro.pontosClube, moeda: parceiro.moeda),
          ),
        if (campanha != null && campanha.isNotEmpty)
          _LinhaDetalheLivelo(rotulo: 'Campanha', valor: campanha),
        _LinhaDetalheLivelo(
          rotulo: 'Código externo',
          valor: parceiro.idExterno,
        ),
        const SizedBox(height: 14),
        Text(
          'Histórico',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'O endpoint retorna as últimas 30 medições salvas. '
          'Abrir o histórico nunca inicia uma coleta.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          key: Key('ver-historico-${parceiro.idExterno}'),
          onPressed: aoAbrirHistorico,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
          ),
          child: const Text('Ver histórico'),
        ),
      ],
    );
  }
}

class _LinhaDetalheLivelo extends StatelessWidget {
  const _LinhaDetalheLivelo({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: CoresRadar.de(context).borda)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            rotulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}
