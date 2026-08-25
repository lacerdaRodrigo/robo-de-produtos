import 'package:http/http.dart' as http;

import '../ambiente.dart';
import 'api.dart';
import 'cliente.dart';

/// Constrói a `Api` real do app, apontando para a URL definida em
/// `Ambiente`. É o único lugar que cria o `http.Client` de produção; testes e
/// widgets injetam uma `Api` com cliente falso (FASE3), nunca a rede.
Api construirApi({
  http.Client? cliente,
  ProvedorToken? provedorToken,
  ProvedorToken? provedorAppCheck,
}) {
  return Api(
    cliente: ClienteApi(
      baseUrl: Ambiente.baseUrlApi,
      cliente: cliente ?? http.Client(),
      provedorToken: provedorToken,
      provedorAppCheck: provedorAppCheck,
    ),
    paginaPadrao: Ambiente.paginaPadrao,
  );
}
