import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/autenticacao/autenticador.dart';
import 'pagina_recuperar.dart';
import '../identidade/logo_radar.dart';
import '../tema/tokens.dart';

abstract final class _TokensLogin {
  static const marca = Tokens.ink;
  static const marcaClara = Tokens.action;
  static const ganho = Tokens.teal;
  static const perigo = Tokens.danger;
}

class PaginaEntrar extends StatefulWidget {
  const PaginaEntrar({super.key, required this.autenticador});

  final Autenticador autenticador;

  @override
  State<PaginaEntrar> createState() => _EstadoPaginaEntrar();
}

class _EstadoPaginaEntrar extends State<PaginaEntrar> {
  static const _larguraLayoutAmplo = 920.0;
  final _formulario = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _ocupado = false;
  bool _ocultarSenha = true;
  String? _erro;

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

  @override
  Widget build(BuildContext context) {
    final pagina = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            aoAlternarSenha: () =>
                setState(() => _ocultarSenha = !_ocultarSenha),
            aoEntrar: _entrar,
            aoAbrirRecuperacao: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => PaginaRecuperarAcesso(
                  autenticador: widget.autenticador,
                  emailInicial: _email.text,
                ),
              ),
            ),
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
    return pagina;
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
        decoration: const BoxDecoration(color: Tokens.ink),
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
                            color: Tokens.textoSuaveEscuro,
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
                    color: Tokens.acaoEscura.withValues(
                      alpha: tamanho == 620 ? 0.18 : 0.1,
                    ),
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
    final cor = compacta ? _TokensLogin.marca : Tokens.actionInk;
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return Row(
      key: compacta ? const Key('login-marca-compacta') : null,
      mainAxisSize: compacta ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (compacta && !escuro)
          SvgPicture.asset(
            'assets/brand/wordmark.svg',
            width: 150,
            height: 38,
            semanticsLabel: 'radar.',
          )
        else if (compacta)
          SvgPicture.asset(
            'assets/brand/symbol-dark.svg',
            width: 42,
            height: 42,
            semanticsLabel: 'Radar',
          )
        else
          const LogoRadar(
            tamanho: 48,
            sobreFundoEscuro: true,
            rotuloSemantico: 'Radar',
          ),
        if (!compacta || escuro) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'radar.',
              style: TextStyle(
                color: cor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
              color: Tokens.actionInk.withValues(alpha: 0.08),
              border: Border.all(
                color: Tokens.actionInk.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'SEU RADAR DE OPORTUNIDADES',
              style: TextStyle(
                color: Tokens.acaoEscura,
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
              color: Tokens.actionInk,
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
                color: Tokens.textoSuaveEscuro,
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
            color: Tokens.acaoEscura,
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: 8),
        ),
        const SizedBox(width: 8),
        Text(
          texto,
          style: const TextStyle(color: Tokens.textoSuaveEscuro, fontSize: 14),
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
    required this.aoAlternarSenha,
    required this.aoEntrar,
    required this.aoAbrirRecuperacao,
  });

  final bool compacto;
  final GlobalKey<FormState> formulario;
  final TextEditingController email;
  final TextEditingController senha;
  final bool ocupado;
  final bool ocultarSenha;
  final String? erro;
  final VoidCallback aoAlternarSenha;
  final VoidCallback aoEntrar;
  final VoidCallback aoAbrirRecuperacao;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
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
                              const SizedBox(height: 20),
                              const Image(
                                image: AssetImage(
                                  'assets/illustrations/descoberta.png',
                                ),
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.contain,
                                semanticLabel:
                                    'Composição de descoberta de preços',
                              ),
                              const SizedBox(height: 20),
                            ],
                            Text(
                              compacto
                                  ? 'Bom te ver por aqui.'
                                  : 'Que bom ter você aqui',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: compacto ? 42 : null,
                                    height: compacto ? 0.98 : null,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: compacto ? -2.2 : -1,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              compacto
                                  ? 'Entre e acompanhe suas próximas escolhas.'
                                  : 'Entre com seu acesso para ver as oportunidades acompanhadas.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                                  color: _TokensLogin.marcaClara,
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
                                          color: Tokens.actionInk,
                                        ),
                                      )
                                    : const Icon(Icons.lock_outline, size: 20),
                                label: Text(ocupado ? 'Entrando…' : 'Entrar'),
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: ocupado ? null : aoAbrirRecuperacao,
                              child: const Text('Recuperar acesso'),
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
    final cores = CoresRadar.de(context);
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(context.tokens.radii.md),
      borderSide: BorderSide(color: cores.borda),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
            hintStyle: TextStyle(color: cores.textoSuave),
            suffixIcon: sufixo,
            filled: true,
            fillColor: habilitado
                ? Theme.of(context).cardColor
                : cores.superficieAlternativa,
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.tokens.spacing.four,
              vertical: context.tokens.spacing.four,
            ),
            border: borda,
            enabledBorder: borda,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.tokens.radii.md),
              borderSide: const BorderSide(color: Tokens.action, width: 2),
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
    final cor = erro ? _TokensLogin.perigo : _TokensLogin.ganho;
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
    final cores = CoresRadar.de(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.superficieAlternativa,
        borderRadius: BorderRadius.circular(context.tokens.radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline, color: Tokens.action, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Seu acesso continua protegido pelo Firebase e validado pela API.',
              style: TextStyle(
                color: cores.textoSuave,
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
