import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api_v1.dart';
import 'cartao_cashback_inter.dart';
import 'controlador_cashback_inter.dart';
import 'formato_cashback_inter.dart';
import '../produtos/pagina_produtos.dart';

/// Consulta somente leitura dos Sites parceiros do Inter (Fase 4.3).
class PaginaCashbackInter extends StatefulWidget {
  const PaginaCashbackInter({super.key, required this.api, this.controlador});

  final ApiV1 api;
  final ControladorCashbackInter? controlador;

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

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => _conteudo(context),
  );

  Widget _conteudo(BuildContext context) {
    final atrasada = coletaInterAtrasada(
      _controlador.atualizadoEm,
      DateTime.now(),
    );
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Shopping Inter',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Produtos no Inter',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PaginaProdutos(api: widget.api),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _campoBusca,
              onChanged: _controlador.mudarBusca,
              decoration: const InputDecoration(
                labelText: 'Buscar por loja',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                'Última coleta: ${dataHoraInter(_controlador.atualizadoEm)}'
                '${atrasada ? ' · dados atrasados' : ''}',
                style: TextStyle(color: atrasada ? Tokens.atencao : null),
              ),
            ),
          if (_controlador.atualizadoEm != null && !_controlador.carregando)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Text('${_controlador.totalItens} lojas acompanhadas'),
            ),
          if (_controlador.ultimaTentativaFalhou &&
              _controlador.atualizadoEm != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  'A última sincronização do Inter falhou. '
                  'Exibindo a última coleta válida.',
                  style: const TextStyle(color: Tokens.perigo),
                ),
              ),
            ),
          Expanded(child: _corpo()),
        ],
      ),
    );
  }

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
            ? 'Nenhuma loja do Inter está sendo acompanhada.'
            : 'Nenhuma loja encontrada para “${_controlador.busca.trim()}”.',
      );
    }
    return LayoutBuilder(
      builder: (context, limites) {
        final colunas = limites.maxWidth >= 900 ? 2 : 1;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            if (colunas == 1)
              for (final loja in _controlador.itens)
                CartaoCashbackInter(loja: loja)
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final loja in _controlador.itens)
                    SizedBox(
                      width: (limites.maxWidth - 16) / 2,
                      child: CartaoCashbackInter(loja: loja),
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
