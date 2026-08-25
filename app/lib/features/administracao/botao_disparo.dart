import 'package:flutter/material.dart';

import '../../core/api/api_v1.dart';
import '../../core/api/erros.dart';
import '../../core/api/idempotencia.dart';
import '../../core/api/modelos.dart';

/// Botão administrativo que pede uma coleta, mas nunca promete que ela acabou.
///
/// A chave permanece enquanto houver dúvida de rede: repetir o toque reenviará
/// a mesma intenção ao servidor, não outro dispatch para o GitHub.
class BotaoDisparo extends StatefulWidget {
  const BotaoDisparo({
    super.key,
    required this.api,
    required this.dominio,
    required this.administrador,
    this.rotulo = 'Atualizar agora',
  });

  final ApiV1 api;
  final String dominio;
  final bool administrador;
  final String rotulo;

  @override
  State<BotaoDisparo> createState() => _EstadoBotaoDisparo();
}

class _EstadoBotaoDisparo extends State<BotaoDisparo> {
  EstadoDisparoAdministrativo? _estado;
  String? _chave;
  bool _carregando = false;
  bool _solicitando = false;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    if (widget.administrador) _consultar();
  }

  Future<void> _consultar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final estado = await widget.api.estadoDisparo(widget.dominio);
      if (mounted) setState(() => _estado = estado);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _solicitar() async {
    if (_solicitando || (_estado?.cooldownSegundos ?? 0) > 0) return;
    setState(() => _solicitando = true);
    final chave = _chave ??= novaChaveDeIdempotencia();
    try {
      final resultado = await widget.api.solicitarDisparo(
        dominio: widget.dominio,
        chaveIdempotencia: chave,
      );
      if (!mounted) return;
      setState(
        () => _estado = EstadoDisparoAdministrativo(
          dominio: resultado.dominio,
          cooldownSegundos: resultado.cooldownSegundos,
          ultimaSolicitacaoEm: DateTime.now().toUtc().toIso8601String(),
          ultimoEstado: resultado.estado == 'aceito' ? 'aceita' : 'reservada',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado.estado == 'aceito'
                ? 'Pedido de coleta aceito. Os dados atualizam quando o robô terminar.'
                : 'Pedido já está sendo processado.',
          ),
        ),
      );
    } catch (erro) {
      // Falha final conhecida permite uma nova intenção. Para falha de rede,
      // mantém a chave: o próximo toque consulta a mesma reserva no servidor.
      if (erro is ErroDeApi && erro.codigo == 'disparo') _chave = null;
      if (mounted) {
        final mensagem = erro is ErroDeApi
            ? erro.mensagem
            : 'Não foi possível solicitar a coleta.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensagem)));
      }
    } finally {
      if (mounted) setState(() => _solicitando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.administrador) return const SizedBox.shrink();
    if (_carregando) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_erro != null) {
      return IconButton(
        tooltip: 'Verificar disponibilidade de atualização',
        onPressed: _consultar,
        icon: const Icon(Icons.refresh),
      );
    }
    final espera = _estado?.cooldownSegundos ?? 0;
    return Tooltip(
      message: espera > 0
          ? 'Aguarde ${_tempo(espera)} para pedir nova coleta.'
          : 'Solicitar: ${widget.rotulo}',
      child: FilledButton.tonalIcon(
        onPressed: espera > 0 || _solicitando ? null : _solicitar,
        icon: _solicitando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        label: Text(
          _solicitando
              ? 'Solicitando…'
              : espera > 0
              ? 'Aguarde ${_tempo(espera)}'
              : widget.rotulo,
        ),
      ),
    );
  }

  String _tempo(int segundos) {
    final minutos = segundos ~/ 60;
    final resto = segundos % 60;
    if (minutos == 0) return '${resto}s';
    return resto == 0 ? '$minutos min' : '$minutos min ${resto}s';
  }
}
