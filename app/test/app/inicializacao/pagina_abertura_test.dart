import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/app.dart';
import 'package:app_robo/app/identidade/logo_radar.dart';
import 'package:app_robo/app/inicializacao/pagina_abertura.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/autenticacao/autenticador.dart';
import 'package:app_robo/core/autenticacao/configuracao_firebase.dart';

const _resumoVazio =
    '{"gerado_em":"2026-08-23T12:00:00Z","estado_geral":"sem_dados",'
    '"livelo":{"estado":"sem_dados"},'
    '"cashback_inter":{"estado":"sem_dados"},'
    '"produtos":{"estado":"sem_dados"}}';

class _AutenticadorFalso implements Autenticador {
  _AutenticadorFalso([this.contaAtual]);

  @override
  ContaAutenticada? contaAtual;

  @override
  Stream<ContaAutenticada?> get mudancas => const Stream.empty();

  @override
  Future<void> entrar({required String email, required String senha}) async {}

  @override
  Future<void> redefinirSenha(String email) async {}

  @override
  Future<void> sair() async {}

  @override
  Future<String?> token() async => 'token-teste';

  @override
  Future<String?> tokenAppCheck() async => 'app-check-teste';
}

Api _api(Autenticador autenticador) => Api(
  paginaPadrao: 20,
  cliente: ClienteApi(
    baseUrl: 'http://localhost:3000',
    provedorToken: autenticador.token,
    provedorAppCheck: autenticador.tokenAppCheck,
    cliente: http_testing.MockClient(
      (requisicao) async => http.Response(
        requisicao.url.path == '/api/resumo'
            ? _resumoVazio
            : '{"api":"v1","saudavel":true}',
        200,
      ),
    ),
  ),
);

Widget _aplicativo({
  required InicializadorAcesso inicializar,
  FabricaApiAutenticada fabricarApi = _api,
  Duration tempoMinimo = Duration.zero,
  Duration tempoParaAviso = const Duration(seconds: 4),
  bool reduzirMovimento = false,
}) {
  return MaterialApp(
    theme: TemaRadar.claro(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduzirMovimento),
      child: PaginaAbertura(
        inicializar: inicializar,
        fabricarApi: fabricarApi,
        tempoMinimo: tempoMinimo,
        tempoParaAviso: tempoParaAviso,
      ),
    ),
  );
}

void main() {
  testWidgets('raiz de produção abre o bootstrap antes do gate', (at) async {
    final resposta = Completer<InicializacaoFirebase>();
    await at.pumpWidget(
      RadarApp.inicializando(
        inicializar: () => resposta.future,
        fabricarApi: _api,
      ),
    );

    expect(find.text('Preparando seu radar…'), findsOneWidget);

    resposta.complete(const InicializacaoFirebase.pendente('falha controlada'));
    await at.pump(const Duration(milliseconds: 1500));
  });

  testWidgets('mostra a marca enquanto a inicialização está pendente', (
    at,
  ) async {
    final resposta = Completer<InicializacaoFirebase>();
    await at.pumpWidget(
      _aplicativo(inicializar: () => resposta.future, reduzirMovimento: true),
    );

    expect(find.text('Radar'), findsOneWidget);
    expect(find.text('Preparando seu radar…'), findsOneWidget);
    expect(
      find.text('Pontos, cashback e preços reunidos em um só radar.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    resposta.complete(const InicializacaoFirebase.pendente('falha controlada'));
    await at.pump();
  });

  testWidgets('ciclo mínimo torna a animação perceptível antes de seguir', (
    at,
  ) async {
    final autenticador = _AutenticadorFalso();
    await at.pumpWidget(
      _aplicativo(
        inicializar: () async => InicializacaoFirebase.pronta(autenticador),
        tempoMinimo: const Duration(milliseconds: 1500),
        reduzirMovimento: true,
      ),
    );
    await at.pump();

    expect(find.text('Preparando seu radar…'), findsOneWidget);
    await at.pump(const Duration(milliseconds: 1499));
    expect(find.text('Preparando seu radar…'), findsOneWidget);
    await at.pump(const Duration(milliseconds: 1));

    expect(find.text('Que bom ter você aqui'), findsOneWidget);
    expect(find.text('Preparando seu radar…'), findsNothing);
  });

  testWidgets('validação lenta não recebe espera adicional', (at) async {
    final autenticador = _AutenticadorFalso();
    final resposta = Completer<InicializacaoFirebase>();
    await at.pumpWidget(
      _aplicativo(
        inicializar: () => resposta.future,
        tempoMinimo: const Duration(milliseconds: 1500),
        reduzirMovimento: true,
      ),
    );

    await at.pump(const Duration(seconds: 2));
    resposta.complete(InicializacaoFirebase.pronta(autenticador));
    await at.pump();
    await at.pump();

    expect(find.text('Que bom ter você aqui'), findsOneWidget);
  });

  testWidgets('mantém a abertura animada durante a validação do convite', (
    at,
  ) async {
    final autenticador = _AutenticadorFalso(
      const ContaAutenticada(id: 'uid-1', email: 'piloto@example.com'),
    );
    final perfil = Completer<http.Response>();
    final api = Api(
      paginaPadrao: 20,
      cliente: ClienteApi(
        baseUrl: 'http://localhost:3000',
        provedorToken: autenticador.token,
        provedorAppCheck: autenticador.tokenAppCheck,
        cliente: http_testing.MockClient((requisicao) {
          if (requisicao.url.path == '/api/perfil') return perfil.future;
          if (requisicao.url.path == '/api/resumo') {
            return Future.value(http.Response(_resumoVazio, 200));
          }
          return Future.value(
            http.Response('{"api":"v1","saudavel":true}', 200),
          );
        }),
      ),
    );

    await at.pumpWidget(
      _aplicativo(
        inicializar: () async => InicializacaoFirebase.pronta(autenticador),
        fabricarApi: (_) => api,
      ),
    );
    await at.pump();
    await at.pump();

    expect(find.text('Radar'), findsOneWidget);
    expect(find.text('Validando seu acesso ao piloto…'), findsOneWidget);

    perfil.complete(
      http.Response(
        '{"id":"42","email":"piloto@example.com","papel":"usuario"}',
        200,
      ),
    );
    await at.pump();
  });

  testWidgets('demora recebe explicação honesta sem esconder a marca', (
    at,
  ) async {
    final resposta = Completer<InicializacaoFirebase>();
    await at.pumpWidget(
      _aplicativo(
        inicializar: () => resposta.future,
        tempoParaAviso: const Duration(seconds: 2),
        reduzirMovimento: true,
      ),
    );

    await at.pump(const Duration(seconds: 2));

    expect(
      find.text('A validação segura está levando um pouco mais de tempo…'),
      findsOneWidget,
    );
    expect(find.text('Radar'), findsOneWidget);

    resposta.complete(const InicializacaoFirebase.pendente('falha controlada'));
    await at.pump();
  });

  testWidgets('falha oferece retry e segue após uma tentativa válida', (
    at,
  ) async {
    final autenticador = _AutenticadorFalso();
    final primeira = Completer<InicializacaoFirebase>();
    final segunda = Completer<InicializacaoFirebase>();
    var chamadas = 0;

    await at.pumpWidget(
      _aplicativo(
        inicializar: () {
          chamadas++;
          return chamadas == 1 ? primeira.future : segunda.future;
        },
        reduzirMovimento: true,
      ),
    );

    primeira.complete(
      const InicializacaoFirebase.pendente('Falha segura de teste.'),
    );
    await at.pump();
    expect(find.text('Falha segura de teste.'), findsOneWidget);

    await at.tap(find.byKey(const Key('abertura-tentar-novamente')));
    await at.pump();
    expect(chamadas, 2);
    expect(find.text('Preparando seu radar…'), findsOneWidget);

    segunda.complete(InicializacaoFirebase.pronta(autenticador));
    await at.pump();
    await at.pump();
    expect(find.text('Que bom ter você aqui'), findsOneWidget);
  });

  testWidgets('exceção não expõe detalhes técnicos na abertura', (at) async {
    await at.pumpWidget(
      _aplicativo(
        inicializar: () => throw StateError('segredo-interno'),
        reduzirMovimento: true,
      ),
    );
    await at.pump();

    expect(
      find.text('Não foi possível preparar seu acesso agora.'),
      findsOneWidget,
    );
    expect(find.textContaining('segredo-interno'), findsNothing);
    expect(find.byKey(const Key('abertura-tentar-novamente')), findsOneWidget);
  });

  testWidgets('falha ao montar a API também termina em estado recuperável', (
    at,
  ) async {
    final autenticador = _AutenticadorFalso();
    await at.pumpWidget(
      _aplicativo(
        inicializar: () async => InicializacaoFirebase.pronta(autenticador),
        fabricarApi: (_) => throw StateError('configuração inválida'),
        reduzirMovimento: true,
      ),
    );
    await at.pump();
    await at.pump();

    expect(
      find.text('Não foi possível preparar seu acesso agora.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('abertura-tentar-novamente')), findsOneWidget);
  });

  testWidgets('movimento reduzido desativa o ticker da marca', (at) async {
    final resposta = Completer<InicializacaoFirebase>();
    await at.pumpWidget(
      _aplicativo(inicializar: () => resposta.future, reduzirMovimento: true),
    );

    final ticker = at.widget<TickerMode>(
      find.byKey(const Key('abertura-ticker')),
    );
    expect(ticker.enabled, isFalse);

    resposta.complete(const InicializacaoFirebase.pendente('falha controlada'));
    await at.pump();
  });

  testWidgets('feixe continua varrendo depois de completar um ciclo', (
    at,
  ) async {
    final resposta = Completer<InicializacaoFirebase>();
    await at.pumpWidget(_aplicativo(inicializar: () => resposta.future));

    await at.pump(const Duration(milliseconds: 1825));
    final logo = at.widget<LogoRadar>(find.byType(LogoRadar));
    expect(logo.progresso, closeTo(425 / 1400, 0.02));

    resposta.complete(const InicializacaoFirebase.pendente('falha controlada'));
    await at.pump();
  });
}
