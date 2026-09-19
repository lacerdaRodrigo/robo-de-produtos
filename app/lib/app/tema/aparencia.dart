import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Persistência mínima da aparência, isolada da regra que decide o tema.
abstract interface class PreferenciasAparencia {
  Future<ThemeMode?> carregar();

  Future<void> salvar(ThemeMode modo);

  Future<bool?> carregarReduzirMovimento();

  Future<void> salvarReduzirMovimento(bool valor);
}

/// Usa as preferências nativas do Android/iOS sem levar essa decisão ao Web.
class PreferenciasAparenciaNativas implements PreferenciasAparencia {
  const PreferenciasAparenciaNativas();

  static const _canal = MethodChannel('br.com.radarbeneficios.app/aparencia');

  bool get _disponivel =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<ThemeMode?> carregar() async {
    if (!_disponivel) return null;
    final valor = await _canal.invokeMethod<String>('carregar');
    return switch (valor) {
      'claro' => ThemeMode.light,
      'escuro' => ThemeMode.dark,
      _ => null,
    };
  }

  @override
  Future<void> salvar(ThemeMode modo) async {
    if (!_disponivel) return;
    final valor = switch (modo) {
      ThemeMode.light => 'claro',
      ThemeMode.dark => 'escuro',
      ThemeMode.system => null,
    };
    await _canal.invokeMethod<void>('salvar', <String, Object?>{'modo': valor});
  }

  @override
  Future<bool?> carregarReduzirMovimento() async {
    if (!_disponivel) return null;
    final valor = await _canal.invokeMethod<bool>('carregar_movimento');
    return valor;
  }

  @override
  Future<void> salvarReduzirMovimento(bool valor) async {
    if (!_disponivel) return;
    await _canal.invokeMethod<void>('salvar_movimento', <String, Object?>{
      'valor': valor,
    });
  }
}

/// Estado de aparência do app nativo compacto.
///
/// A primeira execução acompanha o sistema. Depois da escolha explícita, o
/// valor muda imediatamente e é persistido sem segurar a abertura do app.
class ControladorAparencia extends ChangeNotifier {
  ControladorAparencia({
    PreferenciasAparencia? preferencias,
    ThemeMode modoInicial = ThemeMode.system,
  }) : _preferencias = preferencias ?? const PreferenciasAparenciaNativas(),
       _modo = modoInicial;

  final PreferenciasAparencia _preferencias;
  ThemeMode _modo;
  bool _reduzirMovimento = false;
  Future<void>? _carregamento;
  bool _descartado = false;
  bool _houveEscolhaLocal = false;
  bool _houveEscolhaMovimento = false;

  ThemeMode get modo => _modo;
  bool get reduzirMovimento => _reduzirMovimento;

  Future<void> carregar() => _carregamento ??= _carregar();

  Future<void> _carregar() async {
    try {
      final resultados = await Future.wait<Object?>([
        _preferencias.carregar(),
        _preferencias.carregarReduzirMovimento(),
      ]);
      if (_descartado) return;
      var alterou = false;
      final salvo = resultados[0] as ThemeMode?;
      if (!_houveEscolhaLocal && salvo != null && salvo != _modo) {
        _modo = salvo;
        alterou = true;
      }
      final movimento = resultados[1] as bool?;
      if (!_houveEscolhaMovimento &&
          movimento != null &&
          movimento != _reduzirMovimento) {
        _reduzirMovimento = movimento;
        alterou = true;
      }
      if (alterou) notifyListeners();
    } on MissingPluginException {
      // Testes e plataformas não suportadas continuam com o tema do sistema.
    } on PlatformException {
      // Falha local de leitura não impede a abertura do aplicativo.
    } on Object {
      // Preferência corrompida ou indisponível também volta ao tema do sistema.
    }
  }

  /// Alterna entre claro e escuro e informa se a escolha pôde ser persistida.
  Future<bool> alternar(Brightness brilhoAtual) async {
    final proximo = brilhoAtual == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    return definir(proximo);
  }

  /// Define a preferência completa, incluindo o retorno ao tema do sistema.
  Future<bool> definir(ThemeMode proximo) async {
    _houveEscolhaLocal = true;
    if (_modo != proximo) {
      _modo = proximo;
      notifyListeners();
    }
    try {
      await _preferencias.salvar(proximo);
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on Object {
      return false;
    }
  }

  Future<bool> definirReduzirMovimento(bool valor) async {
    _houveEscolhaMovimento = true;
    if (_reduzirMovimento != valor) {
      _reduzirMovimento = valor;
      notifyListeners();
    }
    try {
      await _preferencias.salvarReduzirMovimento(valor);
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on Object {
      return false;
    }
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}

/// Disponibiliza o controlador sem acoplar as telas à raiz do aplicativo.
class AparenciaRadar extends InheritedNotifier<ControladorAparencia> {
  const AparenciaRadar({
    super.key,
    required ControladorAparencia controlador,
    required super.child,
  }) : super(notifier: controlador);

  static ControladorAparencia? talvezDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AparenciaRadar>()?.notifier;
}
