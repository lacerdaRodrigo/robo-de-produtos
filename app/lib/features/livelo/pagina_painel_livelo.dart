import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
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
  });

  final Api api;
  final ControladorPainelLivelo? controlador;
  final bool administrador;

  @override
  State<PaginaPainelLivelo> createState() => _EstadoPaginaPainelLivelo();
}

class _EstadoPaginaPainelLivelo extends State<PaginaPainelLivelo> {
  late final ControladorPainelLivelo _controlador =
      widget.controlador ??
      ControladorPainelLivelo(
        buscar: ({required q, required ordenar, required pagina}) =>
            widget.api.painelLivelo(q: q, ordenar: ordenar, pagina: pagina),
      );
  late final bool _controladorVeioDeFora = widget.controlador != null;
  final TextEditingController _campoBusca = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
  }

  @override
  void dispose() {
    _campoBusca.dispose();
    if (!_controladorVeioDeFora) {
      _controlador.dispose();
    }
    super.dispose();
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
  });

  final ControladorPainelLivelo controlador;
  final TextEditingController campoBusca;
  final Api api;
  final bool administrador;

  @override
  Widget build(BuildContext context) {
    final agora = DateTime.now();
    final atrasada = coletaAtrasada(controlador.atualizadoEm, agora);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Livelo',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                BotaoDisparo(
                  api: api,
                  dominio: 'livelo',
                  administrador: administrador,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: campoBusca,
              onChanged: controlador.mudarBusca,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                labelText: 'Buscar por loja ou categoria',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ordenacao in OrdenacaoLivelo.values)
                  ChoiceChip(
                    label: Text(ordenacao.rotulo),
                    selected: controlador.ordenacao == ordenacao,
                    onSelected: (_) => controlador.mudarOrdenacao(ordenacao),
                  ),
              ],
            ),
          ),
          if (controlador.atualizadoEm != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    atrasada ? Icons.schedule : Icons.check_circle_outline,
                    size: 18,
                    color: atrasada ? Tokens.atencao : Tokens.ganho,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Última coleta: ${dataHoraLivelo(controlador.atualizadoEm)}'
                      '${atrasada ? ' · dados atrasados' : ''}',
                      style: TextStyle(color: atrasada ? Tokens.atencao : null),
                    ),
                  ),
                ],
              ),
            ),
          if (controlador.atualizadoEm != null &&
              !controlador.carregandoInicial)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text('${controlador.totalItens} lojas encontradas'),
            ),
          Expanded(child: _corpo(context)),
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
    if (controlador.carregandoMais) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controlador.erroMais != null) {
      return Center(
        child: FilledButton.tonalIcon(
          onPressed: controlador.carregarMais,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar carregar mais'),
        ),
      );
    }
    if (controlador.temProxima) {
      return Center(
        child: FilledButton(
          onPressed: controlador.carregarMais,
          child: const Text('Carregar mais'),
        ),
      );
    }
    return const Center(child: Text('Todos os resultados foram carregados.'));
  }
}
