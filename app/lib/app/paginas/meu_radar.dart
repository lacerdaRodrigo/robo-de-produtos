import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
import '../componentes/menu_conta.dart';
import '../tema/tokens.dart';

class PaginaMeuRadar extends StatefulWidget {
  const PaginaMeuRadar({
    super.key,
    required this.api,
    required this.aoExplorar,
    required this.aoAbrirAlertas,
    this.ativa = true,
  });

  final Api api;
  final VoidCallback aoExplorar;
  final VoidCallback aoAbrirAlertas;
  final bool ativa;

  @override
  State<PaginaMeuRadar> createState() => _PaginaMeuRadarState();
}

class _PaginaMeuRadarState extends State<PaginaMeuRadar> {
  final _busca = TextEditingController();
  Timer? _temporizadorBusca;
  PaginaAcompanhamentosPessoais? _pagina;
  Object? _erro;
  var _carregando = true;
  var _paginaAtual = 1;
  var _origem = 'todas';
  var _ordenar = 'recentes';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(covariant PaginaMeuRadar antigo) {
    super.didUpdateWidget(antigo);
    if (widget.ativa && !antigo.ativa) _carregar(silencioso: true);
  }

  @override
  void dispose() {
    _temporizadorBusca?.cancel();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    if (!silencioso && mounted) setState(() => _carregando = true);
    try {
      final pagina = await widget.api.acompanhamentosPessoais(
        q: _busca.text.trim(),
        origem: _origem,
        ordenar: _ordenar,
        pagina: _paginaAtual,
      );
      if (!mounted) return;
      setState(() {
        _pagina = pagina;
        _erro = null;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro;
        _carregando = false;
      });
    }
  }

  void _buscar(String valor) {
    _temporizadorBusca?.cancel();
    _temporizadorBusca = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _paginaAtual = 1);
      _carregar();
    });
  }

  void _selecionarOrigem(String origem) {
    if (_origem == origem) return;
    setState(() {
      _origem = origem;
      _paginaAtual = 1;
    });
    _carregar();
  }

  void _selecionarOrdenacao(String ordenar) {
    if (_ordenar == ordenar) return;
    setState(() {
      _ordenar = ordenar;
      _paginaAtual = 1;
    });
    _carregar();
  }

  Future<void> _remover(AcompanhamentoPessoal item) async {
    final pagina = _pagina;
    final indice = pagina?.itens.indexOf(item) ?? -1;
    if (pagina == null || indice < 0) return;
    setState(() {
      _pagina = PaginaAcompanhamentosPessoais(
        itens: List<AcompanhamentoPessoal>.of(pagina.itens)..removeAt(indice),
        pagina: pagina.pagina,
        porPagina: pagina.porPagina,
        totalItens: pagina.totalItens - 1,
        totalPaginas: pagina.totalPaginas,
        temProxima: pagina.temProxima,
        totaisPorOrigem: _totaisComAjuste(
          pagina.totaisPorOrigem,
          item.origem,
          -1,
        ),
      );
    });
    try {
      await widget.api.alterarAcompanhamentoPessoal(
        origem: item.origem,
        entidadeId: item.entidadeId,
        ativo: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.nome} removido do radar.'),
          action: SnackBarAction(
            label: 'Desfazer',
            onPressed: () => _desfazer(item),
          ),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro;
        _pagina = null;
      });
      await _carregar();
    }
  }

  Future<void> _desfazer(AcompanhamentoPessoal item) async {
    try {
      await widget.api.alterarAcompanhamentoPessoal(
        origem: item.origem,
        entidadeId: item.entidadeId,
        ativo: true,
      );
      if (!mounted) return;
      await _carregar(silencioso: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acompanhamento restaurado.')),
      );
    } catch (erro) {
      if (!mounted) return;
      setState(() => _erro = erro);
      await _carregar(silencioso: true);
    }
  }

  Map<String, int> _totaisComAjuste(
    Map<String, int> atuais,
    String origem,
    int ajuste,
  ) => <String, int>{
    for (final entrada in atuais.entries)
      entrada.key: entrada.key == origem
          ? (entrada.value + ajuste).clamp(0, 1 << 30)
          : entrada.value,
  };

  @override
  Widget build(BuildContext context) {
    if (_pagina == null && _carregando) {
      return const Carregando(mensagem: 'Carregando seu radar…');
    }
    if (_pagina == null) {
      return EstadoFalha(mensagem: _mensagemErro(_erro), voltar: _carregar);
    }

    final pagina = _pagina!;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        key: const Key('pagina-meu-radar'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.only(
          start: context.tokens.spacing.four,
          end: context.tokens.spacing.four,
          top: context.tokens.spacing.five,
          bottom: context.tokens.spacing.eight,
        ),
        children: [
          const CabecalhoSecaoRadar(
            sobrelinha: 'Seu radar',
            titulo: 'O que merece sua atenção.',
            descricao:
                'Acompanhe mudanças de lojas, cashback e produtos a partir dos catálogos.',
          ),
          SizedBox(height: context.tokens.spacing.five),
          _ResumoAcompanhamentos(
            total: pagina.totalItens,
            aoAbrirAlertas: widget.aoAbrirAlertas,
          ),
          SizedBox(height: context.tokens.spacing.four),
          CampoBuscaRadar(
            chaveCampo: const Key('busca-meu-radar'),
            controlador: _busca,
            dica: 'Buscar no seu radar',
            aoMudar: _buscar,
            somenteBusca: true,
          ),
          SizedBox(height: context.tokens.spacing.three),
          _FiltrosRadar(
            origem: _origem,
            ordenar: _ordenar,
            aoSelecionarOrigem: _selecionarOrigem,
            aoSelecionarOrdenacao: _selecionarOrdenacao,
          ),
          SizedBox(height: context.tokens.spacing.four),
          if (_carregando && pagina.itens.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          if (pagina.itens.isEmpty)
            _EstadoSemAcompanhamentos(
              filtrado: _busca.text.isNotEmpty || _origem != 'todas',
              aoExplorar: widget.aoExplorar,
            )
          else
            for (final item in pagina.itens) ...[
              _CartaoAcompanhamento(
                item: item,
                aoRemover: () => _remover(item),
                aoAbrir: () => _abrirItem(item),
              ),
              SizedBox(height: context.tokens.spacing.three),
            ],
          if (_erro != null && pagina.itens.isNotEmpty)
            TextButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
              label: Text(_mensagemErro(_erro)),
            ),
          SizedBox(height: context.tokens.spacing.three),
          PaginacaoRadar(
            pagina: pagina.pagina,
            totalItens: pagina.totalItens,
            porPagina: pagina.porPagina,
            carregando: _carregando,
            erro: _erro,
            aoIrParaPagina: (numero) async {
              setState(() => _paginaAtual = numero);
              await _carregar();
            },
          ),
          CartaoRadar(
            aoTocar: widget.aoAbrirAlertas,
            padding: EdgeInsets.all(context.tokens.spacing.four),
            child: LinhaContaRadar(
              icone: Icons.notifications_none_outlined,
              titulo: 'Central de alertas',
              descricao: 'Veja as mudanças registradas nos itens acompanhados.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirItem(AcompanhamentoPessoal item) async {
    final url = item.urlExterna;
    if (url == null) {
      widget.aoExplorar();
      return;
    }
    final abriu = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o link da fonte.'),
        ),
      );
    }
  }
}

class _ResumoAcompanhamentos extends StatelessWidget {
  const _ResumoAcompanhamentos({
    required this.total,
    required this.aoAbrirAlertas,
  });

  final int total;
  final VoidCallback aoAbrirAlertas;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(context.tokens.radii.xl),
        border: Border.all(color: cores.borda),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.tokens.spacing.five),
        child: Row(
          children: [
            Icon(
              Icons.bookmark_added_outlined,
              color: cores.acao,
              size: context.tokens.sizes.icon,
            ),
            SizedBox(width: context.tokens.spacing.three),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$total',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    total == 1
                        ? 'acompanhamento ativo'
                        : 'acompanhamentos ativos',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Abrir alertas',
              onPressed: aoAbrirAlertas,
              icon: const Icon(Icons.notifications_none_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltrosRadar extends StatelessWidget {
  const _FiltrosRadar({
    required this.origem,
    required this.ordenar,
    required this.aoSelecionarOrigem,
    required this.aoSelecionarOrdenacao,
  });

  final String origem;
  final String ordenar;
  final ValueChanged<String> aoSelecionarOrigem;
  final ValueChanged<String> aoSelecionarOrdenacao;

  @override
  Widget build(BuildContext context) {
    final opcoes = <String, String>{
      'todas': 'Todas',
      'livelo': 'Livelo',
      'inter_cashback': 'Inter parceiros',
      'inter_produto': 'Inter produtos',
      'pichau': 'Pichau',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entrada in opcoes.entries) ...[
                Semantics(
                  button: true,
                  selected: origem == entrada.key,
                  label: 'Filtrar por ${entrada.value}',
                  child: ChoiceChip(
                    label: Text(entrada.value),
                    selected: origem == entrada.key,
                    onSelected: (_) => aoSelecionarOrigem(entrada.key),
                  ),
                ),
                SizedBox(width: context.tokens.spacing.two),
              ],
            ],
          ),
        ),
        SizedBox(height: context.tokens.spacing.two),
        DropdownButtonFormField<String>(
          initialValue: ordenar,
          decoration: const InputDecoration(labelText: 'Ordenar'),
          items: const [
            DropdownMenuItem(value: 'recentes', child: Text('Mais recentes')),
            DropdownMenuItem(value: 'nome', child: Text('Nome')),
          ],
          onChanged: (valor) {
            if (valor != null) aoSelecionarOrdenacao(valor);
          },
        ),
      ],
    );
  }
}

class _CartaoAcompanhamento extends StatelessWidget {
  const _CartaoAcompanhamento({
    required this.item,
    required this.aoRemover,
    required this.aoAbrir,
  });

  final AcompanhamentoPessoal item;
  final VoidCallback aoRemover;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return CartaoRadar(
      aoTocar: aoAbrir,
      padding: EdgeInsetsDirectional.fromSTEB(
        context.tokens.spacing.four,
        context.tokens.spacing.four,
        context.tokens.spacing.two,
        context.tokens.spacing.four,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rotuloOrigem(item.origem),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cores.acao,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: context.tokens.spacing.one),
                Text(
                  item.nome,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.valorTexto != null) ...[
                  SizedBox(height: context.tokens.spacing.one),
                  Text(
                    item.valorTexto!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                SizedBox(height: context.tokens.spacing.one),
                IndicadorEstadoRadar(texto: _rotuloEstado(item.estado)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover acompanhamento',
            onPressed: aoRemover,
            icon: const Icon(Icons.bookmark_remove_outlined),
          ),
        ],
      ),
    );
  }
}

class _EstadoSemAcompanhamentos extends StatelessWidget {
  const _EstadoSemAcompanhamentos({
    required this.filtrado,
    required this.aoExplorar,
  });

  final bool filtrado;
  final VoidCallback aoExplorar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return CartaoRadar(
      padding: EdgeInsets.all(context.tokens.spacing.five),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.bookmark_border,
            color: cores.acao,
            size: context.tokens.sizes.icon,
          ),
          SizedBox(height: context.tokens.spacing.three),
          Text(
            filtrado
                ? 'Nenhum item encontrado.'
                : 'Seu radar ainda está vazio.',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: context.tokens.spacing.one),
          Text(
            filtrado
                ? 'Tente outra busca ou fonte.'
                : 'Explore uma fonte e acompanhe o que você quer revisar depois.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cores.textoSuave),
          ),
          if (!filtrado) ...[
            SizedBox(height: context.tokens.spacing.four),
            FilledButton.icon(
              onPressed: aoExplorar,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explorar fontes'),
            ),
          ],
        ],
      ),
    );
  }
}

String _rotuloOrigem(String origem) => switch (origem) {
  'livelo' => 'LIVELO',
  'inter_cashback' => 'INTER · SITES PARCEIROS',
  'inter_produto' => 'INTER · COMPRE DIRETO',
  'pichau' => 'PICHAU',
  _ => 'RADAR',
};

String _rotuloEstado(EstadoResumo estado) => switch (estado) {
  EstadoResumo.atualizado => 'Atualizado',
  EstadoResumo.parcial => 'Parcial',
  EstadoResumo.atrasado => 'Atrasado',
  EstadoResumo.semDados => 'Sem dados',
  EstadoResumo.indisponivel => 'Indisponível',
  _ => 'Atenção',
};

String _mensagemErro(Object? erro) =>
    erro is ErroDeApi ? erro.mensagem : 'Não foi possível carregar seu radar.';
