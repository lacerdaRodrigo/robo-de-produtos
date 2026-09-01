import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/core/autenticacao/configuracao_firebase.dart';

void main() {
  test('Android usa debug no debug e Play Integrity no release', () {
    expect(
      ConfiguracaoFirebase.provedorAndroid(debug: true),
      isA<AndroidDebugProvider>(),
    );
    expect(
      ConfiguracaoFirebase.provedorAndroid(debug: false),
      isA<AndroidPlayIntegrityProvider>(),
    );
  });

  test('iOS usa debug no debug e App Attest com fallback no release', () {
    expect(
      ConfiguracaoFirebase.provedorApple(debug: true),
      isA<AppleDebugProvider>(),
    );
    expect(
      ConfiguracaoFirebase.provedorApple(debug: false),
      isA<AppleAppAttestWithDeviceCheckFallbackProvider>(),
    );
  });
}
