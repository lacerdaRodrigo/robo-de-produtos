import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import 'gerenciador_notificacoes.dart';

class PaginaPermissaoNotificacoes extends StatefulWidget {
  const PaginaPermissaoNotificacoes({
    super.key,
    required this.api,
    this.aoConcluir,
  });

  final Api api;
  final VoidCallback? aoConcluir;

  @override
  State<PaginaPermissaoNotificacoes> createState() =>
      _EstadoPaginaPermissaoNotificacoes();
}

class _EstadoPaginaPermissaoNotificacoes
    extends State<PaginaPermissaoNotificacoes> {
  late final GerenciadorNotificacoes _notificacoes = GerenciadorNotificacoes(
    api: widget.api,
    aoAbrirCentral: (_) {},
  );
  bool _ocupado = false;
  String? _resultado;

  @override
  void dispose() {
    _notificacoes.dispose();
    super.dispose();
  }

  Future<void> _permitir() async {
    if (_ocupado) return;
    setState(() {
      _ocupado = true;
      _resultado = null;
    });
    final status = await _notificacoes.solicitarPermissao();
    if (!mounted) return;
    setState(() {
      _ocupado = false;
      _resultado = _mensagemStatus(status);
    });
    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      widget.aoConcluir?.call();
    }
  }

  String _mensagemStatus(AuthorizationStatus? status) => switch (status) {
    AuthorizationStatus.authorized =>
      'Permissão concedida. Você pode revisar as preferências na Central de Alertas.',
    AuthorizationStatus.provisional =>
      'Permissão provisória concedida. A Central continua disponível.',
    AuthorizationStatus.denied =>
      'Notificações não foram permitidas. A Central de Alertas continua disponível.',
    AuthorizationStatus.notDetermined =>
      'A decisão ficou pendente. Você pode tentar novamente quando quiser.',
    null =>
      kIsWeb
          ? 'Notificações push não são solicitadas no Web.'
          : 'Não foi possível acessar a permissão neste dispositivo agora.',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissão de notificações'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            tokens.spacing.four,
            tokens.spacing.five,
            tokens.spacing.four,
            tokens.spacing.eight,
          ),
          children: [
            CartaoRadar(
              corDestaque: cores.teal,
              padding: EdgeInsets.all(tokens.spacing.six),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cores.superficieAlternativa,
                      borderRadius: BorderRadius.circular(tokens.radii.md),
                    ),
                    child: SizedBox.square(
                      dimension: tokens.spacing.ten,
                      child: Icon(
                        Icons.notifications_outlined,
                        color: cores.teal,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.five),
                  const CabecalhoSecaoRadar(
                    sobrelinha: 'Um pedido no momento certo',
                    titulo: 'Quer receber mudanças importantes?',
                    descricao:
                        'O push avisa quando um item acompanhado muda. O histórico continua disponível mesmo sem notificações.',
                  ),
                  SizedBox(height: tokens.spacing.six),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('permitir-notificacoes'),
                      onPressed: _ocupado ? null : _permitir,
                      icon: _ocupado
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active_outlined),
                      label: Text(
                        _ocupado ? 'Abrindo pedido…' : 'Permitir notificações',
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.two),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      key: const Key('agora-nao-notificacoes'),
                      onPressed: _ocupado
                          ? null
                          : () => Navigator.of(context).maybePop(),
                      child: const Text('Agora não'),
                    ),
                  ),
                  if (_resultado != null) ...[
                    SizedBox(height: tokens.spacing.four),
                    Text(
                      _resultado!,
                      key: const Key('resultado-permissao-notificacoes'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: tokens.spacing.four),
            Text(
              'Você pode rever essa escolha nas preferências da Central de Alertas. Negar o push não impede o acesso ao histórico.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
            ),
          ],
        ),
      ),
    );
  }
}
