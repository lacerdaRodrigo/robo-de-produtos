import 'package:flutter/material.dart';

import '../../core/autenticacao/autenticador.dart';
import '../componentes/fundacao_visual.dart';
import '../tema/tokens.dart';

class PaginaRecuperarAcesso extends StatefulWidget {
  const PaginaRecuperarAcesso({
    super.key,
    required this.autenticador,
    this.emailInicial = '',
  });

  final Autenticador autenticador;
  final String emailInicial;

  @override
  State<PaginaRecuperarAcesso> createState() => _EstadoPaginaRecuperarAcesso();
}

class _EstadoPaginaRecuperarAcesso extends State<PaginaRecuperarAcesso> {
  static const _mensagemNeutra =
      'Se o e-mail estiver cadastrado, você receberá as instruções.';

  late final TextEditingController _email = TextEditingController(
    text: widget.emailInicial,
  );
  final _formulario = GlobalKey<FormState>();
  bool _ocupado = false;
  String? _erro;
  String? _aviso;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_ocupado || !(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _erro = null;
      _aviso = null;
    });
    try {
      await widget.autenticador.redefinirSenha(_email.text.trim());
      if (mounted) setState(() => _aviso = _mensagemNeutra);
    } on FalhaDeAutenticacao {
      // Nunca revelar se o endereço existe, mesmo quando o provedor falha.
      if (mounted) setState(() => _aviso = _mensagemNeutra);
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
    final tokens = context.tokens;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar acesso'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.four,
            tokens.spacing.five,
            tokens.spacing.four,
            tokens.spacing.eight,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formulario,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CabecalhoSecaoRadar(
                    sobrelinha: 'Acesso seguro',
                    titulo: 'Receba um novo caminho para entrar.',
                    descricao:
                        'Informe o e-mail da conta. A resposta é sempre neutra para proteger sua privacidade.',
                  ),
                  SizedBox(height: tokens.spacing.six),
                  TextFormField(
                    key: const Key('recuperar-email'),
                    controller: _email,
                    enabled: !_ocupado,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _enviar(),
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'voce@exemplo.com',
                    ),
                    validator: (valor) {
                      final texto = valor?.trim() ?? '';
                      return texto.contains('@')
                          ? null
                          : 'Digite um e-mail válido.';
                    },
                  ),
                  if (_erro != null) ...[
                    SizedBox(height: tokens.spacing.four),
                    _MensagemRecuperacao(
                      chave: const Key('recuperar-erro'),
                      texto: _erro!,
                      erro: true,
                    ),
                  ],
                  if (_aviso != null) ...[
                    SizedBox(height: tokens.spacing.four),
                    _MensagemRecuperacao(
                      chave: const Key('recuperar-aviso'),
                      texto: _aviso!,
                    ),
                  ],
                  SizedBox(height: tokens.spacing.five),
                  FilledButton.icon(
                    key: const Key('recuperar-enviar'),
                    onPressed: _ocupado ? null : _enviar,
                    icon: _ocupado
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mark_email_read_outlined),
                    label: Text(_ocupado ? 'Enviando…' : 'Enviar instruções'),
                  ),
                  SizedBox(height: tokens.spacing.four),
                  Text(
                    'Se você não reconhecer este pedido, ignore a mensagem recebida e volte ao aplicativo.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CoresRadar.de(context).textoSuave,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MensagemRecuperacao extends StatelessWidget {
  const _MensagemRecuperacao({
    required this.chave,
    required this.texto,
    this.erro = false,
  });

  final Key chave;
  final String texto;
  final bool erro;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final cor = erro ? cores.perigo : cores.ganho;
    return Semantics(
      key: chave,
      liveRegion: true,
      label: texto,
      child: CartaoRadar(
        corDestaque: cor,
        child: Text(
          texto,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
        ),
      ),
    );
  }
}
