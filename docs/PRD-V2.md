# PRD V2 — Robô de Pontuação Turbinada (Livelo)

**Versão:** v2.1 (planejamento)
**Status:** planejado, não implementado. A V1.0 continua em produção e não é interrompida.

> A V2 deixou de ser um front estático de leitura. Passou a incluir **site próprio com edição, backend, autenticação e banco de dados** — o que derruba a premissa "sem servidor" da V1. A mudança é deliberada e está justificada na Seção 7.3.

Este documento é o **delta sobre o [`PRD.md`](PRD.md)**, que segue valendo como fonte da verdade de tudo que não for redefinido aqui. Onde houver conflito, este documento vence — e cada conflito está marcado explicitamente.

---

## 1. Contexto

A V1.0 entregou o caminho fim a fim: lê 254 parceiros, filtra 132 favoritas, envia e-mail 3x ao dia. Rodou em produção e funciona.

Três coisas apareceram depois:

**A validade da promoção estava ao alcance da mão.** A V1 excluiu esse dado acreditando que custaria ~40 requisições extras. Falso: a página embute um payload JSON com `dateStart` e `dateEnd` por parceiro. Na medição de 2026-08-09, **31 das 40 promoções terminavam naquele mesmo dia** — sem essa informação, o e-mail diz "Sam's Club com 84 pontos" e não diz se restam 6 horas ou 3 semanas.

**O e-mail é um formato apertado para o catálogo que cresceu.** Com 132 lojas, o e-mail responde bem "o que está turbinado agora?" mas não responde "quanto a Renner dá mesmo?". Essa segunda pergunta hoje obriga a abrir a página da Livelo, o que fere O1 diretamente.

**Três e-mails por dia produzem fadiga.** RF10 manda em toda execução, inclusive nos dias vazios. A V1 aceitou esse custo porque era o único jeito de manter O3 de pé: sem e-mail nenhum, "não tem promoção" e "o robô morreu" ficariam indistinguíveis, e C01 desabilita o cron em silêncio.

### 1.1 A dependência entre os três

O terceiro item **não pode ser resolvido sozinho**. Ele só se torna seguro por causa do segundo:

> A página carrega um carimbo de última atualização. Com ela publicada, o silêncio do e-mail deixa de ser ambíguo — basta abrir a página para saber se o robô continua vivo. **O front é o que autoriza o e-mail condicional.**

Implementar o e-mail condicional sem a página seria reabrir o buraco que a V1 fechou de propósito.

---

## 2. Objetivos novos

| ID | Objetivo |
|---|---|
| **O5** | Responder "quanto essa loja dá hoje?" sem abrir o site da Livelo — completa O1, que a V1 só atendeu pela metade |
| **O6** | Saber quanto tempo resta para aproveitar uma promoção |
| **O7** | Receber e-mail apenas quando houver algo a fazer |

O4 (portfólio) ganha reforço: uma página pública funcionando é mais demonstrável que um repositório.

---

## 3. Escopo

### 3.1 Dentro

- Extração a partir do **payload JSON** da página, em vez do texto renderizado dos cards.
- Data de início e fim da promoção, com destaque para o que termina hoje.
- Distinção entre promoção de pontuação base e promoção exclusiva do Clube Livelo.
- **Site próprio, com backend e autenticação**, onde as lojas favoritas e os limiares de alerta são consultados **e editados**.
- **Banco de dados Postgres** como fonte da configuração, substituindo o arquivo TOML.
- **Novo critério de alerta**: múltiplo da pontuação base com piso absoluto — ver Seção 6.1.
- E-mail enviado somente quando alguma favorita cruzar o próprio limiar.

### 3.2 Fora

- Multiusuário, cadastro, recuperação de senha. O site tem um único dono.
- Histórico entre execuções e gráfico de tendência. **A decisão de 1.4 do PRD segue valendo** — o banco guarda configuração, não série temporal.
- Hospedar logotipos ou imagens dos parceiros — ver 9.2.
- Compra, clique automático ou qualquer autenticação na Livelo.

### 3.3 O que este documento revoga do PRD V1

| Onde | O que muda |
|---|---|
| §1.4 "Fora do escopo: front-end" | **Revogado.** Passa a existir uma página estática. O canal de saída deixa de ser único |
| §1.4 "Fora do escopo: data de validade" | **Revogado.** A justificativa era falsa |
| §11.3 "Fora do roadmap: front-end" | **Revogado** pelo mesmo motivo |
| **RF10** (enviar sempre) | **Substituído** por RF16 — ver Seção 5 |
| **RN02** (piso de boost zero: qualquer aumento conta) | **Revogado e invertido** por RN27 — ver 6.1. Era o coração do filtro da V1 e passa a ser o oposto |
| **MS5** (sinal de vida pelo e-mail) | **Substituído** por MS6 — ver Seção 4 |
| §1.4 "sem banco de dados" e §11.3 | **Revogado.** A configuração passa a viver em Postgres, porque o site precisa escrevê-la |
| §5.3 (configuração em `lojas_favoritas.toml`) | **Substituído.** O TOML vira a carga inicial do banco, não a fonte da verdade |
| §9.4 "nunca escreve no repositório" | **Mantido e reforçado.** O robô continua com `contents: read`; agora nem para publicar página ele escreve |
| §2.2 RNF01 "custo zero" | **Mantido**, mas agora depende de free tier de terceiros — ver C08 |

---

## 4. Métricas

| ID | Métrica | Alvo | Fonte |
|---|---|---|---|
| **MS6** | Sinal de vida pela página | O carimbo de atualização da página nunca passa de 24h de atraso | A própria página |
| **MS7** | Utilidade da validade | Nenhuma promoção perdida por desconhecer o prazo | Autoavaliação |
| **MS8** | Redução de ruído | Menos de 1 e-mail por dia em média, em 30 dias | Caixa de entrada |

**MS5 é substituído por MS6.** O sinal de vida migra do e-mail para a página, que é atualizada em toda execução mesmo quando não há promoção.

> **Limitação honesta:** MS6 depende de você abrir a página. Se ficar semanas sem abrir e o cron morrer por C01, a descoberta demora. O e-mail diário garantia isso de forma passiva; a página exige um gesto. É o preço de O7, e está sendo pago conscientemente.

---

## 5. Requisitos novos

### 5.1 Funcionais

| ID | Requisito |
|---|---|
| **RF14** | Extrair os dados dos parceiros a partir do payload JSON embutido na página, incluindo `parity`, `parityClub`, `parityBau`, `dateStart`, `dateEnd` e `activeCampaign` |
| **RF15** | Servir um site com todas as lojas favoritas, suas pontuações atuais e as promoções em destaque |
| **RF16** | Enviar e-mail **somente quando ao menos uma favorita cruzar o próprio limiar de alerta**. **Substitui RF10** |
| **RF17** | Permitir, pelo site e sob autenticação, adicionar e remover lojas favoritas e editar multiplicador e piso, global e por loja |
| **RF18** | Exibir, em cada promoção, quanto tempo resta até o fim, com destaque para o que termina no mesmo dia |
| **RF19** | Registrar na página o instante da última atualização, em horário de Brasília |

### 5.2 Não-funcionais

| ID | Requisito | Alvo verificável |
|---|---|---|
| **RNF13** | A página não adiciona dependência de runtime | Nenhum pacote novo além do que a V1 já usa |
| **RNF14** | A página funciona sem JavaScript | Conteúdo legível com scripts desabilitados |
| **RNF15** | A página não carrega recurso de terceiros | Zero requisição a domínio externo ao abrir |
| **RNF16** | A página é legível no celular | Layout de coluna única abaixo de 600px |
| **RNF17** | O deploy não escreve no repositório | O workflow mantém `contents: read` |

### 5.3 Restrições novas

| ID | Restrição | Impacto |
|---|---|---|
| **C06** | O payload JSON é interno da Livelo e pode mudar de forma sem aviso — não é uma API pública com contrato | Mesma fragilidade de C04, agora concentrada em outro ponto. RN13 continua sendo a rede de proteção |
| **C07** | `parityBau` é preenchido pela Livelo e o alerta inteiro depende dele ser honesto | Se um dia vier igual ao valor promocional, todo mundo vira 1x e **nenhum alerta dispara, em silêncio**. Exige a checagem de RN29 |
| **C08** | O custo zero passa a depender de free tier de terceiros: Neon 0,5 GB e 100 CU-horas por mês, Vercel no plano gratuito | Medido: o projeto usa ~88 KB e ~290 consultas por mês. Folga de mais de 100x, mas os termos podem mudar |
| **C09** | O compute do Neon hiberna após 5 minutos ocioso | Acorda sozinho em milissegundos. Irrelevante para o robô 3x ao dia; a primeira tela do site após ociosidade carrega um pouco mais devagar |

---

## 6. Regras de negócio novas

| ID | Regra |
|---|---|
| **RN21** | Promoção com `dateEnd` já passado **não é promoção**. O payload pode conter campanha encerrada ainda não removida da página |
| **RN22** | Promoção que termina no mesmo dia da execução recebe destaque visual próprio, na página e no e-mail |
| **RN23** | `activeCampaign` distingue três casos: `PROMOTION` (a base subiu), `PROMOTION_CLUB` (a base subiu e o Clube subiu mais) e `CLUB` (só o Clube subiu). Quem não é assinante não deve ser alertado por promoção que não pode aproveitar — mas `PROMOTION_CLUB` ele aproveita, só não pelo número maior |
| **RN24** | A página exibe **todas** as favoritas, em promoção ou não. É o que permite consultar a pontuação base sem abrir a Livelo (O5) |
| **RN25** | A página nunca carrega imagem, fonte ou script de domínio externo. Logotipo de parceiro não é hospedado nem apontado por link direto — ver 9.2 |
| **RN26** | O carimbo de atualização é obrigatório e sempre visível. Sem ele a página não cumpre MS6 |
| **RN27** | **Uma loja gera alerta quando `pontos_atuais >= base × multiplicador` E `pontos_atuais >= piso`.** Substitui e inverte RN02 |
| **RN28** | Multiplicador e piso têm valor padrão global, sobrescrevível por loja. Loja sem sobrescrita usa o padrão |
| **RN29** | Silêncio de alerta acompanhado de página degenerada (quase todo parceiro com `parityBau` igual à pontuação atual) é registrado como suspeita — é o sintoma de C07. Ver 6.3 |
| **RN30** | O site exibe, ao lado de cada loja, a pontuação atual, a base e o valor que dispararia o alerta. Sem isso o limiar desregula em silêncio |

### 6.1 O novo critério de alerta

A V1 alertava quando a Livelo pendurava a etiqueta "Promoção". Medido em 2026-08-09, esse critério **errava nos dois sentidos**:

| Erro | Exemplo real |
|---|---|
| Avisava sem haver aumento | `Eudora` 2 → 2 e `O Boticário` 3 → 3, ambos etiquetados como promoção |
| Não avisava havendo aumento | `Avon` com 6 pontos contra base 2, um salto de 3x, **sem etiqueta nenhuma** |

O critério passa a comparar com `parityBau`, a pontuação normal declarada pela própria Livelo. Dois botões:

- **Multiplicador** — quanto acima do normal daquela loja. Padrão **2,0**
- **Piso** — mínimo absoluto para valer um e-mail. Padrão **4 pontos**

**Por que múltiplo e não número fixo.** Um limiar absoluto ignora a escala de cada loja. Simulado no catálogo real, a regra "avise acima de 8" perderia `Crocs` (2→7), `Avon` (2→6), `Osklen` (2→6), `Fast Shop` (2→5) e `Magalu` (2→4) — todas oportunidades legítimas.

**Por que o piso existe.** Só o multiplicador deixaria passar `Mercado Livre` 1→2 e `Bibi` 1→2. Dobrou, mas são 2 pontos.

**Prova de que não vaza ruído.** `Claro`, `TIM` e `Decolar` dão 6 pontos com base 6, e `Natura` dá 4 com base 4. São pontuações altas permanentes, não oportunidades — nenhuma dispara. Um limiar absoluto de 5 mandaria `Claro` e `TIM` todo dia.

Com padrão 2,0 e piso 4, a medição de 2026-08-09 produziria **um e-mail com 12 lojas**, de 126 favoritas.

> **Recomendação de uso:** subir com o padrão global e **nenhuma sobrescrita**. Configurar 132 limiares na largada é armadilha — você chuta todos, erra a maioria e nunca revisa. Depois de duas ou três semanas, sobrescrever apenas as poucas lojas que incomodarem. A capacidade existe desde o primeiro dia; o uso dela deve ser preguiçoso.

### 6.2 Sobre RN23 e o Clube

A V1 tratou como promoção qualquer parceiro com a etiqueta "Promoção", e isso produziu ruído real: `O Boticário` apareceu com base 3 → 3 pontos, ou seja, sem aumento nenhum na base — o boost estava só no tier Clube, de 3 para 10.

Os valores de `activeCampaign` foram confirmados contra a página real em 2026-08-11 (270 itens): `BAU` (221), `PROMOTION` (30), `CLUB` (5), `PROMOTION_CLUB` (3). São dois casos diferentes envolvendo o Clube, e tratá-los igual erraria:

| Campanha | O que acontece | Exemplo real de 2026-08-11 | No e-mail |
|---|---|---|---|
| `CLUB` | A base não se move; o ganho existe só para assinante | Aliexpress: base 1, Clube 3 | "exclusivo assinantes Clube" |
| `PROMOTION_CLUB` | A base sobe para todo mundo e o Clube sobe mais | Sephora: base 1 → 6, Clube 10 | "assinantes Clube ganham mais" |

A distinção importa porque o não assinante **aproveita** uma promoção `PROMOTION_CLUB` — o que ele não aproveita é o número maior que aparece ao lado. Marcá-la como exclusiva esconderia uma promoção boa; não marcá-la nada deixaria o número maior sem explicação.

Passa a existir a configuração `ASSINANTE_CLUBE`, padrão `false`:

- Não assinante: promoção `CLUB` **não** dispara e-mail, mas continua visível na página, marcada como Clube. `PROMOTION_CLUB` dispara normalmente, pela pontuação que vale para ele.
- Assinante: promoção do Clube conta normalmente, pelo valor do tier.

> A **marcação** no e-mail é da V2.0. A **supressão** do alerta por não ser assinante entrou na V2.2: `CLUB` não dispara para quem não assina, `PROMOTION_CLUB` dispara normalmente, e para quem assina a pontuação que vale é a do tier.

### 6.3 RN29 sem guardar estado

A redação original de RN29 falava em "muitos dias seguidos", o que exigiria histórico — e o robô é stateless por decisão (PRD §1.4). A regra foi implementada sem contador de dias, porque **o sintoma de C07 é visível numa execução só**: se a Livelo passar a preencher `parityBau` com o próprio valor promocional, isso não acontece numa loja, acontece na página inteira de uma vez.

A checagem dispara quando **nenhuma favorita cruzou o limiar** e ao menos 90% dos parceiros com base conhecida vieram com `pontos_atuais == pontos_base`. Uma loja parada é normal; a página parada não é. Há ainda o caso extremo do payload deixar de trazer `parityBau`: aí a suspeita é levantada sem conta nenhuma.

```
WARNING RN29: nenhuma favorita cruzou o limiar e 251 de 254 parceiros
vieram com base igual a pontuacao atual. Suspeita de parityBau
degenerado (C07), nao de "nao teve promocao hoje".
```

A versão com contagem de dias volta à mesa na V2.3, quando o robô passar a gravar cada execução no banco para alimentar o site — aí o histórico existe como subproduto, e não como estado criado só para esta regra.

### 6.4 Medição da régua contra a página real

Ensaio de 2026-08-11 com a página real, o catálogo do Neon e a régua padrão (2,0x, piso 4):

| Critério | Lojas no e-mail |
|---|---|
| V1 — etiqueta "Promoção" da Livelo | 18 |
| RN27 — múltiplo da base com piso | 15 |

As trocas mostram a regra funcionando nos dois sentidos que a V1 errava:

| Loja | Situação | Veredito |
|---|---|---|
| `Mercado Livre` 1 → 2, `Bibi` 1 → 2, `Electrolux` 1 → 2 | Dobrou, mas são 2 pontos | Saiu — é o piso trabalhando |
| `Booking.com` 4 → 6 | Subiu, mas não dobrou | Saiu — é o multiplicador trabalhando |
| `Avon` 2 → 6 | Triplicou **sem etiqueta nenhuma** | Entrou — é o falso negativo da V1 sendo corrigido |

Sensibilidade medida no mesmo dia, para calibrar depois de algumas semanas: `2,0x piso 4` → 15 lojas; `2,5x piso 4` → 14; `3,0x piso 4` → 11; `2,0x piso 6` → 7. O piso é o botão mais sensível dos dois.

---

## 7. Arquitetura

### 7.1 O que muda

A regra de ouro não muda: núcleo puro, mundo por contrato. A V2 acrescenta **uma porta e um módulo de núcleo**.

| Peça | Tipo | Papel |
|---|---|---|
| `extrator.py` | Núcleo, **reescrito** | Passa a ler o payload JSON em vez do texto dos cards |
| `alertas.py` | Núcleo, **novo** | Aplica RN27 e RN28: decide o que merece alerta. Função pura, sem I/O |
| `montador_email.py` | Núcleo, ajustado | Ganha validade e marcação de Clube |
| `CatalogoFavoritas` | **Porta existente, nova implementação** | Passa a ler do Postgres em vez do TOML. **O contrato não muda** — é o dividendo da arquitetura da V1 |
| `PreferenciasGlobais` | **Porta nova** (V2.2) | Entrega a régua de RN28. Separada do catálogo porque vem de outra tabela e responde outra pergunta |
| `RepositorioDeExecucao` | **Porta nova** (V2.3) | Guarda o retrato de cada rodada. É o que dá dado ao site: a pontuação atual só existe durante a execução |
| `retrato.py` | Núcleo, **novo** (V2.3) | Junta cada favorita com o que a página disse dela. RF15, RN24, RN30 |
| `principal.py` | Orquestração, ajustada | Decide envio por RF16 |
| Site | **Componente novo**, fora do robô | Next.js na Vercel: exibe e edita. Fala com o mesmo banco |

### 7.1.1 O que a arquitetura da V1 economiza aqui

Trocar arquivo TOML por Postgres **não toca uma linha do núcleo**. `CatalogoFavoritas.listar()` continua devolvendo `list[LojaFavorita]`, e quem chama não sabe de onde veio. Era exatamente para isto que a porta existia — e é a primeira vez que ela paga o próprio custo.

O TOML atual vira a **carga inicial** do banco, não some.

```mermaid
flowchart TD
    UC["caso de uso"]
    subgraph nucleo["Núcleo puro"]
        EXT["extrator<br/>JSON → Parceiro<br/>RF14, RN21, RN23"]
        REG["categorias<br/>RN01, RN04, RN24"]
        MEM["montador_email<br/>RN22, RF16"]
        MPG["montador_pagina<br/>RF15, RN24, RN26"]
    end
    subgraph ad["Adaptadores"]
        HTTP["FonteDePagina"]
        SMTP["Notificador"]
        CFG["CatalogoFavoritas"]
        PUB["PublicadorDePagina<br/>(novo)"]
    end
    UC --> HTTP --> EXT --> REG
    REG --> MEM --> SMTP
    REG --> MPG --> PUB
    UC --> CFG
```

### 7.2 Por que reescrever o extrator é ganho, não risco

Ler o payload é **mais estável** que raspar o card renderizado:

| Hoje (V1) | V2 |
|---|---|
| Regex sobre texto: `"Até 4 pontos por R$ 1 Eram 1 ponto"` | Campos numéricos: `parity`, `parityBau`, `parityClub` |
| Promoção inferida da presença de uma etiqueta | Campo booleano `promotion` e `activeCampaign` |
| Validade indisponível | `dateStart` e `dateEnd` |
| Quebra se mudarem texto, classe ou estrutura visual | Quebra se mudarem o formato dos dados |

Isso ataca **C04**, que é o maior risco do projeto. A troca é protegida pelos testes existentes na largada da V2.0 (96, ao final dela): a assinatura pública muda em um ponto só, deliberado.

> **Exceção registrada:** a versão original desta seção dizia que `extrair_parceiros(html) -> list[Parceiro]` não mudaria. Isso deixou de ser exato. RN21 (promoção com `dateEnd` no passado não conta) e RN22 (destaque "termina hoje") precisam saber que dia é hoje — e o núcleo não pode ler o relógio por conta própria sem reintroduzir o não-determinismo escondido que a regra de ouro 1 do `CLAUDE.md` existe para evitar. A solução adotada: `agora: datetime` como parâmetro obrigatório e nomeado em `extrair_parceiros` e em `montador_email.montar`, resolvido uma única vez em `principal.py` (a única camada que já faz I/O) e propagado aos dois. O contrato `html -> list[Parceiro]` continua valendo — só ganhou um segundo parâmetro explícito, não um relógio implícito.

### 7.3 Infraestrutura

| Peça | Onde | Por quê |
|---|---|---|
| Robô | GitHub Actions, 3x ao dia | O agendamento, os testes e o gate já funcionam. A notificação nativa de falha sustenta O3 |
| Banco | **Neon** (Postgres) | Não expira e acorda sozinho. Escolhido também por ensinar Postgres, que é conhecimento transferível |
| Site | **Vercel** | Não tem o desligamento longo de outras hospedagens gratuitas |

**Alternativas descartadas, com o motivo:**

- **Render** — o Postgres gratuito **expira 30 dias após a criação e é apagado com os dados**. O web service dorme em 15 minutos e leva cerca de 1 minuto para voltar, o pior perfil possível para um site consultado esporadicamente.
- **Configuração continuar no git**, editada pelo site via API do GitHub — tecnicamente viável e mais simples, dispensando banco. Descartada por decisão explícita: aprender Postgres num projeto próprio é objetivo declarado, e isso pesa mais que a simplicidade aqui. **Registrado como escolha de aprendizado, não como necessidade técnica.**

O robô continua com `permissions: contents: read` (§9.4 do PRD V1) e nunca escreve no repositório.

---

## 8. Modelo de dados

`Parceiro` ganha quatro campos, todos opcionais para não quebrar o que existe:

| Campo | Tipo | Regra |
|---|---|---|
| `pontos_base` | `Decimal \| None` | `parityBau` — a pontuação normal, fora de promoção |
| `inicio_promocao` | `datetime \| None` | `dateStart` |
| `fim_promocao` | `datetime \| None` | `dateEnd`, base de RN21 e RN22 |
| `campanha` | `str \| None` | `activeCampaign`, base de RN23 |

`LojaFavorita` ganha os campos de alerta:

| Campo | Tipo | Regra |
|---|---|---|
| `multiplicador` | `Decimal \| None` | `None` significa "usa o padrão global" (RN28) |
| `piso_pontos` | `Decimal \| None` | Idem |

### 8.1 Esquema do banco

```
loja        id, nome, categoria, multiplicador?, piso_pontos?, criada_em
apelido     id, loja_id, texto              -- RN04 continua exigindo grafia exata
preferencia chave, valor                    -- multiplicador e piso padrão, assinante_clube
execucao    id, momento, parceiros_lidos, alertas, versao          -- V2.3
pontuacao   id, execucao_id, loja_id?, nome, pontos_*, valor_de_disparo, ...  -- V2.3
```

As duas últimas entraram na V2.3 (`migracoes/002_execucao.sql`). Guardam **apenas as 132 favoritas**, não os 254 parceiros: é o mesmo recorte que a página pública exibe (§9.3) e mantém o volume irrelevante diante de C08. `loja_id` nulo significa favorita que não apareceu na página naquela rodada (RN19) — a linha existe para o site dizer "não encontrada" em vez de sumir com a loja.

**Gravar não é crítico.** Falha ao guardar o retrato vira `WARNING` e a execução segue: a consequência é o site ficar velho, e o carimbo de RN26 denuncia isso sozinho na própria página. Perder o e-mail do dia por causa do Neon seria pior — por isso a gravação acontece **depois** do envio, e por isso `FalhaAoGuardar` existe separada de `ConfiguracaoInvalida`.

Três tabelas. Restrições que o banco garante, e não o código — a garantia mora na camada mais baixa possível:

- `nome` único
- `texto` do apelido único **entre todas as lojas**, porque RN04 proíbe ambiguidade
- `categoria` obrigatória, `multiplicador > 0`, `piso_pontos >= 0`

Configuração nova: `assinante_clube`, padrão `false`, agora na tabela de preferências.

---

## 9. Segurança, privacidade e legal

### 9.0 Autenticação do site

Decisão tomada: **senha única**, guardada como variável de ambiente na Vercel, sem cadastro nem tabela de usuários.

O trade-off foi apresentado e aceito: senha compartilhada é credencial de vida longa, sem segundo fator e sem revogação individual. Quatro medidas obrigatórias, porque neste desenho quem entra no site altera o que o robô faz:

| Medida | Motivo |
|---|---|
| Senha longa e aleatória, nunca no código nem no repositório | O repositório é público |
| Limite de tentativas de login | Sem isso, senha única cai por força bruta |
| Cookie de sessão `httpOnly` e `secure`, só sobre HTTPS | Impede leitura por script e trânsito em claro |
| Credenciais do banco só no servidor, nunca no navegador | O front nunca fala direto com o Postgres |

**Leitura pública, edição protegida.** Quem tem a URL vê as promoções; só quem tem a senha altera.

### 9.1 A página é pública

Publicada em repositório público, é acessível a quem tiver a URL. O conteúdo é pontuação pública da Livelo, **não há dado pessoal** — nenhum e-mail, nenhum identificador. O que a página revela é a lista de lojas favoritas, ou seja, preferência de compra. Avaliado e aceito.

**RN18 continua valendo:** o endereço de e-mail nunca aparece na página, como nunca apareceu no log.

### 9.2 Logotipos de parceiros

O payload traz a URL do logotipo de cada parceiro no CDN da Livelo. **Não serão usados**, por duas razões independentes:

1. Apontar direto para o CDN de terceiro consome banda alheia sem autorização e quebra RNF15.
2. Copiar os arquivos para o repositório significa redistribuir marca de terceiro, o que muda a análise da Seção 10.3 do PRD V1, hoje apoiada em "não redistribuo nada".

A página identifica cada loja por nome e cor de categoria, como o e-mail já faz.

### 9.3 Termos de uso

A Seção 10.1 do PRD V1 continua valendo integralmente, **com uma diferença que precisa ser dita**: a V1 consumia os dados em privado, no próprio e-mail. A V2 os **republica em página pública**.

Isso enfraquece o argumento de "uso exclusivamente pessoal" que sustenta a análise legal atual. Mitigações adotadas:

- A página mostra apenas as 132 favoritas, não os 254 parceiros — é uma seleção pessoal, não um espelho do site deles.
- Nenhum logotipo, nenhuma imagem, nenhum texto de regulamento copiado.
- Aviso de não afiliação e link para a Livelo em cada loja (RN08).
- Nenhuma monetização, nenhum anúncio.

**Se a Livelo se manifestar, a página sai do ar.** Mesma linha ética da Seção 10.1: nenhuma evasão, nenhuma insistência.

---

## 10. Testes

Novos casos, seguindo o bloco CT-080 em diante. A estratégia da Seção 8 do PRD V1 não muda: núcleo puro em unitário, orquestração com fakes, nenhum teste tocando rede.

| Regra | Caso |
|---|---|
| RF14 | Payload real da página vira `Parceiro` com todos os campos |
| RF14 | Payload sem `dateEnd`, ou com data malformada, não derruba a extração |
| RN21 | Promoção com `dateEnd` no passado não conta como promoção |
| RN22 | Promoção que termina hoje recebe a marcação de destaque |
| RN23 | Com `ASSINANTE_CLUBE=false`, promoção exclusiva do Clube não dispara e-mail mas aparece na página |
| RN23 | Com `ASSINANTE_CLUBE=true`, a mesma promoção dispara e-mail |
| RF16 | Sem promoção, o notificador **não** é chamado |
| RF16 | Sem promoção, a página **é** publicada mesmo assim |
| RN24 | A página lista as 132, não só as em promoção |
| RN25 | A página não contém nenhuma URL de domínio externo |
| RN26 | A página contém o carimbo de atualização |
| RNF14 | O conteúdo é legível sem executar JavaScript |
| RNF17 | O workflow do robô não declara `contents: write` |

A fixture ganha o payload JSON real, recortado, ao lado do HTML que já existe.

---

## 11. Fases

Cada fase entrega valor sozinha e pode parar ali sem deixar o projeto pela metade.

| Fase | Entrega | Por que nesta ordem |
|---|---|---|
| **V2.0** | Extrator lendo o payload: base, validade e campanha. E-mail mostra validade e marca o que é só do Clube | Base de tudo. Sozinha já melhora o e-mail de hoje, sem site e sem banco |
| **V2.1** | Banco no Neon, `CatalogoFavoritas` lendo de lá, TOML como carga inicial | O núcleo não muda — só a implementação da porta. Fase de menor risco de todas |
| **V2.2** | Regras de alerta RN27 e RN28, ainda com o e-mail diário | Permite calibrar multiplicador e piso **vendo o resultado** antes de depender deles |
| **V2.3** | Site na Vercel: consulta e edição, com senha | Precisa do banco da V2.1. Entrega O5 |
| **V2.4** | E-mail condicional (RF16) | **Só depois da V2.3 no ar e verificada.** Antes disso, cortar o e-mail diário reabre o buraco do O3 |

> Duas ordens não são negociáveis. **V2.4 depois da V2.3**, senão fica sem sinal de vida nenhum. E **V2.2 antes da V2.4**, porque calibrar limiar recebendo e-mail todo dia é fácil; calibrar limiar quando o e-mail só chega se o limiar estiver certo é adivinhação.

---

## 12. Riscos

| Risco | Mitigação |
|---|---|
| O formato do payload muda (C06) | RN13 continua: poucos parceiros extraídos derruba a execução com erro ruidoso |
| O e-mail perder relevância diante do site | **Não é risco, é o desenho.** Cada canal ganha um trabalho só: o site é consulta, o e-mail é alarme. O e-mail para de ser catálogo |
| `parityBau` deixar de ser confiável (C07) | RN29: ausência prolongada de alerta é tratada como suspeita, não como "não teve promoção" |
| Senha única vazar | 9.0: senha aleatória, limite de tentativas, sessão protegida. Estrago limitado a este projeto |
| Free tier de Neon ou Vercel mudar (C08) | Uso medido é ~1% do limite. Se mudar, a configuração volta para arquivo — o contrato `CatalogoFavoritas` torna a volta barata |
| Deixar de abrir a página e não perceber que o robô morreu | Limitação declarada em MS6. Se virar problema real, o candidato é um e-mail semanal de resumo, mesmo sem promoção |
| A exposição pública dos dados atrair atenção da Livelo | 9.3: a página sai do ar na primeira manifestação |
