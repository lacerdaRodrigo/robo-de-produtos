import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../ambiente.dart';
import 'autenticador.dart';
import 'autenticador_firebase.dart';

class InicializacaoFirebase {
  const InicializacaoFirebase._({this.autenticador, this.mensagem});

  const InicializacaoFirebase.pronta(Autenticador autenticador)
    : this._(autenticador: autenticador);

  const InicializacaoFirebase.pendente(String mensagem)
    : this._(mensagem: mensagem);

  final Autenticador? autenticador;
  final String? mensagem;

  bool get pronta => autenticador != null;
}

abstract final class ConfiguracaoFirebase {
  static FirebaseOptions? opcoesAtuais() {
    try {
      return DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      return null;
    }
  }

  static Future<InicializacaoFirebase> inicializar() async {
    final opcoes = opcoesAtuais();
    if (opcoes == null) {
      return const InicializacaoFirebase.pendente(
        'O acesso do piloto ainda não foi configurado neste build.',
      );
    }
    if (kIsWeb &&
        !kDebugMode &&
        Ambiente.appCheckAtivo &&
        Ambiente.firebaseRecaptchaSiteKey.trim().isEmpty) {
      return const InicializacaoFirebase.pendente(
        'A proteção deste build Web ainda não foi configurada.',
      );
    }

    try {
      await Firebase.initializeApp(options: opcoes);
      if (Ambiente.appCheckAtivo) {
        await FirebaseAppCheck.instance.activate(
          providerWeb: kIsWeb
              ? kDebugMode
                    ? WebDebugProvider()
                    : ReCaptchaV3Provider(Ambiente.firebaseRecaptchaSiteKey)
              : null,
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      }
      return InicializacaoFirebase.pronta(
        AutenticadorFirebase(appCheckAtivo: Ambiente.appCheckAtivo),
      );
    } catch (_) {
      return const InicializacaoFirebase.pendente(
        'Não foi possível iniciar o acesso seguro deste build.',
      );
    }
  }
}
