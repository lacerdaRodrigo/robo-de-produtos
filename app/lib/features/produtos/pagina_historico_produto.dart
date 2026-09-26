import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import 'formato_produtos.dart';

class PaginaHistoricoProduto extends StatefulWidget {
  const PaginaHistoricoProduto({
    super.key,
    required this.api,
    required this.produto,
  });

  final Api api;
  final ProdutoDireto produto;

  @override
  State<PaginaHistoricoProduto> createState() =>
      _EstadoPaginaHistoricoProduto();
}

class _EstadoPaginaHistoricoProduto extends State<PaginaHistoricoProduto> {
  static const _itensPorPagina = 5;

  final _medicoes = <MedicaoProdutoDireto>[];
  HistoricoProdutoDireto? _resumo;
  Object? _erro;
  Object? _erroPagina;
  var _carregando = true;
  var _carregandoPagina = false;
  var _pagina = 1;
  var _paginaComErro = 1;

  int get _totalPaginas {
    final resumo = _resumo;
    if (resumo == null || resumo.totalItens == 0) return 1;
    final porPagina = resumo.porPagina > 0 ? resumo.porPagina : _itensPorPagina;
    return (resumo.totalItens + porPagina - 1) ~/ porPagina;
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({int pagina = 1}) async {
    if (_carregandoPagina) return;
    final inicial = _resumo == null;
    setState(() {
      if (inicial) {
        _carregando = true;
        _erro = null;
      } else {
        _carregandoPagina = true;
        _erroPagina = null;
        _paginaComErro = pagina;
      }
    });
    try {
      final resposta = await widget.api.historicoProduto(
        loja: widget.produto.lojaSlug,
        produto: widget.produto.idExterno,
        pagina: pagina,
        porPagina: _itensPorPagina,
      );
      if (!mounted) return;
      setState(() {
        _resumo = resposta;
        _medicoes
          ..clear()
          ..addAll(resposta.medicoes);
        _pagina = resposta.pagina;
        _erroPagina = null;
      });
    } catch (erro) {
      if (mounted) {
        setState(() {
          if (inicial) {
            _erro = erro;
          } else {
            _erroPagina = erro;
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          if (inicial) {
            _carregando = false;
          } else {
            _carregandoPagina = false;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => _corpo();

  Widget _corpo() {
    if (_carregando) {
      return const SizedBox(
        height: 180,
        child: Carregando(mensagem: 'Carregando histórico…'),
      );
    }
    if (_erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o histórico deste produto.',
        voltar: _carregar,
      );
    }

    final resumo = _resumo!;
    return ListView(
      key: const Key('historico-produto-conteudo'),
      padding: const EdgeInsets.fromLTRB(1, 0, 1, 12),
      children: [
        if (resumo.produto.ativo == false) ...[
          const _BlocoInformativo(),
          const SizedBox(height: 8),
        ],
        if (resumo.minimo != null || resumo.maximo != null) ...[
          _ResumoHistorico(minimo: resumo.minimo, maximo: resumo.maximo),
          const SizedBox(height: 10),
        ],
        Text(
          '${resumo.totalItens} ${resumo.totalItens == 1 ? 'medição' : 'medições'} '
          'nos últimos 30 dias',
          style: TextStyle(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_medicoes.isEmpty)
          const _HistoricoVazio()
        else ...[
          for (final medicao in _medicoes)
            _LinhaHistorico(
              rotulo: dataHistoricoProduto(medicao.momento),
              valor: valorMonetario(medicao.precoAtualValor) ?? '—',
              detalheRotulo: 'Cashback',
              detalheValor: valorMonetario(medicao.cashbackValor),
              detalheSecundarioRotulo: 'Após cashback',
              detalheSecundarioValor: valorMonetario(medicao.precoLiquidoValor),
            ),
        ],
        const SizedBox(height: 10),
        Text(
          'O histórico é paginado e limitado à janela de 30 dias.',
          style: TextStyle(
            color: CoresRadar.de(context).textoSuave,
            fontSize: 12,
            height: 1.45,
          ),
        ),
        if (_erroPagina != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: FilledButton.tonal(
                onPressed: () => _carregar(pagina: _paginaComErro),
                child: const Text('Tentar carregar esta página'),
              ),
            ),
          ),
        if (_totalPaginas > 1) ...[
          const SizedBox(height: 10),
          _PaginacaoHistoricoProduto(
            pagina: _pagina,
            totalPaginas: _totalPaginas,
            carregando: _carregandoPagina,
            aoIrParaPagina: (pagina) => _carregar(pagina: pagina),
          ),
        ],
      ],
    );
  }
}

class _LinhaHistorico extends StatelessWidget {
  const _LinhaHistorico({
    required this.rotulo,
    required this.valor,
    this.detalheRotulo,
    this.detalheValor,
    this.detalheSecundarioRotulo,
    this.detalheSecundarioValor,
  });

  final String rotulo;
  final String valor;
  final String? detalheRotulo;
  final String? detalheValor;
  final String? detalheSecundarioRotulo;
  final String? detalheSecundarioValor;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cores.borda)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              color: cores.textoSuave,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          _MetricaHistorico(
            rotulo: 'Preço atual',
            valor: valor,
            cor: Theme.of(context).colorScheme.onSurface,
          ),
          if (detalheRotulo != null) ...[
            const SizedBox(height: 4),
            _MetricaHistorico(
              rotulo: detalheRotulo!,
              valor: detalheValor ?? 'Não informado',
              cor: detalheValor == null ? cores.textoSuave : cores.ganho,
            ),
          ],
          if (detalheSecundarioRotulo != null) ...[
            const SizedBox(height: 4),
            _MetricaHistorico(
              rotulo: detalheSecundarioRotulo!,
              valor: detalheSecundarioValor ?? 'Não informado',
              cor: detalheSecundarioValor == null
                  ? cores.textoSuave
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricaHistorico extends StatelessWidget {
  const _MetricaHistorico({
    required this.rotulo,
    required this.valor,
    required this.cor,
  });

  final String rotulo;
  final String valor;
  final Color cor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
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

class _PaginacaoHistoricoProduto extends StatelessWidget {
  const _PaginacaoHistoricoProduto({
    required this.pagina,
    required this.totalPaginas,
    required this.carregando,
    required this.aoIrParaPagina,
  });

  final int pagina;
  final int totalPaginas;
  final bool carregando;
  final Future<void> Function(int pagina) aoIrParaPagina;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    final anterior = pagina > 1;
    final proxima = pagina < totalPaginas;
    return Semantics(
      label: 'Paginação do histórico, página $pagina de $totalPaginas',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _botao(
            context,
            key: const Key('historico-pagina-anterior'),
            tooltip: 'Página anterior',
            icone: Icons.arrow_back,
            habilitado: anterior,
            aoTocar: () => aoIrParaPagina(pagina - 1),
          ),
          SizedBox(width: tokens.spacing.four),
          Text(
            '$pagina de $totalPaginas',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SizedBox(width: tokens.spacing.four),
          _botao(
            context,
            key: const Key('historico-pagina-proxima'),
            tooltip: 'Próxima página',
            icone: Icons.arrow_forward,
            habilitado: proxima,
            aoTocar: () => aoIrParaPagina(pagina + 1),
          ),
          if (carregando) ...[
            SizedBox(width: tokens.spacing.two),
            SizedBox(
              width: tokens.sizes.icon,
              height: tokens.sizes.icon,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cores.acao,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _botao(
    BuildContext context, {
    required Key key,
    required String tooltip,
    required IconData icone,
    required bool habilitado,
    required VoidCallback aoTocar,
  }) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    return IconButton(
      key: key,
      tooltip: tooltip,
      onPressed: habilitado && !carregando ? aoTocar : null,
      icon: Icon(icone),
      style: IconButton.styleFrom(
        minimumSize: Size.square(tokens.sizes.touchTarget),
        maximumSize: Size.square(tokens.sizes.touchTarget),
        foregroundColor: cores.textoSuave,
        side: BorderSide(color: cores.borda),
        shape: const CircleBorder(),
      ),
    );
  }
}

class _ResumoHistorico extends StatelessWidget {
  const _ResumoHistorico({required this.minimo, required this.maximo});

  final String? minimo;
  final String? maximo;

  @override
  Widget build(BuildContext context) {
    final itens = <Widget>[
      if (minimo != null)
        Expanded(
          child: _DestaqueHistorico(
            rotulo: 'Mínimo no contrato',
            valor: valorMonetario(minimo) ?? '—',
          ),
        ),
      if (minimo != null && maximo != null) const SizedBox(width: 8),
      if (maximo != null)
        Expanded(
          child: _DestaqueHistorico(
            rotulo: 'Máximo no contrato',
            valor: valorMonetario(maximo) ?? '—',
          ),
        ),
    ];
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: itens);
  }
}

class _DestaqueHistorico extends StatelessWidget {
  const _DestaqueHistorico({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        border: Border.all(color: cores.borda),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rotulo,
            style: TextStyle(
              color: cores.textoSuave,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _BlocoInformativo extends StatelessWidget {
  const _BlocoInformativo();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: CoresRadar.de(context).superficieAlternativa,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oferta não está mais ativa',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 2),
        Text('O histórico de preços continua disponível.'),
      ],
    ),
  );
}

class _HistoricoVazio extends StatelessWidget {
  const _HistoricoVazio();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Text(
      'Nenhuma medição disponível nos últimos 30 dias.',
      style: TextStyle(color: CoresRadar.de(context).textoSuave, fontSize: 12),
    ),
  );
}
