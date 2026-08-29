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
    required this.podeAdministrar,
    required this.aoAlternar,
    required this.aoAlternarAlerta,
  });

  final ParceiroCatalogoLivelo parceiro;
  final bool pendente;
  final bool podeAdministrar;
  final VoidCallback aoAlternar;
  final VoidCallback aoAlternarAlerta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final clube = rotuloClube(parceiro.campanha);
    return Semantics(
      label: 'Parceiro Livelo ${parceiro.nome}',
      child: CartaoRadar(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Iniciais(nome: parceiro.nome),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              parceiro.nome,
                              style: tema.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            key: Key('alerta-${parceiro.idExterno}'),
                            tooltip: parceiro.alertaAtivo
                                ? 'Desativar alerta'
                                : 'Ativar alerta',
                            onPressed:
                                parceiro.acompanhada &&
                                    podeAdministrar &&
                                    !pendente
                                ? aoAlternarAlerta
                                : null,
                            icon: Icon(
                              parceiro.alertaAtivo
                                  ? Icons.notifications_active
                                  : Icons.notifications_none_outlined,
                              color: parceiro.alertaAtivo
                                  ? cores.acao
                                  : cores.textoSuave,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        parceiro.categorias.join(' · '),
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: cores.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                pontosLivelo(parceiro.pontosAtuais, moeda: parceiro.moeda),
                textAlign: TextAlign.end,
                style: tema.textTheme.titleSmall?.copyWith(
                  color: cores.acao,
                  fontWeight: FontWeight.w900,
                ),
              ),
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
            SizedBox(
              width: double.infinity,
              child: parceiro.acompanhada
                  ? OutlinedButton.icon(
                      key: Key('acompanhar-${parceiro.idExterno}'),
                      onPressed: podeAdministrar && !pendente
                          ? aoAlternar
                          : null,
                      icon: pendente
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(pendente ? 'Salvando…' : 'Acompanhar'),
                    ),
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
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CoresRadar.de(context).superficieAlternativa,
        borderRadius: BorderRadius.circular(14),
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
      child: Text(texto, style: TextStyle(color: cor, fontSize: 12)),
    );
  }
}
