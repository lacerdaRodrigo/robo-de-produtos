# UI SPEC — contrato visual do redesign mobile

**Status:** aprovado como regra de implementação da branch `re-design`  
**Fonte visual de verdade:** [`prototipo-mobile.html`](prototipo-mobile.html)  
**Assets do protótipo:** [`assets/`](assets/)  
**Plano funcional:** [`PLANO-MIGRACAO-MOBILE.md`](PLANO-MIGRACAO-MOBILE.md)

## 1. Objetivo

Este arquivo existe para impedir que a implementação Flutter seja redesenhada por interpretação do agente. O HTML versionado no repositório é a referência visual primária. PRDs e contratos de API continuam sendo a referência de regra, dados e segurança.

Quando houver conflito:

1. regra de negócio, segurança e contrato de dados: PRD/API vencem;
2. estrutura, hierarquia, espaçamento, cores, estados e navegação mobile: o HTML vence;
3. se o HTML mostrar dado ilustrativo sem contrato real, preserve a composição visual, mas use dado real equivalente ou estado honesto (`—`, vazio, indisponível) conforme o plano;
4. se não houver definição suficiente, não invente. Registre a lacuna e peça decisão.

## 2. Escopo

- alvo inicial: experiência compacta/mobile definida no plano;
- viewport de referência principal: **390 × 844 logical pixels, DPR 1 nos testes**;
- largura mínima que deve continuar utilizável: **320 px**;
- o protótipo limita a composição principal a aproximadamente **430 px**;
- tema claro e escuro fazem parte da mesma especificação;
- o Web e layouts amplos permanecem como regressão protegida, salvo decisão explícita em contrário.

## 3. Tokens extraídos do HTML

### 3.1 Cores — claro

| Token HTML | Valor | Papel |
|---|---:|---|
| `--marca-950` | `#081A2D` | marca profunda / gaveta |
| `--marca-900` | `#102A43` | marca / texto principal |
| `--marca-800` | `#163B5C` | variação institucional |
| `--acao` | `#1769AA` | ação, links e foco |
| `--acao-fundo` | `#DCEEFF` | fundo de ação |
| `--ciano` | `#25B8D8` | destaque de integração |
| `--ciano-fundo` | `#DEF8FD` | fundo ciano |
| `--ganho` | `#16803C` | ganho/sucesso |
| `--ganho-fundo` | `#DCFCE7` | fundo de ganho |
| `--atencao` | `#8B5A12` | atenção |
| `--atencao-fundo` | `#FFF2D7` | fundo de atenção |
| `--perigo` | `#C53030` | erro/zona de perigo |
| `--texto` | `#102A43` | texto principal |
| `--suave` | `#607487` | texto secundário |
| `--fundo` | `#F3F7FB` | fundo interno do app |
| `--superficie` | `#FFFFFF` | cartões/superfícies |
| `--superficie-2` | `#EDF3F8` | superfície secundária |
| `--borda` | `#DCE6EE` | bordas |
| `--sombra` | `0 16px 40px rgba(8,26,45,.10)` | elevação principal |

### 3.2 Cores — escuro

| Token HTML | Valor |
|---|---:|
| `--texto` | `#EDF7FF` |
| `--suave` | `#9FB3C5` |
| `--fundo` | `#06111E` |
| `--superficie` | `#0D2032` |
| `--superficie-2` | `#132B40` |
| `--borda` | `rgba(190,217,238,.14)` |
| `--acao-fundo` | `#173B56` |
| `--ciano-fundo` | `#103A47` |
| `--ganho-fundo` | `#113A27` |
| `--ganho` | `#65D98B` |
| `--atencao-fundo` | `#402F14` |
| `--atencao` | `#FFD17A` |
| `--sombra` | `0 18px 42px rgba(0,0,0,.27)` |

### 3.3 Tipografia

O HTML declara `Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`. No Flutter, não adicione uma fonte remota ou pacote só para aproximar o protótipo sem decisão explícita. Preserve primeiro peso, tamanho, altura de linha e hierarquia. Se a fonte exata for aprovada como asset local, a troca deve ser isolada no tema.

### 3.4 Espaçamento, raios e sombra

O HTML é a referência exata. Ao migrar cada componente, extraia os valores usados por ele e consolide-os em tokens Flutter reutilizáveis; não espalhe números mágicos por telas. Tokens novos devem ter nome semântico e teste quando forem estruturais.

## 4. Componentes que devem ser reutilizáveis

A implementação não precisa copiar os nomes abaixo literalmente, mas deve evitar duplicação visual. Mapear os padrões do HTML para componentes Flutter equivalentes:

- cabeçalho/top bar mobile;
- `HeroCard` / hero de resumo;
- `MetricCard` / métrica;
- `ModuleCard` / entrada de área;
- `StoreCard` / loja Livelo ou Inter com variante semântica;
- `ProductCard` com preço atual e **Após cashback** lado a lado, mantendo o preço líquido em destaque;
- campo de busca;
- abas e filtros/chips;
- gaveta principal;
- folha/bottom sheet de utilidades;
- feedback flutuante/toast/snackbar coerente com o protótipo;
- estados de carregamento, vazio, indisponível, parcial, erro e retry.

Antes de criar um componente novo, verifique `app/lib/app/componentes/` e adapte/reutilize o que já existe quando a semântica for a mesma.

## 5. Telas e navegação de referência

A gaveta mobile deve comunicar quatro áreas principais:

1. **Início**;
2. **Livelo**;
3. **Banco Inter**;
4. **Buscar produtos**.

Alertas, conta, administração, aparência e saída são utilidades e não viram um quinto domínio principal. As regras de autorização continuam no backend e na apresentação.

Estados visuais definidos no HTML devem ser reproduzidos. Os dados do HTML são ilustrativos; dados reais vêm somente da API existente ou de contratos explicitamente aprovados.

## 6. Regras por domínio

### Início

- preservar a hierarquia do cabeçalho, hero, métricas e entradas de área;
- métricas vêm de `GET /api/resumo` ou aparecem em estado honesto;
- no compacto, o resumo pode atualizar conforme o contrato já implementado; navegação e busca não consultam diretamente Livelo/Inter.

### Livelo

- preservar abas, cartões, tags, campanha, validade, histórico e ação de acompanhar quando sustentados pelo contrato real;
- pontos e textos vindos da fonte não são recalculados visualmente.

### Banco Inter

- manter Cashback e Sites/áreas parceiras distinguíveis conforme o plano;
- acompanhar/remover deve preservar busca, página e posição útil;
- pedido aceito e coleta concluída são mensagens diferentes.

### Buscar produtos

- preservar busca, filtros sustentados pela API, paginação e histórico;
- o Flutter nunca recebe o catálogo inteiro;
- `Preço atual` e `Após cashback` são apresentados como no protótipo; cálculo financeiro não deve ser refeito em `double` no cliente.

## 7. Golden tests e comparação visual

Golden test é gate, não documentação decorativa.

Para cada fatia visual estável:

1. fixe dados de teste determinísticos;
2. fixe viewport e DPR;
3. renderize tema claro e escuro quando aplicável;
4. compare com `matchesGoldenFile`;
5. preserve golden de regressão do Web/layout amplo quando a mudança for somente mobile;
6. nunca rode `--update-goldens` para fazer um teste passar sem antes conferir a mudança contra o HTML aprovado;
7. quando a referência visual mudar de propósito, atualize primeiro o HTML/UI_SPEC e só então regenere o golden.

Cobertura mínima desejada ao fim do redesign:

- Início mobile claro/escuro;
- gaveta mobile aberta;
- Livelo mobile claro/escuro;
- Banco Inter mobile claro/escuro;
- Buscar produtos mobile claro/escuro;
- estados relevantes (vazio/erro/parcial) quando alterarem significativamente a composição;
- golden Web/layout amplo de regressão.

## 8. Ciclo obrigatório para o Codex

Ao receber uma tarefa visual nesta branch:

1. ler `AGENTS.md`, este arquivo e o HTML inteiro;
2. localizar no HTML a tela/estado/componente pedido;
3. localizar no Flutter a implementação atual e os testes existentes;
4. implementar a menor fatia coerente sem tocar no backend salvo necessidade contratual aprovada;
5. formatar e analisar;
6. rodar testes unitários/widgets relevantes;
7. rodar goldens relevantes;
8. se houver ambiente de execução, abrir/renderizar no viewport mobile de referência e comparar com o HTML;
9. corrigir diferenças encontradas e repetir os gates necessários;
10. informar arquivos alterados, testes executados e qualquer diferença visual ainda conhecida.

Não pedir screenshot ao responsável para descobrir uma diferença que o próprio HTML, teste ou renderização local já consegue revelar.

## 9. Definição de pronto visual

Uma fatia só está pronta quando:

- o comportamento real continua correto;
- a composição segue o HTML no estado correspondente;
- não há overflow em 320 px nem no viewport de referência;
- texto ampliado não quebra a jornada;
- claro/escuro permanecem legíveis quando aplicáveis;
- goldens relevantes passam sem atualização oportunista;
- regressão Web/layout amplo passa quando protegida;
- nenhum dado ilustrativo do HTML foi promovido a dado real;
- o agente consegue explicar qualquer divergência intencional restante e apontar a decisão que a autoriza.
