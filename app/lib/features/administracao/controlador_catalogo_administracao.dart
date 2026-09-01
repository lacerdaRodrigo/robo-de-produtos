import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/pagina.dart';

typedef BuscarCatalogoAdministrativo<T> =
    Future<Pagina<T>> Function({required String q, required int pagina});

/// Estado paginado e pesquisável para catálogos administrativos.
///
/// A tela não altera a sequência durante uma busca: respostas de uma consulta
/// antiga são descartadas por versão. A paginação só avança por uma ação
/// explícita, para não executar mais leituras do que o administrador pediu.
class ControladorCatalogoAdministracao<T> extends ChangeNotifier {
  ControladorCatalogoAdministracao({
    required this.buscar,
    required this.identificar,
    this.debounce = const Duration(milliseconds: 350),
  });

  final BuscarCatalogoAdministrativo<T> buscar;
  final String Function(T item) identificar;
  final Duration debounce;

  final List<T> _itens = <T>[];
  Timer? _timer;
  String _busca = '';
  int _versao = 0;
  int _pagina = 0;
  int _total = 0;
  bool _temProxima = false;
  bool _carregandoInicial = false;
  bool _carregandoMais = false;
  Object? _erroInicial;
  Object? _erroMais;

  List<T> get itens => List<T>.unmodifiable(_itens);
  String get busca => _busca;
  int get total => _total;
  bool get temProxima => _temProxima;
  bool get carregandoInicial => _carregandoInicial;
  bool get carregandoMais => _carregandoMais;
  Object? get erroInicial => _erroInicial;
  Object? get erroMais => _erroMais;

  Future<void> carregarPrimeira() => _carregarPrimeira(_versao);

  /// Reinicia a consulta quando um filtro externo muda, invalidando respostas
  /// antigas para que busca e paginação continuem representando o servidor.
  Future<void> reiniciarConsulta() {
    _timer?.cancel();
    _versao++;
    _itens.clear();
    _pagina = 0;
    _total = 0;
    _temProxima = false;
    _erroInicial = null;
    _erroMais = null;
    _carregandoInicial = true;
    notifyListeners();
    return _carregarPrimeira(_versao);
  }

  /// Espera a pessoa terminar de digitar antes de reiniciar a lista.
  void mudarBusca(String valor) {
    if (valor == _busca) return;
    _timer?.cancel();
    _busca = valor;
    _versao++;
    _itens.clear();
    _pagina = 0;
    _total = 0;
    _temProxima = false;
    _erroInicial = null;
    _erroMais = null;
    _carregandoInicial = true;
    notifyListeners();
    final versao = _versao;
    _timer = Timer(debounce, () => _carregarPrimeira(versao));
  }

  Future<void> carregarMais() async {
    if (_carregandoInicial || _carregandoMais || !_temProxima) return;
    _carregandoMais = true;
    _erroMais = null;
    notifyListeners();
    final versao = _versao;
    try {
      final resposta = await buscar(q: _busca, pagina: _pagina + 1);
      if (_ativa(versao)) _adicionar(resposta);
    } catch (erro) {
      if (_ativa(versao)) _erroMais = erro;
    } finally {
      if (_ativa(versao)) {
        _carregandoMais = false;
        notifyListeners();
      }
    }
  }

  /// Atualiza o cartão depois que a API confirmou a mudança de estado.
  void substituir(String id, T valor) {
    final indice = _itens.indexWhere((item) => identificar(item) == id);
    if (indice < 0) return;
    _itens[indice] = valor;
    notifyListeners();
  }

  /// Remove localmente somente depois da confirmação da API.
  void remover(String id) {
    final removidos = _itens.length;
    _itens.removeWhere((item) => identificar(item) == id);
    if (_itens.length == removidos) return;
    if (_total > 0) _total--;
    notifyListeners();
  }

  Future<void> _carregarPrimeira(int versao) async {
    if (!_ativa(versao) || _carregandoMais) return;
    _carregandoInicial = true;
    _erroInicial = null;
    notifyListeners();
    try {
      final resposta = await buscar(q: _busca, pagina: 1);
      if (!_ativa(versao)) return;
      _itens
        ..clear()
        ..addAll(_semDuplicatas(resposta.itens));
      _pagina = resposta.pagina;
      _total = resposta.totalItens;
      _temProxima = resposta.temProxima;
    } catch (erro) {
      if (_ativa(versao)) _erroInicial = erro;
    } finally {
      if (_ativa(versao)) {
        _carregandoInicial = false;
        notifyListeners();
      }
    }
  }

  void _adicionar(Pagina<T> resposta) {
    final conhecidos = _itens.map(identificar).toSet();
    _itens.addAll(
      resposta.itens.where((item) => conhecidos.add(identificar(item))),
    );
    _pagina = resposta.pagina;
    _total = resposta.totalItens;
    _temProxima = resposta.temProxima;
  }

  List<T> _semDuplicatas(List<T> valores) {
    final vistos = <String>{};
    return valores.where((item) => vistos.add(identificar(item))).toList();
  }

  bool _ativa(int versao) => versao == _versao;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
