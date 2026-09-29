import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
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
  int? _totalAcompanhamentos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void didUpdateWidget(covariant PaginaMeuRadar antigo) {
    super.didUpdateWidget(antigo);
    if (widget.ativa && !antigo.ativa) {
      _carregar(silencioso: true, atualizarContagem: true);
    }
  }

  @override
  void dispose() {
    _temporizadorBusca?.cancel();
    _busca.dispose();
    super.dispose();
  }

  Future<void> _carregar({
    bool silencioso = false,
    bool atualizarContagem = false,
  }) async {
    if (!silencioso && mounted) setState(() => _carregando = true);
    final consulta = _busca.text.trim();
    final origem = _origem;
    try {
      final pagina = await widget.api.acompanhamentosPessoais(
        q: consulta,
        origem: origem,
        ordenar: 'recentes',
        pagina: _paginaAtual,
      );
      int? totalAtualizado;
      if (consulta.isEmpty && origem == 'todas') {
        totalAtualizado = pagina.totalItens;
      } else if (atualizarContagem || _totalAcompanhamentos == null) {
        try {
          final total = await widget.api.acompanhamentosPessoais(
            origem: 'todas',
            ordenar: 'recentes',
            pagina: 1,
            porPagina: 1,
          );
          totalAtualizado = total.totalItens;
        } catch (_) {
          // Uma falha na contagem não apaga a lista filtrada que carregou.
        }
      }
      if (!mounted) return;
      setState(() {
        _pagina = pagina;
        if (totalAtualizado != null) {
          _totalAcompanhamentos = totalAtualizado;
        }
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

  void _acionarBusca() {
    _temporizadorBusca?.cancel();
    setState(() => _paginaAtual = 1);
    _carregar();
  }

  void _selecionarOrigem(String origem) {
    if (_origem == origem) return;
    setState(() {
      _origem = origem;
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
      if (_totalAcompanhamentos != null && _totalAcompanhamentos! > 0) {
        _totalAcompanhamentos = _totalAcompanhamentos! - 1;
      }
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
        _totalAcompanhamentos = null;
      });
      await _carregar(atualizarContagem: true);
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
      if (_totalAcompanhamentos != null) {
        setState(() => _totalAcompanhamentos = _totalAcompanhamentos! + 1);
      }
      await _carregar(silencioso: true, atualizarContagem: true);
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
    final total = _totalAcompanhamentos ?? pagina.totalItens;
    final cores = CoresRadar.de(context);
    return SafeArea(
      top: true,
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () => _carregar(atualizarContagem: true),
        child: ListView(
          key: const Key('pagina-meu-radar'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.only(
            start: context.tokens.spacing.four,
            end: context.tokens.spacing.four,
            top: context.tokens.spacing.seven,
            bottom: context.tokens.spacing.eight,
          ),
          children: [
            CabecalhoSecaoRadar(
              titulo: 'No seu radar',
              descricao:
                  '$total ${total == 1 ? 'item acompanhado' : 'itens acompanhados'} por você.',
              acao: IconButton(
                tooltip: 'Abrir alertas',
                onPressed: widget.aoAbrirAlertas,
                icon: const Icon(Icons.notifications_none_rounded),
                constraints: BoxConstraints.tightFor(
                  width: context.tokens.sizes.touchTarget,
                  height: context.tokens.sizes.touchTarget,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: cores.superficieAlternativa,
                  foregroundColor: cores.texto,
                ),
              ),
            ),
            SizedBox(height: context.tokens.spacing.five),
            CampoBuscaRadar(
              chaveCampo: const Key('busca-meu-radar'),
              controlador: _busca,
              dica: 'Encontre na sua lista',
              aoMudar: _buscar,
              aoAcionar: _acionarBusca,
              acao: IconButton(
                tooltip: 'Pesquisar',
                onPressed: _acionarBusca,
                icon: const Icon(Icons.arrow_forward_rounded),
                constraints: BoxConstraints.tightFor(
                  width: context.tokens.sizes.touchTarget,
                  height: context.tokens.sizes.touchTarget,
                ),
                style: IconButton.styleFrom(foregroundColor: cores.acao),
              ),
              raioBorda: context.tokens.radii.md,
              comSombra: false,
              acaoSemFundo: true,
            ),
            SizedBox(height: context.tokens.spacing.four),
            _FiltrosRadar(
              origem: _origem,
              aoSelecionarOrigem: _selecionarOrigem,
            ),
            SizedBox(height: context.tokens.spacing.three),
            if (_carregando && pagina.itens.isNotEmpty)
              const LinearProgressIndicator(minHeight: 2),
            if (pagina.itens.isEmpty)
              _EstadoSemAcompanhamentos(
                filtrado: _busca.text.trim().isNotEmpty || _origem != 'todas',
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
          ],
        ),
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

class _FiltrosRadar extends StatelessWidget {
  const _FiltrosRadar({required this.origem, required this.aoSelecionarOrigem});

  final String origem;
  final ValueChanged<String> aoSelecionarOrigem;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final opcoes = <String, String>{
      'todas': 'Todos',
      'inter_cashback': 'Sites parceiros',
      'inter_produto': 'Compre direto',
      'livelo': 'Livelo',
      'pichau': 'Pichau',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final entrada in opcoes.entries) ...[
            Semantics(
              button: true,
              selected: origem == entrada.key,
              label: 'Filtrar por ${entrada.value}',
              child: ChoiceChip(
                showCheckmark: false,
                label: Text(entrada.value),
                selected: origem == entrada.key,
                onSelected: (_) => aoSelecionarOrigem(entrada.key),
                backgroundColor: cores.superficie,
                selectedColor: cores.acao.withValues(alpha: 0.14),
                side: BorderSide(
                  color: origem == entrada.key ? cores.acao : cores.borda,
                ),
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: origem == entrada.key ? cores.acao : cores.textoSuave,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.radii.pill),
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: tokens.spacing.three,
                  vertical: tokens.spacing.two,
                ),
                materialTapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
            SizedBox(width: tokens.spacing.two),
          ],
        ],
      ),
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
    final estado = _rotuloEstado(item.estado);
    final valor = item.valorTexto?.trim();
    final mostrarValor =
        valor != null &&
        valor.isNotEmpty &&
        valor.toLowerCase() != estado.toLowerCase();
    return CartaoRadar(
      aoTocar: aoAbrir,
      padding: EdgeInsets.all(context.tokens.spacing.five),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: context.tokens.spacing.two,
              runSpacing: context.tokens.spacing.one,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: Text(
                    _rotuloOrigem(item.origem),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cores.textoSuave,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                  child: IndicadorEstadoRadar(texto: estado),
                ),
              ],
            ),
          ),
          SizedBox(height: context.tokens.spacing.three),
          Text(
            item.nome,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (mostrarValor) ...[
            SizedBox(height: context.tokens.spacing.two),
            Text(valor, style: Theme.of(context).textTheme.bodyMedium),
          ],
          SizedBox(height: context.tokens.spacing.three),
          Divider(height: context.tokens.spacing.five, color: cores.borda),
          Wrap(
            spacing: context.tokens.spacing.two,
            runSpacing: context.tokens.spacing.one,
            children: [
              TextButton.icon(
                onPressed: aoRemover,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Acompanhando'),
                style: TextButton.styleFrom(
                  backgroundColor: cores.acao.withValues(alpha: 0.14),
                  foregroundColor: cores.acao,
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: context.tokens.spacing.three,
                  ),
                ),
              ),
              if (item.urlExterna != null && item.urlExterna!.isNotEmpty)
                TextButton.icon(
                  onPressed: aoAbrir,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text('Ir para ${_rotuloDestino(item.origem)}'),
                ),
            ],
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

String _rotuloDestino(String origem) => switch (origem) {
  'livelo' => 'a Livelo',
  'inter_cashback' || 'inter_produto' => 'o Inter',
  'pichau' => 'a Pichau',
  _ => 'a origem',
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
