import 'package:flutter/material.dart';

import '../core/api/api_v1.dart';
import '../core/api/construcao.dart';
import 'navegacao/moldura.dart';
import 'tema/tema.dart';

/// Raiz do aplicativo Radar de Benefícios.
///
/// Fase 4.1: shell de navegação + integração real com a API. `api` é
/// injetável para os testes usarem cliente falso; sem ele, o app constrói a
/// API real (PLANO §15, Fase 4).
class RadarApp extends StatelessWidget {
  RadarApp({super.key, ApiV1? api}) : api = api ?? construirApi();

  final ApiV1 api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radar de Benefícios',
      debugShowCheckedModeBanner: false,
      theme: TemaRadar.claro(),
      darkTheme: TemaRadar.escuro(),
      themeMode: ThemeMode.light,
      home: MolduraRadar(api: api),
    );
  }
}
