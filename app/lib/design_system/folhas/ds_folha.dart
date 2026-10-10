import 'package:flutter/material.dart';

import '../componentes/ds_basicos.dart';
import '../fundacao/ds_medidas.dart';
import '../fundacao/ds_tema.dart';

/// Base de TODA folha inferior do app.
///
/// Abre no navigator raiz (por cima da barra de navegação), sobe acima do
/// teclado, respeita a área segura e devolve o foco à origem ao fechar.
/// Nenhuma feature deve chamar `showModalBottomSheet` diretamente.
class DsFolha extends StatelessWidget {
  const DsFolha({
    super.key,
    required this.titulo,
    required this.corpo,
    this.subtitulo,
    this.rodape,
    this.mostrarVoltar = false,
    this.rolavel = true,
  });

  final String titulo;
  final String? subtitulo;
  final Widget corpo;

  /// Ações fixas no fim (Limpar / Aplicar).
  final Widget? rodape;
  final bool mostrarVoltar;

  /// `false` quando o corpo já rola sozinho (listas longas).
  final bool rolavel;

  /// Abre uma folha simples a partir de construtores de corpo e rodapé.
  static Future<T?> mostrar<T>(
    BuildContext context, {
    required String titulo,
    required WidgetBuilder corpo,
    String? subtitulo,
    WidgetBuilder? rodape,
    bool mostrarVoltar = false,
    bool rolavel = true,
  }) => abrir<T>(
    context,
    construir: (contexto) => DsFolha(
      titulo: titulo,
      subtitulo: subtitulo,
      mostrarVoltar: mostrarVoltar,
      rolavel: rolavel,
      rodape: rodape?.call(contexto),
      corpo: Builder(builder: corpo),
    ),
  );

  /// Abre uma folha cujo widget raiz (um [DsFolha] dentro de um
  /// StatefulWidget, por exemplo) é montado por [construir]. Use quando corpo
  /// e rodapé compartilham estado, como na `FolhaFiltros`.
  static Future<T?> abrir<T>(
    BuildContext context, {
    required WidgetBuilder construir,
  }) {
    final reduzido = context.movimentoReduzido;
    // A folha vive no navigator raiz; leva junto o tema de quem a abriu
    // (importa quando uma subárvore sobrescreve o tema, como na vitrine).
    final tema = Theme.of(context);
    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: AnimationStyle(
        duration: DsMovimento.de(DsMovimento.folhaEntrada, reduzido: reduzido),
        reverseDuration: DsMovimento.de(
          DsMovimento.folhaSaida,
          reduzido: reduzido,
        ),
      ),
      builder: (contexto) =>
          Theme(data: tema, child: Builder(builder: construir)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipo;
    final midia = MediaQuery.of(context);
    final alturaMaxima = (midia.size.height - midia.viewInsets.bottom) * 0.9;

    return Padding(
      padding: EdgeInsets.only(bottom: midia.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: alturaMaxima),
        child: Material(
          color: c.superficie1,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DsRaio.lg),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DsEspaco.e2),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.superficie3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DsEspaco.e2),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: DsEspaco.alvoToque,
                      child: mostrarVoltar
                          ? DsBotaoIcone(
                              icone: Icons.arrow_back_rounded,
                              rotulo: 'Voltar',
                              preenchido: false,
                              aoTocar: () => Navigator.of(context).maybePop(),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Column(
                          children: [
                            Text(
                              titulo,
                              style: t.tituloSecao,
                              textAlign: TextAlign.center,
                            ),
                            if (subtitulo != null)
                              Text(
                                subtitulo!,
                                style: t.apoio,
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    ),
                    DsBotaoIcone(
                      icone: Icons.close_rounded,
                      rotulo: 'Fechar',
                      preenchido: false,
                      aoTocar: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: rolavel
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          DsEspaco.e5,
                          DsEspaco.e3,
                          DsEspaco.e5,
                          DsEspaco.e5,
                        ),
                        child: corpo,
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(
                          DsEspaco.e5,
                          DsEspaco.e3,
                          DsEspaco.e5,
                          DsEspaco.e5,
                        ),
                        child: corpo,
                      ),
              ),
              if (rodape != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.borda1)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DsEspaco.e5,
                        DsEspaco.e3,
                        DsEspaco.e5,
                        DsEspaco.e4,
                      ),
                      child: rodape,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
