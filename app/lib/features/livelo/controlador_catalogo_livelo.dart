import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/modelos.dart';

enum AbaCatalogoLivelo {
  lojas('todas', 'Lojas'),
  acompanhadas('acompanhadas', 'Acompanhadas'),
  alertas('alertas', 'Alertas');

  const AbaCatalogoLivelo(this.codigo, this.rotulo);
  final String codigo;
  final String rotulo;
}

enum OrdenacaoCatalogoLivelo {
  pontos('pontos', 'Maior pontuação'),
  nome('nome', 'Nome A–Z');

  const OrdenacaoCatalogoLivelo(this.codigo, this.rotulo);
  final String codigo;
  final String rotulo;
}

typedef BuscarCatalogoLivelo =
    Future<PaginaCatalogoLivelo> Function({
      required String q,
      required String aba,
      required String categoria,
      required String ordenar,
      required int pagina,
    });

typedef AlterarAcompanhamentoLivelo =
    Future<void> Function({
      required String idExterno,
      required bool acompanhada,
    });

typedef AlterarAlertaLivelo =
    Future<void> Function({required String idExterno, required bool ativo});

enum ResultadoAtualizacaoSilenciosa { alterada, degradada, inalterada, falha }

Future<void> _ignorarAlerta({
  required String idExterno,
  required bool ativo,
}) async {}

class ControladorCatalogoLivelo extends ChangeNotifier {
  ControladorCatalogoLivelo({
    required this.buscar,
    required this.alterarAcompanhamento,
    AlterarAlertaLivelo? alterarAlerta,
    this.debounce = const Duration(milliseconds: 350),
  }) : alterarAlerta = alterarAlerta ?? _ignorarAlerta;

  final BuscarCatalogoLivelo buscar;
  final AlterarAcompanhamentoLivelo alterarAcompanhamento;
  final AlterarAlertaLivelo alterarAlerta;
  final Duration debounce;

  final List<ParceiroCatalogoLivelo> _itens = [];
  final Set<String> _idsCarregados = {};
  final Set<String> _mutacoesPendentes = {};
  Timer? _temporizador;
  var _versaoConsulta = 0;
  var _descartado = false;
  String _busca = '';
  String _categoria = '';
  AbaCatalogoLivelo _aba = AbaCatalogoLivelo.lojas;
  OrdenacaoCatalogoLivelo _ordenacao = OrdenacaoCatalogoLivelo.pontos;
  ResumoCatalogoLivelo? _resumo;
  List<String> _categorias = const [];
  int _paginaAtual = 0;
  int _totalItens = 0;
  bool _temProxima = false;
  bool _carregandoInicial = false;
  bool _carregandoMais = false;
  Object? _erroInicial;
  Object? _erroMais;

  List<ParceiroCatalogoLivelo> get itens => List.unmodifiable(_itens);
  Set<String> get mutacoesPendentes => Set.unmodifiable(_mutacoesPendentes);
  String get busca => _busca;
  String get categoria => _categoria;
  AbaCatalogoLivelo get aba => _aba;
  OrdenacaoCatalogoLivelo get ordenacao => _ordenacao;
  ResumoCatalogoLivelo? get resumo => _resumo;
  List<String> get categorias => _categorias;
  int get totalItens => _totalItens;
  bool get temProxima => _temProxima;
  bool get carregandoInicial => _carregandoInicial;
  bool get carregandoMais => _carregandoMais;
  Object? get erroInicial => _erroInicial;
  Object? get erroMais => _erroMais;

  Future<void> carregarInicial() => _reiniciarECarregar();

  void mudarBusca(String valor) {
    if (valor == _busca) return;
    _busca = valor;
    _prepararNovaConsulta();
    _temporizador = Timer(debounce, _carregarPrimeiraPagina);
  }

  Future<void> mudarAba(AbaCatalogoLivelo valor) async {
    if (valor == _aba) return;
    _aba = valor;
    await _reiniciarECarregar();
  }

  Future<void> mudarCategoria(String valor) async {
    if (valor == _categoria) return;
    _categoria = valor;
    await _reiniciarECarregar();
  }

  Future<void> mudarOrdenacao(OrdenacaoCatalogoLivelo valor) async {
    if (valor == _ordenacao) return;
    _ordenacao = valor;
    await _reiniciarECarregar();
  }

  Future<void> tentarNovamente() => _reiniciarECarregar();

  /// Relê o primeiro retrato sem trocar aba, busca, filtros, itens já
  /// carregados nem posição de rolagem. Só aplica quando a coleta mudou.
  Future<ResultadoAtualizacaoSilenciosa> atualizarSilenciosamente() async {
    if (_carregandoInicial || _carregandoMais) {
      return ResultadoAtualizacaoSilenciosa.inalterada;
    }
    try {
      final pagina = await _buscar(1);
      if (_descartado ||
          (pagina.resumo.ultimaColeta == _resumo?.ultimaColeta &&
              pagina.resumo.ultimaTentativaEm == _resumo?.ultimaTentativaEm &&
              pagina.resumo.qualidade == _resumo?.qualidade)) {
        return ResultadoAtualizacaoSilenciosa.inalterada;
      }
      final porId = {for (final item in pagina.itens) item.idExterno: item};
      for (var indice = 0; indice < _itens.length; indice++) {
        final atualizado = porId[_itens[indice].idExterno];
        if (atualizado != null) _itens[indice] = atualizado;
      }
      _resumo = pagina.resumo;
      _categorias = List.unmodifiable(pagina.categorias);
      notifyListeners();
      return pagina.resumo.qualidade == 'degradada'
          ? ResultadoAtualizacaoSilenciosa.degradada
          : ResultadoAtualizacaoSilenciosa.alterada;
    } catch (_) {
      return ResultadoAtualizacaoSilenciosa.falha;
    }
  }

  Future<void> carregarMais() async {
    if (_carregandoInicial || _carregandoMais || !_temProxima) return;
    final versao = _versaoConsulta;
    _carregandoMais = true;
    _erroMais = null;
    notifyListeners();
    try {
      final pagina = await _buscar(_paginaAtual + 1);
      if (_ativa(versao)) _aplicarPagina(pagina);
    } catch (erro) {
      if (_ativa(versao)) _erroMais = erro;
    } finally {
      if (_ativa(versao)) {
        _carregandoMais = false;
        notifyListeners();
      }
    }
  }

  Future<bool> alternarAcompanhamento(ParceiroCatalogoLivelo parceiro) async {
    if (_mutacoesPendentes.contains(parceiro.idExterno)) return false;
    final indice = _itens.indexWhere(
      (item) => item.idExterno == parceiro.idExterno,
    );
    if (indice < 0) return false;

    final versao = _versaoConsulta;
    final original = _itens[indice];
    final resumoOriginal = _resumo;
    final acompanhar = !original.acompanhada;
    _mutacoesPendentes.add(original.idExterno);
    _itens[indice] = original.copiarCom(
      acompanhada: acompanhar,
      alertaAtivo: acompanhar ? original.alertaAtivo : false,
      alerta: false,
    );
    if (_resumo != null) {
      _resumo = _resumo!.copiarCom(
        acompanhadas: _resumo!.acompanhadas + (acompanhar ? 1 : -1),
        alertasAtivos:
            _resumo!.alertasAtivos -
            (!acompanhar && original.alertaAtivo ? 1 : 0),
        alertas: _resumo!.alertas - (!acompanhar && original.alerta ? 1 : 0),
      );
    }
    notifyListeners();

    try {
      await alterarAcompanhamento(
        idExterno: original.idExterno,
        acompanhada: acompanhar,
      );
      if (_ativa(versao) && !acompanhar && _aba != AbaCatalogoLivelo.lojas) {
        _itens.removeWhere((item) => item.idExterno == original.idExterno);
        _idsCarregados.remove(original.idExterno);
        if (_totalItens > 0) _totalItens--;
      }
      return true;
    } catch (_) {
      if (_ativa(versao)) {
        final atual = _itens.indexWhere(
          (item) => item.idExterno == original.idExterno,
        );
        if (atual >= 0) _itens[atual] = original;
        _resumo = resumoOriginal;
      }
      return false;
    } finally {
      _mutacoesPendentes.remove(original.idExterno);
      if (!_descartado) notifyListeners();
    }
  }

  Future<bool> alternarAlerta(ParceiroCatalogoLivelo parceiro) async {
    if (_mutacoesPendentes.contains('alerta:${parceiro.idExterno}')) {
      return false;
    }
    final indice = _itens.indexWhere(
      (item) => item.idExterno == parceiro.idExterno,
    );
    if (indice < 0 || !parceiro.acompanhada) return false;
    final original = _itens[indice];
    final ativo = !original.alertaAtivo;
    final chave = 'alerta:${original.idExterno}';
    _mutacoesPendentes.add(chave);
    _itens[indice] = original.copiarCom(alertaAtivo: ativo);
    final resumoOriginal = _resumo;
    if (_resumo != null) {
      _resumo = _resumo!.copiarCom(
        alertasAtivos: _resumo!.alertasAtivos + (ativo ? 1 : -1),
      );
    }
    notifyListeners();
    try {
      await alterarAlerta(idExterno: original.idExterno, ativo: ativo);
      return true;
    } catch (_) {
      if (_itens.length > indice &&
          _itens[indice].idExterno == original.idExterno) {
        _itens[indice] = original;
      }
      _resumo = resumoOriginal;
      return false;
    } finally {
      _mutacoesPendentes.remove(chave);
      if (!_descartado) notifyListeners();
    }
  }

  Future<void> _reiniciarECarregar() async {
    _temporizador?.cancel();
    _prepararNovaConsulta();
    await _carregarPrimeiraPagina();
  }

  void _prepararNovaConsulta() {
    _temporizador?.cancel();
    _versaoConsulta++;
    _itens.clear();
    _idsCarregados.clear();
    _paginaAtual = 0;
    _totalItens = 0;
    _temProxima = false;
    _carregandoInicial = true;
    _carregandoMais = false;
    _erroInicial = null;
    _erroMais = null;
    notifyListeners();
  }

  Future<void> _carregarPrimeiraPagina() async {
    final versao = _versaoConsulta;
    try {
      final pagina = await _buscar(1);
      if (_ativa(versao)) _aplicarPagina(pagina);
    } catch (erro) {
      if (_ativa(versao)) _erroInicial = erro;
    } finally {
      if (_ativa(versao)) {
        _carregandoInicial = false;
        notifyListeners();
      }
    }
  }

  Future<PaginaCatalogoLivelo> _buscar(int pagina) => buscar(
    q: _busca,
    aba: _aba.codigo,
    categoria: _categoria,
    ordenar: _ordenacao.codigo,
    pagina: pagina,
  );

  void _aplicarPagina(PaginaCatalogoLivelo pagina) {
    for (final item in pagina.itens) {
      if (item.idExterno.isNotEmpty && _idsCarregados.add(item.idExterno)) {
        _itens.add(item);
      }
    }
    _paginaAtual = pagina.pagina;
    _totalItens = pagina.totalItens;
    _temProxima = pagina.temProxima;
    _resumo = pagina.resumo;
    _categorias = List.unmodifiable(pagina.categorias);
    _erroMais = null;
  }

  bool _ativa(int versao) => !_descartado && versao == _versaoConsulta;

  @override
  void dispose() {
    _descartado = true;
    _temporizador?.cancel();
    super.dispose();
  }
}
