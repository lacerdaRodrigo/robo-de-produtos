import 'package:flutter/material.dart';

import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';
import 'formato_livelo.dart';

class CartaoLivelo extends StatelessWidget {
  const CartaoLivelo({super.key, required this.loja});

  final PontuacaoLivelo loja;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final clube = rotuloClube(loja.campanha);
    final pontosAtuais = loja.pontosAtuais;
    final tituloAtual = pontosAtuais == null
        ? 'Não encontrada na última coleta'
        : pontosLivelo(pontosAtuais, moeda: loja.moeda);

    return Semantics(
      label: 'Loja ${loja.nome}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loja.nome, style: tema.textTheme.titleMedium),
                        if (loja.categoria != null)
                          Text(
                            loja.categoria!,
                            style: tema.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (loja.alertou) const _SeloAlerta(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                tituloAtual,
                style: tema.textTheme.titleLarge?.copyWith(
                  color: pontosAtuais == null ? Tokens.atencao : Tokens.marca,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pontosAtuais == null) ...[
                const SizedBox(height: 4),
                const Text(
                  'A loja continua cadastrada; a fonte não a retornou.',
                ),
              ] else ...[
                const SizedBox(height: 12),
                _LinhaDeDetalhe(
                  rotulo: 'Pontuação normal',
                  valor: pontosLivelo(loja.pontosBase, moeda: loja.moeda),
                ),
                _LinhaDeDetalhe(
                  rotulo: 'Alerta a partir de',
                  valor: pontosLivelo(loja.valorDeDisparo, moeda: loja.moeda),
                ),
                if (loja.pontosClube != null)
                  _LinhaDeDetalhe(
                    rotulo: 'Clube Livelo',
                    valor: pontosLivelo(loja.pontosClube, moeda: loja.moeda),
                  ),
              ],
              if (loja.prefixoAte ||
                  loja.emPromocao ||
                  clube != null ||
                  loja.fimPromocao != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (loja.prefixoAte)
                        const _Selo(texto: 'Até', cor: Tokens.marcaClara),
                      if (loja.emPromocao)
                        const _Selo(texto: 'Promoção', cor: Tokens.ganho),
                      if (clube != null)
                        _Selo(texto: clube, cor: Tokens.marcaClara),
                      if (loja.fimPromocao != null)
                        _Selo(
                          texto: validadeLivelo(loja.fimPromocao),
                          cor: Tokens.atencao,
                        ),
                    ],
                  ),
                ),
              if (loja.descricaoCampanha != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text('Condições da campanha'),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(loja.descricaoCampanha!),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaDeDetalhe extends StatelessWidget {
  const _LinhaDeDetalhe({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text('$rotulo: $valor'),
    );
  }
}

class _SeloAlerta extends StatelessWidget {
  const _SeloAlerta();

  @override
  Widget build(BuildContext context) {
    return const _Selo(texto: 'Alerta ativo', cor: Tokens.perigo);
  }
}

class _Selo extends StatelessWidget {
  const _Selo({required this.texto, required this.cor});

  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 12)),
    );
  }
}
