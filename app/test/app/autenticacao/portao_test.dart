import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;

import 'package:app_robo/app/app.dart';
import 'package:app_robo/app/autenticacao/portao.dart';
import 'package:app_robo/core/api/api.dart';
import 'package:app_robo/core/api/cliente.dart';
import 'package:app_robo/core/autenticacao/autenticador.dart';

const _resumoVazio =
    '{"gerado_em":"2026-08-23T12:00:00Z","estado_geral":"sem_dados",'
    '"livelo":{"estado":"sem_dados"},'
    '"cashback_inter":{"estado":"sem_dados"},'
    '"produtos":{"estado":"sem_dados"}}';

class AutenticadorFalso implements Autenticador {
  AutenticadorFalso([this.contaAtual]);

  final controlador = StreamController<ContaAutenticada?>.broadcast();
  @override
  ContaAutenticada? contaAtual;
  String? emailRecebido;
  String? senhaRecebida;
  String? recuperacaoRecebida;
  bool saiu = false;

  @override
  Stream<ContaAutenticada?> get mudancas => controlador.stream;

  @override
  Future<void> entrar({required String email, required String senha}) async {
    emailRecebido = email;
    senhaRecebida = senha;
  }

  @override
  Future<void> redefinirSenha(String email) async {
    recuperacaoRecebida = email;
  }

  @override
  Future<void> sair() async {
    saiu = true;
    contaAtual = null;
    controlador.add(null);
  }

  @override
  Future<String?> token() async => contaAtual == null ? null : 'token-teste';

  @override
  Future<String?> tokenAppCheck() async => 'app-check-teste';

  Future<void> fechar() => controlador.close();
}

Api apiCom(http_testing.MockClient cliente, Autenticador autenticador) {
  return Api(
    paginaPadrao: 20,
    cliente: ClienteApi(
      baseUrl: 'http://localhost:3000',
      cliente: cliente,
      provedorToken: autenticador.token,
      provedorAppCheck: autenticador.tokenAppCheck,
    ),
  );
}

void main() {
  testWidgets('sem sessão mostra login e envia e-mail e senha', (at) async {
    final autenticador = AutenticadorFalso();
    addTearDown(autenticador.fechar);
    final api = apiCom(
      http_testing.MockClient((_) async => http.Response('{}', 200)),
      autenticador,
    );

    await at.pumpWidget(
      RadarApp.comAutenticacao(api: api, autenticador: autenticador),
    );

    expect(find.byKey(const Key('login-marca-compacta')), findsOneWidget);
    await at.enterText(
      find.byKey(const Key('login-email')),
      'piloto@example.com',
    );
    await at.enterText(find.byKey(const Key('login-senha')), 'senha-segura');
    final entrar = find.byKey(const Key('login-entrar'));
    await at.ensureVisible(entrar);
    await at.tap(entrar);
    await at.pump();

    expect(autenticador.emailRecebido, 'piloto@example.com');
    expect(autenticador.senhaRecebida, 'senha-segura');
  });

  testWidgets('recuperação não informa se o e-mail existe', (at) async {
    final autenticador = AutenticadorFalso();
    addTearDown(autenticador.fechar);
    final api = apiCom(
      http_testing.MockClient((_) async => http.Response('{}', 200)),
      autenticador,
    );
    await at.pumpWidget(
      RadarApp.comAutenticacao(api: api, autenticador: autenticador),
    );

    await at.enterText(find.byType(EditableText).first, 'piloto@example.com');
    final recuperar = find.text('Recuperar acesso');
    await at.ensureVisible(recuperar);
    await at.pumpAndSettle();
    await at.tap(recuperar);
    await at.pumpAndSettle();
    await at.tap(find.byKey(const Key('recuperar-enviar')));
    await at.pump();

    expect(autenticador.recuperacaoRecebida, 'piloto@example.com');
    expect(
      find.textContaining('Se o e-mail estiver cadastrado'),
      findsOneWidget,
    );
  });

  testWidgets('sessão convidada atravessa o gate e abre o app', (at) async {
    final autenticador = AutenticadorFalso(
      const ContaAutenticada(id: 'uid-1', email: 'piloto@example.com'),
    );
    addTearDown(autenticador.fechar);
    final api = apiCom(
      http_testing.MockClient((requisicao) async {
        if (requisicao.url.path == '/api/perfil') {
          expect(requisicao.headers['authorization'], 'Bearer token-teste');
          return http.Response(
            '{"id":"42","email":"piloto@example.com","papel":"usuario"}',
            200,
          );
        }
        if (requisicao.url.path == '/api/resumo') {
          return http.Response(_resumoVazio, 200);
        }
        return http.Response('{"api":"v1","saudavel":true}', 200);
      }),
      autenticador,
    );

    await at.pumpWidget(
      RadarApp.comAutenticacao(api: api, autenticador: autenticador),
    );
    await at.pumpAndSettle();

    expect(find.byKey(const Key('resumo-inicio')), findsOneWidget);
    expect(find.byKey(const Key('abrir-alertas-cabecalho')), findsOneWidget);
    expect(find.byKey(const Key('barra-inicio')), findsOneWidget);
  });

  testWidgets('sessão sem convite mostra acesso negado e permite sair', (
    at,
  ) async {
    final autenticador = AutenticadorFalso(
      const ContaAutenticada(id: 'uid-2', email: 'fora@example.com'),
    );
    addTearDown(autenticador.fechar);
    final api = apiCom(
      http_testing.MockClient(
        (_) async => http.Response(
          '{"erro":{"codigo":"acesso-negado","mensagem":"usuario nao autorizado"}}',
          403,
        ),
      ),
      autenticador,
    );

    await at.pumpWidget(
      RadarApp.comAutenticacao(api: api, autenticador: autenticador),
    );
    await at.pumpAndSettle();

    expect(
      find.text('Este usuário não está autorizado para o piloto.'),
      findsOneWidget,
    );
    await at.tap(find.text('Sair'));
    await at.pump();
    expect(autenticador.saiu, isTrue);
  });

  testWidgets('validação offline termina em falha recuperável após timeout', (
    at,
  ) async {
    final autenticador = AutenticadorFalso(
      const ContaAutenticada(id: 'uid-offline', email: 'piloto@example.com'),
    );
    addTearDown(autenticador.fechar);
    final resposta = Completer<http.Response>();
    final api = apiCom(
      http_testing.MockClient((requisicao) {
        if (requisicao.url.path == '/api/perfil') return resposta.future;
        return Future.value(http.Response(_resumoVazio, 200));
      }),
      autenticador,
    );

    await at.pumpWidget(
      MaterialApp(
        home: PortaoAutenticacao(
          autenticador: autenticador,
          api: api,
          tempoMaximoValidacao: const Duration(seconds: 1),
        ),
      ),
    );
    await at.pump(const Duration(seconds: 1));

    expect(
      find.text('Não foi possível validar seu acesso agora.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);

    resposta.complete(http.Response('{}', 503));
  });
}
