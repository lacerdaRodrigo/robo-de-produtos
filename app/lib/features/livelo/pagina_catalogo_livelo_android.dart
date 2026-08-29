import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import 'cartao_catalogo_livelo.dart';
import 'controlador_catalogo_livelo.dart';
import 'formato_livelo.dart';

class PaginaCatalogoLiveloAndroid extends StatefulWidget {
  const PaginaCatalogoLiveloAndroid({
    super.key,
    required this.api,
    required this.administrador,
    this.controlador,
    this.agora,
  });

  final Api api;
  final bool administrador;
  final ControladorCatalogoLivelo? controlador;
  final DateTime Function()? agora;

  @override
  State<PaginaCatalogoLiveloAndroid> createState() =>
      _EstadoPaginaCatalogoLiveloAndroid();
}

class _EstadoPaginaCatalogoLiveloAndroid
    extends State<PaginaCatalogoLiveloAndroid> {
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

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
  }

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
    if (!_controladorExterno) _controlador.dispose();
    super.dispose();
  }

  Future<void> _alternar(ParceiroCatalogoLivelo parceiro) async {
    final sucesso = await _controlador.alternarAcompanhamento(parceiro);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Acompanhamento salvo. A regra será aplicada na próxima coleta.'
              : 'Não foi possível salvar. O estado anterior foi restaurado.',
        ),
      ),
    );
  }

  Future<void> _alternarAlerta(ParceiroCatalogoLivelo parceiro) async {
    final sucesso = await _controlador.alternarAlerta(parceiro);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? (parceiro.alertaAtivo
                    ? 'Alerta desativado para esta loja.'
                    : 'Alerta ativado para esta loja.')
              : 'Não foi possível salvar o alerta.',
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            sliver: SliverToBoxAdapter(
              child: _HeroCatalogo(
                resumo: _controlador.resumo!,
                agora: (widget.agora ?? DateTime.now)(),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(
            child: AbasRadar(
              rotulos: AbaCatalogoLivelo.values
                  .map((aba) => aba.rotulo)
                  .toList(),
              selecionada: _controlador.aba.index,
              aoSelecionar: (indice) =>
                  _controlador.mudarAba(AbaCatalogoLivelo.values[indice]),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
    height: 42,
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              podeAdministrar: widget.administrador,
              aoAlternar: () => _alternar(parceiro),
              aoAlternarAlerta: () => _alternarAlerta(parceiro),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Tokens.marcaProfunda),
            ),
          ),
          Positioned(
            right: -52,
            bottom: -100,
            child: _ArcosDoHero(cor: Colors.white.withValues(alpha: 0.07)),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IndicadorEstadoRadar(
                  texto: atrasada
                      ? 'Dados atrasados'
                      : 'Última coleta concluída',
                  tom: atrasada ? TomRadar.atencao : TomRadar.ganho,
                ),
                const SizedBox(height: 12),
                Text(
                  melhor == null
                      ? 'Nenhuma oferta válida foi encontrada nesta coleta.'
                      : '${pontosLivelo(melhor.pontosAtuais, moeda: melhor.moeda)} é a melhor oferta agora.',
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
        _Metrica(valor: '${resumo.totalCatalogo}', rotulo: 'no catálogo'),
        _Metrica(valor: '${resumo.acompanhadas}', rotulo: 'acompanhadas'),
        _Metrica(valor: '${resumo.alertas}', rotulo: 'alertas'),
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
