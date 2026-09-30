import 'package:flutter/material.dart';

import '../../app/tema/aparencia.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/componentes/menu_conta.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';

class PaginaPerfil extends StatelessWidget {
  const PaginaPerfil({
    super.key,
    required this.api,
    this.identificacao,
    required this.administrador,
    required this.aoAbrirAcompanhamentos,
    required this.aoAbrirNotificacoes,
    required this.aoAbrirAparencia,
    required this.aoAbrirAjuda,
    required this.aoAbrirProblema,
    required this.aoAbrirRelatos,
    required this.aoAbrirPrivacidade,
    this.aoAbrirLaboratorio,
    this.aoAdministrar,
    this.aoSair,
  });

  final String? identificacao;
  final Api api;
  final bool administrador;
  final VoidCallback aoAbrirAcompanhamentos;
  final VoidCallback aoAbrirNotificacoes;
  final VoidCallback aoAbrirAparencia;
  final VoidCallback aoAbrirAjuda;
  final VoidCallback aoAbrirProblema;
  final VoidCallback aoAbrirRelatos;
  final VoidCallback aoAbrirPrivacidade;
  final VoidCallback? aoAbrirLaboratorio;
  final VoidCallback? aoAdministrar;
  final Future<void> Function()? aoSair;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    final modo = AparenciaRadar.talvezDe(context)?.modo ?? ThemeMode.system;
    final descricaoAparencia = switch (modo) {
      ThemeMode.light => 'Tema claro',
      ThemeMode.dark => 'Tema escuro',
      ThemeMode.system => 'Seguir o sistema',
    };
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spacing.five,
            tokens.spacing.three,
            tokens.spacing.five,
            tokens.spacing.eight,
          ),
          children: [
            const CabecalhoMarcaRadar(
              key: Key('perfil-cabecalho'),
              rotulo: 'SUA CONTA',
              rotuloNoInicio: true,
            ),
            SizedBox(height: tokens.spacing.six),
            Semantics(
              key: const Key('perfil-conta'),
              container: true,
              label: 'Olá. ${identificacao ?? 'Sua conta no Radar'}',
              excludeSemantics: true,
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: CircleAvatar(
                      radius: (tokens.spacing.nine + tokens.spacing.three) / 2,
                      backgroundColor: cores.acaoFundo,
                      foregroundColor: cores.acao,
                      child: Text(
                        iniciaisContaRadar(identificacao ?? 'Radar'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spacing.four),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: tokens.spacing.one),
                        Text(
                          identificacao ?? 'Sua conta no Radar',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: cores.textoSuave),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: tokens.spacing.six),
            _grupo(
              context,
              chave: 'perfil-grupo-conta',
              itens: [
                _ItemPerfil(
                  chave: 'perfil-acompanhamentos',
                  icone: Icons.bookmark_border_rounded,
                  titulo: 'Acompanhamentos',
                  descricao: '',
                  descricaoPersonalizada: _DescricaoAcompanhamentos(api: api),
                  aoTocar: aoAbrirAcompanhamentos,
                ),
                _ItemPerfil(
                  chave: 'perfil-aparencia',
                  icone: Icons.dark_mode_outlined,
                  titulo: 'Aparência',
                  descricao: descricaoAparencia,
                  aoTocar: aoAbrirAparencia,
                ),
                _ItemPerfil(
                  chave: 'perfil-notificacoes',
                  icone: Icons.notifications_none_rounded,
                  titulo: 'Notificações',
                  descricao: 'Escolha o que quer receber',
                  descricaoPersonalizada: _DescricaoNotificacoes(api: api),
                  aoTocar: aoAbrirNotificacoes,
                ),
              ],
            ),
            SizedBox(height: tokens.spacing.eight),
            Text(
              'SUPORTE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cores.textoSuave,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: tokens.spacing.one),
            _grupo(
              context,
              chave: 'perfil-grupo-suporte',
              itens: [
                _ItemPerfil(
                  chave: 'perfil-ajuda',
                  icone: Icons.help_outline,
                  titulo: 'Ajuda',
                  descricao: 'Respostas para usar o Radar',
                  aoTocar: aoAbrirAjuda,
                ),
                _ItemPerfil(
                  chave: 'perfil-problema',
                  icone: Icons.message_outlined,
                  titulo: 'Relatar problema',
                  descricao: 'Conte o que aconteceu',
                  aoTocar: aoAbrirProblema,
                ),
                _ItemPerfil(
                  chave: 'perfil-relatos',
                  icone: Icons.history_rounded,
                  titulo: 'Meus relatos',
                  descricao: 'Veja os protocolos que você enviou',
                  aoTocar: aoAbrirRelatos,
                ),
                _ItemPerfil(
                  chave: 'perfil-privacidade',
                  icone: Icons.shield_outlined,
                  titulo: 'Privacidade',
                  descricao: 'Como seus dados são usados',
                  aoTocar: aoAbrirPrivacidade,
                ),
              ],
            ),
            if (aoAdministrar != null) ...[
              SizedBox(height: tokens.spacing.eight),
              Text(
                'GESTÃO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cores.textoSuave,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spacing.one),
              _grupo(
                context,
                chave: 'perfil-grupo-gestao',
                itens: [
                  _ItemPerfil(
                    chave: 'perfil-administracao',
                    icone: Icons.lock_outline,
                    titulo: 'Administração',
                    descricao: 'Operações por domínio',
                    aoTocar: aoAdministrar!,
                  ),
                ],
              ),
            ],
            if (aoSair != null) ...[
              SizedBox(height: tokens.spacing.six),
              OutlinedButton.icon(
                key: const Key('sair-conta'),
                onPressed: aoSair,
                icon: const Icon(Icons.logout),
                label: const Text('Sair da conta'),
              ),
            ],
            SizedBox(height: tokens.spacing.six),
            Text(
              'Radar de Benefícios · Mobile 15\nPreços, cashback e pontos em um só lugar.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grupo(
    BuildContext context, {
    required String chave,
    required List<_ItemPerfil> itens,
  }) {
    final tokens = context.tokens;
    return CartaoRadar(
      key: Key(chave),
      comSombra: false,
      comBorda: false,
      padding: EdgeInsetsDirectional.symmetric(horizontal: tokens.spacing.four),
      child: Column(
        children: [
          for (var indice = 0; indice < itens.length; indice++) ...[
            itens[indice],
            if (indice < itens.length - 1)
              Divider(height: 1, color: CoresRadar.de(context).borda),
          ],
        ],
      ),
    );
  }
}

class _ItemPerfil extends StatelessWidget {
  const _ItemPerfil({
    required this.chave,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.aoTocar,
    this.descricaoPersonalizada,
  });

  final String chave;
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback aoTocar;
  final Widget? descricaoPersonalizada;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    return InkWell(
      key: Key(chave),
      borderRadius: BorderRadius.circular(tokens.radii.md),
      onTap: aoTocar,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: tokens.spacing.four),
        child: Row(
          children: [
            Icon(icone, color: cores.textoSuave),
            SizedBox(width: tokens.spacing.three),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.one),
                  descricaoPersonalizada ??
                      Text(
                        descricao,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cores.textoSuave,
                        ),
                      ),
                ],
              ),
            ),
            SizedBox(width: tokens.spacing.two),
            Icon(
              Icons.chevron_right,
              size: tokens.spacing.five,
              color: cores.textoSuave,
            ),
          ],
        ),
      ),
    );
  }
}

class _DescricaoAcompanhamentos extends StatefulWidget {
  const _DescricaoAcompanhamentos({required this.api});

  final Api api;

  @override
  State<_DescricaoAcompanhamentos> createState() =>
      _DescricaoAcompanhamentosState();
}

class _DescricaoAcompanhamentosState extends State<_DescricaoAcompanhamentos> {
  late final Future<ResumoInicio> _resumo = widget.api.resumo();

  @override
  Widget build(BuildContext context) => FutureBuilder<ResumoInicio>(
    future: _resumo,
    builder: (context, estado) {
      final texto = switch (estado.connectionState) {
        ConnectionState.waiting => 'Carregando seus itens…',
        ConnectionState.none => 'Itens no seu radar',
        ConnectionState.active => 'Carregando seus itens…',
        ConnectionState.done =>
          estado.hasError
              ? 'Contagem indisponível'
              : _descricaoTotal(estado.data?.radar.totalAcompanhamentos),
      };
      return Text(
        texto,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: CoresRadar.de(context).textoSuave,
        ),
      );
    },
  );

  String _descricaoTotal(int? total) {
    if (total == null) return 'Contagem indisponível';
    return '$total ${total == 1 ? 'item' : 'itens'} no seu radar';
  }
}

class _DescricaoNotificacoes extends StatefulWidget {
  const _DescricaoNotificacoes({required this.api});

  final Api api;

  @override
  State<_DescricaoNotificacoes> createState() => _DescricaoNotificacoesState();
}

class _DescricaoNotificacoesState extends State<_DescricaoNotificacoes> {
  late final Future<PreferenciasAlertas> _preferencias = widget.api
      .preferenciasAlertas();

  @override
  Widget build(BuildContext context) => FutureBuilder<PreferenciasAlertas>(
    future: _preferencias,
    builder: (context, estado) {
      final texto = switch (estado.connectionState) {
        ConnectionState.waiting => 'Carregando preferências…',
        ConnectionState.none => 'Escolha o que quer receber',
        ConnectionState.active => 'Carregando preferências…',
        ConnectionState.done =>
          estado.hasError || estado.data == null
              ? 'Preferências indisponíveis'
              : estado.data!.pushGlobal
              ? 'Preferência de avisos ativa'
              : 'Escolha o que quer receber',
      };
      return Text(
        texto,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: CoresRadar.de(context).textoSuave,
        ),
      );
    },
  );
}
