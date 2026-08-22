import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../core/api/api_v1.dart';
import '../../core/api/modelos.dart';
import 'formato_produtos.dart';

class PaginaHistoricoProduto extends StatefulWidget {
  const PaginaHistoricoProduto({
    super.key,
    required this.api,
    required this.produto,
  });

  final ApiV1 api;
  final ProdutoDireto produto;

  @override
  State<PaginaHistoricoProduto> createState() =>
      _EstadoPaginaHistoricoProduto();
}

class _EstadoPaginaHistoricoProduto extends State<PaginaHistoricoProduto> {
  final _medicoes = <MedicaoProdutoDireto>[];
  HistoricoProdutoDireto? _resumo;
  Object? _erro;
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
      });
    } catch (erro) {
      if (mounted) setState(() => _erro = erro);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico do produto')),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_carregando) return const Carregando(mensagem: 'Carregando histórico…');
    if (_erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o histórico deste produto.',
        voltar: _carregar,
      );
    }
    final resumo = _resumo!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          resumo.produto.nome,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(resumo.produto.lojaNome),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ResumoValor(
              rotulo: 'Menor em 30 dias',
              valor: valorMonetario(resumo.minimo),
            ),
            _ResumoValor(
              rotulo: 'Maior em 30 dias',
              valor: valorMonetario(resumo.maximo),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Medições', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final medicao in _medicoes)
          Card(
            child: ListTile(
              title: Text(valorMonetario(medicao.precoAtualValor) ?? '—'),
              subtitle: Text(dataHoraProduto(medicao.momento)),
              trailing: medicao.cashbackValor == null
                  ? null
                  : Text('Cashback\n${valorMonetario(medicao.cashbackValor)}'),
            ),
          ),
        if (_carregandoMais)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_temProxima)
          Center(
            child: FilledButton(
              onPressed: () => _carregar(mais: true),
              child: const Text('Carregar mais medições'),
            ),
          ),
      ],
    );
  }
}

class _ResumoValor extends StatelessWidget {
  const _ResumoValor({required this.rotulo, required this.valor});

  final String rotulo;
  final String? valor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo),
        Text(valor ?? '—', style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}
