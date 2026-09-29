import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/api/api.dart';
import '../../core/versao_app.dart';

/// Integra o FCM sem tornar a permissão um requisito para usar o histórico.
class GerenciadorNotificacoes {
  GerenciadorNotificacoes({
    required this.api,
    required this.aoAbrirCentral,
    @visibleForTesting Future<AuthorizationStatus> Function()? statusPermissao,
    @visibleForTesting Future<String?> Function()? obterToken,
    @visibleForTesting Stream<String>? tokensAtualizados,
    @visibleForTesting Stream<RemoteMessage>? mensagensEmPrimeiroPlano,
    @visibleForTesting Stream<RemoteMessage>? aberturas,
    @visibleForTesting Future<RemoteMessage?> Function()? mensagemInicial,
    @visibleForTesting Future<String> Function()? lerVersaoApp,
  }) : _statusPermissaoInjetado = statusPermissao,
       _obterTokenInjetado = obterToken,
       _tokensAtualizadosInjetados = tokensAtualizados,
       _mensagensEmPrimeiroPlanoInjetadas = mensagensEmPrimeiroPlano,
       _aberturasInjetadas = aberturas,
       _mensagemInicialInjetada = mensagemInicial,
       _lerVersaoAppInjetada = lerVersaoApp;

  static const _canalId = 'alertas';
  static const _canalNome = 'Alertas';
  static const _canalDescricao = 'Mudanças nos itens que você acompanha.';

  final Api api;
  final ValueChanged<String?> aoAbrirCentral;
  final Future<AuthorizationStatus> Function()? _statusPermissaoInjetado;
  final Future<String?> Function()? _obterTokenInjetado;
  final Stream<String>? _tokensAtualizadosInjetados;
  final Stream<RemoteMessage>? _mensagensEmPrimeiroPlanoInjetadas;
  final Stream<RemoteMessage>? _aberturasInjetadas;
  final Future<RemoteMessage?> Function()? _mensagemInicialInjetada;
  final Future<String> Function()? _lerVersaoAppInjetada;
  final FlutterLocalNotificationsPlugin _notificacoesLocais =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _aberturas;
  StreamSubscription<RemoteMessage>? _mensagensEmPrimeiroPlano;
  String? _ultimoToken;
  final Set<String> _tokensEmRegistro = <String>{};

  Future<void> iniciar() async {
    AuthorizationStatus status;
    try {
      status =
          await (_statusPermissaoInjetado?.call() ?? _statusPermissaoAtual());
    } catch (_) {
      // A falha ao consultar FCM não impede o acesso ao histórico.
      return;
    }
    if (status == AuthorizationStatus.denied) return;

    await _configurarApresentacaoEmPrimeiroPlano();

    // Escuta antes de qualquer chamada à API para não perder mensagens enquanto
    // o registro do token aguarda rede.
    _tokens ??=
        (_tokensAtualizadosInjetados ??
                FirebaseMessaging.instance.onTokenRefresh)
            .listen((token) => unawaited(_registrar(token)));
    _aberturas ??= (_aberturasInjetadas ?? FirebaseMessaging.onMessageOpenedApp)
        .listen(_abrir);
    if (defaultTargetPlatform == TargetPlatform.android) {
      _mensagensEmPrimeiroPlano ??=
          (_mensagensEmPrimeiroPlanoInjetadas ?? FirebaseMessaging.onMessage)
              .listen(
                (mensagem) => unawaited(_mostrarEmPrimeiroPlano(mensagem)),
              );
    }

    try {
      final token =
          await (_obterTokenInjetado?.call() ??
              FirebaseMessaging.instance.getToken());
      if (token != null) await _registrar(token);
    } catch (_) {
      // Mensagens e navegação continuam funcionando sem token registrável.
    }

    try {
      final inicial =
          await (_mensagemInicialInjetada?.call() ??
              FirebaseMessaging.instance.getInitialMessage());
      if (inicial != null) _abrir(inicial);
    } catch (_) {
      // A inicialização do FCM não impede o acesso ao histórico.
    }
  }

  /// Solicita somente a decisão do sistema para a tela explícita de permissão.
  /// Retorna nulo quando a plataforma ou o plugin não está disponível.
  Future<AuthorizationStatus?> solicitarPermissao() async {
    try {
      return (await _pedirPermissao(
        FirebaseMessaging.instance,
      )).authorizationStatus;
    } catch (_) {
      return null;
    }
  }

  Future<NotificationSettings> _pedirPermissao(FirebaseMessaging messaging) =>
      messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

  Future<AuthorizationStatus> _statusPermissaoAtual() async =>
      (await _pedirPermissao(FirebaseMessaging.instance)).authorizationStatus;

  Future<void> _configurarApresentacaoEmPrimeiroPlano() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
              alert: true,
              badge: true,
              sound: true,
            );
        return;
      }
      if (defaultTargetPlatform != TargetPlatform.android) return;

      await _notificacoesLocais.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (resposta) =>
            _abrirPayloadLocal(resposta.payload),
      );
      final android = _notificacoesLocais
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _canalId,
          _canalNome,
          description: _canalDescricao,
          importance: Importance.high,
        ),
      );

      final inicial = await _notificacoesLocais
          .getNotificationAppLaunchDetails();
      if (inicial?.didNotificationLaunchApp == true) {
        _abrirPayloadLocal(inicial?.notificationResponse?.payload);
      }
    } catch (_) {
      // Falha na apresentação local não impede cadastro do token nem a Central.
    }
  }

  Future<void> _mostrarEmPrimeiroPlano(RemoteMessage mensagem) async {
    try {
      final titulo =
          _texto(mensagem.notification?.title) ??
          _texto(mensagem.data['title']) ??
          _texto(mensagem.data['titulo']) ??
          'Radar de Benefícios';
      final corpo =
          _texto(mensagem.notification?.body) ??
          _texto(mensagem.data['body']) ??
          _texto(mensagem.data['mensagem']);
      if (corpo == null) return;

      final coleta = _texto(mensagem.data['coleta']);
      final id =
          (mensagem.messageId ?? coleta)?.hashCode ??
          DateTime.now().millisecondsSinceEpoch;
      await _notificacoesLocais.show(
        id: id & 0x7fffffff,
        title: titulo,
        body: corpo,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _canalId,
            _canalNome,
            channelDescription: _canalDescricao,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(
              corpo,
              contentTitle: titulo,
            ),
          ),
        ),
        payload: jsonEncode(<String, String?>{'coleta': coleta}),
      );
    } catch (_) {
      // Uma falha ao apresentar não interrompe o recebimento nem a Central.
    }
  }

  String? _texto(Object? valor) {
    final texto = valor?.toString().trim();
    return texto == null || texto.isEmpty ? null : texto;
  }

  void _abrirPayloadLocal(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final dados = jsonDecode(payload);
      if (dados is Map) aoAbrirCentral(dados['coleta']?.toString());
    } catch (_) {
      // Ignora payloads locais antigos ou malformados.
    }
  }

  Future<void> _registrar(String token) async {
    if (token == _ultimoToken || !_tokensEmRegistro.add(token)) return;
    try {
      await api.registrarDispositivo(
        token: token,
        plataforma: switch (defaultTargetPlatform) {
          TargetPlatform.android => 'android',
          TargetPlatform.iOS => 'ios',
          _ => 'desconhecida',
        },
        versaoApp: await (_lerVersaoAppInjetada?.call() ?? VersaoApp.versao()),
      );
      _ultimoToken = token;
    } catch (_) {
      // O histórico funciona mesmo quando a API ou a configuração FCM está indisponível.
    } finally {
      _tokensEmRegistro.remove(token);
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
    await _mensagensEmPrimeiroPlano?.cancel();
  }
}
