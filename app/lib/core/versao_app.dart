import 'package:package_info_plus/package_info_plus.dart';

/// Lê a versão do aplicativo em runtime, sem hardcode no rodapé.
abstract final class VersaoApp {
  static Future<String> versao() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '—';
    }
  }
}
