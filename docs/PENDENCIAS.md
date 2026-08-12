# Pendências

Lista viva do que falta. Marcar `[x]` conforme for feito e mover para "Concluído" quando a fase inteira fechar.

O **porquê** de cada item está no [`PRD.md`](PRD.md) ou no [`PRD-V2.md`](PRD-V2.md) — aqui fica só o que fazer e em que ordem.

> Atualizado em 2026-08-11. Versão atual: **1.3.0**.

**Onde estamos:** V2.0 e V2.1 fechadas, mescladas e no ar. A partir da próxima execução agendada o catálogo vem do Neon, com o TOML de reserva. O que sobra é confirmação de e-mail e higiene de conta. A próxima fase de código é a V2.2.

---

## Só você pode fazer (exige conta ou credencial)

- [x] Cadastrar `DATABASE_URL` como secret no GitHub — feito em 2026-08-11. Ensaio geral local no mesmo dia, com a página real e o catálogo vindo do banco: 132 lojas em 10 categorias (idênticas às do TOML), 254 parceiros extraídos, 18 promoções em 7 categorias, e-mail de 12 KB — folgado ante o corte de 102 KB do Gmail (C05)
- [ ] Criar a regra de filtro no Gmail que arquiva os e-mails "sem promoção" (PRD §11.4)
- [ ] Confirmar que a senha de aplicativo antiga do Gmail foi revogada e o secret atualizado
- [ ] Abrir o próximo e-mail e conferir de olho o que nenhum teste vê: validade "Válido até dd/mm" e "Termina hoje!" (RN22), rótulo do Clube (RN23) e o corte de exibição do Gmail (C05). O ensaio local de 2026-08-11 já mostrou o conteúdo correto — 5 "Termina hoje!" e a Sephora com "Clube: 10 pontos (assinantes Clube ganham mais)" — mas ninguém viu ainda como isso fica renderizado no Gmail
- [ ] Trocar a senha do Neon: a `DATABASE_URL` completa foi colada num chat em 2026-08-11. Rotacionar no painel do Neon e atualizar o secret e o `.env` é mais barato que torcer
- [x] Revisar e aceitar os PRs do Dependabot — PRs #1 e #2 mesclados em 2026-08-11; `testes.yml` e `robo.yml` estão em `checkout@v7`/`setup-python@v7`

---

## V1.1 — fechar o que a V1.0 deixou aberto

- [~] **Validar MS3**: workflow `ms3-falha-proposital.yml` na `main` desde 2026-08-11, falhando de propósito de hora em hora (minuto 7) e também sob disparo manual. Já falhou uma vez por disparo manual (run `31550859062`). **Falta você confirmar se o e-mail de falha do GitHub chegou** — é a metade que só você enxerga. Confirmado, o workflow sai do repositório na hora; enquanto ele existir, gera um alarme falso por hora
- [x] Escrever o roteiro do smoke manual (CT-050) em `docs/TESTES.md` — passo a passo com os números esperados de 2026-08-11 como base de comparação
- [x] `versao.yml` atualizado para `actions/checkout@v7` e `actions/setup-python@v7`

---

## V2.0 — extrator lendo o payload JSON

**Estado: concluída e validada contra a página real.** Ver "Concluído" abaixo pelo detalhamento.

Duas validações aconteceram em 2026-08-11, depois do merge:

1. **Em produção**: a execução agendada das 23h27 (run `31546517020`) rodou com o extrator novo, leu 254 parceiros e enviou e-mail com 18 promoções em 7 categorias. Ou seja, o caminho completo funciona contra a página real.
2. **Localmente**: a página foi baixada e passada pelo `extrair_parceiros` desta máquina, reproduzindo os mesmos 254 parceiros. Isso fechou as duas hipóteses que estavam em aberto:

| Hipótese | Veredito |
|---|---|
| `separatorSlug: "ATE"` existe e marca "Até X pontos" (RN12) | **Confirmada.** 36 dos 270 itens usam `"ATE"`, 223 usam `"IGUAL"` |
| Valores reais de `activeCampaign` | **Confirmados**: `BAU` (221), `PROMOTION` (30), `CLUB` (5), `PROMOTION_CLUB` (3), ausente (11) |

O que sobrou disso:

- [x] Tirar o "hipótese não confirmada" do comentário em `extrator.py` e do CT-091 em `docs/TESTES.md` — `"ATE"` está confirmado
- [x] **`PROMOTION_CLUB` ganhou rótulo próprio.** Decisão de 2026-08-11: `CLUB` continua "exclusivo assinantes Clube"; `PROMOTION_CLUB` passa a exibir "assinantes Clube ganham mais", porque nesses a base subiu para todo mundo (Sephora 1→6 com Clube em 10) e a promoção *serve* ao não assinante. `activeCampaign` virou a fonte primária de RN23, com a comparação numérica de reserva para valor desconhecido. RN23 reescrita no PRD-V2 §6.2. CT-103 a CT-105
- [x] Ruído no log reduzido: item sem `parity` nenhuma (produto da própria Livelo) cai em `DEBUG` mais um resumo em `INFO`; `parity` presente e ilegível continua `WARNING`, porque aí é sintoma. CT-106 e CT-107
- [x] `testes/fixtures/payload_parceiros.json` enriquecida com quatro itens copiados da página real de 2026-08-11: Sephora e Coffee Mais (`PROMOTION_CLUB`), Aliexpress (`CLUB` com `separatorSlug: "ATE"`) e Liga Vitória (`parity: null`)

---

## V2.1 — banco de dados

- [x] Criar conta e projeto no Neon
- [x] Esquema com `loja`, `apelido` e `preferencia` (`migracoes/001_esquema.sql`)
- [x] Adaptador `CatalogoPostgres` implementando a porta existente
- [x] Script de carga do TOML para o banco (`scripts/carregar_catalogo.py`)
- [x] Verificar leitura: 132 lojas, 10 categorias, apelidos preservados
- [x] `principal.py` escolher o adaptador conforme `DATABASE_URL` existir, com o arquivo como reserva — `montar_catalogo()` mais o adaptador `CatalogoComReserva`. CT-108, CT-109, CT-114 a CT-116
- [x] Passar `DATABASE_URL` ao workflow `robo.yml`
- [x] Colunas `multiplicador` e `piso_pontos` sendo lidas pelo adaptador — e também pelo TOML, para as duas fontes serem equivalentes. `LojaFavorita` ganhou os dois campos, `None` significando "usa o padrão global" (RN28). CT-110 a CT-112

**Estado: no ar desde 2026-08-11.** Secret cadastrado, código mesclado (PR #4, versão 1.3.0). O ensaio local com a página real e o catálogo do banco fechou nos mesmos números do TOML: 132 lojas, 10 categorias, 3 com apelido, nenhuma com limiar próprio ainda.

Quem usa `multiplicador`/`piso_pontos` é o `alertas.py` da V2.2 — hoje eles são lidos e ficam parados. Foi a ordem escolhida: o adaptador entrega o dado antes de existir quem consome, não o contrário.

> **Ao ligar o secret**, confira na execução seguinte: o log deve dizer "Catalogo lido do banco" e o total de favoritas carregadas deve bater com as 132 do TOML. Se aparecer "Catalogo principal indisponivel", o robô está rodando de reserva — funciona, mas o banco precisa de atenção.

---

## V2.2 — regras de alerta

- [ ] Módulo `alertas.py` no núcleo, com RN27 e RN28
- [ ] Preferências globais `multiplicador_padrao` e `piso_pontos_padrao` vindas do banco
- [ ] Sobrescrita por loja
- [ ] Detectar `parityBau` suspeito: ausência prolongada de alerta não é "não teve promoção" (RN29, C07)
- [ ] E-mail continua diário nesta fase, para permitir calibrar vendo o resultado

**Por que antes da V2.4:** calibrar limiar recebendo e-mail todo dia é fácil. Calibrar quando o e-mail só chega se o limiar já estiver certo é adivinhação.

---

## V2.3 — site

- [ ] Projeto Next.js na Vercel
- [ ] Leitura pública das promoções e do catálogo com pontuação atual (RF15, RN24)
- [ ] Edição protegida por senha única (RF17, PRD V2 §9.0)
- [ ] Mostrar, por loja, pontuação atual, base e o valor que dispara o alerta (RN30)
- [ ] Carimbo de última atualização sempre visível (RN26) — é o que sustenta MS6
- [ ] Versão do projeto no rodapé
- [ ] Sem recurso de terceiros, sem logotipo de parceiro (RN25, PRD V2 §9.2)

---

## V2.4 — e-mail condicional

- [ ] Enviar somente quando alguma favorita cruzar o próprio limiar (RF16)
- [ ] Revogar RF10 no PRD

**Bloqueada até a V2.3 estar no ar e verificada.** Sem o site publicado, cortar o e-mail diário deixa o silêncio ambíguo de novo e reabre o buraco do objetivo O3.

---

## Concluído

- [x] **V1.0** — fatia vertical completa, em produção desde 2026-08-09
- [x] Catálogo com 132 lojas nas categorias Beleza, Marketplace, Moda e Eletro
- [x] Teste de fronteira garantindo que o núcleo não faz I/O
- [x] Guarda automática contra o corte de exibição do Gmail
- [x] Repositório público com CI verde
- [x] Secrets de e-mail configurados e primeira execução real confirmada
- [x] Versionamento semântico automático a partir dos commits
- [x] Dependabot: `checkout@v7` e `setup-python@v7` em `testes.yml` e `robo.yml` (PRs #1 e #2, 2026-08-11)
- [x] Versão **1.2.0** publicada em 2026-08-11, carregando a V2.0
- [x] **V2.0 validada contra a página real** em 2026-08-11 — 254 parceiros extraídos tanto na execução agendada das 23h27 quanto na conferência local; `separatorSlug: "ATE"` e o conjunto de valores de `activeCampaign` confirmados
- [x] **V2.0** — `extrator.py` reescrito para ler o payload `__NEXT_DATA__` em vez do texto dos cards (RF14); `Parceiro` ganhou `pontos_base`, `inicio_promocao`, `fim_promocao` e `campanha`; RN21 (promoção com `dateEnd` no passado não conta), RN22 (destaque "Termina hoje!") e RN23 (marcação de exclusivo Clube) implementadas; `extrair_parceiros`/`montar` ganharam parâmetro `agora` obrigatório para as duas regras de data sem o núcleo ler o relógio por conta própria (exceção ao PRD-V2 §7.2, documentada lá); fixture `testes/fixtures/payload_parceiros.json` criada; casos CT-080 a CT-102
- [x] **V2.1** — `montar_catalogo()` escolhe Postgres ou arquivo conforme `DATABASE_URL`; `CatalogoComReserva` protege a execução contra o Neon fora do ar; `multiplicador`/`piso_pontos` lidos das duas fontes; `DATABASE_URL` passado ao `robo.yml`
- [x] Roteiro do smoke manual CT-050 escrito, com os números de 2026-08-11 como linha de base
- [x] 112 testes, 96% de cobertura, quality gate no CI
