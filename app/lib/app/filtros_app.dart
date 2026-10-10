import '../design_system/design_system.dart';
import '../features/inter/controlador_cashback_inter.dart';
import '../features/livelo/controlador_catalogo_livelo.dart';
import '../features/pichau/controlador_catalogo_pichau.dart';

/// Ids das seções, para as telas lerem os valores aplicados sem strings
/// soltas: `context.filtros(EscopoFiltro.pichau).value.texto(IdFiltro.ordenar)`.
abstract final class IdFiltro {
  static const ordenar = 'ordenar';
  static const disponibilidade = 'disponibilidade';
  static const preco = 'preco';
  static const origem = 'origem';
  static const tipo = 'tipo';
}

/// Especificação de TODOS os filtros do app. Mudou uma opção? Muda aqui e
/// todas as telas do escopo acompanham.
///
/// Categorias externas do Inter vêm da API e ficam fora desta lista até a
/// `SecaoEscolha` ganhar opções dinâmicas (ver docs/guias/design-system.md).
final Map<EscopoFiltro, EspecFiltros> especsFiltrosApp = {
  EscopoFiltro.pichau: EspecFiltros(
    origem: 'Pichau',
    secoes: [
      SecaoEscolha(
        id: IdFiltro.ordenar,
        titulo: 'Ordenar por',
        ordenacao: true,
        padraoUnico: OrdenacaoPichau.preco.codigo,
        opcoes: [
          for (final o in OrdenacaoPichau.values) OpcaoFiltro(o.codigo, o.rotulo),
        ],
      ),
      SecaoEscolha(
        id: IdFiltro.disponibilidade,
        titulo: 'Disponibilidade',
        opcoes: [
          for (final d in DisponibilidadePichau.values)
            OpcaoFiltro(d.codigo, d.rotulo),
        ],
      ),
      const SecaoFaixa(id: IdFiltro.preco, titulo: 'Faixa de preço Pix (R\$)'),
    ],
  ),
  EscopoFiltro.compreDireto: const EspecFiltros(
    origem: 'Compre direto',
    secoes: [
      SecaoEscolha(
        id: IdFiltro.ordenar,
        titulo: 'Ordenar por',
        ordenacao: true,
        opcoes: [
          OpcaoFiltro('preco', 'Menor preço por loja'),
          OpcaoFiltro('nome', 'Nome por loja'),
        ],
      ),
      SecaoFaixa(id: IdFiltro.preco, titulo: 'Faixa de preço (R\$)'),
    ],
  ),
  EscopoFiltro.parceirosInter: EspecFiltros(
    origem: 'Sites parceiros',
    secoes: [
      SecaoEscolha(
        id: IdFiltro.ordenar,
        titulo: 'Ordenar por',
        ordenacao: true,
        opcoes: [
          for (final o in OrdenacaoCashbackInter.values)
            OpcaoFiltro(o.codigo, o.rotulo),
        ],
      ),
    ],
  ),
  EscopoFiltro.livelo: EspecFiltros(
    origem: 'Livelo',
    secoes: [
      SecaoEscolha(
        id: IdFiltro.ordenar,
        titulo: 'Ordenar por',
        ordenacao: true,
        opcoes: [
          for (final o in OrdenacaoCatalogoLivelo.values)
            OpcaoFiltro(o.codigo, o.rotulo),
        ],
      ),
    ],
  ),
  EscopoFiltro.meuRadar: const EspecFiltros(
    origem: 'Meu radar',
    secoes: [_secaoOrigem],
  ),
  EscopoFiltro.central: const EspecFiltros(
    origem: 'Central',
    secoes: [
      _secaoOrigem,
      SecaoEscolha(
        id: IdFiltro.tipo,
        titulo: 'Tipo de mudança',
        opcoes: [
          OpcaoFiltro('todos', 'Todos'),
          OpcaoFiltro('preco', 'Preço'),
          OpcaoFiltro('cashback', 'Cashback'),
          OpcaoFiltro('pontuacao', 'Pontos'),
        ],
      ),
    ],
  ),
};

const _secaoOrigem = SecaoEscolha(
  id: IdFiltro.origem,
  titulo: 'Origem',
  opcoes: [
    OpcaoFiltro('todos', 'Todas'),
    OpcaoFiltro('inter_cashback', 'Sites parceiros'),
    OpcaoFiltro('inter_produto', 'Compre direto'),
    OpcaoFiltro('livelo', 'Livelo'),
    OpcaoFiltro('pichau', 'Pichau'),
  ],
);

/// Cria o registro global. Chamar uma vez no estado do `App`.
RegistroFiltros criarRegistroFiltrosApp() => RegistroFiltros(especsFiltrosApp);
