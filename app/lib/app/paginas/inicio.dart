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
    this.aoAbrirLivelo,
    this.aoAbrirProdutos,
    this.aoAbrirCashback,
    this.agora,
    this.experienciaCompacta = false,
  });

  final Api api;
  final VoidCallback? aoAbrirLojas;
  final VoidCallback? aoAbrirLivelo;
  final VoidCallback? aoAbrirProdutos;
  final VoidCallback? aoAbrirCashback;
  final DateTime Function()? agora;
  final bool experienciaCompacta;

  @override
  State<PaginaInicio> createState() => _PaginaInicioState();
}

class _PaginaInicioState extends State<PaginaInicio> {
  ResumoInicio? _resumo;
  bool _carregando = true;
  bool _falhouAtualizacao = false;

  @override
  void initState() {
    super.initState();
    _consultar();
  }

  Future<void> _consultar() async {
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
    }
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 44),
              sliver: SliverList.list(
                children: [
                  if (widget.experienciaCompacta)
                    _CabecalhoResumoCompacto(
                      resumo: resumo,
                      carregando: _carregando,
                      agora: (widget.agora ?? DateTime.now)(),
                      aoAtualizar: _carregando ? null : _consultar,
                    )
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
                  const SizedBox(height: 20),
                  widget.experienciaCompacta
                      ? _DestaqueInicioCompacto(
                          resumo: resumo,
                          agora: (widget.agora ?? DateTime.now)(),
                        )
                      : _DestaqueEstado(resumo: resumo),
                  if (widget.experienciaCompacta) ...[
                    const SizedBox(height: 30),
                    const _TituloSecao(
                      titulo: 'Seus espaços',
                      complemento: 'Um lugar para cada jornada',
                    ),
                    const SizedBox(height: 12),
                    _EspacosCompactos(
                      aoAbrirLivelo: widget.aoAbrirLivelo,
                      aoAbrirInter: widget.aoAbrirCashback,
                      aoAbrirProdutos: widget.aoAbrirProdutos,
                    ),
                    const SizedBox(height: 30),
                    const _TituloSecao(
                      titulo: 'Resumo agora',
                      complemento: 'Últimos retratos válidos',
                    ),
                    const SizedBox(height: 12),
                    _GradeMetricasCompactas(
                      resumo: resumo,
                      agora: (widget.agora ?? DateTime.now)(),
                    ),
                    const SizedBox(height: 30),
                    _AtividadeRecenteCompacta(
                      resumo: resumo,
                      agora: (widget.agora ?? DateTime.now)(),
                    ),
                  ] else ...[
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
  const _CabecalhoResumoCompacto({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CabecalhoSecaoRadar(
          sobrelinha: _dataExtensa(agora),
          titulo: _saudacao(agora),
          descricao:
              'Seus benefícios importantes, sem misturar as regras de cada fonte.',
          acao: IconButton.filledTonal(
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
        ),
        const SizedBox(height: 8),
        Text(
          'Resumo gerado ${_dataHora(resumo.geradoEm)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: CoresRadar.de(context).textoSuave,
          ),
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

class _DestaqueInicioCompacto extends StatelessWidget {
  const _DestaqueInicioCompacto({required this.resumo, required this.agora});

  final ResumoInicio resumo;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    final prioridade = _prioridade(resumo);
    final atualizado = resumo.estadoGeral == EstadoResumo.atualizado;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Container(
            color: Tokens.marcaProfunda,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SeloHeroCompacto(texto: _textoAtualizacao(resumo, agora)),
                const SizedBox(height: 14),
                Text(
                  atualizado ? 'Seu radar está atualizado.' : prioridade.titulo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  atualizado
                      ? 'Livelo, cashback e produtos continuam em leituras independentes.'
                      : prioridade.descricao,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFD7E3ED),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                _MetricasHeroCompactas(resumo: resumo),
              ],
            ),
          ),
          const Positioned(
            right: -46,
            bottom: -74,
            child: _ArcoHeroInicio(tamanho: 190),
          ),
        ],
      ),
    );
  }
}

class _SeloHeroCompacto extends StatelessWidget {
  const _SeloHeroCompacto({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 8, color: Color(0xFF55D6A3)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricasHeroCompactas extends StatelessWidget {
  const _MetricasHeroCompactas({required this.resumo});

  final ResumoInicio resumo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MetricaHero(valor: _valorLivelo(resumo), titulo: 'alertas Livelo'),
        const SizedBox(width: 8),
        _MetricaHero(
          valor: resumo.cashbackInter.estado == EstadoResumo.indisponivel
              ? '—'
              : _inteiro(resumo.cashbackInter.lojasAcompanhadas),
          titulo: 'lojas com cashback',
        ),
        const SizedBox(width: 8),
        _MetricaHero(
          valor: resumo.produtos.estado == EstadoResumo.indisponivel
              ? '—'
              : _inteiro(resumo.produtos.produtosAtivos),
          titulo: 'produtos ativos',
        ),
      ],
    );
  }
}

class _MetricaHero extends StatelessWidget {
  const _MetricaHero({required this.valor, required this.titulo});

  final String valor;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFD7E3ED),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArcoHeroInicio extends StatelessWidget {
  const _ArcoHeroInicio({required this.tamanho});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.square(
        dimension: tamanho,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8EC5F4).withValues(alpha: 0.10),
              width: 18,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8EC5F4).withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradeMetricasCompactas extends StatelessWidget {
  const _GradeMetricasCompactas({required this.resumo, required this.agora});

  final ResumoInicio resumo;
  final DateTime agora;

  @override
  Widget build(BuildContext context) {
    return _GradeResponsiva(
      maximoColunas: 2,
      larguraMinima: 150,
      itens: [
        _MetricaResumoCompacta(
          icone: Icons.storefront_outlined,
          cor: CoresRadar.de(context).acao,
          valor: _valorDisponivel(resumo.livelo.estado)
              ? _inteiro(resumo.livelo.lojasAcompanhadas)
              : '—',
          titulo: 'lojas acompanhadas',
        ),
        _MetricaResumoCompacta(
          icone: Icons.inventory_2_outlined,
          cor: CoresRadar.de(context).integracaoInter,
          valor: _valorDisponivel(resumo.produtos.estado)
              ? _inteiro(resumo.produtos.produtosAtivos)
              : '—',
          titulo: 'produtos ativos',
        ),
        _MetricaResumoCompacta(
          icone: Icons.notifications_none,
          cor: CoresRadar.de(context).atencao,
          valor: _valorLivelo(resumo),
          titulo: 'alertas relevantes',
        ),
        _MetricaResumoCompacta(
          icone: Icons.schedule_outlined,
          cor: CoresRadar.de(context).ganho,
          valor: _tempoDesde(resumo.geradoEm, agora),
          titulo: 'última atualização',
        ),
      ],
    );
  }
}

class _MetricaResumoCompacta extends StatelessWidget {
  const _MetricaResumoCompacta({
    required this.icone,
    required this.cor,
    required this.valor,
    required this.titulo,
  });
  final IconData icone;
  final Color cor;
  final String valor;
  final String titulo;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: SizedBox.square(
              dimension: 36,
              child: Icon(icone, color: cor, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: CoresRadar.de(context).textoSuave,
            ),
          ),
        ],
      ),
    ),
  );
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
      ),
      const SizedBox(height: 12),
      Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        child: Column(
          children: [
            _AtividadeLinha(
              icone: Icons.card_giftcard_outlined,
              cor: CoresRadar.de(context).acao,
              titulo: resumo.livelo.estado == EstadoResumo.atualizado
                  ? 'Livelo concluída'
                  : 'Livelo em leitura',
              detalhe:
                  '${_inteiro(resumo.livelo.lojasAcompanhadas)} lojas acompanhadas',
              quando: _tempoDesde(
                resumo.livelo.ultimoSucessoEm ?? resumo.geradoEm,
                agora,
              ),
            ),
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: CoresRadar.de(context).borda,
            ),
            _AtividadeLinha(
              icone: Icons.inventory_2_outlined,
              cor: CoresRadar.de(context).integracaoInter,
              titulo: resumo.produtos.estado == EstadoResumo.atualizando
                  ? 'Produtos em atualização'
                  : 'Produtos: ${_rotuloEstado(resumo.produtos.estado).toLowerCase()}',
              detalhe: resumo.produtos.estado == EstadoResumo.semDados
                  ? 'Catálogo ainda sem coleta'
                  : 'Catálogo local mantido',
              quando: _tempoDesde(
                resumo.produtos.dadosMaisRecentesEm ?? resumo.geradoEm,
                agora,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

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

class _EspacosCompactos extends StatelessWidget {
  const _EspacosCompactos({
    required this.aoAbrirLivelo,
    required this.aoAbrirInter,
    required this.aoAbrirProdutos,
  });

  final VoidCallback? aoAbrirLivelo;
  final VoidCallback? aoAbrirInter;
  final VoidCallback? aoAbrirProdutos;

  @override
  Widget build(BuildContext context) {
    final cores = CoresRadar.de(context);
    return Column(
      children: [
        _EspacoCompacto(
          chave: const Key('atalho-livelo'),
          icone: Icons.card_giftcard_outlined,
          cor: cores.acao,
          titulo: 'Livelo',
          descricao: 'Pontos, lojas, campanhas e alertas',
          aoTocar: aoAbrirLivelo,
        ),
        const SizedBox(height: 10),
        _EspacoCompacto(
          chave: const Key('atalho-inter'),
          icone: Icons.account_balance_outlined,
          cor: cores.integracaoInter,
          titulo: 'Banco Inter',
          descricao: 'Cashback e produtos em processos separados',
          aoTocar: aoAbrirInter,
        ),
        const SizedBox(height: 10),
        _EspacoCompacto(
          chave: const Key('atalho-produtos'),
          icone: Icons.search,
          cor: cores.ganho,
          titulo: 'Buscar produtos',
          descricao: 'Catálogo local das lojas selecionadas',
          aoTocar: aoAbrirProdutos,
        ),
      ],
    );
  }
}

class _EspacoCompacto extends StatelessWidget {
  const _EspacoCompacto({
    required this.chave,
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.descricao,
    required this.aoTocar,
  });

  final Key chave;
  final IconData icone;
  final Color cor;
  final String titulo;
  final String descricao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    return CartaoRadar(
      aoTocar: aoTocar,
      padding: EdgeInsets.zero,
      child: Ink(
        key: chave,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: SizedBox.square(
                dimension: 48,
                child: Icon(icone, color: cor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descricao,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CoresRadar.de(context).textoSuave,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
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
  const _TituloSecao({required this.titulo, required this.complemento});

  final String titulo;
  final String complemento;

  @override
  Widget build(BuildContext context) {
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
          descricao: _descricaoEstado(estado),
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

bool _valorDisponivel(EstadoResumo estado) =>
    estado != EstadoResumo.indisponivel;

String _valorLivelo(ResumoInicio resumo) {
  if (!_valorDisponivel(resumo.livelo.estado) ||
      resumo.livelo.ultimoSucessoEm == null) {
    return '—';
  }
  return _inteiro(resumo.livelo.alertasUltimaColeta);
}

String _textoAtualizacao(ResumoInicio resumo, DateTime agora) {
  final data = DateTime.tryParse(resumo.geradoEm)?.toLocal();
  if (data == null) return 'Radar atualizado';
  final minutos = agora.toLocal().difference(data).inMinutes;
  if (minutos <= 1) return 'Radar atualizado há pouco';
  if (minutos < 60) return 'Radar atualizado há $minutos min';
  final horas = minutos ~/ 60;
  if (horas < 24) return 'Radar atualizado há $horas h';
  return 'Radar atualizado há ${horas ~/ 24} d';
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

String _saudacao(DateTime momento) {
  if (momento.hour < 12) return 'Bom dia.';
  if (momento.hour < 18) return 'Boa tarde.';
  return 'Boa noite.';
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
