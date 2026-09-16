# Guia — skills do design mobile V12

**Status:** vigente para concepção visual, implementação Flutter e validação

**Última atualização:** 2026-09-16

Este guia explica o papel de cada skill disponível no projeto e a ordem em que
elas devem ser usadas. As skills são ferramentas complementares; nenhuma delas
substitui a documentação do produto, o contrato da API ou a decisão visual
aprovada.

## 1. Onde ficam

As skills específicas deste projeto ficam em:

```text
/home/rodrigo/Estudos/robo/.agents/skills/
```

O inventário e os hashes das skills estão em
[`../../skills-lock.json`](../../skills-lock.json). Algumas também foram instaladas
globalmente em `~/.codex/skills`, mas a cópia local é a referência de trabalho
deste projeto.

O projeto também possui a estrutura de apoio do Impeccable em:

```text
/home/rodrigo/Estudos/robo/.impeccable/
```

## 2. Skills de direção visual

### `frontend-design`

Arquivo: [`frontend-design/SKILL.md`](../../.agents/skills/frontend-design/SKILL.md)

É a skill que atua como liderança de design. Ela orienta:

- personalidade específica para o produto;
- escolha intencional de cores e tipografia;
- composição, alinhamento, escala e densidade;
- uso de conteúdo real em vez de textos vazios;
- planejamento visual antes de escrever código;
- crítica da própria proposta antes da entrega.

No Radar, ela deve transformar o conceito de detectar oportunidades,
acompanhar benefícios e comparar ofertas em uma linguagem visual reconhecível.
Ela não deve copiar a V11 nem decidir contratos de backend.

### `design-anti-slop`

Arquivo: [`design-anti-slop/SKILL.md`](../../.agents/skills/design-anti-slop/SKILL.md)

É a skill de controle contra aparência genérica de IA. Ela trabalha em três
camadas:

1. **Conceitual:** verifica se a ideia e o conteúdo têm ponto de vista real.
2. **Estrutural:** procura composição repetitiva, bento, três cards iguais,
   KPI genérico e navegação previsível.
3. **Visual:** procura paleta, raio, sombra, gradiente, ícone e tipografia
   convergentes.

Ela deve ser usada antes de criar o protótipo, para exigir especificidade, e
depois, para auditar o resultado. Ela não substitui uma decisão completa de
UX, acessibilidade ou identidade de marca.

### `gpt-taste`

Arquivo: [`gpt-taste/SKILL.md`](../../.agents/skills/gpt-taste/SKILL.md)

É uma skill para aumentar a variação de layout, tipografia e direção visual.
Ela tenta impedir que o agente escolha sempre a primeira composição óbvia.

No projeto, seu uso será controlado. Ela foi criada com foco forte em web,
GSAP, AIDA, bento e layouts de apresentação. Portanto:

- usar na Fase A para gerar alternativas visuais;
- aproveitar a exigência de variedade e personalidade;
- não aplicar automaticamente AIDA, GSAP, bento ou espaçamento de landing page
  ao aplicativo Flutter;
- não deixar que ela imponha um visual de site comprimido no celular.

### `mobile-design`

Arquivo: [`mobile-design/SKILL.md`](../../.agents/skills/mobile-design/SKILL.md)

É o guardrail de experiência mobile. Antes de desenhar ou implementar, ela
orienta a identificar a plataforma, entender o objetivo da tela e planejar:

- navegação e retorno;
- ação primária;
- hierarquia e densidade;
- estados de carregamento, vazio, erro e sucesso;
- comportamento de toque, teclado e rolagem;
- acessibilidade, escala de texto e comportamento nativo.

Ela ajuda a interface a funcionar como aplicativo. Não deve escolher sozinha a
identidade visual do Radar nem obrigar o projeto a usar Material genérico.

### Impeccable

O apoio do Impeccable está registrado em
[`../.impeccable/`](../.impeccable/). Ele organiza inspeções, críticas,
auditorias e revisões visuais do protótipo.

Uso previsto:

- revisar a primeira versão do HTML;
- verificar hierarquia, contraste, densidade, estados e responsividade;
- comparar a renderização com a direção aprovada;
- fazer uma rodada limitada de correção.

Ele é um mecanismo de revisão, não uma autorização para redesenhar sem fim.

## 3. Skills auxiliares de imagem e redesign

### `imagegen-frontend-mobile`

Arquivo: [`imagegen-frontend-mobile/SKILL.md`](../../.agents/skills/imagegen-frontend-mobile/SKILL.md)

Gera imagens de conceito e mockups de telas mobile. Não escreve HTML, CSS,
Dart ou Flutter.

Usar somente se precisarmos de:

- moodboard;
- referência de textura ou imagem;
- exploração de direção artística;
- imagem original para uma tela que realmente dependa de imagem.

Não usar para substituir o protótipo clicável nem para transformar imagens em
contrato visual sem decisão.

### `redesign-existing-projects`

Arquivo: [`redesign-existing-projects/SKILL.md`](../../.agents/skills/redesign-existing-projects/SKILL.md)

Audita um projeto existente, identifica problemas e faz melhorias pontuais
sem reescrever tudo.

Não é a skill principal deste ciclo, porque a direção atual começa do zero.
Ela só deve ser usada em uma fase futura de auditoria de uma implementação já
existente e nunca para preservar automaticamente a aparência antiga.

## 4. Skills de sistema visual e reuso Flutter

Estas entram depois que o HTML e os tokens visuais forem aprovados; a Fase C
foi executada no cliente Flutter compacto e seus gates permanecem no CI.

### `design-tokens`

Arquivo: [`design-tokens/SKILL.md`](../../.agents/skills/design-tokens/SKILL.md)

Impede valores visuais espalhados pelos widgets. Cores, espaçamentos, raios,
sombras, durações e estilos de texto devem vir do sistema de tokens do
aplicativo, normalmente via `ThemeExtension`/`AppTokens`.

Benefício para o projeto: uma alteração da identidade nova atualiza o sistema
inteiro sem caçar valores hardcoded em cada tela.

### `codebase-conventions`

Arquivo: [`codebase-conventions/SKILL.md`](../../.agents/skills/codebase-conventions/SKILL.md)

Evita duplicação e mantém o código coerente com o projeto. Antes de criar um
widget, ela orienta a procurar:

- componentes equivalentes já existentes;
- tokens de cor e tipografia;
- assets declarados;
- convenções de nomes, arquivos e imports;
- localização correta dos widgets compartilhados.

### `responsive-adaptive`

Arquivo: [`responsive-adaptive/SKILL.md`](../../.agents/skills/responsive-adaptive/SKILL.md)

Define como sair de uma arte feita em uma largura para um aplicativo que roda
em muitas larguras. Ela diferencia decisões de componente e decisões de tela,
orienta breakpoints centralizados e proíbe tratar a largura do protótipo como
dimensão fixa.

### `a11y-and-rtl`

Arquivo: [`a11y-and-rtl/SKILL.md`](../../.agents/skills/a11y-and-rtl/SKILL.md)

Cuida do que normalmente não aparece no design estático:

- semântica para leitores de tela;
- contraste;
- alvos de toque adequados;
- escala de texto sem overflow;
- padding direcional;
- ícones que precisam espelhar;
- preparação para idiomas RTL quando aplicável.

Ela vale para qualquer widget de usuário, mesmo que o aplicativo inicialmente
use somente português e layout LTR.

## 5. Skills oficiais de implementação Flutter

### `flutter-build-responsive-layout`

Arquivo: [`flutter-build-responsive-layout/SKILL.md`](../../.agents/skills/flutter-build-responsive-layout/SKILL.md)

É a orientação prática para montar árvores responsivas usando
`LayoutBuilder`, `MediaQuery`, `Expanded` e `Flexible`. Ela complementa
`responsive-adaptive`:

- `responsive-adaptive` define a regra e a decisão de adaptação;
- `flutter-build-responsive-layout` ajuda a implementá-la no widget.

### `flutter-add-widget-preview`

Arquivo: [`flutter-add-widget-preview/SKILL.md`](../../.agents/skills/flutter-add-widget-preview/SKILL.md)

Cria previews isolados de widgets. Serve para conferir rapidamente:

- claro e escuro;
- carregando, vazio, erro e sucesso;
- variações de conteúdo;
- tamanhos de tela;
- estados de interação;
- componentes reutilizáveis antes de integrá-los à jornada completa.

### `flutter-add-widget-test`

Arquivo: [`flutter-add-widget-test/SKILL.md`](../../.agents/skills/flutter-add-widget-test/SKILL.md)

Cria testes com `WidgetTester` para confirmar renderização e interação:

- toque;
- rolagem;
- entrada de texto;
- busca e filtros;
- callbacks;
- presença correta de estados.

Neste ciclo, só deve ser usado para widgets diretamente afetados pela mudança.

### `flutter-fix-layout-issues`

Arquivo: [`flutter-fix-layout-issues/SKILL.md`](../../.agents/skills/flutter-fix-layout-issues/SKILL.md)

Entra quando existe um problema concreto de layout, como:

- `RenderFlex overflowed`;
- viewport vertical sem limite;
- `TextField` sem largura definida;
- lista ou grid dentro de constraints incorretas;
- composição que quebra em uma largura específica.

Ela diagnostica a negociação de constraints do Flutter e orienta uma correção
local, sem mascarar o problema com dimensões mágicas.

## 6. Ordem oficial de uso

### Fase A — identidade visual nova

Usar:

```text
frontend-design
gpt-taste
mobile-design
design-anti-slop
```

Entregáveis:

- três direções visuais radicalmente diferentes;
- paleta, tipografia, superfícies, navegação, iconografia e motion de cada uma;
- justificativa específica para o Radar;
- escolha de uma direção;
- tokens e princípios da direção escolhida.

### Fase B — protótipo HTML

Usar:

```text
frontend-design
design-anti-slop
mobile-design
Impeccable
```

Entregáveis:

- HTML/CSS/JavaScript clicável;
- componentes e dados de exemplo reutilizáveis;
- jornadas completas;
- estados de carregamento, vazio, erro, parcial e sucesso;
- responsividade nas larguras definidas pelo projeto;
- uma crítica e uma correção controlada.

### Fase C — Flutter

Usar:

```text
design-tokens
codebase-conventions
responsive-adaptive
a11y-and-rtl
flutter-build-responsive-layout
flutter-add-widget-preview
flutter-add-widget-test
flutter-fix-layout-issues — somente quando houver erro de layout
```

Entregáveis:

- tokens centralizados;
- widgets realmente reutilizáveis;
- composição adaptável;
- previews dos componentes importantes;
- testes unitários/widgets diretamente afetados;
- ausência de overflow nas larguras cobertas.

## 7. Regras para não misturar as skills

- `gpt-taste` não pode transformar um aplicativo mobile em landing page Web.
- `mobile-design` valida experiência mobile, mas não escolhe a identidade
  sozinho.
- `design-anti-slop` audita convergência; não deve reduzir o design a uma lista
  de proibições.
- `redesign-existing-projects` não deve ser usado para a criação do novo mundo
  visual.
- `imagegen-frontend-mobile` não produz código nem protótipo clicável.
- `design-tokens` não deve ser aplicado antes da decisão dos tokens visuais.
- `codebase-conventions` deve impedir a criação de um segundo widget para a
  mesma função.
- `flutter-fix-layout-issues` só entra para corrigir um problema identificado;
  não é uma etapa obrigatória em toda tela.
- Não usar golden, integração, E2E ou regressão visual automatizada sem uma
  decisão específica que altere o escopo de qualidade deste projeto.

## 8. Regra de decisão

Se duas skills derem orientações diferentes, a prioridade é:

1. documentação do produto e regras reais;
2. direção visual aprovada;
3. acessibilidade e comportamento mobile;
4. convenções e tokens do projeto;
5. recomendação genérica da skill.

Uma skill nunca autoriza inventar dado, rota, regra, componente de domínio ou
comportamento que não esteja definido no produto.
