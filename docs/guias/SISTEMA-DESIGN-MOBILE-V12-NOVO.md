# Sistema de design — mobile V12 novo

Este é o contrato visual do protótipo HTML em
[`../prototipos/mobile-v12/`](../prototipos/mobile-v12/). A direção foi criada
do zero para este ciclo e se chama `Delta`.

## Ideia central

O Radar é uma ferramenta de comparação de mudanças, não uma vitrine de ofertas.
A primeira leitura mostra antes, depois, origem e frescor no mesmo gesto. A
composição usa uma ocorrência em destaque, cartões assimétricos de comparação e
um dock de navegação; não há logo externo, gradiente decorativo, dashboard
genérico, bento ou grade de cartões iguais.

## Fundamentos

- Canvas verde-claro e tema escuro de verde mineral, ambos com superfícies
  opacas e contraste alto.
- Coral marca a ação principal; lima marca uma mudança confirmada; verde-petróleo
  sustenta origem e navegação; rosa fica reservado para falha ou atenção.
- Mostarda, verde-água, violeta e coral identificam Livelo, Cashback, Produtos
  e Pichau sem competir com a marca principal.
- Sans-serif humanista e pesada hierarquiza títulos; a leitura corrente fica
  neutra e os valores usam números tabulares sem transformar todo rótulo em
  código técnico.
- Cartões de comparação têm canto assimétrico, sombra curta e hierarquia
  interna própria. Pills existem somente para controles de filtro e seleção.
- Motion curta, funcional e desativada em `prefers-reduced-motion`.

## Componentes obrigatórios

`brand-lockup`, `button`, `icon-button`, `field`, `search-field`, `topbar`,
`bottom-nav`, `tab-row`, `filter-trigger`, `status-marker`, `signal-line`,
`service-row`, `data-row`, `offer-row`, `value-lockup`, `follow-control`,
`state-box`, `pagination`, `sheet`, `dialog`, `toast`, `accordion`,
`metric-band` e `danger-zone` são componentes compartilhados. Uma tela nova
deve compor esses elementos antes de criar uma variação.

## Regras de estado

Todo catálogo deve conseguir demonstrar: sucesso, carregando, vazio,
resultado vazio de busca, erro, parcial, atrasado/desatualizado, offline,
sem sincronização e paginação. Número zero, dado ausente, falha e atraso são
renderizados como situações distintas.

## Layout responsivo

- Compacto: menos de 600 px; dock inferior com Resumo e Serviços, fixo na área
  segura e sem esconder a ação principal do conteúdo.
- Médio: 600–839 px; conteúdo mais largo e ações em linha quando houver
  espaço intrínseco.
- Expandido: 840 px ou mais; duas colunas quando a hierarquia se beneficia,
  sem esticar campos pequenos nem transformar o app em desktop genérico.
- A largura é sempre intrínseca; não há artboard fixo nem escala do layout.
- Os componentes devem suportar aumento de texto até 200% sem corte.

## Acessibilidade

Todos os controles têm nome acessível, foco visível, alvo mínimo de 48 px,
ordem de teclado previsível e sem depender apenas de cor. Overlays podem ser
fechados por Escape e pelo backdrop. O protótipo usa HTML semântico,
`aria-live` para toast e `aria-current`/`aria-selected` nas navegações.

## Fonte de dados

`js/data.js` contém somente dados ilustrativos para revisar a experiência.
Nenhuma imagem, API externa, logo remoto ou operação destrutiva real faz parte
do protótipo.
