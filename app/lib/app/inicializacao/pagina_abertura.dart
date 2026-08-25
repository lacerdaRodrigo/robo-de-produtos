import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/autenticacao/autenticador.dart';
import '../../core/autenticacao/configuracao_firebase.dart';
import '../autenticacao/portao.dart';
import '../identidade/logo_radar.dart';
import '../tema/tokens.dart';

typedef InicializadorAcesso = Future<InicializacaoFirebase> Function();
typedef FabricaApiAutenticada = Api Function(Autenticador autenticador);

/// Abertura Flutter exibida enquanto Firebase, App Check e sessão são
/// preparados. Cumpre o ciclo visual mínimo aprovado; quando a inicialização
/// demora mais, o fluxo segue sem acrescentar outra espera.
class PaginaAbertura extends StatefulWidget {
  const PaginaAbertura({
    super.key,
    required this.inicializar,
    required this.fabricarApi,
    this.tempoMinimo = const Duration(milliseconds: 1500),
    this.tempoParaAviso = const Duration(seconds: 4),
  });

  final InicializadorAcesso inicializar;
  final FabricaApiAutenticada fabricarApi;
  final Duration tempoMinimo;
  final Duration tempoParaAviso;

  @override
  State<PaginaAbertura> createState() => _EstadoPaginaAbertura();
}

class _EstadoPaginaAbertura extends State<PaginaAbertura> {
  Timer? _aviso;
  int _tentativa = 0;
  bool _demorada = false;
  String? _erro;
  Autenticador? _autenticador;
  Api? _api;

  @override
  void initState() {
    super.initState();
    _iniciar(primeiraVez: true);
  }

  @override
  void dispose() {
    _aviso?.cancel();
    super.dispose();
  }

  void _iniciar({bool primeiraVez = false}) {
    final tentativaAtual = ++_tentativa;
    _aviso?.cancel();
    if (primeiraVez) {
      _demorada = false;
      _erro = null;
    } else {
      setState(() {
        _demorada = false;
        _erro = null;
      });
    }

    _aviso = Timer(widget.tempoParaAviso, () {
      if (mounted && tentativaAtual == _tentativa) {
        setState(() => _demorada = true);
      }
    });

    Future<void>.sync(() async {
      final esperaVisual = widget.tempoMinimo == Duration.zero
          ? null
          : Future<void>.delayed(widget.tempoMinimo);
      final resultado = await widget.inicializar();
      if (esperaVisual != null) await esperaVisual;
      if (!mounted || tentativaAtual != _tentativa) return;
      _aviso?.cancel();
      final autenticador = resultado.autenticador;
      if (autenticador == null) {
        setState(() {
          _erro =
              resultado.mensagem ??
              'Não foi possível preparar seu acesso agora.';
        });
        return;
      }
      final api = widget.fabricarApi(autenticador);
      if (!mounted || tentativaAtual != _tentativa) return;
      setState(() {
        _autenticador = autenticador;
        _api = api;
      });
    }).catchError((Object _) {
      if (!mounted || tentativaAtual != _tentativa) return;
      _aviso?.cancel();
      setState(() {
        _erro = 'Não foi possível preparar seu acesso agora.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final autenticador = _autenticador;
    final api = _api;
    if (autenticador != null && api != null) {
      return PortaoAutenticacao(
        autenticador: autenticador,
        api: api,
        construirValidacao: (_) => const TelaAberturaRadar(
          mensagem: 'Validando seu acesso ao piloto…',
        ),
      );
    }

    return TelaAberturaRadar(
      mensagem: _demorada
          ? 'A validação segura está levando um pouco mais de tempo…'
          : 'Preparando seu radar…',
      explicacao: _demorada
          ? 'Você pode aguardar. Se a inicialização falhar, será possível tentar novamente.'
          : null,
      erro: _erro,
      tentarNovamente: _erro == null ? null : () => _iniciar(),
    );
  }
}

/// Composição da abertura, reutilizada durante a validação de Firebase, sessão
/// e convite para não cair no carregamento branco antigo.
class TelaAberturaRadar extends StatelessWidget {
  const TelaAberturaRadar({
    super.key,
    required this.mensagem,
    this.explicacao,
    this.erro,
    this.tentarNovamente,
  });

  final String mensagem;
  final String? explicacao;
  final String? erro;
  final VoidCallback? tentarNovamente;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tokens.marcaProfunda,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MarcaAbertura(),
                    const SizedBox(height: 24),
                    Text(
                      'Radar',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pontos, cashback e preços reunidos em um só radar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFC6D7E7)),
                    ),
                    const SizedBox(height: 28),
                    if (erro == null)
                      _EstadoPreparacao(
                        mensagem: mensagem,
                        explicacao: explicacao,
                      ),
                    if (erro != null) ...[
                      const Icon(
                        Icons.error_outline,
                        key: Key('abertura-erro'),
                        color: Color(0xFFFFB4AB),
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        key: const Key('abertura-tentar-novamente'),
                        onPressed: tentarNovamente,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Tokens.marca,
                          minimumSize: const Size(190, 48),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EstadoPreparacao extends StatelessWidget {
  const _EstadoPreparacao({required this.mensagem, this.explicacao});

  final String mensagem;
  final String? explicacao;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF55D5ED),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                mensagem,
                key: const Key('abertura-status'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        if (explicacao != null) ...[
          const SizedBox(height: 10),
          Text(
            explicacao!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFC6D7E7), fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class MarcaAbertura extends StatefulWidget {
  const MarcaAbertura({super.key});

  @override
  State<MarcaAbertura> createState() => _EstadoMarcaAbertura();
}

class _EstadoMarcaAbertura extends State<MarcaAbertura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controle;
  bool? _reduzirMovimento;

  @override
  void initState() {
    super.initState();
    _controle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduzir = MediaQuery.disableAnimationsOf(context);
    if (_reduzirMovimento == reduzir) return;
    _reduzirMovimento = reduzir;
    if (reduzir) {
      _controle
        ..stop()
        ..value = 0;
    } else {
      _controle.repeat();
    }
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduzir = _reduzirMovimento ?? true;
    return TickerMode(
      key: const Key('abertura-ticker'),
      enabled: !reduzir,
      child: Semantics(
        image: true,
        label: 'Radar de Benefícios',
        child: SizedBox.square(
          dimension: 168,
          child: AnimatedBuilder(
            animation: _controle,
            builder: (context, _) {
              final valor = reduzir ? 0.0 : _controle.value;
              final pulsoA = valor;
              final pulsoB = (valor + 0.5) % 1;
              final respiracao = 1 + (0.018 * (1 - (2 * (valor - 0.5)).abs()));
              return Stack(
                alignment: Alignment.center,
                children: [
                  _PulsoRadar(progresso: pulsoA),
                  _PulsoRadar(progresso: pulsoB),
                  Transform.scale(
                    scale: respiracao,
                    child: LogoRadar(
                      tamanho: 112,
                      sobreFundoEscuro: true,
                      progresso: valor,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PulsoRadar extends StatelessWidget {
  const _PulsoRadar({required this.progresso});

  final double progresso;

  @override
  Widget build(BuildContext context) {
    final tamanho = 118 + (46 * progresso);
    return IgnorePointer(
      child: Opacity(
        opacity: (1 - progresso) * 0.42,
        child: Container(
          width: tamanho,
          height: tamanho,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF55D5ED), width: 2),
          ),
        ),
      ),
    );
  }
}
