import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/idempotencia.dart';
import '../../core/api/modelos.dart';
import '../../app/tema/tokens.dart';

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
    this.aoAceitar,
    this.compacto = false,
  });

  final Api api;
  final String dominio;
  final bool administrador;
  final String rotulo;
  final VoidCallback? aoAceitar;
  final bool compacto;

  @override
  State<BotaoDisparo> createState() => _EstadoBotaoDisparo();
}

class _EstadoBotaoDisparo extends State<BotaoDisparo> {
  EstadoDisparoAdministrativo? _estado;
  String? _chave;
  bool _carregando = false;
  bool _solicitando = false;
  Object? _erro;
  Timer? _cooldown;

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
      if (mounted) {
        setState(() => _estado = estado);
        _iniciarContagem();
      }
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
      _iniciarContagem();
      widget.aoAceitar?.call();
      mostrarMensagemRadar(
        context,
        resultado.estado == 'aceito'
            ? 'Pedido de coleta aceito. Os dados atualizam quando o robô terminar.'
            : 'Pedido já está sendo processado.',
      );
    } catch (erro) {
      // Falha final conhecida permite uma nova intenção. Para falha de rede,
      // mantém a chave: o próximo toque consulta a mesma reserva no servidor.
      if (erro is ErroDeApi && erro.codigo == 'disparo') _chave = null;
      if (mounted) {
        final espera = erro is ErroDeApi && erro.codigo == 'cooldown'
            ? erro.retryAfterSeconds
            : null;
        if (espera != null) {
          final estado = _estado;
          setState(
            () => _estado = EstadoDisparoAdministrativo(
              dominio: widget.dominio,
              cooldownSegundos: espera,
              ultimaSolicitacaoEm: estado?.ultimaSolicitacaoEm,
              ultimoEstado: estado?.ultimoEstado,
            ),
          );
          _iniciarContagem();
        }
        final mensagem = espera != null
            ? 'Aguarde ${_tempo(espera)} antes de solicitar uma nova atualização.'
            : erro is ErroDeApi
            ? erro.mensagem
            : 'Não foi possível solicitar a coleta.';
        mostrarMensagemRadar(context, mensagem, sucesso: false);
      }
    } finally {
      if (mounted) setState(() => _solicitando = false);
    }
  }

  void _iniciarContagem() {
    _cooldown?.cancel();
    if ((_estado?.cooldownSegundos ?? 0) <= 0) return;
    _cooldown = Timer.periodic(const Duration(seconds: 1), (_) {
      final estado = _estado;
      if (!mounted || estado == null || estado.cooldownSegundos <= 0) {
        _cooldown?.cancel();
        return;
      }
      setState(
        () => _estado = EstadoDisparoAdministrativo(
          dominio: estado.dominio,
          cooldownSegundos: estado.cooldownSegundos - 1,
          ultimaSolicitacaoEm: estado.ultimaSolicitacaoEm,
          ultimoEstado: estado.ultimoEstado,
        ),
      );
    });
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
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
    final texto = _solicitando
        ? 'Solicitando…'
        : espera > 0
        ? 'Aguarde ${_tempo(espera)}'
        : widget.rotulo;
    // No compacto o rótulo não muda durante o cooldown: isso preserva a
    // largura das abas e deixa o estado completo disponível no tooltip.
    final textoCompacto = _solicitando ? 'Atualizando…' : widget.rotulo;
    return Tooltip(
      message: espera > 0
          ? 'Aguarde ${_tempo(espera)} para pedir nova coleta.'
          : 'Solicitar: ${widget.rotulo}',
      child: widget.compacto
          ? TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 39),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                foregroundColor: CoresRadar.de(context).textoSuave,
              ),
              onPressed: espera > 0 || _solicitando ? null : _solicitar,
              child: Text(textoCompacto),
            )
          : FilledButton.tonalIcon(
              onPressed: espera > 0 || _solicitando ? null : _solicitar,
              icon: _solicitando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(texto),
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
