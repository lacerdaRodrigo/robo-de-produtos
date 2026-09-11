# `migracoes/` — Schema do Postgres (Neon)

Migrações SQL **aplicadas manualmente** no Postgres (Neon). Cada arquivo é
idempotente e numerado na ordem em que evoluiu o schema. `scripts/carregar_catalogo.py`
cria o `001` e carrega o catálogo.

## Migrações

| Arquivo | Cria/altera | Domínio |
|---|---|---|
| `001_esquema.sql` | `loja`, `apelido`, `preferencia` | Livelo catálogo |
| `002_execucao.sql` | `execucao`, `pontuacao` (retrato) | Livelo site |
| `003_tentativa_login.sql` | `tentativa_login` | autenticação do site legado |
| `004_disparo_manual.sql` | `disparo_manual` (trava 5 min) | site → robô |
| `005_descricao_campanha.sql` | `pontuacao.descricao_campanha` | Livelo |
| `006_inter.sql` | `loja_inter`, `favorita_inter`, `cashback_inter`, `execucao_inter` | Inter V3 |
| `007_produtos_inter.sql` | lojas/execuções/produtos/medições do Compre direto | V4 |
| `008_contrato_real_produtos_inter.sql` | colunas de texto de preço/desconto | V4 |
| `009_coleta_degradada_produtos_inter.sql` | `qualidade`, `tentativas`, totais | V4 |
| `010_autenticacao_app.sql` | `usuario_app`, `auditoria_app` (Firebase) | app (API) |
| `011_disparos_api_idempotentes.sql` | `solicitacao_disparo_app` (cooldown API) | app (API) |
| `012_oferta_direta_inter_atual.sql` | `oferta_direta_inter_atual` (limpeza V5) | V4 |
| `013_catalogo_livelo.sql` | catálogo completo e vínculo opcional com `loja` | Livelo |
| `014_alerta_no_card.sql` | alerta calculado no retrato atual | Livelo |
| `015_historico_catalogo_livelo.sql` | identidade da medição por parceiro e índice do histórico completo | Livelo |
| `016_preserva_historico_livelo.sql` | separa acompanhamento da identidade histórica | Livelo |
| `017_qualidade_livelo.sql` | registra RN29 sem substituir o último snapshot completo | Livelo |
| `018_categorias_produtos_inter.sql` | taxonomia Radar e classificação auditável de categorias | Inter produtos (histórico) |
| `019_classificacao_exata_categorias_produtos_inter.sql` | semeia somente mapeamentos por igualdade exata | Inter produtos (histórico) |
| `020_categorias_inter_fonte_oficial.sql` | substitui a taxonomia Radar por categorias externas exatas do Inter | Inter produtos |
| `021_pichau_pc_gamer.sql` | catálogo/histórico persistido de PCs Gamer | Pichau |
| `022_pichau_android_fila.sql` | fila idempotente do executor Android | Pichau |
| `023_alertas_suporte_privacidade.sql` | acompanhamentos pessoais, eventos, preferências, tokens FCM, outbox e relatos | Central de Alertas/app |
| `024_pichau_android_diagnostico.sql` | diagnóstico JSONB seguro e limitado na fila Android | Pichau |

## Onde são usadas

- Robôs: `001`–`009`, `013`–`022` e `024` (coleta Livelo/Inter/produtos, histórico, categorias e Pichau).
- API do app: `010`–`020` e `023` (autenticação, disparos, catálogos e Central de Alertas).

> **Importante:** aplicar migração em produção é ação explícita e separada — nunca
> feita por esta organização de pastas. Conforme confirmação operacional do
> responsável, as migrations `001`–`024` foram aplicadas manualmente no banco
> alvo. Este checkout não executa nem verifica migrations automaticamente.

`023` foi aplicada manualmente no banco alvo. Este checkout não executou a SQL
nem produziu evidência independente; a confirmação operacional permanece
externa ao repositório.

`024` depende somente de `022` e não aplica nem exige a `023`. Em 2026-09-10,
ela foi validada numa branch temporária derivada de `production`: coluna e
constraints válidas, 47 linhas antigas compatíveis com `{}` e grants existentes
de `pichau_dispatcher` (`SELECT/INSERT`) e `pichau_publisher`
(`SELECT/UPDATE`) preservados. A branch foi descartada sem alterar
`production`. Depois da confirmação do responsável, a migration foi aplicada
em `production`; a verificação somente de leitura confirmou os mesmos
resultados nas 47 linhas existentes.
