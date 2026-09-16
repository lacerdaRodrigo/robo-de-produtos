import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/aparencia.dart';
import '../../app/tema/tokens.dart';

class PaginaAparencia extends StatelessWidget {
  const PaginaAparencia({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controlador = AparenciaRadar.talvezDe(context);
    final modo = controlador?.modo ?? ThemeMode.system;
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
              sobrelinha: 'Perfil / Aparência',
              titulo: 'Escolha como o Radar aparece.',
              descricao: 'A mudança é imediata e não reinicia sua sessão.',
            ),
            SizedBox(height: tokens.spacing.six),
            _OpcaoTema(
              key: const Key('aparencia-opcao-system'),
              icone: Icons.brightness_auto_outlined,
              titulo: 'Sistema',
              descricao: 'Segue a preferência do aparelho.',
              selecionada: modo == ThemeMode.system,
              aoTocar: controlador == null
                  ? null
                  : () => controlador.definir(ThemeMode.system),
            ),
            SizedBox(height: tokens.spacing.three),
            _OpcaoTema(
              key: const Key('aparencia-opcao-light'),
              icone: Icons.light_mode_outlined,
              titulo: 'Claro',
              descricao: 'Superfícies abertas e contraste nítido.',
              selecionada: modo == ThemeMode.light,
              aoTocar: controlador == null
                  ? null
                  : () => controlador.definir(ThemeMode.light),
            ),
            SizedBox(height: tokens.spacing.three),
            _OpcaoTema(
              key: const Key('aparencia-opcao-dark'),
              icone: Icons.dark_mode_outlined,
              titulo: 'Escuro',
              descricao: 'Fundo profundo para pouca luz.',
              selecionada: modo == ThemeMode.dark,
              aoTocar: controlador == null
                  ? null
                  : () => controlador.definir(ThemeMode.dark),
            ),
            SizedBox(height: tokens.spacing.five),
            CartaoRadar(
              corDestaque: CoresRadar.de(context).teal,
              child: Text(
                'Em Sistema, o Radar acompanha o tema do dispositivo quando essa informação existir.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: CoresRadar.de(context).textoSuave,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcaoTema extends StatelessWidget {
  const _OpcaoTema({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.selecionada,
    required this.aoTocar,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool selecionada;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    return Semantics(
      button: true,
      selected: selecionada,
      label: '$titulo${selecionada ? ', ativo' : ''}. $descricao',
      child: CartaoRadar(
        aoTocar: aoTocar,
        corDestaque: selecionada ? cores.acao : null,
        padding: EdgeInsets.all(tokens.spacing.four),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: cores.superficieAlternativa,
                borderRadius: BorderRadius.circular(tokens.radii.md),
              ),
              child: SizedBox.square(
                dimension: tokens.spacing.nine,
                child: Icon(icone, color: cores.acao),
              ),
            ),
            SizedBox(width: tokens.spacing.three),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$titulo${selecionada ? ' · ativo' : ''}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.one),
                  Text(
                    descricao,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                  ),
                ],
              ),
            ),
            Icon(selecionada ? Icons.check_circle : Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
