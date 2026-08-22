import 'dart:math';

/// Gera uma chave opaca para uma única intenção administrativa.
///
/// A chave não contém usuário, domínio ou segredo; ela apenas permite que o
/// servidor reconheça a repetição do mesmo toque após uma falha de rede.
String novaChaveDeIdempotencia() {
  final aleatorio = Random.secure();
  final bytes = List<int>.generate(24, (_) => aleatorio.nextInt(256));
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
