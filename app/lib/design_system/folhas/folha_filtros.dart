import 'package:flutter/material.dart';

import '../componentes/ds_basicos.dart';
import '../componentes/ds_estados.dart';
import '../estado/filtros.dart';
import '../fundacao/ds_medidas.dart';
import '../fundacao/ds_tema.dart';
import 'ds_folha.dart';

/// UMA folha de filtros para o app inteiro.
///
/// A tela só diz o escopo; a especificação e o estado aplicado vêm do
/// [RegistroFiltros] global. Retorna `true` quando o usuário aplicou.
///
/// ```dart
/// final aplicou = await FolhaFiltros.mostrar(context, escopo: EscopoFiltro.pichau);
/// ```
abstract final class FolhaFiltros {
  static Future<bool> mostrar(
    BuildContext context, {
    required EscopoFiltro escopo,
    Future<int?> Function(ValoresFiltro rascunho)? contarResultados,
  }) async {
    final controlador = context.filtros(escopo);
    final aplicou = await DsFolha.abrir<bool>(
      context,
      construir: (_) => _CorpoFiltros(
        controlador: controlador,
        contarResultados: contarResultados,
      ),
    );
    return aplicou ?? false;
  }
}

class _CorpoFiltros extends StatefulWidget {
  const _CorpoFiltros({
    super.key,
    required this.controlador,
    required this.contarResultados,
  });

  final ControladorFiltros controlador;
  final Future<int?> Function(ValoresFiltro rascunho)? contarResultados;

  @override
  State<_CorpoFiltros> createState() => _EstadoCorpoFiltros();
}

class _EstadoCorpoFiltros extends State<_CorpoFiltros> {
  late ValoresFiltro _rascunho = widget.controlador.value;
  final _campos = <String, (TextEditingController, TextEditingController)>{};
  String? _erro;
  int? _contagem;
  var _geracaoContagem = 0;

  EspecFiltros get _espec => widget.controlador.espec;

  @override
  void initState() {
    super.initState();
    for (final secao in _espec.secoes.whereType<SecaoFaixa>()) {
      final faixa = _rascunho.faixa(secao.id);
      _campos[secao.id] = (
        TextEditingController(text: faixa.minimo),
        TextEditingController(text: faixa.maximo),
      );
    }
    _recontar();
  }

  @override
  void dispose() {
    for (final (a, b) in _campos.values) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  void _mudar(String id, Object? valor) {
    setState(() {
      _rascunho = _rascunho.com(id, valor);
      _erro = null;
    });
    _recontar();
  }

  Future<void> _recontar() async {
    final contar = widget.contarResultados;
    if (contar == null) return;
    final geracao = ++_geracaoContagem;
    try {
      final total = await contar(_rascunho);
      if (!mounted || geracao != _geracaoContagem) return;
      setState(() => _contagem = total);
    } catch (_) {
      // Contagem é cortesia: falha não bloqueia aplicar.
    }
  }

  void limpar() {
    setState(() {
      _rascunho = _espec.padroes;
      _erro = null;
      for (final (a, b) in _campos.values) {
        a.clear();
        b.clear();
      }
    });
    _recontar();
  }

  void aplicar() {
    final erro = _espec.validar(_rascunho);
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    widget.controlador.aplicar(_rascunho);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ativos = _espec.contarAtivos(_rascunho);
    final rotuloAplicar = switch (_contagem) {
      null => 'Aplicar filtros',
      1 => 'Ver 1 resultado',
      final n => 'Ver $n resultados',
    };
    return DsFolha(
      titulo: 'Filtros',
      subtitulo: ativos == 0
          ? _espec.origem
          : '${_espec.origem} · $ativos ${ativos == 1 ? 'ativo' : 'ativos'}',
      corpo: _formulario(context),
      rodape: Row(
        children: [
          Expanded(
            child: DsBotao(
              rotulo: 'Limpar',
              variante: DsVarianteBotao.contorno,
              aoTocar: limpar,
            ),
          ),
          const SizedBox(width: DsEspaco.e2),
          Expanded(
            flex: 2,
            child: DsBotao(rotulo: rotuloAplicar, aoTocar: aplicar),
          ),
        ],
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    final t = context.tipo;
    final secoes = _espec.secoes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < secoes.length; i++) ...[
          if (i > 0) const SizedBox(height: DsEspaco.e6),
          Semantics(
            header: true,
            child: Text(
              secoes[i].titulo,
              style: t.rotulo.copyWith(color: context.cores.texto2),
            ),
          ),
          const SizedBox(height: DsEspaco.e1),
          _secao(secoes[i]),
        ],
        if (_erro != null) ...[
          const SizedBox(height: DsEspaco.e4),
          DsFaixa(texto: _erro!, tom: DsTom.perigo),
        ],
      ],
    );
  }

  Widget _secao(SecaoFiltro secao) => switch (secao) {
    SecaoEscolha() => Wrap(
      spacing: DsEspaco.e2,
      children: [
        for (final opcao in secao.opcoes)
          DsChip(
            rotulo: opcao.rotulo,
            selecionado: secao.multipla
                ? _rascunho.conjunto(secao.id).contains(opcao.valor)
                : _rascunho.texto(secao.id) == opcao.valor,
            aoTocar: () {
              if (secao.multipla) {
                final atual = {..._rascunho.conjunto(secao.id)};
                if (!atual.remove(opcao.valor)) atual.add(opcao.valor);
                _mudar(secao.id, atual);
              } else {
                _mudar(secao.id, opcao.valor);
              }
            },
          ),
      ],
    ),
    SecaoFaixa() => Padding(
      padding: const EdgeInsets.only(top: DsEspaco.e2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _campoFaixa(secao, minimo: true)),
          const SizedBox(width: DsEspaco.e2),
          Expanded(child: _campoFaixa(secao, minimo: false)),
        ],
      ),
    ),
    SecaoAlternar() => SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(secao.descricao, style: context.tipo.corpo),
      value: _rascunho.booleano(secao.id),
      onChanged: (v) => _mudar(secao.id, v),
    ),
  };

  Widget _campoFaixa(SecaoFaixa secao, {required bool minimo}) {
    final (controladorMin, controladorMax) = _campos[secao.id]!;
    final controlador = minimo ? controladorMin : controladorMax;
    return TextField(
      controller: controlador,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      scrollPadding: const EdgeInsets.only(bottom: 120),
      decoration: InputDecoration(
        hintText: minimo ? secao.rotuloMinimo : secao.rotuloMaximo,
      ),
      onChanged: (_) => _mudar(
        secao.id,
        FaixaValor(minimo: controladorMin.text, maximo: controladorMax.text),
      ),
    );
  }
}
