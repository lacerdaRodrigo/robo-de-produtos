import 'package:flutter/material.dart';

import '../tema/aparencia.dart';
import '../tema/tokens.dart';

enum TomRadar { neutro, acao, ganho, atencao, perigo }

Color _corDoTom(BuildContext context, TomRadar tom) {
  final cores = CoresRadar.de(context);
  return switch (tom) {
    TomRadar.neutro => cores.textoSuave,
    TomRadar.acao => cores.acao,
    TomRadar.ganho => cores.ganho,
    TomRadar.atencao => cores.atencao,
    TomRadar.perigo => cores.perigo,
  };
}

/// Cabeçalho de conteúdo usado pelas áreas da nova experiência mobile.
class CabecalhoSecaoRadar extends StatelessWidget {
  const CabecalhoSecaoRadar({
    super.key,
    required this.titulo,
    required this.descricao,
    this.sobrelinha,
    this.acao,
  });

  final String titulo;
  final String descricao;
  final String? sobrelinha;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sobrelinha != null) ...[
          Text(
            sobrelinha!.toUpperCase(),
            style: tema.textTheme.labelSmall?.copyWith(
              color: cores.acao,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 7),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                titulo,
                style: tema.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
              ),
            ),
            if (acao != null) ...[const SizedBox(width: 12), acao!],
          ],
        ),
        const SizedBox(height: 7),
        Text(
          descricao,
          style: tema.textTheme.bodyMedium?.copyWith(
            color: cores.textoSuave,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Superfície comum dos cartões, com foco e toque fornecidos pelo Material.
class CartaoRadar extends StatelessWidget {
  const CartaoRadar({
    super.key,
    required this.child,
    this.aoTocar,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? aoTocar;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(21),
      side: BorderSide(color: cores.borda),
    );
    final conteudo = Padding(padding: padding, child: child);
    return Material(
      color: tema.cardColor,
      shape: forma,
      clipBehavior: Clip.antiAlias,
      child: aoTocar == null
          ? conteudo
          : InkWell(onTap: aoTocar, child: conteudo),
    );
  }
}

/// Estado curto que nunca depende apenas da cor para comunicar significado.
class IndicadorEstadoRadar extends StatelessWidget {
  const IndicadorEstadoRadar({
    super.key,
    required this.texto,
    this.tom = TomRadar.neutro,
  });

  final String texto;
  final TomRadar tom;

  @override
  Widget build(BuildContext context) {
    final cor = _corDoTom(context, tom);
    return Semantics(
      label: texto,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            child: const SizedBox.square(dimension: 7),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              texto,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: cor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de busca do novo mobile, sem acoplar debounce ou consulta ao visual.
class CampoBuscaRadar extends StatelessWidget {
  const CampoBuscaRadar({
    super.key,
    required this.controlador,
    required this.dica,
    required this.aoMudar,
    this.acao,
  });

  final TextEditingController controlador;
  final String dica;
  final ValueChanged<String> aoMudar;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controlador,
      onChanged: aoMudar,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: dica,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: acao,
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: CoresRadar.de(context).borda),
        ),
      ),
    );
  }
}

/// Abas roláveis que preservam rótulos completos em telas estreitas.
class AbasRadar extends StatelessWidget {
  const AbasRadar({
    super.key,
    required this.rotulos,
    required this.selecionada,
    required this.aoSelecionar,
  });

  final List<String> rotulos;
  final int selecionada;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var indice = 0; indice < rotulos.length; indice++) ...[
            ChoiceChip(
              label: Text(rotulos[indice]),
              selected: indice == selecionada,
              onSelected: (_) => aoSelecionar(indice),
            ),
            if (indice != rotulos.length - 1) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

/// Estrutura das folhas de Alertas e Conta/Sistema previstas para a Etapa 7.
class FolhaRadar extends StatelessWidget {
  const FolhaRadar({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.child,
  });

  final String titulo;
  final String descricao;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: CoresRadar.de(context).borda,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              titulo,
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              descricao,
              style: tema.textTheme.bodySmall?.copyWith(
                color: CoresRadar.de(context).textoSuave,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

/// Controle único de aparência usado no cabeçalho e na gaveta mobile.
class ControleAparenciaRadar extends StatelessWidget {
  const ControleAparenciaRadar.icone({super.key, this.cor}) : emLinha = false;

  const ControleAparenciaRadar.linha({super.key, this.cor}) : emLinha = true;

  final bool emLinha;
  final Color? cor;

  Future<void> _alternar(BuildContext context) async {
    final controlador = AparenciaRadar.talvezDe(context);
    if (controlador == null) return;
    final salvo = await controlador.alternar(Theme.of(context).brightness);
    if (!context.mounted || salvo) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(
        content: Text(
          'Tema alterado nesta sessão, mas não foi possível salvar a escolha.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    final controlador = AparenciaRadar.talvezDe(context);
    final rotulo = escuro ? 'Ativar tema claro' : 'Ativar tema escuro';
    final icone = escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined;

    if (!emLinha) {
      return IconButton(
        key: const Key('alternar-tema-cabecalho'),
        tooltip: rotulo,
        onPressed: controlador == null ? null : () => _alternar(context),
        color: cor,
        icon: Icon(icone),
      );
    }

    return Semantics(
      key: const Key('alternar-tema-gaveta'),
      button: true,
      toggled: escuro,
      label: rotulo,
      child: ListTile(
        textColor: cor,
        iconColor: cor,
        leading: Icon(icone),
        title: const Text('Aparência'),
        subtitle: Text(escuro ? 'Tema escuro' : 'Tema claro'),
        trailing: Switch(
          value: escuro,
          onChanged: controlador == null ? null : (_) => _alternar(context),
        ),
        onTap: controlador == null ? null : () => _alternar(context),
      ),
    );
  }
}
