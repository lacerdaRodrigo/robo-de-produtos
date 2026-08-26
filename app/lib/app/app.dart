import 'package:flutter/material.dart';

import '../core/api/api.dart';
import '../core/api/construcao.dart';
import '../core/autenticacao/autenticador.dart';
import '../core/autenticacao/configuracao_firebase.dart';
import 'autenticacao/portao.dart';
import 'componentes/estados.dart';
import 'inicializacao/pagina_abertura.dart';
import 'navegacao/moldura.dart';
import 'tema/tema.dart';

/// Raiz do aplicativo Radar de Benefícios.
///
/// Produção usa [RadarApp.inicializando] para exibir a abertura enquanto o
/// acesso seguro é preparado. Os outros construtores permitem isolar jornadas
/// nos testes sem repetir a configuração do Firebase.
class RadarApp extends StatelessWidget {
  const RadarApp.semAutenticacaoParaTeste({super.key, required this.api})
    : autenticador = null,
      erroConfiguracao = null,
      inicializador = null,
      fabricaApi = null;

  const RadarApp.comAutenticacao({
    super.key,
    required this.api,
    required this.autenticador,
  }) : erroConfiguracao = null,
       inicializador = null,
       fabricaApi = null;

  factory RadarApp.inicializando({
    Key? key,
    InicializadorAcesso? inicializar,
    FabricaApiAutenticada? fabricarApi,
  }) => RadarApp._inicializando(
    key: key,
    inicializador: inicializar ?? ConfiguracaoFirebase.inicializar,
    fabricaApi: fabricarApi ?? _fabricarApi,
  );

  const RadarApp._inicializando({
    super.key,
    required this.inicializador,
    required this.fabricaApi,
  }) : api = null,
       autenticador = null,
       erroConfiguracao = null;

  RadarApp.configuracaoPendente(String mensagem, {super.key})
    : api = construirApi(),
      autenticador = null,
      erroConfiguracao = mensagem,
      inicializador = null,
      fabricaApi = null;

  final Api? api;
  final Autenticador? autenticador;
  final String? erroConfiguracao;
  final InicializadorAcesso? inicializador;
  final FabricaApiAutenticada? fabricaApi;

  static Api _fabricarApi(Autenticador autenticador) => construirApi(
    provedorToken: autenticador.token,
    provedorAppCheck: autenticador.tokenAppCheck,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar de Benefícios',
      debugShowCheckedModeBanner: false,
      theme: TemaRadar.claro(),
      darkTheme: TemaRadar.escuro(),
      themeMode: ThemeMode.light,
      home: inicializador != null
          ? PaginaAbertura(
              inicializar: inicializador!,
              fabricarApi: fabricaApi!,
            )
          : erroConfiguracao != null
          ? Scaffold(body: EstadoFalha(mensagem: erroConfiguracao!))
          : autenticador != null
          ? PortaoAutenticacao(autenticador: autenticador!, api: api!)
          : MolduraRadar(api: api!),
    );
  }
}
