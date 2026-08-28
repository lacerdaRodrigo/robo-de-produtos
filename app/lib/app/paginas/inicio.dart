import 'package:flutter/material.dart';

import '../../core/api/api.dart';
import '../../core/api/modelos.dart';
import '../componentes/estados.dart';
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
  });

  final Api api;
  final VoidCallback? aoAbrirLojas;
  final VoidCallback? aoAbrirLivelo;
  final VoidCallback? aoAbrirProdutos;
  final VoidCallback? aoAbrirCashback;
  final DateTime Function()? agora;

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
                  const SizedBox(height: 30),
                  const _TituloSecao(
                    titulo: 'Estado por domínio',
                    complemento: 'Dados reais',
                  ),
                  const SizedBox(height: 12),
                  _EstadoDominios(resumo: resumo),
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
          cor: cores.acao,
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
    final cores = CoresRadar.de(context);
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
  EstadoResumo.indisponivel || EstadoResumo.falhaRecente =>
    CoresRadar.de(context).perigo,
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
