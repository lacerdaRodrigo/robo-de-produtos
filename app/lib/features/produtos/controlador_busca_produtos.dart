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
  int _porPagina = 20;
  int _totalItens = 0;
  bool _temProxima = false;
  bool _carregando = false;
  bool _carregandoMais = false;
  String? _atualizadoEm;
  String? _qualidade;
  String? _ultimaTentativaEm;
  String? _ultimaTentativaEstado;
  Object? _erro;
  Object? _erroMais;

  List<ProdutoDireto> get itens => List.unmodifiable(_itens);
  String get termo => _termo;
  FiltrosProdutos get filtros => _filtros;
  int get totalItens => _totalItens;
  int get pagina => _pagina;
  int get porPagina => _porPagina;
  bool get temProxima => _temProxima;
  bool get carregando => _carregando;
  bool get carregandoMais => _carregandoMais;
  String? get atualizadoEm => _atualizadoEm;
  String? get qualidade => _qualidade;
  String? get ultimaTentativaEm => _ultimaTentativaEm;
  String? get ultimaTentativaEstado => _ultimaTentativaEstado;
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
    _porPagina = 20;
    _totalItens = 0;
    _temProxima = false;
    _atualizadoEm = null;
    _qualidade = null;
    _ultimaTentativaEm = null;
    _ultimaTentativaEstado = null;
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
    final primeiraPagina = _pagina == 0;
    for (final item in resposta.itens) {
      final chave = '${item.lojaSlug}\u0000${item.idExterno}';
      if (_ids.add(chave)) _itens.add(item);
    }
    _pagina = resposta.pagina;
    _porPagina = resposta.porPagina;
    _totalItens = resposta.totalItens;
    _temProxima = resposta.temProxima;
    _atualizadoEm = primeiraPagina
        ? resposta.atualizadoEm
        : _instanteMaisAntigo(_atualizadoEm, resposta.atualizadoEm);
    _qualidade = primeiraPagina
        ? resposta.qualidade
        : _combinarQualidade(_qualidade, resposta.qualidade);
    _ultimaTentativaEm = primeiraPagina
        ? resposta.ultimaTentativaEm
        : _instanteMaisRecente(_ultimaTentativaEm, resposta.ultimaTentativaEm);
    _ultimaTentativaEstado = primeiraPagina
        ? resposta.ultimaTentativaEstado
        : _combinarEstadoTentativa(
            _ultimaTentativaEstado,
            resposta.ultimaTentativaEstado,
          );
    _erroMais = null;
  }

  String? _instanteMaisAntigo(String? atual, String? candidato) =>
      _combinarInstantes(
        atual,
        candidato,
        escolherCandidato: (a, b) => b.isBefore(a),
      );

  String? _instanteMaisRecente(String? atual, String? candidato) =>
      _combinarInstantes(
        atual,
        candidato,
        escolherCandidato: (a, b) => b.isAfter(a),
      );

  String? _combinarInstantes(
    String? atual,
    String? candidato, {
    required bool Function(DateTime atual, DateTime candidato)
    escolherCandidato,
  }) {
    if (atual == null) return candidato;
    if (candidato == null) return atual;
    final instanteAtual = DateTime.tryParse(atual);
    final instanteCandidato = DateTime.tryParse(candidato);
    if (instanteAtual == null) return candidato;
    if (instanteCandidato == null) return atual;
    return escolherCandidato(instanteAtual, instanteCandidato)
        ? candidato
        : atual;
  }

  String? _combinarQualidade(String? atual, String? candidata) {
    if (atual == 'degradada' || candidata == 'degradada') return 'degradada';
    if (atual == null || candidata == null) return null;
    return 'completa';
  }

  String? _combinarEstadoTentativa(String? atual, String? candidato) {
    if (atual == candidato) return atual;
    if (atual == 'iniciada' || candidato == 'iniciada') return 'iniciada';
    return 'parcial';
  }

  bool _ativa(int versao) => !_descartado && versao == _versao;

  @override
  void dispose() {
    _descartado = true;
    _temporizador?.cancel();
    super.dispose();
  }
}
