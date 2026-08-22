/// Configuração de ambiente do app.
///
/// A URL da API pode ser substituída no build com
/// `--dart-define=API_URL=...`. O padrão público permite instalar o APK em um
/// aparelho externo sem fazê-lo apontar para o `localhost` do próprio celular.
/// Nenhum segredo mora aqui (PLANO §6).
abstract final class Ambiente {
  /// Desenvolvimento local pode sobrescrever com `http://localhost:3000`.
  static const baseUrlApi = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://robo-livelo.vercel.app',
  );

  static const paginaPadrao = 20;
  static const paginaMaxima = 50;

  /// App Check Web usa uma chave pública própria do reCAPTCHA. Os demais
  /// identificadores públicos são gerados pelo FlutterFire.
  static const firebaseRecaptchaSiteKey = String.fromEnvironment(
    'FIREBASE_RECAPTCHA_SITE_KEY',
  );
  static const appCheckAtivo = bool.fromEnvironment('ATIVAR_APP_CHECK');
}
