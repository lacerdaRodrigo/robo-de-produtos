# Documentação

Este diretório reúne os documentos de produto, qualidade, operação e decisões
do Radar de Benefícios. Use este índice para localizar o tipo certo de
documentação antes de abrir arquivos isolados.

## Pastas

| Caminho | Conteúdo | Quando consultar |
|---|---|---|
| [`prd/`](prd/) | Requisitos de produto, regras de negócio, contratos, arquitetura e critérios de aceite por domínio. | Antes de implementar ou alterar comportamento de Livelo, Shopping Inter, categorias ou administração. |
| [`planos/`](planos/) | Trabalho futuro que ainda não foi incorporado ao produto. | Ao avaliar ou executar uma evolução que ainda está pendente. |
| [`testes/`](testes/) | Catálogo técnico de casos de teste por módulo. | Ao alterar testes ou confirmar a cobertura esperada de uma regra. |
| [`guias/`](guias/) | Orientações operacionais e de uso do ambiente. | Para tarefas de operação ou configuração descritas no guia correspondente. |

## Planos em avaliação

| Documento | Finalidade |
|---|---|
| [`planos/PLANO-SERVIDOR-ANDROID-PICHAU.md`](planos/PLANO-SERVIDOR-ANDROID-PICHAU.md) | Plano e runbook do Samsung como executor local da coleta Pichau, inclusive operação independente do notebook e da tomada. |
| [`planos/PLANO-VALIDACAO-ANDROID-CASHBACK-INTER-PICHAU.md`](planos/PLANO-VALIDACAO-ANDROID-CASHBACK-INTER-PICHAU.md) | Registro da validação no Samsung, condições completas do Cashback Inter, ADB e três coletas Pichau com `pageSize=200`. |
| [`planos/PLANO-CENTRAL-ALERTAS-SUPORTE-PRIVACIDADE.md`](planos/PLANO-CENTRAL-ALERTAS-SUPORTE-PRIVACIDADE.md) | Plano da Central de Alertas, push, Ajuda, Reportar problema, privacidade e validação visual mobile V11 no Samsung. |

## PRDs de domínio

| Documento | Finalidade |
|---|---|
| [`prd/PRD-PICHAU.md`](prd/PRD-PICHAU.md) | Contrato da jornada Pichau PC Gamer, coletor/API versionados e pendências de operação externa. |
| [`prd/PRD-DISTRIBUICAO-APK.md`](prd/PRD-DISTRIBUICAO-APK.md) | Contrato vigente da geração e distribuição interna da APK pelo Drive privado e e-mail. |

## Documentos na raiz

| Documento | Finalidade |
|---|---|
| [`PENDENCIAS.md`](PENDENCIAS.md) | Lista viva do que continua aberto; não registra trabalho concluído. |
| [`AUDITORIA-COMPLETA-PROJETO.md`](AUDITORIA-COMPLETA-PROJETO.md) | Relatório de auditoria do projeto, com evidências e itens que exigem confirmação externa. |
| [`VALIDACAO-CATEGORIAS-JSON-INTER-2026-09-04.md`](VALIDACAO-CATEGORIAS-JSON-INTER-2026-09-04.md) | Evidência pontual da execução que confirmou a origem das categorias externas do Shopping Inter. O contrato vigente está no PRD de categorias. |

## Ordem sugerida de leitura

1. Abra o PRD do domínio em [`prd/`](prd/).
2. Consulte [`PENDENCIAS.md`](PENDENCIAS.md) para não tratar pendência operacional como concluída.
3. Consulte o catálogo em [`testes/`](testes/) somente quando a mudança afetar comportamento coberto.
4. Use [`planos/`](planos/) apenas para trabalho que ainda não entrou no produto.
