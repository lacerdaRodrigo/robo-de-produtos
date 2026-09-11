import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/api/api.dart';
import '../../core/versao_app.dart';

/// Integra o FCM sem tornar a permissão um requisito para usar o histórico.
class GerenciadorNotificacoes {
  GerenciadorNotificacoes({required this.api, required this.aoAbrirCentral});

  final Api api;
  final ValueChanged<String?> aoAbrirCentral;
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _aberturas;
  String? _ultimoToken;

  Future<void> iniciar() async {
    if (kIsWeb) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final permissao = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (permissao.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null) await _registrar(token);
      _tokens ??= messaging.onTokenRefresh.listen(_registrar);
      _aberturas ??= FirebaseMessaging.onMessageOpenedApp.listen(_abrir);
      final inicial = await messaging.getInitialMessage();
      if (inicial != null) _abrir(inicial);
    } catch (_) {
      // Firebase/FCM indisponível não impede o acesso ao histórico.
    }
  }

  Future<void> _registrar(String token) async {
    if (token == _ultimoToken) return;
    _ultimoToken = token;
    try {
      await api.registrarDispositivo(
        token: token,
        plataforma: switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => 'desconhecida',
        },
        versaoApp: await VersaoApp.versao(),
      );
    } catch (_) {
      // O histórico funciona mesmo quando a API ou a configuração FCM está indisponível.
    }
  }

  void _abrir(RemoteMessage mensagem) =>
      aoAbrirCentral(mensagem.data['coleta']?.toString());

  Future<void> removerAtual() async {
    final token = _ultimoToken;
    if (token != null) {
      try {
        await api.removerDispositivo(token);
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    await _tokens?.cancel();
    await _aberturas?.cancel();
  }
}
