import 'package:flutter/foundation.dart';

import '../../core/api/modelos.dart';

/// Estado persistido de categorias acompanhadas do Compre direto.
///
/// Guarda somente as categorias externas reais lidas da API. `null` representa
/// o agrupamento funcional `Sem categoria`, sem inventar uma categoria no dado
/// bruto do Shopping Inter.
class ControladorCategoriasAcompanhadas extends ChangeNotifier {
  ControladorCategoriasAcompanhadas({
    required this.carregar,
    required this.salvar,
  });

  final Future<CatalogoCategoriasInterUsuario> Function() carregar;
  final Future<CatalogoCategoriasInterUsuario> Function(
    List<String> categorias, {
    required bool semCategoria,
  })
  salvar;

  CatalogoCategoriasInterUsuario? _catalogo;
  bool _carregando = false;
  bool _salvando = false;
  Object? _erro;
  String? _erroSalvar;

  CatalogoCategoriasInterUsuario? get catalogo => _catalogo;
  bool get carregando => _carregando;
  bool get salvando => _salvando;
  Object? get erro => _erro;
  String? get erroSalvar => _erroSalvar;

  bool get configurado => _catalogo?.configurada ?? false;

  int get totalAcompanhadas => _catalogo?.valoresSelecionados.length ?? 0;

  Set<String?> get valoresSelecionados =>
      _catalogo?.valoresSelecionados ?? const <String?>{};

  String get resumo {
    final total = totalAcompanhadas;
    if (total == 0) return 'Nenhuma categoria acompanhada';
    final nome = total == 1 ? 'categoria' : 'categorias';
    return '$total $nome · aplicadas às lojas selecionadas';
  }

  Future<void> carregarAcompanhadas() async {
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      _catalogo = await carregar();
    } catch (erro) {
      _erro = erro;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Salva a seleção externa; em falha mantém o catálogo anterior confirmado.
  Future<bool> salvarSelecao(Set<String?> valores) async {
    _salvando = true;
    _erroSalvar = null;
    notifyListeners();
    try {
      final categorias = valores.whereType<String>().toList()..sort();
      _catalogo = await salvar(
        categorias,
        semCategoria: valores.contains(null),
      );
      return true;
    } catch (erro) {
      _erroSalvar = erro.toString();
      return false;
    } finally {
      _salvando = false;
      notifyListeners();
    }
  }
}
