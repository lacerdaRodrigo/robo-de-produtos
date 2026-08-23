import 'package:flutter/material.dart';

import '../../core/autenticacao/autenticador.dart';
import '../identidade/logo_radar.dart';
import '../tema/tokens.dart';

class PaginaEntrar extends StatefulWidget {
  const PaginaEntrar({super.key, required this.autenticador});

  final Autenticador autenticador;

  @override
  State<PaginaEntrar> createState() => _EstadoPaginaEntrar();
}

class _EstadoPaginaEntrar extends State<PaginaEntrar> {
  static const _larguraLayoutAmplo = 920.0;
  static const _mensagemRecuperacao =
      'Se o e-mail estiver cadastrado, você receberá as instruções.';

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
    if (_ocupado || !(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _ocupado = true;
      _erro = null;
      _aviso = null;
    });
    try {
      await widget.autenticador.entrar(
        email: _email.text.trim(),
        senha: _senha.text,
      );
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
    if (_ocupado) return;
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
      if (mounted) setState(() => _aviso = _mensagemRecuperacao);
    } on FalhaDeAutenticacao {
      // A recuperação nunca confirma se uma conta existe. Até mensagens do
      // provedor são substituídas pela mesma resposta neutra.
      if (mounted) setState(() => _aviso = _mensagemRecuperacao);
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
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, limites) {
          final amplo = limites.maxWidth >= _larguraLayoutAmplo;
          final formulario = _AreaFormulario(
            compacto: !amplo,
            formulario: _formulario,
            email: _email,
            senha: _senha,
            ocupado: _ocupado,
            ocultarSenha: _ocultarSenha,
            erro: _erro,
            aviso: _aviso,
            aoAlternarSenha: () =>
                setState(() => _ocultarSenha = !_ocultarSenha),
            aoEntrar: _entrar,
            aoRecuperar: _redefinirSenha,
          );

          if (!amplo) return formulario;
          return Row(
            children: [
              const Expanded(flex: 108, child: _PainelDaMarca()),
              Expanded(flex: 92, child: formulario),
            ],
          );
        },
      ),
    );
  }
}

class _PainelDaMarca extends StatelessWidget {
  const _PainelDaMarca();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('login-painel-marca'),
      container: true,
      label: 'Apresentação do Radar de Benefícios',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF123D62), Tokens.marcaProfunda],
            stops: [0, 0.58],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              top: -210,
              right: -210,
              child: _AneisDecorativos(),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, limites) {
                  final horizontal = (limites.maxWidth * 0.1)
                      .clamp(32.0, 88.0)
                      .toDouble();
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      40,
                      horizontal,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _AssinaturaMarca(),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              child: _ChamadaDaMarca(
                                larguraDisponivel: limites.maxWidth,
                              ),
                            ),
                          ),
                        ),
                        const Text(
                          'Projeto independente, sem afiliação com Livelo ou Banco Inter.',
                          style: TextStyle(
                            color: Color(0xFF93AABD),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AneisDecorativos extends StatelessWidget {
  const _AneisDecorativos();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 620,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final tamanho in const [620.0, 480.0, 340.0])
              Container(
                width: tamanho,
                height: tamanho,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(
                      0xFF25B8D8,
                    ).withValues(alpha: tamanho == 620 ? 0.18 : 0.1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssinaturaMarca extends StatelessWidget {
  const _AssinaturaMarca({this.compacta = false});

  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final cor = compacta ? Tokens.marca : Colors.white;
    return Row(
      key: compacta ? const Key('login-marca-compacta') : null,
      mainAxisSize: compacta ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: compacta
                ? const [
                    BoxShadow(
                      color: Color(0x16081A2D),
                      blurRadius: 18,
                      offset: Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: const LogoRadar(tamanho: 42),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            'Radar de Benefícios',
            style: TextStyle(
              color: cor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChamadaDaMarca extends StatelessWidget {
  const _ChamadaDaMarca({required this.larguraDisponivel});

  final double larguraDisponivel;

  @override
  Widget build(BuildContext context) {
    final tamanhoTitulo = (larguraDisponivel * 0.09)
        .clamp(42.0, 68.0)
        .toDouble();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 620),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'SEU RADAR DE OPORTUNIDADES',
              style: TextStyle(
                color: Color(0xFFD9F8FF),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Seu próximo benefício não passa despercebido.',
            style: TextStyle(
              color: Colors.white,
              fontSize: tamanhoTitulo,
              height: 0.98,
              letterSpacing: -2.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Text(
              'Pontos, cashback e preços reunidos em um só radar.',
              style: TextStyle(
                color: Color(0xFFC6D7E7),
                fontSize: 19,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              _BeneficioMarca('Livelo'),
              _BeneficioMarca('Shopping Inter'),
              _BeneficioMarca('Histórico de preços'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BeneficioMarca extends StatelessWidget {
  const _BeneficioMarca(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFF25B8D8),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(color: Color(0xFFEAF6FF), fontSize: 14),
        ),
      ],
    );
  }
}

class _AreaFormulario extends StatelessWidget {
  const _AreaFormulario({
    required this.compacto,
    required this.formulario,
    required this.email,
    required this.senha,
    required this.ocupado,
    required this.ocultarSenha,
    required this.erro,
    required this.aviso,
    required this.aoAlternarSenha,
    required this.aoEntrar,
    required this.aoRecuperar,
  });

  final bool compacto;
  final GlobalKey<FormState> formulario;
  final TextEditingController email;
  final TextEditingController senha;
  final bool ocupado;
  final bool ocultarSenha;
  final String? erro;
  final String? aviso;
  final VoidCallback aoAlternarSenha;
  final VoidCallback aoEntrar;
  final VoidCallback aoRecuperar;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, limites) {
            final horizontal = compacto ? 20.0 : 48.0;
            final vertical = compacto ? 36.0 : 48.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontal,
                vertical,
                horizontal,
                32 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (limites.maxHeight - vertical - 32)
                      .clamp(0.0, double.infinity)
                      .toDouble(),
                ),
                child: Align(
                  alignment: compacto ? Alignment.topCenter : Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: AutofillGroup(
                      child: Form(
                        key: formulario,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (compacto) ...[
                              const _AssinaturaMarca(compacta: true),
                              const SizedBox(height: 32),
                            ],
                            Text(
                              'Que bom ter você aqui',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Tokens.marca,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Entre com seu acesso para ver as oportunidades acompanhadas.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF5D7285),
                                    height: 1.45,
                                  ),
                            ),
                            const SizedBox(height: 28),
                            _CampoRotulado(
                              chave: const Key('login-email'),
                              rotulo: 'E-mail',
                              dica: 'voce@exemplo.com',
                              controlador: email,
                              habilitado: !ocupado,
                              teclado: TextInputType.emailAddress,
                              acaoTeclado: TextInputAction.next,
                              autofill: const [AutofillHints.username],
                              validador: (valor) {
                                final texto = valor?.trim() ?? '';
                                return texto.contains('@')
                                    ? null
                                    : 'Digite um e-mail válido.';
                              },
                            ),
                            const SizedBox(height: 18),
                            _CampoRotulado(
                              chave: const Key('login-senha'),
                              rotulo: 'Senha',
                              controlador: senha,
                              habilitado: !ocupado,
                              ocultar: ocultarSenha,
                              acaoTeclado: TextInputAction.done,
                              autofill: const [AutofillHints.password],
                              aoEnviar: (_) => aoEntrar(),
                              sufixo: IconButton(
                                tooltip: ocultarSenha
                                    ? 'Mostrar senha'
                                    : 'Ocultar senha',
                                onPressed: ocupado ? null : aoAlternarSenha,
                                icon: Icon(
                                  ocultarSenha
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Tokens.marcaClara,
                                ),
                              ),
                              validador: (valor) => (valor?.isEmpty ?? true)
                                  ? 'Digite sua senha.'
                                  : null,
                            ),
                            if (erro != null) ...[
                              const SizedBox(height: 16),
                              _MensagemLogin(
                                texto: erro!,
                                erro: true,
                                chave: const Key('login-erro'),
                              ),
                            ],
                            if (aviso != null) ...[
                              const SizedBox(height: 16),
                              _MensagemLogin(
                                texto: aviso!,
                                chave: const Key('login-aviso'),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 52,
                              child: FilledButton.icon(
                                key: const Key('login-entrar'),
                                onPressed: ocupado ? null : aoEntrar,
                                icon: ocupado
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.lock_outline, size: 20),
                                label: Text(ocupado ? 'Entrando…' : 'Entrar'),
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: ocupado ? null : aoRecuperar,
                              child: const Text('Esqueci minha senha'),
                            ),
                            const SizedBox(height: 16),
                            const _AvisoSeguranca(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CampoRotulado extends StatelessWidget {
  const _CampoRotulado({
    required this.chave,
    required this.rotulo,
    required this.controlador,
    required this.habilitado,
    required this.acaoTeclado,
    required this.autofill,
    required this.validador,
    this.dica,
    this.teclado,
    this.ocultar = false,
    this.aoEnviar,
    this.sufixo,
  });

  final Key chave;
  final String rotulo;
  final String? dica;
  final TextEditingController controlador;
  final bool habilitado;
  final TextInputType? teclado;
  final TextInputAction acaoTeclado;
  final List<String> autofill;
  final bool ocultar;
  final ValueChanged<String>? aoEnviar;
  final Widget? sufixo;
  final FormFieldValidator<String> validador;

  @override
  Widget build(BuildContext context) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFD9E3EC)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: const TextStyle(
            color: Tokens.marca,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          key: chave,
          controller: controlador,
          enabled: habilitado,
          keyboardType: teclado,
          textInputAction: acaoTeclado,
          autofillHints: autofill,
          obscureText: ocultar,
          onFieldSubmitted: aoEnviar,
          validator: validador,
          decoration: InputDecoration(
            hintText: dica,
            hintStyle: const TextStyle(color: Color(0xFF8295A6)),
            suffixIcon: sufixo,
            filled: true,
            fillColor: habilitado ? Colors.white : const Color(0xFFF4F7FB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: borda,
            enabledBorder: borda,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Tokens.marcaClara, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _MensagemLogin extends StatelessWidget {
  const _MensagemLogin({
    required this.texto,
    required this.chave,
    this.erro = false,
  });

  final String texto;
  final Key chave;
  final bool erro;

  @override
  Widget build(BuildContext context) {
    final cor = erro ? Tokens.perigo : Tokens.ganho;
    return Semantics(
      key: chave,
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.08),
          border: Border.all(color: cor.withValues(alpha: 0.24)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              erro ? Icons.error_outline : Icons.check_circle_outline,
              color: cor,
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(texto, style: TextStyle(color: cor, height: 1.35)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoSeguranca extends StatelessWidget {
  const _AvisoSeguranca();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Tokens.fundo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: Tokens.marcaClara, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Seu acesso continua protegido pelo Firebase e validado pela API.',
              style: TextStyle(
                color: Color(0xFF5D7285),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
