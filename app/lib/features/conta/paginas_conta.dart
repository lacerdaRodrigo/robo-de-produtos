import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/componentes/estados.dart';
import '../../app/componentes/fundacao_visual.dart';
import '../../app/navegacao/destinos.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../../core/api/pagina.dart';
import '../../core/versao_app.dart';

class PaginaAjuda extends StatelessWidget {
  const PaginaAjuda({
    super.key,
    required this.api,
    this.destinoSelecionado = DestinoCompacto.perfil,
    this.aoNavegar,
  });

  final Api api;
  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _PaginaContaBase(
      titulo: 'Ajuda',
      tituloConteudo: 'Pode perguntar.',
      descricao: 'Respostas para comprar com mais contexto.',
      destinoSelecionado: destinoSelecionado,
      aoNavegar: aoNavegar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PerguntaAjuda(
            chave: 'ajuda-pergunta-origens',
            titulo: 'O que o Radar acompanha?',
            texto:
                'Lojas parceiras da Livelo, cashback de lojas do Inter, produtos do Inter e PCs gamer da Pichau. Cada origem mantém seu catálogo e seu horário de atualização.',
          ),
          const _PerguntaAjuda(
            chave: 'ajuda-pergunta-preco',
            titulo: 'Por que o preço pode mudar no destino?',
            texto:
                'O aplicativo mostra o último valor recebido pela API. A loja pode alterar preço ou disponibilidade depois da atualização; confira as condições no destino antes de comprar.',
          ),
          const _PerguntaAjuda(
            chave: 'ajuda-pergunta-livelo',
            titulo: 'A Livelo também tem produtos?',
            texto:
                'Neste aplicativo, a Livelo reúne lojas parceiras e pontos por real gasto. Produtos do Inter e PCs gamer são consultados nas áreas próprias.',
          ),
          const _PerguntaAjuda(
            chave: 'ajuda-pergunta-alertas',
            titulo: 'Acompanhar garante uma notificação?',
            texto:
                'Mudanças válidas ficam na Central depois de uma coleta completa. Avisos no aparelho também dependem das preferências e da permissão de notificações do sistema.',
          ),
          const _PerguntaAjuda(
            chave: 'ajuda-pergunta-cashback',
            titulo: 'O que significa “até” no cashback?',
            texto:
                'É o limite informado pela origem. Produtos, vendedores e condições podem ter percentuais diferentes; consulte as condições completas da oferta.',
          ),
          const _PerguntaAjuda(
            chave: 'ajuda-pergunta-busca',
            titulo: 'Buscar atualiza a loja em tempo real?',
            texto:
                'Não. A busca consulta o catálogo disponível pela API. As atualizações seguem a programação de cada origem e digitar uma busca não inicia uma coleta.',
          ),
          SizedBox(height: tokens.spacing.five),
          SizedBox(
            height: tokens.sizes.touchTarget,
            child: FilledButton(
              key: const Key('ajuda-abrir-relato'),
              onPressed: () => _abrirRelato(
                context,
                api,
                destinoSelecionado: destinoSelecionado,
                aoNavegar: aoNavegar,
              ),
              child: const Text('Ainda preciso de ajuda'),
            ),
          ),
        ],
      ),
    );
  }
}

class PaginaPrivacidade extends StatelessWidget {
  const PaginaPrivacidade({
    super.key,
    required this.api,
    this.destinoSelecionado = DestinoCompacto.perfil,
    this.aoNavegar,
  });

  final Api api;
  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _PaginaContaBase(
      titulo: 'Privacidade',
      tituloConteudo: 'Você no controle.',
      descricao: 'Dados usados pelo Radar e seus prazos de retenção.',
      destinoSelecionado: destinoSelecionado,
      aoNavegar: aoNavegar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _BlocoTexto(
            titulo: 'O que fica associado à conta',
            texto:
                'A sessão autenticada usa identificador técnico e e-mail para acesso. Preferências, acompanhamentos e eventos ficam associados à conta para manter as funções do Radar e da Central.',
          ),
          const _BlocoTexto(
            titulo: 'Histórico e suporte',
            texto:
                'Alertas são retidos por até 90 dias e relatos de problema por 180 dias. A API autentica as operações e separa os registros por conta.',
          ),
          const _BlocoTexto(
            titulo: 'Notificações',
            texto:
                'A permissão do aparelho é opcional. Recusar não bloqueia os catálogos nem o histórico da Central. Ao sair da conta, o token de notificação deste aparelho é removido.',
          ),
          const _BlocoTexto(
            titulo: 'Seus direitos',
            texto:
                'Esta versão não oferece exclusão automática da conta. Para solicitar acesso, correção ou eliminação de dados, relate uma dúvida de privacidade pelo suporte. Os serviços de autenticação e notificações usam Firebase.',
          ),
          SizedBox(height: tokens.spacing.two),
          SizedBox(
            height: tokens.sizes.touchTarget,
            child: OutlinedButton(
              key: const Key('privacidade-abrir-relato'),
              onPressed: () => _abrirRelato(
                context,
                api,
                destinoSelecionado: destinoSelecionado,
                aoNavegar: aoNavegar,
              ),
              child: const Text('Relatar uma dúvida de privacidade'),
            ),
          ),
        ],
      ),
    );
  }
}

class PaginaRelatoProblema extends StatefulWidget {
  const PaginaRelatoProblema({
    super.key,
    required this.api,
    this.destinoSelecionado = DestinoCompacto.perfil,
    this.aoNavegar,
    this.retornarRecibo = false,
  });

  final Api api;
  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;
  final bool retornarRecibo;

  @override
  State<PaginaRelatoProblema> createState() => _EstadoPaginaRelatoProblema();
}

class _EstadoPaginaRelatoProblema extends State<PaginaRelatoProblema> {
  final _mensagem = TextEditingController();
  String _categoria = 'catalog';
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
    if (mensagem.length < 10 || mensagem.length > 2000) {
      mostrarMensagemRadar(
        context,
        'Descreva o problema usando de 10 a 2.000 caracteres.',
        sucesso: false,
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      final id = await widget.api.relatarProblema(
        categoria: _categoria,
        mensagem: mensagem,
        tela: 'relato-problema',
        versaoApp: _versao ?? 'indisponivel',
      );
      if (mounted) {
        _mensagem.clear();
        final relato = RelatoProblema(
          id: id,
          categoria: _categoria,
          mensagem: mensagem,
          criadoEm: '',
        );
        if (widget.retornarRecibo) {
          Navigator.of(context).pop(relato);
        } else {
          mostrarMensagemRadar(
            context,
            'Relato registrado. Protocolo disponível.',
          );
          await Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute<void>(
              builder: (_) => PaginaMeusRelatos(
                api: widget.api,
                destinoSelecionado: widget.destinoSelecionado,
                aoNavegar: widget.aoNavegar,
                relatoRecemCriado: relato,
              ),
            ),
          );
        }
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
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return _PaginaContaBase(
      titulo: 'Relatar problema',
      tituloConteudo: 'O que aconteceu?',
      descricao: 'Conte o problema e onde você o encontrou.',
      destinoSelecionado: widget.destinoSelecionado,
      aoNavegar: widget.aoNavegar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            key: const Key('categoria-relato'),
            initialValue: _categoria,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Assunto'),
            items: const [
              DropdownMenuItem(
                value: 'catalog',
                child: Text('Dados do catálogo'),
              ),
              DropdownMenuItem(value: 'access', child: Text('Acesso à conta')),
              DropdownMenuItem(
                value: 'notification',
                child: Text('Notificações'),
              ),
              DropdownMenuItem(value: 'privacy', child: Text('Privacidade')),
              DropdownMenuItem(value: 'other', child: Text('Outro')),
            ],
            onChanged: (valor) {
              if (valor != null) setState(() => _categoria = valor);
            },
          ),
          SizedBox(height: tokens.spacing.three),
          TextField(
            key: const Key('descricao-relato'),
            controller: _mensagem,
            maxLength: 2000,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              alignLabelWithHint: true,
              hintText: 'Descreva o que você esperava e o que aconteceu…',
            ),
          ),
          SizedBox(height: tokens.spacing.one),
          Text(
            'De 10 a 2.000 caracteres. Não inclua dados sensíveis.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
            ),
          ),
          SizedBox(height: tokens.spacing.five),
          SizedBox(
            height: tokens.sizes.touchTarget,
            child: FilledButton(
              key: const Key('enviar-relato'),
              onPressed: _enviando ? null : _enviar,
              child: Text(_enviando ? 'Salvando…' : 'Registrar relato'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginaContaBase extends StatelessWidget {
  const _PaginaContaBase({
    required this.titulo,
    this.tituloConteudo,
    required this.descricao,
    required this.child,
    required this.destinoSelecionado,
    this.aoNavegar,
  });
  final String titulo;
  final String? tituloConteudo;
  final String descricao;
  final Widget child;
  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final compacto = MediaQuery.sizeOf(context).width < 920;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('voltar-pagina-conta'),
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(titulo),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            tokens.spacing.four,
            tokens.spacing.five,
            tokens.spacing.four,
            tokens.spacing.nine,
          ),
          children: [
            CabecalhoSecaoRadar(
              titulo: tituloConteudo ?? titulo,
              descricao: descricao,
            ),
            SizedBox(height: tokens.spacing.six),
            child,
          ],
        ),
      ),
      bottomNavigationBar: compacto && aoNavegar != null
          ? BarraInferiorRadar(
              selecionado: destinoSelecionado.destinoDaBarra,
              aoSelecionar: aoNavegar!,
            )
          : null,
    );
  }
}

class PaginaMeusRelatos extends StatefulWidget {
  const PaginaMeusRelatos({
    super.key,
    required this.api,
    this.destinoSelecionado = DestinoCompacto.perfil,
    this.aoNavegar,
    this.relatoRecemCriado,
  });

  final Api api;
  final DestinoCompacto destinoSelecionado;
  final ValueChanged<DestinoCompacto>? aoNavegar;
  final RelatoProblema? relatoRecemCriado;

  @override
  State<PaginaMeusRelatos> createState() => _EstadoPaginaMeusRelatos();
}

class _EstadoPaginaMeusRelatos extends State<PaginaMeusRelatos> {
  static const _porPagina = 20;
  Pagina<RelatoProblema>? _pagina;
  var _carregando = true;
  var _erro = false;
  final List<RelatoProblema> _relatosRecemCriados = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar([int pagina = 1]) async {
    if (!_carregando && mounted) {
      setState(() {
        _carregando = true;
        _erro = false;
      });
    }
    try {
      final resposta = await widget.api.meusRelatos(
        pagina: pagina,
        porPagina: _porPagina,
      );
      if (mounted) {
        setState(() {
          _pagina = resposta;
          _erro = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _novoRelato() async {
    final relato = await _abrirRelato(
      context,
      widget.api,
      destinoSelecionado: widget.destinoSelecionado,
      aoNavegar: widget.aoNavegar,
      retornarRecibo: true,
    );
    if (!mounted) return;
    if (relato != null) {
      setState(() => _relatosRecemCriados.insert(0, relato));
    }
    await _carregar();
  }

  Future<void> _copiarProtocolo(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (mounted) mostrarMensagemRadar(context, 'Protocolo copiado.');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final pagina = _pagina;
    final recebidos = pagina == null || pagina.pagina == 1
        ? <RelatoProblema>[
            if (widget.relatoRecemCriado != null) widget.relatoRecemCriado!,
            ..._relatosRecemCriados,
          ]
        : const <RelatoProblema>[];
    final idsDaPagina =
        pagina?.itens.map((relato) => relato.id).toSet() ?? const <String>{};
    final relatosVisiveis = <RelatoProblema>[
      for (final relato in recebidos)
        if (!idsDaPagina.contains(relato.id)) relato,
      ...?pagina?.itens,
    ];
    final corpo = _carregando && pagina == null && relatosVisiveis.isEmpty
        ? const Carregando(mensagem: 'Carregando relatos…')
        : _erro && pagina == null && relatosVisiveis.isEmpty
        ? EstadoFalha(
            mensagem: 'Não foi possível carregar seus relatos agora.',
            voltar: _carregar,
          )
        : relatosVisiveis.isEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EstadoVazio(
                mensagem:
                    'Nenhum relato por aqui. Os relatos enviados por esta conta aparecem nesta tela.',
              ),
              SizedBox(height: tokens.spacing.three),
              FilledButton(
                key: const Key('novo-relato-vazio'),
                onPressed: _novoRelato,
                child: const Text('Novo relato'),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_erro && pagina == null) ...[
                EstadoFalha(
                  mensagem: 'Não foi possível carregar seus relatos agora.',
                  voltar: _carregar,
                ),
                SizedBox(height: tokens.spacing.three),
              ],
              for (final relato in relatosVisiveis) ...[
                _CartaoRelato(
                  relato: relato,
                  aoCopiar: () => _copiarProtocolo(relato.id),
                ),
                SizedBox(height: tokens.spacing.three),
              ],
              if (_erro && pagina != null) ...[
                EstadoFalha(
                  mensagem: 'Não foi possível carregar esta página agora.',
                  voltar: () => _carregar(pagina.pagina),
                ),
                SizedBox(height: tokens.spacing.three),
              ],
              if (_carregando)
                const LinearProgressIndicator(
                  key: Key('carregando-relatos-pagina'),
                ),
              if (pagina != null)
                PaginacaoRadar(
                  pagina: pagina.pagina,
                  totalItens: pagina.totalItens,
                  porPagina: pagina.porPagina,
                  carregando: _carregando,
                  erro: _erro ? StateError('falha ao carregar') : null,
                  aoIrParaPagina: (valor) => _carregar(valor),
                ),
              FilledButton(
                key: const Key('novo-relato'),
                onPressed: _novoRelato,
                child: const Text('Novo relato'),
              ),
            ],
          );

    return _PaginaContaBase(
      titulo: 'Meus relatos',
      tituloConteudo: 'Seu retorno importa.',
      descricao: 'Acompanhe os protocolos enviados por esta conta.',
      destinoSelecionado: widget.destinoSelecionado,
      aoNavegar: widget.aoNavegar,
      child: corpo,
    );
  }
}

class _CartaoRelato extends StatelessWidget {
  const _CartaoRelato({required this.relato, required this.aoCopiar});

  final RelatoProblema relato;
  final VoidCallback aoCopiar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final cores = CoresRadar.de(context);
    return CartaoRadar(
      key: Key('cartao-relato-${relato.id}'),
      comSombra: false,
      padding: EdgeInsets.all(tokens.spacing.four),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Registro confirmado',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cores.ganho,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spacing.two),
          SelectableText(
            relato.id,
            key: Key('protocolo-relato-${relato.id}'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (relato.criadoEm.isNotEmpty) ...[
            SizedBox(height: tokens.spacing.one),
            Text(
              _dataRelato(context, relato.criadoEm),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cores.textoSuave),
            ),
          ],
          SizedBox(height: tokens.spacing.three),
          SelectableText(relato.mensagem),
          SizedBox(height: tokens.spacing.three),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              key: Key('copiar-relato-${relato.id}'),
              onPressed: aoCopiar,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar protocolo'),
            ),
          ),
        ],
      ),
    );
  }
}

String _dataRelato(BuildContext context, String valor) {
  final data = DateTime.tryParse(valor)?.toLocal();
  if (data == null) return valor;
  final localizacoes = MaterialLocalizations.of(context);
  final dataFormatada = localizacoes.formatMediumDate(data);
  final horaFormatada = localizacoes.formatTimeOfDay(
    TimeOfDay.fromDateTime(data),
  );
  return '$dataFormatada · $horaFormatada';
}

class _PerguntaAjuda extends StatelessWidget {
  const _PerguntaAjuda({
    required this.chave,
    required this.titulo,
    required this.texto,
  });

  final String chave;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: Key(chave),
    tilePadding: EdgeInsetsDirectional.symmetric(
      horizontal: context.tokens.spacing.four,
    ),
    childrenPadding: EdgeInsetsDirectional.fromSTEB(
      context.tokens.spacing.four,
      0,
      context.tokens.spacing.four,
      context.tokens.spacing.four,
    ),
    shape: Border(bottom: BorderSide(color: CoresRadar.de(context).borda)),
    collapsedShape: Border(
      bottom: BorderSide(color: CoresRadar.de(context).borda),
    ),
    title: Text(
      titulo,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          texto,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CoresRadar.de(context).textoSuave,
            height: 1.65,
          ),
        ),
      ),
    ],
  );
}

class _BlocoTexto extends StatelessWidget {
  const _BlocoTexto({required this.titulo, required this.texto});
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(bottom: context.tokens.spacing.five),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        SizedBox(height: context.tokens.spacing.two),
        Text(
          texto,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: CoresRadar.de(context).textoSuave,
            height: 1.75,
          ),
        ),
      ],
    ),
  );
}

Future<RelatoProblema?> _abrirRelato(
  BuildContext context,
  Api api, {
  required DestinoCompacto destinoSelecionado,
  ValueChanged<DestinoCompacto>? aoNavegar,
  bool retornarRecibo = false,
}) => Navigator.of(context).push<RelatoProblema>(
  MaterialPageRoute<RelatoProblema>(
    builder: (_) => PaginaRelatoProblema(
      api: api,
      destinoSelecionado: destinoSelecionado,
      aoNavegar: aoNavegar,
      retornarRecibo: retornarRecibo,
    ),
  ),
);
