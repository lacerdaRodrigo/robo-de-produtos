import 'package:flutter/material.dart';

import '../../core/api/api_v1.dart';
import '../../features/inter/pagina_cashback_inter.dart';
import '../../features/livelo/pagina_painel_livelo.dart';
import '../tema/tokens.dart';

enum FonteLojas { livelo, cashbackInter }

/// Entrada transitória e honesta para as jornadas de lojas já existentes.
///
/// O redesign completo dos cartões pertence ao Módulo 4. Esta página não
/// inventa totais nem mistura dados: apenas mantém Livelo e Shopping Inter
/// alcançáveis depois da troca da navegação principal no Módulo 2.
class PaginaLojas extends StatefulWidget {
  const PaginaLojas({
    super.key,
    required this.api,
    required this.administrador,
    required this.ativa,
  });

  final ApiV1 api;
  final bool administrador;
  final bool ativa;

  @override
  State<PaginaLojas> createState() => EstadoPaginaLojas();
}

class EstadoPaginaLojas extends State<PaginaLojas> {
  final _navegador = GlobalKey<NavigatorState>();

  void abrirFonte(FonteLojas fonte) {
    final navegador = _navegador.currentState;
    if (navegador == null) return;
    navegador.popUntil((rota) => rota.isFirst);
    final (titulo, pagina) = switch (fonte) {
      FonteLojas.livelo => (
        'Livelo',
        PaginaPainelLivelo(
          api: widget.api,
          administrador: widget.administrador,
        ),
      ),
      FonteLojas.cashbackInter => (
        'Shopping Inter',
        PaginaCashbackInter(
          api: widget.api,
          administrador: widget.administrador,
        ),
      ),
    };
    navegador.push(
      MaterialPageRoute<void>(
        builder: (_) => _PaginaInternaLojas(titulo: titulo, pagina: pagina),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler<void>(
      enabled: widget.ativa,
      onPopWithResult: (_) => _navegador.currentState?.pop(),
      child: Navigator(
        key: _navegador,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/lojas'),
          builder: (context) => _HubLojas(aoAbrir: abrirFonte),
        ),
      ),
    );
  }
}

class _HubLojas extends StatelessWidget {
  const _HubLojas({required this.aoAbrir});

  final ValueChanged<FonteLojas> aoAbrir;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const Key('hub-lojas'),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        children: [
          Text('Lojas', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Escolha a fonte que você quer consultar.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF60758A)),
          ),
          const SizedBox(height: 24),
          _AcessoFonte(
            key: const Key('abrir-lojas-livelo'),
            icone: Icons.star_outline,
            titulo: 'Livelo',
            descricao: 'Pontos e oportunidades das lojas acompanhadas.',
            aoAbrir: () => aoAbrir(FonteLojas.livelo),
          ),
          const SizedBox(height: 14),
          _AcessoFonte(
            key: const Key('abrir-lojas-inter'),
            icone: Icons.shopping_bag_outlined,
            titulo: 'Shopping Inter',
            descricao: 'Cashback dos Sites parceiros e acesso aos produtos.',
            aoAbrir: () => aoAbrir(FonteLojas.cashbackInter),
          ),
        ],
      ),
    );
  }
}

class _AcessoFonte extends StatelessWidget {
  const _AcessoFonte({
    super.key,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.aoAbrir,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoAbrir,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2FA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icone, color: Tokens.marcaClara),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(descricao),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginaInternaLojas extends StatelessWidget {
  const _PaginaInternaLojas({required this.titulo, required this.pagina});

  final String titulo;
  final Widget pagina;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('voltar-para-lojas'),
                    tooltip: 'Voltar para Lojas',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: pagina),
      ],
    );
  }
}
