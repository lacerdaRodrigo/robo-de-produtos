import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';
import '../componentes/fundacao_visual.dart';
import '../identidade/logo_radar.dart';
import '../tema/tokens.dart';

/// Resumo real do dia. Atualiza somente pela API e mantém o último retrato
/// recebido caso uma nova tentativa falhe.
class PaginaInicio extends StatefulWidget {
  const PaginaInicio({
    super.key,
    required this.api,
    this.aoAbrirLojas,
    this.aoAbrirProgramas,
    this.aoAbrirLivelo,
    this.aoAbrirProdutos,
    this.aoAbrirCashback,
    this.agora,
    this.experienciaCompacta = false,
    this.ativa = true,
  });

  final Api api;
  final VoidCallback? aoAbrirLojas;
  final VoidCallback? aoAbrirProgramas;
  final VoidCallback? aoAbrirLivelo;
  final VoidCallback? aoAbrirProdutos;
  final VoidCallback? aoAbrirCashback;
  final DateTime Function()? agora;
  final bool experienciaCompacta;
  final bool ativa;

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio>
    with WidgetsBindingObserver {
  ResumoInicio? _resumo;
  bool _carregando = true;
  bool _falhouAtualizacao = false;
  bool _consultando = false;
  bool _emPrimeiroPlano = true;
  Timer? _polling;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _consultar();
    _configurarPolling();
  }

  @override
  void didUpdateWidget(covariant PaginaInicio antigo) {
    super.didUpdateWidget(antigo);
    _configurarPolling();
    if (widget.ativa && !antigo.ativa && _emPrimeiroPlano) _consultar();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    _emPrimeiroPlano = estado == AppLifecycleState.resumed;
    if (_emPrimeiroPlano && widget.ativa) _consultar();
  }

  void _configurarPolling() {
    _polling?.cancel();
    if (!widget.experienciaCompacta || !widget.ativa) return;
    _polling = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_emPrimeiroPlano) _consultar();
    });
  }

  Future<void> _consultar() async {
    if (_consultando || !widget.ativa || !_emPrimeiroPlano) return;
    _consultando = true;
    if (_resumo != null && mounted) {
      setState(() {
        _carregando = true;
        _falhouAtualizacao = false;
      });
    }
    try {
      final resumo = await widget.api.resumo();
      if (!mounted) return;
      setState(() {
        _resumo = resumo;
        _carregando = false;
        _falhouAtualizacao = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _falhouAtualizacao = true;
      });
    } finally {
      _consultando = false;
    }
  }

  @override
  void dispose() {
    _polling?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resumo = _resumo;
    if (resumo == null && _carregando) {
      return const Carregando(mensagem: 'Carregando seu radar…');
    }
    if (resumo == null) {
      return EstadoFalha(
        mensagem:
            'Não foi possível carregar o resumo. O último dado válido não foi alterado.',
        voltar: _consultar,
      );
    }

    return RefreshIndicator(
      onRefresh: _consultar,
      child: CustomScrollView(
        key: const Key('resumo-inicio'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverPadding(
              padding: widget.experienciaCompacta
                  ? const EdgeInsets.fromLTRB(18, 22, 18, 38)
                  : const EdgeInsets.fromLTRB(20, 24, 20, 44),
              sliver: SliverList.list(
                children: [
                  if (widget.experienciaCompacta)
                    const _CabecalhoResumoCompacto()
                  else
                    _CabecalhoResumo(
                      resumo: resumo,
                      carregando: _carregando,
                      agora: (widget.agora ?? DateTime.now)(),
                      aoAtualizar: _carregando ? null : _consultar,
                    ),
                  if (_falhouAtualizacao) ...[
                    const SizedBox(height: 16),
                    _AvisoFalhaAtualizacao(aoTentarNovamente: _consultar),
                  ],
                  if (widget.experienciaCompacta) ...[
                    const SizedBox(height: 25),
                    _TituloSecao(
                      titulo: 'Seus serviços',
                      complemento: 'Estados independentes',
                      compactoMobile: true,
                      acao: widget.aoAbrirProgramas == null
                          ? null
                          : TextButton(
                              onPressed: widget.aoAbrirProgramas,
                              child: const Text('Ver todos'),
                            ),
                    ),
                    const SizedBox(height: 12),
                    _ServicosResumoCompacto(
                      resumo: resumo,
                      aoAbrirLivelo: widget.aoAbrirLivelo,
                      aoAbrirInter: widget.aoAbrirCashback,
                    ),
                    const SizedBox(height: 12),
                    _AcoesRapidasResumo(
                      aoAbrirProdutos: widget.aoAbrirProdutos,
                      aoAbrirServicos: widget.aoAbrirProgramas,
                    ),
                    const SizedBox(height: 25),
                    _AtividadeRecenteCompacta(
                      resumo: resumo,
                      agora: (widget.agora ?? DateTime.now)(),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    _DestaqueEstado(resumo: resumo),
                    const SizedBox(height: 20),
                    _GradeMetricas(resumo: resumo),
                    const SizedBox(height: 30),
                    const _TituloSecao(
                      titulo: 'Atalhos',
                      complemento: 'Fixos nesta fase',
                    ),
                    const SizedBox(height: 12),
                    _GradeAtalhos(
                      aoAbrirLojas: widget.aoAbrirLojas,
                      aoAbrirLivelo: widget.aoAbrirLivelo,
                      aoAbrirProdutos: widget.aoAbrirProdutos,
                      aoAbrirCashback: widget.aoAbrirCashback,
                    ),
                  ],
                  if (!widget.experienciaCompacta) ...[
                    const SizedBox(height: 30),
                    const _TituloSecao(
                      titulo: 'Estado por domínio',
                      complemento: 'Dados reais',
                    ),
                    const SizedBox(height: 12),
                    _EstadoDominios(resumo: resumo),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CabecalhoResumo extends StatelessWidget {
  const _CabecalhoResumo({
    required this.resumo,
    required this.carregando,
    required this.agora,
    required this.aoAtualizar,
  });

  final ResumoInicio resumo;
  final bool carregando;
  final DateTime agora;
  final VoidCallback? aoAtualizar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Pill(texto: 'RESUMO DA API'),
              const SizedBox(height: 10),
              Text(
                'Seu radar hoje',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _dataExtensa(agora),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: cores.textoSuave),
              ),
              const SizedBox(height: 4),
              Text(
                'Resumo gerado ${_dataHora(resumo.geradoEm)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          key: const Key('atualizar-resumo'),
          tooltip: 'Atualizar resumo',
          onPressed: aoAtualizar,
          icon: carregando
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _CabecalhoResumoCompacto extends StatelessWidget {
  const _CabecalhoResumoCompacto();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CabecalhoSecaoRadar(
          sobrelinha: 'Hoje',
          titulo: 'Visão geral',
          descricao: 'Cada serviço mostra seus próprios números e avisos.',
        ),
      ],
    );
  }
}

class _AvisoFalhaAtualizacao extends StatelessWidget {
  const _AvisoFalhaAtualizacao({required this.aoTentarNovamente});

  final VoidCallback aoTentarNovamente;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Material(
      color: cores.atencao.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: cores.atencao),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'A atualização falhou. Mantivemos o último resumo recebido.',
              ),
            ),
            TextButton(
              onPressed: aoTentarNovamente,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtividadeRecenteCompacta extends StatelessWidget {
  const _AtividadeRecenteCompacta({required this.resumo, required this.agora});
  final ResumoInicio resumo;
  final DateTime agora;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _TituloSecao(
        titulo: 'Atividade recente',
        complemento: 'Pedido não é conclusão',
        compactoMobile: true,
      ),
      const SizedBox(height: 12),
      CartaoRadar(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (
              var indice = 0;
              indice < resumo.atividadeRecente.length;
              indice++
            ) ...[
              _AtividadeLinha(
                icone: _iconeAtividade(resumo.atividadeRecente[indice].dominio),
                cor: _corAtividade(
                  context,
                  resumo.atividadeRecente[indice].dominio,
                ),
                titulo: _tituloAtividade(
                  resumo.atividadeRecente[indice].dominio,
                  resumo.atividadeRecente[indice].estado,
                ),
                detalhe: _detalheAtividade(
                  resumo.atividadeRecente[indice].dominio,
                  resumo,
                ),
                quando: _tempoDesde(
                  resumo.atividadeRecente[indice].momento ?? resumo.geradoEm,
                  agora,
                ),
              ),
              if (indice != resumo.atividadeRecente.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: CoresRadar.de(context).borda,
                ),
            ],
          ],
        ),
      ),
    ],
  );
}

IconData _iconeAtividade(String dominio) => switch (dominio) {
  'livelo' => Icons.card_giftcard_outlined,
  'cashback_inter' => Icons.account_balance_outlined,
  _ => Icons.inventory_2_outlined,
};

Color _corAtividade(BuildContext context, String dominio) => dominio == 'livelo'
    ? CoresRadar.de(context).acao
    : CoresRadar.de(context).integracaoInter;

String _tituloAtividade(String dominio, String estado) => switch (dominio) {
  'livelo' => estado == 'atualizado' ? 'Livelo concluída' : 'Livelo: $estado',
  'cashback_inter' => 'Cashback: $estado',
  _ =>
    estado == 'atualizando' ? 'Produtos em atualização' : 'Produtos: $estado',
};

String _detalheAtividade(
  String dominio,
  ResumoInicio resumo,
) => switch (dominio) {
  'livelo' => '${_inteiro(resumo.livelo.lojasAcompanhadas)} lojas acompanhadas',
  'cashback_inter' =>
    '${_inteiro(resumo.cashbackInter.lojasAcompanhadas)} lojas acompanhadas',
  _ =>
    resumo.produtos.estado == EstadoResumo.semDados
        ? 'Catálogo ainda sem coleta'
        : 'Catálogo local mantido',
};

class _AtividadeLinha extends StatelessWidget {
  const _AtividadeLinha({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.detalhe,
    required this.quando,
  });
  final IconData icone;
  final Color cor;
  final String titulo;
  final String detalhe;
  final String quando;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(11),
          ),
          child: SizedBox.square(
            dimension: 34,
            child: Icon(icone, color: cor, size: 19),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                detalhe,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CoresRadar.de(context).textoSuave,
                ),
              ),
            ],
          ),
        ),
        Text(
          quando,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
          ),
        ),
      ],
    ),
  );
}

class _DestaqueEstado extends StatelessWidget {
  const _DestaqueEstado({required this.resumo});

  final ResumoInicio resumo;

  @override
  Widget build(BuildContext context) {
    final atencao = _prioridade(resumo);
    return Container(
      decoration: BoxDecoration(
        color: Tokens.marcaProfunda,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTADO DOS DADOS',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF8EC5F4),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  atencao.titulo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  atencao.descricao,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFD7E3ED),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const LogoRadar(tamanho: 76, sobreFundoEscuro: true),
        ],
      ),
    );
  }
}

class _GradeMetricas extends StatelessWidget {
  const _GradeMetricas({required this.resumo});

  final ResumoInicio resumo;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return _GradeResponsiva(
      maximoColunas: 3,
      larguraMinima: 250,
      itens: [
        _Metrica(
          icone: Icons.star_outline,
          cor: cores.acao,
          valor:
              resumo.livelo.estado == EstadoResumo.indisponivel ||
                  resumo.livelo.ultimoSucessoEm == null
              ? '—'
              : _inteiro(resumo.livelo.alertasUltimaColeta),
          titulo: 'Alertas Livelo',
          recorte: 'Última coleta válida',
        ),
        _Metrica(
          icone: Icons.savings_outlined,
          cor: cores.ganho,
          valor: resumo.cashbackInter.estado == EstadoResumo.indisponivel
              ? '—'
              : _inteiro(resumo.cashbackInter.lojasAcompanhadas),
          titulo: 'Lojas com cashback',
          recorte: 'Acompanhadas atualmente',
        ),
        _Metrica(
          icone: Icons.inventory_2_outlined,
          cor: cores.integracaoInter,
          valor: resumo.produtos.estado == EstadoResumo.indisponivel
              ? '—'
              : _inteiro(resumo.produtos.produtosAtivos),
          titulo: 'Produtos ativos',
          recorte: 'Lojas selecionadas',
        ),
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.icone,
    required this.cor,
    required this.valor,
    required this.titulo,
    required this.recorte,
  });

  final IconData icone;
  final Color cor;
  final String valor;
  final String titulo;
  final String recorte;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icone, color: cor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _Pill(texto: recorte, compacto: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              valor,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 3),
            Text(titulo, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ServicosResumoCompacto extends StatelessWidget {
  const _ServicosResumoCompacto({
    required this.resumo,
    required this.aoAbrirLivelo,
    required this.aoAbrirInter,
  });

  final ResumoInicio resumo;
  final VoidCallback? aoAbrirLivelo;
  final VoidCallback? aoAbrirInter;

  @override
  Widget build(BuildContext context) {
    final estadoInter = _estadoInter(resumo);
    return Column(
      children: [
        _CartaoDominioResumo(
          chave: const Key('resumo-servico-livelo'),
          iniciais: 'LI',
          titulo: 'Livelo',
          descricao: 'Pontos e lojas acompanhadas',
          estado: resumo.livelo.estado,
          metricas: [
            (
              'Lojas acompanhadas',
              _valorResumo(
                resumo.livelo.estado,
                resumo.livelo.lojasAcompanhadas,
              ),
            ),
            ('Último sucesso', _dataHora(resumo.livelo.ultimoSucessoEm)),
          ],
          aviso: resumo.livelo.estado == EstadoResumo.atualizado
              ? null
              : _descricaoEstado(resumo.livelo.estado),
          acao: 'Ver lojas da Livelo',
          aoTocar: aoAbrirLivelo,
        ),
        const SizedBox(height: 11),
        _CartaoDominioResumo(
          chave: const Key('resumo-servico-inter'),
          iniciais: 'BI',
          titulo: 'Banco Inter',
          descricao: 'Cashback e Compre direto',
          estado: estadoInter,
          metricas: [
            (
              'Cashback',
              _valorResumo(
                resumo.cashbackInter.estado,
                resumo.cashbackInter.lojasAcompanhadas,
                sufixo: ' acompanhadas',
              ),
            ),
            (
              'Compre direto',
              _valorResumo(
                resumo.produtos.estado,
                resumo.produtos.lojasSelecionadas,
                sufixo: ' selecionadas',
              ),
            ),
            (
              'Produtos coletados',
              _valorResumo(
                resumo.produtos.estado,
                resumo.produtos.produtosAtivos,
                sufixo: ' ativos',
              ),
            ),
          ],
          aviso:
              estadoInter == EstadoResumo.atualizado ||
                  estadoInter == EstadoResumo.atualizando
              ? null
              : _descricaoEstado(estadoInter),
          acao: 'Abrir Banco Inter',
          aoTocar: aoAbrirInter,
        ),
      ],
    );
  }
}

class _CartaoDominioResumo extends StatelessWidget {
  const _CartaoDominioResumo({
    required this.chave,
    required this.iniciais,
    required this.titulo,
    required this.descricao,
    required this.estado,
    required this.metricas,
    required this.aviso,
    required this.acao,
    required this.aoTocar,
  });

  final Key chave;
  final String iniciais;
  final String titulo;
  final String descricao;
  final EstadoResumo estado;
  final List<(String, String)> metricas;
  final String? aviso;
  final String acao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    final corEstado = _corEstado(context, estado);
    return CartaoRadar(
      aoTocar: aoTocar,
      padding: EdgeInsets.zero,
      child: Padding(
        key: chave,
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Tokens.superficieForteEscura
                        : Tokens.plumSoft,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    iniciais,
                    style: TextStyle(
                      color: cores.marca,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        descricao,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cores.textoSuave,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: _Pill(
                    texto: _rotuloEstado(estado),
                    compacto: true,
                    cor: corEstado,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Divider(height: 1, color: cores.borda),
            for (final metrica in metricas) ...[
              _LinhaMetricaDominio(rotulo: metrica.$1, valor: metrica.$2),
              Divider(height: 1, color: cores.borda),
            ],
            if (aviso != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Tokens.atencaoFundoEscuro
                      : Tokens.warningSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: cores.atencao, size: 15),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        aviso!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cores.atencao,
                          fontSize: 9,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Text(
                    acao,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Tokens.acaoForteEscura
                          : Tokens.actionStrong,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: cores.acao, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LinhaMetricaDominio extends StatelessWidget {
  const _LinhaMetricaDominio({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            rotulo,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
              fontSize: 9,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _AcoesRapidasResumo extends StatelessWidget {
  const _AcoesRapidasResumo({
    required this.aoAbrirProdutos,
    required this.aoAbrirServicos,
  });

  final VoidCallback? aoAbrirProdutos;
  final VoidCallback? aoAbrirServicos;

  @override
  Widget build(BuildContext context) {
    final produtos = FilledButton(
      key: const Key('atalho-produtos'),
      onPressed: aoAbrirProdutos,
      style: FilledButton.styleFrom(
        backgroundColor: CoresRadar.de(context).marca,
      ),
      child: const Text('Buscar produtos'),
    );
    final servicos = OutlinedButton(
      key: const Key('atalho-programas'),
      onPressed: aoAbrirServicos,
      child: const Text('Todos os serviços'),
    );
    return LayoutBuilder(
      builder: (context, limites) {
        final empilhar =
            limites.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(12) > 16;
        if (empilhar) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [produtos, const SizedBox(height: 8), servicos],
          );
        }
        return Row(
          children: [
            Expanded(child: produtos),
            const SizedBox(width: 9),
            Expanded(child: servicos),
          ],
        );
      },
    );
  }
}

class _GradeAtalhos extends StatelessWidget {
  const _GradeAtalhos({
    required this.aoAbrirLojas,
    required this.aoAbrirLivelo,
    required this.aoAbrirProdutos,
    required this.aoAbrirCashback,
  });

  final VoidCallback? aoAbrirLojas;
  final VoidCallback? aoAbrirLivelo;
  final VoidCallback? aoAbrirProdutos;
  final VoidCallback? aoAbrirCashback;

  @override
  Widget build(BuildContext context) {
    return _GradeResponsiva(
      maximoColunas: 4,
      larguraMinima: 185,
      itens: [
        _Atalho(
          chave: 'atalho-lojas',
          icone: Icons.storefront_outlined,
          titulo: 'Lojas',
          descricao: 'Escolher uma fonte',
          aoTocar: aoAbrirLojas,
        ),
        _Atalho(
          chave: 'atalho-livelo',
          icone: Icons.star_outline,
          titulo: 'Ofertas Livelo',
          descricao: 'Ver pontos acompanhados',
          aoTocar: aoAbrirLivelo,
        ),
        _Atalho(
          chave: 'atalho-produtos',
          icone: Icons.search,
          titulo: 'Buscar produto',
          descricao: 'Consultar catálogo local',
          aoTocar: aoAbrirProdutos,
        ),
        _Atalho(
          chave: 'atalho-cashback',
          icone: Icons.savings_outlined,
          titulo: 'Cashback Inter',
          descricao: 'Ver lojas acompanhadas',
          aoTocar: aoAbrirCashback,
        ),
      ],
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.chave,
    required this.icone,
    required this.titulo,
    required this.descricao,
    required this.aoTocar,
  });

  final String chave;
  final IconData icone;
  final String titulo;
  final String descricao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key(chave),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icone, color: cores.acao),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descricao,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoDominios extends StatelessWidget {
  const _EstadoDominios({required this.resumo});

  final ResumoInicio resumo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Column(
        children: [
          _LinhaDominio(
            icone: Icons.star_outline,
            titulo: 'Livelo',
            estado: resumo.livelo.estado,
            descricao: resumo.livelo.estado == EstadoResumo.indisponivel
                ? 'Não foi possível ler este domínio.'
                : '${_inteiro(resumo.livelo.lojasAcompanhadas)} lojas acompanhadas · '
                      'último sucesso ${_dataHora(resumo.livelo.ultimoSucessoEm)}',
          ),
          const Divider(height: 1),
          _LinhaDominio(
            icone: Icons.savings_outlined,
            titulo: 'Cashback Inter',
            estado: resumo.cashbackInter.estado,
            descricao: resumo.cashbackInter.estado == EstadoResumo.indisponivel
                ? 'Não foi possível ler este domínio.'
                : '${_inteiro(resumo.cashbackInter.lojasEncontradasUltimaColeta)} de '
                      '${_inteiro(resumo.cashbackInter.lojasAcompanhadas)} acompanhadas encontradas · '
                      'último sucesso ${_dataHora(resumo.cashbackInter.ultimoSucessoEm)}',
          ),
          const Divider(height: 1),
          _LinhaDominio(
            icone: Icons.inventory_2_outlined,
            titulo: 'Produtos',
            estado: resumo.produtos.estado,
            descricao: resumo.produtos.estado == EstadoResumo.indisponivel
                ? 'Não foi possível ler este domínio.'
                : '${_inteiro(resumo.produtos.lojasSelecionadas)} lojas selecionadas · '
                      '${_inteiro(resumo.produtos.lojasSemColeta)} sem coleta · '
                      'dados de ${_dataHora(resumo.produtos.dadosMaisAntigosEm)} '
                      'até ${_dataHora(resumo.produtos.dadosMaisRecentesEm)}',
          ),
        ],
      ),
    );
  }
}

class _LinhaDominio extends StatelessWidget {
  const _LinhaDominio({
    required this.icone,
    required this.titulo,
    required this.estado,
    required this.descricao,
  });

  final IconData icone;
  final String titulo;
  final EstadoResumo estado;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    final cor = _corEstado(context, estado);
    final indicador = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icone, color: cor),
    );
    final selo = _Pill(texto: _rotuloEstado(estado), compacto: true, cor: cor);
    Widget textos({required bool incluirSelo}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(descricao),
        if (incluirSelo) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: selo),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, limites) {
        final empilhar =
            limites.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 21;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              indicador,
              const SizedBox(width: 12),
              Expanded(child: textos(incluirSelo: empilhar)),
              if (!empilhar) ...[const SizedBox(width: 10), selo],
            ],
          ),
        );
      },
    );
  }
}

class _GradeResponsiva extends StatelessWidget {
  const _GradeResponsiva({
    required this.itens,
    required this.maximoColunas,
    required this.larguraMinima,
  });

  final List<Widget> itens;
  final int maximoColunas;
  final double larguraMinima;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, limites) {
        const espaco = 12.0;
        var colunas = ((limites.maxWidth + espaco) / (larguraMinima + espaco))
            .floor()
            .clamp(1, maximoColunas);
        if (MediaQuery.textScalerOf(context).scale(16) > 23) colunas = 1;
        final largura = (limites.maxWidth - espaco * (colunas - 1)) / colunas;
        return Wrap(
          spacing: espaco,
          runSpacing: espaco,
          children: [
            for (final item in itens) SizedBox(width: largura, child: item),
          ],
        );
      },
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao({
    required this.titulo,
    required this.complemento,
    this.compactoMobile = false,
    this.acao,
  });

  final String titulo;
  final String complemento;
  final bool compactoMobile;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    if (compactoMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              ?acao,
            ],
          ),
          const SizedBox(height: 5),
          Text(
            complemento,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
              fontSize: 11,
            ),
          ),
        ],
      );
    }
    final tituloWidget = Text(
      titulo,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    );
    final complementoWidget = _Pill(texto: complemento, compacto: true);
    return LayoutBuilder(
      builder: (context, limites) {
        final empilhar =
            limites.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(16) > 21;
        if (empilhar) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tituloWidget,
              const SizedBox(height: 8),
              complementoWidget,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: tituloWidget),
            const SizedBox(width: 12),
            complementoWidget,
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.texto, this.compacto = false, this.cor});

  final String texto;
  final bool compacto;
  final Color? cor;

  @override
  Widget build(BuildContext context) {
    final base = cor ?? CoresRadar.de(context).acao;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 9 : 11,
        vertical: compacto ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: base,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

({String titulo, String descricao}) _prioridade(ResumoInicio resumo) {
  final dominios = <(String, EstadoResumo)>[
    ('Livelo', resumo.livelo.estado),
    ('Cashback Inter', resumo.cashbackInter.estado),
    ('Produtos', resumo.produtos.estado),
  ];
  const ordem = <EstadoResumo>[
    EstadoResumo.indisponivel,
    EstadoResumo.falhaRecente,
    EstadoResumo.parcial,
    EstadoResumo.degradado,
    EstadoResumo.atualizando,
    EstadoResumo.atrasado,
    EstadoResumo.semDados,
  ];
  for (final estado in ordem) {
    for (final dominio in dominios) {
      if (dominio.$2 == estado) {
        return (
          titulo: '${dominio.$1}: ${_rotuloEstado(estado).toLowerCase()}',
          descricao: dominio.$1 == 'Livelo' && estado == EstadoResumo.degradado
              ? 'A última base recebida teve qualidade reduzida. O último retrato válido foi preservado.'
              : _descricaoEstado(estado),
        );
      }
    }
  }
  return (
    titulo: 'Os três domínios estão atualizados.',
    descricao:
        'Cada cartão respeita o relógio e o último retrato válido da sua própria fonte.',
  );
}

String _descricaoEstado(EstadoResumo estado) => switch (estado) {
  EstadoResumo.indisponivel =>
    'A leitura deste domínio falhou. Os demais dados continuam independentes.',
  EstadoResumo.falhaRecente =>
    'A tentativa mais recente falhou, mas o último retrato válido foi preservado.',
  EstadoResumo.parcial =>
    'A rodada não concluiu todas as lojas; consulte os horários por domínio.',
  EstadoResumo.degradado =>
    'A fonte variou durante a coleta. Os encontrados foram atualizados sem apagar ausentes.',
  EstadoResumo.atualizando =>
    'Há uma coleta em andamento. O resumo continua mostrando o último retrato válido.',
  EstadoResumo.atrasado =>
    'O último retrato passou do intervalo esperado e permanece marcado como atrasado.',
  EstadoResumo.semDados =>
    'Ainda não existe uma coleta válida para este recorte.',
  _ => 'Os dados estão dentro do intervalo esperado.',
};

String _rotuloEstado(EstadoResumo estado) => switch (estado) {
  EstadoResumo.atualizado => 'Atualizado',
  EstadoResumo.atencao => 'Atenção',
  EstadoResumo.atrasado => 'Atrasado',
  EstadoResumo.atualizando => 'Atualizando',
  EstadoResumo.falhaRecente => 'Falha recente',
  EstadoResumo.parcial => 'Parcial',
  EstadoResumo.degradado => 'Degradado',
  EstadoResumo.semDados => 'Sem dados',
  EstadoResumo.indisponivel => 'Indisponível',
};

Color _corEstado(BuildContext context, EstadoResumo estado) => switch (estado) {
  EstadoResumo.atualizado => CoresRadar.de(context).ganho,
  EstadoResumo.atualizando => CoresRadar.de(context).acao,
  EstadoResumo.indisponivel ||
  EstadoResumo.falhaRecente => CoresRadar.de(context).perigo,
  _ => CoresRadar.de(context).atencao,
};

String _inteiro(int valor) {
  final texto = valor.toString();
  final resultado = StringBuffer();
  for (var indice = 0; indice < texto.length; indice++) {
    if (indice > 0 && (texto.length - indice) % 3 == 0) resultado.write('.');
    resultado.write(texto[indice]);
  }
  return resultado.toString();
}

String _valorResumo(EstadoResumo estado, int valor, {String sufixo = ''}) {
  if (estado == EstadoResumo.indisponivel || estado == EstadoResumo.semDados) {
    return '—';
  }
  return '${_inteiro(valor)}$sufixo';
}

EstadoResumo _estadoInter(ResumoInicio resumo) {
  const prioridade = <EstadoResumo>[
    EstadoResumo.indisponivel,
    EstadoResumo.falhaRecente,
    EstadoResumo.parcial,
    EstadoResumo.degradado,
    EstadoResumo.atualizando,
    EstadoResumo.atrasado,
    EstadoResumo.atencao,
    EstadoResumo.semDados,
    EstadoResumo.atualizado,
  ];
  final estados = {resumo.cashbackInter.estado, resumo.produtos.estado};
  return prioridade.firstWhere(estados.contains);
}

String _tempoDesde(String iso, DateTime agora) {
  final data = DateTime.tryParse(iso)?.toLocal();
  if (data == null) return '—';
  final minutos = agora.toLocal().difference(data).inMinutes;
  if (minutos <= 1) return 'agora';
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  if (horas < 24) return '${horas}h';
  return '${horas ~/ 24}d';
}

String _dataHora(String? iso) {
  final data = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (data == null) return 'ainda não disponível';
  String dois(int valor) => valor.toString().padLeft(2, '0');
  return '${dois(data.day)}/${dois(data.month)} às '
      '${dois(data.hour)}:${dois(data.minute)}';
}

String _dataExtensa(DateTime data) {
  const dias = <String>[
    'segunda-feira',
    'terça-feira',
    'quarta-feira',
    'quinta-feira',
    'sexta-feira',
    'sábado',
    'domingo',
  ];
  const meses = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  final local = data.toLocal();
  return '${dias[local.weekday - 1]}, ${local.day} de ${meses[local.month - 1]}';
}
