import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/versao_app.dart';

class PaginaAjuda extends StatelessWidget {
  const PaginaAjuda({super.key, required this.api});
  final Api api;

  @override
  Widget build(BuildContext context) => _PaginaContaBase(
    titulo: 'Ajuda',
    sobrelinha: 'Suporte',
    descricao:
        'Entenda os estados do Radar e encontre o canal certo para pedir suporte.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BlocoAjuda(
          titulo: 'Como a Central funciona?',
          texto:
              'Ela compara snapshots completos e válidos dos itens que você acompanha. O primeiro snapshot não gera evento; ausência e falha nunca viram zero.',
        ),
        _BlocoAjuda(
          titulo: 'O que significa parcial ou atrasado?',
          texto:
              'O último retrato válido continua visível e recebe um aviso contextual até uma coleta completa substituir o estado.',
        ),
        _BlocoAjuda(
          titulo: 'Busca, filtros e páginas fazem uma nova coleta?',
          texto:
              'Não. Eles consultam o catálogo salvo pela API e preservam a posição útil da tela.',
        ),
        _BlocoAjuda(
          titulo: 'Precisa falar com alguém?',
          texto:
              'Use Reportar problema no perfil ou escreva para lacerdaa.rodrigo@gmail.com.',
        ),
      ],
    ),
  );
}

class PaginaPrivacidade extends StatelessWidget {
  const PaginaPrivacidade({super.key, required this.api});
  final Api api;

  @override
  Widget build(BuildContext context) => _PaginaContaBase(
    titulo: 'Privacidade',
    sobrelinha: 'Transparência',
    descricao: 'Quais dados o Radar usa, por quê e por quanto tempo.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _BlocoTexto(
          titulo: 'Dados e finalidade',
          texto:
              'Firebase usa identificador técnico, e-mail e sessão para autenticação. Preferências, acompanhamentos e eventos sustentam a Central. O token FCM permite notificações quando você autoriza.',
        ),
        _BlocoTexto(
          titulo: 'Retenção e segurança',
          texto:
              'Alertas permanecem por 90 dias e relatos de problema por 180 dias. A API aplica autenticação, isolamento por conta, limites e não grava tokens ou dados pessoais em logs.',
        ),
        _BlocoTexto(
          titulo: 'Seus direitos',
          texto:
              'Não há exclusão automática nesta versão. Solicitações formais, acesso, correção ou eliminação devem usar lacerdaa.rodrigo@gmail.com. Terceiros: Firebase e o provedor de notificações.',
        ),
      ],
    ),
  );
}

class PaginaRelatoProblema extends StatefulWidget {
  const PaginaRelatoProblema({super.key, required this.api});
  final Api api;

  @override
  State<PaginaRelatoProblema> createState() => _EstadoPaginaRelatoProblema();
}

class _EstadoPaginaRelatoProblema extends State<PaginaRelatoProblema> {
  final _mensagem = TextEditingController();
  String _categoria = 'erro';
  var _enviando = false;
  String? _versao;

  @override
  void initState() {
    super.initState();
    VersaoApp.versao().then((valor) {
      if (mounted) setState(() => _versao = valor);
    });
  }

  @override
  void dispose() {
    _mensagem.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final mensagem = _mensagem.text.trim();
    if (mensagem.isEmpty || mensagem.length > 2000) {
      mostrarMensagemRadar(
        context,
        'Descreva o problema em até 2.000 caracteres.',
        sucesso: false,
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      await widget.api.relatarProblema(
        categoria: _categoria,
        mensagem: mensagem,
        tela: 'relato-problema',
        versaoApp: _versao ?? 'indisponivel',
      );
      if (mounted) {
        _mensagem.clear();
        mostrarMensagemRadar(context, 'Relato registrado. Obrigado.');
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagemRadar(
          context,
          'Não foi possível registrar o relato agora.',
          sucesso: false,
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) => _PaginaContaBase(
    titulo: 'Reportar problema',
    sobrelinha: 'Suporte',
    descricao: 'O relato é autenticado e sem dados sensíveis.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _categoria,
          decoration: const InputDecoration(labelText: 'Categoria'),
          items: const [
            DropdownMenuItem(
              value: 'erro',
              child: Text('Erro ou tela travada'),
            ),
            DropdownMenuItem(
              value: 'dados',
              child: Text('Dados desatualizados'),
            ),
            DropdownMenuItem(value: 'conta', child: Text('Conta e acesso')),
            DropdownMenuItem(value: 'outro', child: Text('Outro')),
          ],
          onChanged: (valor) {
            if (valor != null) setState(() => _categoria = valor);
          },
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _mensagem,
          maxLength: 2000,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Mensagem',
            alignLabelWithHint: true,
            hintText: 'Descreva o que aconteceu',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A versão do app é preenchida automaticamente. Não envie senha, token, dados bancários ou catálogo completo.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
          ),
        ),
        const SizedBox(height: 17),
        FilledButton(
          onPressed: _enviando ? null : _enviar,
          child: Text(_enviando ? 'Enviando…' : 'Enviar relato'),
        ),
      ],
    ),
  );
}

class _PaginaContaBase extends StatelessWidget {
  const _PaginaContaBase({
    required this.titulo,
    required this.sobrelinha,
    required this.descricao,
    required this.child,
  });
  final String titulo;
  final String sobrelinha;
  final String descricao;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: 'Voltar',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(titulo),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
      children: [
        CabecalhoSecaoRadar(
          sobrelinha: sobrelinha,
          titulo: titulo,
          descricao: descricao,
        ),
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}

class _BlocoAjuda extends StatelessWidget {
  const _BlocoAjuda({required this.titulo, required this.texto});
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => CartaoRadar(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _BlocoTexto extends StatelessWidget {
  const _BlocoTexto({required this.titulo, required this.texto});
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 19),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 7),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CoresRadar.de(context).textoSuave,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
