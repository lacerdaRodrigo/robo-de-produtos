import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';
import 'formato_livelo.dart';

class CartaoCatalogoLivelo extends StatelessWidget {
  const CartaoCatalogoLivelo({
    super.key,
    required this.parceiro,
    required this.pendente,
    this.alertaPendente = false,
    required this.podeAdministrar,
    required this.aoAlternar,
    required this.aoAlternarAlerta,
    required this.aoHistorico,
  });

  final ParceiroCatalogoLivelo parceiro;
  final bool pendente;
  final bool alertaPendente;
  final bool podeAdministrar;
  final VoidCallback aoAlternar;
  final VoidCallback aoAlternarAlerta;
  final VoidCallback aoHistorico;

  @override
  Widget build(BuildContext context) {
    final clube = rotuloClube(parceiro.campanha);
    return Semantics(
      label: 'Parceiro Livelo ${parceiro.nome}',
      child: CartaoRadar(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopoCartao(
              parceiro: parceiro,
              alertaPendente: alertaPendente,
              podeAdministrar: podeAdministrar,
              aoAlternarAlerta: aoAlternarAlerta,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                if (parceiro.pontosBase != null)
                  _Selo(
                    texto:
                        'Normal ${pontosLivelo(parceiro.pontosBase, moeda: parceiro.moeda)}',
                  ),
                if (parceiro.pontosClube != null)
                  _Selo(
                    texto:
                        'Clube ${pontosLivelo(parceiro.pontosClube, moeda: parceiro.moeda)}',
                    tom: TomRadar.acao,
                  ),
                if (parceiro.emPromocao)
                  const _Selo(texto: 'Promoção', tom: TomRadar.ganho),
                if (clube != null) _Selo(texto: clube, tom: TomRadar.acao),
                if (parceiro.alerta)
                  const _Selo(texto: 'Alerta ativo', tom: TomRadar.perigo),
              ],
            ),
            if (parceiro.fimPromocao != null) ...[
              const SizedBox(height: 10),
              IndicadorEstadoRadar(
                texto: validadeLivelo(parceiro.fimPromocao),
                tom: TomRadar.atencao,
              ),
            ],
            if (parceiro.descricaoCampanha != null &&
                parceiro.descricaoCampanha!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _DescricaoCampanha(
                texto: parceiro.descricaoCampanha!,
                link: parceiro.link,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton(
                  key: Key('historico-${parceiro.idExterno}'),
                  onPressed: aoHistorico,
                  child: const Text('Histórico'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: parceiro.acompanhada
                      ? OutlinedButton.icon(
                          key: Key('acompanhar-${parceiro.idExterno}'),
                          onPressed: podeAdministrar && !pendente
                              ? aoAlternar
                              : null,
                          icon: pendente
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(pendente ? 'Salvando…' : 'Acompanhando'),
                        )
                      : FilledButton.tonalIcon(
                          key: Key('acompanhar-${parceiro.idExterno}'),
                          onPressed: podeAdministrar && !pendente
                              ? aoAlternar
                              : null,
                          icon: pendente
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(pendente ? 'Salvando…' : 'Acompanhar'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DescricaoCampanha extends StatefulWidget {
  const _DescricaoCampanha({required this.texto, this.link});
  final String texto;
  final String? link;

  @override
  State<_DescricaoCampanha> createState() => _DescricaoCampanhaState();
}

class _TopoCartao extends StatelessWidget {
  const _TopoCartao({
    required this.parceiro,
    required this.alertaPendente,
    required this.podeAdministrar,
    required this.aoAlternarAlerta,
  });

  final ParceiroCatalogoLivelo parceiro;
  final bool alertaPendente;
  final bool podeAdministrar;
  final VoidCallback aoAlternarAlerta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final beneficio = Text(
      pontosLivelo(parceiro.pontosAtuais, moeda: parceiro.moeda),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: tema.textTheme.labelMedium?.copyWith(
        color: cores.ganho,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
    final alerta = IconButton(
      key: Key('alerta-${parceiro.idExterno}'),
      tooltip: parceiro.alertaAtivo ? 'Desativar alerta' : 'Ativar alerta',
      onPressed: parceiro.acompanhada && podeAdministrar && !alertaPendente
          ? aoAlternarAlerta
          : null,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(34),
        maximumSize: const Size.square(34),
        padding: EdgeInsets.zero,
        side: BorderSide(color: cores.borda),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      icon: alertaPendente
          ? const SizedBox.square(
              dimension: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              parceiro.alertaAtivo
                  ? Icons.notifications_active
                  : Icons.notifications_none_outlined,
              size: 18,
              color: parceiro.alertaAtivo ? cores.acao : cores.textoSuave,
            ),
    );
    final nome = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parceiro.nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.titleSmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            parceiro.categorias.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.labelSmall?.copyWith(
              color: cores.textoSuave,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, limites) {
        final estreito =
            limites.maxWidth < 270 ||
            MediaQuery.textScalerOf(context).scale(12) > 15;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Iniciais(nome: parceiro.nome),
                const SizedBox(width: 9),
                nome,
                if (!estreito) ...[
                  const SizedBox(width: 7),
                  SizedBox(width: 76, child: beneficio),
                ],
                const SizedBox(width: 7),
                alerta,
              ],
            ),
            if (estreito) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: beneficio),
            ],
          ],
        );
      },
    );
  }
}

class _DescricaoCampanhaState extends State<_DescricaoCampanha> {
  bool _aberta = false;

  Future<void> _abrirLink() async {
    final uri = Uri.tryParse(widget.link ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Condições da campanha',
            style: tema.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.texto,
            maxLines: _aberta ? null : 3,
            overflow: _aberta ? null : TextOverflow.ellipsis,
            style: tema.textTheme.bodySmall?.copyWith(
              color: cores.textoSuave,
              height: 1.35,
            ),
          ),
          if (widget.texto.length > 180)
            TextButton(
              onPressed: () => setState(() => _aberta = !_aberta),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(_aberta ? 'Ver menos' : 'Ver mais'),
            ),
          if (_linkHttpsValido(widget.link))
            TextButton.icon(
              onPressed: _abrirLink,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Ver regras completas no site da Livelo'),
            ),
        ],
      ),
    );
  }
}

bool _linkHttpsValido(String? link) {
  final uri = Uri.tryParse(link ?? '');
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

class _Iniciais extends StatelessWidget {
  const _Iniciais({required this.nome});
  final String nome;

  @override
  Widget build(BuildContext context) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.isNotEmpty);
    final iniciais = partes
        .take(2)
        .map((item) => item.substring(0, 1))
        .join()
        .toUpperCase();
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Theme.of(context).brightness == Brightness.dark
                ? Tokens.acaoFundoEscuro
                : Tokens.acaoFundo,
            Theme.of(context).brightness == Brightness.dark
                ? Tokens.cianoFundoEscuro
                : Tokens.cianoFundo,
          ],
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        iniciais.isEmpty ? '•' : iniciais,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: CoresRadar.de(context).acao,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo({required this.texto, this.tom = TomRadar.neutro});
  final String texto;
  final TomRadar tom;

  @override
  Widget build(BuildContext context) {
    final cor = switch (tom) {
      TomRadar.acao => CoresRadar.de(context).acao,
      TomRadar.ganho => CoresRadar.de(context).ganho,
      TomRadar.atencao => CoresRadar.de(context).atencao,
      TomRadar.perigo => CoresRadar.de(context).perigo,
      TomRadar.neutro => CoresRadar.de(context).textoSuave,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 9)),
    );
  }
}
