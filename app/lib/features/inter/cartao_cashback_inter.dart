import 'package:flutter/material.dart';

import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';

const _descricaoAusente =
    'O Inter não informou condições adicionais nesta consulta';

class CartaoCashbackInter extends StatelessWidget {
  const CartaoCashbackInter({super.key, required this.loja});

  final CashbackInter loja;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final oferta = loja.cashbackPrincipalTexto ?? 'Oferta não informada';
    return Semantics(
      label: 'Loja ${loja.nome}',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loja.nome, style: tema.textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(
                loja.encontrada ? oferta : 'Não encontrada na última coleta',
                style: tema.textTheme.titleLarge?.copyWith(
                  // Verde só comunica benefício. Loja ausente é um estado
                  // neutro, não atraso e tampouco cashback zero.
                  color: loja.encontrada ? Tokens.ganho : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text('Cliente Inter Shopping'),
              if (!loja.encontrada)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'A loja continua acompanhada; a fonte não a retornou.',
                  ),
                ),
              if (loja.etiqueta != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Chip(label: Text(loja.etiqueta!)),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  loja.descricaoPrincipal ?? _descricaoAusente,
                  style: tema.textTheme.bodyMedium,
                ),
              ),
              if (loja.cashbackSecundarioTexto != null ||
                  loja.descricaoSecundaria != null)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Não-correntista'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${loja.cashbackSecundarioTexto ?? 'Oferta não informada'}\n'
                        '${loja.descricaoSecundaria ?? _descricaoAusente}',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
