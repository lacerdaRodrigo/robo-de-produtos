import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../administracao/botao_disparo.dart';
import 'cartao_livelo.dart';
import 'controlador_painel_livelo.dart';
import 'formato_livelo.dart';

/// Painel somente-leitura da Livelo (Fase 4.2B).
class PaginaPainelLivelo extends StatefulWidget {
  const PaginaPainelLivelo({
    super.key,
    required this.api,
    this.controlador,
    this.administrador = false,
    this.experienciaCompacta = false,
  });

  final Api api;
  final ControladorPainelLivelo? controlador;
  final bool administrador;
  final bool experienciaCompacta;

  @override
  State<PaginaPainelLivelo> createState() => _EstadoPaginaPainelLivelo();
}

class _EstadoPaginaPainelLivelo extends State<PaginaPainelLivelo> {
  static const _itensPorPagina = 10;

  late final ControladorPainelLivelo _controlador =
      widget.controlador ??
      ControladorPainelLivelo(
        buscar: ({required q, required ordenar, required pagina}) =>
            widget.api.painelLivelo(
              q: q,
              ordenar: ordenar,
              pagina: pagina,
              porPagina: _itensPorPagina,
            ),
      );
  late final bool _controladorVeioDeFora = widget.controlador != null;
  final TextEditingController _campoBusca = TextEditingController();
  final _rolagem = ScrollController();

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
  }

  @override
  void dispose() {
    _campoBusca.dispose();
    _rolagem.dispose();
    if (!_controladorVeioDeFora) {
      _controlador.dispose();
    }
    super.dispose();
  }

  Future<void> _irParaPagina(int pagina) async {
    await _controlador.irParaPagina(pagina);
    if (!mounted || _controlador.pagina != pagina) return;
    await rolarParaInicioPaginaRadar(_rolagem);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) => _PainelLiveloConteudo(
        controlador: _controlador,
        campoBusca: _campoBusca,
        api: widget.api,
        administrador: widget.administrador,
        experienciaCompacta: widget.experienciaCompacta,
        rolagem: _rolagem,
        aoIrParaPagina: _irParaPagina,
      ),
    );
  }
}

class _PainelLiveloConteudo extends StatelessWidget {
  const _PainelLiveloConteudo({
    required this.controlador,
    required this.campoBusca,
    required this.api,
    required this.administrador,
    required this.experienciaCompacta,
    required this.rolagem,
    required this.aoIrParaPagina,
  });

  final ControladorPainelLivelo controlador;
  final TextEditingController campoBusca;
  final Api api;
  final bool administrador;
  final bool experienciaCompacta;
  final ScrollController rolagem;
  final Future<void> Function(int pagina) aoIrParaPagina;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final atrasada = coletaAtrasada(controlador.atualizadoEm, agora);
    final cores = CoresRadar.de(context);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      experienciaCompacta ? 20 : 24,
                      experienciaCompacta ? 24 : 24,
                      experienciaCompacta ? 20 : 24,
                      12,
                    ),
                    child: experienciaCompacta
                        ? CabecalhoSecaoRadar(
                            sobrelinha: 'Programa de pontos',
                            titulo: 'Livelo',
                            descricao:
                                'Lojas, pontos e campanhas no último retrato salvo. Navegar aqui não consulta a Livelo ao vivo.',
                          )
                        : Text(
                            'Livelo',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      experienciaCompacta ? 20 : 24,
                      0,
                      experienciaCompacta ? 20 : 24,
                      12,
                    ),
                    child: BotaoDisparo(
                      api: api,
                      dominio: 'livelo',
                      administrador: administrador,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: experienciaCompacta ? 20 : 24,
                    ),
                    child: CampoBuscaRadar(
                      controlador: campoBusca,
                      dica: experienciaCompacta
                          ? 'Buscar loja ou categoria'
                          : 'Buscar por loja ou categoria',
                      aoMudar: controlador.mudarBusca,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      experienciaCompacta ? 20 : 24,
                      12,
                      experienciaCompacta ? 20 : 24,
                      8,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final ordenacao in OrdenacaoLivelo.values)
                          ChoiceChip(
                            label: Text(ordenacao.rotulo),
                            selected: controlador.ordenacao == ordenacao,
                            onSelected: (_) =>
                                controlador.mudarOrdenacao(ordenacao),
                          ),
                      ],
                    ),
                  ),
                  if (controlador.atualizadoEm != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: experienciaCompacta ? 20 : 24,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            atrasada
                                ? Icons.schedule
                                : Icons.check_circle_outline,
                            size: 18,
                            color: atrasada ? cores.atencao : cores.ganho,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Última coleta: ${dataHoraLivelo(controlador.atualizadoEm)}'
                              '${atrasada ? ' · dados atrasados' : ''}',
                              style: TextStyle(
                                color: atrasada ? cores.atencao : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (controlador.atualizadoEm != null &&
                      !controlador.carregandoInicial)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        experienciaCompacta ? 20 : 24,
                        4,
                        experienciaCompacta ? 20 : 24,
                        8,
                      ),
                      child: Text(
                        '${controlador.totalItens} lojas encontradas',
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(flex: 3, child: _corpo(context)),
        ],
      ),
    );
  }

  Widget _corpo(BuildContext context) {
    if (controlador.carregandoInicial) {
      return const Carregando(mensagem: 'Carregando painel Livelo…');
    }
    if (controlador.erroInicial != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o painel Livelo.',
        voltar: controlador.tentarNovamente,
      );
    }
    if (controlador.atualizadoEm == null) {
      return const EstadoVazio(
        mensagem: 'Ainda não há uma coleta da Livelo para mostrar.',
      );
    }
    if (controlador.totalItens == 0) {
      if (controlador.busca.trim().isNotEmpty) {
        return EstadoVazio(
          mensagem:
              'Nenhuma loja encontrada para “${controlador.busca.trim()}”.',
        );
      }
      if (controlador.ordenacao == OrdenacaoLivelo.alerta) {
        return const EstadoVazio(
          mensagem: 'Nenhuma loja está em alerta agora.',
        );
      }
      return const EstadoVazio(mensagem: 'Nenhuma loja está cadastrada ainda.');
    }

    return LayoutBuilder(
      builder: (context, limites) {
        final colunas = limites.maxWidth >= 900 ? 2 : 1;
        return ListView(
          controller: rolagem,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (colunas == 1)
              for (final loja in controlador.itens) CartaoLivelo(loja: loja)
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final loja in controlador.itens)
                    SizedBox(
                      width: (limites.maxWidth - 16) / 2,
                      child: CartaoLivelo(loja: loja),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            _paginacao(context),
          ],
        );
      },
    );
  }

  Widget _paginacao(BuildContext context) {
    return PaginacaoRadar(
      pagina: controlador.pagina,
      totalItens: controlador.totalItens,
      porPagina: controlador.porPagina,
      carregando: controlador.carregandoMais,
      erro: controlador.erroMais,
      aoIrParaPagina: aoIrParaPagina,
    );
  }
}
