import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Persistência mínima da aparência, isolada da regra que decide o tema.
abstract interface class PreferenciasAparencia {
  Future<ThemeMode?> carregar();

  Future<void> salvar(ThemeMode modo);
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
  Future<void>? _carregamento;
  bool _descartado = false;
  bool _houveEscolhaLocal = false;

  ThemeMode get modo => _modo;

  Future<void> carregar() => _carregamento ??= _carregar();

  Future<void> _carregar() async {
    try {
      final salvo = await _preferencias.carregar();
      if (_descartado ||
          _houveEscolhaLocal ||
          salvo == null ||
          salvo == _modo) {
        return;
      }
      _modo = salvo;
      notifyListeners();
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
    _houveEscolhaLocal = true;
    final proximo = brilhoAtual == Brightness.dark
        ? ThemeMode.light
        : ThemeMode.dark;
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
