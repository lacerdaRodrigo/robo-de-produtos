import 'dart:async';

import 'package:flutter/foundation.dart';

import 'modelos_pichau.dart';

enum AbaCatalogoPichau {
  todas('todas', 'Todas'),
  acompanhadas('acompanhadas', 'Acompanhadas');

  const AbaCatalogoPichau(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;
}

enum DisponibilidadePichau {
  todas('todas', 'Todas as disponibilidades'),
  disponiveis('disponiveis', 'Disponíveis'),
  esgotados('esgotados', 'Esgotados');

  const DisponibilidadePichau(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;
}

enum OrdenacaoPichau {
  nome('nome', 'Nome do produto'),
  preco('preco', 'Menor preço Pix'),
  desconto('desconto', 'Maior desconto Pix');

  const OrdenacaoPichau(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;
}

typedef BuscarCatalogoPichau =
    Future<PaginaCatalogoPichau> Function({
      required String q,
      required String aba,
      required String disponibilidade,
      required String ordenar,
      required int pagina,
    });

typedef AlterarAcompanhamentoPichau =
    Future<void> Function({
      required String idExterno,
      required bool acompanhada,
    });

/// Estado do catálogo Pichau sem perder busca, filtros ou posição de página.
///
/// A mutação é otimista para manter a resposta da interface igual à de Livelo
/// e Inter. Em falha, o produto e o contador global voltam ao retrato anterior.
class ControladorCatalogoPichau extends ChangeNotifier {
  ControladorCatalogoPichau({
    required this.buscar,
    required this.alterarAcompanhamento,
    this.debounce = const Duration(milliseconds: 350),
  });

  final BuscarCatalogoPichau buscar;
  final AlterarAcompanhamentoPichau alterarAcompanhamento;
  final Duration debounce;

  final _itens = <PichauProduto>[];
  final _mutacoesPendentes = <String>{};
  Timer? _temporizador;
  var _versaoConsulta = 0;
  var _descartado = false;
  var _busca = '';
  var _aba = AbaCatalogoPichau.todas;
  var _disponibilidade = DisponibilidadePichau.todas;
  var _ordenacao = OrdenacaoPichau.nome;
  ResumoCatalogoPichau? _resumo;
  var _paginaAtual = 0;
  var _totalItens = 0;
  var _porPagina = 20;
  var _totalPaginas = 1;
  var _temProxima = false;
  String? _qualidade;
  String? _ultimaTentativaEstado;
  var _carregandoInicial = false;
  var _carregandoMais = false;
  Object? _erroInicial;
  Object? _erroMais;

  List<PichauProduto> get itens => List.unmodifiable(_itens);
  Set<String> get mutacoesPendentes => Set.unmodifiable(_mutacoesPendentes);
  String get busca => _busca;
  AbaCatalogoPichau get aba => _aba;
  DisponibilidadePichau get disponibilidade => _disponibilidade;
  OrdenacaoPichau get ordenacao => _ordenacao;
  ResumoCatalogoPichau? get resumo => _resumo;
  int get pagina => _paginaAtual == 0 ? 1 : _paginaAtual;
  int get totalItens => _totalItens;
  int get porPagina => _porPagina;
  int get totalPaginas => _totalPaginas;
  bool get temProxima => _temProxima;
  bool get carregandoInicial => _carregandoInicial;
  bool get carregandoMais => _carregandoMais;
  Object? get erroInicial => _erroInicial;
  Object? get erroMais => _erroMais;
  String? get qualidade => _qualidade;
  String? get ultimaTentativaEstado => _ultimaTentativaEstado;

  Future<void> carregarInicial() => _reiniciarECarregar();

  void mudarBusca(String valor) {
    if (valor == _busca) return;
    _busca = valor;
    _prepararNovaConsulta();
    _temporizador = Timer(debounce, _carregarPrimeiraPagina);
  }

  Future<void> mudarAba(AbaCatalogoPichau valor) async {
    if (valor == _aba) return;
    _aba = valor;
    await _reiniciarECarregar();
  }

  Future<void> aplicarFiltros({
    required DisponibilidadePichau disponibilidade,
    required OrdenacaoPichau ordenacao,
  }) async {
    if (disponibilidade == _disponibilidade && ordenacao == _ordenacao) {
      return;
    }
    _disponibilidade = disponibilidade;
    _ordenacao = ordenacao;
    await _reiniciarECarregar();
  }

  Future<void> tentarNovamente() {
    if (_resumo == null) return _reiniciarECarregar();
    _temporizador?.cancel();
    _versaoConsulta++;
    _carregandoInicial = true;
    _erroInicial = null;
    _erroMais = null;
    notifyListeners();
    return _carregarPrimeiraPagina(pagina: pagina);
  }

  Future<void> irParaPagina(int pagina) async {
    if (_carregandoInicial ||
        _carregandoMais ||
        pagina < 1 ||
        pagina > _totalPaginas ||
        pagina == _paginaAtual) {
      return;
    }
    final versao = _versaoConsulta;
    _carregandoMais = true;
    _erroMais = null;
    notifyListeners();
    try {
      final resposta = await _buscar(pagina);
      if (_ativa(versao)) _aplicarPagina(resposta);
    } catch (erro) {
      if (_ativa(versao)) _erroMais = erro;
    } finally {
      if (_ativa(versao)) {
        _carregandoMais = false;
        notifyListeners();
      }
    }
  }

  Future<bool> alternarAcompanhamento(PichauProduto produto) async {
    if (_mutacoesPendentes.contains(produto.idExterno)) return false;
    final indice = _itens.indexWhere(
      (item) => item.idExterno == produto.idExterno,
    );
    if (indice < 0) return false;

    final original = _itens[indice];
    final acompanhar = !original.acompanhada;
    final resumoOriginal = _resumo;
    final totalOriginal = _totalItens;
    _mutacoesPendentes.add(original.idExterno);
    _itens[indice] = original.copiarCom(acompanhada: acompanhar);
    if (_resumo != null) {
      _resumo = _resumo!.copiarCom(
        acompanhadas: _resumo!.acompanhadas + (acompanhar ? 1 : -1),
      );
    }
    notifyListeners();

    try {
      await alterarAcompanhamento(
        idExterno: original.idExterno,
        acompanhada: acompanhar,
      );
      if (_ativa(_versaoConsulta) &&
          !acompanhar &&
          _aba == AbaCatalogoPichau.acompanhadas) {
        _itens.removeAt(indice);
        if (_totalItens > 0) _totalItens--;
        if (_paginaAtual > 0 && _itens.isEmpty && _paginaAtual > 1) {
          _paginaAtual--;
        }
        notifyListeners();
      }
      return true;
    } catch (_) {
      if (_ativa(_versaoConsulta)) {
        final atual = _itens.indexWhere(
          (item) => item.idExterno == original.idExterno,
        );
        if (atual >= 0) _itens[atual] = original;
        _resumo = resumoOriginal;
        _totalItens = totalOriginal;
        notifyListeners();
      }
      return false;
    } finally {
      _mutacoesPendentes.remove(original.idExterno);
      if (!_descartado) notifyListeners();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _temporizador?.cancel();
    super.dispose();
  }

  Future<void> _reiniciarECarregar() async {
    _temporizador?.cancel();
    _prepararNovaConsulta();
    await _carregarPrimeiraPagina();
  }

  void _prepararNovaConsulta() {
    _versaoConsulta++;
    _itens.clear();
    _paginaAtual = 0;
    _totalItens = 0;
    _totalPaginas = 1;
    _temProxima = false;
    _carregandoInicial = true;
    _carregandoMais = false;
    _erroInicial = null;
    _erroMais = null;
    notifyListeners();
  }

  Future<void> _carregarPrimeiraPagina({int pagina = 1}) async {
    final versao = _versaoConsulta;
    try {
      final resposta = await _buscar(pagina);
      if (_ativa(versao)) _aplicarPagina(resposta);
    } catch (erro) {
      if (_ativa(versao)) _erroInicial = erro;
    } finally {
      if (_ativa(versao)) {
        _carregandoInicial = false;
        notifyListeners();
      }
    }
  }

  Future<PaginaCatalogoPichau> _buscar(int pagina) => buscar(
    q: _busca.trim(),
    aba: _aba.codigo,
    disponibilidade: _disponibilidade.codigo,
    ordenar: _ordenacao.codigo,
    pagina: pagina,
  );

  void _aplicarPagina(PaginaCatalogoPichau resposta) {
    _itens
      ..clear()
      ..addAll(resposta.itens);
    _resumo = resposta.resumo;
    _paginaAtual = resposta.pagina;
    _porPagina = resposta.porPagina;
    _totalItens = resposta.totalItens;
    _totalPaginas = resposta.totalPaginas;
    _temProxima = resposta.temProxima;
    _qualidade = resposta.qualidade;
    _ultimaTentativaEstado = resposta.ultimaTentativaEstado;
    _erroInicial = null;
    _erroMais = null;
    notifyListeners();
  }

  bool _ativa(int versao) => !_descartado && versao == _versaoConsulta;
}
