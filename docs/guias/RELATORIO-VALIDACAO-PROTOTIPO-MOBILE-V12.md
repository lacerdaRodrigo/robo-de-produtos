# Relatório de validação — protótipo mobile V12

## Escopo executado

Validação estrutural do protótipo em
[`../prototipos/mobile-v12/`](../prototipos/mobile-v12/), sem chamada de API e
sem alteração de Flutter, backend, banco ou produção.

Este recorte registra a validação do protótipo antes da implementação nativa.
A implementação Flutter posterior usa este protótipo como espelho e tem seus
comandos, testes afetados e divergências manuais registrados no plano V12 e em
`docs/PENDENCIAS.md`.

### Rodada visual 4 — Delta

Após novo feedback visual, a direção foi reestruturada como **Delta**.
O produto deixa de usar a gramática compartilhada pelos protótipos anteriores:
sem painel azul-petróleo, trilhos como elemento dominante, tipografia serifada,
cartões técnicos ou rótulos monoespaçados em excesso. A interface passa a
funcionar como uma ferramenta de comparação, usando antes/depois, cartões
assimétricos, sans-serif humanista e dock de navegação. Não foram introduzidos
dados fictícios, imagens externas ou efeitos decorativos sem relação com o
produto.

## Checagens realizadas

| Checagem | Resultado |
|---|---|
| Sintaxe de `data.js`, `state.js`, `router.js`, `components.js`, `screens.js` e `app.js` com `node --check` | Passou |
| Roteamento por hash, guarda de autenticação e rota 404 | Implementado |
| Login, recuperação, acesso negado e permissão push | Implementado |
| Resumo, serviços e catálogos Livelo/Inter/Pichau | Implementado |
| Abas, busca, filtros, paginação, follow, sheets e dialogs | Implementado |
| Central, perfil, aparência, ajuda, suporte e privacidade | Implementado |
| Administração com frase de confirmação | Implementado como simulação |
| Laboratório de estados e papéis | Implementado |
| Dados remotos, logos e imagens externas | Não utilizados |
| Auditoria de convergência visual | Conceito, composição e componentes reconstruídos |
| Renderização real | Abertura, login e resumo renderizados em navegador local |
| Responsividade | Conferida nas larguras 320, 390, 600, 840 e 1440 px |
| Tema escuro pela interface | Canvas, superfícies e seleção ativa atualizados |
| Foco inicial | Login compacto não salta para o formulário ao abrir |
| Reset visual Delta | Tokens semânticos, tipografia, cards, páginas e dock revistos em uma folha única |
| Catálogo Livelo | Busca, abas, filtros, ações e 4 registros renderizados sem overflow |

## Pendências de validação visual

- Executar uma revisão humana da linguagem visual e dos fluxos Flutter/HTML
  antes do aceite final.
- Revisar navegação por teclado e leitor de tela no navegador escolhido.
- Comparar renderização final Flutter com a matriz de telas e o protótipo após
  o primeiro feedback visual do responsável.
- A simulação de refresh usa timeout local e não prova latência, contrato ou
  comportamento do backend.

## Como registrar divergências

Abra o protótipo pelo laboratório, anote rota, largura, tema, estado e ação
que reproduz o problema. Corrija primeiro os componentes compartilhados; só
depois faça uma exceção no arquivo da tela.
