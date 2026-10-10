import 'package:flutter/material.dart';

import '../fundacao/ds_medidas.dart';
import '../fundacao/ds_tema.dart';
import 'ds_basicos.dart';

/// Cabeçalho de tela. O voltar aparece sozinho quando a rota foi empilhada
/// e usa o mesmo `maybePop` do gesto/botão do Android.
class DsCabecalho extends StatelessWidget {
  const DsCabecalho({
    super.key,
    required this.titulo,
    this.kicker,
    this.acoes = const <Widget>[],
    this.mostrarVoltar,
  });

  final String titulo;
  final String? kicker;
  final List<Widget> acoes;

  /// `null` = automático (`Navigator.canPop`).
  final bool? mostrarVoltar;

  @override
  Widget build(BuildContext context) {
    final t = context.tipo;
    final voltar = mostrarVoltar ?? Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsEspaco.margemTela,
        vertical: DsEspaco.e2,
      ),
      child: Row(
        children: [
          if (voltar) ...[
            DsBotaoIcone(
              icone: Icons.arrow_back_rounded,
              rotulo: 'Voltar',
              aoTocar: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: DsEspaco.e3),
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kicker != null)
                    Text(kicker!.toUpperCase(), style: t.kicker),
                  Text(titulo, style: t.tituloTela),
                ],
              ),
            ),
          ),
          for (final acao in acoes) ...[
            const SizedBox(width: DsEspaco.e2),
            acao,
          ],
        ],
      ),
    );
  }
}

/// Os quatro destinos fixos do app.
enum DsDestino { inicio, explorar, meuRadar, perfil }

class DsBarraNavegacao extends StatelessWidget {
  const DsBarraNavegacao({
    super.key,
    required this.destinoAtual,
    required this.aoMudar,
    this.novidadeNoRadar = false,
  });

  final DsDestino destinoAtual;
  final ValueChanged<DsDestino> aoMudar;
  final bool novidadeNoRadar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    Widget comPonto(Widget icone) => Badge(
      isLabelVisible: novidadeNoRadar,
      backgroundColor: c.sinal,
      smallSize: 8,
      child: icone,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.borda1)),
      ),
      child: NavigationBar(
        selectedIndex: destinoAtual.index,
        onDestinationSelected: (i) => aoMudar(DsDestino.values[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explorar',
          ),
          NavigationDestination(
            icon: comPonto(const Icon(Icons.radar_outlined)),
            selectedIcon: comPonto(const Icon(Icons.radar_rounded)),
            label: 'Meu radar',
            tooltip: novidadeNoRadar ? 'Meu radar, tem novidades' : null,
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

/// Paginação com setas circulares. `totalPaginas == null` quando a API só
/// informa `tem_proxima`.
class DsPaginacao extends StatelessWidget {
  const DsPaginacao({
    super.key,
    required this.pagina,
    required this.aoMudar,
    this.totalPaginas,
    this.temProxima,
  });

  final int pagina;
  final int? totalPaginas;
  final bool? temProxima;
  final ValueChanged<int> aoMudar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipo;
    final podeAvancar = totalPaginas != null
        ? pagina < totalPaginas!
        : (temProxima ?? false);
    final texto = totalPaginas != null
        ? '$pagina de $totalPaginas'
        : 'Página $pagina';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DsBotaoIcone(
          icone: Icons.chevron_left_rounded,
          rotulo: 'Página anterior',
          aoTocar: pagina > 1 ? () => aoMudar(pagina - 1) : null,
        ),
        const SizedBox(width: DsEspaco.e4),
        Semantics(
          liveRegion: true,
          child: Text(
            texto,
            style: t.rotulo.copyWith(color: c.texto2),
          ),
        ),
        const SizedBox(width: DsEspaco.e4),
        DsBotaoIcone(
          icone: Icons.chevron_right_rounded,
          rotulo: 'Próxima página',
          aoTocar: podeAvancar ? () => aoMudar(pagina + 1) : null,
        ),
      ],
    );
  }
}
