import 'package:flutter/material.dart';

import 'design_system.dart';

/// Vitrine do Radar DS dentro do app: todos os componentes com dados
/// ilustrativos, nos dois temas, para revisão visual e aprovação.
///
/// Abrir de qualquer lugar (ex.: Perfil > Laboratório):
/// `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VitrineDs()));`
class VitrineDs extends StatefulWidget {
  const VitrineDs({super.key});

  @override
  State<VitrineDs> createState() => _EstadoVitrineDs();
}

class _EstadoVitrineDs extends State<VitrineDs> {
  var _escuro = false;
  var _recorte = 'todos';
  final _registro = RegistroFiltros({
    EscopoFiltro.pichau: const EspecFiltros(
      origem: 'Pichau',
      secoes: [
        SecaoEscolha(
          id: 'ordenar',
          titulo: 'Ordenar por',
          ordenacao: true,
          padraoUnico: 'preco',
          opcoes: [
            OpcaoFiltro('nome', 'Nome'),
            OpcaoFiltro('preco', 'Menor preço Pix'),
            OpcaoFiltro('desconto', 'Maior desconto Pix'),
          ],
        ),
        SecaoEscolha(
          id: 'disponibilidade',
          titulo: 'Disponibilidade',
          opcoes: [
            OpcaoFiltro('todas', 'Todos'),
            OpcaoFiltro('disponiveis', 'Disponíveis'),
            OpcaoFiltro('esgotados', 'Esgotados'),
            OpcaoFiltro('fora_catalogo', 'Fora do catálogo'),
          ],
        ),
        SecaoFaixa(id: 'preco', titulo: 'Faixa de preço Pix (R\$)'),
      ],
    ),
  });

  @override
  void dispose() {
    _registro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EscopoDs(
      filtros: _registro,
      child: Theme(
        data: _escuro ? DsTema.escuro() : DsTema.claro(),
        child: Builder(builder: _pagina),
      ),
    );
  }

  Widget _pagina(BuildContext context) {
    final c = context.cores;
    final t = context.tipo;
    Widget titulo(String texto) => Padding(
      padding: const EdgeInsets.only(top: DsEspaco.e8, bottom: DsEspaco.e3),
      child: Text(texto.toUpperCase(), style: t.kicker),
    );

    return Scaffold(
      backgroundColor: c.fundoApp,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: DsEspaco.e10),
          children: [
            DsCabecalho(
              kicker: 'Radar DS',
              titulo: 'Vitrine',
              acoes: [
                DsBotaoIcone(
                  icone: _escuro
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  rotulo: _escuro ? 'Tema claro' : 'Tema escuro',
                  aoTocar: () => setState(() => _escuro = !_escuro),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DsEspaco.margemTela,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DsCampoBusca(
                    dica: 'Buscar PC ou SKU',
                    escopoFiltros: EscopoFiltro.pichau,
                    contarResultados: (_) async => 37,
                    aoBuscar: (_) {},
                  ),
                  const SizedBox(height: DsEspaco.e3),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: DsSegmentado<String>(
                      opcoes: const [
                        DsOpcao('todos', 'Todos'),
                        DsOpcao('radar', 'No radar', contagem: 4),
                      ],
                      selecionado: _recorte,
                      aoMudar: (v) => setState(() => _recorte = v),
                    ),
                  ),
                  titulo('Cartão de oferta'),
                  _cartaoPichau(context),
                  const SizedBox(height: DsEspaco.e3),
                  _cartaoLivelo(context),
                  titulo('Botões'),
                  Wrap(
                    spacing: DsEspaco.e2,
                    runSpacing: DsEspaco.e2,
                    children: [
                      DsBotao(rotulo: 'Aplicar filtros', aoTocar: () {}),
                      DsBotao(
                        rotulo: 'Ver histórico',
                        variante: DsVarianteBotao.tonal,
                        aoTocar: () {},
                      ),
                      DsBotao(
                        rotulo: 'Limpar',
                        variante: DsVarianteBotao.contorno,
                        aoTocar: () {},
                      ),
                      DsBotao(
                        rotulo: 'Abrir na loja',
                        variante: DsVarianteBotao.texto,
                        aoTocar: () {},
                      ),
                    ],
                  ),
                  titulo('Selos'),
                  const Wrap(
                    spacing: DsEspaco.e2,
                    runSpacing: DsEspaco.e2,
                    children: [
                      DsSelo(texto: 'Mudou', tom: DsTom.sinal),
                      DsSelo(texto: 'Disponível', tom: DsTom.sucesso),
                      DsSelo(texto: 'Coleta parcial', tom: DsTom.atencao),
                      DsSelo(texto: 'Esgotado', tom: DsTom.perigo),
                      DsSelo(texto: 'Clube', tom: DsTom.primaria),
                    ],
                  ),
                  titulo('Estados'),
                  const DsFaixa(
                    texto: 'Coleta parcial às 14:05. Alguns preços podem '
                        'estar desatualizados.',
                  ),
                  DsEstadoVazio(
                    titulo: 'Nada com esses filtros',
                    texto: 'Tente outra faixa de preço ou limpe os filtros.',
                    rotuloAcao: 'Limpar filtros',
                    aoAcionar: () =>
                        context.filtros(EscopoFiltro.pichau).limpar(),
                  ),
                  DsSkeleton.cartao(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DsBarraNavegacao(
        destinoAtual: DsDestino.explorar,
        novidadeNoRadar: true,
        aoMudar: (_) {},
      ),
    );
  }

  Widget _cartaoPichau(BuildContext context) => DsCartaoOferta(
    origem: 'Pichau · SKU 81273',
    titulo: 'PC Gamer Afrodite, Ryzen 5 5600, RTX 4060 8GB, 16GB, SSD 480GB',
    selo: const DsSelo(texto: 'Disponível', tom: DsTom.sucesso),
    valores: const [
      DsValor(
        rotulo: 'Pix',
        valor: r'R$ 4.299,90',
        variacao: DsVariacao.melhorou,
        textoVariacao: r'R$ 500 em 7 dias',
      ),
      DsValor(
        rotulo: 'Cartão',
        valor: r'R$ 4.799,90',
        tamanho: DsTamanhoValor.secundario,
      ),
    ],
    acompanhar: DsBotaoAcompanhar(
      acompanhado: true,
      nomeItem: 'PC Gamer Afrodite',
      aoAlternar: (_) => Future<void>.delayed(const Duration(milliseconds: 400)),
    ),
    acoes: [
      DsBotaoIcone(
        icone: Icons.show_chart_rounded,
        rotulo: 'Histórico',
        aoTocar: () => FolhaHistorico.mostrar(
          context,
          subtitulo: 'PC Gamer Afrodite · Pichau',
          fonte: _FonteDemo(),
        ),
      ),
      DsBotaoIcone(
        icone: Icons.open_in_new_rounded,
        rotulo: 'Abrir na loja',
        aoTocar: () {},
      ),
    ],
  );

  Widget _cartaoLivelo(BuildContext context) => DsCartaoOferta(
    origem: 'Livelo · Moda',
    titulo: 'Renner',
    selo: const DsSelo(texto: 'Mudou', tom: DsTom.sinal),
    meta: 'Até 12/10 · Hoje, 14:05',
    valores: const [
      DsValor(
        rotulo: 'Pontos',
        valor: r'8 pts/R$ 1',
        variacao: DsVariacao.melhorou,
        subiu: true,
        textoVariacao: 'era 4 pts',
      ),
      DsValor(
        rotulo: 'Clube',
        valor: r'10 pts/R$ 1',
        tamanho: DsTamanhoValor.secundario,
      ),
    ],
    acompanhar: DsBotaoAcompanhar(
      acompanhado: false,
      nomeItem: 'Renner',
      aoAlternar: (_) => Future<void>.delayed(const Duration(milliseconds: 400)),
    ),
    acoes: [
      DsBotao(
        rotulo: 'Condições',
        variante: DsVarianteBotao.texto,
        aoTocar: () => DsFolha.mostrar<void>(
          context,
          titulo: 'Condições',
          subtitulo: 'Renner · Livelo',
          mostrarVoltar: true,
          corpo: (contexto) => Text(
            'Texto ilustrativo. As condições reais vêm da API e são exibidas '
            'na íntegra, sem resumo.',
            style: contexto.tipo.corpo,
          ),
        ),
      ),
    ],
  );
}

class _FonteDemo extends FonteHistoricoLocal {
  _FonteDemo()
    : super(
        nota: 'Dados ilustrativos',
        carregarTudo: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          const dados = <(String, String, String)>[
            ('Hoje, 14:05', r'R$ 4.299,90', r'R$ 4.799,90'),
            ('Ontem, 22:10', r'R$ 4.799,90', r'R$ 5.299,90'),
            ('08/10, 14:02', r'R$ 4.199,90', r'R$ 4.699,90'),
            ('07/10, 22:01', r'R$ 4.349,90', r'R$ 4.849,90'),
            ('07/10, 06:00', r'R$ 4.349,90', r'R$ 4.849,90'),
            ('06/10, 14:03', r'R$ 4.499,90', r'R$ 4.999,90'),
            ('05/10, 22:00', r'R$ 4.599,90', r'R$ 5.099,90'),
          ];
          final linhas = [
            for (final (momento, pix, cartao) in dados)
              LinhaHistorico(
                momento: momento,
                valorPrincipal: pix,
                secundarios: ['Cartão $cartao'],
                status: pix == r'R$ 4.199,90' ? 'Menor do período' : null,
                destaque: pix == r'R$ 4.199,90',
              ),
          ];
          return (
            linhas,
            const [
              MetricaHistorico('Menor em 30 dias', r'R$ 4.199,90'),
              MetricaHistorico('Maior em 30 dias', r'R$ 4.799,90'),
            ],
          );
        },
      );
}
