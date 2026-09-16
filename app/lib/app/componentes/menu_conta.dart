import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Cartão de identificação reutilizado nas superfícies de conta do mobile.
class PerfilContaRadar extends StatelessWidget {
  const PerfilContaRadar({
    super.key,
    required this.identificacao,
    required this.administrador,
  });

  final String? identificacao;
  final bool administrador;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    final tema = Theme.of(context);
    final nome = identificacao ?? 'Conta do Radar';
    final escuro = tema.brightness == Brightness.dark;
    return DecoratedBox(
      key: const Key('perfil-conta'),
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(tokens.radii.md),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.four),
        child: Row(
          children: [
            CircleAvatar(
              radius: tokens.spacing.four,
              backgroundColor: escuro
                  ? Tokens.superficieForteEscura
                  : Tokens.superficieForte,
              foregroundColor: escuro ? Tokens.textoEscuro : Tokens.texto,
              child: Text(
                iniciaisContaRadar(nome),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            SizedBox(width: tokens.spacing.three),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.one),
                  Text(
                    administrador ? 'Acesso administrador' : 'Acesso padrão',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: cores.textoSuave,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha de navegação de uma seção do perfil, com área de toque integral.
class LinhaContaRadar extends StatelessWidget {
  const LinhaContaRadar({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.mostrarSeta = true,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final bool mostrarSeta;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    final tema = Theme.of(context);
    return Row(
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
                titulo,
                style: tema.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
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
        if (mostrarSeta) ...[
          SizedBox(width: tokens.spacing.two),
          const Icon(Icons.chevron_right),
        ],
      ],
    );
  }
}

String iniciaisContaRadar(String nome) {
  final partes = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((parte) => parte.isNotEmpty)
      .toList(growable: false);
  if (partes.isEmpty) return 'R';
  if (partes.length == 1) return partes.first.characters.first.toUpperCase();
  return '${partes.first.characters.first}${partes.last.characters.first}'
      .toUpperCase();
}
