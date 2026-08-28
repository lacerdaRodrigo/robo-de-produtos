import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';
import '../../core/autenticacao/autenticador.dart';
import '../componentes/estados.dart';
import '../navegacao/moldura.dart';
import 'pagina_entrar.dart';

typedef ConstrutorValidacaoAcesso = Widget Function(BuildContext context);

class PortaoAutenticacao extends StatelessWidget {
  const PortaoAutenticacao({
    super.key,
    required this.autenticador,
    required this.api,
    this.construirValidacao,
  });

  final Autenticador autenticador;
  final Api api;
  final ConstrutorValidacaoAcesso? construirValidacao;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ContaAutenticada?>(
      stream: autenticador.mudancas,
      initialData: autenticador.contaAtual,
      builder: (context, estado) {
        final conta = estado.data;
        if (conta == null) return PaginaEntrar(autenticador: autenticador);
        return _ValidacaoDoConvite(
          key: ValueKey(conta.id),
          api: api,
          autenticador: autenticador,
          construirValidacao: construirValidacao,
        );
      },
    );
  }
}

class _ValidacaoDoConvite extends StatefulWidget {
  const _ValidacaoDoConvite({
    super.key,
    required this.api,
    required this.autenticador,
    this.construirValidacao,
  });

  final Api api;
  final Autenticador autenticador;
  final ConstrutorValidacaoAcesso? construirValidacao;

  @override
  State<_ValidacaoDoConvite> createState() => _EstadoValidacaoDoConvite();
}

class _EstadoValidacaoDoConvite extends State<_ValidacaoDoConvite> {
  late Future<PerfilUsuario> _perfil;

  @override
  void initState() {
    super.initState();
    _perfil = widget.api.perfil();
  }

  void _tentarNovamente() => setState(() => _perfil = widget.api.perfil());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PerfilUsuario>(
      future: _perfil,
      builder: (context, estado) {
        if (estado.connectionState != ConnectionState.done) {
          final construirValidacao = widget.construirValidacao;
          if (construirValidacao != null) {
            return construirValidacao(context);
          }
          return const Scaffold(
            body: Carregando(mensagem: 'Validando acesso ao piloto…'),
          );
        }
        if (estado.hasData) {
          return MolduraRadar(
            api: widget.api,
            administrador: estado.data!.administrador,
            identificacaoConta: estado.data!.email,
            aoSair: widget.autenticador.sair,
          );
        }

        final erro = estado.error;
        final acessoNegado = erro is ErroDeApi && erro.status == 403;
        return Scaffold(
          body: EstadoFalha(
            mensagem: acessoNegado
                ? 'Este usuário não está autorizado para o piloto.'
                : 'Não foi possível validar seu acesso agora.',
            voltar: acessoNegado ? null : _tentarNovamente,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton.icon(
                onPressed: widget.autenticador.sair,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ),
          ),
        );
      },
    );
  }
}
