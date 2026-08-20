/// Configuração de ambiente do app.
///
/// A URL da API pode ser injetada no build com `--dart-define=API_URL=...`.
/// Padrão para o dev Web contra o site local (Vercel em produção usa a mesma
/// origem). Nenhum segredo mora aqui (PLANO §6).
abstract final class Ambiente {
  /// Ex.: `http://localhost:3000` (dev) ou a mesma origem do deploy.
  static const baseUrlApi = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const paginaPadrao = 20;
  static const paginaMaxima = 50;
}
