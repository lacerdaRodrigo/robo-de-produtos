import 'package:flutter/material.dart';

import '../core/api/api_v1.dart';
import '../core/api/construcao.dart';
import '../core/autenticacao/autenticador.dart';
import 'autenticacao/portao.dart';
import 'componentes/estados.dart';
import 'navegacao/moldura.dart';
import 'tema/tema.dart';

/// Raiz do aplicativo Radar de Benefícios.
///
/// Produção sempre usa [RadarApp.comAutenticacao]. O construtor sem gate tem
/// nome explícito e existe apenas para widgets antigos continuarem testáveis.
class RadarApp extends StatelessWidget {
  const RadarApp.semAutenticacaoParaTeste({super.key, required this.api})
    : autenticador = null,
      erroConfiguracao = null;

  const RadarApp.comAutenticacao({
    super.key,
    required this.api,
    required this.autenticador,
  }) : erroConfiguracao = null;

  RadarApp.configuracaoPendente(String mensagem, {super.key})
    : api = construirApi(),
      autenticador = null,
      erroConfiguracao = mensagem;

  final ApiV1 api;
  final Autenticador? autenticador;
  final String? erroConfiguracao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar de Benefícios',
      debugShowCheckedModeBanner: false,
      theme: TemaRadar.claro(),
      darkTheme: TemaRadar.escuro(),
      themeMode: ThemeMode.light,
      home: erroConfiguracao != null
          ? Scaffold(body: EstadoFalha(mensagem: erroConfiguracao!))
          : autenticador != null
          ? PortaoAutenticacao(autenticador: autenticador!, api: api)
          : MolduraRadar(api: api),
    );
  }
}
