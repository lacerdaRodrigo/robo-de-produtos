# Fechamento das dependências de backend do Mobile V15

Status: contrato implementado localmente na branch
`codex/backend-mobile-v15-fechamento`. A lista consolidada do Meu radar e o
bloco pessoal da Home já têm rota, modelo, testes e integração Flutter. Este
arquivo deixou de ser uma especificação de trabalho pendente; o plano de
execução e o checkpoint operacional permanecem em
[`PLANO-BACKEND-E-RETESTE-MOBILE-V15.md`](PLANO-BACKEND-E-RETESTE-MOBILE-V15.md).

## Contratos fechados

- `GET /api/alertas/acompanhamentos` lê somente `usuario_app_id` autenticado,
  pagina no banco, filtra por nome/origem, ordena por atualização/nome e
  devolve as quatro origens sempre presentes em `totais_por_origem`.
- `PATCH /api/alertas/acompanhamentos` continua compatível e mantém a mutação
  pessoal isolada da seleção administrativa/global.
- `GET /api/resumo` acrescenta `radar`, com total pessoal, contagens por origem,
  não lidos e o alerta não lido mais recente. O campo antigo
  `atividade_recente` permanece para compatibilidade.
- Valores monetários e de pontuação continuam texto decimal; URLs externas são
  normalizadas e aceitas somente com `http` ou `https`.
- A migration aditiva `migracoes/029_indices_mobile_v15.sql` cria somente os
  índices necessários para a lista e o destaque não lido.

## Trabalho concluído no código

- Backend: rota, consultas separadas por domínio, resumo pessoal e testes Vitest.
- Flutter: modelos, cliente API, Home real, Meu radar paginado, filtros,
  remoção otimista/desfazer/rollback, movimento reduzido e sessão expirada.
- Documentação: PRD da Central, catálogo técnico, pendências e README de
  migrations atualizados.

## Checkpoint externo ainda aberto

A migration 029 ainda não foi aplicada pelo Codex. O responsável deve aplicá-la
em conexão direta/unpooled no ambiente de teste, usando o arquivo versionado e
as consultas de verificação do plano. Depois da confirmação, o próximo ciclo
é publicar a API, instalar o APK e executar o reteste físico autorizado. Não
há segredo, credencial, backup ou URL privada neste documento.

## Lacuna de dados ilustrativos

O protótipo ainda pode mostrar composições visuais que exigem um item recente;
o Flutter usa somente `radar.destaque` quando o backend possui esse evento e
mantém estado indisponível/sem dados quando não possui. Nenhum dado ilustrativo
é promovido a dado de produção.
