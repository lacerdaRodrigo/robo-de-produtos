import 'package:flutter/material.dart';

import '../fundacao/ds_medidas.dart';
import '../fundacao/ds_tema.dart';
import 'ds_basicos.dart';

/// Vazio ou "nada com esses filtros". Uma ação no máximo.
class DsEstadoVazio extends StatelessWidget {
  const DsEstadoVazio({
    super.key,
    required this.titulo,
    required this.texto,
    this.icone = Icons.search_off_rounded,
    this.rotuloAcao,
    this.aoAcionar,
  });

  final String titulo;
  final String texto;
  final IconData icone;
  final String? rotuloAcao;
  final VoidCallback? aoAcionar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipo;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsEspaco.e6,
        vertical: DsEspaco.e10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c.primariaSuave,
              shape: BoxShape.circle,
            ),
            child: Icon(icone, color: c.primariaForte),
          ),
          const SizedBox(height: DsEspaco.e4),
          Text(titulo, style: t.tituloItem, textAlign: TextAlign.center),
          const SizedBox(height: DsEspaco.e2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              texto,
              textAlign: TextAlign.center,
              style: t.corpo.copyWith(fontSize: 14, color: c.texto2),
            ),
          ),
          if (rotuloAcao != null && aoAcionar != null) ...[
            const SizedBox(height: DsEspaco.e4),
            DsBotao(
              rotulo: rotuloAcao!,
              aoTocar: aoAcionar,
              variante: DsVarianteBotao.tonal,
            ),
          ],
        ],
      ),
    );
  }
}

/// Falha de carregamento com "Tentar de novo".
class DsEstadoErro extends StatelessWidget {
  const DsEstadoErro({
    super.key,
    this.titulo = 'Não foi possível carregar',
    this.texto = 'Verifique a conexão e tente de novo.',
    required this.aoTentarDeNovo,
  });

  final String titulo;
  final String texto;
  final VoidCallback aoTentarDeNovo;

  @override
  Widget build(BuildContext context) => DsEstadoVazio(
    titulo: titulo,
    texto: texto,
    icone: Icons.cloud_off_rounded,
    rotuloAcao: 'Tentar de novo',
    aoAcionar: aoTentarDeNovo,
  );
}

/// Faixa de aviso dentro da tela (coleta parcial, dados antigos, erro com
/// dados anteriores ainda visíveis).
class DsFaixa extends StatelessWidget {
  const DsFaixa({super.key, required this.texto, this.tom = DsTom.atencao});

  final String texto;
  final DsTom tom;

  @override
  Widget build(BuildContext context) {
    final (fundo, frente) = tom.cores(context.cores);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(DsRaio.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DsEspaco.e4,
            vertical: DsEspaco.e3,
          ),
          child: Text(texto, style: context.tipo.rotulo.copyWith(color: frente)),
        ),
      ),
    );
  }
}

/// Esqueleto de carregamento. Só no PRIMEIRO carregamento; em atualizações
/// o conteúdo anterior continua visível.
class DsSkeleton extends StatelessWidget {
  const DsSkeleton({super.key, this.largura, this.altura = 14});

  final double? largura;
  final double altura;

  /// Um cartão inteiro.
  static Widget cartao() => const _SkeletonCartao();

  /// `n` linhas de histórico.
  static Widget linhas(int n) => Column(
    children: [
      for (var i = 0; i < n; i++)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: DsEspaco.e3),
          child: Row(
            children: [
              Expanded(child: DsSkeleton(largura: 120)),
              DsSkeleton(largura: 88, altura: 18),
            ],
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        width: largura,
        height: altura,
        decoration: BoxDecoration(
          color: context.cores.superficie2,
          borderRadius: BorderRadius.circular(DsRaio.xs),
        ),
      ),
    ),
  );
}

class _SkeletonCartao extends StatelessWidget {
  const _SkeletonCartao();

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Semantics(
      label: 'Carregando',
      child: Container(
        padding: const EdgeInsets.all(DsEspaco.e4),
        decoration: BoxDecoration(
          color: c.superficie1,
          borderRadius: BorderRadius.circular(DsRaio.md),
          border: Border.all(color: c.borda1),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DsSkeleton(largura: 96, altura: 12),
            SizedBox(height: DsEspaco.e2),
            DsSkeleton(largura: 220, altura: 18),
            SizedBox(height: DsEspaco.e4),
            DsSkeleton(largura: 140, altura: 24),
          ],
        ),
      ),
    );
  }
}

/// SnackBar do DS: uma ação no máximo (Desfazer, Tentar de novo).
abstract final class DsAviso {
  static void mostrar(
    BuildContext context, {
    required String texto,
    String? rotuloAcao,
    VoidCallback? aoAcionar,
  }) {
    final mensageiro = ScaffoldMessenger.of(context);
    mensageiro.hideCurrentSnackBar();
    mensageiro.showSnackBar(
      SnackBar(
        content: Text(texto),
        duration: const Duration(seconds: 4),
        action: rotuloAcao != null && aoAcionar != null
            ? SnackBarAction(label: rotuloAcao, onPressed: aoAcionar)
            : null,
      ),
    );
  }
}
