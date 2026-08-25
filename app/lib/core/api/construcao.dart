import 'package:http/http.dart' as http;

import '../ambiente.dart';
import 'api_v1.dart';
import 'cliente.dart';

/// Constrói a `ApiV1` real do app, apontando para a URL definida em
/// `Ambiente`. É o único lugar que cria o `http.Client` de produção; testes e
/// widgets injetam uma `ApiV1` com cliente falso (FASE3), nunca a rede.
ApiV1 construirApi({
  http.Client? cliente,
  ProvedorToken? provedorToken,
  ProvedorToken? provedorAppCheck,
}) {
  return ApiV1(
    cliente: ClienteApi(
      baseUrl: Ambiente.baseUrlApi,
      cliente: cliente ?? http.Client(),
      provedorToken: provedorToken,
      provedorAppCheck: provedorAppCheck,
    ),
    paginaPadrao: Ambiente.paginaPadrao,
  );
}
