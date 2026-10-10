import 'package:flutter/material.dart';

import '../fundacao/ds_cores.dart';
import '../fundacao/ds_medidas.dart';
import '../fundacao/ds_tema.dart';

// ---------------------------------------------------------------------------
// Botão
// ---------------------------------------------------------------------------

enum DsVarianteBotao { primaria, tonal, contorno, texto, perigo }

/// Botão único do app. Uma ação `primaria` por tela/folha.
class DsBotao extends StatelessWidget {
  const DsBotao({
    super.key,
    required this.rotulo,
    required this.aoTocar,
    this.variante = DsVarianteBotao.primaria,
    this.icone,
    this.carregando = false,
    this.expandir = false,
  });

  final String rotulo;
  final VoidCallback? aoTocar;
  final DsVarianteBotao variante;
  final IconData? icone;
  final bool carregando;
  final bool expandir;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final (fundo, frente, borda) = switch (variante) {
      DsVarianteBotao.primaria => (c.primaria, c.sobrePrimaria, null),
      DsVarianteBotao.tonal => (c.primariaSuave, c.primariaForte, null),
      DsVarianteBotao.contorno => (Colors.transparent, c.texto1, c.borda2),
      DsVarianteBotao.texto => (Colors.transparent, c.primaria, null),
      DsVarianteBotao.perigo => (c.perigo, c.superficie1, null),
    };
    final conteudo = carregando
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: frente),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icone != null) ...[
                Icon(icone, size: 20, color: frente),
                const SizedBox(width: DsEspaco.e2),
              ],
              Flexible(
                child: Text(
                  rotulo,
                  textAlign: TextAlign.center,
                  style: context.tipo.rotulo.copyWith(
                    fontSize: 14,
                    color: frente,
                  ),
                ),
              ),
            ],
          );

    final botao = Semantics(
      button: true,
      enabled: aoTocar != null && !carregando,
      label: carregando ? '$rotulo, carregando' : null,
      child: Material(
        color: fundo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DsRaio.sm),
          side: borda == null ? BorderSide.none : BorderSide(color: borda),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: carregando ? null : aoTocar,
          child: Opacity(
            opacity: aoTocar == null ? 0.45 : 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: DsEspaco.alvoToque),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: variante == DsVarianteBotao.texto
                      ? DsEspaco.e3
                      : DsEspaco.e5,
                ),
                child: Center(widthFactor: 1, child: conteudo),
              ),
            ),
          ),
        ),
      ),
    );
    return expandir ? SizedBox(width: double.infinity, child: botao) : botao;
  }
}

/// Botão redondo de ícone (48 px) com rótulo semântico obrigatório.
class DsBotaoIcone extends StatelessWidget {
  const DsBotaoIcone({
    super.key,
    required this.icone,
    required this.rotulo,
    required this.aoTocar,
    this.preenchido = true,
  });

  final IconData icone;
  final String rotulo;
  final VoidCallback? aoTocar;
  final bool preenchido;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Tooltip(
      message: rotulo,
      child: Material(
        color: preenchido ? c.superficie2 : Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: SizedBox.square(
            dimension: DsEspaco.alvoToque,
            child: Icon(
              icone,
              size: 20,
              color: aoTocar == null ? c.texto1.withValues(alpha: 0.4) : c.texto1,
              semanticLabel: rotulo,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip
// ---------------------------------------------------------------------------

class DsChip extends StatelessWidget {
  const DsChip({
    super.key,
    required this.rotulo,
    required this.selecionado,
    required this.aoTocar,
  });

  final String rotulo;
  final bool selecionado;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return Semantics(
      button: true,
      selected: selecionado,
      child: SizedBox(
        height: DsEspaco.alvoToque,
        child: Center(
          widthFactor: 1,
          child: Material(
            color: selecionado ? c.primariaSuave : c.superficie2,
            shape: StadiumBorder(
              side: selecionado
                  ? BorderSide(color: c.primaria)
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: aoTocar,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 36),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DsEspaco.e3),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      rotulo,
                      style: context.tipo.rotulo.copyWith(
                        color: selecionado ? c.primariaForte : c.texto1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Selo
// ---------------------------------------------------------------------------

enum DsTom { neutro, sinal, sucesso, atencao, perigo, primaria }

extension DsTomCores on DsTom {
  (Color fundo, Color frente) cores(DsCores c) => switch (this) {
    DsTom.neutro => (c.superficie2, c.texto2),
    DsTom.sinal => (c.sinal, c.sobreSinal),
    DsTom.sucesso => (c.sucessoSuave, c.sucesso),
    DsTom.atencao => (c.atencaoSuave, c.atencao),
    DsTom.perigo => (c.perigoSuave, c.perigo),
    DsTom.primaria => (c.primariaSuave, c.primariaForte),
  };
}

/// Etiqueta curta de estado. `DsTom.sinal` só para Mudou/Novo/Não lido.
class DsSelo extends StatelessWidget {
  const DsSelo({super.key, required this.texto, this.tom = DsTom.neutro});

  final String texto;
  final DsTom tom;

  @override
  Widget build(BuildContext context) {
    final (fundo, frente) = tom.cores(context.cores);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(DsRaio.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DsEspaco.e2,
          vertical: DsEspaco.e1,
        ),
        child: Text(
          texto,
          style: context.tipo.apoio.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: frente,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Segmentado
// ---------------------------------------------------------------------------

class DsOpcao<T> {
  const DsOpcao(this.valor, this.rotulo, {this.contagem});
  final T valor;
  final String rotulo;
  final int? contagem;
}

/// Alternância Todos / No radar, Todos / Não lidos.
class DsSegmentado<T> extends StatelessWidget {
  const DsSegmentado({
    super.key,
    required this.opcoes,
    required this.selecionado,
    required this.aoMudar,
  });

  final List<DsOpcao<T>> opcoes;
  final T selecionado;
  final ValueChanged<T> aoMudar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.superficie2,
        borderRadius: BorderRadius.circular(DsRaio.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DsEspaco.e1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final opcao in opcoes)
              _Segmento(
                rotulo: opcao.rotulo,
                contagem: opcao.contagem,
                ativo: opcao.valor == selecionado,
                aoTocar: () => aoMudar(opcao.valor),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.rotulo,
    required this.contagem,
    required this.ativo,
    required this.aoTocar,
  });

  final String rotulo;
  final int? contagem;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final estilo = context.tipo.rotulo;
    return Semantics(
      button: true,
      selected: ativo,
      child: AnimatedContainer(
        duration: DsMovimento.de(
          DsMovimento.toque,
          reduzido: context.movimentoReduzido,
        ),
        decoration: BoxDecoration(
          color: ativo ? c.superficie1 : Colors.transparent,
          borderRadius: BorderRadius.circular(DsRaio.xs),
          boxShadow: ativo && Theme.of(context).brightness == Brightness.light
              ? const [
                  BoxShadow(
                    color: Color(0x0F11131A),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(DsRaio.xs),
          onTap: aoTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: DsEspaco.e4),
              child: Center(
                widthFactor: 1,
                child: Text.rich(
                  TextSpan(
                    text: rotulo,
                    style: estilo.copyWith(color: ativo ? c.texto1 : c.texto2),
                    children: [
                      if (contagem != null && contagem! > 0)
                        TextSpan(
                          text: '  $contagem',
                          style: estilo.copyWith(color: c.primaria),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Valor
// ---------------------------------------------------------------------------

/// Direção da mudança do ponto de vista do USUÁRIO.
enum DsVariacao { melhorou, piorou }

enum DsTamanhoValor { cartao, secundario, destaque }

/// Número rotulado: preço, cashback ou pontos. Recebe texto já formatado
/// (`moeda()`, `decimal()`), nunca `double`.
class DsValor extends StatelessWidget {
  const DsValor({
    super.key,
    required this.rotulo,
    required this.valor,
    this.anterior,
    this.variacao,
    this.textoVariacao,
    this.subiu = false,
    this.tamanho = DsTamanhoValor.cartao,
  });

  final String rotulo;
  final String valor;

  /// Valor anterior riscado ("R$ 4.799,90").
  final String? anterior;
  final DsVariacao? variacao;

  /// Texto da variação ("R$ 500 em 7 dias", "era 5%").
  final String? textoVariacao;

  /// Direção do NÚMERO (define a seta). A cor vem de [variacao]: preço que
  /// caiu é `subiu: false` + `DsVariacao.melhorou`.
  final bool subiu;
  final DsTamanhoValor tamanho;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipo;
    final estiloValor = switch (tamanho) {
      DsTamanhoValor.destaque => t.preco,
      DsTamanhoValor.cartao => t.precoCartao,
      DsTamanhoValor.secundario => t.numeroLinha.copyWith(
        fontSize: 16,
        color: c.texto2,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rotulo, style: t.apoio.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(valor, style: estiloValor),
        if (anterior != null)
          Text(
            anterior!,
            style: t.apoio.copyWith(decoration: TextDecoration.lineThrough),
          ),
        if (variacao != null && textoVariacao != null)
          Text(
            '${subiu ? '▲' : '▼'} $textoVariacao',
            semanticsLabel:
                '${variacao == DsVariacao.melhorou ? 'Melhorou' : 'Piorou'}: $textoVariacao',
            style: t.apoio.copyWith(
              fontWeight: FontWeight.w700,
              color: variacao == DsVariacao.melhorou ? c.sucesso : c.perigo,
            ),
          ),
      ],
    );
  }
}
