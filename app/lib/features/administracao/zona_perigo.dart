import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';

const _frases = <String, String>{
  'livelo': 'APAGAR LIVELO',
  'inter': 'RESETAR INTER',
};

const _rotulos = <String, String>{
  'lojas': 'Lojas',
  'apelidos': 'Apelidos',
  'execucoes': 'Execuções',
  'pontuacoes': 'Pontuações',
  'disparos': 'Disparos manuais',
  'lojasParceiras': 'Lojas parceiras',
  'favoritas': 'Favoritas',
  'execucoesParceiras': 'Execuções de parceiros',
  'cashbacks': 'Snapshots de cashback',
  'vendedoresDiretos': 'Vendedores diretos',
  'selecionadas': 'Vendedores selecionados',
  'produtos': 'Produtos',
  'ofertasAtuais': 'Ofertas atuais',
  'medicoes': 'Medições de produtos',
  'execucoesProdutos': 'Execuções de produtos',
};

class ZonaPerigoAdministrativa extends StatelessWidget {
  const ZonaPerigoAdministrativa({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) {
    final corErro = CoresRadar.de(context).perigo;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Semantics(
          header: true,
          child: Text(
            'Zona de perigo',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: corErro),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Estas ações apagam dados definitivamente. Cada domínio possui uma '
          'prévia e uma página de confirmação separada.',
        ),
        const SizedBox(height: 16),
        _CartaoDominio(
          titulo: 'Apagar dados da Livelo',
          descricao:
              'Remove lojas, apelidos, regras, execuções, pontuações e disparos manuais da Livelo.',
          aoAbrir: () => _abrir(context, 'livelo'),
        ),
        _CartaoDominio(
          titulo: 'Resetar dados do Inter',
          descricao:
              'Remove Sites parceiros, Compre direto, seleções, produtos e histórico do Inter.',
          aoAbrir: () => _abrir(context, 'inter'),
        ),
      ],
    );
  }

  void _abrir(BuildContext context, String dominio) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaginaConfirmacaoLimpeza(api: api, dominio: dominio),
      ),
    );
  }
}

class _CartaoDominio extends StatelessWidget {
  const _CartaoDominio({
    required this.titulo,
    required this.descricao,
    required this.aoAbrir,
  });

  final String titulo;
  final String descricao;
  final VoidCallback aoAbrir;

  @override
  Widget build(BuildContext context) {
    final corErro = CoresRadar.de(context).perigo;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: corErro,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(descricao),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: aoAbrir,
                style: OutlinedButton.styleFrom(foregroundColor: corErro),
                child: const Text('Ver detalhes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaginaConfirmacaoLimpeza extends StatefulWidget {
  const PaginaConfirmacaoLimpeza({
    super.key,
    required this.api,
    required this.dominio,
  }) : assert(dominio == 'livelo' || dominio == 'inter');

  final Api api;
  final String dominio;

  @override
  State<PaginaConfirmacaoLimpeza> createState() =>
      _EstadoPaginaConfirmacaoLimpeza();
}

class _EstadoPaginaConfirmacaoLimpeza extends State<PaginaConfirmacaoLimpeza> {
  final TextEditingController _frase = TextEditingController();
  ResumoLimpezaAdministrativa? _resumo;
  Object? _erro;
  bool _carregando = true;
  bool _executando = false;
  bool _concluida = false;

  String get _fraseEsperada => _frases[widget.dominio]!;
  bool get _confirmacaoValida => _frase.text.trim() == _fraseEsperada;
  bool get _livelo => widget.dominio == 'livelo';

  @override
  void initState() {
    super.initState();
    _frase.addListener(_atualizarConfirmacao);
    _carregar();
  }

  @override
  void dispose() {
    _frase
      ..removeListener(_atualizarConfirmacao)
      ..dispose();
    super.dispose();
  }

  void _atualizarConfirmacao() => setState(() {});

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resumo = await widget.api.resumoLimpeza(widget.dominio);
      if (resumo.dominio != widget.dominio ||
          resumo.fraseConfirmacao != _fraseEsperada) {
        throw ErroDeRede('contrato de confirmação inválido');
      }
      if (mounted) setState(() => _resumo = resumo);
    } catch (erro) {
      if (mounted) setState(() => _erro = erro);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _executar() async {
    if (!_confirmacaoValida || _executando) return;
    setState(() => _executando = true);
    try {
      await widget.api.executarLimpeza(
        dominio: widget.dominio,
        frase: _frase.text,
      );
      if (mounted) setState(() => _concluida = true);
    } catch (erro) {
      if (!mounted) return;
      final mensagem = erro is ErroDeApi
          ? erro.mensagem
          : 'Não foi possível concluir. Nenhum dado foi alterado.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensagem)));
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = _livelo
        ? 'Apagar dados da Livelo?'
        : 'Resetar dados do Inter?';
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: _concluida
          ? _SucessoLimpeza(livelo: _livelo)
          : _carregando
          ? const Carregando(mensagem: 'Consultando o que será removido…')
          : _erro != null
          ? EstadoFalha(
              mensagem: 'Não foi possível consultar as contagens.',
              voltar: _carregar,
            )
          : _conteudo(context),
    );
  }

  Widget _conteudo(BuildContext context) {
    final resumo = _resumo!;
    final corErro = CoresRadar.de(context).perigo;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _livelo
              ? 'Esta ação remove somente os dados da Livelo.'
              : 'Esta ação remove Sites parceiros e Compre direto do Inter.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'A ação é definitiva, não possui backup no aplicativo e não encerra '
          'seu login. Os workflows continuam agendados.',
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            'Prévia do que será removido',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        for (final entrada in resumo.contagens.entries)
          ListTile(
            dense: true,
            title: Text(_rotulos[entrada.key] ?? entrada.key),
            trailing: Text('${entrada.value}'),
          ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(
            text: 'Digite exatamente ',
            children: [
              TextSpan(
                text: _fraseEsperada,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' para continuar.'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('frase-limpeza'),
          controller: _frase,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(
            labelText: 'Frase de confirmação',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('confirmar-limpeza'),
          onPressed: _confirmacaoValida && !_executando ? _executar : null,
          style: FilledButton.styleFrom(
            backgroundColor: corErro,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          icon: _executando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: Text(
            _livelo ? 'Apagar definitivamente' : 'Resetar definitivamente',
          ),
        ),
      ],
    );
  }
}

class _SucessoLimpeza extends StatelessWidget {
  const _SucessoLimpeza({required this.livelo});

  final bool livelo;

  @override
  Widget build(BuildContext context) {
    final ganho = CoresRadar.de(context).ganho;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: ganho),
            const SizedBox(height: 12),
            Text(
              livelo
                  ? 'Os dados da Livelo foram apagados.'
                  : 'Os dados do Inter foram resetados.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar à administração'),
            ),
          ],
        ),
      ),
    );
  }
}
