import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/aparencia.dart';
import '../../app/tema/tokens.dart';

class PaginaLaboratorio extends StatefulWidget {
  const PaginaLaboratorio({super.key});

  @override
  State<PaginaLaboratorio> createState() => _EstadoPaginaLaboratorio();
}

class _EstadoPaginaLaboratorio extends State<PaginaLaboratorio> {
  String _estado = 'success';

  static const _estados = [
    'success',
    'loading',
    'empty',
    'searchEmpty',
    'error',
    'partial',
    'stale',
    'offline',
    'noSync',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final controlador = AparenciaRadar.talvezDe(context);
    const rotas = [
      'Abertura',
      'Login',
      'Recuperação',
      'Permissão push',
      'Início',
      'Explorar',
      'Livelo',
      'Banco Inter',
      'Cashback',
      'Compre direto',
      'Produtos',
      'Pichau',
      'Alertas',
      'Perfil',
      'Aparência',
      'Ajuda',
      'Relatar problema',
      'Privacidade',
      'Administração',
      'Rota inexistente',
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratório QA'),
        leading: IconButton(
          tooltip: 'Voltar ao app',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.spacing.four,
          tokens.spacing.five,
          tokens.spacing.four,
          tokens.spacing.eight,
        ),
        children: [
          const CabecalhoSecaoRadar(
            sobrelinha: 'Revisão interna',
            titulo: 'Teste cada canto do aplicativo.',
            descricao:
                'Superfície de QA para revisar cobertura, estados, temas e autorização sem repetir toda a jornada.',
          ),
          SizedBox(height: tokens.spacing.six),
          _SecaoLaboratorio(
            titulo: 'Mapa de telas · ${rotas.length} destinos',
            child: Column(
              children: [
                for (final rota in rotas) ...[
                  CartaoRadar(
                    padding: EdgeInsets.all(tokens.spacing.four),
                    child: LinhaLaboratorioRadar(titulo: rota),
                  ),
                  SizedBox(height: tokens.spacing.three),
                ],
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.five),
          _SecaoLaboratorio(
            titulo: 'Forçar uma resposta',
            child: Wrap(
              spacing: tokens.spacing.two,
              runSpacing: tokens.spacing.two,
              children: [
                for (final estado in _estados)
                  FilterChip(
                    label: Text(estado),
                    selected: _estado == estado,
                    onSelected: (_) => setState(() => _estado = estado),
                  ),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.three),
          _previewEstado(context),
          SizedBox(height: tokens.spacing.five),
          _SecaoLaboratorio(
            titulo: 'Aparência e autorização',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: controlador == null
                      ? null
                      : () => controlador.definir(
                          Theme.of(context).brightness == Brightness.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        ),
                  icon: const Icon(Icons.contrast_outlined),
                  label: const Text('Alternar tema'),
                ),
                const Text('Acesso atual: administrador (ambiente de QA).'),
              ],
            ),
          ),
          SizedBox(height: tokens.spacing.five),
          CartaoRadar(
            corDestaque: CoresRadar.de(context).perigo,
            child: Text(
              kDebugMode
                  ? 'Somente revisão. Nenhuma chamada externa é executada por esta tela.'
                  : 'Laboratório disponível apenas para revisão local.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewEstado(BuildContext context) => switch (_estado) {
    'loading' => const SizedBox(height: 180, child: Carregando()),
    'empty' || 'searchEmpty' || 'noSync' => SizedBox(
      height: 180,
      child: EstadoVazio(
        mensagem: switch (_estado) {
          'searchEmpty' => 'Nenhum resultado para esta busca.',
          'noSync' => 'Ainda não há um retrato válido sincronizado.',
          _ => 'Nenhum item para mostrar neste estado.',
        },
      ),
    ),
    'error' || 'offline' => SizedBox(
      height: 180,
      child: EstadoFalha(
        mensagem: _estado == 'offline'
            ? 'Sem conexão. O último retrato permanece preservado.'
            : 'Não foi possível carregar este retrato.',
        voltar: () => setState(() => _estado = 'success'),
      ),
    ),
    'partial' || 'stale' => CartaoRadar(
      corDestaque: CoresRadar.de(context).atencao,
      child: Text(
        _estado == 'partial'
            ? 'Resposta parcial: parte dos dados está disponível.'
            : 'Retrato atrasado: o último sucesso continua visível.',
      ),
    ),
    _ => CartaoRadar(
      corDestaque: CoresRadar.de(context).ganho,
      child: const Text('Sucesso: dados válidos disponíveis.'),
    ),
  };
}

class _SecaoLaboratorio extends StatelessWidget {
  const _SecaoLaboratorio({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        titulo,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      SizedBox(height: context.tokens.spacing.three),
      child,
    ],
  );
}

class LinhaLaboratorioRadar extends StatelessWidget {
  const LinhaLaboratorioRadar({super.key, required this.titulo});

  final String titulo;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(titulo)),
      const Icon(Icons.arrow_forward, size: 20),
    ],
  );
}
