import 'dart:async';

import 'package:flutter/material.dart';

import '../estado/filtros.dart';
import '../folhas/folha_filtros.dart';
import '../fundacao/ds_medidas.dart';
import '../fundacao/ds_tema.dart';

/// Busca com o botão de filtros embutido.
///
/// Quando recebe [escopoFiltros], o botão abre a `FolhaFiltros` desse
/// escopo e o contador reflete o estado GLOBAL do escopo — o mesmo número
/// em qualquer tela que use o mesmo escopo.
class DsCampoBusca extends StatefulWidget {
  const DsCampoBusca({
    super.key,
    required this.aoBuscar,
    this.controlador,
    this.dica = 'Buscar',
    this.escopoFiltros,
    this.contarResultados,
    this.espera = const Duration(milliseconds: 350),
  });

  final ValueChanged<String> aoBuscar;
  final TextEditingController? controlador;
  final String dica;
  final EscopoFiltro? escopoFiltros;
  final Future<int?> Function(ValoresFiltro rascunho)? contarResultados;

  /// Debounce da digitação. Enviar pelo teclado busca na hora.
  final Duration espera;

  @override
  State<DsCampoBusca> createState() => _EstadoDsCampoBusca();
}

class _EstadoDsCampoBusca extends State<DsCampoBusca> {
  late final TextEditingController _controlador =
      widget.controlador ?? TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.controlador == null) _controlador.dispose();
    super.dispose();
  }

  void _aoDigitar(String texto) {
    _timer?.cancel();
    _timer = Timer(widget.espera, () => widget.aoBuscar(texto.trim()));
    setState(() {});
  }

  void _enviar(String texto) {
    _timer?.cancel();
    widget.aoBuscar(texto.trim());
  }

  void _limpar() {
    _controlador.clear();
    _enviar('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipo;
    final escopo = widget.escopoFiltros;
    return Container(
      height: DsEspaco.alvoToque,
      padding: const EdgeInsetsDirectional.only(
        start: DsEspaco.e4,
        end: DsEspaco.e1,
      ),
      decoration: BoxDecoration(
        color: c.superficie1,
        borderRadius: BorderRadius.circular(DsRaio.sm),
        border: Border.all(color: c.borda2),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: c.texto2),
          const SizedBox(width: DsEspaco.e2),
          Expanded(
            child: TextField(
              controller: _controlador,
              onChanged: _aoDigitar,
              onSubmitted: _enviar,
              textInputAction: TextInputAction.search,
              style: t.corpo,
              decoration: InputDecoration(
                hintText: widget.dica,
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (_controlador.text.isNotEmpty)
            IconButton(
              tooltip: 'Limpar busca',
              icon: Icon(Icons.close_rounded, size: 18, color: c.texto2),
              onPressed: _limpar,
            ),
          if (escopo != null)
            _BotaoFiltros(
              controlador: context.filtros(escopo),
              aoTocar: () => FolhaFiltros.mostrar(
                context,
                escopo: escopo,
                contarResultados: widget.contarResultados,
              ),
            ),
        ],
      ),
    );
  }
}

class _BotaoFiltros extends StatelessWidget {
  const _BotaoFiltros({required this.controlador, required this.aoTocar});

  final ControladorFiltros controlador;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    return ValueListenableBuilder<ValoresFiltro>(
      valueListenable: controlador,
      builder: (context, _, _) {
        final ativos = controlador.ativos;
        return Tooltip(
          message: switch (ativos) {
            0 => 'Filtros',
            1 => 'Filtros, 1 ativo',
            _ => 'Filtros, $ativos ativos',
          },
          child: Material(
            color: ativos > 0 ? c.primariaSuave : c.superficie2,
            borderRadius: BorderRadius.circular(DsRaio.xs),
            child: InkWell(
              borderRadius: BorderRadius.circular(DsRaio.xs),
              onTap: aoTocar,
              child: SizedBox.square(
                dimension: 40,
                child: Center(
                  child: Badge(
                  isLabelVisible: ativos > 0,
                  label: Text('$ativos'),
                  backgroundColor: c.primaria,
                  textColor: c.sobrePrimaria,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: ativos > 0 ? c.primariaForte : c.texto1,
                  ),
                ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
