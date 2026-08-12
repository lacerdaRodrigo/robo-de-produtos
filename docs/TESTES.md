# Plano de Testes

Casos de teste organizados por módulo. Todos rodam automaticamente a cada `git push`, via `testes.yml`, usando `pytest`.

A estratégia (pirâmide, uso de fakes, meta de cobertura) está na **Seção 8 do [`PRD.md`](PRD.md)**. Este documento é só o catálogo de casos.

Convenção: arquivos e funções de teste usam o prefixo `teste_` (em vez do padrão `test_` do pytest), configurado no `pyproject.toml`.

A numeração tem lacunas propositais (009, 025–029, 039, 047–059) para deixar espaço de crescimento em cada bloco. **O total é a soma dos itens listados, nunca o intervalo.**

---

## `testes/teste_categorias.py` — função `reconhecer()`

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-001 | Loja exata na lista | Nome cadastrado igualzinho ("Natura") deve retornar a categoria certa | Chamar `reconhecer("Natura")`, esperar `"Beleza"` |
| CT-002 | Acentuação diferente | "Boticário" e "boticario" (sem acento) devem dar o mesmo resultado | Testar as duas grafias, comparar retorno |
| CT-003 | Caixa alta/baixa | "CASAS BAHIA", "casas bahia", "Casas Bahia" devem funcionar igual | Rodar as 3 variações, checar retorno idêntico |
| CT-004 | Loja não cadastrada | Loja fora do dicionário deve retornar `None`, sem quebrar | Chamar com nome não listado, checar `is None` |
| CT-005 | Sufixo só casa se for apelido cadastrado ⚠️ | RN04 proíbe substring. "Casas Bahia Oficial" só é reconhecido se estiver na lista de apelidos da loja; um sufixo não cadastrado **não** pode casar | Testar apelido cadastrado (espera a categoria) e sufixo não cadastrado (espera `None`) |
| CT-006 | Lojas parecidas não se confundem ⚠️ | "Ponto" e "Pontofrio" são lojas diferentes, não podem se capturar por engano | Testar os dois nomes, garantir categorias corretas e distintas |
| CT-007 | String vazia | Nome vazio não pode gerar erro | Chamar `reconhecer("")`, checar `None` sem exceção |
| CT-008 | Espaços extras | " Natura " (com espaços) deve funcionar igual a "Natura" | Testar com espaços sobrando, comparar resultado |

## `testes/teste_extrator.py` — núcleo puro: payload JSON → `Parceiro` (fixture do payload, **nunca** rede)

> A V2.0 trocou a raspagem de HTML (`data-testid`, regex sobre texto de card) pela leitura do payload `__NEXT_DATA__` (RF14). CT-015 (nome via atributo `alt`), CT-016 (fallback sem `alt`) e CT-019 (link que não é de parceiro) foram **aposentados**, não adaptados — não existe mais atributo `alt` nem "link solto misturado no HTML" num array JSON, então não há o que testar no lugar. Os números não são reaproveitados.

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-010 | Loja sem promoção | Item com `promotion: false` deve marcar `em_promocao=False` | Item sintético, rodar extração |
| CT-011 | Promoção preenche `pontos_base` | O antigo "Eram X pontos" vira `pontos_base` a partir de `parityBau`, não mais regex | Item com `parity` e `parityBau` distintos, validar os dois campos |
| CT-012 | Tier Clube Livelo | `parityClub` distinto de `parity` deve preencher `pontos_clube` | Item com os dois valores diferentes, checar campo |
| CT-013 | Prefixo "Até X pontos" | `separatorSlug` mapeia para `prefixo_ate` | Item com `separatorSlug` correspondente, validar |
| CT-014 | Moeda em dólar | Parceiros de viagem usam `currency: "U$"` em vez de `"R$"` | Item tipo Booking, checar `moeda == "U$"` |
| CT-017 | Parceiro duplicado | Nome repetido no array `configPartners` — resultado final não pode duplicar | Dois itens com o mesmo nome, checar resultado único |
| CT-018 | Página sem parceiros | `configPartners` vazio deve devolver lista vazia, não erro | Payload com a seção vazia, checar `len() == 0` |
| CT-020 | Nome com caracteres especiais | "Sam's Club", "O.U.i Paris", "C&A" não podem quebrar o parsing | Itens com esses nomes, checar extração correta |
| CT-080 | Mapeamento completo (RF14) | `pontos_base`, `inicio_promocao`, `fim_promocao` e `campanha` saem corretos a partir de `parityBau`/`dateStart`/`dateEnd`/`activeCampaign` | Item completo, validar os 4 campos novos |
| CT-081 | Fracionário sem resíduo de `float` | PRD §5.4 — `json.loads` com `parse_float=Decimal` evita `2.9000000000000004` | Item com `parity: 2.9`, checar `Decimal` exato |
| CT-082 | Localiza a seção por título, não por índice (C06) | A seção de listagem pode vir em qualquer posição de `components` — a Livelo pode reordenar | Seção de destaque (schema diferente) e a de listagem em ordem trocada, checar que só a certa é lida |
| CT-083 | Seção ausente devolve lista vazia | Sem a seção esperada, não lança exceção — quem falha é o limiar RN13 em `principal.py` | Payload sem nenhuma seção com o título esperado |
| CT-084 | Sem `dateEnd` não quebra | Item com `promotion: true` mas sem data de fim | Checar `fim_promocao is None` e `em_promocao` preservado |
| CT-085 | Data malformada vira `None` | `dateEnd` num formato inesperado não derruba o item | Item com data ilegível, checar `fim_promocao is None`, resto válido |
| CT-086 | RN21 — `dateEnd` no passado desliga `em_promocao` ⚠️ | Promoção com prazo vencido não conta, mesmo com `promotion: true` no payload | Item com `dateEnd` antes do `agora` do teste |
| CT-087 | RN21 — `dateEnd` no futuro mantém `em_promocao` | Contraprova de CT-086 | Item com `dateEnd` depois do `agora` do teste |
| CT-088 | Sem pontuação legível é descartado | Descarta só aquele item, os outros seguem (PRD §6.4) | Item com `parity.parity` não numérico entre itens válidos |
| CT-089 | Sem nome é descartado | Idem, para item sem `name` | Item com `name` vazio entre itens válidos |
| CT-090 | Dedup por nome (RN06) | Repetido no array conta uma vez só | Dois itens com o mesmo nome |
| CT-091 | `separatorSlug: "ATE"` (RN12) | Confirmado contra a página real em 2026-08-11: 36 dos 270 itens usavam `"ATE"` | Item com esse `separatorSlug`, checar `prefixo_ate=True` |
| CT-092 | Moeda preservada (RN11) | Nunca converte, exibe como veio | Item com `currency: "U$"` |
| CT-093 | `parityClub == parity` não popula `pontos_clube` | Evita ruído de "Clube: N pontos" repetido em toda loja sem distinção real | Item com os dois valores iguais |
| CT-094 | `parityClub` distinto popula `pontos_clube` | Contraprova de CT-093 | Item com os dois valores diferentes |
| CT-095 | Integração com o payload real recortado | A fixture é o payload de verdade (capturado ao vivo em 2026-08), não inventado | `testes/fixtures/payload_parceiros.json`, checar nomes e os casos difíceis (RN21, RN22 candidato, RN23, dado malformado) |
| CT-106 | Item sem `parity` não vira `WARNING` | São 11 por execução (produtos da própria Livelo: `LVA`, `CIB`, `XXX`...). Descartar está certo; gritar toda vez afogaria o aviso que importa (RNF06). Vai em `DEBUG` mais um resumo em `INFO` | Item com `parity` ausente entre válidos, checar nível dos registros |
| CT-107 | `parity` presente mas ilegível continua `WARNING` | Contraprova de CT-106: pontuação que existe e não dá para ler é sintoma de mudança na página | Item com `parity.parity` não numérico, checar `WARNING` |

Também há um bloco sem ID de "robustez contra payload hostil" (RN07): script `__NEXT_DATA__` ausente, JSON inválido, payload que não é objeto, componente ou item que não é um objeto, `parity` que não é um objeto, `parityBau`/`parityClub` não numéricos — todos cobertos, contam para o total executado mas não têm CT próprio (mesma convenção dos testes de apoio já existentes no arquivo).

## `testes/teste_adaptadores.py` — implementações das portas (PRD §4.2)

> Bloco novo. CT-021 a CT-023 vieram de `teste_extrator.py`: o extrator virou núcleo puro e não conhece rede, então falha de conexão é responsabilidade do adaptador `FonteDePagina`.

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-021 | Erro de rede | Falha de conexão deve ser tratada, não travar silenciosamente | Simular falha do `requests.get`, checar tratamento |
| CT-022 | Retry após falha temporária | Uma falha isolada não pode derrubar a execução — deve tentar de novo | Simular 1 falha seguida de sucesso, checar que o retorno final é válido |
| CT-023 | Desiste após esgotar tentativas | Depois de todas as tentativas falharem, deve lançar erro claro | Simular falha sempre, checar exceção após o número máximo de tentativas |
| CT-060 | Resposta grande demais | PRD §9.2 — resposta acima do tamanho máximo é tratada como falha | Simular resposta gigante, checar que vira erro |
| CT-061 | Config ausente ou vazia | PRD §7.2 — sem favoritas, falha ruidosa | Apontar para arquivo inexistente e para arquivo sem loja, checar erro nos dois |
| CT-062 | Config malformada | TOML inválido deve dar erro legível, não stack trace cru | Arquivo com sintaxe quebrada, checar mensagem |
| CT-063 | Apelido repetido entre lojas | Mesmo apelido em duas lojas é erro de configuração, não empate silencioso | Config com apelido duplicado, checar erro |
| CT-108 | Reserva assume quando o banco falha ⚠️ | O Neon é serviço de terceiro em plano gratuito. Ficar sem catálogo derrubaria a execução por motivo que nada tem a ver com a Livelo | `CatalogoComReserva` com principal que levanta `ConfiguracaoInvalida`, checar resultado da reserva e o `WARNING` |
| CT-109 | Reserva não é tocada quando o banco responde | Contraprova de CT-108: a reserva não pode virar caminho normal sem ninguém notar | Principal que responde, checar que a reserva não foi chamada |
| CT-110 | Limiar por loja no arquivo vira `Decimal` | RN28 — `multiplicador`/`piso_pontos` opcionais. Ausente significa "usa o padrão global" | TOML com uma loja com limiar e outra sem, checar `Decimal` e `None` |
| CT-111 | Limiar inválido é recusado | Limiar errado por erro de digitação viraria alerta errado depois, silenciosamente | TOML com texto, com zero e com negativo, checar `ConfiguracaoInvalida` nos três |
| CT-112 | Catálogo do banco mapeia as colunas | O adaptador lê nome, categoria, apelidos, `multiplicador` e `piso_pontos` (RN28) | Fake de `psycopg` em `sys.modules`, checar mapeamento e as colunas na consulta |
| CT-113 | Senha da URL não vaza na mensagem de erro ⚠️ | PRD §9.1 — o log do Actions é público e a exceção original carrega a `DATABASE_URL` inteira | Fake que falha ao conectar, checar ausência da senha no texto e `__cause__` cortado |
| CT-130 | Preferências padrão sem banco | Quem não tem Neon roda com 2,0x e piso 4 (PRD-V2 §6.1) | `PreferenciasPadrao().carregar()` |
| CT-131 | Preferências vindas do banco | RN28 — a régua é editável sem `git push` | Fake de `psycopg` devolvendo as três chaves |
| CT-132 | Preferência ilegível ou ausente cai no padrão | Escolha oposta à do catálogo: existe valor sensato para seguir, então a rodada continua — mas não em silêncio | Chave com texto no lugar de número, checar padrão e `WARNING` |
| CT-133 | Preferências caem para o padrão quando o banco falha | Mesmo motivo de CT-108 | Principal que levanta `ConfiguracaoInvalida`, checar padrão e `WARNING` |
| CT-144 | Grava execução e pontuações na mesma transação | Retrato pela metade no banco viraria página mentindo, que é pior que página velha | Fake de `psycopg`, checar a linha de execução e as de pontuação |
| CT-145 | Link fora do domínio não é gravado ⚠️ | RN08 vale para o site também: link arbitrário não entra na página | Parceiro com link hostil, checar `link is None` |
| CT-146 | Falha ao gravar não vaza a senha ⚠️ | PRD §9.1 — a exceção do `psycopg` carrega a URL inteira | Fake que falha, checar ausência da senha e `__cause__` cortado |

## `testes/teste_montador_email.py` — função `montar_email()`

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-030 | Uma categoria, uma loja | Caso mais simples: e-mail sai com 1 categoria e 1 loja | Dict pequeno, checar presença do nome no HTML |
| CT-031 | Várias categorias e lojas | Todas as categorias e lojas devem aparecer, sem sumir nenhuma | Dict com 3 categorias, 2 lojas cada, contar ocorrências |
| CT-032 | Ordenação por pontos | Loja com mais pontos aparece antes da com menos, na mesma categoria | 2 lojas fora de ordem, checar posição no HTML |
| CT-033 | Loja sem tier Clube | Não pode gerar erro nem bloco vazio estranho | Loja sem `pontos_clube` (ou `None`), checar HTML limpo |
| CT-034 | Loja com tier Clube | Valor extra deve aparecer visível no HTML | Loja com `pontos_clube` preenchido, checar presença do texto |
| CT-035 | Assunto reflete o total | Com 5 promoções, o assunto deve conter "5" | Montar com 5 lojas, checar número no assunto |
| CT-036 | Categorias em ordem alfabética | "Beleza" deve aparecer antes de "Moda" | Categorias fora de ordem, checar posição no HTML |
| CT-037 | Dicionário vazio | Sem promoções, gera e-mail válido com o assunto próprio de "sem promoções" (RN/PRD RF10) | Passar `{}`, checar que o assunto é o de ausência de promoção |
| CT-038 | Texto simples bate com HTML | Fallback em texto puro precisa ter as mesmas lojas que o HTML | Comparar presença de nomes nas duas versões |
| CT-064 | Escape de texto hostil ⚠️ | RN07 — nome contendo `<`, `&` ou aspas não pode injetar markup no e-mail | Loja chamada `<b>Loja</b> & "X"`, checar que sai escapado |
| CT-065 | Link fora do domínio da Livelo | PRD §9.2 — link que não aponta para a Livelo não entra no e-mail | Parceiro com link externo, checar que o botão não é gerado com ele |
| CT-066 | Categoria vazia não aparece | RN14 — categoria sem loja em promoção some do e-mail | Agrupamento com categoria vazia, checar ausência do título |
| CT-067 | Pontuação fracionada | PRD §5.4 — `Decimal` evita `2.9000000000000004` no corpo | Parceiro com 2,9 pontos, checar o texto exato renderizado |
| CT-068 | Prefixo "Até" preservado na exibição | RN12 — o sentido de "Até X pontos" não pode se perder | Parceiro com `prefixo_ate=True`, checar que o texto exibe "Até" |
| CT-096 | Termina hoje recebe destaque (RN22) | `fim_promocao` no mesmo dia do `agora` mostra "Termina hoje!" com destaque próprio | Parceiro com `fim` igual ao dia do `agora` do teste, checar HTML e texto |
| CT-097 | Validade futura mostra data (RF18) | `fim_promocao` numa data futura mostra "Válido até DD/MM", sem o destaque de RN22 | Parceiro com `fim` alguns dias à frente |
| CT-098 | Sem `fim_promocao`, sem texto de validade | Não pode gerar texto nem quebrar | Parceiro com `fim=None` |
| CT-099 | Marca exclusivo Clube (RN23) | Base parada (`pontos_atuais == pontos_base`) com `pontos_clube` maior — o exemplo real do PRD-V2 (O Boticário) | Parceiro com `base` igual a `pontos_atuais` e `clube` maior |
| CT-100 | Base também turbinada não marca exclusivo | Contraprova de CT-099 — é bônus geral, não só do Clube | Parceiro com `base` menor que `pontos_atuais` e `clube` maior ainda |
| CT-101 | Sem `pontos_clube`, sem marcação | Regressão de CT-033 | Parceiro sem `clube` |
| CT-103 | `PROMOTION_CLUB` ganha rótulo próprio | RN23 — a base subiu também, então não é exclusivo: o não assinante aproveita, só não pelo número maior | Sephora real (base 1 → 6, Clube 10), checar "assinantes Clube ganham mais" e ausência de "exclusivo" |
| CT-104 | `CLUB` marca exclusivo sem depender de `pontos_base` | RN23 — a string confirmada decide sozinha | Parceiro com `campanha="CLUB"` e `pontos_base=None`, checar "exclusivo assinantes Clube" |
| CT-105 | Campanha desconhecida cai na comparação numérica | Valor novo que a Livelo invente não pode derrubar a marcação | Dois parceiros com campanha inventada, um com base parada e outro não |

## `testes/teste_principal.py` — orquestração com **fakes** das 3 portas (sem rede nem e-mail reais)

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-040 | Filtra loja fora do catálogo | Loja em promoção mas fora das favoritas deve ser ignorada (RN05) | Lista com 1 cadastrada + 1 não cadastrada, checar filtro |
| CT-041 | Filtra loja sem promoção | Loja cadastrada mas com `em_promocao=False` não entra | Simular essa loja, checar ausência no resultado |
| CT-042 | Agrupamento por categoria | Duas lojas da mesma categoria caem na mesma lista | 2 lojas de "Beleza", checar `len(resultado["Beleza"]) == 2` |
| CT-024 | Alerta de quebra ⚠️ | RN13 — total abaixo do limiar encerra a execução com falha. Veio de `teste_extrator.py`: o limiar é regra de negócio, não parsing (PRD §6.4) | Fake devolvendo menos parceiros que o limiar, checar exceção e código de saída ≠ 0 |
| CT-043 | Sem promoções, envia mesmo assim | RF10 — toda execução envia. Substitui os antigos CT-043/CT-044, que testavam o `SEMPRE_ENVIAR` eliminado | Fake sem promoções, checar que o notificador **foi** chamado com o assunto de ausência |
| CT-045 | Credenciais corretas no envio | O adaptador deve usar exatamente as variáveis configuradas | Fake de notificador, checar os argumentos recebidos |
| CT-046 | Falha de login no Gmail | Senha errada não pode travar sem explicação | Simular erro de autenticação, checar exceção legível |
| CT-069 | Segredo faltando falha antes da rede ⚠️ | PRD §7.3 — validação na largada, sem gastar requisição | Remover um segredo, checar erro e que a fonte de página **não** foi chamada |
| CT-070 | Favoritas ausentes vão pro log | RN19 — favorita cadastrada que não apareceu na página é registrada no log, nunca no e-mail | Fake sem uma das favoritas, checar log e ausência no e-mail |
| CT-071 | Parceiro malformado não derruba | PRD §6.4 — descarta só aquele parceiro e segue | Fake com 1 parceiro de valor inválido entre válidos, checar que o e-mail sai |
| CT-072 | Destinatário único | RN17/RN18 — envio sem CC e sem BCC | Checar que o notificador recebeu exatamente um destinatário |
| CT-073 | Nenhum segredo no log ⚠️ | RNF05 — log do Actions é público | Capturar a saída de log da execução completa, checar ausência de senha e de e-mail |
| CT-102 | `agora` chega ao extrator e ao e-mail, fim a fim | O mesmo `agora` passado a `verificar_promocoes` decide RN21 no extrator e RN22 no montador — uma promoção que termina hoje aparece destacada no e-mail final | Fluxo completo com fakes, checar "Termina hoje!" no resultado |
| CT-114 | Sem `DATABASE_URL`, catálogo vem do arquivo | Quem clona o projeto e roda na própria máquina não tem Neon | `montar_catalogo({})`, checar `CatalogoArquivo` |
| CT-115 | Com `DATABASE_URL`, o banco manda e o arquivo fica de reserva | PRD V2 §7.1.1 | `montar_catalogo` com a variável, checar `CatalogoComReserva` |
| CT-116 | `DATABASE_URL` em branco conta como ausente | Secret não configurado no Actions chega como string vazia, não ausente — sem isto o robô tentaria conectar em `""` | `montar_catalogo` com espaços, checar `CatalogoArquivo` |
| CT-134 | Sem `DATABASE_URL`, preferências são os padrões | Simétrico a CT-114 | `montar_preferencias({})` |
| CT-135 | Com `DATABASE_URL`, preferências vêm do banco com reserva | Simétrico a CT-115 | `montar_preferencias` com a variável |
| CT-136 | O alerta manda no e-mail, não a etiqueta ⚠️ | RN27 fim a fim: a Livelo etiqueta um sem aumento e esquece outro que triplicou | Payload com os dois casos, checar quem sai no e-mail |
| CT-137 | Preferências do banco mudam o resultado | RN28 fim a fim: a mesma página com três réguas | Fake da porta com piso e multiplicador diferentes |
| CT-138 | Suspeita de RN29 vai para o log ⚠️ | Silêncio com página parada é suspeita, não dia fraco | Payload com todos os parceiros parados, checar `WARNING` |
| CT-147 | Sem `DATABASE_URL` não há onde guardar | Quem clonou sem Neon continua recebendo e-mail | `montar_repositorio({})`, checar `RepositorioNulo` |
| CT-148 | Com `DATABASE_URL` o retrato vai para o banco | RF15 | `montar_repositorio` com a variável |
| CT-149 | Retrato registrado depois do e-mail | RF15 fim a fim: o site recebe **todas** as favoritas, não só as alertadas (RN24) | Fluxo completo com fake de repositório |
| CT-150 | Falha ao guardar não derruba a execução ⚠️ | A consequência é site velho, que o carimbo de RN26 denuncia sozinho. Perder o e-mail do dia seria pior | Repositório que levanta `FalhaAoGuardar`, checar e-mail enviado e `WARNING` |

## `testes/teste_alertas.py` — núcleo puro: o que merece alerta (PRD-V2 §6.1)

> Bloco novo da V2.2. Os números dos casos vêm da medição real de 2026-08-09 e 2026-08-11 registrada no PRD-V2 — são exatamente os exemplos que a V1 errava.

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-117 | Cruza multiplicador e piso dispara | RN27 — `Crocs` 2 → 7 | Parceiro com base 2 e 7 pontos, régua padrão |
| CT-118 | Dobrou mas não passa do piso | RN27 — `Mercado Livre` 1 → 2. Dobrou, mas são 2 pontos | Base 1 e 2 pontos, checar recusa |
| CT-119 | Pontuação alta permanente não dispara ⚠️ | RN27 — `Claro` dá 6 com base 6 e `Natura` 4 com base 4. Um limiar absoluto de 5 mandaria a Claro todo dia | Base igual à pontuação atual, checar recusa |
| CT-120 | Aumento sem etiqueta dispara ⚠️ | RN27 invertendo RN02 — `Avon` 2 → 6 sem etiqueta nenhuma. Era o falso negativo da V1 | Parceiro com `em_promocao=False` e base 3x menor |
| CT-121 | Etiqueta sem aumento não dispara ⚠️ | RN27 — `O Boticário` 3 → 3 etiquetado. Era o falso positivo da V1 | Parceiro com `em_promocao=True` e base igual |
| CT-122 | Sobrescrita da loja vence o padrão global | RN28 — `None` na loja usa o padrão; valor na loja manda | Mesma loja com três réguas: padrão, multiplicador frouxo, piso alto |
| CT-123 | `CLUB` não alerta quem não assina | RN23 — o ganho é de outra pessoa. `PROMOTION_CLUB` passa, porque nesse a base subiu para todos | Dois parceiros, um de cada campanha |
| CT-124 | Assinante enxerga o tier do Clube | RN23 — para quem assina, a pontuação que vale é `parityClub` | Mesmo parceiro com `assinante_clube` false e true |
| CT-125 | Sem base, cai no critério da V1 mais o piso | Sem `parityBau` não dá para provar aumento, mas sumir em silêncio é pior | Três parceiros sem base: com etiqueta, sem etiqueta, e abaixo do piso |
| CT-126 | Valor de disparo é o maior entre múltiplo e piso | RN30 — é o número que o site exibe ao lado da loja | Base baixa (manda o piso), base alta (manda o múltiplo), sem base (`None`) |
| CT-127 | Silêncio com página degenerada vira suspeita ⚠️ | RN29/C07 — `parityBau` chegar igual ao valor promocional zera todos os alertas sem nada quebrar | 20 parceiros com base igual à pontuação, zero alertas |
| CT-128 | Silêncio com página normal não vira suspeita | Contraprova de CT-127: dia fraco de verdade não pode virar alarme | 20 parceiros com base menor, zero alertas |
| CT-129 | Havendo alerta não há suspeita | RN29 só olha o silêncio | Mesma página de CT-127 com um alerta |

Sem ID: página que parou de trazer `parityBau` também levanta suspeita, página vazia não (aí quem falha é RN13), e o critério fechado sobre as preferências chega intacto ao `agrupar`.

## `testes/teste_retrato.py` — núcleo puro: o retrato da execução (PRD-V2 RF15)

> Bloco novo da V2.3. O robô passa a guardar o que viu, para o site ter o que mostrar.

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-139 | Todas as favoritas entram, em promoção ou não ⚠️ | RN24 — se só as promoções entrassem, o site não responderia "quanto a Renner dá hoje?", que é o motivo da fase existir (O5) | Três favoritas, uma só na página sem promoção |
| CT-140 | Favorita ausente vira linha sem parceiro | RN19 — sumir com a loja faria o leitor achar que ela saiu do catálogo, quando a Livelo é que mudou a grafia | Favorita que não aparece na página, checar `parceiro is None` |
| CT-141 | Apelido liga à loja certa | RN04 — a Livelo escreve "CEA", o catálogo diz "C&A" | Parceiro com a grafia do site, checar a loja canônica |
| CT-142 | Valor de disparo acompanha a régua | RN30 — o número é gravado calculado porque a régua muda com o tempo | Mesmo parceiro com duas réguas |
| CT-143 | Retrato carrega contagem e versão | RN26 — o carimbo do site sai daqui; a versão torna o defeito rastreável | Checar `momento`, `parceiros_lidos`, `versao`, `alertas` |

## `testes/teste_fronteira.py` — arquitetura (PRD §9.3)

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-074 | Núcleo puro não importa dependência externa ⚠️ | A estrutura é plana, então a fronteira núcleo/adaptador só existe se for testada | Varrer os imports de `modelos.py`, `extrator.py`, `categorias.py`, `alertas.py` e `montador_email.py`, falhar se aparecer `requests`, `smtplib`, `tomllib`, `os`, `pathlib` ou `dotenv` |

---

## Fora dos testes automáticos

| ID | Título | Descrição |
|---|---|---|
| CT-050 | Smoke test manual periódico | Rodar o robô contra o site real e conferir com o olho o que nenhum teste automático vê. Roteiro abaixo. |
| CT-051 | Falha injetada uma vez | PRD MS3 — forçar uma falha proposital e confirmar que a notificação do GitHub chega. Feito uma vez, não repetido. |

### Roteiro do CT-050

**Quando rodar:** depois de mexer no `extrator.py` ou no `montador_email.py`, quando o e-mail parecer estranho, e uma vez por mês sem motivo nenhum. A suíte automática usa fixture: ela prova que o código faz o que foi combinado, nunca que a Livelo continua entregando o que combinou.

**Passo 1 — a página ainda tem o payload:**

```bash
curl -sL -A "Mozilla/5.0" https://www.livelo.com.br/juntar-pontos/todos-os-parceiros -o /tmp/livelo.html
grep -c '__NEXT_DATA__' /tmp/livelo.html   # espera 1
```

Zero aqui significa que a Livelo trocou a tecnologia da página. É o cenário de C04, não um bug do robô.

**Passo 2 — a extração ainda funciona:**

```bash
python - <<'PY'
from datetime import datetime, timedelta, timezone
from robo_livelo.extrator import extrair_parceiros
agora = datetime.now(timezone(timedelta(hours=-3)))
p = extrair_parceiros(open('/tmp/livelo.html', encoding='utf-8').read(), agora=agora)
print(len(p), 'parceiros |', sum(x.em_promocao for x in p), 'em promoção')
print(sorted({x.campanha for x in p}))
PY
```

O que conferir:

| Sinal | Esperado em 2026-08-11 | O que significa se mudar |
|---|---|---|
| Total de parceiros | ~254 | Abaixo de 150 o robô falha sozinho por RN13. Entre 150 e 200, ninguém avisa — é justamente o que este passo pega |
| Em promoção | 31 | Zero por vários dias seguidos é suspeito (C07) |
| Valores de `campanha` | `BAU`, `PROMOTION`, `CLUB`, `PROMOTION_CLUB` | Valor novo na lista significa regra nova da Livelo e RN23 desatualizada |

**Passo 3 — o e-mail (a parte que só o olho pega):** abrir o último e-mail recebido e conferir que a validade aparece (`Válido até dd/mm` ou `Termina hoje!`), que o rótulo do Clube bate com o caso (`exclusivo assinantes Clube` só quando a base não se moveu), que os pontos não têm cauda de `float` (`2,9`, nunca `2,9000000000000004`) e que o Gmail não cortou o fim da mensagem com "[Mensagem truncada]" (C05).

**Passo 4 — registrar:** anotar a data e os números em `docs/PENDENCIAS.md`. Sem registro, a comparação do mês seguinte não tem contra o quê comparar.

---

## Totais

Os casos com identificador CT são os planejados. A implementação acrescentou testes de apoio sem identificador (caminhos de descarte, validação do catálogo real, ordenação), por isso o número executado é maior que o catalogado.

| Arquivo | Casos CT | Executados |
|---|---|---|
| `teste_categorias.py` | 8 | 12 |
| `teste_extrator.py` | 26 | 34 |
| `teste_adaptadores.py` | 20 | 25 |
| `teste_alertas.py` | 13 | 17 |
| `teste_retrato.py` | 5 | 5 |
| `teste_montador_email.py` | 23 | 26 |
| `teste_principal.py` | 25 | 27 |
| `teste_fronteira.py` | 1 | 7 |
| **Total** | **121** | **153** |

`teste_extrator.py` conta 24, não 27: CT-015, CT-016 e CT-019 (V1) foram aposentados na V2.0, não substituídos por outro número.

Manuais: CT-050 e CT-051.

Confirme o número real com `pytest --collect-only -q` antes de citá-lo em qualquer documento — foi assim que o total errado de "47 casos" sobreviveu ao planejamento original.
