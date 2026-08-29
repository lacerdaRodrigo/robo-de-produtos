import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';

const _descricaoAusente =
    'O Inter não informou condições adicionais nesta consulta';

class CartaoCashbackInter extends StatelessWidget {
  const CartaoCashbackInter({
    super.key,
    required this.loja,
    this.compacto = false,
    this.acompanhada = false,
    this.podeAdministrar = false,
    this.aoAcompanhar,
  });

  final CashbackInter loja;
  final bool compacto;
  final bool acompanhada;
  final bool podeAdministrar;
  final VoidCallback? aoAcompanhar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final conteudo = compacto
        ? _CartaoCompacto(
            tema: tema,
            cores: cores,
            loja: loja,
            acompanhada: acompanhada,
            podeAdministrar: podeAdministrar,
            aoAcompanhar: aoAcompanhar,
          )
        : _CartaoDetalhado(tema: tema, cores: cores, loja: loja);
    return Semantics(label: 'Loja ${loja.nome}', child: conteudo);
  }
}

class _CartaoCompacto extends StatelessWidget {
  const _CartaoCompacto({
    required this.tema,
    required this.cores,
    required this.loja,
    required this.acompanhada,
    required this.podeAdministrar,
    required this.aoAcompanhar,
  });

  final ThemeData tema;
  final CoresRadar cores;
  final CashbackInter loja;
  final bool acompanhada;
  final bool podeAdministrar;
  final VoidCallback? aoAcompanhar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: CartaoRadar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF3FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _iniciais(loja.nome),
                  style: TextStyle(
                    color: Tokens.marca,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loja.nome,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Site parceiro · cashback publicado',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                loja.encontrada
                    ? (loja.cashbackPrincipalTexto ?? 'Oferta disponível')
                    : 'Indisponível',
                style: tema.textTheme.titleSmall?.copyWith(
                  color: loja.encontrada ? cores.ganho : cores.textoSuave,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cashback salvo na última coleta',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: cores.textoSuave,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: podeAdministrar ? aoAcompanhar : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD7F8E5),
                  foregroundColor: Tokens.ganho,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                icon: Icon(
                  acompanhada
                      ? Icons.check_circle_outline
                      : Icons.add_circle_outline,
                  size: 16,
                ),
                label: Text(acompanhada ? 'Acompanhada' : 'Acompanhar'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  static String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}

class _CartaoDetalhado extends StatelessWidget {
  const _CartaoDetalhado({
    required this.tema,
    required this.cores,
    required this.loja,
  });

  final ThemeData tema;
  final CoresRadar cores;
  final CashbackInter loja;

  @override
  Widget build(BuildContext context) {
    final oferta = loja.cashbackPrincipalTexto ?? 'Oferta não informada';
    return Card(
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
                color: loja.encontrada ? cores.ganho : null,
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
    );
  }
}
