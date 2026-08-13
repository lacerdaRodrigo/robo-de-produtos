# Pendências

Lista viva do que falta. Marcar `[x]` conforme for feito e mover para "Concluído" quando a fase inteira fechar.

O **porquê** de cada item está no [`PRD.md`](PRD.md) ou no [`PRD-V2.md`](PRD-V2.md) — aqui fica só o que fazer e em que ordem.

> Atualizado em 2026-08-13. Versão atual: **1.15.x**.

**Onde estamos:** V2.0 a V2.3 fechadas, incluindo V2.3.1 (redesenho de informação), V2.3.2 (banco manda, e o site dispara o robô), V2.3.3 (redesenho visual: grade de cartões, barra de progresso, tema claro/escuro) e V2.3.4 (flags de funcionalidade em `/configuracoes`, como interruptores estilo liga/desliga, verde sempre significando "sumiu da tela": esconder a regra de aviso opcional no cadastro de loja e esconder a tela de Alertas inteira — ambas desligadas por padrão, guardadas em cookie, sem tabela nem migração. Corrigido em 2026-08-12: antes o flag do aviso opcional tinha a lógica invertida da de Alertas — ligado escondia os campos em vez de mostrar — e o padrão de quem nunca mexeu virou campo visível, não mais escondido). O Painel também passou a mostrar a letra miúda da campanha (`legalTerms`/RN31, migração `005` aplicada em 2026-08-12). O site está publicado na Vercel e lê o retrato de cada execução. `GITHUB_TOKEN_DISPARO` cadastrado na Vercel desde 2026-08-13 — botão "Forçar atualização" confirmado habilitado em produção. O parâmetro `enviar_email` no `robo.yml` está feito desde 2026-08-13 — o disparo manual do site já roda em silêncio. Você verificou o site publicado em 2026-08-13 (carimbo, RN30, sem JavaScript) — a V2.4 está destravada, ainda não iniciada. Na madrugada de 2026-08-12 para 13, o e-mail foi redesenhado com marca própria "Pontuação Livelo" (ver `docs/EMAIL.md`) e começou o redesenho de navegação apelidado "V4.6" pelo mockup que o originou — ver seção própria abaixo: a barra lateral, a cor de ação (indigo) e o Painel (hero com Top 3, botão "Ir para a Livelo") já entraram; Lojas e Central de Alertas ficam pendentes, e os controles de ordenar do mockup foram deixados de fora de propósito por conflitarem com o agrupamento por categoria que já existe. O catálogo vem do Neon com o TOML de reserva, e o alerta é decidido por múltiplo da base (RN27), não pela etiqueta da Livelo. O e-mail continua diário de propósito, para calibrar a régua vendo o resultado.

---

## Só você pode fazer (exige conta ou credencial)

- [x] Cadastrar `DATABASE_URL` como secret no GitHub — feito em 2026-08-11. Ensaio geral local no mesmo dia, com a página real e o catálogo vindo do banco: 132 lojas em 10 categorias (idênticas às do TOML), 254 parceiros extraídos, 18 promoções em 7 categorias, e-mail de 12 KB — folgado ante o corte de 102 KB do Gmail (C05)
- [x] Criar a regra de filtro no Gmail que arquiva os e-mails "sem promoção" (PRD §11.4) — feito em 2026-08-13: filtro por `subject:(Livelo: nenhuma promoção nas suas lojas hoje)`, ação "Ignorar caixa de entrada", aplicado retroativamente aos 2 e-mails que já estavam na caixa
- [x] Confirmar que a senha de aplicativo antiga do Gmail foi revogada e o secret atualizado — feito em 2026-08-13
- [x] Abrir o próximo e-mail e conferir de olho o que nenhum teste vê: validade "Válido até dd/mm" e "Termina hoje!" (RN22), rótulo do Clube (RN23) e o corte de exibição do Gmail (C05) — conferido em 2026-08-13 no e-mail real das 21:51 (18 promoções): Fast Shop e Pontofrio com "(Válido até dd/mm)" em cinza, Netshoes e Casas Bahia com "(Termina hoje!)" em destaque, Pontofrio com "Clube: 4 pontos (assinantes Clube ganham mais)" (RN23), e-mail completo até o rodapé sem aviso de corte do Gmail
- [x] Trocar a senha do Neon: a `DATABASE_URL` completa foi colada num chat em 2026-08-11. Rotacionar no painel do Neon e atualizar o secret e o `.env` é mais barato que torcer — feito em 2026-08-13
- [x] Revisar e aceitar os PRs do Dependabot — PRs #1 e #2 mesclados em 2026-08-11; `testes.yml` e `robo.yml` estão em `checkout@v7`/`setup-python@v7`
- [x] Aplicar `migracoes/005_descricao_campanha.sql` no Neon — feito em 2026-08-12, coluna `descricao_campanha` existe em `pontuacao`

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
- [ ] Controles de ordenar (Maior Pontuação / Em Alerta / Nome A-Z) do mockup: **decidido não fazer ainda.** O mockup ordena numa lista única, sem agrupar por categoria; o site agrupa por categoria com índice de navegação (essencial pra achar uma loja entre 132) desde a V2.3.1. Encaixar as duas coisas — ordenar dentro de cada grupo, ou abandonar o agrupamento quando ordenado — é decisão de UX visível, não reskin puro. Fica para confirmar antes de implementar

**Pendente, na ordem do mockup:**

- [ ] Lojas: cadastro existente reestilizado como tabela de linha única por loja, com ações à direita
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
- [x] **V2.0** — `extrator.py` reescrito para ler o payload `__NEXT_DATA__` em vez do texto dos cards (RF14); `Parceiro` ganhou `pontos_base`, `inicio_promocao`, `fim_promocao` e `campanha`; RN21 (promoção com `dateEnd` no passado não conta), RN22 (destaque "Termina hoje!") e RN23 (marcação de exclusivo Clube) implementadas; `extrair_parceiros`/`montar` ganharam parâmetro `agora` obrigatório para as duas regras de data sem o núcleo ler o relógio por conta própria (exceção ao PRD-V2 §7.2, documentada lá); fixture `testes/fixtures/payload_parceiros.json` criada; casos CT-080 a CT-102
- [x] **V2.1** — `montar_catalogo()` escolhe Postgres ou arquivo conforme `DATABASE_URL`; `CatalogoComReserva` protege a execução contra o Neon fora do ar; `multiplicador`/`piso_pontos` lidos das duas fontes; `DATABASE_URL` passado ao `robo.yml`
- [x] Roteiro do smoke manual CT-050 escrito, com os números de 2026-08-11 como linha de base
- [x] **V2.2** — `alertas.py` no núcleo com RN27 (múltiplo da base com piso), RN28 (padrão global sobrescrito por loja), RN29 (suspeita de C07 sem guardar estado) e a supressão de RN23 para quem não assina o Clube; porta nova `PreferenciasGlobais` lendo a tabela `preferencia`; `categorias.agrupar` passa a receber o critério em vez de olhar a etiqueta. CT-117 a CT-138
- [x] **V2.3, metade 1** — o robô grava o retrato de cada execução: migração `002`, porta `RepositorioDeExecucao`, núcleo `retrato.py`. CT-139 a CT-150
- [x] **V2.3, metade 2** — site Next.js em `site/`: leitura pública, edição com senha única e limite de tentativas, RN24/RN25/RN26/RN30 e RNF14 atendidos. CT-151 a CT-155
- [x] 153 testes no robô e 7 no site, 96% de cobertura, quality gate no CI para os dois
- [x] **Redesign do e-mail e marca "Pontuação Livelo"** (2026-08-13) — `montador_email.py` reescrito: bloco de cor sólida por oferta em vez de card com borda fina, categoria vira selo com contador, descrição de campanha (`descricao_campanha`, RN31) expansível via `<details>/<summary>` sem JavaScript ("…mais"/"▲ menos"). CSS movido pra um único `<style>` no `<head>` e nomes de classe encurtados — o pior caso (132 lojas, Clube, descrição longa em todas) cabe em ~93 KB, ~11 KB de folga antes do corte do Gmail (C05). Marca "R$ vira ponto" criada a partir do que o sistema faz (dinheiro→pontos, não um ícone genérico), vetor em `site/public/logo.svg`, rasterizada em PNG: cabeçalho e rodapé do site (todas as telas), título do navegador via convenção `app/icon.png` do Next.js, e topo/rodapé do e-mail apontando pra `https://robo-livelo.vercel.app/logo.png` (não base64 — confirmado ao vivo que o Gmail descarta `data:` URI em e-mail, só página web aceita). Confirmado disparando e-mail real duas vezes: primeira tentativa tinha `<style>` fora do `<head>` (Gmail descarta a folha inteira) e cor por categoria via custom property CSS num `style=` inline (Gmail remove `--x` do atributo, só `background`/`color` direto sobrevivem) — os dois corrigidos no mesmo dia. Detalhes completos, incluindo as três lições do Gmail, em [`docs/EMAIL.md`](EMAIL.md). CT-168 a CT-173
