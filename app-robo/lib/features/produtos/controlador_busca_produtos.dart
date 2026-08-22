import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/modelos.dart';
import '../../core/api/pagina.dart';

class FiltrosProdutos {
  const FiltrosProdutos({
    this.marca = '',
    this.categoria = '',
    this.loja = '',
    this.precoMin = '',
    this.precoMax = '',
  });

  final String marca;
  final String categoria;
  final String loja;
  final String precoMin;
  final String precoMax;

  FiltrosProdutos copiarCom({
    String? marca,
    String? categoria,
    String? loja,
    String? precoMin,
    String? precoMax,
  }) => FiltrosProdutos(
    marca: marca ?? this.marca,
    categoria: categoria ?? this.categoria,
    loja: loja ?? this.loja,
    precoMin: precoMin ?? this.precoMin,
    precoMax: precoMax ?? this.precoMax,
  );

  String? _opcional(String valor) {
    final limpo = valor.trim();
    return limpo.isEmpty ? null : limpo;
  }

  String? get marcaOpcional => _opcional(marca);
  String? get categoriaOpcional => _opcional(categoria);
  String? get lojaOpcional => _opcional(loja);
  String? get precoMinOpcional => _opcional(precoMin);
  String? get precoMaxOpcional => _opcional(precoMax);

  bool get estaVazio =>
      marcaOpcional == null &&
      categoriaOpcional == null &&
      lojaOpcional == null &&
      precoMinOpcional == null &&
      precoMaxOpcional == null;
}

typedef BuscarProdutos =
    Future<Pagina<ProdutoDireto>> Function({
      required String termo,
      required int pagina,
      String? marca,
      String? categoria,
      String? loja,
      String? precoMin,
      String? precoMax,
    });

/// Estado paginado da busca local de produtos (PRD-V4 RF43/RN70/RN71).
class ControladorBuscaProdutos extends ChangeNotifier {
  ControladorBuscaProdutos({
    required this.buscar,
    this.debounce = const Duration(milliseconds: 350),
  });

  final BuscarProdutos buscar;
  final Duration debounce;
  final _itens = <ProdutoDireto>[];
  final _ids = <String>{};
  Timer? _temporizador;
  var _versao = 0;
  var _descartado = false;
  String _termo = '';
  FiltrosProdutos _filtros = const FiltrosProdutos();
  int _pagina = 0;
  int _totalItens = 0;
  bool _temProxima = false;
  bool _carregando = false;
  bool _carregandoMais = false;
  String? _atualizadoEm;
  String? _qualidade;
  Object? _erro;
  Object? _erroMais;

  List<ProdutoDireto> get itens => List.unmodifiable(_itens);
  String get termo => _termo;
  FiltrosProdutos get filtros => _filtros;
  int get totalItens => _totalItens;
  bool get temProxima => _temProxima;
  bool get carregando => _carregando;
  bool get carregandoMais => _carregandoMais;
  String? get atualizadoEm => _atualizadoEm;
  String? get qualidade => _qualidade;
  Object? get erro => _erro;
  Object? get erroMais => _erroMais;
  bool get termoValido => _termo.trim().length >= 2;

  void mudarTermo(String valor) {
    if (valor == _termo) return;
    _termo = valor;
    _reiniciar(adiar: true);
  }

  void mudarFiltros(FiltrosProdutos valor) {
    _filtros = valor;
    _reiniciar();
  }

  Future<void> tentarNovamente() => _reiniciar();

  Future<void> carregarMais() async {
    if (!termoValido || _carregando || _carregandoMais || !_temProxima) {
      return;
    }
    final versao = _versao;
    _carregandoMais = true;
    _erroMais = null;
    notifyListeners();
    try {
      final resposta = await _buscar(pagina: _pagina + 1);
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

  Future<void> _reiniciar({bool adiar = false}) async {
    _temporizador?.cancel();
    _versao++;
    _itens.clear();
    _ids.clear();
    _pagina = 0;
    _totalItens = 0;
    _temProxima = false;
    _atualizadoEm = null;
    _qualidade = null;
    _erro = null;
    _erroMais = null;
    _carregandoMais = false;
    _carregando = termoValido;
    notifyListeners();

    if (!termoValido) return;
    if (adiar) {
      _temporizador = Timer(debounce, _primeiraPagina);
      return;
    }
    await _primeiraPagina();
  }

  Future<void> _primeiraPagina() async {
    final versao = _versao;
    try {
      final resposta = await _buscar(pagina: 1);
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

  Future<Pagina<ProdutoDireto>> _buscar({required int pagina}) => buscar(
    termo: _termo.trim(),
    pagina: pagina,
    marca: _filtros.marcaOpcional,
    categoria: _filtros.categoriaOpcional,
    loja: _filtros.lojaOpcional,
    precoMin: _filtros.precoMinOpcional,
    precoMax: _filtros.precoMaxOpcional,
  );

  void _aplicar(Pagina<ProdutoDireto> resposta) {
    for (final item in resposta.itens) {
      final chave = '${item.lojaSlug}\u0000${item.idExterno}';
      if (_ids.add(chave)) _itens.add(item);
    }
    _pagina = resposta.pagina;
    _totalItens = resposta.totalItens;
    _temProxima = resposta.temProxima;
    _atualizadoEm = resposta.atualizadoEm;
    _qualidade = resposta.qualidade;
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
