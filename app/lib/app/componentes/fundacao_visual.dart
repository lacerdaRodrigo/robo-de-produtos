import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../tema/aparencia.dart';
import '../tema/tokens.dart';

enum TomRadar { neutro, acao, ganho, atencao, perigo }

/// Mensagem padrão de confirmação/erro usada pelas ações do aplicativo.
/// Mantém o mesmo cartão flutuante e contraste nos temas claro e escuro;
/// cada tela só precisa fornecer o texto.
void mostrarMensagemRadar(
  BuildContext context,
  String mensagem, {
  bool sucesso = true,
}) {
  final cores = CoresRadar.de(context);
  final cor = sucesso ? cores.ganho : cores.perigo;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).cardColor,
        elevation: 8,
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
            const SizedBox(width: 10),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sobrelinha != null) ...[
          Text(
            sobrelinha!.toUpperCase(),
            style: tema.textTheme.labelSmall?.copyWith(
              color: tema.brightness == Brightness.dark
                  ? Tokens.acaoForteEscura
                  : Tokens.actionStrong,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
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
            if (acao != null) ...[const SizedBox(width: 12), acao!],
          ],
        ),
        const SizedBox(height: 7),
        Text(
          descricao,
          style: tema.textTheme.bodyMedium?.copyWith(
            color: cores.textoSuave,
            fontSize: 13,
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
    final forma = RoundedRectangleBorder(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
        bottomRight: Radius.circular(22),
        bottomLeft: Radius.circular(8),
      ),
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
/// Por padrão, reproduz o `SearchBox` da V11 com ação coral de avanço. Use
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
    final brilho = Theme.of(context).brightness;
    final sufixo = acao != null
        ? Padding(
            padding: const EdgeInsets.all(6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cores.superficieAlternativa,
                borderRadius: BorderRadius.circular(11),
              ),
              child: acao,
            ),
          )
        : somenteBusca
        ? null
        : Padding(
            padding: const EdgeInsets.all(6),
            child: IconButton(
              tooltip: 'Pesquisar',
              onPressed: aoAcionar ?? () => aoMudar(controlador.text),
              icon: const Icon(Icons.chevron_right_rounded, size: 24),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
              style: IconButton.styleFrom(
                backgroundColor: cores.acao,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
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
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: dica,
          prefixIcon: const Icon(Icons.search, size: 22),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 47,
            minHeight: 52,
          ),
          suffixIcon: sufixo,
          suffixIconConstraints: sufixo == null
              ? null
              : const BoxConstraints(minWidth: 50, minHeight: 52),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          constraints: const BoxConstraints(minHeight: 52),
          contentPadding: const EdgeInsets.only(right: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(color: cores.borda),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(color: cores.borda),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
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
  final List<int>? contadores;
  final bool expandir;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        border: Border.all(color: cores.borda),
        borderRadius: BorderRadius.circular(18),
      ),
      child: expandir
          ? Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  for (var indice = 0; indice < rotulos.length; indice++) ...[
                    if (indice > 0) const SizedBox(width: 4),
                    Expanded(child: _construirAba(indice)),
                  ],
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(4),
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var indice = 0; indice < rotulos.length; indice++) ...[
                    if (indice > 0) const SizedBox(width: 4),
                    _construirAba(indice),
                  ],
                  if (acao != null) ...[
                    if (rotulos.isNotEmpty) const SizedBox(width: 4),
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
    return Material(
      color: selecionada ? cores.marca : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: aoTocar,
        child: Semantics(
          selected: selecionada,
          button: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: larguraFlexivel ? 7 : 12,
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
                                  ? Theme.of(context).colorScheme.onSecondary
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
                        color: selecionada
                            ? Theme.of(context).colorScheme.onSecondary
                            : cores.textoSuave,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (contador != null) ...[
                    SizedBox(width: larguraFlexivel ? 4 : 7),
                    Container(
                      constraints: const BoxConstraints(minWidth: 21),
                      height: 21,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: larguraFlexivel ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: selecionada
                            ? Theme.of(
                                context,
                              ).colorScheme.onSecondary.withValues(alpha: 0.16)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$contador',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selecionada
                              ? Theme.of(context).colorScheme.onSecondary
                              : cores.textoSuave,
                          fontSize: 9,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 21),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: CoresRadar.de(context).borda,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 17),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 42),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 42,
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
                          style: tema.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          descricao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: CoresRadar.de(context).textoSuave,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 11),
                  IconButton(
                    key: const Key('fechar-folha-radar'),
                    tooltip: 'Fechar painel',
                    onPressed: () => Navigator.maybePop(context),
                    style: IconButton.styleFrom(
                      minimumSize: const Size.square(42),
                      maximumSize: const Size.square(42),
                      padding: EdgeInsets.zero,
                      backgroundColor: CoresRadar.de(
                        context,
                      ).superficieAlternativa,
                      side: BorderSide(color: CoresRadar.de(context).borda),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Navegação paginada V11 para catálogos de cards.
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
                const SizedBox(width: 8),
              ],
              for (var indice = 0; indice < paginas.length; indice++) ...[
                if (paginas[indice] == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text('…'),
                  )
                else
                  _botaoPagina(context, paginas[indice]!, cores),
                if (indice != paginas.length - 1) const SizedBox(width: 8),
              ],
              if (pagina < totalPaginas) ...[
                const SizedBox(width: 8),
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
                const SizedBox(width: 10),
                const SizedBox(
                  width: 20,
                  height: 20,
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
    return Semantics(
      button: true,
      selected: ativa,
      label: 'Página $destino',
      child: SizedBox(
        width: 40,
        height: 40,
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
              borderRadius: BorderRadius.circular(13),
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
    width: 40,
    height: 40,
    child: IconButton(
      tooltip: tooltip,
      onPressed: carregando ? null : aoTocar,
      icon: Icon(icone),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(contexto).cardColor,
        foregroundColor: CoresRadar.de(contexto).textoSuave,
        side: BorderSide(color: CoresRadar.de(contexto).borda),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
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

/// Abre uma folha inferior mobile V11 com fundo bloqueado e desfocado.
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
    transitionDuration: const Duration(milliseconds: 240),
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
                  color: const Color(0x7A1B121B),
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
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(27),
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: cores.borda)),
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

    return Material(
      type: MaterialType.transparency,
      child: Semantics(
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
      ),
    );
  }
}
