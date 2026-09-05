# Plano de Testes

Casos de teste organizados por módulo. Todos rodam automaticamente a cada `git push`, via `testes.yml`: o robô usa `pytest` e o app e a API usam Flutter/TypeScript.

A estratégia (pirâmide, uso de fakes, meta de cobertura) está na **Seção 8 do [`PRD-LIVELO.md`](PRD-LIVELO.md)**. Este documento é só o catálogo de casos.

Convenção: arquivos e funções de teste usam o prefixo `teste_` (em vez do padrão `test_` do pytest), configurado no `pyproject.toml`.

A numeração tem lacunas propositais (009, 025–029, 039, 047–059) para deixar espaço de crescimento em cada bloco. **O total é a soma dos itens listados, nunca o intervalo.**

---

## `backend/robo/testes/teste_categorias.py` — função `reconhecer()`

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

## `backend/robo/testes/teste_extrator.py` — núcleo puro: payload JSON → `Parceiro` (fixture do payload, **nunca** rede)

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
| CT-095 | Integração com o payload real recortado | A fixture é o payload de verdade (capturado ao vivo em 2026-08), não inventado | `backend/robo/backend/robo/testes/fixtures/payload_parceiros.json`, checar nomes e os casos difíceis (RN21, RN22 candidato, RN23, dado malformado) |
| CT-106 | Item sem `parity` não vira `WARNING` | São 11 por execução (produtos da própria Livelo: `LVA`, `CIB`, `XXX`...). Descartar está certo; gritar toda vez afogaria o aviso que importa (RNF06). Vai em `DEBUG` mais um resumo em `INFO` | Item com `parity` ausente entre válidos, checar nível dos registros |
| CT-107 | `parity` presente mas ilegível continua `WARNING` | Contraprova de CT-106: pontuação que existe e não dá para ler é sintoma de mudança na página | Item com `parity.parity` não numérico, checar `WARNING` |
| CT-166 | `legalTerms` vira texto puro (RN31) | RN07 — só o texto sai daqui, nunca a marcação HTML crua | Item com `legalTerms: "<p>Campanha válida...</p>"`, checar `descricao_campanha` sem as tags |
| CT-167 | `legalTerms` vazio vira `None`, não string vazia | `"<p><br></p>"` é o formato mais comum quando a Livelo não publica letra miúda para o parceiro | Item com `legalTerms: "<p><br></p>"`, checar `descricao_campanha is None` |

Também há um bloco sem ID de "robustez contra payload hostil" (RN07): script `__NEXT_DATA__` ausente, JSON inválido, payload que não é objeto, componente ou item que não é um objeto, `parity` que não é um objeto, `parityBau`/`parityClub` não numéricos — todos cobertos, contam para o total executado mas não têm CT próprio (mesma convenção dos testes de apoio já existentes no arquivo).

## `backend/robo/testes/teste_adaptadores.py` — implementações das portas (PRD §4.2)

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
| CT-114 | Preferência do sino por loja | `alerta_ativo` vem do Postgres e controla se a régua pode gerar alerta | Fake de `psycopg` com a coluna booleana, checar `LojaFavorita.alerta_ativo` |
| CT-113 | Senha da URL não vaza na mensagem de erro ⚠️ | PRD §9.1 — o log do Actions é público e a exceção original carrega a `DATABASE_URL` inteira | Fake que falha ao conectar, checar ausência da senha no texto e `__cause__` cortado |
| CT-130 | Preferências padrão sem banco | Quem não tem Neon roda com 2,0x e piso 4 (PRD-V2 §6.1) | `PreferenciasPadrao().carregar()` |
| CT-131 | Preferências vindas do banco | RN28 — a régua é editável sem `git push` | Fake de `psycopg` devolvendo as três chaves |
| CT-132 | Preferência ilegível ou ausente cai no padrão | Escolha oposta à do catálogo: existe valor sensato para seguir, então a rodada continua — mas não em silêncio | Chave com texto no lugar de número, checar padrão e `WARNING` |
| CT-133 | Preferências caem para o padrão quando o banco falha | Mesmo motivo de CT-108 | Principal que levanta `ConfiguracaoInvalida`, checar padrão e `WARNING` |
| CT-144 | Grava execução e pontuações na mesma transação | Retrato pela metade no banco viraria página mentindo, que é pior que página velha | Fake de `psycopg`, checar a linha de execução e as de pontuação |
| CT-145 | Link fora do domínio não é gravado ⚠️ | RN08 vale para o site também: link arbitrário não entra na página | Parceiro com link hostil, checar `link is None` |
| CT-146 | Falha ao gravar não vaza a senha ⚠️ | PRD §9.1 — a exceção do `psycopg` carrega a URL inteira | Fake que falha, checar ausência da senha e `__cause__` cortado |
| CT-159 | Banco vazio não é falha ⚠️ | Levantar aqui faria a reserva cair no TOML e ressuscitar as lojas que o dono acabou de apagar pelo site. A reserva cobre indisponibilidade, não vontade | Consulta que devolve zero linhas, checar `[]` e `WARNING` |
| CT-160 | Banco vazio não aciona a reserva | Contraprova de CT-108: só falha de verdade chega na reserva | Principal vazio com reserva cheia, checar que a reserva não foi chamada |

## `backend/robo/testes/teste_montador_email.py` — função `montar_email()`

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
| CT-161 | Catálogo vazio tem assunto próprio ⚠️ | "Não teve promoção" e "você não tem loja nenhuma" não podem ler igual — a segunda com a frase da primeira faria o robô parecer trabalhando quando não há o que procurar | `montar({}, catalogo_vazio=True)`, checar assunto e corpo |
| CT-162 | Sem promoção continua com a frase de sempre | Contraprova de CT-161 | `montar({})` sem a marca |
| CT-169 | Descrição com mais de uma frase ganha "…mais" (redesign 2026-08-13) | `<details>/<summary>` sem JavaScript — primeira frase sempre visível, resto atrás do clique | Descrição com duas frases, checar `<details` e as duas frases presentes |
| CT-170 | Descrição de frase única não ganha "…mais" | Sem segunda frase não há o que esconder — clicar não revelaria nada novo | Descrição com uma frase só, checar ausência de `<details` |
| CT-171 | Sem `descricao_campanha`, sem bloco de descrição | Card sem descrição não ganha rodapé nenhum, nem vazio | Parceiro com `descricao_campanha=None` |
| CT-172 | Descrição longa corta sem quebrar palavra (C05) | O "resto" atrás do "…mais" tem teto, para o pior caso (132 lojas) caber no limite do Gmail | Descrição com "resto" bem acima do limite, checar corte em fronteira de palavra |
| CT-173 | Marca aparece no topo e no rodapé | Redesign 2026-08-13: logo R$→ponto hospedado em URL, assinando as duas pontas do e-mail. Não pode usar `data:` URI, que o Gmail descarta | `montar(...)`, contar duas ocorrências de `https://robo-livelo.vercel.app/logo.png` e checar ausência de `data:image` |

## `backend/robo/testes/teste_principal.py` — orquestração com **fakes** das 3 portas (sem rede nem e-mail reais)

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
| CT-163 | Catálogo vazio avisa no e-mail e no log ⚠️ | Fim a fim: banco sem loja nenhuma não vira "dia sem promoção" | `CatalogoFake([])`, checar assunto próprio e `WARNING` |
| CT-168 | `enviar_email=False` cala o notificador, não o retrato | RF13: disparo manual do site. Não é RF16 — não depende de ter promoção, depende de quem pediu a execução | Fluxo completo com `enviar_email=False`, checar `notificador.foi_chamado is False` e retrato gravado igual |
| CT-169 | Sino desligado suprime alerta | RN27 — a régua continua calculada, mas só uma loja marcada no sino gera alerta | Retrato com loja acompanhada e `alerta_ativo=False`, checar `alertou is False` |

## `backend/robo/testes/teste_alertas.py` — núcleo puro: o que merece alerta (PRD-V2 §6.1)

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

## `backend/robo/testes/teste_retrato.py` — núcleo puro: o retrato da execução (PRD-V2 RF15)

> Bloco novo da V2.3. O robô passa a guardar o que viu, para o site ter o que mostrar.

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-139 | Todas as favoritas entram, em promoção ou não ⚠️ | RN24 — se só as promoções entrassem, o site não responderia "quanto a Renner dá hoje?", que é o motivo da fase existir (O5) | Três favoritas, uma só na página sem promoção |
| CT-140 | Favorita ausente vira linha sem parceiro | RN19 — sumir com a loja faria o leitor achar que ela saiu do catálogo, quando a Livelo é que mudou a grafia | Favorita que não aparece na página, checar `parceiro is None` |
| CT-141 | Apelido liga à loja certa | RN04 — a Livelo escreve "CEA", o catálogo diz "C&A" | Parceiro com a grafia do site, checar a loja canônica |
| CT-142 | Valor de disparo acompanha a régua | RN30 — o número é gravado calculado porque a régua muda com o tempo | Mesmo parceiro com duas réguas |
| CT-143 | Retrato carrega contagem e versão | RN26 — o carimbo do site sai daqui; a versão torna o defeito rastreável | Checar `momento`, `parceiros_lidos`, `versao`, `alertas` |

## `backend/robo/testes/teste_fronteira.py` — arquitetura (PRD §9.3)

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-074 | Núcleo puro não importa dependência externa ⚠️ | A estrutura é plana, então a fronteira núcleo/adaptador só existe se for testada | Varrer os imports de `modelos.py`, `extrator.py`, `categorias.py`, `alertas.py` e `montador_email.py`, falhar se aparecer `requests`, `smtplib`, `tomllib`, `os`, `pathlib` ou `dotenv` |

## Formatação do app/API (antes `site/testes/formato.teste.ts`, TypeScript)

> Bloco novo da V2.3. A interface tem pouca lógica de propósito: o que ela faz é ler o banco e desenhar. O que **tem** regra é a formatação — e é onde um `Number()` distraído desfaria o cuidado que o robô tem com `Decimal` desde a V1.

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-151 | Pontuação sem resíduo de `float` ⚠️ | O `NUMERIC` do Postgres chega como string e assim fica. `Number("2.90")` traria de volta o `2.9000000000000004` que o e-mail evita (PRD §5.4) | `pontos("2.90")` → `"2,9"`; `pontos(null)` → `"—"` |
| CT-152 | Rótulo do Clube (RN23) | Mesma distinção do e-mail: `CLUB` é exclusividade, `PROMOTION_CLUB` é vantagem maior | As duas campanhas mais uma desconhecida |
| CT-153 | Termina hoje no fuso certo (RN22) | A Vercel roda em UTC. Sem fixar Brasília, promoção que acaba 23h59 apareceria como "amanhã" | Data de hoje e data futura |
| CT-154 | Idade do carimbo (RN26) | O carimbo só cumpre o papel se der para perceber que envelheceu — é o que sustenta MS6 | 30 min, 3 h, 20 h e 3 dias |
| CT-155 | Pontuação inteira não ganha vírgula | `6`, não `6,00` | `pontos("6.000")` |
| CT-156 | Busca ignora acento e caixa (RN03) | Quem digita no celular não põe acento. Mesma normalização do robô | "boticario", "BOTICÁRIO" e " renner " |
| CT-157 | Busca aceita pedaço do nome ⚠️ | RN04 proíbe substring no **reconhecimento** da loja, onde um erro troca a pontuação de uma pela de outra. Na busca da tela não há esse risco: quem escolhe o resultado é o olho de quem procura | "pet" acha Petlove e Petz; "petl" acha só Petlove |
| CT-158 | Âncora de categoria | O índice da página pula a rolagem de 130 lojas | "Marketplace / Varejo Geral" → `marketplace-varejo-geral` |
| CT-164 | Limiar em branco vira `null`, nunca `"0"` (RN28) ⚠️ | Campo vazio e zero são coisas diferentes: um segue o padrão global, o outro é um limiar real de zero pontos. `numeroOuPadrao` é compartilhado entre `/lojas` (cadastro) e `/avisos` (exceção), então o mesmo comportamento vale nas duas telas | `numeroOuPadrao("")` → `null`; `numeroOuPadrao("2,5")` → `"2.5"`; `numeroOuPadrao("-1")` e `numeroOuPadrao("abc")` lançam erro |
| CT-165 | Barra de progresso do cartão (RN30, redesenho V2.3.3) | `atual`/`base` ausentes (loja não encontrada) devolvem `null`, sem dividir por zero; a largura nunca passa de 100% mesmo com o limiar bem acima do teto calculado | `barraDeProgresso(null, ...)` → `null`; `barraDeProgresso("6", "1", "4")` com valores dentro de 0–100; teto vindo de zero não gera `NaN`/`Infinity` |
| CT-174 | Ordenação do Painel (redesenho V4.6) | A grade única do Painel troca o agrupamento por categoria por ordenação explícita, sem `Number()` virar texto exibido | Ordenar por maior pontuação, em alerta e nome A-Z, preservando casos sem pontuação |

Rodavam com `npm run testar` dentro de `site/` (removido em 2026-08-24). A API agora vive arquivada em `backend/api/`; esses casos de contrato permanecem como registro.

## Shopping Inter — V3

> Casos da V3 definidos no [`PRD-INTER-CASHBACK.md`](PRD-INTER-CASHBACK.md). A suíte padrão usa a
> fixture sanitizada `backend/robo/testes/fixtures/lojas_inter.json` e nunca toca a rede.

### `backend/robo/testes/teste_extrator_inter.py` — JSON público → `LojaInter`

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-175 | Fixture recortada sem rede | Os cinco formatos representativos da fonte viram cinco lojas | Extrair `lojas_inter.json` e comparar total, IDs e nomes |
| CT-176 | Oferta principal usa `Decimal` | Texto e número principal não se confundem nem passam por `float` | Magalu → `"Até 20% de cashback"` e `Decimal("20")` |
| CT-177 | Oferta secundária fica separada | A condição de não-correntista nunca sobrescreve a principal | Magalu → 14 no campo secundário e 20 no principal |
| CT-178 | Zero pode ser “Ofertas disponíveis” | Zero não significa loja ausente | Amazon → texto preservado, valor `Decimal("0")` |
| CT-179 | Descrição multilinha e vazia | Condições são preservadas; string vazia vira `None` | Magalu mantém as faixas; C&A fica sem descrição |
| CT-180 | Identidade por ID e slug | Mudança de nome não muda a identidade da favorita | Mesmo ID/slug com outro nome continua a mesma loja |
| CT-182 | Catálogo pequeno falha | RN43 protege o último retrato de resposta parcial | Validar cinco lojas com limiar 100 → `SiteInterMudou` |
| CT-183 | Resposta inválida falha ruidosamente | Objeto, JSON quebrado e estrutura incompatível não viram catálogo vazio | Entradas inválidas levantam erro próprio |
| CT-186 | Imagem não entra no domínio | `imageUrl` da fonte não é persistida nem exposta pelo modelo | Inspecionar campos de `LojaInter` |

### `backend/robo/testes/teste_ranking_inter.py` — ordenação pura

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-181 | Ranking principal | Positivos descem por valor; empate por nome; zero e ausente ficam depois | Misturar 20, 15, 12, 0, `None` e ausente |

### `backend/robo/testes/teste_retrato_inter.py` — favoritas da execução

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-184 | Favorita ausente permanece | Fonte não devolver a loja não remove a escolha | Favorita sem loja correspondente vira `encontrada=false` |

### `backend/robo/testes/teste_adaptadores_inter.py` — HTTP e Postgres

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-185 | Transação é atômica | Falha entre catálogo e snapshot não deixa meia execução visível | Fake de conexão falha e verifica rollback |
| CT-187 | Uma consulta lógica | Sucesso chama HTTP uma vez; retry só ocorre em falha transitória | Injetar respostas e contar chamadas |

### `backend/robo/testes/teste_fronteira.py` — núcleo do Inter

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-188 | Núcleo do Inter não faz I/O | Modelos, extrator, ranking e retrato não importam rede, banco, arquivo ou ambiente | Varrer AST dos módulos novos |

### `backend/robo/testes/teste_principal_inter.py` — orquestração com fakes

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-189 | Falha isolada da Livelo | Processo do Inter usa somente suas portas e devolve código diferente de zero na falha | Fakes do Inter; nenhum módulo da Livelo é chamado |

### Formatação Inter (antes `site/testes/formato-inter.teste.ts`) — regras puras do Inter

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-190 | Busca normalizada | “C&A”, “c&a” e `slug=ca` encontram a mesma loja; resultado não é selecionado sozinho | Testar normalização e filtro |
| CT-191 | Ordenação do cashback | Positivos descem, zero fica depois e ausente vai ao final | Lista com todos os estados |
| CT-192 | Condições da Magalu | Card recebe 20%, 11% e 2% do mesmo snapshot | Fixture da Magalu |
| CT-193 | Ausência de descrição | Texto neutro aparece sem inventar promoção | Descrição `null` |
| CT-194 | Link genérico | O único destino é a constante aprovada | Comparar URL do card |
| CT-195 | Texto hostil é escapado | Tags vindas da fonte aparecem como texto | Renderizar nome/descrição com HTML |
| CT-196 | Estados não se confundem | Sem execução, falha recente, atraso e favorita ausente têm rótulos distintos | Função de estado com quatro entradas |
| CT-197 | Mutação exige sessão | Ações de selecionar, remover e disparar rejeitam visitante | Teste das guards das server actions |
| CT-198 | Sem imagem externa | Tipo e card não usam `imageUrl` | Inspeção do resultado renderizado |
| CT-199 | Livelo não regride | Formatação e rotas atuais continuam com o contrato anterior | Rodar toda a suíte existente junto com a V3 |

---

## Produtos do Shopping Inter — V4

> Casos definidos no [`PRD-INTER-PRODUTOS.md`](PRD-INTER-PRODUTOS.md). A primeira implementação usa
> `backend/robo/testes/teste_produtos_inter.py` para o domínio, paginação e isolamento,
> e `backend/api/` (antes `site/testes/formato-produtos-inter.teste.ts`) para a busca local e a migração
> `007`/`008` para a persistência. Em 2026-08-17, o aceite real da Casas Bahia
> confirmou 111 vendedores, 94 páginas, 3.310 produtos únicos e o Edge 60 Pro
> na busca local. Fixtures continuam obrigatórias para o CI não tocar a rede.

### `backend/robo/testes/teste_extrator_produtos_inter.py` — páginas públicas → produtos

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-200 | Catálogo de vendedores diretos | A fonte de Compre direto vira lojas com ID, slug e nome, separadas da V3 | Fixture com Casas Bahia, Ponto e outra loja |
| CT-201 | Campos comerciais usam `Decimal` | Preço cheio, atual, desconto, cashback e líquido não passam por `float` | Extrair produto com todos os valores e comparar `Decimal` |
| CT-202 | Texto e número permanecem separados | “R$ 3.688,89” e `Decimal("3688.89")` preservam papéis diferentes | Fixture com texto localizado e valor numérico |
| CT-203 | Campo opcional ausente | Marca, categoria, parcelamento ou etiqueta ausente não derruba produto válido nem vira zero | Remover cada opcional isoladamente |
| CT-204 | Item inválido é descartado | Produto sem ID, nome ou preço atual válido não contamina o catálogo | Misturar válidos e inválidos e conferir contagens |
| CT-205 | Raiz inválida falha | JSON quebrado, objeto inesperado ou paginação ausente não viram catálogo vazio | Entradas inválidas levantam erro controlado |
| CT-206 | Imagens e SKUs ficam fora | `image`, `images`, `thumbnails` e detalhes de `skus` não entram no modelo | Inspecionar produto extraído |
| CT-207 | Link individual seguro | Caminho relativo, com `?v=<ID>` opcional, vira HTTPS em `shopping.inter.co`; URL externa e query arbitrária são rejeitadas | Testar destinos válidos e hostis |
| CT-208 | Identidade por loja + produto | Mesmo ID em Casas Bahia e Ponto representa dois produtos distintos | Inserir ID igual sob duas lojas |
| CT-209 | Textos hostis continuam texto | Nome e etiquetas com HTML não são interpretados | Extrair tags maliciosas e renderizar escapado |
| CT-210 | Vendedor incompatível falha | Página pedida para Casas Bahia não aceita silenciosamente produto de outro vendedor | Fixture com `sellerId` inesperado |

### `backend/robo/testes/teste_paginacao_produtos_inter.py` — catálogo completo exposto

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-211 | Avança até a última página | Offsets crescem pelo limite retornado e param somente em `isLastPage=true` | Fixture de três páginas com última parcial |
| CT-212 | Sem teto artificial de 3.000 | Um total declarado de 5.000 continua sendo paginado até o fim | Fonte fake com mais de 84 páginas |
| CT-213 | `searchId` estável por partição | Todas as páginas da mesma partição usam o mesmo UUID; janela-base e suplemento usam IDs diferentes | Fonte fake registra argumentos |
| CT-214 | Produto repetido é deduplicado | ID repetido entre páginas gera um produto e incrementa duplicatas | Repetir o mesmo ID em duas páginas |
| CT-215 | Página repetida interrompe | Fingerprint repetido não causa loop infinito nem publica catálogo parcial | Fonte retorna a mesma página para offsets diferentes |
| CT-216 | Offset sem avanço interrompe | Limite zero ou próximo offset igual ao anterior vira falha de paginação | Página malformada com `limit=0` |
| CT-217 | União de partições é observável | Totais declarados, lidos, únicos e sobreposições permanecem separados | Janela-base + `smartphone` com ID repetido e Edge só no suplemento |

### `backend/robo/testes/teste_adaptadores_produtos_inter.py` — HTTP responsável

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-218 | Identificação honesta | Requisição usa User-Agent do projeto, JSON e nenhum cookie/token do Inter | Inspecionar chamada da sessão fake |
| CT-219 | Páginas sequenciais por loja | A próxima página só começa depois da anterior | Fonte controlada registra início e fim |
| CT-220 | Retry só em falha transitória | Timeout, 429 e 5xx respeitam limite; 401/403 encerram imediatamente | Parametrizar status e contar tentativas |
| CT-221 | Resposta grande é recusada | Limite de bytes impede carregar payload sem controle | Stream fake acima do máximo definido na V4.1 |

### `backend/robo/testes/teste_principal_produtos_inter.py` — seleção e isolamento

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-222 | Somente lojas selecionadas | Loja não selecionada nunca gera consulta de produto | Catálogo com dez lojas e seleção de Casas Bahia/Ponto |
| CT-223 | Quantidade de tarefas acompanha seleção | Zero, três e dez selecionadas produzem zero, três e dez tarefas, sem teto funcional | Repositório fake parametrizado |
| CT-224 | Falha de uma loja preserva as outras | Ponto falha e Casas Bahia publica normalmente; rodada geral fica parcial | Duas fontes fake com resultados diferentes |
| CT-225 | Catálogo parcial não é publicado | Falha na página 80 mantém o último sucesso da loja | Repositório fake verifica ausência de `publicar` |
| CT-226 | Publicação por loja é atômica | Produtos, inativações, medições e conclusão entram juntos ou sofrem rollback | Falhar entre etapas da transação |
| CT-227 | Produto ausente fica inativo | Produto do sucesso anterior que não veio no novo catálogo completo sai da busca atual | Dois snapshots sucessivos |
| CT-228 | Loja removida deixa de coletar | Desmarcar loja impede nova tarefa e esconde seu catálogo sem apagar histórico imediatamente | Alternar seleção entre rodadas |
| CT-229 | Retenção de 30 dias | Medição no limite permanece; mais antiga é removida sem tocar no catálogo atual | Relógio fixo e datas de fronteira |
| CT-230 | Log não vaza conteúdo sensível | Erro registra código e contagens, nunca payload, token ou `DATABASE_URL` | Exceções fake com segredos sentinela |
| CT-231 | Núcleo novo não faz I/O | Modelos, normalização, paginação e deduplicação não importam rede, banco ou ambiente | Ampliar o teste AST de fronteira |
| CT-245 | Tentativa estável vence | Total variável reinicia a partição; uma tentativa posterior estável é publicada e descarta candidatas instáveis, mesmo maiores | Fonte sequencial com tentativa variável e tentativa estável |
| CT-246 | Melhor tentativa degradada | Depois de três tentativas completas com total variável, publica a que contém mais produtos únicos válidos | Três candidatas com tamanhos distintos e inspeção do resumo |
| CT-247 | Ausentes são preservados | Publicação degradada grava encontrados e medições sem executar a inativação; publicação completa continua inativando | Adaptador Postgres com cursor fake nos dois modos |

### Site V4 — busca e histórico

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-232 | Busca normaliza celular/smartphone | “celular Motorola Edge 60 Pro” encontra nome iniciado por “Smartphone” | Função pura com os dois textos |
| CT-233 | Todos os termos significativos são exigidos | Edge 60 Pro entra; Moto G06 e Edge 60 Neo ficam fora | Lista com modelos próximos |
| CT-234 | Loja Ponto tem aliases de busca | “Ponto”, “Ponto Frio” e “Pontofrio” localizam `slug=ponto` sem mudar sua identidade | Normalização do cadastro de lojas |
| CT-235 | Busca pública respeita seleção | Produto de loja removida não aparece mesmo permanecendo armazenado | Consulta com duas lojas e uma ativa |
| CT-236 | Ordem usa preço numérico | Menor preço atual vem primeiro sem converter o texto exibido em `number` | Valores localizados e strings decimais |
| CT-237 | Card usa uma medição | Preço cheio, desconto, atual, cashback e líquido têm o mesmo ID de medição | Misturar dados de duas rodadas e rejeitar combinação |
| CT-238 | Ausente não vira zero | Campo monetário `null` some ou ganha rótulo neutro | Renderizar card incompleto |
| CT-239 | Histórico calcula mínimo e máximo | Resumo usa preço atual de medições dos últimos 30 dias com precisão decimal | Série com fronteira de retenção |
| CT-240 | Histórico informa desaparecimento | Produto inativo conserva tabela e não aparece como oferta atual | Estado atual ausente com medições anteriores |
| CT-241 | Mutação exige sessão | Selecionar, remover e disparar rejeitam visitante; busca e histórico são públicos | Guards das Server Actions e páginas |
| CT-242 | Sem imagem ou HTML externo | Cards não usam URLs de imagem nem `dangerouslySetInnerHTML` | Inspeção da renderização |
| CT-243 | Funciona sem JavaScript | Busca por `?q=`, seleção, remoção e histórico possuem HTML e formulários reais | Renderização de servidor e navegação manual |
| CT-244 | Integrações anteriores não regridem | V4 ausente, vazia ou falhando não muda Livelo nem V3 | Rodar todas as suítes e builds existentes |

### Fase 3B — autenticação da API e Flutter

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-248 | Bearer obrigatório | Endpoint privado recusa cabeçalho ausente ou ambíguo antes de ler dados | Dependências falsas e resposta 401 |
| CT-249 | Token inválido ou revogado | Falhas distintas do provedor viram a mesma resposta neutra | Firebase Admin falso lança exceção |
| CT-250 | E-mail verificado | Token válido sem e-mail confirmado não atravessa o gate | Claim `email_verified=false`, resposta 403 |
| CT-251 | Convite ativo | Existir no Firebase não basta; ausente ou inativo é recusado | Repositório de usuários falso |
| CT-252 | Papel no servidor | Usuário comum não executa operação marcada como admin | Papel exigido `admin`, resposta 403 |
| CT-253 | App Check em rollout | Quando exigido, token ausente/inválido é recusado antes da identidade | Alternar a dependência `appCheckObrigatorio` |
| CT-254 | Limite por origem | Excesso antes da autenticação devolve 429 e `Retry-After` | Contador persistente falso bloqueia primeira janela |
| CT-255 | Limite por usuário/operação | Segundo limite protege conta autenticada e ações sensíveis | Primeira janela aceita e segunda recusa |
| CT-256 | Falha interna neutra | Erro de banco/provedor não vaza URL ou segredo e conserva request ID | Exceção sentinela e corpo 500 |
| CT-257 | Tokens no cliente | Flutter envia Bearer/App Check em chamada privada e nunca chama rede privada sem sessão | `MockClient` inspeciona cabeçalhos |
| CT-258 | Login e recuperação | Tela envia credenciais pela porta injetada e recuperação não enumera e-mail | Testes de widget com autenticador falso |
| CT-259 | Gate de convite | Perfil autorizado abre o app; 403 mostra acesso negado e permite sair | API e autenticação falsas em widget test |
| CT-260 | Retenção da auditoria | Cada evento novo também remove registros técnicos anteriores a 30 dias | Banco falso inspeciona a consulta única de inserção e expurgo |
| CT-261 | Navegação inferior no celular | Os cinco destinos aparecem com ícone/rótulo e trocam o painel | Widget em viewport de telefone toca em Livelo |
| CT-262 | Navegação realmente adaptativa | Paisagem de celular mantém barra inferior; tela larga conserva lateral | Widgets com menor dimensão abaixo/acima de 600 px |

### Fase 4.2B — painel Livelo no Flutter

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-263 | Modelo Livelo completo | JSON da API vira `PontuacaoLivelo`, preservando opcionais e decimais como `String` | Fixture em Dart com todos os campos |
| CT-264 | Decimal textual de pontos | `2.90` vira `2,9` e `6.000` vira `6`, sem `double` | Testar formatador puro |
| CT-265 | Rótulos do Clube | `CLUB` e `PROMOTION_CLUB` recebem explicações distintas | Testar a função pura de rótulo |
| CT-266 | Validade e atraso | Data no fuso de Brasília e coleta acima de 12 h usam relógio explícito | Fixar `agora` no teste |
| CT-267 | Consulta do painel | Cliente mobile envia `q`, `ordenar`, `pagina` e `por_pagina=10` | `MockClient` inspeciona URL e resposta |
| CT-268 | Primeira página | Controlador expõe itens, total, carimbo e próxima página | Fonte injetada responde envelope válido |
| CT-269 | Paginação visível Livelo | Próximas páginas chegam pelos controles V11 e substituem os cartões visíveis | Duas respostas, com troca explícita para a página 2 |
| CT-270 | Concorrência, reset e resposta antiga | Não há duas chamadas de paginação; busca/ordenação limpam a sequência e descartam resposta antiga | `Completer` controla a ordem das respostas |
| CT-271 | Debounce da busca | Digitação só consulta após 350 ms sem nova entrada | Relógio de teste/fonte injetada |
| CT-272 | Erro de página adicional | Itens anteriores ficam visíveis e retry tenta apenas a próxima página | Primeira resposta válida, segunda falha e terceira passa |
| CT-273 | Estados do painel | Loading, falha/retry, sem coleta, catálogo vazio, busca vazia, atraso e loja ausente não se confundem | Testes de widget com controlador injetado |
| CT-274 | Cartão e condições | Pontos, base, limiar, Clube, promoção, estado de alerta e condições expansíveis são renderizados com texto seguro; o cartão mobile não exibe o controle de sino | Widget com modelo completo |
| CT-275 | Filtros e fim da lista | Os três controles aparecem; página final informa que não há mais resultados | Tocar controles e carregar a última resposta |
| CT-276 | Layout e navegação Livelo | Retrato, tela larga e toque em Livelo preservam a moldura e exibem o painel real | Widgets em viewports distintos |

### Fase 4.3 — cashback Inter no Flutter

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-277 | Modelo e carimbo Inter | Oferta textual, decimais como `String`, opcionais e horário de Brasília são preservados; atraso ocorre somente após 24 h | Fixture Dart e relógio explícito |
| CT-278 | Consulta do cashback | Cliente mobile envia `q`, `ordenar`, `pagina` e `por_pagina=10` ao endpoint autenticado | `MockClient` inspeciona URL e envelope |
| CT-279 | Página visível Inter | Primeira página e página seguinte trocam os cards sem acumulá-los na rolagem | Fonte injetada com duas páginas |
| CT-280 | Reset e resposta antiga | Busca/ordenação reiniciam a sequência, aguardam 350 ms e descartam a resposta anterior | `Completer` e fonte injetada |
| CT-281 | Erro de página adicional | Lista anterior permanece visível e o retry consulta a mesma página | Segunda resposta falha, terceira responde |
| CT-282 | Falha, atraso e ausência | Última tentativa falha sem apagar o último retrato; atraso, sem coleta e loja ausente têm textos diferentes | Envelope com metadados de tentativa e widgets |
| CT-283 | Card e condições completas | Oferta principal, etiqueta, condição neutra e seção não-correntista são renderizadas como texto | Widget com payload completo e sem descrição |
| CT-284 | Navegação e responsividade Inter | Tocar Inter abre o painel real e a moldura preserva abas, retrato/paisagem e tela larga | Widget da moldura em viewports distintos |

### Fase 4.4 — produtos no Flutter

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-285 | Modelo e histórico de produto | Campos comerciais, medições e valores `NUMERIC` permanecem textuais; carimbo usa Brasília e atraso de 12 h | Fixtures Dart e relógio explícito |
| CT-286 | Contrato de histórico | Cliente envia loja, produto e paginação própria de 30 itens ao endpoint autenticado | `MockClient` inspeciona URL e resposta |
| CT-287 | Busca paginada local | Termo curto não consulta; busca aguarda 350 ms, pagina e deduplica por loja + ID | Controlador com fonte injetada |
| CT-288 | Filtros e respostas antigas | Filtros reiniciam a sequência e a resposta de consulta descartada não reaparece | `Completer` controla a ordem |
| CT-289 | Falha adicional de produtos | Itens existentes permanecem e retry carrega a mesma página | Segunda resposta falha, terceira passa |
| CT-290 | Estados e cards de produto | Termo mínimo, vazio, falha/retry, qualidade degradada, preço, cashback, líquido e grupos de loja são distintos | Widgets com controlador injetado |
| CT-291 | Filtros de Produtos por lojas selecionadas | A folha de meia tela não exibe Marca, Categoria nem “Loja (slug)”. Conta administrativa recebe todas as páginas de lojas `acompanhadas`, informa a quantidade selecionada para coleta e oferece “Todas as lojas” mais uma escolha por nome/slug retornado. Mínimo e máximo são os únicos campos editáveis; o recorte de categoria é iniciado somente pela busca contextual por área. Aplicar envia somente a loja exata e a faixa, preserva termo e recorte ativo e reinicia a paginação local. Durante a consulta, os cards anteriores permanecem montados e na mesma posição | `pagina_produtos_test.dart` com `MockClient` para duas lojas selecionadas; tocar Loja, preencher mínimo/máximo, inspecionar os argumentos do controlador, conferir que o modal não contém opções de categoria nem supera metade da altura compacta e completar uma resposta atrasada verificando a permanência do card |
| CT-292 | Inter abre Produtos | O atalho interno na aba Inter abre a busca sem descartar o painel de cashback | Teste de widget da navegação interna |
| CT-293 | Histórico de 30 dias | Mínimo, máximo, medições paginadas, falha e retry aparecem sem converter valores em `double` | Mock autenticado da API e widget |
| CT-293A | Escopo contextual de Produtos | O app percorre área → subárea → recorte final (inclusive Casa → Eletrodomésticos → Refrigeração e lavanderia → Geladeiras/Freezers/Lavadoras, além de cozinhas, quarto/camas, limpeza/climatização, beleza, saúde e festas), exibe seta de voltar sem aplicar filtro e permite adicionar várias folhas. Os chips removem uma folha ou `Limpar` remove todas; o app serializa somente identificadores aprovados, únicos e ordenados. A API resolve sua união em categorias externas exatas, mantém paginação, rejeita escopo desconhecido/repetido e não combina escopo com categoria externa ou `Sem categoria`; `Outros / novas categorias` é exclusivo. Se app e API estiverem fora de versão, o erro preserva os cards anteriores e informa que eles podem não pertencer ao recorte atual | Vitest da rota e repositório; widget do seletor contextual |

### Fase 5 — administração compartilhada no Flutter/API

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-294 | Catálogos administrativos | Seleção, favoritas, paginação e deduplicação usam apenas os contratos autenticados da API | Cliente falso, controlador e widgets administrativos |
| CT-295 | Disparo idempotente e cooldown | Duplo toque não cria dois pedidos; o app exibe aceite/cooldown sem afirmar que a coleta terminou | API falsa, chave opaca e widget do botão de disparo |
| CT-296 | Decimais administrativos textuais | Pontos, limites, multiplicadores e cashback atravessam Flutter/API como texto, sem `double` | Fixtures e inspeção de corpo JSON |
| CT-297 | Preferências e regras Livelo | Padrões globais, Clube e exceção por loja usam rotas fechadas e preservam o estado carregado | API falsa e jornada de widget da administração |
| CT-298 | Limpeza protegida e descartável | Prévia, frase exata, autorização e rollback impedem limpeza acidental; o aceite destrutivo usa somente banco isolado | Widgets, Vitest e roteiro 5.3 do plano Flutter |

### Redesign — Etapa 1, identidade e abertura

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-299 | Logo vetorial | As variantes clara/escura conservam geometria e semântica | `logo_radar_test.dart` com `CustomPainter` e semântica |
| CT-300 | Bootstrap antes do gate | A raiz de produção desenha a abertura enquanto Firebase/App Check ainda inicializam | `Completer` injetado em `RadarApp.inicializando` |
| CT-301 | Ciclo visual mínimo | Resultado pronto aguarda somente o ciclo aprovado de 1,5 segundo; inicialização mais lenta não recebe espera adicional | Inicializadores falso imediato e lento com relógio controlado |
| CT-302 | Inicialização demorada honesta | Após o limiar, o status explica a demora e mantém a marca visível | Relógio do teste avança até `tempoParaAviso` |
| CT-303 | Falha segura e nova tentativa | Erro oferece retry, não vaza a exceção interna e uma tentativa válida segue o fluxo | Inicializadores pendente, excepcional e válido injetados |
| CT-304 | Movimento reduzido | A preferência do sistema desativa o ticker e os pulsos da marca | `MediaQueryData(disableAnimations: true)` e inspeção de `TickerMode` |

O APK instalado no Android conectado também validou manifests, ícones e o loop
dos recursos de abertura nativos e Flutter. O build Web passou antes dos ajustes
visuais finais do Android e não foi repetido nesta rodada. O
`LaunchScreen.storyboard` do iOS foi conferido estruturalmente, mas seu build
depende de Xcode/macOS e permanece parte do smoke físico da etapa.

### Redesign — Módulo 1, login

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-305 | Login responsivo | Celular prioriza o formulário; Web amplo separa apresentação e acesso no breakpoint aprovado | Widgets em 390 × 844 e 1440 × 900 |
| CT-306 | Credenciais sem transformação indevida | O e-mail perde somente espaços nas bordas; a senha chega intacta ao `Autenticador` | Autenticador falso inspeciona os argumentos recebidos |
| CT-307 | Senha acessível | Mostrar/ocultar troca rótulo e obscurecimento sem apagar o conteúdo | Tooltip, `EditableText` e conteúdo controlado |
| CT-308 | Envio pendente seguro | Loading preserva os dois campos e impede novo envio enquanto a tentativa está pendente | `Completer` injetado e inspeção do formulário |
| CT-309 | Falha e recuperação neutra | Erro não apaga os campos; recuperação nunca confirma se a conta existe, mesmo diante de falha conhecida do provedor | `FalhaDeAutenticacao` injetada e regiões de mensagem inspecionadas |
| CT-310 | Tela estreita e texto ampliado | Em 320 × 640 com texto a 150%, campos e ações continuam alcançáveis sem overflow | Viewport e `TextScaler` controlados |

O fechamento do módulo passou por formatação, análise, 131 testes, build Web e
APK debug. `pagina_entrar.dart` atingiu 233/241 linhas (96,68%); a cobertura
global observada foi 89,76%. O APK foi aberto no Samsung SM-M135M sem submeter
credenciais reais, e o responsável aprovou o resultado visual e dispensou o
restante do roteiro manual.

### Redesign — Módulo 2, moldura e navegação

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-311 | Destinos fixos do redesign | A ordem principal é Início, Lojas, Produtos, Alertas e Mais, sem esconder jornadas existentes | Enum fechado e inspeção dos cinco itens |
| CT-312 | Gaveta e lateral adaptativas | Mobile/retrato/paisagem usa cabeçalho + gaveta; Web a partir de 920 px usa lateral com a mesma ordem | Viewports 390 × 844, 844 × 390 e 1440 × 900 |
| CT-313 | Hub transitório de Lojas | Livelo e Shopping Inter continuam alcançáveis sem consultar resumo nem exibir métricas fictícias | API falsa e ações do hub isolado |
| CT-314 | Voltar na hierarquia interna | Voltar de Livelo/Inter retorna primeiro para Lojas em vez de sair do app | Navegador aninhado e `handlePopRoute` |
| CT-315 | Estado preservado entre áreas | Trocar de Produtos para outra área e retornar não apaga a busca digitada | `IndexedStack` e controlador do campo |
| CT-316 | Alertas e Administração preservados | Atalho do cabeçalho abre o estado honesto de Alertas; Mais mantém Administração para admin | Ações da moldura e API falsa fechada |
| CT-317 | Navegação com texto ampliado | Em 320 × 640 e texto a 150%, abrir/fechar e os cinco destinos continuam alcançáveis sem overflow | `TextScaler` e viewport controlados |
| CT-318 | Moldura adaptativa | Gaveta Mobile e lateral Web permanecem alcançáveis e preservam a ordem dos destinos | Widgets nos dois breakpoints |

O fechamento passou por formatação, análise, 137 testes, build Web e APK debug.
A cobertura global ficou em 2529/2805 linhas (90,16%); `moldura.dart` atingiu
116/118 (98,31%) e `lojas.dart`, 70/71 (98,59%). O APK foi instalado com
substituição, preservando os dados locais, e o responsável concluiu o teste
manual no Samsung SM-M135M com resultado aprovado.

### Redesign — Módulo 3, Início e resumo real

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-319 | Agregação isolada | Livelo, Cashback Inter e Produtos conservam relógios, recortes e contagens próprios | Dependências assíncronas injetadas no agregador TypeScript |
| CT-320 | Estados e frescor | Atualizado, atraso, atualização, falha recente, parcial, degradado e sem dados não se confundem | Relógio UTC explícito e fixtures de cada domínio |
| CT-321 | Falha parcial segura | Falha de uma consulta marca somente o domínio como indisponível, sem vazar exceção nem fabricar zero | Uma dependência rejeita e as outras respondem |
| CT-322 | Contrato Flutter | `/api/resumo` envia autenticação e converte estados, horários e contagens sem aceitar valores hostis | `MockClient` e modelos Dart manuais |
| CT-323 | Métricas e recortes | Alertas Livelo, lojas de cashback e produtos ativos exibem o recorte real; indisponível usa `—` | Widget com respostas válidas, zero e indisponibilidade |
| CT-324 | Retry sem apagar resumo | Falha na atualização mantém o último payload visível e oferece nova tentativa | Primeira resposta válida e segunda com erro |
| CT-325 | Atalhos reais | Lojas, Livelo, Produtos e Cashback Inter abrem as jornadas existentes | Callbacks isolados e moldura completa |
| CT-326 | Responsividade e acessibilidade | Web amplo, 320 × 640 e texto a 150% permanecem alcançáveis sem overflow | Viewports e `TextScaler` controlados |

O fechamento local passou por TypeScript, ESLint, 83 testes Vitest e build do
site legado (removido em 2026-08-24); a rota `/api/resumo` era a raiz do contrato de Início. No Flutter,
formatação, análise, 147 testes e builds Web/APK debug passaram. A cobertura
global ficou em 2872/3146 linhas (91,29%); `inicio.dart` atingiu 306/306
(100%). Não houve publicação, instalação ou smoke contra produção.

### Redesign — Módulo 4, hub de Lojas

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-328 | Resumos isolados no hub | Livelo, Cashback e Produtos exibem contagens e estados próprios; falha recente e parcial não viram zero nem contaminam outra fonte | Fixture de `/api/resumo` com estados distintos e teste de widget da moldura |

### Redesign — Módulo 5, hub do Shopping Inter

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-329 | Modalidades, atualizações e retornos isolados | O hub distingue Cashback — Sites parceiros de Produtos — Compre direto, preserva seus estados, consulta cada domínio administrativo e retorna de cada jornada ao Shopping Inter antes de Lojas | Fixture de `/api/resumo` e teste de widget da moldura navegando por ambas as modalidades |

### Redesign — Módulo 6, Produtos e histórico

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-330 | Link comercial seguro | Caminho relativo é reconstruído sob HTTPS de `shopping.inter.co`; URL, autoridade e navegação hostis não originam botão externo | Teste unitário do construtor de URI segura |
| CT-331 | Histórico resiliente | Falha ao carregar uma página adicional mantém medições e resumos já exibidos, oferecendo retry da mesma página | Teste de widget com falha injetada na segunda página |

### Migração mobile — Etapa 1, fundação visual e aparência

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-332 | Primeira execução acompanha o sistema | Sem escolha persistida, o app nativo compacto usa `ThemeMode.system` | Preferência falsa sem valor e inspeção do controlador |
| CT-333 | Aparência persiste localmente | Claro/escuro muda imediatamente e a escolha reaparece em outro controlador | Repositório de preferência em memória compartilhado |
| CT-334 | Persistência não bloqueia nem volta no tempo | Falha ao salvar mantém a escolha da sessão; leitura atrasada não sobrescreve toque mais recente | Exceção e `Completer` injetados no armazenamento |
| CT-335 | Escopo mobile preserva o Web | Android/iOS compacto aceita escuro; layout amplo continua claro e sem controle novo | Viewports 390 × 844 e 1440 × 900 com modo escuro injetado |
| CT-336 | Controle acessível de aparência | Cabeçalho e gaveta informam ação/estado e alternam sem reiniciar a sessão | Widget completo, chave, tooltip, semântica e controlador falso |
| CT-337 | Fundação funciona nos dois temas | Cabeçalho, cartão, estado, busca V11 com ação de avanço ou variante `search-only`, abas e folha usam tokens sem perder interação | Testes de widget parametrizados em claro/escuro |
| CT-338 | Folha e busca V11 são únicas | Filtros, seletores, detalhes e folhas de conta usam `FolhaRadar` com fundo desfocado, cabeçalho V11 e retorno preservado; todas as buscas usam `CampoBuscaRadar` | Testes de widget dos fluxos Livelo, Produtos, categorias e fundação |
| CT-338A | Paginação V11 de cartões | Produtos, Livelo, Sites parceiros e Compre direto solicitam 10 itens; com 9/10 não há paginação e com 11 há acesso à página 2 sem acumular cards | Widget da fundação, controladores e `MockClient` das telas afetadas |

Os testes foram escritos em `app/test/app/tema/aparencia_test.dart` e
`app/test/app/componentes/fundacao_visual_test.dart`. A execução e os totais da
fundação foram verificados junto com os casos do catálogo Android em 28 de
agosto de 2026.

### Catálogo Livelo completo — Android compacto

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-338 | Identidade e categorias Livelo | ID externo e categorias saem do payload; `todos` não vira categoria | Itens sintéticos e fixture real no extrator puro |
| CT-339 | Deduplicação e conflito | Repetição idêntica do ID entra uma vez; IDs distintos com o mesmo nome permanecem; conflito no mesmo ID falha | Variar ID, nome e conteúdo no payload |
| CT-340 | ID hostil invalida coleta | ID ausente, longo ou com caracteres de caminho não chega ao banco nem à URL da API | Payload hostil e `CatalogoLiveloInvalido` |
| CT-341 | Publicação atômica | Execução, catálogo, vínculos e pontuações usam uma transação e contagens exatas | Cursor fake com lotes e contadores |
| CT-342 | Rollback de publicação parcial | Divergência em catálogo, vínculos ou pontuações falha sem registrar sucesso | Injetar contagem parcial e observar exceção sair do contexto transacional |
| CT-343 | Zero acompanhadas | Catálogo completo é publicado mesmo quando `loja` está vazia; nenhuma pontuação é inventada | Caso de uso com catálogo fake vazio e repositório espião |
| CT-344 | Consulta e filtros da API | Busca, abas, categoria e ordenação respeitam ID, texto e decimais sem `number` | Vitest das funções puras e contrato de paginação |
| CT-345 | Categorias em português | Códigos conhecidos recebem rótulo; desconhecidos e ausência viram “Outros” | Tabela de entradas conhecida/hostil |
| CT-346 | Acompanhamento fechado | Corpo aceita somente `acompanhada: boolean`; nome, link e categoria do cliente são rejeitados | Validador TypeScript e PATCH inspecionado no Flutter |
| CT-347 | Modelo e API Flutter | IDs, categorias e `NUMERIC` permanecem textuais; GET e PATCH enviam somente parâmetros permitidos | Fixtures Dart e `MockClient` |
| CT-348 | Debounce e resposta antiga | Busca espera 350 ms e uma resposta descartada não substitui a consulta atual | `Completer`, fonte injetada e relógio de teste |
| CT-349 | Paginação por ID | Página adicional preserva cartões e deduplica somente por ID externo | Duas páginas com ID repetido |
| CT-350 | Mutação reversível | Duplo toque não repete PATCH; falha restaura cartão e resumo sem apagar filtros | `Completer` e falha injetada no controlador |
| CT-351 | Conteúdo Android real | Hero, métricas, abas, busca, categorias e cartões usam somente o payload da API | Widget com controlador injetado |
| CT-352 | Estados distintos | Loading, falha/retry, nunca sincronizado, busca vazia, zero acompanhadas, zero alertas e atraso não se confundem | Resumos e erros injetados |
| CT-353 | Tela estreita e texto ampliado | 320 × 640 com texto a 150% rola sem overflow | Viewport e `TextScaler` controlados |
| CT-355 | Escopo por plataforma | Somente Android compacto usa o catálogo novo; iOS, Web e layout amplo preservam a tela anterior | Override de plataforma e viewports compacta/ampla |
| CT-356 | Histórico Livelo por loja | Botão do card abre histórico somente leitura para acompanhada ou não acompanhada, com medições em ordem decrescente e estado vazio válido | Widget com API fake e resposta vazia |
| CT-357 | Contrato do histórico Livelo | Cliente chama o ID externo correto, mantém pontuação decimal como texto e não inicia coleta | Mock autenticado da rota `/api/livelo/catalogo/{id_externo}/historico` |
| CT-358 | Limite e identidade do histórico | API retorna no máximo 30 medições da loja solicitada e não mistura lojas ou parceiros | Banco fake com execuções repetidas, IDs distintos e ordenação por momento |
| CT-360 | Coleta completa Livelo | Cada execução grava pontuação para todos os parceiros válidos; alerta e limiar continuam exclusivos das acompanhadas | Retrato com parceira acompanhada, não acompanhada e ausente |
| CT-356 | Polling compacto seguro | Início consulta a API a cada 30 s só em primeiro plano e visível; retorno dispara leitura imediata e nunca sobrepõe chamadas | Relógio falso, ciclo de vida e `Completer` |
| CT-357 | Previsão e atraso Livelo | As três janelas de Brasília, virada do dia e primeira conclusão posterior distinguem previsão de atraso | Relógio UTC explícito no agregador TypeScript |
| CT-358 | Melhor acompanhada atual | Decimal textual, empate estável e zero acompanhadas não vazam o catálogo geral para o hero | Fixtures do catálogo autenticado |
| CT-359 | Atualização administrativa preservada | Aceite/cooldown regressivo, idempotência e nova coleta atualizam silenciosamente sem perder aba, busca, páginas ou rolagem | Widget/controlador com API falsa |

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

**Passo 2b — o site, no navegador de verdade:** além do que vem abaixo, o passeio sem teclado: partindo da página inicial, chegar a **todas** as telas e voltar usando só cliques. Se alguma exigir digitar URL, é defeito.

 abrir a página publicada **com JavaScript ligado** e confirmar que as lojas aparecem. Parece redundante depois do passo 3 do e-mail, mas não é: em 2026-08-11 a página serviu HTML perfeito e ficou em branco no navegador, porque a CSP recusou os scripts inline do Next e o React apagou o que o servidor tinha mandado. `curl` não pega essa classe de defeito — só o navegador.

**Passo 3 — o e-mail (a parte que só o olho pega):** abrir o último e-mail recebido e conferir que a validade aparece (`Válido até dd/mm` ou `Termina hoje!`), que o rótulo do Clube bate com o caso (`exclusivo assinantes Clube` só quando a base não se moveu), que os pontos não têm cauda de `float` (`2,9`, nunca `2,9000000000000004`) e que o Gmail não cortou o fim da mensagem com "[Mensagem truncada]" (C05).

**Passo 4 — registrar:** anotar a data e os números em `docs/PENDENCIAS.md`. Sem registro, a comparação do mês seguinte não tem contra o quê comparar.

---

## Totais

Até CT-199, a implementação acrescentou testes de apoio sem identificador (caminhos de descarte, validação do catálogo real, ordenação), por isso o número executado é maior que o catalogado. A V4 inicia a cobertura automatizada em `teste_produtos_inter.py`; os demais CT-200 a CT-244 continuam como roteiro de expansão e aceite real.

| Arquivo | Casos CT | Executados |
|---|---|---|
| `teste_categorias.py` | 8 | 12 |
| `teste_extrator.py` | 28 | 40 |
| `teste_adaptadores.py` | 22 | 29 |
| `teste_alertas.py` | 13 | 17 |
| `teste_retrato.py` | 5 | 5 |
| `teste_montador_email.py` | 31 | 33 |
| `teste_principal.py` | 27 | 29 |
| `teste_extrator_inter.py` | 9 | 10 |
| `teste_adaptadores_inter.py` | 2 | 4 |
| `teste_ranking_inter.py` | 1 | 1 |
| `teste_retrato_inter.py` | 1 | 1 |
| `teste_principal_inter.py` | 1 | 3 |
| `teste_produtos_inter.py` | 9 | 19 |
| `teste_fronteira.py` | 2 | 13 |
| **Total (robô)** | **159** | **177** |
| `site/testes/formato.teste.ts` | 11 | 23 |
| `site/testes/formato-inter.teste.ts` | 10 | 8 |
| `site/testes/formato-produtos-inter.teste.ts` | 2 | 2 |
| `site/testes/paginacao.teste.ts` | 0 | 5 |
| `site/testes/api.teste.ts` | 0 | 9 |
| `site/testes/limpeza.teste.ts` | 0 | 3 |
| `site/testes/autenticacao-api.teste.ts` | CT-248–CT-256 | 12 |
| `site/testes/firebase-admin.teste.ts` | regressão de carregamento tardio do App Check | 1 |
| `site/testes/banco-autenticacao.teste.ts` | CT-260 | 1 |
| `site/testes/resumo-inicio.teste.ts` | CT-319–CT-321 | 5 |
| **Total (site)** | **CTs catalogados + apoio** | **83** |
| `app/test/` | CT-257–CT-259, CT-261–CT-355 + fundação | 178 confirmados nesta entrega |
| **Total (Flutter)** | **CTs catalogados + apoio** | **178** |

`teste_extrator.py` conta 28 CTs: CT-015, CT-016 e CT-019 (V1) foram aposentados na V2.0, não substituídos por outro número; CT-106, CT-107, CT-166 e CT-167 entraram depois.

Manuais: CT-050 e CT-051.

Confirme o número real com o coletor de cada suíte antes de citá-lo em qualquer
documento (`pytest --collect-only -q` no robô e `flutter test` no app) — foi
assim que o total errado de "47 casos" sobreviveu ao planejamento original.
