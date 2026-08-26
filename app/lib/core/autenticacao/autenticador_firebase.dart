import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;

import 'autenticador.dart';

class AutenticadorFirebase implements Autenticador {
  AutenticadorFirebase({
    firebase.FirebaseAuth? firebaseAuth,
    FirebaseAppCheck? appCheck,
    required this.appCheckAtivo,
  }) : _auth = firebaseAuth ?? firebase.FirebaseAuth.instance,
       _appCheck = appCheck ?? FirebaseAppCheck.instance;

  final firebase.FirebaseAuth _auth;
  final FirebaseAppCheck _appCheck;
  final bool appCheckAtivo;

  ContaAutenticada? _converter(firebase.User? usuario) {
    final email = usuario?.email;
    if (usuario == null || email == null) return null;
    return ContaAutenticada(id: usuario.uid, email: email);
  }

  @override
  Stream<ContaAutenticada?> get mudancas =>
      _auth.authStateChanges().map(_converter);

  @override
  ContaAutenticada? get contaAtual => _converter(_auth.currentUser);

  @override
  Future<void> entrar({required String email, required String senha}) async {
    try {
      final credencial = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );
      final usuario = credencial.user;
      if (usuario != null && !usuario.emailVerified) {
        try {
          await usuario.sendEmailVerification();
        } finally {
          await _auth.signOut();
        }
        throw const FalhaDeAutenticacao(
          'Enviamos um link para confirmar seu e-mail. Depois, entre novamente.',
        );
      }
    } on firebase.FirebaseAuthException catch (erro) {
      throw FalhaDeAutenticacao(_mensagem(erro.code));
    }
  }

  @override
  Future<void> redefinirSenha(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on firebase.FirebaseAuthException catch (erro) {
      throw FalhaDeAutenticacao(_mensagem(erro.code));
    }
  }

  @override
  Future<void> sair() => _auth.signOut();

  @override
  Future<String?> token() async => _auth.currentUser?.getIdToken();

  @override
  Future<String?> tokenAppCheck() =>
      appCheckAtivo ? _appCheck.getToken() : Future<String?>.value();

  String _mensagem(String codigo) {
    return switch (codigo) {
      'invalid-email' => 'Digite um e-mail válido.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde um pouco e tente novamente.',
      'network-request-failed' =>
        'Sem conexão. Confira a internet e tente novamente.',
      'user-disabled' => 'Este acesso está desativado.',
      _ => 'E-mail ou senha inválidos.',
    };
  }
}
