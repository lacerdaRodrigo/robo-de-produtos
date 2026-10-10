import 'package:flutter/material.dart';

import '../componentes/ds_estados.dart';
import '../componentes/ds_navegacao.dart';
import '../fundacao/ds_medidas.dart';
import '../fundacao/ds_tema.dart';
import 'ds_folha.dart';

// ---------------------------------------------------------------------------
// Contrato de dados
// ---------------------------------------------------------------------------

/// Uma medição já pronta para exibir. Os adaptadores formatam; a folha não
/// conhece Livelo, Pichau nem Inter.
@immutable
class LinhaHistorico {
  const LinhaHistorico({
    required this.momento,
    required this.valorPrincipal,
    this.secundarios = const <String>[],
    this.status,
    this.destaque = false,
  });

  /// "Hoje, 14:05", "08/10, 14:02".
  final String momento;
  final String valorPrincipal;

  /// "Cartão R$ 4.799,90", "Cashback 8%", "Clube 10 pts/R$ 1".
  final List<String> secundarios;

  /// "Coleta completa", "Completa", "Menor do período".
  final String? status;

  /// Marca a linha como o melhor valor do período.
  final bool destaque;
}

@immutable
class MetricaHistorico {
  const MetricaHistorico(this.rotulo, this.valor);
  final String rotulo;
  final String valor;
}

@immutable
class PaginaHistorico {
  const PaginaHistorico({
    required this.linhas,
    required this.pagina,
    this.resumo = const <MetricaHistorico>[],
    this.totalPaginas,
    this.temProxima = false,
    this.nota,
  });

  final List<LinhaHistorico> linhas;
  final int pagina;
  final List<MetricaHistorico> resumo;
  final int? totalPaginas;
  final bool temProxima;

  /// Texto curto acima das linhas ("Últimos 30 dias · somente leitura").
  final String? nota;
}

/// O que cada domínio implementa para usar a folha. Ver os adaptadores em
/// `features/<dominio>/adaptadores_ds.dart`.
abstract interface class FonteHistorico {
  Future<PaginaHistorico> carregar(int pagina);
}

/// Para APIs que devolvem o histórico inteiro de uma vez (Livelo): carrega
/// uma vez e pagina localmente de [porPagina] em [porPagina].
class FonteHistoricoLocal implements FonteHistorico {
  FonteHistoricoLocal({
    required Future<(List<LinhaHistorico>, List<MetricaHistorico>)> Function()
    carregarTudo,
    this.porPagina = 5,
    this.nota,
  }) : _carregarTudo = carregarTudo;

  final Future<(List<LinhaHistorico>, List<MetricaHistorico>)> Function()
  _carregarTudo;
  final int porPagina;
  final String? nota;
  (List<LinhaHistorico>, List<MetricaHistorico>)? _cache;

  @override
  Future<PaginaHistorico> carregar(int pagina) async {
    final (linhas, resumo) = _cache ??= await _carregarTudo();
    final total = linhas.isEmpty ? 1 : (linhas.length + porPagina - 1) ~/ porPagina;
    final atual = pagina.clamp(1, total);
    final inicio = (atual - 1) * porPagina;
    final fim = (inicio + porPagina).clamp(0, linhas.length);
    return PaginaHistorico(
      linhas: linhas.sublist(inicio, fim),
      pagina: atual,
      totalPaginas: total,
      resumo: resumo,
      nota: nota,
    );
  }
}

// ---------------------------------------------------------------------------
// Folha
// ---------------------------------------------------------------------------

/// UMA folha de histórico para o app inteiro.
///
/// ```dart
/// FolhaHistorico.mostrar(
///   context,
///   subtitulo: '${produto.nome} · Pichau',
///   fonte: FonteHistoricoPichau(api: api, idExterno: produto.idExterno),
/// );
/// ```
abstract final class FolhaHistorico {
  static Future<void> mostrar(
    BuildContext context, {
    required String subtitulo,
    required FonteHistorico fonte,
    String titulo = 'Histórico de preço',
    bool mostrarVoltar = true,
  }) => DsFolha.mostrar<void>(
    context,
    titulo: titulo,
    subtitulo: subtitulo,
    mostrarVoltar: mostrarVoltar,
    corpo: (_) => CorpoHistorico(fonte: fonte),
  );
}

/// Corpo da folha, exposto para testes e para uso em página cheia.
class CorpoHistorico extends StatefulWidget {
  const CorpoHistorico({super.key, required this.fonte});

  final FonteHistorico fonte;

  @override
  State<CorpoHistorico> createState() => _EstadoCorpoHistorico();
}

class _EstadoCorpoHistorico extends State<CorpoHistorico> {
  PaginaHistorico? _dados;
  Object? _erro;
  var _carregando = true;
  var _pagina = 1;

  @override
  void initState() {
    super.initState();
    _carregar(1);
  }

  Future<void> _carregar(int pagina) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final dados = await widget.fonte.carregar(pagina);
      if (!mounted) return;
      setState(() {
        _dados = dados;
        _pagina = dados.pagina;
      });
    } catch (erro) {
      if (mounted) setState(() => _erro = erro);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dados = _dados;
    if (_erro != null && dados == null) {
      return DsEstadoErro(
        texto: 'Não foi possível carregar o histórico.',
        aoTentarDeNovo: () => _carregar(_pagina),
      );
    }
    if (dados == null) return DsSkeleton.linhas(5);
    if (dados.linhas.isEmpty && dados.pagina == 1) {
      return const DsEstadoVazio(
        titulo: 'Sem medições ainda',
        texto: 'O histórico aparece depois das próximas coletas.',
        icone: Icons.show_chart_rounded,
      );
    }

    final c = context.cores;
    final t = context.tipo;
    final temPaginas =
        (dados.totalPaginas ?? 1) > 1 || dados.temProxima || dados.pagina > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (dados.resumo.isNotEmpty) ...[
          Row(
            children: [
              for (var i = 0; i < dados.resumo.length; i++) ...[
                if (i > 0) const SizedBox(width: DsEspaco.e2),
                Expanded(child: _Metrica(metrica: dados.resumo[i])),
              ],
            ],
          ),
          const SizedBox(height: DsEspaco.e4),
        ],
        if (dados.nota != null) ...[
          Text(dados.nota!, style: t.apoio),
          const SizedBox(height: DsEspaco.e2),
        ],
        if (_erro != null)
          const Padding(
            padding: EdgeInsets.only(bottom: DsEspaco.e3),
            child: DsFaixa(texto: 'Não foi possível trocar de página.'),
          ),
        AnimatedOpacity(
          opacity: _carregando ? 0.4 : 1,
          duration: DsMovimento.de(
            DsMovimento.toque,
            reduzido: context.movimentoReduzido,
          ),
          child: Column(
            children: [
              for (var i = 0; i < dados.linhas.length; i++)
                _Linha(
                  linha: dados.linhas[i],
                  ultima: i == dados.linhas.length - 1,
                  borda: c.borda1,
                ),
            ],
          ),
        ),
        if (temPaginas) ...[
          const SizedBox(height: DsEspaco.e3),
          DsPaginacao(
            pagina: _pagina,
            totalPaginas: dados.totalPaginas,
            temProxima: dados.temProxima,
            aoMudar: _carregando ? (_) {} : _carregar,
          ),
        ],
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.metrica});
  final MetricaHistorico metrica;

  @override
  Widget build(BuildContext context) {
    final t = context.tipo;
    return Container(
      padding: const EdgeInsets.all(DsEspaco.e3),
      decoration: BoxDecoration(
        color: context.cores.superficie2,
        borderRadius: BorderRadius.circular(DsRaio.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metrica.rotulo, style: t.apoio.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(metrica.valor, style: t.numeroLinha.copyWith(fontSize: 18, height: 24 / 18)),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.linha, required this.ultima, required this.borda});

  final LinhaHistorico linha;
  final bool ultima;
  final Color borda;

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipo;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DsEspaco.e3),
        decoration: BoxDecoration(
          border: ultima ? null : Border(bottom: BorderSide(color: borda)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(linha.momento, style: t.rotulo),
                  if (linha.status != null)
                    Text(
                      linha.status!,
                      style: t.apoio.copyWith(
                        color: linha.destaque ? c.sucesso : c.texto2,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: DsEspaco.e3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  linha.valorPrincipal,
                  style: t.numeroLinha.copyWith(
                    color: linha.destaque ? c.sucesso : c.texto1,
                  ),
                ),
                for (final secundario in linha.secundarios)
                  Text(
                    secundario,
                    style: t.apoio.copyWith(
                      fontFeatures: t.numeroLinha.fontFeatures,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
