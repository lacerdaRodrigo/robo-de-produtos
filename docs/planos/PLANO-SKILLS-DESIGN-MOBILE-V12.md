# Plano — conjunto de skills para o novo design mobile V12

**Status:** Fases A, B e C implementadas; validação estática, testes afetados e
aceite manual final continuam registrados nas pendências

**Última atualização:** 2026-09-16

**Escopo:** direção visual Delta, protótipo HTML mobile e implementação da
jornada Flutter compacta. Backend/API só pode ser alterado quando necessário à
jornada e documentado; banco, workflow, produção e publicação permanecem
submetidos às autorizações operacionais próprias.

## 1. Objetivo

Criar uma identidade visual mobile completamente nova para o Radar de
Benefícios, sem reciclar a aparência dos protótipos anteriores, e transformar
essa direção em widgets Flutter reaproveitáveis, responsivos, acessíveis e
fáceis de validar.

O produto real continua preservado: jornadas, funcionalidades, dados, regras
de negócio, APIs, paginação, estados honestos e limites técnicos. A mudança é
visual e estrutural na interface, não uma autorização para inventar contratos
ou alterar o backend.

## 2. Princípios de uso

- Não carregar todas as skills ao mesmo tempo. Cada grupo entra na fase em que
  consegue contribuir sem disputar a mesma decisão.
- Skills de direção visual definem o conceito; skills Flutter não escolhem a
  identidade por conta própria.
- O protótipo HTML é criado antes da implementação Flutter.
- O resultado deve nascer de três direções visuais realmente diferentes, e não
  de três variações de cards e cores.
- A identidade final deve ter tokens próprios de cor, tipografia, superfície,
  espaçamento, forma, estados, motion e componentes.
- Cards, pills, gradientes, blur, glow e navegação Material são decisões
  contextuais, nunca padrões obrigatórios.
- Dados ilustrativos continuam isolados do contrato real da API.
- Usar somente as validações e os testes autorizados pelas instruções vigentes
  deste projeto; não adicionar integração, E2E, golden ou regressão visual
  automatizada sem decisão específica.

## 3. Skills escolhidas

### 3.1 Direção visual e protótipo

| Skill | Papel | Decisão |
|---|---|---|
| `frontend-design` | Direção visual intencional, tipografia, composição, paleta e crítica de escolhas genéricas. | Usar como base de concepção. |
| `design-anti-slop` | Detectar padrões convergentes de UI gerada por IA e exigir uma linguagem própria. | Usar como auditoria antes e depois do protótipo. |
| `Impeccable` | Organizar criação, crítica, auditoria e correção de uma interface nova. | Usar com uma rodada de correção limitada. |
| `gpt-taste` | Aumentar a variação de layout e reforçar personalidade visual para agentes GPT/Codex. | Usar como skill externa de gosto. |

Fontes: [Anthropic frontend-design](https://github.com/anthropics/skills/tree/main/skills/frontend-design), [design-anti-slop](https://github.com/prathameshagrawal/design-anti-slop), [Taste Skill](https://github.com/Leonxlnx/taste-skill) e [Impeccable](https://github.com/pbakaus/impeccable).

### 3.2 UX específico para mobile

| Skill | Papel | Decisão |
|---|---|---|
| `mobile-design` | Intake, hierarquia, densidade, estados, adaptação de plataforma e crítica mobile. | Usar como guardrail de UX; consultar apenas as seções necessárias por fase. |
| `mobile-ui-ux-designer` | Objetivo da tela, ação primária, estados, recuperação, acessibilidade, motion e contrato de componentes. | Referência avaliada, mas não instalada: o repositório usa `skill.md` em minúsculas e não passa no instalador Codex sem cópia manual. |

Fonte instalada: [mobile-design](https://github.com/ulugbekeshnazarov409/mobile-design). Referência não instalada: [mobile-ui-ux-designer](https://github.com/mdrmuhaimin/agentic-skills/blob/main/codex/mobile-ui-ux-designer/skill.md).

### 3.3 Implementação Flutter oficial

Usar durante a implementação Flutter depois da aprovação visual do HTML:

| Skill | Uso no projeto |
|---|---|
| `flutter-build-responsive-layout` | Adaptar o layout às larguras mobile sem assumir uma única orientação ou tamanho. |
| `flutter-add-widget-preview` | Inspecionar widgets isolados em temas, estados e configurações diferentes. |
| `flutter-fix-layout-issues` | Diagnosticar overflow, constraints e problemas de composição. |
| `flutter-add-widget-test` | Cobrir renderização e interação dos widgets diretamente afetados. |

Fonte: [Flutter Agent Plugins](https://github.com/flutter/agent-plugins),
repositório mantido pelo time do Flutter.

### 3.4 Reuso, tokens e qualidade Flutter

Usar o subconjunto selecionado de [flutter_craft_skills](https://github.com/draz26648/flutter_craft_skills):

| Skill | Uso no projeto |
|---|---|
| `design-tokens` | Concentrar cores, tipografia, espaçamento, raios e estados em tokens reutilizáveis. |
| `codebase-conventions` | Procurar componentes existentes por função antes de criar novos widgets. |
| `responsive-adaptive` | Separar adaptação de layout de decisões específicas de um aparelho. |
| `a11y-and-rtl` | Semântica, tamanho mínimo de toque, escala de texto, contraste e padding direcional. |

As skills de `golden-tests`, `visual-verification` e `review-gate` ficam fora
do gate atual. Podem ser reavaliadas em outro plano se o escopo de testes
mudar.

## 4. Skills avaliadas e não escolhidas

### `flutter-ui-ux`

Fica como referência secundária, não como autoridade estética. É útil para
composição de widgets, tema, animação e responsividade, mas é genérica para o
problema atual e o repositório de origem está arquivado.

Fontes: [skills-collection](https://github.com/ajianaz/skills-collection) e [SKILL.md](https://raw.githubusercontent.com/ajianaz/skills-collection/main/skills/flutter-ui-ux/SKILL.md).

### `redesign-existing-projects`

Não usar na concepção atual. O objetivo é uma direção nova a partir de uma
folha em branco, e não uma reforma da aparência existente.

### `imagegen-frontend-mobile`

Não usar para construir HTML ou Flutter. Pode ser considerada somente para um
moodboard ou referência bitmap, caso uma decisão futura peça imagens originais.

### `mobile-app-ui-design`

Não usar como autoridade porque pode reintroduzir rounded cards, blur, glow e
componentes decorativos genéricos.

### `ui-ux-pro-max`

Não instalar neste momento. O catálogo amplo de estilos e paletas pode ajudar
em pesquisa, mas não deve escolher automaticamente a linguagem do produto.

### `ui-package`

Não criar pacote Flutter separado agora. A extração para `packages/` somente
será avaliada se o projeto decidir formalmente compartilhar a biblioteca entre
aplicativos.

## 5. Ordem de execução

### Fase A — definir o mundo visual

Usar `frontend-design`, `design-anti-slop`, `gpt-taste` e `Impeccable` para:

1. preservar apenas o produto real e fechar referências estéticas antigas;
2. propor três conceitos visuais radicalmente diferentes;
3. definir em cada conceito paleta, tipografia, composição, navegação,
   produtos, benefícios, lojas, iconografia, motion, dark mode e elemento
   memorável;
4. reprovar qualquer proposta que pareça fintech, marketplace, dashboard de
   IA, template Material, SaaS, Dribbble ou uma versão da V11;
5. escolher uma direção e registrar seus tokens e regras.

### Fase B — protótipo HTML clicável

Usar `Impeccable` e, quando necessário, `mobile-design` para construir um
protótipo vanilla HTML/CSS/JavaScript:

- 100% clicável nas jornadas definidas;
- responsivo em 320, 360, 390, 412 e 430px;
- claro e escuro quando aplicável;
- componentes visuais e dados de exemplo reutilizáveis;
- busca, filtros, abas, retorno, folhas, ações e navegação;
- carregamento, vazio, erro, parcial, atraso, ausência de dado e sucesso;
- sem promover dados ilustrativos a contratos reais.

Executar uma crítica visual e uma correção controlada antes de considerar o
HTML pronto para a implementação.

### Fase C — implementar widgets Flutter — concluída localmente

Após a aprovação visual do protótipo:

1. ler o HTML aprovado, o sistema visual aprovado e os arquivos Flutter
   diretamente relacionados;
2. criar ou adaptar tokens antes dos widgets;
3. extrair componentes por responsabilidade, não por semelhança superficial;
4. usar previews para conferir variações de estado e tema;
5. aplicar as regras de responsividade e corrigir overflow;
6. preservar navegação, paginação, busca, posição útil e estados reais;
7. rodar apenas as validações e os testes diretamente afetados.

### Registro da entrega HTML

A Fase B foi executada em `design-app/prototipos/mobile-v12/`, com a direção
`Delta`. O inventário de rotas, overlays e estados está em
[`../guias/MATRIZ-TELAS-MOBILE-V12.md`](../guias/MATRIZ-TELAS-MOBILE-V12.md), o
contrato visual está em
[`../guias/SISTEMA-DESIGN-MOBILE-V12-NOVO.md`](../guias/SISTEMA-DESIGN-MOBILE-V12-NOVO.md)
e as verificações realizadas estão em
[`../guias/RELATORIO-VALIDACAO-PROTOTIPO-MOBILE-V12.md`](../guias/RELATORIO-VALIDACAO-PROTOTIPO-MOBILE-V12.md).

O protótipo foi revisado e a Fase C foi executada no cliente Flutter. As
pendências de equivalência visual física e de distribuição continuam no
registro vivo de pendências.

## 6. Registro da implementação Flutter

A implementação V12 Delta entrou no cliente Flutter compacto e permanece
cliente exclusivo da API autenticada. Foram entregues:

- tema claro/escuro e tokens Delta centralizados;
- moldura compacta com navegação flutuante de Resumo e Serviços;
- perfil, aparência, recuperação de acesso, permissão de notificações e
  laboratório de estados;
- estados de carregamento, sucesso, vazio, erro, parcial, atrasado, offline,
  ausência de sincronização e ação em andamento nas jornadas tocadas;
- acentos por fonte para Livelo, Cashback Inter, Produtos e Pichau;
- reuso de fundação visual, menu de conta, cartões, folhas, busca, abas,
  paginação e estados existentes;
- testes unitários/widgets diretamente afetados, sem golden, integração, E2E,
  Web ou testes de regressão visual automatizados.

A equivalência visual manual em dispositivo físico, a entrega do APK pela
pipeline e a validação externa permanecem pendências operacionais até haver
evidência verificável no repositório ou no workflow.

## 7. Critérios de aceite

- A direção escolhida é visualmente distinta dos protótipos anteriores.
- A identidade continua reconhecível sem depender do logo ou de um ícone de
  radar repetido em todas as telas.
- Cores fortes têm contraste adequado e funcionam em claro/escuro.
- Os componentes reutilizáveis não escondem regras de domínio nem dados
  fictícios.
- Não há overflow nas larguras cobertas.
- A jornada mobile real continua funcionando com a API existente; nenhuma
  chamada de catálogo foi movida para o cliente ou para o protótipo.
- As validações e os testes permitidos passam.
- Não há alteração em backend, banco, workflow, produção ou contratos sem
  autorização.
- Divergências visuais, lacunas de decisão e validações manuais continuam
  registradas na documentação de pendências deste projeto.

## 8. Instalação inicial

As skills externas do conjunto escolhido foram instaladas globalmente em
`~/.codex/skills` e copiadas para `docs/.agents/skills/`, que é o diretório
local de skills deste projeto. As quatro skills que já existiam ali foram
preservadas sem sobrescrita.

### Instaladas

- `gpt-taste`, de `Leonxlnx/taste-skill/skills/gpt-tasteskill`;
- `mobile-design`, de `ulugbekeshnazarov409/mobile-design`;
- `flutter-build-responsive-layout`;
- `flutter-add-widget-preview`;
- `flutter-fix-layout-issues`;
- `flutter-add-widget-test`;
- `design-tokens`;
- `codebase-conventions`;
- `responsive-adaptive`;
- `a11y-and-rtl`.

### Não instaladas

- `flutter-ui-ux`;
- `redesign-existing-projects`;
- `imagegen-frontend-mobile`;
- golden tests, integração, E2E e regressão visual automatizada;
- variantes simultâneas `design-taste-frontend` e `gpt-taste`.

A tentativa de instalar `mobile-ui-ux-designer` falhou porque o repositório usa
`skill.md` em minúsculas. Não foi criada cópia parcial; `mobile-design` foi
usada como alternativa compatível.

## 8. Registro de instalação

| Data | Skill | Origem/caminho | Resultado |
|---|---|---|---|
| 2026-09-15 | `gpt-taste` | `Leonxlnx/taste-skill/skills/gpt-tasteskill` | global e local em `docs/.agents/skills/gpt-taste` |
| 2026-09-15 | `mobile-design` | `ulugbekeshnazarov409/mobile-design` | global e local em `docs/.agents/skills/mobile-design` |
| 2026-09-15 | `flutter-build-responsive-layout` | `flutter/agent-plugins/skills/flutter-build-responsive-layout` | global e local em `docs/.agents/skills/flutter-build-responsive-layout` |
| 2026-09-15 | `flutter-add-widget-preview` | `flutter/agent-plugins/skills/flutter-add-widget-preview` | global e local em `docs/.agents/skills/flutter-add-widget-preview` |
| 2026-09-15 | `flutter-fix-layout-issues` | `flutter/agent-plugins/skills/flutter-fix-layout-issues` | global e local em `docs/.agents/skills/flutter-fix-layout-issues` |
| 2026-09-15 | `flutter-add-widget-test` | `flutter/agent-plugins/skills/flutter-add-widget-test` | global e local em `docs/.agents/skills/flutter-add-widget-test` |
| 2026-09-15 | `design-tokens` | `draz26648/flutter_craft_skills/plugins/flutter-design-fidelity/skills/design-tokens` | global e local em `docs/.agents/skills/design-tokens` |
| 2026-09-15 | `codebase-conventions` | `draz26648/flutter_craft_skills/plugins/flutter-code-quality/skills/codebase-conventions` | global e local em `docs/.agents/skills/codebase-conventions` |
| 2026-09-15 | `responsive-adaptive` | `draz26648/flutter_craft_skills/plugins/flutter-code-quality/skills/responsive-adaptive` | global e local em `docs/.agents/skills/responsive-adaptive` |
| 2026-09-15 | `a11y-and-rtl` | `draz26648/flutter_craft_skills/plugins/flutter-code-quality/skills/a11y-and-rtl` | global e local em `docs/.agents/skills/a11y-and-rtl` |
| 2026-09-15 | `mobile-ui-ux-designer` | `mdrmuhaimin/agentic-skills/codex/mobile-ui-ux-designer` | não instalado; arquivo `skill.md` incompatível com o instalador |
