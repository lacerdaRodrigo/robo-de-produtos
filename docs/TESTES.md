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
| CT-091 | `separatorSlug: "ATE"` (RN12) ⚠️ **hipótese não confirmada** | Sem exemplo real ainda — só `"IGUAL"` foi visto em produção. Implementado e testado, mas precisa validação quando aparecer um caso real | Item com esse `separatorSlug`, checar `prefixo_ate=True` |
| CT-092 | Moeda preservada (RN11) | Nunca converte, exibe como veio | Item com `currency: "U$"` |
| CT-093 | `parityClub == parity` não popula `pontos_clube` | Evita ruído de "Clube: N pontos" repetido em toda loja sem distinção real | Item com os dois valores iguais |
| CT-094 | `parityClub` distinto popula `pontos_clube` | Contraprova de CT-093 | Item com os dois valores diferentes |
| CT-095 | Integração com o payload real recortado | A fixture é o payload de verdade (capturado ao vivo em 2026-08), não inventado | `testes/fixtures/payload_parceiros.json`, checar nomes e os casos difíceis (RN21, RN22 candidato, RN23, dado malformado) |

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

## `testes/teste_fronteira.py` — arquitetura (PRD §9.3)

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-074 | Núcleo puro não importa dependência externa ⚠️ | A estrutura é plana, então a fronteira núcleo/adaptador só existe se for testada | Varrer os imports de `extrator.py`, `categorias.py` e `montador_email.py`, falhar se aparecer `requests`, `bs4` ou `smtplib` |

---

## Fora dos testes automáticos

| ID | Título | Descrição |
|---|---|---|
| CT-050 | Smoke test manual periódico | De vez em quando, rodar o robô contra o site real pra confirmar que a Livelo não mudou a estrutura. Manual, não entra no `pytest` — é uma checagem de sanidade quando algo parecer estranho no e-mail. |
| CT-051 | Falha injetada uma vez | PRD MS3 — forçar uma falha proposital na V1 e confirmar que a notificação do GitHub chega. Feito uma vez, não repetido. |

---

## Totais

Os casos com identificador CT são os planejados. A implementação acrescentou testes de apoio sem identificador (caminhos de descarte, validação do catálogo real, ordenação), por isso o número executado é maior que o catalogado.

| Arquivo | Casos CT | Executados |
|---|---|---|
| `teste_categorias.py` | 8 | 12 |
| `teste_extrator.py` | 24 | 32 |
| `teste_adaptadores.py` | 7 | 9 |
| `teste_montador_email.py` | 20 | 23 |
| `teste_principal.py` | 13 | 15 |
| `teste_fronteira.py` | 1 | 5 |
| **Total** | **73** | **96** |

`teste_extrator.py` conta 24, não 27: CT-015, CT-016 e CT-019 (V1) foram aposentados na V2.0, não substituídos por outro número.

Manuais: CT-050 e CT-051.

Confirme o número real com `pytest --collect-only -q` antes de citá-lo em qualquer documento — foi assim que o total errado de "47 casos" sobreviveu ao planejamento original.
