import 'package:flutter/foundation.dart';

import '../../core/api/modelos.dart';

/// Estado persistido de categorias acompanhadas do Compre direto.
///
/// Guarda somente o catálogo real lido da API; nunca uma taxonomia fixa. A
/// edição acontece no bottom sheet e o salvamento usa o método autorizado.
class ControladorCategoriasAcompanhadas extends ChangeNotifier {
  ControladorCategoriasAcompanhadas({
    required this.carregar,
    required this.salvar,
  });

  final Future<CatalogoCategoriasRadarUsuario> Function() carregar;
  final Future<CatalogoCategoriasRadarUsuario> Function(List<String> slugs)
  salvar;

  CatalogoCategoriasRadarUsuario? _catalogo;
  bool _carregando = false;
  bool _salvando = false;
  Object? _erro;
  String? _erroSalvar;

  CatalogoCategoriasRadarUsuario? get catalogo => _catalogo;
  bool get carregando => _carregando;
  bool get salvando => _salvando;
  Object? get erro => _erro;
  String? get erroSalvar => _erroSalvar;

  bool get configurado => _catalogo?.configurada ?? false;

  int get totalAcompanhadas => _catalogo?.slugsAcompanhados.length ?? 0;

  Set<String> get slugsSelecionadosDiretos =>
      _catalogo?.slugsSelecionadosDiretos ?? const <String>{};

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

  /// Salva a seleção direta; em falha mantém o catálogo anterior confirmado.
  Future<bool> salvarSelecao(Set<String> slugs) async {
    _salvando = true;
    _erroSalvar = null;
    notifyListeners();
    try {
      _catalogo = await salvar(slugs.toList()..sort());
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
