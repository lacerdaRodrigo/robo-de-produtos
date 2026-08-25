import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/modelos.dart';
import '../../core/api/pagina.dart';

enum OrdenacaoCashbackInter {
  cashback('cashback', 'Maior cashback'),
  nome('nome', 'Nome A–Z');

  const OrdenacaoCashbackInter(this.codigo, this.rotulo);
  final String codigo;
  final String rotulo;
}

typedef BuscarCashbackInter =
    Future<Pagina<CashbackInter>> Function({
      required String q,
      required String ordenar,
      required int pagina,
    });

class ControladorCashbackInter extends ChangeNotifier {
  ControladorCashbackInter({
    required this.buscar,
    this.debounce = const Duration(milliseconds: 350),
  });

  final BuscarCashbackInter buscar;
  final Duration debounce;
  Timer? _temporizador;
  var _versao = 0;
  var _descartado = false;
  final _itens = <CashbackInter>[];
  final _ids = <String>{};
  String _busca = '';
  OrdenacaoCashbackInter _ordenacao = OrdenacaoCashbackInter.cashback;
  String? _atualizadoEm;
  String? _ultimaTentativaEm;
  String? _ultimaTentativaEstado;
  int _totalItens = 0;
  int _pagina = 0;
  bool _temProxima = false;
  bool _carregando = false;
  bool _carregandoMais = false;
  Object? _erro;
  Object? _erroMais;

  List<CashbackInter> get itens => List.unmodifiable(_itens);
  String get busca => _busca;
  OrdenacaoCashbackInter get ordenacao => _ordenacao;
  String? get atualizadoEm => _atualizadoEm;
  String? get ultimaTentativaEm => _ultimaTentativaEm;
  String? get ultimaTentativaEstado => _ultimaTentativaEstado;
  bool get ultimaTentativaFalhou => _ultimaTentativaEstado == 'falha';
  int get totalItens => _totalItens;
  bool get temProxima => _temProxima;
  bool get carregando => _carregando;
  bool get carregandoMais => _carregandoMais;
  Object? get erro => _erro;
  Object? get erroMais => _erroMais;

  Future<void> carregarInicial() => _reiniciar();

  void mudarBusca(String valor) {
    if (valor == _busca) return;
    _busca = valor;
    _limpar();
    _temporizador = Timer(debounce, _primeiraPagina);
  }

  Future<void> mudarOrdenacao(OrdenacaoCashbackInter valor) async {
    if (valor == _ordenacao) return;
    _ordenacao = valor;
    await _reiniciar();
  }

  Future<void> tentarNovamente() => _reiniciar();

  Future<void> carregarMais() async {
    if (_carregando || _carregandoMais || !_temProxima) return;
    final versao = _versao;
    _carregandoMais = true;
    _erroMais = null;
    notifyListeners();
    try {
      final resposta = await buscar(
        q: _busca,
        ordenar: _ordenacao.codigo,
        pagina: _pagina + 1,
      );
      if (_ativa(versao)) _aplicar(resposta);
    } catch (erro) {
      if (_ativa(versao)) _erroMais = erro;
    } finally {
      if (_ativa(versao)) {
        _carregandoMais = false;
        notifyListeners();
      }
    }
  }

  Future<void> _reiniciar() async {
    _temporizador?.cancel();
    _limpar();
    await _primeiraPagina();
  }

  void _limpar() {
    _temporizador?.cancel();
    _versao++;
    _itens.clear();
    _ids.clear();
    _atualizadoEm = null;
    _ultimaTentativaEm = null;
    _ultimaTentativaEstado = null;
    _totalItens = 0;
    _pagina = 0;
    _temProxima = false;
    _carregando = true;
    _carregandoMais = false;
    _erro = null;
    _erroMais = null;
    notifyListeners();
  }

  Future<void> _primeiraPagina() async {
    final versao = _versao;
    try {
      final resposta = await buscar(
        q: _busca,
        ordenar: _ordenacao.codigo,
        pagina: 1,
      );
      if (_ativa(versao)) _aplicar(resposta);
    } catch (erro) {
      if (_ativa(versao)) _erro = erro;
    } finally {
      if (_ativa(versao)) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  void _aplicar(Pagina<CashbackInter> resposta) {
    for (final item in resposta.itens) {
      final chave = item.id.isNotEmpty ? item.id : item.slug;
      if (chave.isNotEmpty && _ids.add(chave)) _itens.add(item);
    }
    _pagina = resposta.pagina;
    _totalItens = resposta.totalItens;
    _temProxima = resposta.temProxima;
    _atualizadoEm = resposta.atualizadoEm;
    _ultimaTentativaEm = resposta.ultimaTentativaEm;
    _ultimaTentativaEstado = resposta.ultimaTentativaEstado;
    _erroMais = null;
  }

  bool _ativa(int versao) => !_descartado && versao == _versao;

  @override
  void dispose() {
    _descartado = true;
    _temporizador?.cancel();
    super.dispose();
  }
}
