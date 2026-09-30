import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/api/api.dart';
import '../core/api/construcao.dart';
import '../core/autenticacao/autenticador.dart';
import '../core/autenticacao/configuracao_firebase.dart';
import 'autenticacao/portao.dart';
import 'componentes/estados.dart';
import 'inicializacao/pagina_abertura.dart';
import 'navegacao/moldura.dart';
import 'tema/aparencia.dart';
import 'tema/tema.dart';
import 'tema/tokens.dart';

/// Raiz do aplicativo Radar de Benefícios.
///
/// Produção usa [RadarApp.inicializando] para exibir a abertura enquanto o
/// acesso seguro é preparado. Os outros construtores permitem isolar jornadas
/// nos testes sem repetir a configuração do Firebase.
class RadarApp extends StatefulWidget {
  const RadarApp.semAutenticacaoParaTeste({
    super.key,
    required this.api,
    this.controladorAparencia,
  }) : autenticador = null,
       erroConfiguracao = null,
       inicializador = null,
       fabricaApi = null;

  const RadarApp.comAutenticacao({
    super.key,
    required this.api,
    required this.autenticador,
    this.controladorAparencia,
  }) : erroConfiguracao = null,
       inicializador = null,
       fabricaApi = null;

  factory RadarApp.inicializando({
    Key? key,
    InicializadorAcesso? inicializar,
    FabricaApiAutenticada? fabricarApi,
    ControladorAparencia? controladorAparencia,
  }) => RadarApp._inicializando(
    key: key,
    inicializador: inicializar ?? ConfiguracaoFirebase.inicializar,
    fabricaApi: fabricarApi ?? _fabricarApi,
    controladorAparencia: controladorAparencia,
  );

  const RadarApp._inicializando({
    super.key,
    required this.inicializador,
    required this.fabricaApi,
    this.controladorAparencia,
  }) : api = null,
       autenticador = null,
       erroConfiguracao = null;

  RadarApp.configuracaoPendente(
    String mensagem, {
    super.key,
    this.controladorAparencia,
  }) : api = construirApi(),
       autenticador = null,
       erroConfiguracao = mensagem,
       inicializador = null,
       fabricaApi = null;

  final Api? api;
  final Autenticador? autenticador;
  final String? erroConfiguracao;
  final InicializadorAcesso? inicializador;
  final FabricaApiAutenticada? fabricaApi;
  final ControladorAparencia? controladorAparencia;

  static Api _fabricarApi(Autenticador autenticador) => construirApi(
    provedorToken: autenticador.token,
    provedorAppCheck: autenticador.tokenAppCheck,
  );

  @override
  State<RadarApp> createState() => _EstadoRadarApp();
}

class _EstadoRadarApp extends State<RadarApp> {
  static const _larguraLayoutAmplo = 920.0;

  late final bool _controladorProprio = widget.controladorAparencia == null;
  late final ControladorAparencia _aparencia =
      widget.controladorAparencia ?? ControladorAparencia();

  @override
  void initState() {
    super.initState();
    unawaited(_aparencia.carregar());
  }

  @override
  void dispose() {
    if (_controladorProprio) _aparencia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _aparencia,
      builder: (context, _) => MaterialApp(
        title: 'Radar de Benefícios',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const <Locale>[Locale('pt', 'BR')],
        theme: TemaRadar.claro(),
        darkTheme: TemaRadar.escuro(),
        themeMode: _aparencia.modo,
        builder: (context, child) => LayoutBuilder(
          builder: (context, limites) {
            final preservarClaro = limites.maxWidth >= _larguraLayoutAmplo;
            final temaEfetivo = preservarClaro
                ? TemaRadar.claro()
                : Theme.of(context);
            final cores =
                temaEfetivo.extension<CoresRadar>() ?? CoresRadar.de(context);
            final iconesClaros = temaEfetivo.brightness == Brightness.dark;
            final barrasSistema = SystemUiOverlayStyle(
              statusBarColor: cores.canvas,
              statusBarBrightness: temaEfetivo.brightness,
              statusBarIconBrightness: iconesClaros
                  ? Brightness.light
                  : Brightness.dark,
              systemNavigationBarColor: cores.superficie,
              systemNavigationBarDividerColor: cores.borda,
              systemNavigationBarIconBrightness: iconesClaros
                  ? Brightness.light
                  : Brightness.dark,
            );
            final media = MediaQuery.of(context);
            final mediaComMovimento = media.copyWith(
              disableAnimations:
                  media.disableAnimations || _aparencia.reduzirMovimento,
            );
            final conteudo = preservarClaro
                ? Theme(data: temaEfetivo, child: child!)
                : child!;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: barrasSistema,
              child: MediaQuery(
                data: mediaComMovimento,
                child: AparenciaRadar(controlador: _aparencia, child: conteudo),
              ),
            );
          },
        ),
        home: widget.inicializador != null
            ? PaginaAbertura(
                inicializar: widget.inicializador!,
                fabricarApi: widget.fabricaApi!,
              )
            : widget.erroConfiguracao != null
            ? Scaffold(body: EstadoFalha(mensagem: widget.erroConfiguracao!))
            : widget.autenticador != null
            ? PortaoAutenticacao(
                autenticador: widget.autenticador!,
                api: widget.api!,
              )
            : MolduraRadar(api: widget.api!),
      ),
    );
  }
}
