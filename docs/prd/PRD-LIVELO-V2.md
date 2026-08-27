# PRD — Livelo V2 (delta: payload, banco e régua)

**Status:** V2.0 a V2.3 implementadas. Documento condensado em 27 de agosto de
2026 para representar somente o desenho que permanece no produto.

Este delta explica o que a V2 acrescentou à Livelo. A fonte atual e
prevalecente continua sendo [`prd/PRD-LIVELO.md`](prd/PRD-LIVELO.md). O antigo
canal de notificação foi retirado por decisão do responsável; requisitos,
código e configuração desse canal permanecem apenas no histórico Git.

## 1. Problema que a V2 resolveu

A primeira versão sabia quais lojas apareciam como promoção, mas não tinha base
confiável, validade, catálogo editável nem dado persistido para um cliente. A
página já embutia tudo isso em `__NEXT_DATA__`; raspar apenas o texto visual dos
cards descartava informação útil e era mais frágil.

A V2 passou a:

- ler `parity`, `parityBau`, `parityClub`, `dateStart`, `dateEnd`,
  `activeCampaign` e `legalTerms` do payload;
- usar múltiplo da base e piso absoluto para calcular alertas;
- guardar catálogo, preferências e retratos no Postgres;
- permitir consulta e administração por API autenticada;
- entregar ao Flutter todas as favoritas, não só as alertadas.

## 2. Requisitos acrescentados

| ID | Requisito vigente |
|---|---|
| **RF14** | Extrair os campos Livelo do payload JSON embutido |
| **RF15** | Persistir execução e pontuações de todas as favoritas para API/Flutter |
| **RF16** | **Aposentado:** pertencia ao canal retirado |
| **RF17** | Administrar catálogo e régua por API autenticada |
| **RF18** | Expor a validade de cada campanha quando existir |
| **RF19** | Registrar o instante da coleta em horário de Brasília |

| ID | Requisito não funcional vigente |
|---|---|
| **RNF13** | Evitar dependência desnecessária no cliente |
| **RNF14** | Dados essenciais continuam acessíveis sem depender de efeito visual |
| **RNF15** | Cliente não carrega recurso de parceiro externo |
| **RNF16** | Flutter adapta o layout a Web, Android e iOS |
| **RNF17** | Workflow de coleta mantém `contents: read` |

## 3. Restrições acrescentadas

| ID | Restrição | Resposta |
|---|---|---|
| **C06** | O payload é interno e pode mudar sem aviso | Fixture real, testes e limiar RN13 |
| **C07** | O alerta depende de `parityBau` honesto | Suspeita RN29 |
| **C08** | Neon e Vercel têm limites/termos próprios | Medir antes de ampliar volume |
| **C09** | Neon pode hibernar quando ocioso | Aceitar latência de despertar |

## 4. Regras acrescentadas

| ID | Regra vigente |
|---|---|
| **RN21** | `dateEnd` no passado desativa a campanha |
| **RN22** | O cliente pode destacar campanha que termina no dia da coleta |
| **RN23** | `CLUB` é exclusivo do assinante; `PROMOTION_CLUB` também melhora a pontuação aberta |
| **RN24** | O retrato contém todas as favoritas, inclusive sem alerta ou ausentes na fonte |
| **RN25** | Não carregar imagem, fonte ou script de domínio de parceiro |
| **RN26** | Mostrar o instante da última coleta válida |
| **RN27** | Alertar quando `atual >= base × multiplicador` e `atual >= piso` |
| **RN28** | Multiplicador e piso têm padrão global e sobrescrita opcional por loja |
| **RN29** | Zero alerta com base degenerada em quase toda a página gera suspeita operacional |
| **RN30** | Persistir pontuação atual, base e valor calculado de disparo |
| **RN31** | Transformar `legalTerms` em texto puro; nunca persistir marcação executável |

## 5. Critério de alerta

A etiqueta visual da Livelo não manda na decisão. Ela já apresentou falsos
positivos (pontuação atual igual à base) e falsos negativos (aumento sem etiqueta).

Para cada loja:

```text
valor_de_disparo = max(base × multiplicador, piso)
alertou = pontuacao_efetiva >= valor_de_disparo
```

Padrões atuais: multiplicador `2.0` e piso `4`. Uma loja pode sobrescrever os
dois. Valor `NULL` significa usar o padrão global; zero e ausência não são o
mesmo estado. Cálculos usam `Decimal`/`NUMERIC`.

Quando `parityBau` não existe, o fallback exige a etiqueta ativa e o piso. Para
campanha `CLUB`, a pontuação do tier só vale se `assinante_clube=true`.

RN29 não usa histórico: se nenhuma favorita alertar e pelo menos 90% dos
parceiros com base vierem com atual igual à base, o log marca a rodada como
suspeita de payload degenerado.

## 6. Arquitetura da V2

| Peça | Papel atual |
|---|---|
| `extrator.py` | Ler e validar `__NEXT_DATA__` |
| `alertas.py` | Aplicar RN23, RN27, RN28 e RN29 |
| `retrato.py` | Juntar todas as favoritas ao resultado da execução |
| `CatalogoFavoritas` | Ler Postgres; TOML é reserva diante de indisponibilidade |
| `PreferenciasGlobais` | Ler régua do Postgres; padrões são reserva |
| `RepositorioDeExecucao` | Gravar retrato no Postgres; nulo apenas para diagnóstico local |
| `principal.py` | Resolver ambiente/relógio, orquestrar e tornar falha visível |
| `backend/api/` | Autenticar, administrar e servir contratos ao Flutter |

O banco vazio é decisão válida do responsável e não aciona o TOML de reserva.
A reserva cobre indisponibilidade, não vontade.

Sem `DATABASE_URL`, uma execução local usa TOML/padrões e não persiste. Com
Postgres configurado, falha ao registrar encerra a execução: não existe outro
produto da coleta que justifique deixar o workflow verde com dado velho.

## 7. Dados

```text
loja        id, nome, categoria, multiplicador?, piso_pontos?, criada_em
apelido     id, loja_id, texto
preferencia chave, valor
execucao    id, momento, parceiros_lidos, alertas, versao
pontuacao   id, execucao_id, loja_id?, nome, pontos_*, valor_de_disparo,
            moeda, campanha, descricao_campanha, fim_promocao, link, alertou
```

- `loja_id`/parceiro ausente representa favorita não encontrada na rodada.
- Execução e pontuações são publicadas na mesma transação.
- Link é persistido somente se for HTTP(S) sob `livelo.com.br`.
- Texto externo é tratado como dado hostil.

## 8. Fases registradas

| Fase | Entrega permanente |
|---|---|
| **V2.0** | Payload, validade e campanha |
| **V2.1** | Catálogo no Neon com TOML de reserva |
| **V2.2** | Régua RN27/RN28 e suspeita RN29 |
| **V2.3** | Retratos no banco, API e cliente |
| **V2.4** | Cancelada; requisito aposentado junto do antigo canal |

## 9. Testes mínimos da V2

- validade passada e futura;
- campanhas `CLUB` e `PROMOTION_CLUB`;
- múltiplo, piso, padrão e sobrescrita por loja;
- suspeita RN29 e contraprovas;
- banco vazio sem acionar reserva;
- persistência transacional de todas as favoritas;
- link externo descartado;
- falha de persistência propagada;
- fronteira de núcleo sem I/O.

O catálogo completo de casos está em [`TESTES.md`](TESTES.md).
