# UI SPEC — redesign mobile

**Branch:** `re-design`  
**Fonte visual de verdade:** [`prototipo-mobile.html`](prototipo-mobile.html)  
**Escopo:** somente Flutter mobile compacto. **Web está fora deste ciclo.**  
**Testes neste ciclo:** somente **unitários e widgets**.

## 1. Regra principal

O HTML mobile manda em estrutura, hierarquia, espaçamento, cores, estados e navegação. PRDs/API mandam em regras, dados e segurança.

Se o HTML mostrar dado ilustrativo sem contrato real, preserve a composição e use dado real equivalente ou estado honesto (`—`, vazio, indisponível). Se algo não estiver definido, não invente.

## 2. Viewports

- referência principal: **390 × 844 logical pixels**;
- largura mínima: **320 px**;
- composição do protótipo: até aproximadamente **430 px**;
- validar tema claro e escuro quando aplicável;
- **não validar Web/layout amplo nesta branch**, salvo se uma alteração compartilhada impedir o app mobile de compilar.

## 3. Tokens do HTML

### Claro

| Token | Valor |
|---|---:|
| `--marca-950` | `#081A2D` |
| `--marca-900` | `#102A43` |
| `--marca-800` | `#163B5C` |
| `--acao` | `#1769AA` |
| `--acao-fundo` | `#DCEEFF` |
| `--ciano` | `#25B8D8` |
| `--ciano-fundo` | `#DEF8FD` |
| `--ganho` | `#16803C` |
| `--ganho-fundo` | `#DCFCE7` |
| `--atencao` | `#8B5A12` |
| `--atencao-fundo` | `#FFF2D7` |
| `--perigo` | `#C53030` |
| `--texto` | `#102A43` |
| `--suave` | `#607487` |
| `--fundo` | `#F3F7FB` |
| `--superficie` | `#FFFFFF` |
| `--superficie-2` | `#EDF3F8` |
| `--borda` | `#DCE6EE` |

### Escuro

| Token | Valor |
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

O HTML também é a referência para tipografia, espaçamento, raios e sombras. Extraia esses valores conforme cada componente for migrado e centralize-os nos tokens Flutter; não espalhe números mágicos.

## 4. Componentes reutilizáveis

Reutilizar/adaptar `app/lib/app/componentes/` antes de criar duplicação. Padrões principais:

- top bar mobile;
- hero;
- métricas;
- cartões de módulo;
- cartões de loja;
- cartões de produto;
- busca;
- abas/filtros;
- gaveta;
- bottom sheets de utilidades;
- feedback flutuante;
- carregamento, vazio, parcial, indisponível, erro e retry.

No cartão de produto, `Preço atual` e **`Após cashback`** devem manter a hierarquia visual aprovada, com o preço líquido em destaque.

## 5. Navegação mobile

A gaveta possui exatamente quatro áreas principais:

1. **Início**;
2. **Livelo**;
3. **Banco Inter**;
4. **Buscar produtos**.

Alertas, conta, administração, aparência e saída são utilidades.

## 6. Regras das telas

### Início

- cabeçalho + hero + métricas + módulos conforme HTML;
- métricas reais de `/api/resumo` ou estado honesto;
- preservar atualização/retry e último retrato válido.

### Livelo

- preservar abas, busca, cartões, tags, campanha, validade, histórico e acompanhamento quando sustentados pela API;
- não recalcular pontos vindos da fonte.

### Banco Inter

- cashback e Compre direto continuam conceitualmente separados;
- acompanhar/remover preserva busca, página e posição;
- pedido aceito é diferente de coleta concluída.

### Buscar produtos

- preservar busca, paginação, filtros reais e histórico;
- nunca carregar catálogo inteiro no Flutter;
- não usar `double` para regra financeira.

## 7. Política de testes desta branch

Neste ciclo, os únicos tipos de teste autorizados são:

- **testes unitários** para lógica, mapeamentos, estado e regras locais alteradas;
- **testes de widgets** para renderização, interação e estados visíveis alterados.

Testar somente o necessário para a fase atual. Priorizar poucos testes úteis em vez de ampliar cobertura por quantidade.

Ficam adiados para outro ciclo:

- golden tests;
- integração;
- E2E;
- smoke automatizado;
- performance;
- regressão visual automatizada;
- testes Web.

Não apagar testes existentes dessas categorias. Apenas não criar, atualizar ou executar como gate deste redesign.

`dart format` e `flutter analyze` continuam obrigatórios e não contam como tipos de teste.

## 8. Ciclo do Codex

1. ler somente `AGENTS.md`, este arquivo, o HTML mobile e o plano da branch;
2. abrir apenas código e testes unitários/widgets da fase atual;
3. consultar PRD específico somente quando surgir dúvida de regra/API;
4. implementar a menor fatia coerente;
5. formatar/analisar;
6. executar somente unitários/widgets relevantes;
7. renderizar o app quando necessário e comparar visualmente com o HTML;
8. corrigir e repetir apenas as validações necessárias até estabilizar.

Não pedir screenshot para diferenças que possam ser identificadas localmente.

## 9. Pronto visual

A fatia está pronta quando o comportamento mobile funciona, a composição segue o HTML, não há overflow nas larguras cobertas pelos widgets, claro/escuro estão corretos quando aplicáveis, unitários/widgets relevantes passam e nenhum dado fictício virou dado real.
