import 'package:flutter/material.dart';

import '../../core/api/api_v1.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';

/// Início — primeira integração real (Fase 4.1): consulta o `/status` da API
/// e mostra o estado honesto. Com dados de verdade (4.2+) vira o dashboard.
class PaginaInicio extends StatefulWidget {
  const PaginaInicio({super.key, required this.api});

  final ApiV1 api;

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  late Future<StatusApi> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.api.status();
  }

  void _recarregar() {
    setState(() {
      _futuro = widget.api.status();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StatusApi>(
      future: _futuro,
      builder: (context, estado) {
        if (estado.connectionState == ConnectionState.waiting) {
          return const Carregando();
        }
        if (estado.hasError) {
          return EstadoFalha(
            mensagem:
                'Não foi possível falar com o serviço. Confira se a API está no ar.',
            voltar: _recarregar,
          );
        }
        final status = estado.data!;
        return _ConteudoStatus(status);
      },
    );
  }
}

class _ConteudoStatus extends StatelessWidget {
  const _ConteudoStatus(this.status);

  final StatusApi status;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Serviço conectado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'API ${status.api}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
