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
import '../produtos/formato_produtos.dart';

/// Catálogo mobile do Compre direto com busca e paginação fornecidas pela API.
class PaginaCompreDiretoInter extends StatefulWidget {
  const PaginaCompreDiretoInter({
    super.key,
    required this.api,
    required this.administrador,
    required this.sliversAntes,
    this.controlador,
    this.aoAtualizar,
    this.ordenacaoInicial = 'nome',
    this.filtroInicial = 'todas',
    this.aoMudarConsulta,
  });

  final Api api;
  final bool administrador;
  final List<Widget> sliversAntes;
  final ControladorCatalogoAdministracao<LojaDireto>? controlador;
  final Future<void> Function()? aoAtualizar;
  final String ordenacaoInicial;
  final String filtroInicial;
  final void Function({required String ordenar, required String filtro})?
  aoMudarConsulta;

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
          ordenar: _filtro == _FiltroCompreDireto.maiorCashback
              ? 'cashback'
              : 'nome',
          filtro: _filtro == _FiltroCompreDireto.acompanhadas
              ? 'acompanhadas'
              : 'todas',
        ),
        identificar: (loja) => loja.id,
      );
  late final bool _controladorExterno = widget.controlador != null;
  late final _busca = TextEditingController(text: _controlador.busca);
  final _alterando = <String>{};
  late var _filtro = widget.filtroInicial == 'acompanhadas'
      ? _FiltroCompreDireto.acompanhadas
      : widget.ordenacaoInicial == 'cashback'
      ? _FiltroCompreDireto.maiorCashback
      : _FiltroCompreDireto.todas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.administrador && _controlador.itens.isEmpty) {
      _controlador.carregarPrimeira();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _busca.dispose();
    if (!_controladorExterno) _controlador.dispose();
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
    }
    final atualizarResumo = widget.aoAtualizar;
    if (atualizarResumo != null) tarefas.add(atualizarResumo());
    await Future.wait(tarefas);
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
    setState(() => _filtro = filtro);
    widget.aoMudarConsulta?.call(
      ordenar: filtro == _FiltroCompreDireto.maiorCashback
          ? 'cashback'
          : 'nome',
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
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: CampoBuscaRadar(
                        chaveCampo: const Key('busca-compre-direto'),
                        controlador: _busca,
                        dica: 'Buscar loja no Compre direto',
                        aoMudar: _controlador.mudarBusca,
                      ),
                    ),
                    const SizedBox(width: 8),
                    BotaoDisparo(
                      api: widget.api,
                      dominio: 'produtos_inter',
                      administrador: widget.administrador,
                      rotulo: 'Coletar',
                      compacto: true,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${_controlador.total} ${_filtro == _FiltroCompreDireto.acompanhadas ? 'lojas acompanhadas' : 'lojas disponíveis'}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: CoresRadar.de(context).textoSuave,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _FiltrosCompreDireto(
                selecionado: _filtro,
                aoSelecionar: _selecionarFiltro,
              ),
            ),
            if (_filtro == _FiltroCompreDireto.acompanhadas)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: _AvisoFiltroCompreDireto(
                    mensagem:
                        'No Compre direto, esta aba mostra as lojas selecionadas para a coleta.',
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
              detalhado: _filtro == _FiltroCompreDireto.acompanhadas,
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

enum _FiltroCompreDireto { todas, maiorCashback, acompanhadas }

class _FiltrosCompreDireto extends StatelessWidget {
  const _FiltrosCompreDireto({
    required this.selecionado,
    required this.aoSelecionar,
  });

  final _FiltroCompreDireto selecionado;
  final ValueChanged<_FiltroCompreDireto> aoSelecionar;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _FiltroCompreDiretoBotao(
          rotulo: 'Todas',
          ativo: selecionado == _FiltroCompreDireto.todas,
          aoTocar: () => aoSelecionar(_FiltroCompreDireto.todas),
        ),
        const SizedBox(width: 7),
        _FiltroCompreDiretoBotao(
          rotulo: 'Maior cashback',
          ativo: selecionado == _FiltroCompreDireto.maiorCashback,
          aoTocar: () => aoSelecionar(_FiltroCompreDireto.maiorCashback),
        ),
        const SizedBox(width: 7),
        _FiltroCompreDiretoBotao(
          rotulo: 'Selecionadas',
          ativo: selecionado == _FiltroCompreDireto.acompanhadas,
          aoTocar: () => aoSelecionar(_FiltroCompreDireto.acompanhadas),
        ),
      ],
    ),
  );
}

class _FiltroCompreDiretoBotao extends StatelessWidget {
  const _FiltroCompreDiretoBotao({
    required this.rotulo,
    required this.ativo,
    required this.aoTocar,
  });

  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return TextButton(
      onPressed: aoTocar,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 37),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        backgroundColor: ativo ? cores.marca : Theme.of(context).cardColor,
        foregroundColor: ativo
            ? Theme.of(context).colorScheme.onSecondary
            : cores.textoSuave,
        shape: StadiumBorder(
          side: BorderSide(color: ativo ? cores.marca : cores.borda),
        ),
      ),
      child: Text(
        rotulo,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _AvisoFiltroCompreDireto extends StatelessWidget {
  const _AvisoFiltroCompreDireto({required this.mensagem});

  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cores.borda),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 17, color: cores.textoSuave),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
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

class _CartaoLojaDireta extends StatelessWidget {
  const _CartaoLojaDireta({
    required this.loja,
    required this.detalhado,
    required this.alterando,
    required this.aoAlternar,
  });

  final LojaDireto loja;
  final bool detalhado;
  final bool alterando;
  final VoidCallback aoAlternar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final estado = _descricao(loja);
    return Opacity(
      opacity: loja.ativa ? 1 : 0.7,
      child: CartaoRadar(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cores.superficieAlternativa,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _iniciais(loja.nome),
                    style: TextStyle(
                      color: cores.acao,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loja.nome,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Compre direto',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cores.textoSuave,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                if (loja.cashbackResumoTexto != null && !detalhado) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _cashbackComPrefixo(loja.cashbackResumoTexto!),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cores.ganho,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 8),
                  IndicadorEstadoRadar(
                    texto: loja.ativa ? 'Ativa' : 'Inativa',
                    tom: loja.ativa ? TomRadar.ganho : TomRadar.neutro,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 7),
            Text(
              estado,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
            ),
            if (detalhado) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 11),
              _ResumoDadosDireto(loja: loja),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: loja.ativa && !alterando ? aoAlternar : null,
                icon: alterando
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        loja.selecionada ? Icons.check : Icons.add,
                        size: 16,
                      ),
                label: Text(
                  loja.ativa
                      ? loja.selecionada
                            ? 'Selecionada'
                            : 'Selecionar'
                      : 'Indisponível',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumoDadosDireto extends StatelessWidget {
  const _ResumoDadosDireto({required this.loja});

  final LojaDireto loja;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Último snapshot válido',
          style: tema.textTheme.labelSmall?.copyWith(
            color: cores.textoSuave,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        _LinhaDadoDireto(
          rotulo: 'Produtos encontrados',
          valor: _quantidadeProdutos(loja.produtosEncontrados),
        ),
        const SizedBox(height: 6),
        _LinhaDadoDireto(
          rotulo: 'Última coleta concluída',
          valor: loja.ultimaColetaSucessoEm == null
              ? 'Indisponível'
              : dataHoraProduto(loja.ultimaColetaSucessoEm),
        ),
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cores.superficieAlternativa,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            loja.cashbackResumoTexto == null
                ? 'Cashback indisponível'
                : _cashbackComPrefixo(loja.cashbackResumoTexto!),
            style: tema.textTheme.labelMedium?.copyWith(
              color: loja.cashbackResumoTexto == null
                  ? cores.textoSuave
                  : cores.ganho,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LinhaDadoDireto extends StatelessWidget {
  const _LinhaDadoDireto({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            rotulo,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cores.textoSuave,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

String _descricao(LojaDireto loja) {
  if (!loja.ativa) return 'Loja inativa · sem seleção disponível';
  return switch (loja.ultimaTentativaEstado) {
    'iniciada' => 'Coleta em andamento',
    'falha' => 'Última tentativa falhou',
    'sucesso' => 'Última tentativa concluída',
    _ => 'Sem tentativa recente',
  };
}

String _quantidadeProdutos(int? quantidade) {
  if (quantidade == null) return 'Indisponível';
  return '$quantidade produto${quantidade == 1 ? '' : 's'}';
}

String _cashbackComPrefixo(String resumo) {
  var valor = resumo.trim();
  if (valor.isEmpty) return 'Cashback indisponível';
  const sufixo = ' de cashback';
  if (valor.toLowerCase().endsWith(sufixo)) {
    valor = valor.substring(0, valor.length - sufixo.length);
  }
  return 'Cashback: ${valor[0].toLowerCase()}${valor.substring(1)}';
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
