import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tema/aparencia.dart';
import '../tema/tokens.dart';

enum TomRadar { neutro, acao, ganho, atencao, perigo }

/// Marca compacta oficial da V15, usada nos cabeçalhos de raiz e de catálogo.
class CabecalhoMarcaRadar extends StatelessWidget {
  const CabecalhoMarcaRadar({super.key, this.rotulo, this.acao});

  final String? rotulo;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tokens = context.tokens;
    final escuro = tema.brightness == Brightness.dark;
    final marca = escuro
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/brand/symbol-dark.svg',
                width: tokens.sizes.brandHeight,
                height: tokens.sizes.brandHeight,
                semanticsLabel: 'Radar',
              ),
              SizedBox(width: tokens.spacing.two),
              Flexible(
                child: Text(
                  'radar.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ],
          )
        : SvgPicture.asset(
            'assets/brand/wordmark.svg',
            width: tokens.sizes.brandWidth,
            height: tokens.sizes.brandHeight,
            semanticsLabel: 'Radar',
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: marca,
          ),
        ),
        if (rotulo != null)
          Text(
            rotulo!,
            style: tema.textTheme.labelLarge?.copyWith(
              color: CoresRadar.de(context).textoSuave,
              fontWeight: FontWeight.w700,
            ),
          ),
        if (acao != null) ...[SizedBox(width: tokens.spacing.two), acao!],
      ],
    );
  }
}

/// Mensagem padrão de confirmação/erro usada pelas ações do aplicativo.
/// Mantém o mesmo cartão flutuante e contraste nos temas claro e escuro;
/// cada tela só precisa fornecer o texto.
void mostrarMensagemRadar(
  BuildContext context,
  String mensagem, {
  bool sucesso = true,
}) {
  final cores = CoresRadar.de(context);
  final tokens = context.tokens;
  final cor = sucesso ? cores.ganho : cores.perigo;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: cor.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Icon(
              sucesso ? Icons.check_circle_outline : Icons.error_outline,
              color: cor,
            ),
            SizedBox(width: tokens.spacing.three),
            Expanded(
              child: Text(
                mensagem,
                style: TextStyle(color: cor, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
}

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
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sobrelinha != null) ...[
          Text(
            sobrelinha!.toUpperCase(),
            style: tema.textTheme.labelSmall?.copyWith(
              color: cores.acao,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: tokens.spacing.two),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                titulo,
                style: tema.textTheme.headlineMedium?.copyWith(
                  fontSize: (MediaQuery.sizeOf(context).width * 0.08).clamp(
                    30.0,
                    32.0,
                  ),
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -1.1,
                ),
              ),
            ),
            if (acao != null) ...[SizedBox(width: tokens.spacing.three), acao!],
          ],
        ),
        SizedBox(height: tokens.spacing.two),
        Text(
          descricao,
          style: tema.textTheme.bodyMedium?.copyWith(
            color: cores.textoSuave,
            fontSize: 14,
            height: 1.5,
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
    this.corDestaque,
  });

  final Widget child;
  final VoidCallback? aoTocar;
  final EdgeInsetsGeometry padding;
  final Color? corDestaque;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(tokens.radii.lg),
      side: BorderSide(color: cores.borda),
    );
    final conteudo = corDestaque == null
        ? Padding(padding: padding, child: child)
        : Stack(
            children: [
              Positioned(
                left: 0,
                top: 18,
                bottom: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: corDestaque,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(RaioRadar.pilula),
                    ),
                  ),
                  child: const SizedBox(width: 4),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: forma.borderRadius,
        boxShadow: <BoxShadow>[SombraRadar.para(tema.brightness)],
      ),
      child: Material(
        color: tema.cardColor,
        shape: forma,
        clipBehavior: Clip.antiAlias,
        child: aoTocar == null
            ? conteudo
            : InkWell(onTap: aoTocar, child: conteudo),
      ),
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
///
/// Por padrão, reproduz o campo de busca V15 com ação de avanço. Use
/// [somenteBusca] nos catálogos que filtram enquanto a pessoa digita e não
/// possuem uma ação separada no campo.
class CampoBuscaRadar extends StatelessWidget {
  const CampoBuscaRadar({
    super.key,
    required this.controlador,
    required this.dica,
    required this.aoMudar,
    this.acao,
    this.aoAcionar,
    this.somenteBusca = false,
    this.chaveCampo,
  });

  final TextEditingController controlador;
  final String dica;
  final ValueChanged<String> aoMudar;
  final Widget? acao;

  /// Ação opcional do botão de avanço e do envio pelo teclado.
  final VoidCallback? aoAcionar;

  /// Remove o botão de avanço, mantendo o campo no formato `search-only`.
  final bool somenteBusca;
  final Key? chaveCampo;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final brilho = Theme.of(context).brightness;
    final sufixo = acao != null
        ? Padding(
            padding: EdgeInsets.all(tokens.spacing.one),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cores.superficieAlternativa,
                borderRadius: BorderRadius.circular(tokens.radii.md),
              ),
              child: acao,
            ),
          )
        : somenteBusca
        ? null
        : Padding(
            padding: EdgeInsets.all(tokens.spacing.one),
            child: IconButton(
              tooltip: 'Pesquisar',
              onPressed: aoAcionar ?? () => aoMudar(controlador.text),
              icon: const Icon(Icons.chevron_right_rounded, size: 24),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: tokens.sizes.touchTarget,
                height: tokens.sizes.touchTarget,
              ),
              style: IconButton.styleFrom(
                backgroundColor: cores.acao,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(tokens.radii.md),
                ),
              ),
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radii.lg),
        boxShadow: [SombraRadar.para(brilho)],
      ),
      child: TextField(
        key: chaveCampo,
        controller: controlador,
        onChanged: aoMudar,
        onSubmitted: acao == null && !somenteBusca
            ? (_) {
                if (aoAcionar != null) {
                  aoAcionar!();
                } else {
                  aoMudar(controlador.text);
                }
              }
            : null,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: dica,
          prefixIcon: const Icon(Icons.search, size: 22),
          prefixIconConstraints: BoxConstraints(
            minWidth: tokens.sizes.field,
            minHeight: tokens.sizes.field,
          ),
          suffixIcon: sufixo,
          suffixIconConstraints: sufixo == null
              ? null
              : BoxConstraints(
                  minWidth: tokens.sizes.field,
                  minHeight: tokens.sizes.field,
                ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          constraints: BoxConstraints(minHeight: tokens.sizes.field),
          contentPadding: EdgeInsetsDirectional.only(end: tokens.spacing.two),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radii.lg),
            borderSide: BorderSide(color: cores.borda),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radii.lg),
            borderSide: BorderSide(color: cores.borda),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radii.lg),
            borderSide: BorderSide(color: cores.acao, width: 1.5),
          ),
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
    this.acao,
    this.contadores,
    this.expandir = false,
  }) : assert(contadores == null || contadores.length == rotulos.length);

  final List<String> rotulos;
  final int selecionada;
  final ValueChanged<int> aoSelecionar;
  final Widget? acao;
  final List<int?>? contadores;
  final bool expandir;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        border: Border.all(color: cores.borda),
        borderRadius: BorderRadius.circular(tokens.radii.lg),
      ),
      child: expandir
          ? Padding(
              padding: EdgeInsets.all(tokens.spacing.one),
              child: Row(
                children: [
                  for (var indice = 0; indice < rotulos.length; indice++) ...[
                    if (indice > 0) SizedBox(width: tokens.spacing.one),
                    Expanded(child: _construirAba(indice)),
                  ],
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(tokens.spacing.one),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var indice = 0; indice < rotulos.length; indice++) ...[
                    if (indice > 0) SizedBox(width: tokens.spacing.one),
                    _construirAba(indice),
                  ],
                  if (acao != null) ...[
                    if (rotulos.isNotEmpty) SizedBox(width: tokens.spacing.one),
                    acao!,
                  ],
                ],
              ),
            ),
    );
  }

  Widget _construirAba(int indice) => _AbaRadar(
    key: Key('aba-radar-$indice'),
    rotulo: rotulos[indice],
    contador: contadores?[indice],
    larguraFlexivel: expandir,
    selecionada: indice == selecionada,
    aoTocar: () => aoSelecionar(indice),
  );
}

class _AbaRadar extends StatelessWidget {
  const _AbaRadar({
    super.key,
    required this.rotulo,
    this.contador,
    this.larguraFlexivel = false,
    required this.selecionada,
    required this.aoTocar,
  });

  final String rotulo;
  final int? contador;
  final bool larguraFlexivel;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return Material(
      color: selecionada ? cores.superficie : Colors.transparent,
      borderRadius: BorderRadius.circular(tokens.radii.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radii.md),
        onTap: aoTocar,
        child: Semantics(
          selected: selecionada,
          button: true,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: tokens.sizes.touchTarget),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: larguraFlexivel
                    ? tokens.spacing.two
                    : tokens.spacing.three,
              ),
              child: Row(
                mainAxisSize: larguraFlexivel
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (larguraFlexivel)
                    Expanded(
                      child: Text(
                        rotulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: selecionada
                                  ? cores.texto
                                  : cores.textoSuave,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    )
                  else
                    Text(
                      rotulo,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: selecionada ? cores.texto : cores.textoSuave,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (contador != null) ...[
                    SizedBox(
                      width: larguraFlexivel
                          ? tokens.spacing.one
                          : tokens.spacing.two,
                    ),
                    Container(
                      constraints: BoxConstraints(
                        minWidth: tokens.spacing.four,
                      ),
                      height: tokens.spacing.four,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: larguraFlexivel ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: selecionada
                            ? cores.teal.withValues(alpha: 0.14)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(tokens.radii.pill),
                      ),
                      child: Text(
                        '$contador',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selecionada ? cores.texto : cores.textoSuave,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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
    this.mostrarVoltar = true,
    this.aoVoltar,
  });

  final String titulo;
  final String descricao;
  final Widget child;
  final bool mostrarVoltar;
  final VoidCallback? aoVoltar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.spacing.four,
          tokens.spacing.two,
          tokens.spacing.four,
          tokens.spacing.five,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: tokens.sizes.sheetHandleWidth,
                height: tokens.sizes.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: cores.borda,
                  borderRadius: BorderRadius.circular(tokens.radii.pill),
                ),
              ),
            ),
            SizedBox(height: tokens.spacing.four),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: tokens.sizes.touchTarget),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: tokens.sizes.touchTarget,
                    child: mostrarVoltar
                        ? IconButton(
                            key: const Key('voltar-folha-radar'),
                            tooltip: 'Voltar',
                            onPressed:
                                aoVoltar ?? () => Navigator.maybePop(context),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: tema.textTheme.titleLarge,
                        ),
                        SizedBox(height: tokens.spacing.one),
                        Text(
                          descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: CoresRadar.de(context).textoSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: tokens.spacing.three),
                  IconButton(
                    key: const Key('fechar-folha-radar'),
                    tooltip: 'Fechar painel',
                    onPressed: () => Navigator.maybePop(context),
                    style: IconButton.styleFrom(
                      minimumSize: Size.square(tokens.sizes.touchTarget),
                      maximumSize: Size.square(tokens.sizes.touchTarget),
                      padding: EdgeInsets.zero,
                      backgroundColor: CoresRadar.de(
                        context,
                      ).superficieAlternativa,
                      side: BorderSide(color: CoresRadar.de(context).borda),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(tokens.radii.md),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.spacing.three),
            child,
          ],
        ),
      ),
    );
  }
}

/// Navegação paginada V15 para catálogos de cards.
///
/// Os controles só aparecem quando há mais itens do que a página comporta;
/// portanto, 9 ou 10 resultados não exibem uma paginação vazia.
class PaginacaoRadar extends StatelessWidget {
  const PaginacaoRadar({
    super.key,
    required this.pagina,
    required this.totalItens,
    required this.porPagina,
    required this.carregando,
    required this.aoIrParaPagina,
    this.erro,
  });

  final int pagina;
  final int totalItens;
  final int porPagina;
  final bool carregando;
  final Future<void> Function(int pagina) aoIrParaPagina;
  final Object? erro;

  int get _totalPaginas {
    final tamanhoPagina = porPagina <= 0 ? 1 : porPagina;
    return (totalItens + tamanhoPagina - 1) ~/ tamanhoPagina;
  }

  @override
  Widget build(BuildContext context) {
    if (totalItens <= porPagina) return const SizedBox.shrink();
    final cores = CoresRadar.de(context);
    final tokens = context.tokens;
    final totalPaginas = _totalPaginas;
    final paginas = _paginasVisiveis(totalPaginas);
    final proxima = pagina < totalPaginas ? pagina + 1 : pagina;

    return Semantics(
      label: 'Paginação, página $pagina de $totalPaginas',
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pagina > 1) ...[
                _botaoIcone(
                  contexto: context,
                  tooltip: 'Página anterior',
                  icone: Icons.chevron_left_rounded,
                  aoTocar: () => aoIrParaPagina(pagina - 1),
                ),
                SizedBox(width: tokens.spacing.two),
              ],
              for (var indice = 0; indice < paginas.length; indice++) ...[
                if (paginas[indice] == null)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.one / 2,
                    ),
                    child: Text('…'),
                  )
                else
                  _botaoPagina(context, paginas[indice]!, cores),
                if (indice != paginas.length - 1)
                  SizedBox(width: tokens.spacing.two),
              ],
              if (pagina < totalPaginas) ...[
                SizedBox(width: tokens.spacing.two),
                _botaoIcone(
                  contexto: context,
                  tooltip: erro == null
                      ? 'Próxima página'
                      : 'Tentar próxima página',
                  icone: erro == null
                      ? Icons.chevron_right_rounded
                      : Icons.refresh_rounded,
                  aoTocar: () => aoIrParaPagina(proxima),
                ),
              ],
              if (carregando) ...[
                SizedBox(width: tokens.spacing.three),
                SizedBox(
                  width: tokens.spacing.four,
                  height: tokens.spacing.four,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<int?> _paginasVisiveis(int totalPaginas) {
    if (totalPaginas <= 7) {
      return List<int?>.generate(totalPaginas, (indice) => indice + 1);
    }

    final candidatas = <int>{1, 2, 3, totalPaginas};
    for (var numero = pagina - 1; numero <= pagina + 1; numero++) {
      if (numero > 0 && numero <= totalPaginas) candidatas.add(numero);
    }
    final ordenadas = candidatas.toList()..sort();
    final resultado = <int?>[];
    for (final numero in ordenadas) {
      int? anterior;
      for (final item in resultado.reversed) {
        if (item != null) {
          anterior = item;
          break;
        }
      }
      if (anterior != null && numero - anterior > 1) resultado.add(null);
      resultado.add(numero);
    }
    return resultado;
  }

  Widget _botaoPagina(BuildContext context, int destino, CoresRadar cores) {
    final ativa = destino == pagina;
    final tokens = context.tokens;
    return Semantics(
      button: true,
      selected: ativa,
      label: 'Página $destino',
      child: SizedBox(
        width: tokens.sizes.touchTarget,
        height: tokens.sizes.touchTarget,
        child: TextButton(
          key: Key('paginacao-radar-$destino'),
          onPressed: ativa || carregando ? null : () => aoIrParaPagina(destino),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: ativa
                ? Theme.of(context).colorScheme.onSecondary
                : cores.textoSuave,
            disabledForegroundColor: ativa
                ? Theme.of(context).colorScheme.onSecondary
                : cores.textoSuave,
            backgroundColor: ativa ? cores.marca : Theme.of(context).cardColor,
            side: BorderSide(color: ativa ? cores.marca : cores.borda),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radii.md),
            ),
          ),
          child: Text(
            '$destino',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  Widget _botaoIcone({
    required BuildContext contexto,
    required String tooltip,
    required IconData icone,
    required VoidCallback aoTocar,
  }) => SizedBox(
    width: contexto.tokens.sizes.touchTarget,
    height: contexto.tokens.sizes.touchTarget,
    child: IconButton(
      tooltip: tooltip,
      onPressed: carregando ? null : aoTocar,
      icon: Icon(icone),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(contexto).cardColor,
        foregroundColor: CoresRadar.de(contexto).textoSuave,
        side: BorderSide(color: CoresRadar.de(contexto).borda),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(contexto.tokens.radii.md),
        ),
      ),
    ),
  );
}

/// Retorna suavemente ao início depois que uma página de cards foi trocada.
Future<void> rolarParaInicioPaginaRadar(ScrollController rolagem) async {
  if (!rolagem.hasClients) return;
  await rolagem.animateTo(
    0,
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeInOutCubic,
  );
}

/// Abre uma folha inferior mobile V15 com fundo bloqueado e desfocado.
///
/// O conteúdo deve usar [FolhaRadar] para compartilhar o cabeçalho, o
/// puxador, a tipografia e as ações. O retorno tem a mesma semântica de um
/// `showModalBottomSheet`, mantendo filtros e seleções intactos.
Future<T?> mostrarFolhaRadar<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double alturaMaxima = 0.82,
}) {
  final localizations = MaterialLocalizations.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: localizations.modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: AppTokens.de(context).motion.forReducedMotion(
      AppTokens.de(context).motion.standard,
      MediaQuery.disableAnimationsOf(context),
    ),
    pageBuilder: (context, _, _) {
      final cores = CoresRadar.de(context);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: ColoredBox(
                  color: CoresRadar.de(context).marca.withValues(alpha: 0.72),
                  child: Semantics(
                    label: localizations.modalBarrierDismissLabel,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 430,
                  maxHeight: MediaQuery.sizeOf(context).height * alturaMaxima,
                ),
                child: Material(
                  key: const Key('folha-radar-modal'),
                  color: Theme.of(context).cardColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: 20,
                  shadowColor: Colors.black.withValues(alpha: 0.22),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTokens.de(context).radii.xl),
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: cores.acao, width: 3),
                      ),
                    ),
                    child: builder(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final entrada = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: entrada,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(entrada),
          child: child,
        ),
      );
    },
  );
}

/// Controle único de aparência usado no cabeçalho e no perfil mobile.
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

    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        key: const Key('alternar-tema-conta'),
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
      ),
    );
  }
}
