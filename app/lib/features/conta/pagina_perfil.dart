import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/componentes/menu_conta.dart';
import '../../app/tema/tokens.dart';

class PaginaPerfil extends StatelessWidget {
  const PaginaPerfil({
    super.key,
    this.identificacao,
    required this.administrador,
    required this.aoAbrirAlertas,
    required this.aoAbrirAparencia,
    required this.aoAbrirAjuda,
    required this.aoAbrirProblema,
    required this.aoAbrirPrivacidade,
    this.aoAbrirLaboratorio,
    this.aoAdministrar,
    this.aoSair,
  });

  final String? identificacao;
  final bool administrador;
  final VoidCallback aoAbrirAlertas;
  final VoidCallback aoAbrirAparencia;
  final VoidCallback aoAbrirAjuda;
  final VoidCallback aoAbrirProblema;
  final VoidCallback aoAbrirPrivacidade;
  final VoidCallback? aoAbrirLaboratorio;
  final VoidCallback? aoAdministrar;
  final Future<void> Function()? aoSair;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final nome = identificacao ?? 'Conta do Radar';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
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
            CabecalhoSecaoRadar(
              sobrelinha: 'Perfil',
              titulo: 'Olá, $nome.',
              descricao: identificacao ?? 'Sessão autenticada do Radar.',
            ),
            SizedBox(height: tokens.spacing.six),
            PerfilContaRadar(
              identificacao: identificacao,
              administrador: administrador,
            ),
            SizedBox(height: tokens.spacing.five),
            _menu(context),
            if (aoSair != null) ...[
              SizedBox(height: tokens.spacing.five),
              OutlinedButton.icon(
                key: const Key('sair-conta'),
                onPressed: aoSair,
                icon: const Icon(Icons.logout),
                label: const Text('Sair do Radar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    final itens = <Widget>[
      _item(
        context,
        chave: 'perfil-alertas',
        icone: Icons.notifications_outlined,
        titulo: 'Central de Alertas',
        descricao: 'Mudanças dos itens acompanhados',
        aoTocar: aoAbrirAlertas,
      ),
      _item(
        context,
        chave: 'perfil-aparencia',
        icone: Icons.tune_rounded,
        titulo: 'Aparência',
        descricao: 'Claro, escuro ou preferência do sistema',
        aoTocar: aoAbrirAparencia,
      ),
      _item(
        context,
        chave: 'perfil-ajuda',
        icone: Icons.help_outline,
        titulo: 'Ajuda',
        descricao: 'Entenda fontes, estados e histórico',
        aoTocar: aoAbrirAjuda,
      ),
      _item(
        context,
        chave: 'perfil-problema',
        icone: Icons.flag_outlined,
        titulo: 'Reportar problema',
        descricao: 'Envie contexto sem incluir senha',
        aoTocar: aoAbrirProblema,
      ),
      _item(
        context,
        chave: 'perfil-privacidade',
        icone: Icons.shield_outlined,
        titulo: 'Privacidade',
        descricao: 'Acompanhamento, retenção e direitos',
        aoTocar: aoAbrirPrivacidade,
      ),
    ];
    if (aoAdministrar != null) {
      itens.add(
        _item(
          context,
          chave: 'perfil-administracao',
          icone: Icons.settings_outlined,
          titulo: 'Administração',
          descricao: 'Zona de perigo protegida',
          aoTocar: aoAdministrar!,
        ),
      );
    }
    if (kDebugMode && aoAbrirLaboratorio != null) {
      itens.add(
        _item(
          context,
          chave: 'perfil-laboratorio',
          icone: Icons.science_outlined,
          titulo: 'Laboratório QA',
          descricao: 'Revisar estados e rotas em ambiente local',
          aoTocar: aoAbrirLaboratorio!,
        ),
      );
    }
    return Column(
      children: [
        for (var indice = 0; indice < itens.length; indice++) ...[
          itens[indice],
          if (indice < itens.length - 1)
            SizedBox(height: context.tokens.spacing.three),
        ],
      ],
    );
  }

  Widget _item(
    BuildContext context, {
    required String chave,
    required IconData icone,
    required String titulo,
    required String descricao,
    required VoidCallback aoTocar,
  }) => CartaoRadar(
    key: Key(chave),
    aoTocar: aoTocar,
    padding: EdgeInsets.all(context.tokens.spacing.four),
    child: LinhaContaRadar(icone: icone, titulo: titulo, descricao: descricao),
  );
}
