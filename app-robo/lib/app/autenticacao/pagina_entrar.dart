import 'package:flutter/material.dart';

import '../../core/autenticacao/autenticador.dart';
import '../tema/tokens.dart';

class PaginaEntrar extends StatefulWidget {
  const PaginaEntrar({super.key, required this.autenticador});

  final Autenticador autenticador;

  @override
  State<PaginaEntrar> createState() => _EstadoPaginaEntrar();
}

class _EstadoPaginaEntrar extends State<PaginaEntrar> {
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocupado = false;
  bool _ocultarSenha = true;
  String? _erro;
  String? _aviso;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _erro = null;
      _aviso = null;
    });
    try {
      await widget.autenticador.entrar(email: _email.text, senha: _senha.text);
    } on FalhaDeAutenticacao catch (erro) {
      if (mounted) setState(() => _erro = erro.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível entrar. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _redefinirSenha() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _erro = 'Digite seu e-mail antes de recuperar a senha.';
        _aviso = null;
      });
      return;
    }
    setState(() {
      _ocupado = true;
      _erro = null;
      _aviso = null;
    });
    try {
      await widget.autenticador.redefinirSenha(email);
      if (mounted) {
        setState(() {
          _aviso =
              'Se o e-mail estiver cadastrado, você receberá as instruções.';
        });
      }
    } on FalhaDeAutenticacao catch (erro) {
      if (mounted) setState(() => _erro = erro.mensagem);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível pedir uma nova senha.');
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formulario,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.radar, size: 44, color: Tokens.marca),
                        const SizedBox(height: 16),
                        Text(
                          'Radar de Benefícios',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Entre com o acesso recebido para o piloto.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _email,
                          enabled: !_ocupado,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.mail_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (valor) {
                            final texto = valor?.trim() ?? '';
                            return texto.contains('@')
                                ? null
                                : 'Digite um e-mail válido.';
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _senha,
                          enabled: !_ocupado,
                          obscureText: _ocultarSenha,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _entrar(),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _ocultarSenha
                                  ? 'Mostrar senha'
                                  : 'Ocultar senha',
                              onPressed: _ocupado
                                  ? null
                                  : () => setState(
                                      () => _ocultarSenha = !_ocultarSenha,
                                    ),
                              icon: Icon(
                                _ocultarSenha
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (valor) => (valor?.isEmpty ?? true)
                              ? 'Digite sua senha.'
                              : null,
                        ),
                        if (_erro != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _erro!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        if (_aviso != null) ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(_aviso!, textAlign: TextAlign.center),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _ocupado ? null : _entrar,
                          child: _ocupado
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Entrar'),
                        ),
                        TextButton(
                          onPressed: _ocupado ? null : _redefinirSenha,
                          child: const Text('Esqueci minha senha'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
