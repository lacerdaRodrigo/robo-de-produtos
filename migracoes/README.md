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

## Onde são usadas

- Robôs: `001`–`009` e `013`–`020` (coleta Livelo/Inter/produtos, histórico e categorias).
- API do app: `010`–`020` (autenticação, disparos e catálogos).

> **Importante:** aplicar migração em produção é ação explícita e separada — nunca
> feita por esta organização de pastas. Confira `docs/PENDENCIAS.md` antes de
> rodar uma migração ainda não aplicada. O repositório não comprova o estado do
> Neon: confira `docs/PENDENCIAS.md` e o ambiente alvo, especialmente antes da
> `020`, que exige não haver seleção legada de categorias Radar.
