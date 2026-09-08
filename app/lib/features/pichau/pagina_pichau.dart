import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import 'controlador_catalogo_pichau.dart';
import 'link_pichau.dart';
import 'modelos_pichau.dart';

/// Catálogo interno da Pichau, subordinado a Serviços.
///
/// A tela só renderiza o retrato entregue pela API. Busca e paginação pedem
/// outro recorte desse retrato e nunca iniciam coleta na fonte externa.
class PaginaPichau extends StatefulWidget {
  const PaginaPichau({
    super.key,
    required this.api,
    this.administrador = false,
    this.ativa = true,
  });

  final Api api;
  final bool administrador;
  final bool ativa;

  @override
  State<PaginaPichau> createState() => _EstadoPaginaPichau();
}

class _EstadoPaginaPichau extends State<PaginaPichau> {
  late final ControladorCatalogoPichau _controlador = ControladorCatalogoPichau(
    buscar:
        ({
          required String q,
          required String aba,
          required String disponibilidade,
          required String ordenar,
          required int pagina,
        }) => widget.api.catalogoPichau(
          q: q,
          aba: aba,
          disponibilidade: disponibilidade,
          ordenar: ordenar,
          pagina: pagina,
        ),
    alterarAcompanhamento:
        ({required String idExterno, required bool acompanhada}) =>
            widget.api.alterarAcompanhamentoPichau(
              idExterno: idExterno,
              acompanhada: acompanhada,
            ),
  );
  final _busca = TextEditingController();
  final _rolagem = ScrollController();

  @override
  void initState() {
    super.initState();
    _controlador.carregarInicial();
  }

  @override
  void didUpdateWidget(covariant PaginaPichau antigo) {
    super.didUpdateWidget(antigo);
    if (widget.ativa && !antigo.ativa) {
      _controlador.tentarNovamente();
    }
  }

  @override
  void dispose() {
    _busca.dispose();
    _rolagem.dispose();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    builder: (context, _) => _conteudo(context),
  );

  Widget _conteudo(BuildContext context) {
    final parcial =
        _controlador.qualidade == 'degradada' ||
        _controlador.ultimaTentativaEstado == 'parcial';
    final carregando =
        _controlador.carregandoInicial || _controlador.carregandoMais;
    final itens = _controlador.itens;
    final falha = _controlador.erroInicial != null;
    final falhaComRetrato = falha && itens.isNotEmpty;
    final estado = falha
        ? 'Falha recente'
        : parcial
        ? 'Parcial / atrasado'
        : _controlador.carregandoInicial
        ? 'Carregando'
        : _controlador.totalItens == 0
        ? 'Catálogo vazio'
        : 'Catálogo atualizado';
    return RefreshIndicator(
      onRefresh: _controlador.tentarNovamente,
      child: ListView(
        key: const Key('pagina-pichau'),
        controller: _rolagem,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          const CabecalhoSecaoRadar(
            sobrelinha: 'PC Gamer',
            titulo: 'Pichau',
            descricao:
                'Veja o catálogo salvo de PCs Gamer e abra o produto no site da Pichau.',
          ),
          const SizedBox(height: 22),
          CampoBuscaRadar(
            chaveCampo: const Key('busca-pichau'),
            controlador: _busca,
            dica: 'Buscar por nome, marca ou SKU',
            somenteBusca: true,
            aoMudar: _controlador.mudarBusca,
          ),
          const SizedBox(height: 12),
          AbasRadar(
            key: const Key('abas-pichau'),
            rotulos: AbaCatalogoPichau.values.map((aba) => aba.rotulo).toList(),
            contadores: [
              _controlador.resumo?.totalCatalogo ?? 0,
              _controlador.resumo?.acompanhadas ?? 0,
            ],
            expandir: true,
            selecionada: _controlador.aba.index,
            aoSelecionar: (indice) =>
                _controlador.mudarAba(AbaCatalogoPichau.values[indice]),
          ),
          const SizedBox(height: 4),
          _BarraCatalogoPichau(
            total: _controlador.totalItens,
            acompanhadas: _controlador.aba == AbaCatalogoPichau.acompanhadas,
            estado: estado,
            carregando: carregando,
            filtroAtivo:
                _controlador.disponibilidade != DisponibilidadePichau.todas ||
                _controlador.ordenacao != OrdenacaoPichau.nome,
            aoFiltrar: _abrirFiltros,
          ),
          if (parcial || falhaComRetrato) ...[
            const SizedBox(height: 12),
            _AvisoQualidadePichau(falha: falhaComRetrato),
          ],
          if (_controlador.carregandoInicial && itens.isEmpty) ...[
            const SizedBox(height: 22),
            const SizedBox(
              height: 180,
              child: Carregando(mensagem: 'Carregando catálogo Pichau…'),
            ),
          ] else if (falha && itens.isEmpty) ...[
            const SizedBox(height: 12),
            EstadoFalha(
              mensagem: 'Não foi possível carregar o catálogo Pichau.',
              voltar: _controlador.tentarNovamente,
            ),
          ] else if (itens.isEmpty) ...[
            const SizedBox(height: 12),
            EstadoVazio(
              mensagem: _controlador.aba == AbaCatalogoPichau.acompanhadas
                  ? 'Nenhum PC Gamer está acompanhado ainda.'
                  : _controlador.busca.trim().isNotEmpty ||
                        _controlador.disponibilidade !=
                            DisponibilidadePichau.todas
                  ? 'Nenhum PC Gamer corresponde aos filtros atuais.'
                  : 'Nenhum PC Gamer foi encontrado na última coleta completa.',
            ),
          ] else ...[
            const SizedBox(height: 12),
            for (final produto in itens) ...[
              CartaoPichau(
                produto: produto,
                podeAdministrar: widget.administrador,
                alterando: _controlador.mutacoesPendentes.contains(
                  produto.idExterno,
                ),
                aoAlternarAcompanhamento: () =>
                    _alternarAcompanhamento(produto),
                aoAbrirHistorico: () => _abrirHistorico(produto),
                aoAbrirNoSite: _acaoAbrirProduto(produto),
              ),
              if (produto != itens.last) const SizedBox(height: 10),
            ],
            if (carregando)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 17),
            PaginacaoRadar(
              pagina: _controlador.pagina,
              totalItens: _controlador.totalItens,
              porPagina: _controlador.porPagina,
              carregando: _controlador.carregandoMais,
              erro: _controlador.erroMais,
              aoIrParaPagina: _irParaPagina,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _irParaPagina(int pagina) async {
    await _controlador.irParaPagina(pagina);
    if (mounted && _controlador.pagina == pagina) {
      await rolarParaInicioPaginaRadar(_rolagem);
    }
  }

  Future<void> _alternarAcompanhamento(PichauProduto produto) async {
    final acompanhada = !produto.acompanhada;
    final sucesso = await _controlador.alternarAcompanhamento(produto);
    if (!mounted) return;
    mostrarMensagemRadar(
      context,
      sucesso
          ? acompanhada
                ? 'Produto adicionado às acompanhadas.'
                : 'Produto removido das acompanhadas.'
          : 'Não foi possível salvar o acompanhamento.',
      sucesso: sucesso,
    );
  }

  Future<void> _abrirFiltros() async {
    var disponibilidade = _controlador.disponibilidade;
    var ordenacao = _controlador.ordenacao;
    await mostrarFolhaRadar<void>(
      context,
      builder: (contexto) => StatefulBuilder(
        builder: (contexto, atualizar) => FolhaRadar(
          titulo: 'Filtrar catálogo Pichau',
          descricao: 'Refine as ofertas salvas de PC Gamer',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<DisponibilidadePichau>(
                key: const Key('filtro-disponibilidade-pichau'),
                initialValue: disponibilidade,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Disponibilidade'),
                items: [
                  for (final valor in DisponibilidadePichau.values)
                    DropdownMenuItem(value: valor, child: Text(valor.rotulo)),
                ],
                onChanged: (valor) => atualizar(() {
                  if (valor != null) disponibilidade = valor;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OrdenacaoPichau>(
                key: const Key('filtro-ordenacao-pichau'),
                initialValue: ordenacao,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Ordenar por'),
                items: [
                  for (final valor in OrdenacaoPichau.values)
                    DropdownMenuItem(value: valor, child: Text(valor.rotulo)),
                ],
                onChanged: (valor) => atualizar(() {
                  if (valor != null) ordenacao = valor;
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(contexto).pop();
                        _controlador.aplicarFiltros(
                          disponibilidade: DisponibilidadePichau.todas,
                          ordenacao: OrdenacaoPichau.nome,
                        );
                      },
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(contexto).pop();
                        _controlador.aplicarFiltros(
                          disponibilidade: disponibilidade,
                          ordenacao: ordenacao,
                        );
                      },
                      child: const Text('Ver ofertas'),
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

  VoidCallback? _acaoAbrirProduto(PichauProduto produto) {
    final link = linkSeguroPichau(produto.urlProduto);
    if (link == null) return null;
    return () => _abrirProduto(link);
  }

  Future<void> _abrirProduto(Uri link) async {
    final abriu = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      mostrarMensagemRadar(
        context,
        'Não foi possível abrir a Pichau.',
        sucesso: false,
      );
    }
  }

  Future<void> _abrirHistorico(PichauProduto produto) async {
    await mostrarFolhaRadar<void>(
      context,
      alturaMaxima: 0.9,
      builder: (contexto) => FolhaRadar(
        titulo: 'Histórico de preço',
        descricao: '${produto.nome} · Pichau',
        child: Flexible(
          child: PaginaHistoricoPichau(api: widget.api, produto: produto),
        ),
      ),
    );
  }
}

class CartaoPichau extends StatelessWidget {
  const CartaoPichau({
    super.key,
    required this.produto,
    required this.aoAbrirHistorico,
    this.podeAdministrar = false,
    this.alterando = false,
    this.aoAlternarAcompanhamento,
    this.aoAbrirNoSite,
  });

  final PichauProduto produto;
  final VoidCallback aoAbrirHistorico;
  final bool podeAdministrar;
  final bool alterando;
  final VoidCallback? aoAlternarAcompanhamento;
  final VoidCallback? aoAbrirNoSite;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final tema = Theme.of(context);
    final estadoTom = produto.foraDoCatalogo || produto.esgotado
        ? TomRadar.atencao
        : TomRadar.ganho;
    final estadoTexto = produto.foraDoCatalogo
        ? 'Fora do catálogo'
        : produto.esgotado
        ? 'Esgotado'
        : 'Disponível';

    return Semantics(
      label: 'PC Gamer ${produto.nome}, origem Pichau',
      child: CartaoRadar(
        padding: EdgeInsets.zero,
        corDestaque: produto.foraDoCatalogo || produto.esgotado
            ? cores.atencao
            : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        _EtiquetaPichau(texto: produto.categoria ?? 'PC Gamer'),
                        const _EtiquetaPichau(texto: 'Pichau', plum: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _EtiquetaPichau(texto: 'Origem Pichau', neutra: true),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                produto.nome,
                style: tema.textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.35,
                ),
              ),
              if (produto.marca != null || produto.idExterno.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [
                      if (produto.marca != null) 'Marca: ${produto.marca}',
                      if (produto.idExterno.isNotEmpty)
                        'SKU: ${produto.idExterno}',
                    ].join(' · '),
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: cores.textoSuave,
                      fontSize: 9,
                    ),
                  ),
                ),
              const SizedBox(height: 11),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PrecoPichau(
                      rotulo: 'Preço Pix',
                      valor: produto.precoPixTexto,
                      complemento: [
                        produto.precoOriginalTexto == null
                            ? null
                            : 'De ${produto.precoOriginalTexto}',
                        produto.descontoPixTexto,
                      ].whereType<String>().join(' · '),
                      destaque: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PrecoPichau(
                      rotulo: 'Preço no cartão',
                      valor: produto.precoCartaoTexto,
                      complemento: produto.parcelamento ?? '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 9,
                runSpacing: 5,
                children: [
                  IndicadorEstadoRadar(texto: estadoTexto, tom: estadoTom),
                  if (produto.semJuros == true)
                    const _MetaPichau(texto: 'Sem juros'),
                  for (final etiqueta in produto.etiquetas)
                    _MetaPichau(texto: etiqueta, acao: true),
                ],
              ),
              const SizedBox(height: 11),
              OutlinedButton(
                key: Key('acompanhar-pichau-${produto.idExterno}'),
                onPressed: podeAdministrar && !alterando
                    ? aoAlternarAcompanhamento
                    : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(41),
                  foregroundColor: produto.acompanhada
                      ? cores.ganho
                      : cores.acao,
                  backgroundColor: produto.acompanhada
                      ? cores.ganho.withValues(alpha: 0.12)
                      : cores.acao.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: produto.acompanhada ? cores.ganho : cores.acao,
                  ),
                ),
                child: alterando
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        produto.acompanhada ? 'Acompanhando' : 'Acompanhar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              if (!podeAdministrar)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    'Acompanhamento exige autorização administrativa.',
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: cores.textoSuave,
                      fontSize: 9,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: Key('historico-pichau-${produto.idExterno}'),
                      onPressed: aoAbrirHistorico,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        'Histórico',
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: Key('abrir-pichau-${produto.idExterno}'),
                      onPressed: aoAbrirNoSite,
                      child: const Text('Ver na Pichau'),
                    ),
                  ),
                ],
              ),
              if (aoAbrirNoSite == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'URL do produto não informada.',
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: cores.textoSuave,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtiquetaPichau extends StatelessWidget {
  const _EtiquetaPichau({
    required this.texto,
    this.plum = false,
    this.neutra = false,
  });

  final String texto;
  final bool plum;
  final bool neutra;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final fundo = neutra
        ? cores.superficieAlternativa
        : plum
        ? (Theme.of(context).brightness == Brightness.dark
              ? Tokens.superficieForteEscura
              : Tokens.plumSoft)
        : (Theme.of(context).brightness == Brightness.dark
              ? Tokens.acaoFundoEscuro
              : Tokens.actionSoft);
    final textoCor = neutra
        ? cores.textoSuave
        : plum
        ? cores.marca
        : cores.acao;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          texto,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textoCor,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PrecoPichau extends StatelessWidget {
  const _PrecoPichau({
    required this.rotulo,
    required this.valor,
    required this.complemento,
    this.destaque = false,
  });

  final String rotulo;
  final String? valor;
  final String complemento;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final cor = destaque
        ? cores.ganho
        : Theme.of(context).colorScheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: destaque
            ? cores.ganho.withValues(alpha: 0.14)
            : cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rotulo,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: destaque
                    ? cor.withValues(alpha: 0.84)
                    : cores.textoSuave,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              valor ?? 'Não informado',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (complemento.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  complemento,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: destaque
                        ? cor.withValues(alpha: 0.82)
                        : cores.textoSuave,
                    fontSize: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetaPichau extends StatelessWidget {
  const _MetaPichau({required this.texto, this.acao = false});

  final String texto;
  final bool acao;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final cor = acao ? cores.acao : cores.textoSuave;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 4),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: cor, fontSize: 8),
        ),
      ],
    );
  }
}

class _BarraCatalogoPichau extends StatelessWidget {
  const _BarraCatalogoPichau({
    required this.total,
    required this.acompanhadas,
    required this.estado,
    required this.carregando,
    required this.filtroAtivo,
    required this.aoFiltrar,
  });

  final int total;
  final bool acompanhadas;
  final String estado;
  final bool carregando;
  final bool filtroAtivo;
  final VoidCallback aoFiltrar;

  @override
  Widget build(BuildContext context) {
    final totalTexto = total == 1
        ? '1 oferta encontrada'
        : '$total ofertas encontradas';
    final tom = estado == 'Catálogo atualizado'
        ? TomRadar.ganho
        : estado == 'Parcial / atrasado' || estado == 'Falha recente'
        ? TomRadar.atencao
        : TomRadar.neutro;
    final resumo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          totalTexto,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 3),
        Text(
          acompanhadas
              ? 'Produtos acompanhados'
              : 'Catálogo completo · última coleta válida',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 9,
          ),
        ),
      ],
    );
    final filtro = OutlinedButton.icon(
      key: const Key('filtrar-ordenar-pichau'),
      onPressed: aoFiltrar,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 38),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        backgroundColor: filtroAtivo
            ? CoresRadar.de(context).acao.withValues(alpha: 0.1)
            : null,
      ),
      icon: const Icon(Icons.filter_list_rounded, size: 17),
      label: const Text('Filtrar e ordenar'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, limites) {
            if (limites.maxWidth < 350) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [resumo, const SizedBox(height: 8), filtro],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: resumo),
                const SizedBox(width: 8),
                filtro,
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: IndicadorEstadoRadar(
            texto: carregando && total > 0 ? 'Atualizando' : estado,
            tom: carregando && total > 0 ? TomRadar.acao : tom,
          ),
        ),
      ],
    );
  }
}

class _AvisoQualidadePichau extends StatelessWidget {
  const _AvisoQualidadePichau({required this.falha});

  final bool falha;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cores.atencao.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 17, color: cores.atencao),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                falha
                    ? 'A última tentativa da Pichau falhou. Mantivemos o último catálogo válido.'
                    : 'A coleta da Pichau está parcial ou atrasada. O último catálogo válido continua disponível.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cores.atencao,
                  fontSize: 10,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaginaHistoricoPichau extends StatefulWidget {
  const PaginaHistoricoPichau({
    super.key,
    required this.api,
    required this.produto,
  });

  final Api api;
  final PichauProduto produto;

  @override
  State<PaginaHistoricoPichau> createState() => _EstadoPaginaHistoricoPichau();
}

class _EstadoPaginaHistoricoPichau extends State<PaginaHistoricoPichau> {
  final _medicoes = <MedicaoPichau>[];
  HistoricoPichau? _resumo;
  Object? _erro;
  Object? _erroMais;
  var _carregando = true;
  var _carregandoMais = false;
  var _pagina = 0;
  var _temProxima = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool mais = false}) async {
    if (mais && (_carregandoMais || !_temProxima)) return;
    setState(() {
      if (mais) {
        _carregandoMais = true;
        _erroMais = null;
      } else {
        _carregando = true;
        _erro = null;
      }
    });
    try {
      final resposta = await widget.api.historicoPichau(
        idExterno: widget.produto.idExterno,
        pagina: mais ? _pagina + 1 : 1,
      );
      if (!mounted) return;
      setState(() {
        _resumo = resposta;
        if (mais) {
          _medicoes.addAll(resposta.medicoes);
        } else {
          _medicoes
            ..clear()
            ..addAll(resposta.medicoes);
        }
        _pagina = resposta.pagina;
        _temProxima = resposta.temProxima;
      });
    } catch (erro) {
      if (mounted) {
        setState(() {
          if (mais) {
            _erroMais = erro;
          } else {
            _erro = erro;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
          _carregandoMais = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const SizedBox(
        height: 180,
        child: Carregando(mensagem: 'Carregando histórico…'),
      );
    }
    if (_erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o histórico deste PC.',
        voltar: _carregar,
      );
    }

    final resumo = _resumo!;
    return ListView(
      key: const Key('historico-pichau-conteudo'),
      padding: const EdgeInsets.fromLTRB(1, 0, 1, 12),
      children: [
        if (resumo.minimoPixTexto != null || resumo.maximoPixTexto != null)
          _ResumoHistoricoPichau(
            minimo: resumo.minimoPixTexto,
            maximo: resumo.maximoPixTexto,
          ),
        const SizedBox(height: 10),
        Text(
          '${resumo.totalItens} ${resumo.totalItens == 1 ? 'medição' : 'medições'} nos últimos 30 dias',
          style: TextStyle(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_medicoes.isEmpty)
          const EstadoVazio(mensagem: 'Nenhuma medição de preço disponível.')
        else
          for (final medicao in _medicoes)
            _LinhaHistoricoPichau(medicao: medicao),
        const SizedBox(height: 10),
        Text(
          'O histórico é paginado e limitado à janela de 30 dias.',
          style: TextStyle(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        if (_carregandoMais)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_erroMais != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: FilledButton.tonal(
                onPressed: () => _carregar(mais: true),
                child: const Text('Tentar carregar mais medições'),
              ),
            ),
          )
        else if (_temProxima)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: OutlinedButton(
                onPressed: () => _carregar(mais: true),
                child: const Text('Carregar mais medições'),
              ),
            ),
          ),
      ],
    );
  }
}

class _LinhaHistoricoPichau extends StatelessWidget {
  const _LinhaHistoricoPichau({required this.medicao});

  final MedicaoPichau medicao;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cores.borda)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _momentoPichau(medicao.momento),
            style: TextStyle(
              color: cores.textoSuave,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          _MetricaPichau(
            rotulo: 'Preço Pix',
            valor: medicao.precoPixTexto ?? 'Não informado',
            cor: medicao.precoPixTexto == null ? cores.textoSuave : cores.ganho,
          ),
          const SizedBox(height: 4),
          _MetricaPichau(
            rotulo: 'Preço no cartão',
            valor: medicao.precoCartaoTexto ?? 'Não informado',
            cor: medicao.precoCartaoTexto == null
                ? cores.textoSuave
                : Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}

class _MetricaPichau extends StatelessWidget {
  const _MetricaPichau({
    required this.rotulo,
    required this.valor,
    required this.cor,
  });

  final String rotulo;
  final String valor;
  final Color cor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          rotulo,
          style: TextStyle(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 10,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(
        valor,
        textAlign: TextAlign.right,
        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _ResumoHistoricoPichau extends StatelessWidget {
  const _ResumoHistoricoPichau({required this.minimo, required this.maximo});

  final String? minimo;
  final String? maximo;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CoresRadar.de(context).superficieAlternativa,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _MetricaPichau(
              rotulo: 'Mínimo Pix',
              valor: minimo ?? 'Não informado',
              cor: CoresRadar.de(context).ganho,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricaPichau(
              rotulo: 'Máximo Pix',
              valor: maximo ?? 'Não informado',
              cor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}

String _momentoPichau(String? valor) {
  final data = DateTime.tryParse(valor ?? '')?.toLocal();
  if (data == null) {
    return valor?.trim().isNotEmpty == true ? valor! : 'Momento não informado';
  }
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  final hora = data.hour.toString().padLeft(2, '0');
  final minuto = data.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${data.year} · $hora:$minuto';
}
