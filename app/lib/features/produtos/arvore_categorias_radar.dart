import 'package:flutter/material.dart';

import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';

/// Modo de seleção da árvore de categorias do Radar.
enum ModoSeletorCategoriasRadar { acompanhar, filtrar }

/// Nó exibível da hierarquia montada a partir da lista plana do contrato.
class CategoriaRadarNo {
  const CategoriaRadarNo({required this.categoria, required this.filhos});

  final CategoriaRadar categoria;
  final List<CategoriaRadarNo> filhos;

  bool get eFolha => filhos.isEmpty;
}

/// Monta a árvore a partir da lista plana retornada pela API. Referências
/// órfãs continuam visíveis como raiz e a ordenação vem do contrato.
List<CategoriaRadarNo> montarArvoreCategoriasRadar(
  List<CategoriaRadar> categorias,
) {
  final nos = <String, CategoriaRadarNo>{
    for (final categoria in categorias)
      categoria.slug: CategoriaRadarNo(categoria: categoria, filhos: []),
  };
  final raizes = <CategoriaRadarNo>[];
  for (final no in nos.values) {
    final paiSlug = no.categoria.categoriaPaiSlug;
    final pai = paiSlug == null ? null : nos[paiSlug];
    if (pai == null) {
      raizes.add(no);
    } else {
      pai.filhos.add(no);
    }
  }
  int comparar(CategoriaRadarNo a, CategoriaRadarNo b) {
    final porOrdem = a.categoria.ordem.compareTo(b.categoria.ordem);
    if (porOrdem != 0) return porOrdem;
    return a.categoria.nome.compareTo(b.categoria.nome);
  }

  void ordenar(List<CategoriaRadarNo> itens) {
    itens.sort(comparar);
    for (final item in itens) {
      ordenar(item.filhos);
    }
  }

  ordenar(raizes);
  return raizes;
}

bool _todosMarcados(CategoriaRadarNo no, Set<String> marcadas) {
  if (!marcadas.contains(no.categoria.slug)) return false;
  for (final filho in no.filhos) {
    if (!_todosMarcados(filho, marcadas)) return false;
  }
  return true;
}

bool _nenhumMarcado(CategoriaRadarNo no, Set<String> marcadas) {
  if (marcadas.contains(no.categoria.slug)) return false;
  for (final filho in no.filhos) {
    if (!_nenhumMarcado(filho, marcadas)) return false;
  }
  return true;
}

/// Árvore vertical recolhível de categorias do Radar.
///
/// O estado de expansão vive aqui; a seleção chega e sai pelo widget, para que
/// o dono preserve a escolha confirmada. Em [ModoSeletorCategoriasRadar.acompanhar],
/// [marcadas] contém somente os nós escolhidos diretamente: a cobertura dos
/// descendentes é calculada aqui, sem transformar uma seleção de pai em uma
/// lista fechada de filhos. No modo [ModoSeletorCategoriasRadar.filtrar]
/// apenas uma seleção ativa é permitida.
class ArvoreCategoriasRadar extends StatefulWidget {
  const ArvoreCategoriasRadar({
    super.key,
    required this.categorias,
    required this.modo,
    required this.marcadas,
    required this.aoMudar,
  });

  final List<CategoriaRadar> categorias;
  final ModoSeletorCategoriasRadar modo;
  final Set<String> marcadas;
  final ValueChanged<Set<String>> aoMudar;

  @override
  State<ArvoreCategoriasRadar> createState() => _EstadoArvoreCategoriasRadar();
}

class _EstadoArvoreCategoriasRadar extends State<ArvoreCategoriasRadar> {
  late List<CategoriaRadarNo> _raizes;
  late Set<String> _expandidas;

  @override
  void initState() {
    super.initState();
    _reconstruirArvore();
  }

  @override
  void didUpdateWidget(covariant ArvoreCategoriasRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.categorias, widget.categorias)) {
      _reconstruirArvore(preservarExpansao: true);
    }
  }

  void _reconstruirArvore({bool preservarExpansao = false}) {
    _raizes = montarArvoreCategoriasRadar(widget.categorias);
    final expansoesValidas = {for (final no in _raizes) ..._paisRecursivo(no)};
    _expandidas = preservarExpansao
        ? _expandidas.intersection(expansoesValidas)
        : expansoesValidas;
  }

  static List<String> _paisRecursivo(CategoriaRadarNo no) => [
    if (!no.eFolha) no.categoria.slug,
    for (final filho in no.filhos) ..._paisRecursivo(filho),
  ];

  void _alternarExpansao(String slug) {
    setState(() {
      if (!_expandidas.add(slug)) _expandidas.remove(slug);
    });
  }

  Set<String> _efetivas(Set<String> diretas) {
    final efetivas = <String>{};
    void visitar(CategoriaRadarNo no, bool cobertaPeloPai) {
      final coberta = cobertaPeloPai || diretas.contains(no.categoria.slug);
      if (coberta) efetivas.add(no.categoria.slug);
      for (final filho in no.filhos) {
        visitar(filho, coberta);
      }
    }

    for (final raiz in _raizes) {
      visitar(raiz, false);
    }
    return efetivas;
  }

  void _removerDiretasDaSubarvore(CategoriaRadarNo no, Set<String> diretas) {
    diretas.remove(no.categoria.slug);
    for (final filho in no.filhos) {
      _removerDiretasDaSubarvore(filho, diretas);
    }
  }

  Set<String> _selecionarSubarvore(CategoriaRadarNo no) {
    final novo = {...widget.marcadas};
    _removerDiretasDaSubarvore(no, novo);
    novo.add(no.categoria.slug);
    return novo;
  }

  Set<String> _desmarcarSubarvore(CategoriaRadarNo alvo) {
    final novo = {...widget.marcadas};
    final caminho = <CategoriaRadarNo>[];

    bool encontrar(CategoriaRadarNo no) {
      caminho.add(no);
      if (identical(no, alvo)) return true;
      for (final filho in no.filhos) {
        if (encontrar(filho)) return true;
      }
      caminho.removeLast();
      return false;
    }

    for (final raiz in _raizes) {
      if (encontrar(raiz)) break;
    }

    var coberturaHerdada = false;
    for (var indice = 0; indice < caminho.length - 1; indice++) {
      final atual = caminho[indice];
      final proximo = caminho[indice + 1];
      final coberturaDireta = novo.contains(atual.categoria.slug);
      if (coberturaHerdada || coberturaDireta) {
        novo.remove(atual.categoria.slug);
        for (final irmao in atual.filhos) {
          if (!identical(irmao, proximo)) novo.add(irmao.categoria.slug);
        }
        coberturaHerdada = true;
      }
    }
    _removerDiretasDaSubarvore(alvo, novo);
    return novo;
  }

  Set<String> _alternar(CategoriaRadarNo no) {
    if (widget.modo == ModoSeletorCategoriasRadar.filtrar) {
      if (widget.marcadas.contains(no.categoria.slug)) return const {};
      return {no.categoria.slug};
    }
    final efetivas = _efetivas(widget.marcadas);
    if (_todosMarcados(no, efetivas)) return _desmarcarSubarvore(no);
    return _selecionarSubarvore(no);
  }

  @override
  Widget build(BuildContext context) {
    if (_raizes.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [for (final no in _raizes) ..._grupo(no, nivel: 0)],
    );
  }

  List<Widget> _grupo(CategoriaRadarNo no, {required int nivel}) {
    final expandida = _expandidas.contains(no.categoria.slug);
    final cor = CoresRadar.de(context);
    final marcadas = widget.modo == ModoSeletorCategoriasRadar.acompanhar
        ? _efetivas(widget.marcadas)
        : widget.marcadas;
    final filhos = [
      if (expandida)
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: cor.borda.withValues(alpha: 0.65)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final filho in no.filhos) ..._grupo(filho, nivel: nivel + 1),
            ],
          ),
        ),
    ];
    return [
      Container(
        decoration: BoxDecoration(
          color: cor.superficieAlternativa,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cor.borda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LinhaCategoria(
              no: no,
              modo: widget.modo,
              marcadas: marcadas,
              expandida: expandida,
              aoAlternarExpansao: no.eFolha
                  ? null
                  : () => _alternarExpansao(no.categoria.slug),
              aoEscolher: () => widget.aoMudar(_alternar(no)),
              nivel: nivel,
            ),
            ...filhos,
          ],
        ),
      ),
    ];
  }
}

class _LinhaCategoria extends StatelessWidget {
  const _LinhaCategoria({
    required this.no,
    required this.modo,
    required this.marcadas,
    required this.expandida,
    required this.aoAlternarExpansao,
    required this.aoEscolher,
    required this.nivel,
  });

  final CategoriaRadarNo no;
  final ModoSeletorCategoriasRadar modo;
  final Set<String> marcadas;
  final bool expandida;
  final VoidCallback? aoAlternarExpansao;
  final VoidCallback aoEscolher;
  final int nivel;

  bool get _marcada => marcadas.contains(no.categoria.slug);

  @override
  Widget build(BuildContext context) {
    final eFolha = no.eFolha;
    final todos = _todosMarcados(no, marcadas);
    final parcial = !todos && !_nenhumMarcado(no, marcadas);
    final estado = modo == ModoSeletorCategoriasRadar.acompanhar
        ? eFolha
              ? _marcada
                    ? 'selecionada'
                    : 'não selecionada'
              : parcial
              ? 'parcialmente selecionada'
              : todos
              ? 'selecionada'
              : 'não selecionada'
        : _marcada
        ? 'filtro ativo'
        : 'sem filtro';
    return Semantics(
      container: true,
      label:
          'Categoria ${no.categoria.nome}, nível ${nivel + 1}, '
          '${no.eFolha ? estado : (expandida ? 'expandida' : 'recolhida')}, '
          '$estado',
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
        child: Row(
          children: [
            SizedBox(width: 38, height: 38, child: _toggleExpansao(context)),
            Expanded(child: _escolha(context, todos, parcial)),
          ],
        ),
      ),
    );
  }

  Widget _toggleExpansao(BuildContext context) {
    if (no.eFolha) return const SizedBox.shrink();
    final cores = CoresRadar.de(context);
    return IconButton(
      key: ValueKey('expandir-${no.categoria.slug}'),
      onPressed: aoAlternarExpansao,
      tooltip: expandida
          ? 'Recolher ${no.categoria.nome}'
          : 'Expandir ${no.categoria.nome}',
      icon: AnimatedRotation(
        turns: expandida ? 0.25 : 0,
        duration: const Duration(milliseconds: 180),
        child: Icon(Icons.chevron_right, size: 20, color: cores.textoSuave),
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
    );
  }

  Widget _escolha(BuildContext context, bool todos, bool parcial) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final eFolha = no.eFolha;
    final nome = no.categoria.nome;
    final acompanhar = modo == ModoSeletorCategoriasRadar.acompanhar;
    final nota = acompanhar
        ? (eFolha
              ? null
              : parcial
              ? 'Seleção parcial abaixo'
              : 'Seleciona todas as categorias abaixo')
        : (eFolha ? null : 'Inclui as categorias filhas');

    final controle = acompanhar
        ? Checkbox(
            value: _marcada ? true : (parcial ? null : false),
            tristate: true,
            onChanged: (_) => aoEscolher(),
            activeColor: cores.acao,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        : Radio<String>(
            value: no.categoria.slug,
            activeColor: cores.acao,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          );

    final rotulo = InkWell(
      onTap: aoEscolher,
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            controle,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: tema.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  if (nota != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      nota,
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: cores.textoSuave,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return rotulo;
  }
}

/// Seleção confirmada no filtro temporário; `slug == null` significa `Todas`.
class SelecaoCategoriaTemporaria {
  const SelecaoCategoriaTemporaria.todas() : slug = null;
  const SelecaoCategoriaTemporaria.uma(this.slug);

  final String? slug;
}

/// Abre o bottom sheet persistente de categorias acompanhadas.
///
/// Retorna o conjunto escolhido ao confirmar com `Salvar categorias` ou `null`
/// quando a pessoa cancela sem alterar a seleção confirmada.
Future<Set<String>?> mostrarSeletorCategoriasAcompanhadas(
  BuildContext contexto, {
  required List<CategoriaRadar> categorias,
  required Set<String> selecionadasIniciais,
}) {
  return showModalBottomSheet<Set<String>>(
    context: contexto,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _SeletorCategoriasSheet(
      titulo: 'Categorias acompanhadas',
      subtitulo: 'Configuração persistente para as lojas selecionadas',
      nota:
          'Escolher um grupo inclui suas categorias filhas atuais e futuras. '
          'Esta configuração é diferente do filtro temporário da tela Produtos.',
      categorias: categorias,
      selecionadasIniciais: selecionadasIniciais,
      rotuloConfirmar: 'Salvar categorias',
      converterRetorno: (selecionadas) => selecionadas,
    ),
  );
}

/// Abre o bottom sheet do filtro temporário de `Produtos`.
///
/// Retorna `null` ao cancelar ou uma [SelecaoCategoriaTemporaria] com o nó
/// escolhido (`todas` quando a pessoa escolher ver o catálogo inteiro).
Future<SelecaoCategoriaTemporaria?> mostrarSelecaoCategoriaTemporaria(
  BuildContext contexto, {
  required List<CategoriaRadar> categorias,
  required String? selecionadaAtual,
}) {
  const todas = SelecaoCategoriaTemporaria.todas();
  return showModalBottomSheet<SelecaoCategoriaTemporaria>(
    context: contexto,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _SeletorCategoriasSheet(
      titulo: 'Filtrar por categoria',
      subtitulo: 'Filtro temporário do catálogo já salvo',
      nota:
          'Isto não altera suas categorias acompanhadas nem solicita uma nova coleta.',
      categorias: categorias,
      selecionadasIniciais: selecionadaAtual == null || selecionadaAtual.isEmpty
          ? const {}
          : {selecionadaAtual},
      rotuloConfirmar: 'Ver ofertas',
      modo: ModoSeletorCategoriasRadar.filtrar,
      converterRetorno: (selecionadas) => selecionadas.isEmpty
          ? todas
          : SelecaoCategoriaTemporaria.uma(selecionadas.first),
    ),
  );
}

class _SeletorCategoriasSheet extends StatefulWidget {
  const _SeletorCategoriasSheet({
    required this.titulo,
    required this.subtitulo,
    required this.nota,
    required this.categorias,
    required this.selecionadasIniciais,
    required this.rotuloConfirmar,
    required this.converterRetorno,
    this.modo = ModoSeletorCategoriasRadar.acompanhar,
  });

  final String titulo;
  final String subtitulo;
  final String nota;
  final List<CategoriaRadar> categorias;
  final Set<String> selecionadasIniciais;
  final String rotuloConfirmar;
  final ModoSeletorCategoriasRadar modo;
  final Object Function(Set<String> selecionadas) converterRetorno;

  @override
  State<_SeletorCategoriasSheet> createState() =>
      _EstadoSeletorCategoriasSheet();
}

class _EstadoSeletorCategoriasSheet extends State<_SeletorCategoriasSheet> {
  late var _selecionadas = {...widget.selecionadasIniciais};

  void _confirmar() {
    Navigator.of(context).pop(widget.converterRetorno(_selecionadas));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    final escuro = tema.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.titulo,
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.subtitulo,
                style: tema.textTheme.labelSmall?.copyWith(
                  color: cores.textoSuave,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: escuro ? Tokens.cianoFundoEscuro : Tokens.plumSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              widget.nota,
              style: tema.textTheme.labelSmall?.copyWith(
                color: cores.textoSuave,
                fontSize: 9,
                height: 1.5,
              ),
            ),
          ),
        ),
        Flexible(child: _corpoSelecao(context)),
        _BotoesAcoes(sheet: widget, confirmar: _confirmar),
      ],
    );
  }

  Widget _corpoSelecao(BuildContext context) {
    final lista = ListView(
      key: const Key('seletor-categorias-lista'),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      children: [
        if (widget.modo == ModoSeletorCategoriasRadar.filtrar)
          _LinhaTodasCategorias(
            marcada: _selecionadas.isEmpty,
            aoEscolher: () => setState(() => _selecionadas = <String>{}),
          ),
        ArvoreCategoriasRadar(
          categorias: widget.categorias,
          modo: widget.modo,
          marcadas: _selecionadas,
          aoMudar: (novo) => setState(() => _selecionadas = novo),
        ),
      ],
    );
    if (widget.modo != ModoSeletorCategoriasRadar.filtrar) return lista;
    return RadioGroup<String>(
      groupValue: _selecionadas.isEmpty ? null : _selecionadas.first,
      onChanged: (valor) {
        final Set<String> novo = valor == null || valor.isEmpty
            ? <String>{}
            : <String>{valor};
        if (novo != _selecionadas) setState(() => _selecionadas = novo);
      },
      child: lista,
    );
  }
}

class _LinhaTodasCategorias extends StatelessWidget {
  const _LinhaTodasCategorias({
    required this.marcada,
    required this.aoEscolher,
  });

  final bool marcada;
  final VoidCallback aoEscolher;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cores = CoresRadar.de(context);
    return Semantics(
      selected: marcada,
      child: InkWell(
        onTap: aoEscolher,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: cores.superficieAlternativa,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cores.borda),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: '',
                activeColor: cores.acao,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Todas as categorias',
                  style: tema.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotoesAcoes extends StatelessWidget {
  const _BotoesAcoes({required this.sheet, required this.confirmar});

  final _SeletorCategoriasSheet sheet;
  final VoidCallback confirmar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      child: LayoutBuilder(
        builder: (context, limites) {
          final empilhar =
              limites.maxWidth < 340 ||
              MediaQuery.textScalerOf(context).scale(10) > 13;
          final cancelar = OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          );
          final confirmarWidget = FilledButton(
            key: Key('confirmar-${sheet.modo.name}'),
            onPressed: confirmar,
            style: FilledButton.styleFrom(backgroundColor: Tokens.action),
            child: Text(sheet.rotuloConfirmar),
          );
          if (empilhar) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [confirmarWidget, const SizedBox(height: 8), cancelar],
            );
          }
          return Row(
            children: [
              Expanded(child: cancelar),
              const SizedBox(width: 10),
              Expanded(child: confirmarWidget),
            ],
          );
        },
      ),
    );
  }
}
