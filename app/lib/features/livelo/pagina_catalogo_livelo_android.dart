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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 15),
          sliver: SliverToBoxAdapter(
            child: AbasRadar(
              rotulos: _abasVisiveis.map((aba) => aba.rotulo).toList(),
              selecionada: _abasVisiveis.indexOf(_controlador.aba).clamp(0, 1),
              aoSelecionar: (indice) =>
                  _controlador.mudarAba(_abasVisiveis[indice]),
            ),
          ),
        ),
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
