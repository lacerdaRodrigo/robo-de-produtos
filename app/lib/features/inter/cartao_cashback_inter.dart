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
    this.aoAbrirParceiro,
  });

  final CashbackInter loja;
  final bool compacto;
  final bool acompanhada;
  final bool alterando;
  final String? atualizadoEm;
  final bool podeAdministrar;
  final VoidCallback? aoAcompanhar;
  final VoidCallback? aoAbrirParceiro;

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
            aoAbrirParceiro: aoAbrirParceiro,
          )
        : _CartaoDetalhado(
            tema: tema,
            cores: cores,
            loja: loja,
            aoAbrirParceiro: aoAbrirParceiro,
          );
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
    required this.aoAbrirParceiro,
  });

  final ThemeData tema;
  final CoresRadar cores;
  final CashbackInter loja;
  final bool acompanhada;
  final bool alterando;
  final String? atualizadoEm;
  final bool podeAdministrar;
  final VoidCallback? aoAcompanhar;
  final VoidCallback? aoAbrirParceiro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: CartaoRadar(
      corDestaque: cores.ganho,
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: loja.encontrada
                        ? (Theme.of(context).brightness == Brightness.dark
                              ? Tokens.ganhoFundoEscuro
                              : Tokens.positiveSoft)
                        : cores.superficieAlternativa,
                    borderRadius: BorderRadius.circular(RaioRadar.pilula),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      loja.encontrada ? 'Melhor cashback' : 'Indisponível',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: loja.encontrada ? cores.ganho : cores.textoSuave,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: loja.cashbackPrincipalTexto == null
                  ? cores.superficieAlternativa
                  : (Theme.of(context).brightness == Brightness.dark
                        ? Tokens.ganhoFundoEscuro
                        : Tokens.positiveSoft),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para correntista',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: loja.cashbackPrincipalTexto == null
                        ? cores.textoSuave
                        : cores.ganho,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loja.cashbackPrincipalTexto ?? 'Percentual não informado',
                  style: tema.textTheme.titleLarge?.copyWith(
                    color: loja.cashbackPrincipalTexto == null
                        ? cores.textoSuave
                        : cores.ganho,
                    fontSize: 21,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ],
            ),
          ),
          if (loja.etiqueta != null || loja.descricaoPrincipal != null) ...[
            const SizedBox(height: 11),
            if (loja.etiqueta != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Tokens.ganhoFundoEscuro
                      : Tokens.ganhoFundo,
                  borderRadius: BorderRadius.circular(RaioRadar.pilula),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Text(
                    loja.etiqueta!,
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: cores.ganho,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            if (loja.descricaoPrincipal != null) ...[
              const SizedBox(height: 7),
              Text(
                loja.descricaoPrincipal!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ],
          if (loja.cashbackPrincipalTexto != null ||
              loja.cashbackSecundarioTexto != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: tema.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  if (loja.cashbackPrincipalTexto != null)
                    _LinhaCashbackInter(
                      rotulo: 'Para correntista',
                      valor: loja.cashbackPrincipalTexto!,
                      tema: tema,
                      cores: cores,
                    ),
                  if (loja.cashbackPrincipalTexto != null &&
                      loja.cashbackSecundarioTexto != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 7),
                      child: Divider(height: 1),
                    ),
                  ],
                  if (loja.cashbackSecundarioTexto != null)
                    _LinhaCashbackInter(
                      rotulo: 'Para não-correntista',
                      valor: loja.cashbackSecundarioTexto!,
                      tema: tema,
                      cores: cores,
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 11),
          Row(
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
          if (!podeAdministrar && acompanhada) ...[
            const SizedBox(height: 8),
            Text(
              '✓ Acompanhada',
              style: tema.textTheme.labelSmall?.copyWith(
                color: cores.ganho,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.end,
            children: [
              if (podeAdministrar)
                OutlinedButton.icon(
                  key: ValueKey('acompanhar-${loja.id}'),
                  onPressed: !alterando ? aoAcompanhar : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
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
                  icon: alterando
                      ? const SizedBox.square(
                          dimension: 13,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          acompanhada
                              ? Icons.notifications_off_outlined
                              : Icons.notifications_none_rounded,
                          size: 15,
                        ),
                  label: Text(
                    alterando
                        ? 'Salvando…'
                        : acompanhada
                        ? 'Deixar de acompanhar'
                        : 'Acompanhar',
                  ),
                ),
              FilledButton.icon(
                key: ValueKey('ir-inter-${loja.id}'),
                onPressed: aoAbrirParceiro,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  backgroundColor: cores.acao,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: const Icon(Icons.open_in_new_rounded, size: 15),
                label: const Text('Ir para o Inter'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  static String _iniciais(String nome) {
    final partes = nome.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty || partes.first.isEmpty) return '?';
    if (partes.length == 1) return partes.first.substring(0, 1).toUpperCase();
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }
}

class _LinhaCashbackInter extends StatelessWidget {
  const _LinhaCashbackInter({
    required this.rotulo,
    required this.valor,
    required this.tema,
    required this.cores,
  });

  final String rotulo;
  final String valor;
  final ThemeData tema;
  final CoresRadar cores;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          rotulo,
          style: tema.textTheme.labelSmall?.copyWith(
            color: cores.textoSuave,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          valor,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: tema.textTheme.labelSmall?.copyWith(
            color: cores.ganho,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _CartaoDetalhado extends StatelessWidget {
  const _CartaoDetalhado({
    required this.tema,
    required this.cores,
    required this.loja,
    required this.aoAbrirParceiro,
  });

  final ThemeData tema;
  final CoresRadar cores;
  final CashbackInter loja;
  final VoidCallback? aoAbrirParceiro;

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
            const Text('Para correntista'),
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
            if (aoAbrirParceiro != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: aoAbrirParceiro,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Ir para o Inter'),
                ),
              ),
            if (loja.cashbackSecundarioTexto != null ||
                loja.descricaoSecundaria != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('Para não-correntista'),
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
