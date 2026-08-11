# Pendências

Lista viva do que falta. Marcar `[x]` conforme for feito e mover para "Concluído" quando a fase inteira fechar.

O **porquê** de cada item está no [`PRD.md`](PRD.md) ou no [`PRD-V2.md`](PRD-V2.md) — aqui fica só o que fazer e em que ordem.

> Atualizado em 2026-08-11. Versão atual: **1.1.0**.

---

## Só você pode fazer (exige conta ou credencial)

- [ ] Cadastrar `DATABASE_URL` como secret no GitHub — necessário antes de o robô ler o catálogo do banco
- [ ] Criar a regra de filtro no Gmail que arquiva os e-mails "sem promoção" (PRD §11.4)
- [ ] Revisar e aceitar os PRs do Dependabot — `checkout@v4` e `setup-python@v5` usam Node 20, descontinuado
- [ ] Confirmar que a senha de aplicativo antiga do Gmail foi revogada e o secret atualizado

---

## V1.1 — fechar o que a V1.0 deixou aberto

- [ ] **Validar MS3**: forçar uma falha de propósito e confirmar que o GitHub notifica. É o único critério do objetivo O3 ainda não provado — hoje você *acredita* que vai ser avisado quando quebrar
- [ ] Escrever o roteiro do smoke manual (CT-050) em `docs/TESTES.md`

---

## V2.0 — extrator lendo o payload JSON

**Estado: concluída.** Ver "Concluído" abaixo pelo detalhamento. Dois pontos ficaram como hipótese não confirmada por falta de exemplo real (registrados em código com comentário e em `docs/TESTES.md`):

- [ ] Confirmar contra a página real se `separatorSlug: "ATE"` é de fato o valor usado para o prefixo "Até X pontos" (RN12) — só `"IGUAL"` foi visto em produção até agora
- [ ] Confirmar o valor real de `activeCampaign` para promoção exclusiva do Clube — RN23 hoje decide por comparação numérica (`pontos_atuais == pontos_base`), não pela string, justamente por não haver exemplo confirmado
- [ ] Recapturar um payload real mais amplo (mais parceiros, mais variedade de campanha) para enriquecer `testes/fixtures/payload_parceiros.json`, hoje majoritariamente construída à mão seguindo o schema confirmado — precisa de acesso de rede à Livelo, que a sessão que fez a V2.0 não tinha

---

## V2.1 — banco de dados

- [x] Criar conta e projeto no Neon
- [x] Esquema com `loja`, `apelido` e `preferencia` (`migracoes/001_esquema.sql`)
- [x] Adaptador `CatalogoPostgres` implementando a porta existente
- [x] Script de carga do TOML para o banco (`scripts/carregar_catalogo.py`)
- [x] Verificar leitura: 132 lojas, 10 categorias, apelidos preservados
- [ ] `principal.py` escolher o adaptador conforme `DATABASE_URL` existir, com o arquivo como reserva
- [ ] Passar `DATABASE_URL` ao workflow `robo.yml`
- [ ] Colunas `multiplicador` e `piso_pontos` sendo lidas pelo adaptador

**Estado:** o banco está pronto e povoado, mas **o robô ainda lê do TOML**. A troca só é segura com a reserva em arquivo, senão o Neon fora do ar derruba a produção.

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
- [x] **V2.0** — `extrator.py` reescrito para ler o payload `__NEXT_DATA__` em vez do texto dos cards (RF14); `Parceiro` ganhou `pontos_base`, `inicio_promocao`, `fim_promocao` e `campanha`; RN21 (promoção com `dateEnd` no passado não conta), RN22 (destaque "Termina hoje!") e RN23 (marcação de exclusivo Clube) implementadas; `extrair_parceiros`/`montar` ganharam parâmetro `agora` obrigatório para as duas regras de data sem o núcleo ler o relógio por conta própria (exceção ao PRD-V2 §7.2, documentada lá); fixture `testes/fixtures/payload_parceiros.json` criada; casos CT-080 a CT-102
- [x] 96 testes, 93% de cobertura, quality gate no CI
