import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/modelos.dart';
import '../../core/api/pagina.dart';

enum OrdenacaoLivelo {
  pontos('pontos', 'Maior pontuação'),
  alerta('alerta', 'Em alerta'),
  nome('nome', 'Nome A–Z');

  const OrdenacaoLivelo(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;
}

typedef BuscarPainelLivelo =
    Future<Pagina<PontuacaoLivelo>> Function({
      required String q,
      required String ordenar,
      required int pagina,
    });

/// Estado testável do painel Livelo. A tela só observa e encaminha intenções.
class ControladorPainelLivelo extends ChangeNotifier {
  ControladorPainelLivelo({
    required this.buscar,
    this.debounce = const Duration(milliseconds: 350),
  });

  final BuscarPainelLivelo buscar;
  final Duration debounce;
  Timer? _temporizador;
  var _versaoDaConsulta = 0;
  var _descartado = false;

  final List<PontuacaoLivelo> _itens = <PontuacaoLivelo>[];
  final Set<String> _nomesCarregados = <String>{};
  String _busca = '';
  OrdenacaoLivelo _ordenacao = OrdenacaoLivelo.pontos;
  String? _atualizadoEm;
  int _totalItens = 0;
  int _paginaAtual = 0;
  int _porPagina = 10;
  int _totalPaginas = 1;
  bool _temProxima = false;
  bool _carregandoInicial = false;
  bool _carregandoMais = false;
  Object? _erroInicial;
  Object? _erroMais;

  List<PontuacaoLivelo> get itens => List.unmodifiable(_itens);
  String get busca => _busca;
  OrdenacaoLivelo get ordenacao => _ordenacao;
  String? get atualizadoEm => _atualizadoEm;
  int get totalItens => _totalItens;
  bool get temProxima => _temProxima;
  int get pagina => _paginaAtual == 0 ? 1 : _paginaAtual;
  int get porPagina => _porPagina;
  int get totalPaginas => _totalPaginas;
  bool get carregandoInicial => _carregandoInicial;
  bool get carregandoMais => _carregandoMais;
  Object? get erroInicial => _erroInicial;
  Object? get erroMais => _erroMais;

  Future<void> carregarInicial() => _reiniciarECarregar();

  void mudarBusca(String valor) {
    if (valor == _busca) {
      return;
    }
    _busca = valor;
    _limparParaNovaConsulta();
    _temporizador = Timer(debounce, _carregarPrimeiraPagina);
  }

  Future<void> mudarOrdenacao(OrdenacaoLivelo valor) async {
    if (valor == _ordenacao) {
      return;
    }
    _ordenacao = valor;
    await _reiniciarECarregar();
  }

  Future<void> tentarNovamente() => _reiniciarECarregar();

  Future<void> carregarMais() async {
    if (_carregandoInicial || _carregandoMais || !_temProxima) {
      return;
    }
    final versao = _versaoDaConsulta;
    _carregandoMais = true;
    _erroMais = null;
    notifyListeners();
    try {
      final pagina = await buscar(
        q: _busca,
        ordenar: _ordenacao.codigo,
        pagina: _paginaAtual + 1,
      );
      if (!_ativa(versao)) {
        return;
      }
      _aplicarPagina(pagina);
    } catch (erro) {
      if (_ativa(versao)) {
        _erroMais = erro;
      }
    } finally {
      if (_ativa(versao)) {
        _carregandoMais = false;
        notifyListeners();
      }
    }
  }

  /// Busca a página selecionada e substitui os cards exibidos.
  Future<void> irParaPagina(int pagina) async {
    if (_carregandoInicial ||
        _carregandoMais ||
        pagina < 1 ||
        pagina > _totalPaginas ||
        pagina == _paginaAtual) {
      return;
    }
    final versao = _versaoDaConsulta;
    _carregandoMais = true;
    _erroMais = null;
    notifyListeners();
    try {
      final resposta = await buscar(
        q: _busca,
        ordenar: _ordenacao.codigo,
        pagina: pagina,
      );
      if (_ativa(versao)) {
        _itens.clear();
        _nomesCarregados.clear();
        _aplicarPagina(resposta);
      }
    } catch (erro) {
      if (_ativa(versao)) _erroMais = erro;
    } finally {
      if (_ativa(versao)) {
        _carregandoMais = false;
        notifyListeners();
      }
    }
  }

  Future<void> _reiniciarECarregar() async {
    _temporizador?.cancel();
    _limparParaNovaConsulta();
    await _carregarPrimeiraPagina();
  }

  void _limparParaNovaConsulta() {
    _temporizador?.cancel();
    _versaoDaConsulta++;
    _itens.clear();
    _nomesCarregados.clear();
    _atualizadoEm = null;
    _totalItens = 0;
    _paginaAtual = 0;
    _porPagina = 10;
    _totalPaginas = 1;
    _temProxima = false;
    _carregandoInicial = true;
    _carregandoMais = false;
    _erroInicial = null;
    _erroMais = null;
    notifyListeners();
  }

  Future<void> _carregarPrimeiraPagina() async {
    final versao = _versaoDaConsulta;
    try {
      final pagina = await buscar(
        q: _busca,
        ordenar: _ordenacao.codigo,
        pagina: 1,
      );
      if (!_ativa(versao)) {
        return;
      }
      _aplicarPagina(pagina);
    } catch (erro) {
      if (_ativa(versao)) {
        _erroInicial = erro;
      }
    } finally {
      if (_ativa(versao)) {
        _carregandoInicial = false;
        notifyListeners();
      }
    }
  }

  void _aplicarPagina(Pagina<PontuacaoLivelo> pagina) {
    for (final item in pagina.itens) {
      final nome = item.nome.trim();
      if (nome.isNotEmpty && _nomesCarregados.add(nome)) {
        _itens.add(item);
      }
    }
    _paginaAtual = pagina.pagina;
    _totalItens = pagina.totalItens;
    _porPagina = pagina.porPagina;
    _totalPaginas = pagina.totalPaginas;
    _temProxima = pagina.temProxima;
    _atualizadoEm = pagina.atualizadoEm;
    _erroMais = null;
  }

  bool _ativa(int versao) => !_descartado && versao == _versaoDaConsulta;

  @override
  void dispose() {
    _descartado = true;
    _temporizador?.cancel();
    super.dispose();
  }
}
