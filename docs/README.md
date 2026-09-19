# Documentação

Este diretório reúne os documentos de produto, qualidade, operação e decisões
do Radar de Benefícios. Use este índice para localizar o tipo certo de
documentação antes de abrir arquivos isolados.

## Pastas

| Caminho | Conteúdo | Quando consultar |
|---|---|---|
| [`prd/`](prd/) | Requisitos de produto, regras de negócio, contratos, arquitetura e critérios de aceite por domínio. | Antes de implementar ou alterar comportamento de Livelo, Shopping Inter, categorias ou administração. |
| [`planos/`](planos/) | Planos e registros de evolução do aplicativo. | Ao revisar decisões de implementação ou evoluções ainda abertas. |
| [`testes/`](testes/) | Catálogo técnico de casos de teste por módulo. | Ao alterar testes ou confirmar a cobertura esperada de uma regra. |
| [`guias/`](guias/) | Orientações operacionais e de uso do ambiente. | Para tarefas de operação ou configuração descritas no guia correspondente. |

## Registros concluídos

| Documento | Finalidade |
|---|---|
| [`prd/PRD-DISTRIBUICAO-ANDROID.md`](prd/PRD-DISTRIBUICAO-ANDROID.md) | Contrato vigente da validação e distribuição privada de APK Android pelo GitHub Actions, Google Drive e e-mail. |
| [`prd/PRD-CENTRAL-ALERTAS-SUPORTE-PRIVACIDADE.md`](prd/PRD-CENTRAL-ALERTAS-SUPORTE-PRIVACIDADE.md) | Contrato da Central de Alertas, suporte, privacidade, acompanhamento pessoal e notificações FCM. |
| [`planos/PLANO-SERVIDOR-ANDROID-PICHAU.md`](planos/PLANO-SERVIDOR-ANDROID-PICHAU.md) | Registro histórico da primeira validação do executor; o contrato vigente e o novo gate de disponibilidade estão no PRD Pichau. |

## Artefatos visuais

| Documento | Finalidade |
|---|---|
| [`../design-app/mobile-v15/index.html`](../design-app/mobile-v15/index.html) | Fonte visual navegável da identidade mobile V15, com temas, assets, estados, jornadas e movimento. |
| [`../design-app/mobile-v15/identidade.html`](../design-app/mobile-v15/identidade.html) | Galeria da marca, ícones, ilustrações e animações oficiais da V15. |
| [`guias/design-v15.md`](guias/design-v15.md) | Contrato visual, componentes, acessibilidade, movimento e cobertura funcional da V15. |

## Execução da V15

| Documento | Finalidade |
|---|---|
| [`planos/PROMPT-MIGRACAO-DEFINITIVA-MOBILE-V15.md`](planos/PROMPT-MIGRACAO-DEFINITIVA-MOBILE-V15.md) | Prompt mestre para substituir integralmente a experiência visual mobile Flutter pela V15 sem regredir regras, API ou autorização. |
| [`planos/DEPENDENCIAS-BACKEND-MOBILE-V15.md`](planos/DEPENDENCIAS-BACKEND-MOBILE-V15.md) | Lacunas de contrato registradas sem alterar backend, especialmente a lista consolidada do Meu radar. |
| [`planos/RELATORIO-TESTE-DEVICE-MOBILE-V15.md`](planos/RELATORIO-TESTE-DEVICE-MOBILE-V15.md) | Registro dos testes manuais no Android, correções, evidências e bloqueios externos da validação V15. |

## PRDs de domínio

| Documento | Finalidade |
|---|---|
| [`prd/PRD-LIVELO.md`](prd/PRD-LIVELO.md) | Base histórica do coletor Livelo e do catálogo V1; o contrato atual de alertas pessoais está no PRD da Central. |
| [`prd/PRD-LIVELO-CATALOGO-ALERTAS-APP.md`](prd/PRD-LIVELO-CATALOGO-ALERTAS-APP.md) | Catálogo Livelo, indicador administrativo legado e jornada mobile; não substitui o contrato pessoal da Central. |
| [`prd/PRD-INTER-CASHBACK.md`](prd/PRD-INTER-CASHBACK.md) | Contrato de Sites parceiros do Inter, cashback e acompanhamento pessoal. |
| [`prd/PRD-INTER-PRODUTOS.md`](prd/PRD-INTER-PRODUTOS.md) | Contrato de Produtos Inter, preço/cashback e acompanhamento pessoal por produto. |
| [`prd/PRD-INTER-PRODUTOS-CATEGORIAS-EXTERNAS.md`](prd/PRD-INTER-PRODUTOS-CATEGORIAS-EXTERNAS.md) | Contrato das categorias externas de Produtos Inter. |
| [`prd/PRD-ADMINISTRACAO.md`](prd/PRD-ADMINISTRACAO.md) | Contrato de autorização e operações administrativas, incluindo seleções globais legadas. |
| [`prd/PRD-PICHAU.md`](prd/PRD-PICHAU.md) | Contrato da jornada Pichau PC Gamer, coletor/API versionados e pendências de operação externa. |

O comportamento comum de eventos, histórico, outbox e push está no PRD da
Central. “Acompanhada” no aplicativo significa relação pessoal em
`acompanhamento_usuario`; seleções globais/admin e o indicador legado de
catálogo não são, sozinhos, garantia de alerta pessoal.

## Documentos na raiz

| Documento | Finalidade |
|---|---|
| [`PENDENCIAS.md`](PENDENCIAS.md) | Lista viva do que continua aberto; não registra trabalho concluído. |
| [`AUDITORIA-COMPLETA-PROJETO.md`](AUDITORIA-COMPLETA-PROJETO.md) | Relatório de auditoria do projeto, com evidências e itens que exigem confirmação externa. |

## Ordem sugerida de leitura

1. Abra o PRD do domínio em [`prd/`](prd/).
2. Consulte [`PENDENCIAS.md`](PENDENCIAS.md) para não tratar pendência operacional como concluída.
3. Consulte o catálogo em [`testes/`](testes/) somente quando a mudança afetar comportamento coberto.
4. Use [`planos/`](planos/) para decisões de evolução, distinguindo registros
   já executados de pendências ainda abertas.
