import 'package:flutter/material.dart';

import '../../app/componentes/estados.dart';
import '../../core/api/api_v1.dart';
import '../../core/api/erros.dart';
import '../../core/api/modelos.dart';
import 'controlador_catalogo_administracao.dart';
import 'zona_perigo.dart';

/// Administração segura da Fase 5.1.
///
/// Ela não aceita URL e não expõe a limpeza total enquanto o aceite destrutivo
/// em banco descartável continuar pendente.
class PaginaAdministracao extends StatefulWidget {
  const PaginaAdministracao({
    super.key,
    required this.api,
    this.administrador = true,
    this.incorporada = false,
  });

  final ApiV1 api;
  final bool administrador;
  final bool incorporada;

  @override
  State<PaginaAdministracao> createState() => _EstadoPaginaAdministracao();
}

class _EstadoPaginaAdministracao extends State<PaginaAdministracao> {
  late final ControladorCatalogoAdministracao<LojaCatalogoInter>
  _catalogoParceiros = ControladorCatalogoAdministracao<LojaCatalogoInter>(
    buscar: ({required q, required pagina}) =>
        widget.api.lojasInter(q: q, pagina: pagina),
    identificar: (loja) => loja.id,
  );
  late final ControladorCatalogoAdministracao<LojaDireto> _catalogoDiretas =
      ControladorCatalogoAdministracao<LojaDireto>(
        buscar: ({required q, required pagina}) =>
            widget.api.lojasDiretas(q: q, pagina: pagina),
        identificar: (loja) => loja.id,
      );
  final Set<String> _alterando = <String>{};

  @override
  void initState() {
    super.initState();
    if (!widget.administrador) return;
    _catalogoParceiros.carregarPrimeira();
    _catalogoDiretas.carregarPrimeira();
  }

  @override
  void dispose() {
    _catalogoParceiros.dispose();
    _catalogoDiretas.dispose();
    super.dispose();
  }

  Future<void> _alterarFavorita(LojaCatalogoInter loja, bool favorita) async {
    if (_alterando.contains(loja.id)) return;
    setState(() => _alterando.add(loja.id));
    try {
      await widget.api.alterarFavoritaInter(id: loja.id, favorita: favorita);
      _catalogoParceiros.substituir(
        loja.id,
        loja.copiarCom(favorita: favorita),
      );
    } catch (erro) {
      _mostrarErro(erro, 'Não foi possível alterar a favorita.');
    } finally {
      if (mounted) setState(() => _alterando.remove(loja.id));
    }
  }

  Future<void> _alterarSelecao(LojaDireto loja, bool selecionada) async {
    if (_alterando.contains(loja.id)) return;
    setState(() => _alterando.add(loja.id));
    try {
      await widget.api.alterarSelecaoLojaDireta(
        id: loja.id,
        selecionada: selecionada,
      );
      _catalogoDiretas.substituir(
        loja.id,
        loja.copiarCom(selecionada: selecionada),
      );
    } catch (erro) {
      _mostrarErro(erro, 'Não foi possível alterar a seleção.');
    } finally {
      if (mounted) setState(() => _alterando.remove(loja.id));
    }
  }

  void _mostrarErro(Object erro, String padrao) {
    if (!mounted) return;
    final mensagem = erro is ErroDeApi ? erro.mensagem : padrao;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.administrador) {
      const corpo = EstadoVazio(
        mensagem: 'Seu acesso não permite administrar catálogos.',
      );
      return widget.incorporada ? corpo : const Scaffold(body: corpo);
    }
    return DefaultTabController(
      length: 4,
      child: Builder(
        builder: (context) {
          const abas = TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Livelo'),
              Tab(text: 'Sites parceiros'),
              Tab(text: 'Compre direto'),
              Tab(text: 'Zona de perigo'),
            ],
          );
          final conteudo = TabBarView(
            children: [
              _AdministracaoLivelo(api: widget.api),
              _CatalogoParceiros(
                controlador: _catalogoParceiros,
                alterando: _alterando,
                aoAlterar: _alterarFavorita,
              ),
              _CatalogoDiretas(
                controlador: _catalogoDiretas,
                alterando: _alterando,
                aoAlterar: _alterarSelecao,
              ),
              ZonaPerigoAdministrativa(api: widget.api),
            ],
          );

          if (!widget.incorporada) {
            return Scaffold(
              appBar: AppBar(title: const Text('Administração'), bottom: abas),
              body: conteudo,
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  'Administração',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const Material(color: Colors.transparent, child: abas),
              Expanded(child: conteudo),
            ],
          );
        },
      ),
    );
  }
}

class _AdministracaoLivelo extends StatefulWidget {
  const _AdministracaoLivelo({required this.api});

  final ApiV1 api;

  @override
  State<_AdministracaoLivelo> createState() => _EstadoAdministracaoLivelo();
}

class _EstadoAdministracaoLivelo extends State<_AdministracaoLivelo> {
  late final ControladorCatalogoAdministracao<LojaLiveloAdministrativa>
  _catalogo = ControladorCatalogoAdministracao<LojaLiveloAdministrativa>(
    buscar: ({required q, required pagina}) =>
        widget.api.lojasLivelo(q: q, pagina: pagina),
    identificar: (loja) => loja.id,
  );
  PreferenciasLiveloAdministrativas? _preferencias;
  Object? _erroPreferencias;
  bool _carregandoPreferencias = true;
  final Set<String> _alterando = <String>{};

  @override
  void initState() {
    super.initState();
    _catalogo.carregarPrimeira();
    _carregarPreferencias();
  }

  @override
  void dispose() {
    _catalogo.dispose();
    super.dispose();
  }

  Future<void> _carregarPreferencias() async {
    setState(() {
      _carregandoPreferencias = true;
      _erroPreferencias = null;
    });
    try {
      final preferencias = await widget.api.preferenciasLivelo();
      if (mounted) setState(() => _preferencias = preferencias);
    } catch (erro) {
      if (mounted) setState(() => _erroPreferencias = erro);
    } finally {
      if (mounted) setState(() => _carregandoPreferencias = false);
    }
  }

  Future<void> _editarPreferencias() async {
    final atuais = _preferencias;
    if (atuais == null || _alterando.contains('preferencias')) return;
    final dados = await _dialogoPreferencias(context, atuais);
    if (dados == null || !mounted) return;
    setState(() => _alterando.add('preferencias'));
    try {
      final salvas = await widget.api.salvarPreferenciasLivelo(
        multiplicador: dados.multiplicador,
        piso: dados.piso,
        assinanteClube: dados.assinanteClube,
      );
      if (mounted) setState(() => _preferencias = salvas);
      _mostrarSucesso('Preferências Livelo salvas.');
    } catch (erro) {
      _mostrarErro(erro, 'Não foi possível salvar as preferências.');
    } finally {
      if (mounted) setState(() => _alterando.remove('preferencias'));
    }
  }

  Future<void> _adicionarLoja() async {
    if (_alterando.contains('nova-loja')) return;
    final dados = await _dialogoNovaLoja(context);
    if (dados == null || !mounted) return;
    setState(() => _alterando.add('nova-loja'));
    try {
      await widget.api.cadastrarLojaLivelo(
        nome: dados.nome,
        categoria: dados.categoria,
        apelidos: dados.apelidos,
        multiplicador: dados.multiplicador,
        piso: dados.piso,
      );
      await _catalogo.carregarPrimeira();
      _mostrarSucesso('Loja Livelo cadastrada.');
    } catch (erro) {
      _mostrarErro(erro, 'Não foi possível cadastrar a loja.');
    } finally {
      if (mounted) setState(() => _alterando.remove('nova-loja'));
    }
  }

  Future<void> _editarRegra(LojaLiveloAdministrativa loja) async {
    if (_alterando.contains(loja.id)) return;
    final dados = await _dialogoRegra(context, loja);
    if (dados == null || !mounted) return;
    setState(() => _alterando.add(loja.id));
    try {
      await widget.api.alterarRegraLojaLivelo(
        id: loja.id,
        multiplicador: dados.multiplicador,
        piso: dados.piso,
      );
      _catalogo.substituir(
        loja.id,
        loja.comRegra(multiplicador: dados.multiplicador, piso: dados.piso),
      );
      _mostrarSucesso('Regra da loja salva.');
    } catch (erro) {
      _mostrarErro(erro, 'Não foi possível salvar a regra.');
    } finally {
      if (mounted) setState(() => _alterando.remove(loja.id));
    }
  }

  Future<void> _removerLoja(LojaLiveloAdministrativa loja) async {
    if (_alterando.contains(loja.id)) return;
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover loja Livelo?'),
        content: Text(
          'A loja “${loja.nome}” e seus apelidos serão removidos. '
          'Essa ação não executa o robô.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover loja'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _alterando.add(loja.id));
    try {
      await widget.api.removerLojaLivelo(loja.id);
      _catalogo.remover(loja.id);
      _mostrarSucesso('Loja Livelo removida.');
    } catch (erro) {
      _mostrarErro(erro, 'Não foi possível remover a loja.');
    } finally {
      if (mounted) setState(() => _alterando.remove(loja.id));
    }
  }

  void _mostrarErro(Object erro, String padrao) {
    if (!mounted) return;
    final mensagem = erro is ErroDeApi ? erro.mensagem : padrao;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  void _mostrarSucesso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _catalogo,
      builder: (context, _) => _EstruturaCatalogo(
        chaveBusca: const Key('busca-lojas-livelo'),
        rotuloBusca: 'Buscar loja Livelo',
        controlador: _catalogo,
        cabecalho: _CabecalhoLivelo(
          preferencias: _preferencias,
          erro: _erroPreferencias,
          carregando: _carregandoPreferencias,
          salvando: _alterando.contains('preferencias'),
          adicionando: _alterando.contains('nova-loja'),
          aoTentarPreferencias: _carregarPreferencias,
          aoEditarPreferencias: _editarPreferencias,
          aoAdicionarLoja: _adicionarLoja,
        ),
        item: (loja) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                title: Text(loja.nome),
                subtitle: Text(
                  '${loja.categoria}\n'
                  'Alerta: ${loja.multiplicador ?? 'padrão'} × | '
                  'Piso: ${loja.piso ?? 'padrão'} pontos'
                  '${loja.apelidos.isEmpty ? '' : '\nApelidos: ${loja.apelidos.join(', ')}'}',
                ),
                isThreeLine: true,
                trailing: _alterando.contains(loja.id)
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    key: Key('editar-regra-${loja.id}'),
                    onPressed: _alterando.contains(loja.id)
                        ? null
                        : () => _editarRegra(loja),
                    icon: const Icon(Icons.tune),
                    label: const Text('Editar regra'),
                  ),
                  TextButton.icon(
                    key: Key('remover-loja-${loja.id}'),
                    onPressed: _alterando.contains(loja.id)
                        ? null
                        : () => _removerLoja(loja),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CabecalhoLivelo extends StatelessWidget {
  const _CabecalhoLivelo({
    required this.preferencias,
    required this.erro,
    required this.carregando,
    required this.salvando,
    required this.adicionando,
    required this.aoTentarPreferencias,
    required this.aoEditarPreferencias,
    required this.aoAdicionarLoja,
  });

  final PreferenciasLiveloAdministrativas? preferencias;
  final Object? erro;
  final bool carregando;
  final bool salvando;
  final bool adicionando;
  final VoidCallback aoTentarPreferencias;
  final VoidCallback aoEditarPreferencias;
  final VoidCallback aoAdicionarLoja;

  @override
  Widget build(BuildContext context) {
    final preferenciasAtuais = preferencias;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              leading: carregando || salvando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.notifications_active_outlined),
              title: const Text('Preferências padrão'),
              subtitle: erro != null
                  ? const Text('Não foi possível carregar as preferências.')
                  : preferenciasAtuais == null
                  ? const Text('Carregando…')
                  : Text(
                      'Alerta em ${preferenciasAtuais.multiplicador} ×; '
                      'piso ${preferenciasAtuais.piso}; '
                      'Clube ${preferenciasAtuais.assinanteClube ? 'ativo' : 'inativo'}.',
                    ),
              trailing: erro != null
                  ? IconButton(
                      tooltip: 'Tentar novamente',
                      onPressed: carregando ? null : aoTentarPreferencias,
                      icon: const Icon(Icons.refresh),
                    )
                  : IconButton(
                      key: const Key('editar-preferencias-livelo'),
                      tooltip: 'Editar preferências',
                      onPressed: preferenciasAtuais == null || salvando
                          ? null
                          : aoEditarPreferencias,
                      icon: const Icon(Icons.edit_outlined),
                    ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              key: const Key('adicionar-loja-livelo'),
              onPressed: adicionando ? null : aoAdicionarLoja,
              icon: adicionando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Adicionar loja'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogoParceiros extends StatelessWidget {
  const _CatalogoParceiros({
    required this.controlador,
    required this.alterando,
    required this.aoAlterar,
  });

  final ControladorCatalogoAdministracao<LojaCatalogoInter> controlador;
  final Set<String> alterando;
  final Future<void> Function(LojaCatalogoInter loja, bool favorita) aoAlterar;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controlador,
      builder: (context, _) => _EstruturaCatalogo(
        chaveBusca: const Key('busca-parceiros-inter'),
        rotuloBusca: 'Buscar loja parceira',
        controlador: controlador,
        item: (loja) => SwitchListTile(
          title: Text(loja.nome),
          subtitle: Text(
            loja.ativa
                ? (loja.cashbackPrincipalTexto.isEmpty
                      ? 'Oferta ainda não informada'
                      : loja.cashbackPrincipalTexto)
                : 'Loja indisponível para acompanhar',
          ),
          value: loja.favorita,
          onChanged: !loja.ativa || alterando.contains(loja.id)
              ? null
              : (valor) => aoAlterar(loja, valor),
          secondary: alterando.contains(loja.id)
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.favorite_outline),
        ),
      ),
    );
  }
}

class _CatalogoDiretas extends StatelessWidget {
  const _CatalogoDiretas({
    required this.controlador,
    required this.alterando,
    required this.aoAlterar,
  });

  final ControladorCatalogoAdministracao<LojaDireto> controlador;
  final Set<String> alterando;
  final Future<void> Function(LojaDireto loja, bool selecionada) aoAlterar;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controlador,
      builder: (context, _) => _EstruturaCatalogo(
        chaveBusca: const Key('busca-lojas-diretas'),
        rotuloBusca: 'Buscar loja do Compre direto',
        controlador: controlador,
        item: (loja) => SwitchListTile(
          title: Text(loja.nome),
          subtitle: Text(
            loja.ativa
                ? 'Selecionada: ${loja.selecionada ? 'sim' : 'não'}'
                : 'Loja indisponível para seleção',
          ),
          value: loja.selecionada,
          onChanged: !loja.ativa || alterando.contains(loja.id)
              ? null
              : (valor) => aoAlterar(loja, valor),
          secondary: alterando.contains(loja.id)
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.storefront_outlined),
        ),
      ),
    );
  }
}

class _EstruturaCatalogo<T> extends StatelessWidget {
  const _EstruturaCatalogo({
    required this.chaveBusca,
    required this.rotuloBusca,
    required this.controlador,
    required this.item,
    this.cabecalho,
  });

  final Key chaveBusca;
  final String rotuloBusca;
  final ControladorCatalogoAdministracao<T> controlador;
  final Widget Function(T item) item;
  final Widget? cabecalho;

  @override
  Widget build(BuildContext context) {
    final soCarregando =
        controlador.carregandoInicial && controlador.itens.isEmpty;
    final falhaInicial =
        controlador.erroInicial != null && controlador.itens.isEmpty;
    return Column(
      children: [
        ?cabecalho,
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            key: chaveBusca,
            onChanged: controlador.mudarBusca,
            decoration: InputDecoration(
              labelText: rotuloBusca,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        if (!soCarregando && !falhaInicial)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('${controlador.total} encontrada(s)'),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: soCarregando
              ? const Carregando(mensagem: 'Carregando catálogo…')
              : falhaInicial
              ? EstadoFalha(
                  mensagem: 'Não foi possível carregar o catálogo.',
                  voltar: controlador.carregarPrimeira,
                )
              : controlador.itens.isEmpty
              ? const Center(child: Text('Nenhuma loja encontrada.'))
              : ListView(
                  children: [
                    for (final loja in controlador.itens) item(loja),
                    _RodapePaginacao(controlador: controlador),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DadosNovaLoja {
  const _DadosNovaLoja({
    required this.nome,
    required this.categoria,
    required this.apelidos,
    required this.multiplicador,
    required this.piso,
  });

  final String nome;
  final String categoria;
  final List<String> apelidos;
  final String? multiplicador;
  final String? piso;
}

class _DadosRegra {
  const _DadosRegra({required this.multiplicador, required this.piso});

  final String? multiplicador;
  final String? piso;
}

class _DadosPreferencias {
  const _DadosPreferencias({
    required this.multiplicador,
    required this.piso,
    required this.assinanteClube,
  });

  final String multiplicador;
  final String piso;
  final bool assinanteClube;
}

String? _opcional(String texto) {
  final valor = texto.trim();
  return valor.isEmpty ? null : valor;
}

Future<_DadosNovaLoja?> _dialogoNovaLoja(BuildContext context) async {
  var nome = '';
  var categoria = '';
  var apelidos = '';
  var multiplicador = '';
  var piso = '';
  return showDialog<_DadosNovaLoja>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Adicionar loja Livelo'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('nova-loja-nome'),
              onChanged: (valor) => nome = valor,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextFormField(
              key: const Key('nova-loja-categoria'),
              onChanged: (valor) => categoria = valor,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            TextFormField(
              onChanged: (valor) => apelidos = valor,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Apelidos (um por linha)',
              ),
            ),
            TextFormField(
              onChanged: (valor) => multiplicador = valor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Alerta próprio (opcional)',
              ),
            ),
            TextFormField(
              onChanged: (valor) => piso = valor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Piso próprio (opcional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar-nova-loja'),
          onPressed: () {
            final nomeFinal = nome.trim();
            final categoriaFinal = categoria.trim();
            if (nomeFinal.isEmpty || categoriaFinal.isEmpty) return;
            Navigator.pop(
              context,
              _DadosNovaLoja(
                nome: nomeFinal,
                categoria: categoriaFinal,
                apelidos: apelidos
                    .split('\n')
                    .map((valor) => valor.trim())
                    .where((valor) => valor.isNotEmpty)
                    .toList(growable: false),
                multiplicador: _opcional(multiplicador),
                piso: _opcional(piso),
              ),
            );
          },
          child: const Text('Cadastrar'),
        ),
      ],
    ),
  );
}

Future<_DadosRegra?> _dialogoRegra(
  BuildContext context,
  LojaLiveloAdministrativa loja,
) async {
  var multiplicador = loja.multiplicador ?? '';
  var piso = loja.piso ?? '';
  return showDialog<_DadosRegra>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Regra de ${loja.nome}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const Key('regra-multiplicador'),
            initialValue: multiplicador,
            onChanged: (valor) => multiplicador = valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Alerta próprio',
              helperText: 'Vazio usa o padrão global',
            ),
          ),
          TextFormField(
            key: const Key('regra-piso'),
            initialValue: piso,
            onChanged: (valor) => piso = valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Piso próprio',
              helperText: 'Vazio usa o padrão global',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('confirmar-regra-livelo'),
          onPressed: () => Navigator.pop(
            context,
            _DadosRegra(
              multiplicador: _opcional(multiplicador),
              piso: _opcional(piso),
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<_DadosPreferencias?> _dialogoPreferencias(
  BuildContext context,
  PreferenciasLiveloAdministrativas atuais,
) async {
  var multiplicador = atuais.multiplicador;
  var piso = atuais.piso;
  var clube = atuais.assinanteClube;
  return showDialog<_DadosPreferencias>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, atualizar) => AlertDialog(
        title: const Text('Preferências Livelo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('preferencia-multiplicador'),
              initialValue: multiplicador,
              onChanged: (valor) => multiplicador = valor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Multiplicador padrão',
              ),
            ),
            TextFormField(
              key: const Key('preferencia-piso'),
              initialValue: piso,
              onChanged: (valor) => piso = valor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Piso padrão'),
            ),
            SwitchListTile(
              title: const Text('Assinante Clube Livelo'),
              value: clube,
              onChanged: (valor) => atualizar(() => clube = valor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar-preferencias-livelo'),
            onPressed: () {
              final multiplicadorFinal = multiplicador.trim();
              final pisoFinal = piso.trim();
              if (multiplicadorFinal.isEmpty || pisoFinal.isEmpty) return;
              Navigator.pop(
                context,
                _DadosPreferencias(
                  multiplicador: multiplicadorFinal,
                  piso: pisoFinal,
                  assinanteClube: clube,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}

class _RodapePaginacao<T> extends StatelessWidget {
  const _RodapePaginacao({required this.controlador});

  final ControladorCatalogoAdministracao<T> controlador;

  @override
  Widget build(BuildContext context) {
    if (controlador.carregandoMais) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (controlador.erroMais != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton(
          onPressed: controlador.carregarMais,
          child: const Text('Tentar carregar mais'),
        ),
      );
    }
    if (controlador.temProxima) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton(
          onPressed: controlador.carregarMais,
          child: const Text('Carregar mais'),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: Text('Fim da lista.')),
    );
  }
}
