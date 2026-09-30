import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/navegacao/destinos.dart';
import '../../app/tema/aparencia.dart';
import '../../app/tema/tokens.dart';

class PaginaAparencia extends StatelessWidget {
  const PaginaAparencia({
    super.key,
    this.destinoSelecionado = DestinoCompacto.perfil,
    this.aoNavegar,
  });

  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controlador = AparenciaRadar.talvezDe(context);
    final modo = controlador?.modo ?? ThemeMode.system;
    final reduzirMovimento = controlador?.reduzirMovimento ?? false;
    final compacto = MediaQuery.sizeOf(context).width < 920;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aparência'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.four,
            tokens.spacing.five,
            tokens.spacing.four,
            tokens.spacing.eight,
          ),
          children: [
            const CabecalhoSecaoRadar(
              titulo: 'Do seu jeito.',
              descricao: 'Uma escolha para todo o aplicativo.',
            ),
            SizedBox(height: tokens.spacing.six),
            _OpcaoTema(
              key: const Key('aparencia-opcao-system'),
              modo: ThemeMode.system,
              titulo: 'Seguir o sistema',
              descricao: 'Acompanha a aparência do aparelho.',
              selecionada: modo == ThemeMode.system,
              aoTocar: controlador == null
                  ? null
                  : () => controlador.definir(ThemeMode.system),
            ),
            SizedBox(height: tokens.spacing.three),
            _OpcaoTema(
              key: const Key('aparencia-opcao-light'),
              modo: ThemeMode.light,
              titulo: 'Claro',
              descricao: 'Luz suave, leitura confortável.',
              selecionada: modo == ThemeMode.light,
              aoTocar: controlador == null
                  ? null
                  : () => controlador.definir(ThemeMode.light),
            ),
            SizedBox(height: tokens.spacing.three),
            _OpcaoTema(
              key: const Key('aparencia-opcao-dark'),
              modo: ThemeMode.dark,
              titulo: 'Escuro',
              descricao: 'Grafite, contraste e menos brilho.',
              selecionada: modo == ThemeMode.dark,
              aoTocar: controlador == null
                  ? null
                  : () => controlador.definir(ThemeMode.dark),
            ),
            SizedBox(height: tokens.spacing.five),
            Text('Movimento', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: tokens.spacing.two),
            _OpcaoMovimento(
              reduzirMovimento: reduzirMovimento,
              aoMudar: controlador == null
                  ? null
                  : (valor) => controlador.definirReduzirMovimento(valor),
            ),
          ],
        ),
      ),
      bottomNavigationBar: compacto && aoNavegar != null
          ? BarraInferiorRadar(
              selecionado: destinoSelecionado.destinoDaBarra,
              aoSelecionar: aoNavegar!,
            )
          : null,
    );
  }
}

class _OpcaoMovimento extends StatelessWidget {
  const _OpcaoMovimento({
    required this.reduzirMovimento,
    required this.aoMudar,
  });

  final bool reduzirMovimento;
  final ValueChanged<bool>? aoMudar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    return MergeSemantics(
      child: Padding(
        key: const Key('aparencia-reduzir-movimento'),
        padding: EdgeInsetsDirectional.symmetric(
          vertical: tokens.spacing.three,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reduzir animações',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.one),
                  Text(
                    'Transições mais discretas.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                  ),
                ],
              ),
            ),
            Switch(value: reduzirMovimento, onChanged: aoMudar),
          ],
        ),
      ),
    );
  }
}

class _OpcaoTema extends StatelessWidget {
  const _OpcaoTema({
    super.key,
    required this.modo,
    required this.titulo,
    required this.descricao,
    required this.selecionada,
    required this.aoTocar,
  });

  final ThemeMode modo;
  final String titulo;
  final String descricao;
  final bool selecionada;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.lg),
      side: BorderSide(color: selecionada ? cores.acao : cores.borda),
    );
    final corSuperficie = selecionada
        ? tokens.colors.acaoFundo
        : cores.superficie;
    return Semantics(
      button: true,
      selected: selecionada,
      label: '$titulo${selecionada ? ', ativo' : ''}. $descricao',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: tokens.sizes.field + tokens.spacing.eight,
        ),
        child: Material(
          color: corSuperficie,
          shape: forma,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: aoTocar,
            child: Padding(
              padding: EdgeInsets.all(tokens.spacing.four),
              child: Row(
                children: [
                  _AmostraTema(modo: modo),
                  SizedBox(width: tokens.spacing.four),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titulo,
                          style: tema.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: tokens.spacing.one),
                        Text(
                          descricao,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: cores.textoSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: tokens.spacing.two),
                  Icon(
                    selecionada ? Icons.check : Icons.chevron_right,
                    color: cores.textoSuave,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmostraTema extends StatelessWidget {
  const _AmostraTema({required this.modo});

  final ThemeMode modo;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    final corClara = const CoresRadar.claras().canvas;
    final corEscura = const CoresRadar.escuras().superficie;
    return Container(
      width: tokens.spacing.eight,
      height: tokens.sizes.field + tokens.spacing.one,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: cores.borda),
        borderRadius: BorderRadius.circular(tokens.radii.md),
      ),
      child: switch (modo) {
        ThemeMode.light => ColoredBox(color: corClara),
        ThemeMode.dark => ColoredBox(color: corEscura),
        ThemeMode.system => Row(
          children: [
            Expanded(child: ColoredBox(color: corClara)),
            Expanded(child: ColoredBox(color: corEscura)),
          ],
        ),
      },
    );
  }
}
