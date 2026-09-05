import 'package:flutter/material.dart';

import '../../app/componentes/fundacao_visual.dart';
import '../../app/tema/tokens.dart';
import '../../core/api/modelos.dart';

enum ModoSeletorCategoriasInter { acompanhar, filtrar }

/// Seleção do filtro temporário. `categoria == null && !semCategoria` significa
/// Todas; `semCategoria` identifica somente ausência de categoria na origem.
class SelecaoCategoriaTemporaria {
  const SelecaoCategoriaTemporaria.todas()
    : categoria = null,
      semCategoria = false;
  const SelecaoCategoriaTemporaria.categoria(this.categoria)
    : semCategoria = false;
  const SelecaoCategoriaTemporaria.semCategoria()
    : categoria = null,
      semCategoria = true;

  final String? categoria;
  final bool semCategoria;
}

Future<Set<String?>?> mostrarSeletorCategoriasAcompanhadas(
  BuildContext contexto, {
  required List<CategoriaInter> categorias,
  required Set<String?> selecionadasIniciais,
}) {
  return mostrarFolhaRadar<Set<String?>>(
    contexto,
    alturaMaxima: 0.9,
    builder: (context) => FolhaRadar(
      titulo: 'Categorias acompanhadas',
      descricao: 'Categorias fornecidas pelo Shopping Inter',
      child: Flexible(
        child: _SeletorCategoriasSheet(
          nota:
              'A lista acompanha os nomes recebidos do Inter. Categorias novas podem aparecer automaticamente após novas coletas.',
          categorias: categorias,
          selecionadasIniciais: selecionadasIniciais,
          rotuloConfirmar: 'Salvar categorias',
          modo: ModoSeletorCategoriasInter.acompanhar,
          converterRetorno: (selecionadas) => selecionadas,
        ),
      ),
    ),
  );
}

Future<SelecaoCategoriaTemporaria?> mostrarSelecaoCategoriaTemporaria(
  BuildContext contexto, {
  required List<CategoriaInter> categorias,
  required String? categoriaAtual,
  required bool semCategoriaAtual,
}) {
  const todas = SelecaoCategoriaTemporaria.todas();
  final iniciais = semCategoriaAtual
      ? <String?>{null}
      : categoriaAtual == null || categoriaAtual.isEmpty
      ? <String?>{}
      : <String?>{categoriaAtual};
  return mostrarFolhaRadar<SelecaoCategoriaTemporaria>(
    contexto,
    alturaMaxima: 0.9,
    builder: (context) => FolhaRadar(
      titulo: 'Filtrar por categoria',
      descricao: 'Filtro temporário do catálogo já salvo',
      child: Flexible(
        child: _SeletorCategoriasSheet(
          nota:
              'A categoria é usada exatamente como foi recebida do Shopping Inter. Isto não solicita uma nova coleta.',
          categorias: categorias,
          selecionadasIniciais: iniciais,
          rotuloConfirmar: 'Ver ofertas',
          modo: ModoSeletorCategoriasInter.filtrar,
          converterRetorno: (selecionadas) {
            if (selecionadas.isEmpty) return todas;
            final valor = selecionadas.first;
            return valor == null
                ? const SelecaoCategoriaTemporaria.semCategoria()
                : SelecaoCategoriaTemporaria.categoria(valor);
          },
        ),
      ),
    ),
  );
}

class _SeletorCategoriasSheet<T> extends StatefulWidget {
  const _SeletorCategoriasSheet({
    required this.nota,
    required this.categorias,
    required this.selecionadasIniciais,
    required this.rotuloConfirmar,
    required this.modo,
    required this.converterRetorno,
  });

  final String nota;
  final List<CategoriaInter> categorias;
  final Set<String?> selecionadasIniciais;
  final String rotuloConfirmar;
  final ModoSeletorCategoriasInter modo;
  final T Function(Set<String?> selecionadas) converterRetorno;

  @override
  State<_SeletorCategoriasSheet<T>> createState() =>
      _EstadoSeletorCategoriasSheet<T>();
}

class _EstadoSeletorCategoriasSheet<T>
    extends State<_SeletorCategoriasSheet<T>> {
  late var _selecionadas = <String?>{...widget.selecionadasIniciais};

  void _alternar(String? valor) {
    setState(() {
      if (widget.modo == ModoSeletorCategoriasInter.filtrar) {
        _selecionadas = <String?>{valor};
        return;
      }
      final nova = <String?>{..._selecionadas};
      if (!nova.add(valor)) nova.remove(valor);
      _selecionadas = nova;
    });
  }

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
          padding: const EdgeInsets.fromLTRB(3, 0, 3, 4),
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
        Flexible(
          child: ListView(
            key: const Key('seletor-categorias-lista'),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            children: [
              if (widget.modo == ModoSeletorCategoriasInter.filtrar)
                _LinhaCategoriaInter(
                  key: const Key('categoria-todas'),
                  nome: 'Todas as categorias',
                  selecionada: _selecionadas.isEmpty,
                  modo: widget.modo,
                  aoEscolher: () => setState(() => _selecionadas = <String?>{}),
                ),
              for (final categoria in widget.categorias)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: _LinhaCategoriaInter(
                    key: ValueKey(
                      'categoria-${categoria.valor ?? '__sem_categoria__'}',
                    ),
                    nome: categoria.nome,
                    selecionada: _selecionadas.contains(categoria.valor),
                    modo: widget.modo,
                    aoEscolher: () => _alternar(categoria.valor),
                  ),
                ),
            ],
          ),
        ),
        Padding(
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
              final confirmar = FilledButton(
                key: Key('confirmar-${widget.modo.name}'),
                onPressed: _confirmar,
                style: FilledButton.styleFrom(backgroundColor: Tokens.action),
                child: Text(widget.rotuloConfirmar),
              );
              if (empilhar) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [confirmar, const SizedBox(height: 8), cancelar],
                );
              }
              return Row(
                children: [
                  Expanded(child: cancelar),
                  const SizedBox(width: 10),
                  Expanded(child: confirmar),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LinhaCategoriaInter extends StatelessWidget {
  const _LinhaCategoriaInter({
    super.key,
    required this.nome,
    required this.selecionada,
    required this.modo,
    required this.aoEscolher,
  });

  final String nome;
  final bool selecionada;
  final ModoSeletorCategoriasInter modo;
  final VoidCallback aoEscolher;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Semantics(
      selected: selecionada,
      button: true,
      label:
          'Categoria $nome, ${selecionada ? 'selecionada' : 'não selecionada'}',
      child: InkWell(
        onTap: aoEscolher,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
          decoration: BoxDecoration(
            color: cores.superficieAlternativa,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cores.borda),
          ),
          child: Row(
            children: [
              if (modo == ModoSeletorCategoriasInter.acompanhar)
                Checkbox(
                  value: selecionada,
                  onChanged: (_) => aoEscolher(),
                  activeColor: cores.acao,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )
              else
                Icon(
                  selecionada
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selecionada ? cores.acao : cores.textoSuave,
                  size: 20,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nome,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
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
