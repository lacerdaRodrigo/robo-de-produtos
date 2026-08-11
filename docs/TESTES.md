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

## `testes/teste_extrator.py` — núcleo puro: HTML → `Parceiro` (fixture de HTML, **nunca** rede)

| ID | Título | Descrição | Como fazer |
|---|---|---|---|
| CT-010 | Loja sem promoção | HTML sem a tag "Promoção" deve marcar `em_promocao=False` | Fixture simulando isso, rodar extração |
| CT-011 | Loja em promoção com "Eram X pontos" | `pontos_atuais`, `pontos_anteriores` e `em_promocao=True` devem sair corretos | Fixture com o padrão completo, validar os 3 campos |
| CT-012 | Tier Clube Livelo | Valor extra pra assinante deve preencher `pontos_clube` | Fixture com bloco "Clube X pontos", checar campo |
| CT-013 | Prefixo "Até X pontos" | Extrair o número corretamente, ignorando "Até" | Fixture com esse padrão, validar valor numérico |
| CT-014 | Moeda em dólar | Parceiros de viagem usam "U$" em vez de "R$" | Fixture tipo Booking/Decolar, checar `moeda == "U$"` |
| CT-015 | Nome via atributo `alt` da imagem | `alt="Logo Casas Bahia"` deve virar `"Casas Bahia"` | Fixture com essa tag, checar nome limpo |
| CT-016 | Sem atributo `alt` (fallback) | Sem quebrar mesmo se a imagem não tiver `alt` | Fixture sem `alt`, checar ausência de exceção |
| CT-017 | Parceiro duplicado | A página às vezes repete o mesmo link — resultado final não pode duplicar | Fixture com parceiro 2x, checar resultado único |
| CT-018 | Página sem parceiros | HTML fora do padrão deve retornar lista vazia, não erro | HTML sem links de parceiro, checar `len() == 0` |
| CT-019 | Link que não é de parceiro | Links de menu/rodapé não podem ser capturados como loja | Fixture com link genérico misturado, checar ausência |
| CT-020 | Nome com caracteres especiais | "Sam's Club", "O.U.i Paris" não podem quebrar o regex | Fixture com esses nomes, checar extração correta |

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
| `teste_extrator.py` | 11 | 16 |
| `teste_adaptadores.py` | 7 | 9 |
| `teste_montador_email.py` | 14 | 17 |
| `teste_principal.py` | 12 | 13 |
| `teste_fronteira.py` | 1 | 5 |
| **Total** | **53** | **72** |

Manuais: CT-050 e CT-051.

Confirme o número real com `pytest --collect-only -q` antes de citá-lo em qualquer documento — foi assim que o total errado de "47 casos" sobreviveu ao planejamento original.
