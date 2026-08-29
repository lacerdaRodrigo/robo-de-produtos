import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import 'formato_livelo.dart';

/// Histórico de leitura do parceiro do catálogo atual.
///
/// Não recebe nem inicia uma coleta: a única chamada é a rota autenticada que
/// lê as medições já persistidas pelo robô.
class PaginaHistoricoLiveloAndroid extends StatefulWidget {
  const PaginaHistoricoLiveloAndroid({
    super.key,
    required this.api,
    required this.parceiro,
  });

  final Api api;
  final ParceiroCatalogoLivelo parceiro;

  @override
  State<PaginaHistoricoLiveloAndroid> createState() =>
      _EstadoPaginaHistoricoLiveloAndroid();
}

class _EstadoPaginaHistoricoLiveloAndroid
    extends State<PaginaHistoricoLiveloAndroid> {
  HistoricoLivelo? _historico;
  Object? _erro;
  var _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final historico = await widget.api.historicoLivelo(
        widget.parceiro.idExterno,
      );
      if (mounted) setState(() => _historico = historico);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Histórico')),
    body: _corpo(),
  );

  Widget _corpo() {
    if (_carregando) {
      return const Carregando(mensagem: 'Carregando histórico…');
    }
    if (_erro != null) {
      return EstadoFalha(
        mensagem: 'Não foi possível carregar o histórico desta loja.',
        voltar: _carregar,
      );
    }
    final medicoes = _historico!.medicoes;
    if (medicoes.isEmpty) {
      return EstadoVazio(
        mensagem:
            'Ainda não há medições históricas para ${widget.parceiro.nome}.',
      );
    }
    return ListView(
      key: const Key('historico-livelo-android'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Text(
          widget.parceiro.nome,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Últimas coletas salvas',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final medicao in medicoes)
          Card(
            child: ListTile(
              title: Text(
                pontosLivelo(medicao.pontos, moeda: medicao.moeda),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(dataHoraLivelo(medicao.momento)),
              trailing: const Icon(Icons.history),
            ),
          ),
      ],
    );
  }
}
