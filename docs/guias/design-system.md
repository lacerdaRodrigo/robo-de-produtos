# Radar DS — design system do app Flutter

> **Estado: proposta aguardando aprovação visual.** Pela regra de produto do
> [`CLAUDE.md`](../../CLAUDE.md), nenhuma tela troca de visual antes do aceite do
> responsável. A camada `app/lib/design_system/` já existe e é testada, mas o
> `MaterialApp` continua com o tema V15 até a decisão. Depois do aceite, este
> guia substitui [`design-v15.md`](design-v15.md) como contrato visual.

Referência navegável (tokens, componentes com prévia clara/escura e regras):
artefato **Radar DS** no claude.ai, compartilhado pelo responsável.
Vitrine dentro do app: `VitrineDs` (`app/lib/design_system/vitrine_ds.dart`).

## Por que

O app tinha a mesma coisa implementada várias vezes, cada uma do seu jeito:

| Conceito | Antes (V15) | Agora (Radar DS) |
|---|---|---|
| Histórico | `PaginaHistoricoProduto`, `PaginaHistoricoPichau`, `PaginaHistoricoLiveloAndroid` | `FolhaHistorico` + uma `FonteHistorico` por domínio |
| Filtros | `_FiltrosProdutosSheet`, `_FolhaFiltrosPichau`, `_FiltrosCashbackInter`, `_FolhaFiltrosAlertas`, `_FiltrosRadar` | `FolhaFiltros` + `especsFiltrosApp` |
| Estado do filtro | `setState` local de cada página (perde ao sair) | `RegistroFiltros` global, acima do `MaterialApp` |
| Folha | `FolhaRadar` + `showModalBottomSheet` espalhado | `DsFolha.mostrar` / `DsFolha.abrir` |
| Cartão | `CartaoRadar`, `cartao_produto`, `cartao_livelo`, `cartao_catalogo_livelo`, `cartao_cashback_inter` | `DsCartaoOferta` |
| Cores | `Tokens` com ~60 aliases duplicados | `DsCores` com 21 papéis semânticos |

## Identidade

**Sinal claro.** Interface neutra, uma cor de ação e uma cor de sinal que só
aparece quando algo mudou.

| Papel | Claro | Escuro |
|---|---|---|
| `fundoApp` | `#F4F5F9` | `#0D0F15` |
| `superficie1` (cartão, folha, campo) | `#FFFFFF` | `#161922` |
| `superficie2` (trilho, chip, skeleton) | `#EBEDF3` | `#1F2330` |
| `texto1` | `#11131A` | `#F1F3F8` |
| `texto2` (metadados) | `#565C6C` | `#A3A9BA` |
| `primaria` (cobalto: ação, seleção, foco) | `#2E45E6` | `#8C9BFF` |
| `sinal` (lima: Mudou/Novo/Não lido) | `#CFF54A` | `#D6F86B` |
| `sucesso` / `atencao` / `perigo` | `#0B7A55` / `#8A5700` / `#B42A35` | `#5BD6A4` / `#F2C15C` / `#FF8A93` |

Todos os pares de texto passam 4,5:1 nos dois temas; bordas de controle (`borda2`)
passam 3:1. Texto sobre `sinal` usa sempre `sobreSinal`.

Tipografia: **Plus Jakarta Sans** (OFL, `app/assets/fonts/plus_jakarta_sans.ttf`),
números tabulares em preços. Escala: display 32, título de tela 24, título de
seção 18, título de item 16, corpo 15, rótulo 13, apoio 12, preço 28/20/14.
Espaço em grade de 4 (`DsEspaco`), raios por função (`DsRaio`: 8/12/16/24/pílula),
movimento em `DsMovimento` respeitando movimento reduzido.

O símbolo da etiqueta foi mantido e apenas recolorido para o cobalto.

## Estrutura

```text
app/lib/design_system/
├── design_system.dart          # import único
├── fundacao/                   # DsCores, DsTipo, DsEspaco, DsRaio, DsMovimento, DsTema, DsFormato
├── componentes/                # DsBotao, DsBotaoIcone, DsChip, DsSelo, DsSegmentado, DsValor,
│                               # DsCampoBusca, DsCartaoOferta, DsBotaoAcompanhar,
│                               # DsCabecalho, DsBarraNavegacao, DsPaginacao, estados, DsAviso
├── folhas/                     # DsFolha, FolhaHistorico (+ FonteHistorico), FolhaFiltros
├── estado/filtros.dart         # EscopoFiltro, EspecFiltros, RegistroFiltros, EscopoDs
└── vitrine_ds.dart             # galeria para revisão
app/lib/app/filtros_app.dart    # especificação de TODOS os filtros do app
app/lib/features/*/historico_ds.dart  # adaptadores de histórico por domínio
```

Regra: uma feature nunca chama `showModalBottomSheet`, nunca desenha um cartão
com `BoxDecoration` próprio e nunca declara `Color(0x…)`. Se faltar algo, o
componente entra no DS primeiro.

## Como os componentes globais funcionam

### Histórico (um para o app inteiro)

```dart
FolhaHistorico.mostrar(
  context,
  subtitulo: '${produto.nome} · Pichau',
  fonte: FonteHistoricoPichau(api: api, produto: produto),
);
```

`FonteHistorico.carregar(pagina)` devolve `PaginaHistorico` com resumo,
linhas já formatadas e paginação. Paginação remota (Compre direto, Pichau) e
local (`FonteHistoricoLocal`, Livelo) usam o mesmo contrato. Estados de
carregando, vazio, erro e erro ao trocar de página são da folha.

### Filtros (um para o app inteiro, estado global)

1. A especificação de cada escopo fica em `especsFiltrosApp`.
2. O `RegistroFiltros` é criado uma vez e provido por `EscopoDs` acima do
   `MaterialApp`.
3. Qualquer tela abre `FolhaFiltros.mostrar(context, escopo: …)` ou usa
   `DsCampoBusca(escopoFiltros: …)`, que já traz o botão e o contador.
4. A tela escuta `context.filtros(escopo)` (um `ValueNotifier`) e refaz a
   consulta quando o valor muda.

Como o estado mora acima do `MaterialApp`, ele sobrevive a navegação, troca de
aba e folhas no navigator raiz; o contador mostra o mesmo número em qualquer
lugar. `RegistroFiltros.limparTudo()` deve ser chamado ao sair da conta.

Lacuna conhecida: categorias externas do Inter vêm da API; `SecaoEscolha` ainda
recebe opções fixas. Antes de migrar Sites parceiros e Compre direto, adicionar
opções dinâmicas à seção (decisão de implementação, sem mudança de API).

## Ligar no app (após aprovação)

```dart
// app/lib/app/app.dart
late final _filtros = criarRegistroFiltrosApp();

@override
void dispose() {
  _filtros.dispose();
  super.dispose();
}

// build:
EscopoDs(
  filtros: _filtros,
  child: MaterialApp(
    theme: DsTema.claro(),
    darkTheme: DsTema.escuro(),
    // ...
  ),
);
```

Durante a migração, as telas V15 ainda leem `CoresRadar`/`AppTokens`. Para as
duas convivirem, some as extensões do DS ao tema atual em vez de trocá-lo de
uma vez:

```dart
theme: TemaRadar.claro().copyWith(
  extensions: [
    ...TemaRadar.claro().extensions.values,
    DsCores.claro,
    DsTipo.de(DsCores.claro),
  ],
),
```

## Ordem de migração

Cada passo é uma PR pequena, com os testes da jornada ajustados.

1. Ligar `EscopoDs` + extensões do DS no tema (sem mudança visual).
2. **Pichau** (piloto): `DsCampoBusca(escopoFiltros: pichau)`, `DsCartaoOferta`,
   `FolhaHistorico` + `FonteHistoricoPichau`. Remover `_FolhaFiltrosPichau`,
   `PaginaHistoricoPichau`.
3. **Livelo**: `fonteHistoricoLivelo`, filtros `livelo`, cartão. Remover
   `PaginaHistoricoLiveloAndroid`, `cartao_catalogo_livelo`.
4. **Compre direto**: `FonteHistoricoProduto`, opções dinâmicas de categoria,
   cartão. Remover `PaginaHistoricoProduto`, `_FiltrosProdutosSheet`.
5. **Sites parceiros**, **Meu radar** e **Central**: filtros e cartões.
6. Navegação (`DsBarraNavegacao`, `DsCabecalho`) e Início/Perfil.
7. Trocar o tema para `DsTema` puro e apagar `tokens.dart`, `CoresRadar`,
   `FolhaRadar`, `fundacao_visual.dart` e Manrope.

## Testes

`app/test/design_system/` cobre faixa decimal sem `double`, estado único por
escopo, ordenação fora da contagem, paginação da `FolhaHistorico` pela fonte
e `FolhaFiltros` aplicando no estado global e refletindo no contador da busca.
