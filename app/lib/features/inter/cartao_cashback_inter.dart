import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';
import 'formato_cashback_inter.dart';

const _descricaoAusente =
    'O Inter não informou condições adicionais nesta consulta';

class CartaoCashbackInter extends StatelessWidget {
  const CartaoCashbackInter({
    super.key,
    required this.loja,
    this.compacto = false,
    this.acompanhada = false,
    this.alterando = false,
    this.atualizadoEm,
    this.podeAdministrar = false,
    this.aoAcompanhar,
  });

  final CashbackInter loja;
  final bool compacto;
  final bool acompanhada;
  final bool alterando;
  final String? atualizadoEm;
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
            alterando: alterando,
            atualizadoEm: atualizadoEm,
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
    required this.alterando,
    required this.atualizadoEm,
    required this.podeAdministrar,
    required this.aoAcompanhar,
  });

  final ThemeData tema;
  final CoresRadar cores;
  final CashbackInter loja;
  final bool acompanhada;
  final bool alterando;
  final String? atualizadoEm;
  final bool podeAdministrar;
  final VoidCallback? aoAcompanhar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: CartaoRadar(
      padding: const EdgeInsets.all(14),
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
                  gradient: LinearGradient(
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
                  _iniciais(loja.nome),
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFDFF8FF)
                        : Tokens.marca,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loja.nome,
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Site parceiro',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: cores.textoSuave,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  loja.encontrada
                      ? (loja.cashbackPrincipalTexto ?? 'Oferta disponível')
                      : 'Indisponível',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: loja.encontrada ? cores.ganho : cores.textoSuave,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: loja.encontrada ? cores.ganho : cores.atencao,
                        shape: BoxShape.circle,
                      ),
                      child: const SizedBox.square(dimension: 6),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        loja.encontrada
                            ? tempoColetaInter(atualizadoEm, DateTime.now())
                            : 'Não retornada na última coleta',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: cores.textoSuave,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (podeAdministrar)
                OutlinedButton(
                  onPressed: !alterando ? aoAcompanhar : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 35),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    foregroundColor: acompanhada ? cores.ganho : cores.acao,
                    backgroundColor: acompanhada
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Tokens.ganhoFundoEscuro
                              : Tokens.ganhoFundo)
                        : Colors.transparent,
                    side: BorderSide(
                      color: acompanhada ? Colors.transparent : cores.acao,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (alterando)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: SizedBox.square(
                            dimension: 13,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (acompanhada) ...[
                        const Icon(Icons.check, size: 13),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        alterando
                            ? 'Salvando…'
                            : acompanhada
                            ? 'Acompanhada'
                            : 'Acompanhar',
                      ),
                    ],
                  ),
                )
              else if (acompanhada)
                Text(
                  '✓ Acompanhada',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: cores.ganho,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
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
