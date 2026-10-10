import 'package:flutter/material.dart';

import '../fundacao/ds_medidas.dart';
import '../fundacao/ds_tema.dart';
import 'ds_basicos.dart';
import 'ds_estados.dart';

/// O cartão único do app. Loja Inter, oferta do Compre direto, parceiro
/// Livelo e PC Pichau são este mesmo widget; cada domínio só escreve um
/// mapeamento de dados para estes parâmetros.
class DsCartaoOferta extends StatelessWidget {
  const DsCartaoOferta({
    super.key,
    required this.origem,
    required this.titulo,
    required this.valores,
    this.selo,
    this.meta,
    this.acompanhar,
    this.acoes = const <Widget>[],
    this.aoTocar,
  });

  /// "Pichau · SKU 81273", "Livelo · Moda".
  final String origem;
  final String titulo;

  /// Normalmente 1–2 [DsValor]; o primeiro é o principal.
  final List<Widget> valores;
  final DsSelo? selo;

  /// Linha de metadados ("Até 12/10 · Hoje, 14:05").
  final String? meta;

  /// Botão de acompanhamento; fica sempre à esquerda da barra de ações.
  final DsBotaoAcompanhar? acompanhar;

  /// Ações à direita: [DsBotaoIcone] de histórico, abrir na loja, condições.
  final List<Widget> acoes;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipo;
    final temAcoes = acompanhar != null || acoes.isNotEmpty;
    return Material(
      color: c.superficie1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DsRaio.md),
        side: BorderSide(color: c.borda1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(DsEspaco.e4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          origem,
                          style: t.apoio.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          titulo,
                          style: t.tituloItem,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (selo != null) ...[
                    const SizedBox(width: DsEspaco.e3),
                    selo!,
                  ],
                ],
              ),
              if (valores.isNotEmpty) ...[
                const SizedBox(height: DsEspaco.e3),
                Wrap(
                  spacing: DsEspaco.e6,
                  runSpacing: DsEspaco.e2,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: valores,
                ),
              ],
              if (meta != null) ...[
                const SizedBox(height: DsEspaco.e2),
                Text(meta!, style: t.apoio),
              ],
              if (temAcoes) ...[
                const SizedBox(height: DsEspaco.e3),
                Divider(color: c.borda1),
                const SizedBox(height: DsEspaco.e3),
                Row(
                  children: [
                    if (acompanhar != null) acompanhar!,
                    const Spacer(),
                    for (var i = 0; i < acoes.length; i++) ...[
                      if (i > 0) const SizedBox(width: DsEspaco.e2),
                      acoes[i],
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Liga/desliga acompanhamento de forma otimista: vira na hora, bloqueia
/// durante a gravação, volta em falha com aviso e oferece Desfazer.
class DsBotaoAcompanhar extends StatefulWidget {
  const DsBotaoAcompanhar({
    super.key,
    required this.acompanhado,
    required this.aoAlternar,
    this.nomeItem,
  });

  final bool acompanhado;

  /// Grava o novo estado. Deve lançar exceção em falha.
  final Future<void> Function(bool novo) aoAlternar;

  /// Usado nos avisos ("Você deixou de acompanhar Renner").
  final String? nomeItem;

  @override
  State<DsBotaoAcompanhar> createState() => _EstadoDsBotaoAcompanhar();
}

class _EstadoDsBotaoAcompanhar extends State<DsBotaoAcompanhar> {
  late bool _valor = widget.acompanhado;
  var _salvando = false;

  @override
  void didUpdateWidget(DsBotaoAcompanhar antigo) {
    super.didUpdateWidget(antigo);
    if (!_salvando && antigo.acompanhado != widget.acompanhado) {
      _valor = widget.acompanhado;
    }
  }

  Future<void> _alternar({bool permitirDesfazer = true}) async {
    if (_salvando) return;
    final anterior = _valor;
    final novo = !anterior;
    setState(() {
      _valor = novo;
      _salvando = true;
    });
    try {
      await widget.aoAlternar(novo);
      if (!mounted) return;
      if (!novo && permitirDesfazer) {
        DsAviso.mostrar(
          context,
          texto: widget.nomeItem == null
              ? 'Você deixou de acompanhar.'
              : 'Você deixou de acompanhar ${widget.nomeItem}.',
          rotuloAcao: 'Desfazer',
          aoAcionar: () => _alternar(permitirDesfazer: false),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _valor = anterior);
      DsAviso.mostrar(
        context,
        texto: 'Não foi possível salvar.',
        rotuloAcao: 'Tentar de novo',
        aoAcionar: _alternar,
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final rotulo = _salvando
        ? 'Salvando…'
        : (_valor ? 'Acompanhando' : 'Acompanhar');
    return Semantics(
      button: true,
      toggled: _valor,
      enabled: !_salvando,
      child: Opacity(
        opacity: _salvando ? 0.6 : 1,
        child: Material(
          color: _valor ? c.primaria : Colors.transparent,
          shape: StadiumBorder(
            side: _valor ? BorderSide.none : BorderSide(color: c.primaria),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _salvando ? null : _alternar,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: DsEspaco.alvoToque),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: DsEspaco.e4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _valor
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 18,
                      color: _valor ? c.sobrePrimaria : c.primaria,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rotulo,
                      style: context.tipo.rotulo.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _valor ? c.sobrePrimaria : c.primaria,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
