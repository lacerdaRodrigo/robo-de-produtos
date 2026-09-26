// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';

class ControladorAlertas extends ChangeNotifier {
  // O parâmetro público mantém a API do controlador; `_api` continua privado.
  ControladorAlertas({required Api api, String? coletaInicial})
    : _api = api,
      _coleta = coletaInicial;

  final Api _api;
  final String? _coleta;
  List<AlertaApp> itens = const [];
  String filtro = 'todos';
  int pagina = 1;
  int totalItens = 0;
  int totalPaginas = 1;
  int porPagina = 20;
  int naoLidos = 0;
  bool carregando = false;
  bool parcial = false;
  Object? erro;

  bool get temProxima => pagina < totalPaginas;

  Future<void> carregar({bool preservar = true}) async {
    if (carregando) return;
    carregando = true;
    erro = null;
    if (!preservar) itens = const [];
    notifyListeners();
    try {
      final resposta = await _api.alertas(
        filtro: filtro,
        pagina: pagina,
        coleta: _coleta,
      );
      itens = resposta.itens;
      pagina = resposta.pagina;
      totalItens = resposta.totalItens;
      totalPaginas = resposta.totalPaginas;
      porPagina = resposta.porPagina;
      naoLidos = resposta.naoLidos;
      parcial = false;
    } on ErroDeApi catch (ex) {
      erro = ex;
      parcial = itens.isNotEmpty;
    } on Object catch (ex) {
      erro = ex;
      parcial = itens.isNotEmpty;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  Future<void> iniciar() => carregar(preservar: false);

  Future<void> mudarFiltro(String novo) async {
    if (filtro == novo) return;
    filtro = novo;
    pagina = 1;
    await carregar(preservar: true);
  }

  Future<void> irParaPagina(int nova) async {
    if (nova < 1 || nova > totalPaginas || nova == pagina) return;
    pagina = nova;
    await carregar(preservar: true);
  }

  Future<void> marcar(AlertaApp alerta) async {
    final novoEstado = !alerta.lido;
    final indice = itens.indexWhere((item) => item.id == alerta.id);
    if (indice < 0) return;
    final anterior = itens[indice];
    itens = [...itens]..[indice] = alerta.copiarCom(lido: novoEstado);
    naoLidos += novoEstado ? -1 : 1;
    if (naoLidos < 0) naoLidos = 0;
    notifyListeners();
    try {
      await _api.marcarAlerta(id: alerta.id, lido: novoEstado);
    } catch (_) {
      itens = [...itens]..[indice] = anterior;
      naoLidos += novoEstado ? 1 : -1;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> marcarVisiveis() async {
    final ids = itens
        .where((item) => !item.lido)
        .map((item) => item.id)
        .toList(growable: false);
    if (ids.isEmpty) return;
    final anteriores = itens;
    itens = itens
        .map((item) => item.copiarCom(lido: true))
        .toList(growable: false);
    naoLidos = 0;
    notifyListeners();
    try {
      await _api.marcarAlertas(ids: ids, lido: true);
    } catch (_) {
      itens = anteriores;
      naoLidos = anteriores.where((item) => !item.lido).length;
      notifyListeners();
      rethrow;
    }
  }

  /// Marca como lidos todos os eventos do recorte atual, não só a página
  /// renderizada. A busca continua paginada e cada mutação respeita o limite
  /// de ids aceito pela API.
  Future<void> marcarTodos() async {
    final ids = <String>[];
    var paginaBusca = 1;
    PaginaAlertasApi? resposta;
    do {
      resposta = await _api.alertas(
        filtro: filtro,
        pagina: paginaBusca,
        porPagina: 50,
        coleta: _coleta,
      );
      ids.addAll(
        resposta.itens.where((item) => !item.lido).map((item) => item.id),
      );
      paginaBusca++;
    } while (paginaBusca <= resposta.totalPaginas);

    final anteriores = itens;
    final naoLidosAnterior = naoLidos;
    itens = itens
        .map((item) => item.copiarCom(lido: true))
        .toList(growable: false);
    naoLidos = naoLidos > ids.length ? naoLidos - ids.length : 0;
    notifyListeners();
    try {
      for (var inicio = 0; inicio < ids.length; inicio += 100) {
        final fim = (inicio + 100).clamp(0, ids.length);
        await _api.marcarAlertas(ids: ids.sublist(inicio, fim), lido: true);
      }
    } catch (_) {
      itens = anteriores;
      naoLidos = naoLidosAnterior;
      notifyListeners();
      rethrow;
    }
  }
}
