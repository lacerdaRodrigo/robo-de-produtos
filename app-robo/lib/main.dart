import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'core/api/construcao.dart';
import 'core/autenticacao/configuracao_firebase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final inicializacao = await ConfiguracaoFirebase.inicializar();
  final autenticador = inicializacao.autenticador;
  if (autenticador == null) {
    runApp(RadarApp.configuracaoPendente(inicializacao.mensagem!));
    return;
  }

  runApp(
    RadarApp.comAutenticacao(
      autenticador: autenticador,
      api: construirApi(
        provedorToken: autenticador.token,
        provedorAppCheck: autenticador.tokenAppCheck,
      ),
    ),
  );
}
