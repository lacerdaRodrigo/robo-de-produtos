import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../administracao/botao_disparo.dart';
import 'cartao_cashback_inter.dart';
import 'controlador_cashback_inter.dart';
import 'formato_cashback_inter.dart';

/// Consulta somente leitura dos Sites parceiros do Inter (Fase 4.3).
class PaginaCashbackInter extends StatefulWidget {
  const PaginaCashbackInter({
    super.key,
    required this.api,
    this.controlador,
    this.administrador = false,
    this.incorporada = false,
    this.mostrarAtualizacao = true,
    this.sliversAntesDoCashback = const [],
    this.chaveRolagemCompacta,
  });

  final Api api;
  final ControladorCashbackInter? controlador;
  final bool administrador;
  final bool incorporada;
  final bool mostrarAtualizacao;

  /// Conteúdo que deve rolar antes da busca na experiência mobile integrada.
  final List<Widget> sliversAntesDoCashback;
  final Key? chaveRolagemCompacta;

  @override
  State<PaginaCashbackInter> createState() => _EstadoPaginaCashbackInter();
}

class _EstadoPaginaCashbackInter extends State<PaginaCashbackInter> {
  late final ControladorCashbackInter _controlador =
      widget.controlador ??
      ControladorCashbackInter(
        buscar: ({required q, required ordenar, required pagina}) => widget.api
            .painelCashbackInter(q: q, ordenar: ordenar, pagina: pagina),
      );
  late final bool _externo = widget.controlador != null;
  final _campoBusca = TextEditingController();
  final _acompanhamentoAlterado = <String, bool>{};
  var _filtroCompacto = 0;

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
  }

  @override
  void dispose() {
    _campoBusca.dispose();
    if (!_externo) _controlador.dispose();
    super.dispose();
  }

  Future<void> _alternarAcompanhamento(CashbackInter loja) async {
    if (!widget.administrador) return;
    final acompanhada = !_estaAcompanhada(loja);
    try {
      await widget.api.alterarFavoritaInter(id: loja.id, favorita: acompanhada);
      if (!mounted) return;
      setState(() {
        _acompanhamentoAlterado[loja.id] = acompanhada;
      });
      mostrarMensagemRadar(
        context,
        acompanhada
            ? 'Loja adicionada ao acompanhamento.'
            : 'Loja removida do acompanhamento.',
      );
    } catch (_) {
      if (mounted) {
        mostrarMensagemRadar(
          context,
          'Não foi possível salvar o acompanhamento.',
          sucesso: false,
        );
      }
    }
  }

  bool _estaAcompanhada(CashbackInter loja) =>
      _acompanhamentoAlterado[loja.id] ?? loja.favorita;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => _conteudo(context),
  );

  Widget _conteudo(BuildContext context) {
    final cores = CoresRadar.de(context);
    final margem = widget.incorporada ? 20.0 : 24.0;
    final atrasada = coletaInterAtrasada(
      _controlador.atualizadoEm,
      DateTime.now(),
    );

    if (widget.incorporada) {
      return _conteudoCompacto(context, margem);
    }

    final conteudo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            'Cashback — Sites parceiros',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (widget.mostrarAtualizacao)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margem),
            child: BotaoDisparo(
              api: widget.api,
              dominio: 'inter',
              administrador: widget.administrador,
              rotulo: 'Atualizar Cashback',
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: margem),
          child: TextField(
            controller: _campoBusca,
            key: const Key('busca-cashback-inter'),
            onChanged: _controlador.mudarBusca,
            decoration: const InputDecoration(
              hintText: 'Buscar por loja',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(margem, 12, margem, 8),
          child: Wrap(
            spacing: 8,
            children: [
              for (final ordenacao in OrdenacaoCashbackInter.values)
                ChoiceChip(
                  label: Text(ordenacao.rotulo),
                  selected: _controlador.ordenacao == ordenacao,
                  onSelected: (_) => _controlador.mudarOrdenacao(ordenacao),
                ),
            ],
          ),
        ),
        if (_controlador.atualizadoEm != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margem, vertical: 4),
            child: Text(
              'Última coleta: ${dataHoraInter(_controlador.atualizadoEm)}'
              '${atrasada ? ' · dados atrasados' : ''}',
              style: TextStyle(color: atrasada ? cores.atencao : null),
            ),
          ),
        if (_controlador.atualizadoEm != null && !_controlador.carregando)
          Padding(
            padding: EdgeInsets.fromLTRB(margem, 4, margem, 8),
            child: Text('${_controlador.totalItens} lojas encontradas'),
          ),
        if (_controlador.ultimaTentativaFalhou &&
            _controlador.atualizadoEm != null)
          Padding(
            padding: EdgeInsets.fromLTRB(margem, 4, margem, 8),
            child: Semantics(
              liveRegion: true,
              child: Text(
                'A última sincronização do Inter falhou. '
                'Exibindo a última coleta válida.',
                style: TextStyle(color: cores.perigo),
              ),
            ),
          ),
        Expanded(child: _corpo()),
      ],
    );
    return SafeArea(child: conteudo);
  }

  Widget _conteudoCompacto(
    BuildContext context,
    double margem,
  ) => CustomScrollView(
    key: widget.chaveRolagemCompacta ?? const Key('cashback-inter-compacto'),
    slivers: [
      ...widget.sliversAntesDoCashback,
      if (widget.mostrarAtualizacao)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(margem, 16, margem, 8),
          sliver: SliverToBoxAdapter(
            child: BotaoDisparo(
              api: widget.api,
              dominio: 'inter',
              administrador: widget.administrador,
              rotulo: 'Atualizar Cashback',
            ),
          ),
        ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(margem, 8, margem, 0),
        sliver: SliverToBoxAdapter(
          child: TextField(
            controller: _campoBusca,
            key: const Key('busca-cashback-inter'),
            onChanged: _controlador.mudarBusca,
            decoration: InputDecoration(
              hintText: 'Buscar entre as lojas do Inter',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: CoresRadar.de(context).borda),
              ),
            ),
          ),
        ),
      ),
      SliverPadding(
        padding: EdgeInsets.fromLTRB(margem, 12, margem, 8),
        sliver: SliverToBoxAdapter(
          child: _FiltrosCompactosInter(
            selecionado: _filtroCompacto,
            aoSelecionar: (indice) {
              setState(() => _filtroCompacto = indice);
              if (indice == 1) {
                _controlador.mudarOrdenacao(OrdenacaoCashbackInter.cashback);
              }
            },
          ),
        ),
      ),
      ..._corpoCompacto(),
    ],
  );

  List<Widget> _corpoCompacto() {
    if (_controlador.carregando) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Carregando(mensagem: 'Carregando cashback do Inter…'),
        ),
      ];
    }
    if (_controlador.erro != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoFalha(
            mensagem: 'Não foi possível carregar o cashback do Inter.',
            voltar: _controlador.tentarNovamente,
          ),
        ),
      ];
    }
    if (_controlador.atualizadoEm == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _controlador.ultimaTentativaFalhou
              ? EstadoFalha(
                  mensagem:
                      'A última sincronização do Inter falhou. '
                      'Ainda não há dados válidos para mostrar.',
                  voltar: _controlador.tentarNovamente,
                )
              : const EstadoVazio(
                  mensagem: 'O Inter ainda não foi sincronizado.',
                ),
        ),
      ];
    }
    final lojas = _lojasCompactas();
    if (lojas.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoVazio(
            mensagem: _filtroCompacto == 2
                ? 'Nenhuma loja está acompanhada ainda.'
                : _controlador.busca.trim().isEmpty
                ? 'Nenhuma loja do Inter foi encontrada.'
                : 'Nenhuma loja encontrada para “${_controlador.busca.trim()}”.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            for (final loja in lojas)
              CartaoCashbackInter(
                loja: loja,
                compacto: true,
                acompanhada: _estaAcompanhada(loja),
                podeAdministrar: widget.administrador,
                aoAcompanhar: () => _alternarAcompanhamento(loja),
              ),
            const SizedBox(height: 8),
            _paginacao(),
          ]),
        ),
      ),
    ];
  }

  List<CashbackInter> _lojasCompactas() => _filtroCompacto == 2
      ? _controlador.itens.where(_estaAcompanhada).toList(growable: false)
      : _controlador.itens;

  Widget _corpo() {
    if (_controlador.carregando) {
      return const Carregando(mensagem: 'Carregando cashback do Inter…');
    }
    if (_controlador.erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o cashback do Inter.',
        voltar: _controlador.tentarNovamente,
      );
    }
    if (_controlador.atualizadoEm == null) {
      if (_controlador.ultimaTentativaFalhou) {
        return EstadoFalha(
          mensagem:
              'A última sincronização do Inter falhou. '
              'Ainda não há dados válidos para mostrar.',
          voltar: _controlador.tentarNovamente,
        );
      }
      return const EstadoVazio(mensagem: 'O Inter ainda não foi sincronizado.');
    }
    if (_controlador.totalItens == 0) {
      return EstadoVazio(
        mensagem: _controlador.busca.trim().isEmpty
            ? 'Nenhuma loja do Inter foi encontrada.'
            : 'Nenhuma loja encontrada para “${_controlador.busca.trim()}”.',
      );
    }
    return LayoutBuilder(
      builder: (context, limites) {
        final colunas = limites.maxWidth >= 900 ? 2 : 1;
        final margem = widget.incorporada ? 20.0 : 24.0;
        return ListView(
          padding: EdgeInsets.fromLTRB(margem, 8, margem, 32),
          children: [
            if (colunas == 1)
              for (final loja in _controlador.itens)
                CartaoCashbackInter(
                  loja: loja,
                  compacto: widget.incorporada,
                  acompanhada: _estaAcompanhada(loja),
                  podeAdministrar: widget.administrador,
                  aoAcompanhar: () => _alternarAcompanhamento(loja),
                )
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final loja in _controlador.itens)
                    SizedBox(
                      width: (limites.maxWidth - 16) / 2,
                      child: CartaoCashbackInter(
                        loja: loja,
                        compacto: widget.incorporada,
                        acompanhada: _estaAcompanhada(loja),
                        podeAdministrar: widget.administrador,
                        aoAcompanhar: () => _alternarAcompanhamento(loja),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            _paginacao(),
          ],
        );
      },
    );
  }

  Widget _paginacao() {
    if (_controlador.carregandoMais) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_controlador.erroMais != null) {
      return Center(
        child: FilledButton.tonal(
          onPressed: _controlador.carregarMais,
          child: const Text('Tentar carregar mais'),
        ),
      );
    }
    if (_controlador.temProxima) {
      return Center(
        child: FilledButton(
          onPressed: _controlador.carregarMais,
          child: const Text('Carregar mais'),
        ),
      );
    }
    return const Center(child: Text('Todos os resultados foram carregados.'));
  }
}

class _FiltrosCompactosInter extends StatelessWidget {
  const _FiltrosCompactosInter({
    required this.selecionado,
    required this.aoSelecionar,
  });

  final int selecionado;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FiltroCompactoInter(
            rotulo: 'Todas as lojas',
            ativo: selecionado == 0,
            corAtiva: cores.acao,
            aoTocar: () => aoSelecionar(0),
          ),
          const SizedBox(width: 8),
          _FiltroCompactoInter(
            rotulo: 'Maior cashback',
            ativo: selecionado == 1,
            corAtiva: cores.acao,
            aoTocar: () => aoSelecionar(1),
          ),
          const SizedBox(width: 8),
          _FiltroCompactoInter(
            rotulo: 'Acompanhadas',
            ativo: selecionado == 2,
            corAtiva: cores.acao,
            aoTocar: () => aoSelecionar(2),
          ),
        ],
      ),
    );
  }
}

class _FiltroCompactoInter extends StatelessWidget {
  const _FiltroCompactoInter({
    required this.rotulo,
    required this.ativo,
    required this.corAtiva,
    required this.aoTocar,
  });

  final String rotulo;
  final bool ativo;
  final Color corAtiva;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: aoTocar,
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 38),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      backgroundColor: ativo ? const Color(0xFFE1F1FF) : Colors.white,
      foregroundColor: ativo ? corAtiva : CoresRadar.de(context).textoSuave,
      shape: StadiumBorder(
        side: BorderSide(
          color: ativo ? corAtiva : CoresRadar.de(context).borda,
        ),
      ),
    ),
    child: Text(
      rotulo,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}
