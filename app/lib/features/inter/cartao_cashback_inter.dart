import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tema.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';
import 'formato_cashback_inter.dart';

const _descricaoAusente =
    'O Inter não informou condições adicionais nesta consulta';

Future<void> _abrirCondicoesCashback(
  BuildContext context,
  CashbackInter loja, {
  String? atualizadoEm,
  VoidCallback? aoAbrirParceiro,
}) async {
  await mostrarFolhaRadar<void>(
    context,
    alturaMaxima: 0.86,
    builder: (contexto) => FolhaRadar(
      titulo: loja.nome,
      descricao: '',
      mostrarVoltar: false,
      child: Flexible(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: CoresRadar.de(contexto).superficieAlternativa,
                    borderRadius: BorderRadius.circular(
                      contexto.tokens.radii.md,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: contexto.tokens.spacing.two,
                      vertical: contexto.tokens.spacing.one,
                    ),
                    child: Text(
                      'Sites parceiros',
                      style: Theme.of(contexto).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
              SizedBox(height: contexto.tokens.spacing.four),
              Text(
                'Condições da oferta',
                style: Theme.of(
                  contexto,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              SizedBox(height: contexto.tokens.spacing.two),
              Text(
                loja.descricaoPrincipal ?? _descricaoAusente,
                key: ValueKey('condicoes-principal-${loja.id}'),
                style: Theme.of(contexto).textTheme.bodyMedium?.copyWith(
                  color: CoresRadar.de(contexto).textoSuave,
                  height: 1.45,
                ),
              ),
              if (loja.cashbackSecundarioTexto != null ||
                  loja.descricaoSecundaria != null) ...[
                SizedBox(height: contexto.tokens.spacing.four),
                Text(
                  'Para não-correntista',
                  style: Theme.of(contexto).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: contexto.tokens.spacing.two),
                Text(
                  loja.cashbackSecundarioTexto ?? 'Oferta não informada',
                  style: Theme.of(contexto).textTheme.bodyMedium?.copyWith(
                    color: CoresRadar.de(contexto).textoSuave,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: contexto.tokens.spacing.two),
                Text(
                  loja.descricaoSecundaria ?? _descricaoAusente,
                  key: ValueKey('condicoes-secundaria-${loja.id}'),
                  style: Theme.of(contexto).textTheme.bodyMedium?.copyWith(
                    color: CoresRadar.de(contexto).textoSuave,
                    height: 1.45,
                  ),
                ),
              ],
              if (atualizadoEm != null) ...[
                SizedBox(height: contexto.tokens.spacing.four),
                Text(
                  dataHoraInter(atualizadoEm),
                  style: Theme.of(contexto).textTheme.bodySmall?.copyWith(
                    color: CoresRadar.de(contexto).textoSuave,
                  ),
                ),
              ],
              if (aoAbrirParceiro != null) ...[
                SizedBox(height: contexto.tokens.spacing.four),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: ValueKey('abrir-banco-inter-${loja.id}'),
                    onPressed: () {
                      Navigator.of(contexto).pop();
                      aoAbrirParceiro();
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Abrir Banco Inter'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

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
        ? _CartaoCompactoV15(
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
            acompanhada: acompanhada,
            alterando: alterando,
            aoAcompanhar: aoAcompanhar,
            aoAbrirParceiro: aoAbrirParceiro,
          );
    return Semantics(label: 'Loja ${loja.nome}', child: conteudo);
  }
}

class _CartaoCompactoV15 extends StatelessWidget {
  const _CartaoCompactoV15({
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
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textoPrincipal =
        loja.cashbackPrincipalTexto ?? 'Oferta não informada';
    final contexto = [
      loja.categoria?.trim(),
      loja.etiqueta?.trim(),
    ].whereType<String>().where((valor) => valor.isNotEmpty).join(' · ');
    final atualizado = atualizadoEm == null
        ? null
        : dataHoraInter(atualizadoEm);
    final possuiAcompanhamento = podeAdministrar || aoAcompanhar != null;
    final seguir = OutlinedButton.icon(
      key: ValueKey('acompanhar-${loja.id}'),
      onPressed: !alterando ? aoAcompanhar : null,
      icon: alterando
          ? SizedBox.square(
              dimension: tokens.sizes.icon,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              acompanhada
                  ? Icons.check_rounded
                  : Icons.notifications_none_rounded,
            ),
      label: Text(
        alterando
            ? 'Salvando…'
            : acompanhada
            ? 'Acompanhando'
            : 'Acompanhar',
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, tokens.sizes.touchTarget),
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.two),
        foregroundColor: acompanhada ? cores.acao : cores.texto,
        backgroundColor: acompanhada
            ? cores.acao.withValues(alpha: 0.14)
            : Colors.transparent,
        side: BorderSide(color: acompanhada ? Colors.transparent : cores.borda),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      ),
    );
    final condicoes = TextButton(
      key: ValueKey('condicoes-${loja.id}'),
      onPressed: () => _abrirCondicoesCashback(
        context,
        loja,
        atualizadoEm: atualizadoEm,
        aoAbrirParceiro: aoAbrirParceiro,
      ),
      style: TextButton.styleFrom(
        minimumSize: Size(0, tokens.sizes.touchTarget),
        padding: EdgeInsets.symmetric(horizontal: tokens.spacing.two),
        foregroundColor: cores.acao,
      ),
      child: const Text('Condições'),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spacing.four),
      child: CartaoRadar(
        padding: EdgeInsets.all(tokens.spacing.five),
        comSombra: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contexto.isEmpty ? 'Sites parceiros' : contexto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.labelMedium?.copyWith(
                      color: cores.textoSuave,
                    ),
                  ),
                ),
                if (!loja.encontrada)
                  Text(
                    'Indisponível',
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: cores.atencao,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (loja.encontrada && atualizado != null)
                  Flexible(
                    child: Text(
                      atualizado,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: cores.textoSuave,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: tokens.spacing.three),
            Text(loja.nome, style: tema.textTheme.tituloOferta),
            SizedBox(height: tokens.spacing.three),
            Text(
              loja.encontrada ? textoPrincipal : 'Oferta não encontrada',
              style: tema.textTheme.precoOferta?.copyWith(
                color: loja.encontrada ? cores.texto : cores.textoSuave,
              ),
            ),
            SizedBox(height: tokens.spacing.one),
            Text(
              'Cliente Inter Shopping',
              style: tema.textTheme.bodySmall?.copyWith(
                color: cores.textoSuave,
              ),
            ),
            if (loja.cashbackSecundarioTexto != null ||
                loja.descricaoSecundaria != null) ...[
              SizedBox(height: tokens.spacing.three),
              Text(
                'Para não-correntista',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spacing.one),
              Text(
                loja.cashbackSecundarioTexto ?? 'Oferta não informada',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (!loja.encontrada) ...[
              SizedBox(height: tokens.spacing.two),
              Text(
                'A loja continua acompanhada; a fonte não a retornou.',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.atencao,
                  height: 1.35,
                ),
              ),
            ],
            SizedBox(height: tokens.spacing.three),
            Divider(color: cores.borda),
            if (possuiAcompanhamento) ...[
              SizedBox(height: tokens.spacing.one),
              LayoutBuilder(
                builder: (context, limites) {
                  final textoAmpliado =
                      MediaQuery.textScalerOf(context).scale(10) > 12;
                  final empilhar = limites.maxWidth < 300 || textoAmpliado;
                  if (empilhar) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        seguir,
                        SizedBox(height: tokens.spacing.one),
                        condicoes,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: seguir),
                      SizedBox(width: tokens.spacing.one),
                      condicoes,
                    ],
                  );
                },
              ),
            ],
            if (aoAbrirParceiro != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: ValueKey('ir-inter-${loja.id}'),
                  onPressed: aoAbrirParceiro,
                  style: TextButton.styleFrom(
                    minimumSize: Size(0, tokens.sizes.touchTarget),
                    padding: EdgeInsets.zero,
                    foregroundColor: cores.acao,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Ir para o Inter'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartaoDetalhado extends StatelessWidget {
  const _CartaoDetalhado({
    required this.tema,
    required this.cores,
    required this.loja,
    required this.acompanhada,
    required this.alterando,
    required this.aoAcompanhar,
    required this.aoAbrirParceiro,
  });

  final ThemeData tema;
  final CoresRadar cores;
  final CashbackInter loja;
  final bool acompanhada;
  final bool alterando;
  final VoidCallback? aoAcompanhar;
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
            Row(
              children: [
                Expanded(
                  child: Text(loja.nome, style: tema.textTheme.titleMedium),
                ),
                if (aoAcompanhar != null)
                  IconButton(
                    key: ValueKey('alerta-inter-${loja.id}'),
                    tooltip: acompanhada
                        ? 'Deixar de acompanhar ${loja.nome}'
                        : 'Acompanhar ${loja.nome}',
                    onPressed: !alterando ? aoAcompanhar : null,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      acompanhada
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_none_outlined,
                    ),
                  ),
              ],
            ),
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
