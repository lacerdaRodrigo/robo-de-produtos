import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';
import 'controlador_alertas.dart';

class PaginaAlertas extends StatefulWidget {
  const PaginaAlertas({super.key, required this.api, this.coletaInicial});

  final Api api;
  final String? coletaInicial;

  @override
  State<PaginaAlertas> createState() => _EstadoPaginaAlertas();
}

class _EstadoPaginaAlertas extends State<PaginaAlertas> {
  late final ControladorAlertas _controlador = ControladorAlertas(
    api: widget.api,
    coletaInicial: widget.coletaInicial,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controlador.iniciar());
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _preferencias() async {
    late final PreferenciasAlertas preferencias;
    try {
      preferencias = await widget.api.preferenciasAlertas();
    } catch (_) {
      if (!mounted) return;
      mostrarMensagemRadar(
        context,
        'Não foi possível carregar as preferências agora.',
        sucesso: false,
      );
      return;
    }
    if (!mounted) return;
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.78,
      builder: (_) =>
          _FolhaPreferenciasAlertas(api: widget.api, iniciais: preferencias),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Central de Alertas'),
      leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        IconButton(
          key: const Key('preferencias-alertas'),
          tooltip: 'Preferências',
          icon: const Icon(Icons.tune_rounded),
          onPressed: _preferencias,
        ),
      ],
    ),
    body: AnimatedBuilder(
      animation: _controlador,
      builder: (context, _) => RefreshIndicator(
        onRefresh: _controlador.carregar,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
              sliver: SliverToBoxAdapter(
                child: const CabecalhoSecaoRadar(
                  sobrelinha: 'Conta',
                  titulo: 'Central de Alertas',
                  descricao:
                      'Mudanças válidas nos itens que você acompanha, preservadas por até 90 dias.',
                ),
              ),
            ),
            SliverToBoxAdapter(child: _filtros()),
            SliverToBoxAdapter(child: _resumo()),
            ..._corpo(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 36),
              sliver: SliverToBoxAdapter(
                child: PaginacaoRadar(
                  pagina: _controlador.pagina,
                  totalItens: _controlador.totalItens,
                  porPagina: _controlador.porPagina,
                  carregando: _controlador.carregando,
                  erro: _controlador.erro,
                  aoIrParaPagina: _controlador.irParaPagina,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _filtros() {
    final cores = CoresRadar.de(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filtro in const [
              'todos',
              'preco',
              'cashback',
              'pontuacao',
              'nao_lidos',
            ]) ...[
              if (filtro != 'todos') const SizedBox(width: 7),
              ChoiceChip(
                label: Text(_rotuloFiltro(filtro)),
                selected: _controlador.filtro == filtro,
                selectedColor: cores.marca,
                checkmarkColor: Theme.of(context).colorScheme.onSecondary,
                labelStyle: TextStyle(
                  color: _controlador.filtro == filtro
                      ? Theme.of(context).colorScheme.onSecondary
                      : null,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) => _controlador.mudarFiltro(filtro),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resumo() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 13),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${_controlador.naoLidos} não lidos',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: _controlador.naoLidos == 0
              ? null
              : () async {
                  try {
                    await _controlador.marcarVisiveis();
                    if (mounted) {
                      mostrarMensagemRadar(
                        context,
                        'Alertas visíveis marcados como lidos.',
                      );
                    }
                  } catch (_) {
                    if (mounted) {
                      mostrarMensagemRadar(
                        context,
                        'Não foi possível marcar os alertas.',
                        sucesso: false,
                      );
                    }
                  }
                },
          child: const Text('Marcar visíveis'),
        ),
      ],
    ),
  );

  List<Widget> _corpo() {
    if (_controlador.carregando && _controlador.itens.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Carregando(mensagem: 'Carregando alertas…'),
        ),
      ];
    }
    if (_controlador.erro != null && _controlador.itens.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoFalha(
            mensagem: _controlador.erro is ErroDeRede
                ? 'Sem conexão. A Central precisa de internet para atualizar.'
                : 'Não foi possível carregar a Central agora.',
            voltar: _controlador.carregar,
          ),
        ),
      ];
    }
    if (_controlador.itens.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: EstadoVazio(
            mensagem: 'Nenhum alerta corresponde a este filtro.',
          ),
        ),
      ];
    }
    return [
      if (_controlador.parcial)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
          sliver: SliverToBoxAdapter(
            child: _aviso(
              'A atualização foi parcial; o último resultado válido continua visível.',
              TomRadar.atencao,
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        sliver: SliverList.separated(
          itemCount: _controlador.itens.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, indice) => _CartaoAlerta(
            alerta: _controlador.itens[indice],
            aoMarcar: () async {
              try {
                await _controlador.marcar(_controlador.itens[indice]);
              } catch (_) {
                if (!mounted) return;
                mostrarMensagemRadar(
                  this.context,
                  'Não foi possível atualizar a leitura.',
                  sucesso: false,
                );
              }
            },
          ),
        ),
      ),
    ];
  }

  Widget _aviso(String mensagem, TomRadar tom) => DecoratedBox(
    decoration: BoxDecoration(
      color: tom == TomRadar.atencao
          ? Tokens.atencaoFundo
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        mensagem,
        style: TextStyle(color: CoresRadar.de(context).atencao, fontSize: 11),
      ),
    ),
  );
}

class _CartaoAlerta extends StatelessWidget {
  const _CartaoAlerta({required this.alerta, required this.aoMarcar});
  final AlertaApp alerta;
  final VoidCallback aoMarcar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final cor = alerta.tipo == TipoAlertaApp.preco
        ? cores.acao
        : alerta.tipo == TipoAlertaApp.cashback
        ? cores.ganho
        : cores.marca;
    final titulo = '${_rotuloTipo(alerta.tipo)} · ${alerta.entidadeNome}';
    final comparacao = alerta.valorAnterior == null
        ? alerta.valorAtual
        : '${alerta.valorAnterior} → ${alerta.valorAtual}';
    return CartaoRadar(
      corDestaque: alerta.lido ? null : cor,
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: SizedBox.square(
              dimension: 34,
              child: Icon(
                alerta.tipo == TipoAlertaApp.preco
                    ? Icons.sell_outlined
                    : alerta.tipo == TipoAlertaApp.cashback
                    ? Icons.payments_outlined
                    : Icons.stars_outlined,
                color: cor,
                size: 19,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$comparacao ${alerta.unidade}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                ),
                const SizedBox(height: 5),
                Text(
                  '${alerta.origem} · ${alerta.criadoEm}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cores.textoSuave,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: aoMarcar,
            child: Text(
              alerta.lido ? 'Não lido' : 'Marcar lido',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolhaPreferenciasAlertas extends StatefulWidget {
  const _FolhaPreferenciasAlertas({required this.api, required this.iniciais});
  final Api api;
  final PreferenciasAlertas iniciais;

  @override
  State<_FolhaPreferenciasAlertas> createState() =>
      _EstadoFolhaPreferenciasAlertas();
}

class _EstadoFolhaPreferenciasAlertas extends State<_FolhaPreferenciasAlertas> {
  late PreferenciasAlertas _valor = widget.iniciais;
  var _salvando = false;

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await widget.api.salvarPreferenciasAlertas(_valor);
      if (mounted) {
        mostrarMensagemRadar(context, 'Preferências salvas.');
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagemRadar(
          context,
          'Não foi possível salvar as preferências.',
          sucesso: false,
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) => FolhaRadar(
    titulo: 'Preferências de alertas',
    descricao: 'Push é opcional; o histórico permanece acessível.',
    child: Flexible(
      child: ListView(
        shrinkWrap: true,
        children: [
          _chave(
            'Receber notificações',
            'Resumo por coleta válida',
            _valor.pushGlobal,
            (value) =>
                setState(() => _valor = _valor.copiarCom(pushGlobal: value)),
          ),
          _chave(
            'Alterações de preço',
            null,
            _valor.preco,
            (value) => setState(() => _valor = _valor.copiarCom(preco: value)),
          ),
          _chave(
            'Alterações de cashback',
            null,
            _valor.cashback,
            (value) =>
                setState(() => _valor = _valor.copiarCom(cashback: value)),
          ),
          _chave(
            'Alterações de pontuação',
            null,
            _valor.pontuacao,
            (value) =>
                setState(() => _valor = _valor.copiarCom(pontuacao: value)),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: Text(_salvando ? 'Salvando…' : 'Salvar preferências'),
          ),
        ],
      ),
    ),
  );

  Widget _chave(
    String titulo,
    String? descricao,
    bool valor,
    ValueChanged<bool> aoMudar,
  ) => SwitchListTile(
    title: Text(titulo),
    subtitle: descricao == null ? null : Text(descricao),
    value: valor,
    onChanged: aoMudar,
    contentPadding: EdgeInsets.zero,
  );
}

String _rotuloFiltro(String filtro) => switch (filtro) {
  'todos' => 'Todos',
  'preco' => 'Preço',
  'cashback' => 'Cashback',
  'pontuacao' => 'Pontuação',
  _ => 'Não lidos',
};
String _rotuloTipo(TipoAlertaApp tipo) => switch (tipo) {
  TipoAlertaApp.preco => 'Preço mudou',
  TipoAlertaApp.cashback => 'Cashback mudou',
  TipoAlertaApp.pontuacao => 'Pontuação mudou',
};
