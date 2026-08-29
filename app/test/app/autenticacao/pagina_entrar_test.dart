import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_robo/app/autenticacao/pagina_entrar.dart';
import 'package:app_robo/app/tema/tema.dart';
import 'package:app_robo/core/autenticacao/autenticador.dart';

class _AutenticadorFalso implements Autenticador {
  final controlador = StreamController<ContaAutenticada?>.broadcast();
  Completer<void>? entradaPendente;
  Object? falhaEntrada;
  Object? falhaRecuperacao;
  String? emailRecebido;
  String? senhaRecebida;
  String? recuperacaoRecebida;

  @override
  ContaAutenticada? get contaAtual => null;

  @override
  Stream<ContaAutenticada?> get mudancas => controlador.stream;

  @override
  Future<void> entrar({required String email, required String senha}) async {
    emailRecebido = email;
    senhaRecebida = senha;
    if (falhaEntrada case final falha?) throw falha;
    final pendente = entradaPendente;
    if (pendente != null) await pendente.future;
  }

  @override
  Future<void> redefinirSenha(String email) async {
    recuperacaoRecebida = email;
    if (falhaRecuperacao case final falha?) throw falha;
  }

  @override
  Future<void> sair() async {}

  @override
  Future<String?> token() async => null;

  @override
  Future<String?> tokenAppCheck() async => null;

  Future<void> fechar() => controlador.close();
}

Future<void> _abrir(
  WidgetTester at,
  _AutenticadorFalso autenticador, {
  Size tamanho = const Size(390, 844),
  double escalaTexto = 1,
}) async {
  await at.binding.setSurfaceSize(tamanho);
  addTearDown(() => at.binding.setSurfaceSize(null));
  addTearDown(autenticador.fechar);
  await at.pumpWidget(
    MaterialApp(
      theme: TemaRadar.legadoClaro(),
      home: PaginaEntrar(autenticador: autenticador),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
    ),
  );
  await at.pump();
}

void main() {
  testWidgets('celular prioriza formulário e mantém a marca compacta', (
    at,
  ) async {
    await _abrir(at, _AutenticadorFalso());

    expect(find.byKey(const Key('login-marca-compacta')), findsOneWidget);
    expect(find.byKey(const Key('login-painel-marca')), findsNothing);
    expect(find.text('Que bom ter você aqui'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Web amplo divide apresentação e formulário', (at) async {
    await _abrir(at, _AutenticadorFalso(), tamanho: const Size(1440, 900));

    expect(find.byKey(const Key('login-painel-marca')), findsOneWidget);
    expect(find.byKey(const Key('login-marca-compacta')), findsNothing);
    expect(
      find.text('Seu próximo benefício não passa despercebido.'),
      findsOneWidget,
    );
    expect(find.text('Histórico de preços'), findsOneWidget);
    expect(find.text('Que bom ter você aqui'), findsOneWidget);
  });

  testWidgets('celular estreito aceita texto ampliado sem perder ações', (
    at,
  ) async {
    await _abrir(
      at,
      _AutenticadorFalso(),
      tamanho: const Size(320, 640),
      escalaTexto: 1.5,
    );

    expect(at.takeException(), isNull);
    expect(find.byKey(const Key('login-email')), findsOneWidget);
    expect(find.byKey(const Key('login-senha')), findsOneWidget);
    expect(find.byKey(const Key('login-entrar')), findsOneWidget);
    expect(find.text('Esqueci minha senha'), findsOneWidget);
  });

  testWidgets('envia credenciais, remove espaços do e-mail e mantém a senha', (
    at,
  ) async {
    final autenticador = _AutenticadorFalso();
    await _abrir(at, autenticador);

    await at.enterText(
      find.byKey(const Key('login-email')),
      '  piloto@example.com  ',
    );
    await at.enterText(find.byKey(const Key('login-senha')), ' senha-segura ');
    await at.tap(find.byKey(const Key('login-entrar')));
    await at.pump();

    expect(autenticador.emailRecebido, 'piloto@example.com');
    expect(autenticador.senhaRecebida, ' senha-segura ');
  });

  testWidgets('mostrar senha alterna rótulo e mantém o conteúdo', (at) async {
    await _abrir(at, _AutenticadorFalso());
    await at.enterText(find.byKey(const Key('login-senha')), 'segredo');

    expect(find.byTooltip('Mostrar senha'), findsOneWidget);
    expect(
      at.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isTrue,
    );

    await at.tap(find.byTooltip('Mostrar senha'));
    await at.pump();

    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    expect(
      at.widget<EditableText>(find.byType(EditableText).last).obscureText,
      isFalse,
    );
    expect(
      at.widget<EditableText>(find.byType(EditableText).last).controller.text,
      'segredo',
    );
  });

  testWidgets('entrada pendente preserva campos e bloqueia novo envio', (
    at,
  ) async {
    final autenticador = _AutenticadorFalso()
      ..entradaPendente = Completer<void>();
    await _abrir(at, autenticador);

    await at.enterText(
      find.byKey(const Key('login-email')),
      'piloto@example.com',
    );
    await at.enterText(find.byKey(const Key('login-senha')), 'senha-segura');
    await at.tap(find.byKey(const Key('login-entrar')));
    await at.pump();

    expect(find.text('Entrando…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      at.widget<EditableText>(find.byType(EditableText).first).controller.text,
      'piloto@example.com',
    );
    expect(
      at.widget<EditableText>(find.byType(EditableText).last).controller.text,
      'senha-segura',
    );

    autenticador.entradaPendente!.complete();
    await at.pump();
  });

  testWidgets('erro de entrada é acessível e não apaga os campos', (at) async {
    final autenticador = _AutenticadorFalso()
      ..falhaEntrada = const FalhaDeAutenticacao('E-mail ou senha inválidos.');
    await _abrir(at, autenticador);

    await at.enterText(
      find.byKey(const Key('login-email')),
      'piloto@example.com',
    );
    await at.enterText(find.byKey(const Key('login-senha')), 'senha-incorreta');
    await at.tap(find.byKey(const Key('login-entrar')));
    await at.pump();

    expect(find.byKey(const Key('login-erro')), findsOneWidget);
    expect(find.text('E-mail ou senha inválidos.'), findsOneWidget);
    expect(
      at.widget<EditableText>(find.byType(EditableText).first).controller.text,
      'piloto@example.com',
    );
    expect(
      at.widget<EditableText>(find.byType(EditableText).last).controller.text,
      'senha-incorreta',
    );
  });

  testWidgets(
    'recuperação mantém resposta neutra até quando o provedor falha',
    (at) async {
      final autenticador = _AutenticadorFalso()
        ..falhaRecuperacao = const FalhaDeAutenticacao(
          'E-mail ou senha inválidos.',
        );
      await _abrir(at, autenticador);

      await at.enterText(
        find.byKey(const Key('login-email')),
        'piloto@example.com',
      );
      await at.tap(find.text('Esqueci minha senha'));
      await at.pump();

      expect(autenticador.recuperacaoRecebida, 'piloto@example.com');
      expect(find.byKey(const Key('login-aviso')), findsOneWidget);
      expect(
        find.text(
          'Se o e-mail estiver cadastrado, você receberá as instruções.',
        ),
        findsOneWidget,
      );
      expect(find.text('E-mail ou senha inválidos.'), findsNothing);
    },
  );

  testWidgets('login compacto confere com o golden aprovado', (at) async {
    await _abrir(at, _AutenticadorFalso());

    await expectLater(
      find.byType(PaginaEntrar),
      matchesGoldenFile('../../goldens/login_compacto.png'),
    );
  });

  testWidgets('login amplo confere com o golden aprovado', (at) async {
    await _abrir(at, _AutenticadorFalso(), tamanho: const Size(1440, 900));

    await expectLater(
      find.byType(PaginaEntrar),
      matchesGoldenFile('../../goldens/login_amplo.png'),
    );
  });
}
