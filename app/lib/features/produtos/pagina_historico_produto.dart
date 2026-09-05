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
  final _medicoes = <MedicaoProdutoDireto>[];
  HistoricoProdutoDireto? _resumo;
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
      final resposta = await widget.api.historicoProduto(
        loja: widget.produto.lojaSlug,
        produto: widget.produto.idExterno,
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
        _erroMais = null;
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
