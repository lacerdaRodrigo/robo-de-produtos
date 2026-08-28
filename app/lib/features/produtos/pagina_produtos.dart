import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/componentes/estados.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../administracao/botao_disparo.dart';
import 'cartao_produto.dart';
import 'controlador_busca_produtos.dart';
import 'formato_produtos.dart';
import 'link_shopping_inter.dart';
import 'pagina_historico_produto.dart';

/// Busca local de produtos diretos. Nunca consulta o Inter durante a digitação.
class PaginaProdutos extends StatefulWidget {
  const PaginaProdutos({
    super.key,
    required this.api,
    this.controlador,
    this.administrador = false,
    this.incorporada = false,
    this.mostrarTituloInterno = true,
  });

  final Api api;
  final ControladorBuscaProdutos? controlador;
  final bool administrador;
  final bool incorporada;
  final bool mostrarTituloInterno;

  @override
  State<PaginaProdutos> createState() => _EstadoPaginaProdutos();
}

class _EstadoPaginaProdutos extends State<PaginaProdutos> {
  late final ControladorBuscaProdutos _controlador =
      widget.controlador ??
      ControladorBuscaProdutos(
        buscar:
            ({
              required termo,
              required pagina,
              marca,
              categoria,
              loja,
              precoMin,
              precoMax,
            }) => widget.api.buscarProdutos(
              termo,
              pagina: pagina,
              marca: marca,
              categoria: categoria,
              loja: loja,
              precoMin: precoMin,
              precoMax: precoMax,
            ),
      );
  late final bool _controladorExterno = widget.controlador != null;
  final _campoBusca = TextEditingController();

  @override
  void dispose() {
    _campoBusca.dispose();
    if (!_controladorExterno) _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corpo = AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) => _conteudo(context),
    );
    if (widget.incorporada) return corpo;
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos no Inter')),
      body: corpo,
    );
  }

  Widget _conteudo(BuildContext context) {
    final cores = CoresRadar.de(context);
    final atrasado = coletaProdutosAtrasada(
      _controlador.atualizadoEm,
      DateTime.now(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.incorporada && widget.mostrarTituloInterno)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text(
              'Produtos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            widget.incorporada && widget.mostrarTituloInterno ? 12 : 16,
            24,
            0,
          ),
          child: BotaoDisparo(
            api: widget.api,
            dominio: 'produtos_inter',
            administrador: widget.administrador,
            rotulo: 'Atualizar Produtos',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: TextField(
            controller: _campoBusca,
            onChanged: _controlador.mudarTermo,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              labelText: 'Buscar produtos',
              hintText: 'Ex.: celular Motorola Edge 60 Pro',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _abrirFiltros,
                icon: const Icon(Icons.tune),
                label: Text(
                  _controlador.filtros.estaVazio ? 'Filtros' : 'Filtros ativos',
                ),
              ),
              if (!_controlador.filtros.estaVazio)
                TextButton(
                  onPressed: () {
                    _controlador.mudarFiltros(const FiltrosProdutos());
                  },
                  child: const Text('Limpar filtros'),
                ),
            ],
          ),
        ),
        if (_controlador.atualizadoEm != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Text(
              'Catálogo mais recente: ${dataHoraProduto(_controlador.atualizadoEm)}'
              '${atrasado ? ' · dados atrasados' : ''}',
              style: TextStyle(color: atrasado ? cores.atencao : null),
            ),
          ),
        if (_controlador.qualidade == 'degradada')
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              'A última coleta foi degradada; produtos ausentes não foram removidos.',
            ),
          ),
        if (_controlador.termoValido &&
            !_controlador.carregando &&
            _controlador.erro == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    '${_controlador.totalItens} produtos · página '
                    '${_controlador.pagina} · ${_controlador.porPagina} por página',
                  ),
                ),
                Chip(
                  label: Text(
                    _controlador.qualidade == 'degradada'
                        ? 'Catálogo degradado'
                        : 'Catálogo completo',
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _corpo()),
      ],
    );
  }

  Widget _corpo() {
    final cores = CoresRadar.de(context);
    if (!_controlador.termoValido) {
      return const EstadoVazio(
        mensagem: 'Digite pelo menos 2 caracteres para pesquisar no catálogo.',
      );
    }
    if (_controlador.carregando) {
      return const Carregando(mensagem: 'Buscando produtos no catálogo…');
    }
    if (_controlador.erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível buscar produtos agora.',
        voltar: _controlador.tentarNovamente,
      );
    }
    if (_controlador.totalItens == 0) {
      return const EstadoVazio(
        mensagem: 'Nenhum produto encontrado com esses filtros.',
      );
    }
    final grupos = <String, List<ProdutoDireto>>{};
    for (final produto in _controlador.itens) {
      grupos.putIfAbsent(produto.lojaNome, () => []).add(produto);
    }
    return LayoutBuilder(
      builder: (context, limites) {
        final duasColunas = limites.maxWidth >= 900;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            for (final entrada in grupos.entries) ...[
              Text(entrada.key, style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Atualizado: ${dataHoraProduto(entrada.value.first.atualizadaEm)}',
                style: TextStyle(
                  color:
                      coletaProdutosAtrasada(
                        entrada.value.first.atualizadaEm,
                        DateTime.now(),
                      )
                      ? cores.atencao
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              if (duasColunas)
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final produto in entrada.value)
                      SizedBox(
                        width: (limites.maxWidth - 16) / 2,
                        child: _cartao(produto),
                      ),
                  ],
                )
              else
                for (final produto in entrada.value) _cartao(produto),
              const SizedBox(height: 16),
            ],
            _paginacao(),
          ],
        );
      },
    );
  }

  Widget _cartao(ProdutoDireto produto) {
    final link = linkSeguroShoppingInter(produto.caminho);
    return CartaoProduto(
      produto: produto,
      aoAbrirHistorico: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                PaginaHistoricoProduto(api: widget.api, produto: produto),
          ),
        );
      },
      aoAbrirNoShopping: link == null ? null : () => _abrirNoShopping(link),
    );
  }

  Future<void> _abrirNoShopping(Uri link) async {
    final abriu = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o Shopping Inter.'),
        ),
      );
    }
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

  Future<void> _abrirFiltros() async {
    final filtros = _controlador.filtros;
    final marca = TextEditingController(text: filtros.marca);
    final categoria = TextEditingController(text: filtros.categoria);
    final loja = TextEditingController(text: filtros.loja);
    final precoMin = TextEditingController(text: filtros.precoMin);
    final precoMax = TextEditingController(text: filtros.precoMax);
    final novos = await showModalBottomSheet<FiltrosProdutos>(
      context: context,
      isScrollControlled: true,
      builder: (contexto) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewInsetsOf(contexto).bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filtros', style: Theme.of(contexto).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(
                  controller: marca,
                  decoration: const InputDecoration(labelText: 'Marca'),
                ),
                TextField(
                  controller: categoria,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
                TextField(
                  controller: loja,
                  decoration: const InputDecoration(labelText: 'Loja (slug)'),
                ),
                TextField(
                  controller: precoMin,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Preço mínimo'),
                ),
                TextField(
                  controller: precoMax,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Preço máximo'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(contexto).pop(
                    FiltrosProdutos(
                      marca: marca.text,
                      categoria: categoria.text,
                      loja: loja.text,
                      precoMin: precoMin.text,
                      precoMax: precoMax.text,
                    ),
                  ),
                  child: const Text('Aplicar filtros'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Os campos ainda pertencem à animação de saída do bottom sheet depois
    // que o Future retorna. Eles são descartados junto do modal; destruí-los
    // aqui faria o Flutter tentar reconstruir um TextField já sem controller.
    if (mounted && novos != null) _controlador.mudarFiltros(novos);
  }
}
