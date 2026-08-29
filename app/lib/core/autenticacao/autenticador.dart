class ContaAutenticada {
  const ContaAutenticada({required this.id, required this.email});

  final String id;
  final String email;
}

class FalhaDeAutenticacao implements Exception {
  const FalhaDeAutenticacao(this.mensagem);

  final String mensagem;

  @override
  String toString() => 'FalhaDeAutenticacao';
}

/// Porta pequena para a UI não depender diretamente do SDK do Firebase.
abstract interface class Autenticador {
  Stream<ContaAutenticada?> get mudancas;

  ContaAutenticada? get contaAtual;

  Future<void> entrar({required String email, required String senha});

  Future<void> redefinirSenha(String email);

  Future<void> sair();

  Future<String?> token();

  Future<String?> tokenAppCheck();
}
