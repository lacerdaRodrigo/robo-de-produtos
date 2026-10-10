import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Escopos de filtro do app. Cada um tem UMA especificação e UM estado,
/// compartilhados por qualquer tela que abrir a `FolhaFiltros` desse escopo.
enum EscopoFiltro { parceirosInter, compreDireto, livelo, pichau, meuRadar, central }

// ---------------------------------------------------------------------------
// Valores
// ---------------------------------------------------------------------------

/// Faixa mínima/máxima em texto (decimais pt-BR digitados pelo usuário).
@immutable
class FaixaValor {
  const FaixaValor({this.minimo = '', this.maximo = ''});

  final String minimo;
  final String maximo;

  bool get vazia => minimo.trim().isEmpty && maximo.trim().isEmpty;

  @override
  bool operator ==(Object other) =>
      other is FaixaValor && other.minimo == minimo && other.maximo == maximo;

  @override
  int get hashCode => Object.hash(minimo, maximo);
}

/// Valores aplicados de um escopo, indexados pelo `id` de cada seção.
///
/// Tipos por seção: [SecaoEscolha] única → `String`; múltipla →
/// `Set<String>`; [SecaoFaixa] → [FaixaValor]; [SecaoAlternar] → `bool`.
@immutable
class ValoresFiltro {
  const ValoresFiltro([this._mapa = const <String, Object?>{}]);

  final Map<String, Object?> _mapa;

  String? texto(String id) => _mapa[id] as String?;
  Set<String> conjunto(String id) =>
      (_mapa[id] as Set<String>?) ?? const <String>{};
  FaixaValor faixa(String id) => (_mapa[id] as FaixaValor?) ?? const FaixaValor();
  bool booleano(String id) => (_mapa[id] as bool?) ?? false;
  Object? bruto(String id) => _mapa[id];

  ValoresFiltro com(String id, Object? valor) =>
      ValoresFiltro(<String, Object?>{..._mapa, id: valor});

  @override
  bool operator ==(Object other) {
    if (other is! ValoresFiltro || other._mapa.length != _mapa.length) {
      return false;
    }
    for (final entrada in _mapa.entries) {
      final outro = other._mapa[entrada.key];
      final atual = entrada.value;
      if (atual is Set<String> && outro is Set<String>) {
        if (!setEquals(atual, outro)) return false;
      } else if (atual != outro) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _mapa.entries.map(
      (e) => Object.hash(
        e.key,
        e.value is Set ? Object.hashAllUnordered(e.value as Set) : e.value,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Especificação declarativa
// ---------------------------------------------------------------------------

@immutable
class OpcaoFiltro {
  const OpcaoFiltro(this.valor, this.rotulo);
  final String valor;
  final String rotulo;
}

/// Uma seção da folha. As subclasses são o vocabulário completo de filtros
/// do app; se uma tela precisar de outro tipo, ele entra aqui primeiro.
sealed class SecaoFiltro {
  const SecaoFiltro({required this.id, required this.titulo});

  final String id;
  final String titulo;

  Object? get padrao;

  /// Ordenação não conta como filtro ativo; as demais contam quando diferem
  /// do padrão.
  bool contaComoAtivo(Object? valor);

  /// Mensagem de erro de validação, ou `null`.
  String? validar(Object? valor) => null;
}

/// Chips de escolha única ou múltipla. Também serve para ordenação
/// (`ordenacao: true`).
class SecaoEscolha extends SecaoFiltro {
  const SecaoEscolha({
    required super.id,
    required super.titulo,
    required this.opcoes,
    this.multipla = false,
    this.ordenacao = false,
    String? padraoUnico,
    Set<String> padraoMultiplo = const <String>{},
  }) : _padraoUnico = padraoUnico,
       _padraoMultiplo = padraoMultiplo;

  final List<OpcaoFiltro> opcoes;
  final bool multipla;
  final bool ordenacao;
  final String? _padraoUnico;
  final Set<String> _padraoMultiplo;

  @override
  Object? get padrao =>
      multipla ? _padraoMultiplo : (_padraoUnico ?? opcoes.first.valor);

  @override
  bool contaComoAtivo(Object? valor) {
    if (ordenacao) return false;
    if (multipla) {
      return !setEquals(
        (valor as Set<String>?) ?? const <String>{},
        _padraoMultiplo,
      );
    }
    return valor != padrao;
  }

  String rotuloDe(String? valor) {
    for (final opcao in opcoes) {
      if (opcao.valor == valor) return opcao.rotulo;
    }
    return valor ?? '';
  }
}

/// Faixa mínimo/máximo para preço, cashback ou pontos. Compara decimais sem
/// `double` (regra de dinheiro do PRD).
class SecaoFaixa extends SecaoFiltro {
  const SecaoFaixa({
    required super.id,
    required super.titulo,
    this.rotuloMinimo = 'Mínimo',
    this.rotuloMaximo = 'Máximo',
  });

  final String rotuloMinimo;
  final String rotuloMaximo;

  @override
  Object? get padrao => const FaixaValor();

  @override
  bool contaComoAtivo(Object? valor) =>
      !((valor as FaixaValor?) ?? const FaixaValor()).vazia;

  @override
  String? validar(Object? valor) {
    final faixa = (valor as FaixaValor?) ?? const FaixaValor();
    final minimo = centavosDe(faixa.minimo);
    final maximo = centavosDe(faixa.maximo);
    if (faixa.minimo.trim().isNotEmpty && minimo == null) {
      return 'Valor mínimo inválido.';
    }
    if (faixa.maximo.trim().isNotEmpty && maximo == null) {
      return 'Valor máximo inválido.';
    }
    if (minimo != null && maximo != null && minimo > maximo) {
      return 'O máximo deve ser maior ou igual ao mínimo.';
    }
    return null;
  }

  /// "1.234,5" → 123450. Aceita vírgula ou ponto como decimal.
  static int? centavosDe(String texto) {
    var limpo = texto.trim().replaceAll(' ', '');
    if (limpo.isEmpty) return null;
    if (limpo.contains(',')) {
      limpo = limpo.replaceAll('.', '').replaceAll(',', '.');
    }
    final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(limpo);
    if (m == null) return null;
    final inteiro = int.parse(m.group(1)!);
    final fracao = (m.group(2) ?? '').padRight(2, '0');
    return inteiro * 100 + int.parse(fracao);
  }

  /// Converte o texto digitado para o decimal com ponto esperado pela API.
  static String? paraApi(String texto) {
    final centavos = centavosDe(texto);
    if (centavos == null) return null;
    final fracao = (centavos % 100).toString().padLeft(2, '0');
    return '${centavos ~/ 100}.$fracao';
  }
}

/// Interruptor simples ("Somente com cashback", "Somente não lidos").
class SecaoAlternar extends SecaoFiltro {
  const SecaoAlternar({
    required super.id,
    required super.titulo,
    required this.descricao,
    this.padraoLigado = false,
  });

  final String descricao;
  final bool padraoLigado;

  @override
  Object? get padrao => padraoLigado;

  @override
  bool contaComoAtivo(Object? valor) => (valor as bool? ?? false) != padraoLigado;
}

@immutable
class EspecFiltros {
  const EspecFiltros({required this.origem, required this.secoes});

  /// Nome mostrado no subtítulo da folha ("Pichau", "Livelo"…).
  final String origem;
  final List<SecaoFiltro> secoes;

  ValoresFiltro get padroes {
    var valores = const ValoresFiltro();
    for (final secao in secoes) {
      valores = valores.com(secao.id, secao.padrao);
    }
    return valores;
  }

  int contarAtivos(ValoresFiltro valores) => secoes
      .where((s) => s.contaComoAtivo(valores.bruto(s.id)))
      .length;

  /// Primeiro erro de validação, ou `null`.
  String? validar(ValoresFiltro valores) {
    for (final secao in secoes) {
      final erro = secao.validar(valores.bruto(secao.id));
      if (erro != null) return erro;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Estado global
// ---------------------------------------------------------------------------

/// Estado aplicado de UM escopo. Telas escutam com `ValueListenableBuilder`
/// ou `addListener` e refazem a consulta quando o valor muda.
class ControladorFiltros extends ValueNotifier<ValoresFiltro> {
  ControladorFiltros(this.espec) : super(espec.padroes);

  final EspecFiltros espec;

  int get ativos => espec.contarAtivos(value);

  void aplicar(ValoresFiltro novos) => value = novos;

  void limpar() => value = espec.padroes;
}

/// Todos os filtros do app. Criado UMA vez e provido por [EscopoDs] acima do
/// `MaterialApp`, para que o estado sobreviva a navegação, troca de aba e
/// folhas abertas no navigator raiz.
class RegistroFiltros {
  RegistroFiltros(Map<EscopoFiltro, EspecFiltros> especs)
    : _controladores = <EscopoFiltro, ControladorFiltros>{
        for (final e in especs.entries) e.key: ControladorFiltros(e.value),
      };

  final Map<EscopoFiltro, ControladorFiltros> _controladores;

  ControladorFiltros de(EscopoFiltro escopo) {
    final controlador = _controladores[escopo];
    if (controlador == null) {
      throw StateError('Escopo de filtro sem especificação: $escopo');
    }
    return controlador;
  }

  bool possui(EscopoFiltro escopo) => _controladores.containsKey(escopo);

  /// Usado ao sair da conta: volta tudo ao padrão.
  void limparTudo() {
    for (final c in _controladores.values) {
      c.limpar();
    }
  }

  void dispose() {
    for (final c in _controladores.values) {
      c.dispose();
    }
  }
}

/// Provedor do estado compartilhado do Radar DS.
///
/// ```dart
/// EscopoDs(
///   filtros: RegistroFiltros(especsDoApp),
///   child: MaterialApp(...),
/// )
/// ```
class EscopoDs extends InheritedWidget {
  const EscopoDs({super.key, required this.filtros, required super.child});

  final RegistroFiltros filtros;

  static RegistroFiltros filtrosDe(BuildContext context) {
    final escopo = context.getInheritedWidgetOfExactType<EscopoDs>();
    if (escopo == null) {
      throw FlutterError(
        'EscopoDs não encontrado. Envolva o MaterialApp com EscopoDs.',
      );
    }
    return escopo.filtros;
  }

  @override
  bool updateShouldNotify(EscopoDs oldWidget) => filtros != oldWidget.filtros;
}

/// Atalho: `context.filtros(EscopoFiltro.pichau)`.
extension FiltrosContexto on BuildContext {
  ControladorFiltros filtros(EscopoFiltro escopo) =>
      EscopoDs.filtrosDe(this).de(escopo);
}
