# Pendências

Lista viva do que falta. Marcar `[x]` conforme for feito e mover para "Concluído" quando a fase inteira fechar.

O **porquê** de cada item está no [`PRD.md`](PRD.md), no [`PRD-V2.md`](PRD-V2.md), no [`PRD-V3.md`](PRD-V3.md) ou no [`PRD-V4.md`](PRD-V4.md) — aqui fica só o que fazer e em que ordem.

> Atualizado em 2026-08-23. Versão técnica atual: **1.34.0**.

**Onde estamos:** V2.0 a V2.3 fechadas, incluindo V2.3.1 (redesenho de informação), V2.3.2 (banco manda, e o site dispara o robô), V2.3.3 (redesenho visual: grade de cartões, barra de progresso, tema claro/escuro) e V2.3.4 (flags de funcionalidade em `/configuracoes`, como interruptores estilo liga/desliga, verde sempre significando "sumiu da tela": esconder a regra de aviso opcional no cadastro de loja e esconder a tela de Alertas inteira — ambas desligadas por padrão, guardadas em cookie, sem tabela nem migração. Corrigido em 2026-08-12: antes o flag do aviso opcional tinha a lógica invertida da de Alertas — ligado escondia os campos em vez de mostrar — e o padrão de quem nunca mexeu virou campo visível, não mais escondido). O Painel também passou a mostrar a letra miúda da campanha (`legalTerms`/RN31, migração `005` aplicada em 2026-08-12). O site está publicado na Vercel e lê o retrato de cada execução. `GITHUB_TOKEN_DISPARO` cadastrado na Vercel desde 2026-08-13 — botão "Forçar atualização" confirmado habilitado em produção. O parâmetro `enviar_email` no `robo.yml` está feito desde 2026-08-13 — o disparo manual do site já roda em silêncio. Você verificou o site publicado em 2026-08-13 (carimbo, RN30, sem JavaScript) — a V2.4 está destravada, ainda não iniciada. Na madrugada de 2026-08-12 para 13, o e-mail foi redesenhado com marca própria "Pontuação Livelo" (ver `docs/EMAIL.md`) e começou o redesenho de navegação apelidado "V4.6" pelo mockup que o originou — ver seção própria abaixo: a barra lateral, a cor de ação (indigo), o Painel (hero com Top 3, botão "Ir para a Livelo") e a tabela de Lojas (coluna Limiar, ícone de remover) já entraram. Em 2026-08-13, pela manhã, você mandou `novo.html` direto na `main` (fora de PR) — mesmo mockup que já estava em mãos, confirmado byte a byte igual ao HTML colado no chat — e cobrou que o Painel estava "totalmente diferente". Comparação lado a lado (prints do Painel e de Lojas logado contra a leitura do mockup, já que o CDN do Tailwind não carrega neste ambiente) mostrou que a barra lateral, o hero, os cartões e os toggles já batiam; a diferença de verdade era estrutural: o mockup ordena numa grade única, o site ainda agrupava por categoria. Resolvido na quarta fatia (ver abaixo) — os controles de ordenar entraram e o agrupamento por categoria saiu, com busca cobrindo o que o índice de categoria fazia antes. O modal de cadastro do mockup segue de fora por não ganhar nada sobre o formulário inline que já funciona sem JavaScript; só a Central de Alertas fica pendente. O catálogo vem do Neon com o TOML de reserva, e o alerta é decidido por múltiplo da base (RN27), não pela etiqueta da Livelo. O e-mail continua diário de propósito, para calibrar a régua vendo o resultado.

**V3 do Shopping Inter:** implementação publicada pela PR #22. A migração `006` está aplicada no Neon e a primeira execução real terminou com sucesso, cadastrando 381 lojas. A conferência visual final na Vercel continua pendente.

**V4 de produtos diretos:** V4.1–V4.5 estão implementadas. A migração incremental `008` foi aplicada no Neon e o primeiro aceite real, somente com Casas Bahia, terminou em sucesso: 94 páginas, 3.363 itens lidos, 3.310 produtos únicos e Edge 60 Pro retornando na busca local. A correção V4.5.1 para total variável está pronta no código, com a migração `009` ainda pendente no Neon. O próximo rollout é Ponto; projeções para 3, 10 e 111 lojas ainda precisam ser fechadas.

---

## Flutter — Fase 3B (autenticação por convite)

**Fase 3B concluída e validada em produção em 2026-08-20.** O projeto Firebase
`radarbeneficios` está conectado a Web, Android e iOS. O primeiro convite foi
vinculado no acesso real, a API protegida respondeu pelo app instalado no Samsung
SM-M135M e a auditoria registrou o sucesso. A direção final é manter somente a
interface Flutter; a interface web Next.js (`site/`) foi desativada em 2026-08-24
e a API v1 foi arquivada em `backend/api/`.

- [x] Definir Firebase Authentication por e-mail/senha, sem cadastro público
- [x] Conectar Web, Android e iOS pelo FlutterFire, sem segredo administrativo no bundle
- [x] Criar login, recuperação, confirmação de e-mail e encerramento de sessão
- [x] Enviar ID token nas chamadas privadas e manter `/api/status` público
- [x] Validar token e revogação no servidor antes de consultar dados
- [x] Exigir convite ativo, papel e e-mail verificado no Postgres
- [x] Implementar rate limit persistente por origem, usuário e operação
- [x] Auditar com hashes técnicos, sem token, IP, e-mail ou payload bruto
- [x] Preparar e validar token do App Check nos dois lados, com rollout desligado
- [x] Instalar build debug no Samsung SM-M135M e abrir o aplicativo
- [x] Confirmar que o provedor **E-mail/senha** está ativo — criação da conta aceita pelo Firebase
- [x] Aplicar `migracoes/010_autenticacao_app.sql` no Neon — aplicada em 2026-08-20
- [x] Criar o primeiro usuário Firebase e inserir o convite `admin` ativo em `usuario_app`
- [x] Responsável definiu a senha, confirmou o endereço e concluiu o vínculo do UID
      no primeiro acesso real — validado em 2026-08-20
- [x] Configurar na Vercel `FIREBASE_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`,
      `SEGREDO_LIMITE_API` e `EXIGIR_APP_CHECK=false`
- [x] Publicar a API protegida e executar o smoke login → perfil → leitura — APK
      de produção exibiu `Serviço conectado / API v1`; vínculo e auditoria de
      sucesso confirmados no Neon em 2026-08-20
- [x] Habilitar a API Firebase App Check, registrar o token de depuração do Samsung
      SM-M135M e validar o Android com `ATIVAR_APP_CHECK=true` — concluído em
      2026-08-20, sem gravar o token no repositório
- [ ] Registrar/observar App Check em Web e iOS; só depois exigir no servidor
- [x] Definir retenção de 30 dias para `auditoria_app`; cada nova gravação remove
      os eventos vencidos na mesma consulta, sem cron ou credencial adicional
- [ ] Acompanhar atualização de `firebase_app_check`: a versão atual ainda emite aviso
      de migração futura para Built-in Kotlin, sem quebrar o build atual
- [ ] Investigar o `next build` do site: Next 16.3.1 compila, mas falha ao ler
      a saída válida de `tsc --showConfig` com TypeScript 5.9.3; `tsc --noEmit`
      e os 65 testes Vitest passaram em 2026-08-22
- [ ] Remover e recriar o token de depuração do App Check do Samsung após o
      smoke de 2026-08-22: o provedor de depuração o escreveu no log local;
      nunca registrar ou compartilhar esse valor
- [x] Tratar a auditoria npm: Next 16.3.1, React 19.2.8 e dependências corrigidas;
      `npm audit --omit=dev` confirmou zero vulnerabilidades em 2026-08-20

O app Android de teste já envia um token App Check aceito pelo Firebase. A
obrigatoriedade global permanece desligada na API (`EXIGIR_APP_CHECK=false`)
para não bloquear Web/iOS antes de esses dois alvos serem observados.

---

## Flutter — Fase 4 Android primeiro

**Fase 4.2A concluída em 2026-08-20.** O Samsung SM-M135M usa barra inferior
com Início, Livelo, Inter, Alertas e Mais; a seleção troca o `IndexedStack` sem
descartar o estado das áreas. Celular em retrato e paisagem mantém essa barra,
enquanto telas maiores preservam a lateral. O Flutter Web fica por último por
decisão do responsável.

- [x] Implementar navegação inferior para celular sem comprimir a barra lateral
- [x] Preservar os mesmos cinco destinos, rótulos semânticos e estado das abas
- [x] Testar celular em retrato/paisagem e tela larga
- [x] Instalar no Samsung e validar seleção de Início → Livelo
- [x] **Fase 4.2B concluída em 2026-08-22:** substituir o lugar-ocupante de Livelo pelo painel real
  - [x] consumir `/api/livelo/painel` mantendo decimais como texto
  - [x] pesquisar loja/categoria e ordenar por pontos, alerta ou nome
  - [x] carregar todas as páginas sob demanda, sem duplicar itens e ignorando respostas antigas
  - [x] mostrar pontos atuais, base, disparo, Clube, promoção e alerta
  - [x] distinguir carregamento, erro/retry, nenhuma coleta, busca vazia, dado atrasado e loja ausente
  - [x] cobrir modelo, API, paginação e widgets com testes (59 testes Flutter; cobertura crítica 93,00%)
  - [x] gerar APK local de depuração
  - [x] validar no Samsung SM-M135M: login real, App Check, busca, filtros e rotação; a API real expôs duas lojas em uma única página, e paginação/deduplicação em várias páginas seguem cobertas pelo CT-269
  - [x] não inventar coleta parcial/degradada enquanto o endpoint não expuser qualidade
- [ ] **Fase 4.3:** cashback Inter somente leitura — gates locais concluídos;
      falta somente o smoke físico no Samsung antes de concluir
- [ ] **Fase 4.4:** produtos, busca paginada e histórico — gates Flutter locais
      concluídos (87 testes, cobertura crítica >= 90%, builds Web/APK); falta o
      smoke físico no Samsung antes de concluir

---

## Flutter — redesign por telas

O redesign segue o
[`app/PLANO-REDESIGN-POR-TELAS.md`](../app/PLANO-REDESIGN-POR-TELAS.md)
e não libera todas as telas de uma vez. Em 23 de agosto de 2026, o plano passou
a mapear todos os módulos até o fechamento multiplataforma, incluindo
dependências de API, gates visuais e o roteiro automático no Samsung conectado.

- [x] **Etapa 0:** aprovar nome, símbolo, textos, abertura e estrutura do login
- [x] Sincronizar os protótipos Web/Mobile e produzir as duas variantes SVG
- [x] **Etapa 1 local:** aplicar ícones, launch screens e bootstrap Flutter com
      ciclo mínimo de 1,5 segundo, loop durante a validação, demora honesta,
      erro seguro, retry e movimento reduzido
- [x] Passar 137 testes Flutter, análise e formatação
- [x] Instalar e aprovar visualmente a abertura no Samsung SM-M135M conectado
- [x] Planejar os Módulos 1 a 12, separando reskin existente, contrato novo,
      melhoria opcional e funcionalidade futura
- [x] Registrar a autorização para criar/rodar localmente e testar no Samsung,
      sem `push`, publicação, migração, disparo ou mutação real automática
- [ ] Fazer o aceite visual da abertura no navegador quando voltar ao escopo
- [ ] Validar launch screen e ícone em iOS quando houver macOS/Xcode ou aparelho
- [x] Aprovar e implementar o **Módulo 1 — Login** sem mudar Firebase, convite
      ou autorização da API; 131 testes, análise, builds Web/APK e abertura no
      Samsung passaram
- [x] Escolher a gaveta como navegação mobile do **Módulo 2 — Moldura** e manter
      lateral fixa no Web amplo
- [x] Implementar cinco destinos, hub transitório de Lojas, retorno interno e
      preservação de estado; análise, 137 testes, cobertura global de 90,16%,
      builds Web/APK e instalação preservando dados locais passaram
- [x] Fazer o aceite visual final do Módulo 2 no Samsung já aberto
- [x] Aprovar os protótipos e o contrato agregado do **Módulo 3 — Início**
- [x] Implementar localmente `GET /api/resumo` com leituras isoladas de
      Livelo, Cashback Inter e Produtos, sem chamada direta às fontes
- [x] Implementar métricas, prioridade por estado, retry preservando o último
      resumo e quatro atalhos reais no Flutter
- [x] Passar TypeScript, ESLint, 83 testes e build do site; formatação, análise,
      147 testes, 91,29% de cobertura e builds Web/APK no Flutter
- [x] Confirmar que a rota publicada `/api/resumo` continua protegida sem
      credencial e abrir o Início autenticado no Samsung; o resumo carregou em
      build debug com App Check desativado, sem mutação de dados
- [x] Aprovar os protótipos do **Módulo 4 — hub de Lojas**
- [x] Implementar o hub com resumo real por domínio, estados separados de
      Livelo/Cashback/Produtos e retorno preservado; 148 testes, análise e
      builds Web/APK passaram
- [x] Fazer o aceite visual do Módulo 4 no Samsung com o APK novo
- [x] Aprovar os protótipos do **Módulo 5 — hub do Shopping Inter**
- [x] Implementar o hub com Cashback e Produtos separados, retornos explícitos
      e pedidos administrativos por domínio; 150 testes, análise e builds
      Web/APK passaram
- [x] Fazer o aceite visual do Módulo 5 no fluxo aprovado
- [x] Aprovar os protótipos do **Módulo 6 — Produtos e histórico de 30 dias**
- [x] Implementar busca, cartão e histórico redesenhados; 153 testes, análise
      e builds Web/APK passaram

**Execução atual:** Módulos 0 a 5 estão aceitos. O Módulo 6 está pronto
localmente e aguarda somente o aceite visual do responsável; nenhum `push`,
publicação, migração, disparo ou mutação foi feito nesta etapa.

---

## Só você pode fazer (exige conta ou credencial)

- [x] Cadastrar `DATABASE_URL` como secret no GitHub — feito em 2026-08-11. Ensaio geral local no mesmo dia, com a página real e o catálogo vindo do banco: 132 lojas em 10 categorias (idênticas às do TOML), 254 parceiros extraídos, 18 promoções em 7 categorias, e-mail de 12 KB — folgado ante o corte de 102 KB do Gmail (C05)
- [x] Criar a regra de filtro no Gmail que arquiva os e-mails "sem promoção" (PRD §11.4) — feito em 2026-08-13: filtro por `subject:(Livelo: nenhuma promoção nas suas lojas hoje)`, ação "Ignorar caixa de entrada", aplicado retroativamente aos 2 e-mails que já estavam na caixa
- [x] Confirmar que a senha de aplicativo antiga do Gmail foi revogada e o secret atualizado — feito em 2026-08-13
- [x] Abrir o próximo e-mail e conferir de olho o que nenhum teste vê: validade "Válido até dd/mm" e "Termina hoje!" (RN22), rótulo do Clube (RN23) e o corte de exibição do Gmail (C05) — conferido em 2026-08-13 no e-mail real das 21:51 (18 promoções): Fast Shop e Pontofrio com "(Válido até dd/mm)" em cinza, Netshoes e Casas Bahia com "(Termina hoje!)" em destaque, Pontofrio com "Clube: 4 pontos (assinantes Clube ganham mais)" (RN23), e-mail completo até o rodapé sem aviso de corte do Gmail
- [x] Trocar a senha do Neon: a `DATABASE_URL` completa foi colada num chat em 2026-08-11. Rotacionar no painel do Neon e atualizar o secret e o `.env` é mais barato que torcer — feito em 2026-08-13
- [x] Revisar e aceitar os PRs do Dependabot — PRs #1 e #2 mesclados em 2026-08-11; `testes.yml` e `robo.yml` estão em `checkout@v7`/`setup-python@v7`
- [x] Aplicar `migracoes/005_descricao_campanha.sql` no Neon — feito em 2026-08-12, coluna `descricao_campanha` existe em `pontuacao`
- [x] Aplicar `migracoes/006_inter.sql` no Neon e fazer a primeira sincronização — feito em 2026-08-14: 381 lojas, execução em `sucesso`, nenhuma favorita ainda

---

## V3 — Shopping Inter

- [x] **V3.0:** modelos, extrator JSON, ranking, fixture sanitizada e núcleo sem I/O
- [x] **V3.1:** migração `006`, catálogo e snapshot transacionais, identidade por ID externo/slug e primeira sincronização real
- [x] **V3.2:** páginas `/inter` e `/inter/lojas`, busca, seleção, remoção, ranking, descrições e link genérico aprovado
- [x] **V3.3:** workflow independente `inter.yml`, três horários, disparo manual separado, cooldown, carimbo de atraso e preservação do último sucesso após falha
- [x] Validar o endpoint real: 381 lidas e 381 válidas em 2026-08-14, com C&A, Riachuelo e Magalu presentes
- [x] Rodar todos os gates locais: 189 testes Python, 31 testes do site, 91,85% de cobertura, Ruff, TypeScript e build verdes
- [x] Enviar as mudanças à `main`, habilitando `inter.yml` no GitHub Actions e publicando as páginas novas pela Vercel — PR #22 mesclada em 2026-08-17
- [ ] No site publicado, entrar em **Lojas Inter**, acompanhar as primeiras lojas desejadas e forçar uma atualização para conferir os cartões reais

---

## V4 — catálogo de produtos do Compre direto no Inter

- [x] **V4.0:** levantar a fonte pública real, separar Compre direto de Sites parceiros e escrever o `PRD-V4.md`
- [x] Registrar CT-200 em diante como catálogo de testes planejados
- [x] **V4.1 de código:** medidor `backend/robo/scripts/medir_v4.py`, schema/migração `007` e contratos de persistência
- [ ] **V4.1 — gate físico:** paginação, duração e duplicatas medidas na Casas Bahia; falta registrar bytes totais e projeções
- [ ] Projetar volume para 3, 10 e 111 lojas, com três rodadas diárias e retenção de 30 dias
- [x] Fechar em código schema, índices, área de preparação em memória, publicação atômica e expurgo de 30 dias
- [x] **V4.2:** domínio puro, fixture multipágina sintética, extrator, deduplicação e adaptador HTTP
- [x] **V4.3:** seleção de lojas, coleta por loja, snapshot atual e histórico
- [x] **V4.4:** `/inter/produtos`, seleção administrativa e histórico público
- [x] **V4.5:** workflow matricial, `max-parallel: 2`, cooldown de 1,5 s e consolidação da rodada
- [x] **V4.5.1:** total variável conserva até três candidatas completas, publica a maior como degradada e preserva produtos ausentes (`migracoes/009`)
- [x] Validar a primeira loja: Casas Bahia, 3.310 produtos ativos e Edge 60 Pro confirmado
- [ ] Aplicar `migracoes/009_coleta_degradada_produtos_inter.sql` no Neon antes de publicar a V4.5.1
- [ ] Validar Ponto antes de ampliar a seleção

---

## V1.1 — fechar o que a V1.0 deixou aberto

- [x] **Validar MS3**: workflow `ms3-falha-proposital.yml` na `main` desde 2026-08-11, falhando de propósito de hora em hora (minuto 7) e também sob disparo manual. E-mail de falha do GitHub confirmado recebido em 2026-08-12 — workflow apagado do repositório
- [x] **C06 aconteceu de verdade**: em 2026-08-12 a Livelo renomeou a seção de `"C&P - Site - Listagem de Parceiros"` para `"C&P - Site/App - Listagem de Parceiros"`, zerando a extração em produção (`SiteMudou`, RN13 fez o job falhar como esperado, sem e-mail de "sem promoção" mascarando o problema). `TITULO_SECAO_PARCEIROS` em `extrator.py` e a fixture `payload_parceiros.json` atualizados; 253 parceiros extraídos de novo contra a página real
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
- [x] `backend/robo/testes/fixtures/payload_parceiros.json` enriquecida com quatro itens copiados da página real de 2026-08-11: Sephora e Coffee Mais (`PROMOTION_CLUB`), Aliexpress (`CLUB` com `separatorSlug: "ATE"`) e Liga Vitória (`parity: null`)

---

## V2.1 — banco de dados

- [x] Criar conta e projeto no Neon
- [x] Esquema com `loja`, `apelido` e `preferencia` (`migracoes/001_esquema.sql`)
- [x] Adaptador `CatalogoPostgres` implementando a porta existente
- [x] Script de carga do TOML para o banco (`backend/robo/scripts/carregar_catalogo.py`)
- [x] Verificar leitura: 132 lojas, 10 categorias, apelidos preservados
- [x] `principal.py` escolher o adaptador conforme `DATABASE_URL` existir, com o arquivo como reserva — `montar_catalogo()` mais o adaptador `CatalogoComReserva`. CT-108, CT-109, CT-114 a CT-116
- [x] Passar `DATABASE_URL` ao workflow `robo.yml`
- [x] Colunas `multiplicador` e `piso_pontos` sendo lidas pelo adaptador — e também pelo TOML, para as duas fontes serem equivalentes. `LojaFavorita` ganhou os dois campos, `None` significando "usa o padrão global" (RN28). CT-110 a CT-112

**Estado: no ar desde 2026-08-11.** Secret cadastrado, código mesclado (PR #4, versão 1.3.0). O ensaio local com a página real e o catálogo do banco fechou nos mesmos números do TOML: 132 lojas, 10 categorias, 3 com apelido, nenhuma com limiar próprio ainda.

Quem usa `multiplicador`/`piso_pontos` é o `alertas.py` da V2.2 — hoje eles são lidos e ficam parados. Foi a ordem escolhida: o adaptador entrega o dado antes de existir quem consome, não o contrário.

> **Ao ligar o secret**, confira na execução seguinte: o log deve dizer "Catalogo lido do banco" e o total de favoritas carregadas deve bater com as 132 do TOML. Se aparecer "Catalogo principal indisponivel", o robô está rodando de reserva — funciona, mas o banco precisa de atenção.

---

## V2.2 — regras de alerta

- [x] Módulo `alertas.py` no núcleo, com RN27 e RN28
- [x] Preferências globais `multiplicador_padrao` e `piso_pontos_padrao` vindas do banco — porta nova `PreferenciasGlobais`, com os padrões do PRD-V2 §6.1 de reserva
- [x] Sobrescrita por loja
- [x] Detectar `parityBau` suspeito (RN29, C07) — sem contar dias e sem guardar estado: o sintoma afeta a página inteira de uma vez e é visível numa execução só. Decisão registrada no PRD-V2 §6.3
- [x] E-mail continua diário nesta fase, para permitir calibrar vendo o resultado
- [x] Supressão de RN23: `CLUB` não alerta quem não assina; `PROMOTION_CLUB` alerta

**Por que antes da V2.4:** calibrar limiar recebendo e-mail todo dia é fácil. Calibrar quando o e-mail só chega se o limiar já estiver certo é adivinhação.

**Medido contra a página real em 2026-08-11** (régua padrão 2,0x e piso 4): o critério antigo dava 18 lojas, RN27 dá **15**. Saíram `Mercado Livre` 1→2, `Bibi` 1→2 e `Electrolux` 1→2 (dobrou, mas são 2 pontos) e `Booking.com` 4→6 (subiu, mas não dobrou). Entrou `Avon` 2→6, que triplicou **sem etiqueta nenhuma** — o alerta que a V1 nunca mandava.

### Calibragem — a fazer olhando o e-mail chegar

- [ ] Depois de duas ou três semanas recebendo, decidir se 2,0x e piso 4 servem. Sensibilidade medida no mesmo dia: `2,5x piso 4` → 14 lojas, `3,0x piso 4` → 11, `2,0x piso 6` → 7. **O piso é o botão mais sensível**
- [ ] Só então sobrescrever loja por loja, e só as que incomodarem (PRD-V2 §6.1). Configurar 132 limiares na largada é armadilha
- [ ] Ajustar direto no banco: `UPDATE preferencia SET valor = '2.5' WHERE chave = 'multiplicador_padrao'`. Vale na execução seguinte, sem `git push`

---

## V2.3 — site

**Metade 1 (feita): o robô virou fonte do site.** Sem isso o site não teria o que mostrar — a pontuação atual só existe durante a execução.

- [x] Migração `002_execucao.sql`: tabelas `execucao` e `pontuacao`, aplicada no Neon em 2026-08-11
- [x] Porta `RepositorioDeExecucao` — era o "ponto de extensão documentado, não implementado" do PRD §4.2 desde a V1
- [x] Núcleo `retrato.py`: junta cada favorita com o que a página disse dela (RN24, RN30)
- [x] Gravar não derruba a execução: falha vira `WARNING`, porque a consequência é site velho e o carimbo de RN26 denuncia isso sozinho
- [x] Ensaio real: 132 pontuações gravadas, 15 alertas, carimbo e versão na tabela `execucao`

**Metade 2 (feita): o site.**

- [x] Projeto Next.js em `site/`, pronto para a Vercel
- [x] Leitura pública das promoções e do catálogo com pontuação atual (RF15, RN24)
- [x] Edição protegida por senha única (RF17, PRD V2 §9.0): cookie `httpOnly`+`secure`, comparação em tempo constante, limite de 5 tentativas por 15 min gravado no banco (migração `003`)
- [x] Mostrar, por loja, pontuação atual, base e o valor que dispara o alerta (RN30)
- [x] Carimbo de última atualização sempre visível (RN26), que fica vermelho depois de 12 h
- [x] Versão no rodapé — a que gerou o dado, vinda da tabela `execucao`
- [x] Sem recurso de terceiros, sem logotipo de parceiro (RN25, PRD V2 §9.2) — verificado no HTML servido
- [x] Funciona sem JavaScript (RNF14), formulários inclusive — verificado: 147 cartões no HTML com todas as `<script>` removidas

### V2.3.1 — redesenho (feito)

- [x] Uma tela por tarefa: `/` pontuação, `/avisos` régua, `/lojas` cadastro, `/ajuda` FAQ
- [x] Linguagem comum na tela; o termo técnico do PRD ficou no tooltip
- [x] Tooltips `(?)` sem JavaScript, funcionando no toque e no teclado
- [x] Ajuda com nove perguntas, escrita para quem esqueceu como o sistema decide
- [x] Ícone de entrar no topo; login devolve para a tela de onde saiu
- [x] Busca por nome e índice de categorias, que é o que torna 130 lojas navegáveis no celular
- [x] Nenhuma tela alcançável só digitando URL

### V2.3.2 — o banco manda, e o site dispara (feito)

- [x] Banco vazio deixa de cair no TOML: apagar pelo site passa a valer de verdade. A reserva cobre indisponibilidade, não vontade
- [x] E-mail de catálogo vazio com assunto próprio, para não se confundir com "nenhuma promoção hoje"
- [x] Botão **Forçar atualização** (ex-"Atualizar agora") em Lojas: pede ao GitHub que rode o robô, e a lista sai com as suas mudanças em cerca de um minuto
- [x] Trava de 5 minutos entre disparos manuais (migração `004`), por causa de RNF02
- [x] **Dívida combinada:** hoje o disparo manual manda e-mail igual ao agendado, para você conferir se veio certo. Quando confiar no resultado, o `robo.yml` ganha um parâmetro `enviar_email` e o disparo do site passa a rodar em silêncio — cadastrar dez lojas numa tarde geraria dez e-mails idênticos, e o dia em que você começar a ignorar o e-mail é o dia em que ele deixa de servir de sinal de vida — feito em 2026-08-13: `workflow_dispatch.inputs.enviar_email` (padrão `true`) vira `ENVIAR_EMAIL` no ambiente, `verificar_promocoes` recebe `enviar_email` e pula só o notificador — retrato continua sendo gravado igual. `dispararRobo()` manda `enviar_email: "false"` no botão do site; o agendado nunca preenche `inputs`, então continua mandando sempre. CT-168
- [x] Criar o **fine-grained token** no GitHub (acesso só a `robo-livelo`, permissão *Actions: read and write*) e cadastrar na Vercel como `GITHUB_TOKEN_DISPARO`. Sem ele o botão fica desabilitado explicando o que falta — confirmado em 2026-08-13: botão "Forçar atualização" em `/lojas` aparece habilitado em produção

### Só você pode fazer

- [x] Criar o projeto na Vercel apontando para este repositório, com **Root Directory = `site`**
- [x] Cadastrar `SENHA_SITE` (longa e aleatória) e `SEGREDO_SESSAO` nas Environment Variables, além de `DATABASE_URL`
- [x] Abrir a página publicada e conferir o carimbo, RN30 e o comportamento sem JavaScript — conferido em 2026-08-13 em `robo-livelo.vercel.app`: carimbo "Sincronizado há 21 min (12/08/2026, 21:51)" com bolinha verde; cada card mostra pontuação atual, "Normal: X" (base) e "Aviso: X" (limiar do alerta), RN30 atendida; HTML servido pelo Vercel já vem com os 36 cartões e barras de progresso prontos sem nenhum `<script>`, funciona sem JavaScript

---

## V4.6 — redesenho de navegação (sidebar)

> "V4.6" é o nome que o próprio mockup usa (não é a versão do projeto, que segue solta via `semantic-release` — hoje 1.15.x). Guardado aqui só para achar o design de origem: HTML estático completo (sidebar escura, cards, toggles) mandado no chat em 2026-08-13, com uma versão em PDF idêntica.

**Feito (primeira fatia, madrugada de 2026-08-12 para 13):**

- [x] Cabeçalho fixo virou barra lateral: coluna fixa a partir de 768px (Painel/Alertas/Lojas/Ajuda no corpo; Configurações/Tema/Sair no rodapé), barra superior compacta no celular. Mesmo componente (`componentes/cabecalho.tsx`), chamado do mesmo jeito nas 8 páginas — nada mudou fora dele e de `globals.css`
- [x] Cor de ação virou indigo (`--marca`, novo token) e o rosa (`--acento`) ficou reservado só para alerta — separa "isso é um botão" de "isso pede atenção" — com variantes de tema claro/escuro
- [x] Ícones do menu são SVG inline, escritos à mão (RN25 — nenhum ícone de CDN, ao contrário do mockup original que usa `unpkg.com/lucide`)
- [x] O logo real (`/public/logo.png`, "R$ vira ponto") entrou na barra lateral — precisou de um chip branco atrás dele: o quadrado "R$" da marca usa um tom quase branco pensado pro fundo claro do resto do site, e sumia de contraste no fundo escuro da lateral

**Feito (segunda fatia, 2026-08-13):**

- [x] Painel: hero escuro no topo (mesma paleta `--lateral-*` da barra lateral) com contagem de lojas monitoradas e parceiros lidos, badge "N alertas ativos" e "Top 3 Oportunidade" — as três lojas de maior pontuação atual, calculada só para ordenar (nunca para exibir texto, mesma ressalva de `barraDeProgresso` em PRD 5.4)
- [x] Botão **"Ir para a Livelo"** em todo cartão de loja com link, ao lado de "Ajustar alerta" — antes só o nome da loja era clicável
- [x] ~~Controles de ordenar~~ — feito na quarta fatia, ver abaixo. A decisão de "não fazer ainda" foi revista: você pediu explicitamente para seguir a funcionalidade do mockup, e o conflito com o agrupamento por categoria foi resolvido abandonando o agrupamento, não os controles

**Feito (terceira fatia, 2026-08-13):**

- [x] Lojas: tabela de "Lojas cadastradas" ganhou coluna **Limiar** — mostra "Padrão de todas" ou o multiplicador/piso próprio da loja (dados que já existiam em `Loja.multiplicador`/`Loja.piso_pontos`, só não apareciam na tabela). Botão "Remover" virou ícone de lixeira, linha destaca no hover
- [ ] Modal de "Adicionar loja" do mockup: **não fez.** O formulário inline que já existe cumpre RNF14 (funciona sem JavaScript) sem precisar de modal — um modal de verdade, sem JS, exigiria `<dialog>` ou o truque de `:target`, e não parecia ganho nenhum trocar algo que já funciona bem

**Feito (quarta fatia, 2026-08-13, em resposta a "totalmente diferente"):**

- [x] Painel: agrupamento por categoria (títulos `<h2>` + índice `#âncora` do topo) saiu, deu lugar a uma grade única — igual ao mockup. Ordenar (`?ordenar=pontos|alerta|nome`, links comuns, funciona sem JavaScript) troca entre "Maior pontuação" (padrão — quem não apareceu na Livelo vai por último, nunca pro topo), "Em alerta" (filtra, só quem cruzou o próprio limite) e "Nome A-Z". A busca (`?q=`) continua cobrindo nome e categoria, então procurar "moda" ainda acha as lojas de Moda — o que o índice fazia por clique, a busca faz por texto
- [x] Cada cartão de loja ganhou uma etiqueta de categoria (reaproveitando `.etiqueta`, mesmo componente visual do "Alerta ativo"), já que a categoria não aparece mais como título de seção
- [x] Lógica de ordenação extraída para `ordenarLojas()` em `lib/formato.ts` (`Number()` só decide posição na lista, nunca vira texto — mesma ressalva de `barraDeProgresso`, PRD 5.4), com testes próprios (CT-174, `testes/formato.teste.ts`) — a pedido explícito de focar em testes nesta rodada, já que muita coisa mudou
- [ ] "+X% avanço" do mockup (crescimento sobre o normal da loja, como texto): **decidido não fazer.** É `Number()` virando texto na tela, o que PRD 5.4 proíbe fora da ressalva de ordenação/geometria — o mesmo cuidado que já existe pra não devolver "2,9000000000000004"
- [ ] Pílula "Monitorando" em todo cartão sem alerta (mockup mostra status em todos): **decidido não fazer.** Cartão sem alerta já se distingue visualmente (sem borda rosa, sem etiqueta "Alerta ativo") — uma pílula cinza a mais em ~130 cartões seria ruído sem contraste com nada

**Feito (quinta fatia, 2026-08-13):**

- [x] Botão "Forçar atualização" saiu do fim de `/lojas` e foi para a barra lateral, logo abaixo de "Lojas" — igual ao mockup, que tem "Executar Robô" fixo no menu, não escondido no fim de uma tela. `Cabecalho` busca a trava de 5 minutos (RNF02) e o token só quando há sessão, pra não gastar consulta ao banco em visita anônima; o clique continua voltando pra `/lojas`, onde o recado de sucesso/espera/sem-token aparece. O bloco "Terminou de mexer?" (`.bloco.destaque`, agora sem uso) saiu junto
- [x] **Bug de verdade encontrado nessa mudança, não só reskin**: com sessão, a barra compacta do celular (abaixo de 768px) tinha 5 itens de menu + 3 de rodapé competindo por ~360px — o nome "Pontuação Livelo" ao lado do logo mais o rodapé cheio deixavam só ~77px pra navegação, que precisava rolar quase sem indício visual disso. É provavelmente a causa real do "veio quebrado" relatado no celular que não tinha sido reproduzido antes (a investigação anterior só cobriu telas com menos itens). Corrigido escondendo `.bl-marca-nome` abaixo de 480px — sobra ~206px pra navegação, cabe quase tudo, só "Ajuda" fica parcialmente visível na borda (rolagem com indício, não escondida)

**Pendente, na ordem do mockup:**

- [ ] Central de Alertas: **funcionalidade nova de verdade, não só reskin.** O mockup mostra histórico de e-mails enviados com "Ver Payload" — hoje o site só sabe "quem alertou nesta execução" (RN27, uma foto só). Um histórico de verdade (quem foi avisado, quando, o que tinha no e-mail) exige tabela nova e mudança em `principal.py`/`montador_email.py` para gravar cada envio, não só o retrato. Fica pendente de desenho — não é para fazer sem pensar no esquema primeiro
- [ ] Toggle "Disparo de e-mails automático" do mockup: **decidido não implementar por enquanto.** Controlar se o robô manda e-mail é literalmente RF16/V2.4 (ver abaixo), que só destravou em 2026-08-13 e ainda não começou — reabrir isso por atalho, com um toggle vistoso que não muda nada de verdade no robô, seria pior que não ter o toggle

Nota de convivência com o resto do trabalho que aconteceu na mesma noite (redesenho do e-mail, disparo silencioso, V2.4 destravada — ver "Concluído" abaixo): a barra lateral foi construída **por cima** dessas mudanças, não substituindo nada — o toggle bonito (`.interruptor`/`.linha-interruptor`) de `/configuracoes`, a lógica corrigida da flag de aviso opcional e o logo em `/public` continuam exatamente como estavam.

---

## V2.4 — e-mail condicional

- [ ] Enviar somente quando alguma favorita cruzar o próprio limiar (RF16)
- [ ] Revogar RF10 no PRD

**Destravada em 2026-08-13.** Estava bloqueada até a V2.3 estar no ar e verificada — sem o site publicado, cortar o e-mail diário deixaria o silêncio ambíguo de novo e reabriria o buraco do objetivo O3. Você conferiu o site publicado (carimbo, RN30, sem JavaScript) nessa data, então o gatilho aconteceu. Ainda não iniciada.

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
- [x] **V2.0** — `extrator.py` reescrito para ler o payload `__NEXT_DATA__` em vez do texto dos cards (RF14); `Parceiro` ganhou `pontos_base`, `inicio_promocao`, `fim_promocao` e `campanha`; RN21 (promoção com `dateEnd` no passado não conta), RN22 (destaque "Termina hoje!") e RN23 (marcação de exclusivo Clube) implementadas; `extrair_parceiros`/`montar` ganharam parâmetro `agora` obrigatório para as duas regras de data sem o núcleo ler o relógio por conta própria (exceção ao PRD-V2 §7.2, documentada lá); fixture `backend/robo/testes/fixtures/payload_parceiros.json` criada; casos CT-080 a CT-102
- [x] **V2.1** — `montar_catalogo()` escolhe Postgres ou arquivo conforme `DATABASE_URL`; `CatalogoComReserva` protege a execução contra o Neon fora do ar; `multiplicador`/`piso_pontos` lidos das duas fontes; `DATABASE_URL` passado ao `robo.yml`
- [x] Roteiro do smoke manual CT-050 escrito, com os números de 2026-08-11 como linha de base
- [x] **V2.2** — `alertas.py` no núcleo com RN27 (múltiplo da base com piso), RN28 (padrão global sobrescrito por loja), RN29 (suspeita de C07 sem guardar estado) e a supressão de RN23 para quem não assina o Clube; porta nova `PreferenciasGlobais` lendo a tabela `preferencia`; `categorias.agrupar` passa a receber o critério em vez de olhar a etiqueta. CT-117 a CT-138
- [x] **V2.3, metade 1** — o robô grava o retrato de cada execução: migração `002`, porta `RepositorioDeExecucao`, núcleo `retrato.py`. CT-139 a CT-150
- [x] **V2.3, metade 2** — site Next.js em `site/`: leitura pública, edição com senha única e limite de tentativas, RN24/RN25/RN26/RN30 e RNF14 atendidos. CT-151 a CT-155
- [x] 189 testes no robô e 31 no site, 91,85% de cobertura Python, quality gate local para os dois
- [x] **Redesign do e-mail e marca "Pontuação Livelo"** (2026-08-13) — `montador_email.py` reescrito: bloco de cor sólida por oferta em vez de card com borda fina, categoria vira selo com contador, descrição de campanha (`descricao_campanha`, RN31) expansível via `<details>/<summary>` sem JavaScript ("…mais"/"▲ menos"). CSS movido pra um único `<style>` no `<head>` e nomes de classe encurtados — o pior caso (132 lojas, Clube, descrição longa em todas) cabe em ~93 KB, ~11 KB de folga antes do corte do Gmail (C05). Marca "R$ vira ponto" criada a partir do que o sistema faz (dinheiro→pontos, não um ícone genérico), vetor em `site/public/logo.svg`, rasterizada em PNG: cabeçalho e rodapé do site (todas as telas), título do navegador via convenção `app/icon.png` do Next.js, e topo/rodapé do e-mail apontando pra `https://robo-livelo.vercel.app/logo.png` (não base64 — confirmado ao vivo que o Gmail descarta `data:` URI em e-mail, só página web aceita). Confirmado disparando e-mail real duas vezes: primeira tentativa tinha `<style>` fora do `<head>` (Gmail descarta a folha inteira) e cor por categoria via custom property CSS num `style=` inline (Gmail remove `--x` do atributo, só `background`/`color` direto sobrevivem) — os dois corrigidos no mesmo dia. Detalhes completos, incluindo as três lições do Gmail, em [`docs/EMAIL.md`](EMAIL.md). CT-168 a CT-173
