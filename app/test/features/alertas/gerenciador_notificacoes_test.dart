import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/features/alertas/gerenciador_notificacoes.dart';

const _canalLocal = MethodChannel('dexterous.com/flutter/local_notifications');

Api _api(http.Client cliente) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: () async => 'token-de-teste',
    cliente: cliente,
  ),
);

List<MethodCall> _configurarCanalAndroid() {
  final chamadas = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_canalLocal, (chamada) async {
        chamadas.add(chamada);
        return switch (chamada.method) {
          'initialize' => true,
          'getNotificationAppLaunchDetails' => <String, Object?>{
            'notificationLaunchedApp': false,
          },
          _ => null,
        };
      });
  AndroidFlutterLocalNotificationsPlugin.registerWith();
  return chamadas;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_canalLocal, null);
  });

  test('apresenta mensagem FCM completa no canal Android de alertas', () async {
    final chamadas = _configurarCanalAndroid();
    final mensagens = StreamController<RemoteMessage>();
    final aberturas = StreamController<RemoteMessage>();
    final coletasAbertas = <String?>[];
    var pedidosDePermissao = 0;
    final gerente = GerenciadorNotificacoes(
      api: _api(http_testing.MockClient((_) async => http.Response('{}', 200))),
      aoAbrirCentral: coletasAbertas.add,
      statusPermissao: () async {
        pedidosDePermissao += 1;
        return AuthorizationStatus.authorized;
      },
      obterToken: () async => null,
      tokensAtualizados: const Stream<String>.empty(),
      mensagensEmPrimeiroPlano: mensagens.stream,
      aberturas: aberturas.stream,
      mensagemInicial: () async => null,
      lerVersaoApp: () async => '1.74.0',
    );

    await gerente.iniciar();
    mensagens.add(
      RemoteMessage(
        messageId: 'alerta-pichau-1',
        notification: const RemoteNotification(
          title: 'Pichau: Ryzen 5 5600G',
          body: 'Preço Pix caiu de R\$ 899,90 para R\$ 799,90.',
        ),
        data: <String, dynamic>{'rota': 'alertas', 'coleta': 'coleta-123'},
      ),
    );
    aberturas.add(
      RemoteMessage(data: <String, dynamic>{'coleta': 'coleta-123'}),
    );
    await Future<void>.delayed(Duration.zero);

    final chamadaShow = chamadas.singleWhere(
      (chamada) => chamada.method == 'show',
    );
    final dados = Map<Object?, Object?>.from(chamadaShow.arguments as Map);
    final plataforma = Map<Object?, Object?>.from(
      dados['platformSpecifics'] as Map,
    );
    final chamadaCanal = chamadas.singleWhere(
      (chamada) => chamada.method == 'createNotificationChannel',
    );
    final dadosCanal = Map<Object?, Object?>.from(
      chamadaCanal.arguments as Map,
    );
    expect(dados['title'], 'Pichau: Ryzen 5 5600G');
    expect(dados['body'], 'Preço Pix caiu de R\$ 899,90 para R\$ 799,90.');
    expect(jsonDecode(dados['payload'] as String), <String, String>{
      'coleta': 'coleta-123',
    });
    expect(dadosCanal['id'], 'alertas');
    expect(dadosCanal['importance'], Importance.high.value);
    expect(plataforma['channelId'], 'alertas');
    expect(plataforma['importance'], Importance.high.value);
    expect(plataforma['priority'], Priority.high.value);
    expect(
      chamadas.where(
        (chamada) => chamada.method == 'requestNotificationsPermission',
      ),
      isEmpty,
    );
    expect(pedidosDePermissao, 1);
    expect(coletasAbertas, <String?>['coleta-123']);

    await gerente.dispose();
    await mensagens.close();
    await aberturas.close();
  });

  test('escuta o push enquanto a API registra o token', () async {
    final chamadas = _configurarCanalAndroid();
    final mensagens = StreamController<RemoteMessage>();
    final registroIniciado = Completer<void>();
    final respostaRegistro = Completer<http.Response>();
    final cliente = http_testing.MockClient((request) {
      if (request.url.path == '/api/notificacoes/dispositivos') {
        registroIniciado.complete();
        return respostaRegistro.future;
      }
      return Future.value(http.Response('{}', 200));
    });
    final gerente = GerenciadorNotificacoes(
      api: _api(cliente),
      aoAbrirCentral: (_) {},
      statusPermissao: () async => AuthorizationStatus.authorized,
      obterToken: () async => 'token-lento',
      tokensAtualizados: const Stream<String>.empty(),
      mensagensEmPrimeiroPlano: mensagens.stream,
      aberturas: const Stream<RemoteMessage>.empty(),
      mensagemInicial: () async => null,
      lerVersaoApp: () async => '1.74.0',
    );

    final inicializacao = gerente.iniciar();
    await registroIniciado.future.timeout(const Duration(seconds: 2));
    mensagens.add(
      RemoteMessage(
        notification: const RemoteNotification(
          title: 'Livelo: loja parceira',
          body: 'Pontuação subiu para 3 pontos por real.',
        ),
        data: const <String, dynamic>{'coleta': 'coleta-lenta'},
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final chamadaShow = chamadas.singleWhere(
      (chamada) => chamada.method == 'show',
    );
    expect(
      (chamadaShow.arguments as Map<Object?, Object?>)['body'],
      'Pontuação subiu para 3 pontos por real.',
    );

    respostaRegistro.complete(http.Response('{}', 200));
    await inicializacao;
    await gerente.dispose();
    await mensagens.close();
    cliente.close();
  });

  test(
    'tenta registrar novamente o token após falha transitória da API',
    () async {
      _configurarCanalAndroid();
      final tokens = StreamController<String>();
      var tentativas = 0;
      final segundaTentativa = Completer<void>();
      final httpCliente = http_testing.MockClient((request) async {
        if (request.url.path == '/api/notificacoes/dispositivos') {
          tentativas += 1;
          if (tentativas == 1) {
            return http.Response(
              '{"erro":{"codigo":"inesperado","mensagem":"falha"}}',
              503,
            );
          }
          segundaTentativa.complete();
        }
        return http.Response('{}', 200);
      });
      final gerente = GerenciadorNotificacoes(
        api: _api(httpCliente),
        aoAbrirCentral: (_) {},
        statusPermissao: () async => AuthorizationStatus.authorized,
        obterToken: () async => 'token-recuperavel',
        tokensAtualizados: tokens.stream,
        mensagensEmPrimeiroPlano: const Stream<RemoteMessage>.empty(),
        aberturas: const Stream<RemoteMessage>.empty(),
        mensagemInicial: () async => null,
        lerVersaoApp: () async => '1.74.0',
      );

      await gerente.iniciar();
      expect(tentativas, 1);
      tokens.add('token-recuperavel');
      await segundaTentativa.future.timeout(const Duration(seconds: 2));
      expect(tentativas, 2);

      await gerente.dispose();
      await tokens.close();
      httpCliente.close();
    },
  );
}
