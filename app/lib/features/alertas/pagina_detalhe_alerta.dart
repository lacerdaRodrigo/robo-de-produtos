import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/navegacao/destinos.dart';
import '../../app/tema/tema.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../inter/cartao_cashback_inter.dart';
import '../livelo/cartao_catalogo_livelo.dart';
import '../livelo/pagina_historico_livelo_android.dart';
import '../pichau/link_pichau.dart';
import '../pichau/modelos_pichau.dart';
import '../pichau/pagina_pichau.dart';
import '../produtos/link_shopping_inter.dart';
import '../produtos/pagina_historico_produto.dart';
import 'modelo_item_alerta.dart';

/// Full-page V15 detail opened from the Alerts center.
class PaginaDetalheAlerta extends StatefulWidget {
  const PaginaDetalheAlerta({
    super.key,
    required this.api,
    required this.detalhe,
    this.destinoSelecionado = DestinoCompacto.inicio,
    this.aoNavegar,
  });

  final Api api;
  final ItemResolvidoAlerta detalhe;
  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;

  @override
  State<PaginaDetalheAlerta> createState() => _EstadoPaginaDetalheAlerta();
}

class _EstadoPaginaDetalheAlerta extends State<PaginaDetalheAlerta> {
  late bool _acompanhado = _estadoAcompanhamento;
  bool _salvandoAcompanhamento = false;

  bool get _estadoAcompanhamento => switch (widget.detalhe.origem) {
    OrigemItemAlerta.livelo =>
      (widget.detalhe.item as ParceiroCatalogoLivelo).acompanhada,
    OrigemItemAlerta.interCashback =>
      (widget.detalhe.item as CashbackInter).favorita,
    OrigemItemAlerta.interProduto =>
      (widget.detalhe.item as ProdutoDireto).acompanhado,
    OrigemItemAlerta.pichau =>
      (widget.detalhe.item as PichauProduto).acompanhada,
  };

  String get _nome => switch (widget.detalhe.origem) {
    OrigemItemAlerta.livelo =>
      (widget.detalhe.item as ParceiroCatalogoLivelo).nome,
    OrigemItemAlerta.interCashback =>
      (widget.detalhe.item as CashbackInter).nome,
    OrigemItemAlerta.interProduto =>
      (widget.detalhe.item as ProdutoDireto).nome,
    OrigemItemAlerta.pichau => (widget.detalhe.item as PichauProduto).nome,
  };

  String get _origemRotulo => switch (widget.detalhe.origem) {
    OrigemItemAlerta.livelo => 'Livelo',
    OrigemItemAlerta.interCashback ||
    OrigemItemAlerta.interProduto => 'Banco Inter',
    OrigemItemAlerta.pichau => 'Pichau',
  };

  bool get _tipoLoja =>
      widget.detalhe.origem == OrigemItemAlerta.livelo ||
      widget.detalhe.origem == OrigemItemAlerta.interCashback;

  @override
  Widget build(BuildContext context) {
    final compacto = MediaQuery.sizeOf(context).width < 920;
    final acao = _acaoPrincipal();
    final nav = compacto
        ? BarraInferiorRadar(
            selecionado: widget.destinoSelecionado,
            aoSelecionar: (destino) {
              if (widget.aoNavegar != null) {
                widget.aoNavegar!(destino);
              } else {
                Navigator.of(context).maybePop();
              }
            },
          )
        : null;
    return Scaffold(
      appBar: _cabecalho(context),
      body: _conteudo(),
      bottomNavigationBar: acao == null
          ? nav
          : Column(mainAxisSize: MainAxisSize.min, children: [acao, ?nav]),
    );
  }

  PreferredSizeWidget _cabecalho(BuildContext context) {
    final tema = Theme.of(context);
    final cores = context.tokens.colors;
    final nomeLoja = switch (widget.detalhe.origem) {
      OrigemItemAlerta.livelo => _origemRotulo,
      OrigemItemAlerta.interCashback => _origemRotulo,
      OrigemItemAlerta.interProduto =>
        (widget.detalhe.item as ProdutoDireto).lojaNome,
      OrigemItemAlerta.pichau => _origemRotulo,
    };
    final titulo = _tipoLoja ? _nome : 'Detalhes';
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        key: const Key('voltar-detalhe-alerta'),
        tooltip: 'Voltar à Central de alertas',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            nomeLoja,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.bodySmall?.copyWith(color: cores.textoSuave),
          ),
        ],
      ),
      actions: _tipoLoja
          ? null
          : [
              IconButton(
                key: const Key('acompanhar-detalhe-alerta-cabecalho'),
                tooltip: _acompanhado
                    ? 'Deixar de acompanhar $_nome'
                    : 'Acompanhar $_nome',
                onPressed: _salvandoAcompanhamento
                    ? null
                    : () => unawaited(_alternarAcompanhamento()),
                icon: _salvandoAcompanhamento
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _acompanhado
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_none_outlined,
                      ),
              ),
            ],
    );
  }

  Widget _conteudo() => switch (widget.detalhe.origem) {
    OrigemItemAlerta.livelo => _conteudoLivelo(),
    OrigemItemAlerta.interCashback => _conteudoCashback(),
    OrigemItemAlerta.interProduto => _conteudoProdutoDireto(
      widget.detalhe.item as ProdutoDireto,
    ),
    OrigemItemAlerta.pichau => _conteudoPichau(
      widget.detalhe.item as PichauProduto,
    ),
  };

  Widget _conteudoLivelo() {
    final parceiro = widget.detalhe.item as ParceiroCatalogoLivelo;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          context.tokens.spacing.five,
          context.tokens.spacing.two,
          context.tokens.spacing.five,
          context.tokens.spacing.six,
        ),
        child: CartaoCatalogoLivelo(
          parceiro: parceiro.copiarCom(acompanhada: _acompanhado),
          pendente: _salvandoAcompanhamento,
          podeAdministrar: false,
          podeAcompanhar: true,
          atualizadoEm: null,
          aoAlternar: () => unawaited(_alternarAcompanhamento()),
          aoDetalhes: () => unawaited(_abrirCondicoesLivelo(parceiro)),
          aoHistorico: () => unawaited(_abrirHistoricoLivelo(parceiro)),
          aoAbrirLivelo: () => unawaited(_abrirLinkLivelo(parceiro.link)),
        ),
      ),
    );
  }

  Widget _conteudoCashback() {
    final loja = widget.detalhe.item as CashbackInter;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          context.tokens.spacing.five,
          context.tokens.spacing.two,
          context.tokens.spacing.five,
          context.tokens.spacing.six,
        ),
        child: CartaoCashbackInter(
          loja: loja,
          compacto: true,
          acompanhada: _acompanhado,
          alterando: _salvandoAcompanhamento,
          aoAcompanhar: () => unawaited(_alternarAcompanhamento()),
          aoAbrirParceiro: () => unawaited(_abrirLinkInter(loja.link)),
        ),
      ),
    );
  }

  Widget _conteudoProdutoDireto(ProdutoDireto produto) {
    final tokens = context.tokens;
    final cores = tokens.colors;
    final status = produto.statusDisponibilidade;
    final statusFavoravel = status == 'Disponível';
    final metadados = [
      produto.marca,
      produto.categoria,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');
    final cashback = [
      produto.cashbackPercentualTexto,
      produto.cashbackTexto,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');
    return ListView(
      key: const Key('detalhe-alerta-inter-produto'),
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spacing.five,
        tokens.spacing.two,
        tokens.spacing.five,
        tokens.spacing.five,
      ),
      children: [
        _SeloDetalhe(texto: status, favoravel: statusFavoravel),
        SizedBox(height: tokens.spacing.three),
        Text(
          produto.nome,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        if (metadados.isNotEmpty) ...[
          SizedBox(height: tokens.spacing.two),
          Text(
            metadados,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
          ),
        ],
        SizedBox(height: tokens.spacing.five),
        _PainelPrecoDetalhe(
          rotulo: 'Preço de compra',
          precoAtual: produto.precoAtualTexto,
          precoAnterior: produto.precoCheioTexto,
          atualizadoEm: produto.atualizadaEm,
        ),
        SizedBox(height: tokens.spacing.four),
        if (cashback.isNotEmpty)
          _FatoDetalhe(rotulo: 'Cashback', valor: cashback),
        if (produto.precoLiquidoTexto != null)
          _FatoDetalhe(
            rotulo: 'Estimativa após cashback',
            valor: produto.precoLiquidoTexto!,
          ),
        _FatoDetalhe(rotulo: 'Loja', valor: produto.lojaNome),
        SizedBox(height: tokens.spacing.three),
        Text(
          produto.parcelamento == null
              ? 'Parcelamento não informado.'
              : 'Parcelamento disponível: ${produto.parcelamento}.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
        ),
        if (cashback.isNotEmpty) ...[
          SizedBox(height: tokens.spacing.three),
          _AvisoDetalhe(
            titulo: 'Sobre o cashback',
            mensagem:
                'A estimativa após cashback depende das condições e da elegibilidade. O valor cobrado é o preço de compra.',
          ),
        ],
        SizedBox(height: tokens.spacing.five),
        _acoesComHistorico(
          OutlinedButton.icon(
            key: const Key('historico-detalhe-alerta-inter'),
            onPressed: () => unawaited(_abrirHistoricoProduto(produto)),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Histórico'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, tokens.sizes.touchTarget),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spacing.two,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _conteudoPichau(PichauProduto produto) {
    final tokens = context.tokens;
    final cores = tokens.colors;
    final status = produto.statusDisponibilidade;
    final identificador = produto.sku?.trim().isNotEmpty == true
        ? produto.sku!.trim()
        : produto.idExterno;
    final metadados = [
      produto.marca,
      produto.categoria,
    ].whereType<String>().where((texto) => texto.trim().isNotEmpty).join(' · ');
    final fatos = <(String, String)>[
      if (produto.precoCartaoTexto != null)
        ('No cartão', produto.precoCartaoTexto!),
      if (produto.descontoPixTexto != null)
        ('Desconto no Pix', produto.descontoPixTexto!),
    ];
    return ListView(
      key: const Key('detalhe-alerta-pichau'),
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spacing.five,
        tokens.spacing.two,
        tokens.spacing.five,
        tokens.spacing.five,
      ),
      children: [
        _SeloDetalhe(texto: status, favoravel: status == 'Disponível'),
        SizedBox(height: tokens.spacing.three),
        Text(
          produto.nome,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: tokens.spacing.two),
        Text(
          [
            metadados,
            identificador,
          ].where((texto) => texto.trim().isNotEmpty).join(' · '),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
        ),
        SizedBox(height: tokens.spacing.five),
        _PainelPrecoDetalhe(
          rotulo: 'Preço no Pix',
          precoAtual: produto.precoPixTexto,
          precoAnterior: produto.precoOriginalTexto,
          ausencia: 'Preço atual indisponível.',
          atualizadoEm: produto.atualizadoEm,
        ),
        SizedBox(height: tokens.spacing.four),
        for (final (rotulo, valor) in fatos)
          _FatoDetalhe(rotulo: rotulo, valor: valor),
        if (produto.parcelamento?.trim().isNotEmpty == true) ...[
          SizedBox(height: tokens.spacing.three),
          Text(
            produto.parcelamento!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
          ),
        ],
        SizedBox(height: tokens.spacing.five),
        _acoesComHistorico(
          OutlinedButton.icon(
            key: const Key('historico-detalhe-alerta-pichau'),
            onPressed: () => unawaited(_abrirHistoricoPichau(produto)),
            icon: const Icon(Icons.history_rounded),
            label: const Text('Histórico'),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(0, tokens.sizes.touchTarget),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spacing.two,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _botaoAcompanhar() {
    final tokens = context.tokens;
    final cores = tokens.colors;
    return OutlinedButton.icon(
      key: const Key('acompanhar-detalhe-alerta'),
      onPressed: _salvandoAcompanhamento
          ? null
          : () => unawaited(_alternarAcompanhamento()),
      icon: _salvandoAcompanhamento
          ? SizedBox.square(
              dimension: tokens.sizes.icon,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              _acompanhado
                  ? Icons.check_rounded
                  : Icons.notifications_none_rounded,
              size: tokens.sizes.icon,
            ),
      label: Text(
        _salvandoAcompanhamento
            ? 'Salvando…'
            : _acompanhado
            ? 'Acompanhando'
            : 'Acompanhar',
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, tokens.sizes.touchTarget),
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: tokens.spacing.two,
        ),
        foregroundColor: _acompanhado ? cores.acao : cores.texto,
        backgroundColor: _acompanhado ? cores.acaoFundo : Colors.transparent,
        side: BorderSide(
          color: _acompanhado ? Colors.transparent : cores.borda,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tokens.radii.md),
        ),
      ),
    );
  }

  Widget _acoesComHistorico(Widget botaoHistorico) => LayoutBuilder(
    builder: (context, limites) {
      final empilhar =
          limites.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(14) > 17;
      if (empilhar) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _botaoAcompanhar(),
            SizedBox(height: context.tokens.spacing.two),
            botaoHistorico,
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: _botaoAcompanhar()),
          SizedBox(width: context.tokens.spacing.two),
          Expanded(child: botaoHistorico),
        ],
      );
    },
  );

  Widget? _acaoPrincipal() {
    final tokens = context.tokens;
    final (rotulo, link, habilitado) = switch (widget.detalhe.origem) {
      OrigemItemAlerta.interProduto => (
        'Abrir Inter',
        linkSeguroShoppingInter((widget.detalhe.item as ProdutoDireto).caminho),
        (widget.detalhe.item as ProdutoDireto).ativo != false,
      ),
      OrigemItemAlerta.pichau => (
        'Abrir Pichau',
        linkSeguroPichau((widget.detalhe.item as PichauProduto).urlProduto),
        !(widget.detalhe.item as PichauProduto).foraDoCatalogo,
      ),
      _ => ('', null, false),
    };
    if (rotulo.isEmpty) return null;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.four),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('abrir-destino-detalhe-alerta'),
            onPressed: link == null || !habilitado
                ? null
                : () => unawaited(_abrirExterno(link, rotulo)),
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(rotulo),
            style: FilledButton.styleFrom(
              minimumSize: Size(double.infinity, tokens.sizes.touchTarget),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _alternarAcompanhamento() async {
    if (_salvandoAcompanhamento) return;
    final anterior = _acompanhado;
    setState(() {
      _salvandoAcompanhamento = true;
      _acompanhado = !anterior;
    });
    try {
      switch (widget.detalhe.origem) {
        case OrigemItemAlerta.livelo:
          await widget.api.alterarAcompanhamentoPessoalLivelo(
            idExterno:
                (widget.detalhe.item as ParceiroCatalogoLivelo).idExterno,
            ativo: !anterior,
          );
        case OrigemItemAlerta.interCashback:
          await widget.api.alterarAcompanhamentoPessoalCashback(
            id: (widget.detalhe.item as CashbackInter).id,
            ativo: !anterior,
          );
        case OrigemItemAlerta.interProduto:
          final produto = widget.detalhe.item as ProdutoDireto;
          await widget.api.alterarAcompanhamentoProduto(
            loja: produto.lojaSlug,
            idExterno: produto.idExterno,
            ativo: !anterior,
          );
        case OrigemItemAlerta.pichau:
          await widget.api.alterarAcompanhamentoPichau(
            idExterno: (widget.detalhe.item as PichauProduto).idExterno,
            acompanhada: !anterior,
          );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _acompanhado = anterior);
        mostrarMensagemRadar(
          context,
          'Não foi possível salvar o acompanhamento.',
          sucesso: false,
        );
      }
    } finally {
      if (mounted) setState(() => _salvandoAcompanhamento = false);
    }
  }

  Future<void> _abrirHistoricoLivelo(ParceiroCatalogoLivelo parceiro) async {
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.9,
      builder: (_) =>
          PaginaHistoricoLiveloAndroid(api: widget.api, parceiro: parceiro),
    );
  }

  Future<void> _abrirHistoricoProduto(ProdutoDireto produto) async {
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.9,
      builder: (_) => FolhaRadar(
        titulo: 'Histórico de preço',
        descricao: '${produto.nome} · ${produto.lojaNome}',
        child: Flexible(
          child: PaginaHistoricoProduto(api: widget.api, produto: produto),
        ),
      ),
    );
  }

  Future<void> _abrirHistoricoPichau(PichauProduto produto) async {
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.92,
      builder: (_) => FolhaRadar(
        titulo: 'Histórico de preço',
        descricao: '${produto.nome} · Pichau',
        child: Flexible(
          child: PaginaHistoricoPichau(api: widget.api, produto: produto),
        ),
      ),
    );
  }

  Future<void> _abrirCondicoesLivelo(ParceiroCatalogoLivelo parceiro) async {
    final tokens = context.tokens;
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.7,
      builder: (_) => FolhaRadar(
        titulo: 'Condições da oferta',
        descricao: parceiro.nome,
        child: Flexible(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: tokens.spacing.four),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (parceiro.descricaoCampanha?.trim().isNotEmpty == true)
                    Text(parceiro.descricaoCampanha!),
                  if (parceiro.campanha?.trim().isNotEmpty == true) ...[
                    SizedBox(height: tokens.spacing.three),
                    Text('Campanha: ${parceiro.campanha}'),
                  ],
                  if (parceiro.inicioPromocao != null) ...[
                    SizedBox(height: tokens.spacing.two),
                    Text('Início: ${parceiro.inicioPromocao}'),
                  ],
                  if (parceiro.fimPromocao != null) ...[
                    SizedBox(height: tokens.spacing.two),
                    Text('Validade: ${parceiro.fimPromocao}'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _abrirLinkLivelo(String? link) async {
    final uri = Uri.tryParse(link?.trim() ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return;
    await _abrirExterno(uri, 'Livelo');
  }

  Future<void> _abrirLinkInter(String? link) async {
    final uri = linkAbsolutoSeguroShoppingInter(link);
    if (uri == null) return;
    await _abrirExterno(uri, 'Banco Inter');
  }

  Future<void> _abrirExterno(Uri uri, String origem) async {
    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      mostrarMensagemRadar(
        context,
        'Não foi possível abrir $origem.',
        sucesso: false,
      );
    }
  }
}

class _SeloDetalhe extends StatelessWidget {
  const _SeloDetalhe({required this.texto, required this.favoravel});

  final String texto;
  final bool favoravel;

  @override
  Widget build(BuildContext context) {
    final cores = context.tokens.colors;
    final cor = favoravel ? cores.ganho : cores.atencao;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(context.tokens.radii.md),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.tokens.spacing.two,
            vertical: context.tokens.spacing.one,
          ),
          child: Text(
            texto,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PainelPrecoDetalhe extends StatelessWidget {
  const _PainelPrecoDetalhe({
    required this.rotulo,
    required this.precoAtual,
    this.precoAnterior,
    this.atualizadoEm,
    this.ausencia = 'Preço atual não informado.',
  });

  final String rotulo;
  final String? precoAtual;
  final String? precoAnterior;
  final String? atualizadoEm;
  final String ausencia;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tokens = context.tokens;
    final cores = tokens.colors;
    final atual = precoAtual?.trim();
    final anterior = precoAnterior?.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.acaoFundo,
        borderRadius: BorderRadius.circular(tokens.radii.lg),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(tokens.spacing.five),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: tema.textTheme.labelSmall?.copyWith(
                color: cores.textoSuave,
              ),
            ),
            if (anterior != null && anterior.isNotEmpty && anterior != atual)
              Text(
                anterior,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            if (atual == null || atual.isEmpty)
              Text(ausencia, style: tema.textTheme.bodyMedium)
            else
              Text(atual, style: tema.textTheme.precoOferta),
            if (atualizadoEm?.trim().isNotEmpty == true) ...[
              SizedBox(height: tokens.spacing.one),
              Text(
                atualizadoEm!,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: cores.textoSuave,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FatoDetalhe extends StatelessWidget {
  const _FatoDetalhe({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = tokens.colors;
    final tema = Theme.of(context);
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: tokens.spacing.three),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: tema.textTheme.labelLarge?.copyWith(
                color: cores.textoSuave,
              ),
            ),
          ),
          SizedBox(width: tokens.spacing.four),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: tema.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoDetalhe extends StatelessWidget {
  const _AvisoDetalhe({required this.titulo, required this.mensagem});

  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = tokens.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(tokens.radii.md),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(tokens.spacing.three),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, color: cores.textoSuave),
            SizedBox(width: tokens.spacing.two),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.one),
                  Text(mensagem, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
