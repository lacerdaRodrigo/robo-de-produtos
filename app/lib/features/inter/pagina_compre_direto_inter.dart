import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';
import '../administracao/botao_disparo.dart';
import '../administracao/controlador_catalogo_administracao.dart';
import '../produtos/arvore_categorias_radar.dart';
import 'controlador_categorias_acompanhadas.dart';

/// Catálogo mobile do Compre direto com busca e paginação fornecidas pela API.
class PaginaCompreDiretoInter extends StatefulWidget {
  const PaginaCompreDiretoInter({
    super.key,
    required this.api,
    required this.administrador,
    required this.sliversAntes,
    this.controlador,
    this.controladorCategorias,
    this.aoAtualizar,
    this.ordenacaoInicial = 'nome',
    this.filtroInicial = 'todas',
    this.aoMudarConsulta,
    this.totalSelecionadas,
    this.aoVariarSelecionadas,
    this.aoSalvarCategoriasAcompanhadas,
  });

  final Api api;
  final bool administrador;
  final List<Widget> sliversAntes;
  final ControladorCatalogoAdministracao<LojaDireto>? controlador;
  final ControladorCategoriasAcompanhadas? controladorCategorias;
  final Future<void> Function()? aoAtualizar;
  final String ordenacaoInicial;
  final String filtroInicial;
  final void Function({required String ordenar, required String filtro})?
  aoMudarConsulta;
  final int? totalSelecionadas;
  final ValueChanged<int>? aoVariarSelecionadas;
  final Future<void> Function(bool salvo)? aoSalvarCategoriasAcompanhadas;

  @override
  State<PaginaCompreDiretoInter> createState() =>
      _EstadoPaginaCompreDiretoInter();
}

class _EstadoPaginaCompreDiretoInter extends State<PaginaCompreDiretoInter>
    with WidgetsBindingObserver {
  late final ControladorCatalogoAdministracao<LojaDireto> _controlador =
      widget.controlador ??
      ControladorCatalogoAdministracao<LojaDireto>(
        buscar: ({required q, required pagina}) => widget.api.lojasDiretas(
          q: q,
          pagina: pagina,
          ordenar: 'nome',
          filtro: _filtro == _FiltroCompreDireto.acompanhadas
              ? 'acompanhadas'
              : 'todas',
        ),
        identificar: (loja) => loja.id,
      );
  late final ControladorCategoriasAcompanhadas _controladorCategorias =
      widget.controladorCategorias ??
      ControladorCategoriasAcompanhadas(
        carregar: widget.api.categoriasRadar,
        salvar: widget.api.salvarCategoriasRadar,
      );
  late final bool _controladorExterno = widget.controlador != null;
  late final _busca = TextEditingController(text: _controlador.busca);
  final _alterando = <String>{};
  late var _filtro = widget.filtroInicial == 'acompanhadas'
      ? _FiltroCompreDireto.acompanhadas
      : _FiltroCompreDireto.todas;
  var _totalTodasConhecido = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.administrador) {
      if (_controlador.itens.isEmpty) _controlador.carregarPrimeira();
      _controladorCategorias.carregarAcompanhadas();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _busca.dispose();
    if (!_controladorExterno) _controlador.dispose();
    if (widget.controladorCategorias == null) {
      _controladorCategorias.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_atualizarDados());
    }
  }

  Future<void> _atualizarDados() async {
    final tarefas = <Future<void>>[];
    if (widget.administrador) {
      tarefas.add(_controlador.reiniciarConsulta());
      tarefas.add(_controladorCategorias.carregarAcompanhadas());
    }
    final atualizarResumo = widget.aoAtualizar;
    if (atualizarResumo != null) tarefas.add(atualizarResumo());
    await Future.wait(tarefas);
  }

  Future<void> _configurarCategorias() async {
    final catalogo = _controladorCategorias.catalogo;
    if (catalogo == null || _controladorCategorias.salvando) return;
    final selecionadas = await mostrarSeletorCategoriasAcompanhadas(
      context,
      categorias: catalogo.itens,
      selecionadasIniciais: _controladorCategorias.slugsSelecionadosDiretos,
    );
    if (selecionadas == null || !mounted) return;
    final salvo = await _controladorCategorias.salvarSelecao(selecionadas);
    if (!mounted) return;
    if (salvo) {
      mostrarMensagemRadar(
        context,
        'Categorias acompanhadas salvas para as lojas selecionadas.',
      );
    } else {
      mostrarMensagemRadar(
        context,
        'Não foi possível salvar as categorias. '
        'A seleção anterior foi preservada. Tente novamente.',
        sucesso: false,
      );
    }
    final avisar = widget.aoSalvarCategoriasAcompanhadas;
    if (avisar != null) await avisar(salvo);
  }

  Future<void> _alternar(LojaDireto loja) async {
    if (!widget.administrador || _alterando.contains(loja.id) || !loja.ativa) {
      return;
    }
    setState(() => _alterando.add(loja.id));
    final selecionada = !loja.selecionada;
    try {
      await widget.api.alterarSelecaoLojaDireta(
        id: loja.id,
        selecionada: selecionada,
      );
      if (_filtro == _FiltroCompreDireto.acompanhadas && !selecionada) {
        _controlador.remover(loja.id);
      } else {
        _controlador.substituir(
          loja.id,
          loja.copiarCom(selecionada: selecionada),
        );
      }
      widget.aoVariarSelecionadas?.call(selecionada ? 1 : -1);
      if (!mounted) return;
      mostrarMensagemRadar(
        context,
        selecionada
            ? 'Loja selecionada para a próxima coleta.'
            : 'Loja removida da próxima coleta.',
      );
    } catch (erro) {
      if (!mounted) return;
      mostrarMensagemRadar(
        context,
        erro is ErroDeApi
            ? erro.mensagem
            : 'Não foi possível alterar a seleção.',
        sucesso: false,
      );
    } finally {
      if (mounted) setState(() => _alterando.remove(loja.id));
    }
  }

  Future<void> _selecionarFiltro(_FiltroCompreDireto filtro) async {
    if (_filtro == filtro) return;
    if (_filtro == _FiltroCompreDireto.todas) {
      _totalTodasConhecido = _controlador.total;
    }
    setState(() => _filtro = filtro);
    widget.aoMudarConsulta?.call(
      ordenar: 'nome',
      filtro: filtro == _FiltroCompreDireto.acompanhadas
          ? 'acompanhadas'
          : 'todas',
    );
    await _controlador.reiniciarConsulta();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => RefreshIndicator(
      key: const Key('puxar-atualizar-compre-direto-inter'),
      onRefresh: _atualizarDados,
      child: CustomScrollView(
        key: const PageStorageKey('compre-direto-inter'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          ...widget.sliversAntes,
          if (!widget.administrador)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 24),
              sliver: SliverToBoxAdapter(
                child: EstadoVazio(
                  mensagem:
                      'A seleção de lojas do Compre direto exige autorização administrativa.',
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              sliver: SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _controladorCategorias,
                  builder: (context, _) => _CartaoCategoriasAcompanhadas(
                    controlador: _controladorCategorias,
                    aoConfigurar: _configurarCategorias,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              sliver: SliverToBoxAdapter(
                child: CampoBuscaRadar(
                  chaveCampo: const Key('busca-compre-direto'),
                  controlador: _busca,
                  dica: 'Buscar loja no Compre direto',
                  aoMudar: _controlador.mudarBusca,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FiltrosCompreDireto(
                selecionado: _filtro,
                totalTodas: _totalTodas,
                totalSelecionadas: _totalSelecionadas,
                aoSelecionar: _selecionarFiltro,
              ),
            ),
            if (!_controlador.carregandoInicial &&
                _controlador.erroInicial == null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 11),
                sliver: SliverToBoxAdapter(
                  child: _BarraResultadosCompreDireto(
                    total: _controlador.total,
                    selecionadas: _filtro == _FiltroCompreDireto.acompanhadas,
                    api: widget.api,
                    administrador: widget.administrador,
                  ),
                ),
              ),
            ..._corpo(),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    ),
  );

  int get _totalTodas => _filtro == _FiltroCompreDireto.todas
      ? _controlador.total
      : _totalTodasConhecido;

  int get _totalSelecionadas =>
      widget.totalSelecionadas ??
      (_filtro == _FiltroCompreDireto.acompanhadas
          ? _controlador.total
          : _controlador.itens.where((loja) => loja.selecionada).length);

  List<Widget> _corpo() {
    if (_controlador.carregandoInicial && _controlador.itens.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Carregando(mensagem: 'Carregando lojas do Compre direto…'),
        ),
      ];
    }
    if (_controlador.erroInicial != null && _controlador.itens.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EstadoFalha(
            mensagem: 'Não foi possível carregar as lojas do Compre direto.',
            voltar: _controlador.carregarPrimeira,
          ),
        ),
      ];
    }
    if (_controlador.itens.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EstadoVazio(
            mensagem: _filtro == _FiltroCompreDireto.acompanhadas
                ? 'Nenhuma loja está selecionada para coleta.'
                : 'Nenhuma loja corresponde à busca atual.',
          ),
        ),
      ];
    }
    final lojas = _controlador.itens;
    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: lojas.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, indice) {
            final loja = lojas[indice];
            return _CartaoLojaDireta(
              loja: loja,
              alterando: _alterando.contains(loja.id),
              aoAlternar: () => _alternar(loja),
            );
          },
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(18),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: _controlador.carregandoMais
                ? const CircularProgressIndicator()
                : _controlador.erroMais != null
                ? OutlinedButton.icon(
                    onPressed: _controlador.carregarMais,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar carregar mais'),
                  )
                : _controlador.temProxima
                ? FilledButton(
                    onPressed: _controlador.carregarMais,
                    child: const Text('Carregar mais'),
                  )
                : const Text('Todas as lojas foram carregadas.'),
          ),
        ),
      ),
    ];
  }
}

enum _FiltroCompreDireto { todas, acompanhadas }

class _CartaoCategoriasAcompanhadas extends StatelessWidget {
  const _CartaoCategoriasAcompanhadas({
    required this.controlador,
    required this.aoConfigurar,
  });

  final ControladorCategoriasAcompanhadas controlador;
  final VoidCallback aoConfigurar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final escuro = tema.brightness == Brightness.dark;
    final carregando = controlador.carregando && controlador.catalogo == null;
    final comErro = controlador.erro != null && controlador.catalogo == null;
    final subtitulo = carregando
        ? 'Carregando as categorias acompanhadas…'
        : comErro
        ? 'Não foi possível carregar as categorias.'
        : controlador.resumo;
    return CartaoRadar(
      padding: const EdgeInsets.fromLTRB(13, 12, 11, 12),
      child: LayoutBuilder(
        builder: (context, limites) {
          final icone = Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: escuro ? Tokens.superficieForteEscura : Tokens.plumSoft,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
                bottomLeft: Radius.circular(5),
              ),
            ),
            child: Icon(Icons.topic_outlined, size: 21, color: cores.marca),
          );
          final texto = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categorias acompanhadas',
                style: tema.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitulo,
                style: tema.textTheme.labelSmall?.copyWith(
                  color: cores.textoSuave,
                  fontSize: 9,
                  height: 1.4,
                ),
              ),
            ],
          );
          final botao = _botao(
            context,
            carregando: carregando,
            comErro: comErro,
          );
          final empilhar =
              limites.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(10) > 12;
          if (empilhar) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    icone,
                    const SizedBox(width: 11),
                    Expanded(child: texto),
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: botao),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              icone,
              const SizedBox(width: 11),
              Expanded(child: texto),
              const SizedBox(width: 8),
              botao,
            ],
          );
        },
      ),
    );
  }

  Widget _botao(
    BuildContext context, {
    required bool carregando,
    required bool comErro,
  }) {
    if (controlador.salvando || carregando) {
      return const SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (comErro) {
      return OutlinedButton(
        key: const Key('recarregar-categorias-acompanhadas'),
        onPressed: controlador.carregarAcompanhadas,
        child: const Text('Tentar novamente'),
      );
    }
    return OutlinedButton(
      key: const Key('configurar-categorias-acompanhadas'),
      onPressed: controlador.catalogo == null ? null : aoConfigurar,
      child: const Text('Configurar'),
    );
  }
}

class _FiltrosCompreDireto extends StatelessWidget {
  const _FiltrosCompreDireto({
    required this.selecionado,
    required this.totalTodas,
    required this.totalSelecionadas,
    required this.aoSelecionar,
  });

  final _FiltroCompreDireto selecionado;
  final int totalTodas;
  final int totalSelecionadas;
  final ValueChanged<_FiltroCompreDireto> aoSelecionar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
    child: AbasRadar(
      rotulos: const ['Todas', 'Selecionadas'],
      contadores: [totalTodas, totalSelecionadas],
      expandir: true,
      selecionada: selecionado.index,
      aoSelecionar: (indice) =>
          aoSelecionar(_FiltroCompreDireto.values[indice]),
    ),
  );
}

class _BarraResultadosCompreDireto extends StatelessWidget {
  const _BarraResultadosCompreDireto({
    required this.total,
    required this.selecionadas,
    required this.api,
    required this.administrador,
  });

  final int total;
  final bool selecionadas;
  final Api api;
  final bool administrador;

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
          selecionadas
              ? 'Selecionadas para a próxima coleta'
              : 'Disponíveis para seleção',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 9,
          ),
        ),
      ],
    );
    final atualizar = BotaoDisparo(
      api: api,
      dominio: 'produtos_inter',
      administrador: administrador,
      rotulo: 'Atualizar produtos',
      compacto: true,
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
          final estreito =
              limites.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(10) > 12;
          if (estreito) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                resumo,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: atualizar),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: resumo),
              const SizedBox(width: 12),
              atualizar,
            ],
          );
        },
      ),
    );
  }
}

class _CartaoLojaDireta extends StatelessWidget {
  const _CartaoLojaDireta({
    required this.loja,
    required this.alterando,
    required this.aoAlternar,
  });

  final LojaDireto loja;
  final bool alterando;
  final VoidCallback aoAlternar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final escuro = tema.brightness == Brightness.dark;
    final corAcao = escuro ? Tokens.acaoForteEscura : Tokens.actionStrong;
    final fundoAcao = escuro ? Tokens.acaoFundoEscuro : Tokens.actionSoft;
    final fundoGanho = escuro ? Tokens.ganhoFundoEscuro : Tokens.positiveSoft;
    final selecionada = loja.selecionada;
    final aviso = _avisoColeta(loja);
    return Opacity(
      opacity: loja.ativa ? 1 : 0.7,
      child: CartaoRadar(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: escuro
                          ? Tokens.superficieForteEscura
                          : Tokens.plumSoft,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                        bottomLeft: Radius.circular(5),
                      ),
                    ),
                    child: Text(
                      _iniciais(loja.nome),
                      style: TextStyle(
                        color: cores.marca,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loja.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tema.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Compre direto',
                          style: tema.textTheme.labelSmall?.copyWith(
                            color: cores.textoSuave,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _beneficioDireto(loja),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: tema.textTheme.titleSmall?.copyWith(
                        color: corAcao,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: cores.superficieAlternativa,
                border: Border(top: BorderSide(color: cores.borda)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _DadoResumoDireto(
                      rotulo: loja.produtosEncontrados == null
                          ? 'Produtos'
                          : 'Último catálogo',
                      valor: loja.produtosEncontrados == null
                          ? 'Após a primeira coleta'
                          : _quantidadeProdutos(loja.produtosEncontrados),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DadoResumoDireto(
                      rotulo: 'Seleção',
                      valor: selecionada ? 'Selecionada' : 'Não selecionada',
                      alinharFim: true,
                    ),
                  ),
                ],
              ),
            ),
            if (aviso != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                child: Text(
                  aviso,
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: loja.ultimaTentativaEstado == 'falha'
                        ? cores.perigo
                        : cores.atencao,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 11, 15, 14),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: ValueKey('selecionar-loja-direta-${loja.id}'),
                  onPressed: loja.ativa && !alterando ? aoAlternar : null,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    backgroundColor: selecionada ? fundoGanho : fundoAcao,
                    foregroundColor: selecionada ? cores.ganho : corAcao,
                    disabledBackgroundColor: cores.superficieAlternativa,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                      side: BorderSide(
                        color: (selecionada ? cores.ganho : corAcao).withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                  child: alterando
                      ? const SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          loja.ativa
                              ? selecionada
                                    ? 'Selecionada para coleta'
                                    : 'Selecionar loja'
                              : 'Indisponível',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DadoResumoDireto extends StatelessWidget {
  const _DadoResumoDireto({
    required this.rotulo,
    required this.valor,
    this.alinharFim = false,
  });

  final String rotulo;
  final String valor;
  final bool alinharFim;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alinharFim
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        rotulo,
        textAlign: alinharFim ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: CoresRadar.de(context).textoSuave,
          fontSize: 9,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        valor,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: alinharFim ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

String? _avisoColeta(LojaDireto loja) {
  if (!loja.ativa) return 'Loja inativa; seleção indisponível.';
  return switch (loja.ultimaTentativaEstado) {
    'iniciada' => 'Coleta em andamento.',
    'falha' => 'A última tentativa falhou; exibindo o último catálogo válido.',
    'parcial' => 'A última coleta foi parcial; exibindo os dados preservados.',
    _ => null,
  };
}

String _quantidadeProdutos(int? quantidade) {
  if (quantidade == null) return 'Indisponível';
  return '$quantidade produto${quantidade == 1 ? '' : 's'}';
}

String _beneficioDireto(LojaDireto loja) {
  if (!loja.ativa) return 'Indisponível';
  var valor = loja.cashbackResumoTexto?.trim() ?? '';
  if (valor.isEmpty) return 'Disponível';
  const sufixo = ' de cashback';
  if (valor.toLowerCase().endsWith(sufixo)) {
    valor = valor.substring(0, valor.length - sufixo.length);
  }
  if (valor.isEmpty) return 'Disponível';
  return '${valor[0].toLowerCase()}${valor.substring(1)}';
}

String _iniciais(String nome) {
  final partes = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((parte) => parte.isNotEmpty)
      .take(2);
  final valor = partes.map((parte) => parte.substring(0, 1)).join();
  return valor.isEmpty ? '•' : valor.toUpperCase();
}
