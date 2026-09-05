# PRD — Inter Produtos (Compre direto)

**Versão:** V4.5.1 em aceite progressivo
**Status vigente em 2026-09-04:** schema, coletor, API autenticada e Flutter implementados. A carga de referência da Casas Bahia publicou 3.310 produtos. O estado de aplicação de migrations no Neon exige confirmação operacional; as categorias externas são regidas pelo `PRD-CATEGORIAS-INTER-FONTE-OFICIAL.md`.
**Levantamento da fonte:** 16 e 17 de agosto de 2026

> A V4 acrescenta uma terceira integração ao Radar de Benefícios: produtos vendidos na área **Compre direto no Inter**. Ela não substitui a Livelo nem o cashback de **Sites parceiros** da V3. Cada fonte continua com domínio, coleta, persistência e páginas próprios.

Este documento é o **delta sobre o [`PRD-LIVELO.md`](PRD-LIVELO.md), o [`PRD-LIVELO-V2.md`](PRD-LIVELO-V2.md) e o [`PRD-INTER-CASHBACK.md`](PRD-INTER-CASHBACK.md)**. Tudo que não for redefinido aqui continua valendo. “V4” é a versão de produto deste documento; o antigo nome “V4.6” do mockup de navegação é apenas um rótulo visual histórico e não tem relação com esta entrega.

---

## 1. Contexto

A Livelo responde “quantos pontos por real esta loja oferece?” e a V3 responde “qual é o cashback desta loja nos Sites parceiros?”. Falta responder uma pergunta de compra concreta:

> “Em quais das lojas que escolhi existe este produto, por qual preço e com qual cashback?”

A página pública `https://shopping.inter.co/lojas-shopping` é a área **Compre direto no Inter**. Ela contém vendedores e produtos compráveis dentro do Shopping Inter. É uma fonte diferente de `https://shopping.inter.co/site-parceiro/lojas`, usada pela V3.

O caso que orienta a V4 é:

1. A pessoa escolhe Casas Bahia e Ponto.
2. O robô coleta o catálogo completo exposto dessas duas lojas e ignora todas as outras.
3. A pessoa procura “celular Motorola Edge 60 Pro” no Radar de Benefícios.
4. O Flutter consulta somente a API e mostra resultados do banco local das lojas escolhidas.
5. Cada resultado informa preço cheio, desconto, preço atual, cashback e preço líquido estimado.

Depois da coleta, a mesma base também responde por geladeira, televisão ou qualquer outro item já presente no catálogo. Não existe cadastro prévio de termos de busca.

### 1.1 Evidência levantada na fonte real

A página pública de lojas diretas é:

`https://shopping.inter.co/lojas-shopping`

A página pública da Casas Bahia é:

`https://shopping.inter.co/lojas-shopping/casas-bahia`

O frontend usa estas operações públicas, sem autenticação:

```text
GET  https://marketplace-api.web.bancointer.com.br/site/affiliate/inter/v1/ecommerce/sellers?lang=pt-BR
POST https://marketplace-api.web.bancointer.com.br/site/affiliate/inter/v1/ecommerce/products/search
```

A requisição de catálogo replica somente o contrato de dados observado, com ordenação estável:

```json
{
  "aggregate": true,
  "slug": "casas-bahia",
  "searchText": "",
  "sort": "NAME_ASCENDENT",
  "pagination": {"offset": 0, "limit": 36},
  "featureFilters": [],
  "searchId": "uuid-da-tentativa-da-loja"
}
```

O próximo offset usa o limite efetivamente devolvido pela fonte, não presume que ela respeitou o valor pedido.

O GET de vendedores responde com a lista sob a chave `sellers`. Produtos usam caminhos relativos sem barra inicial e podem acrescentar somente a variante segura `?v=<ID numérico>`. Etiquetas chegam como objetos com campo `text`; marca, categoria e estoque podem estar no primeiro item de `skus`.

Na medição de 2026-08-16:

- o catálogo direto retornou 111 vendedores;
- Ponto apareceu com `id = interponto`, nome `Ponto` e `slug = ponto`;
- Casas Bahia usa `slug = casas-bahia`;
- Casas Bahia e Ponto declararam `pagination.total = 3000` numa busca vazia;
- com páginas de 36 itens, cada uma exigia 84 páginas para chegar ao fim declarado;
- a busca por Motorola Edge 60 Pro encontrou ofertas nas duas lojas;
- a listagem forneceu ID, nome, vendedor, preço cheio, preço atual, desconto, cashback, preço líquido, parcelamento, estoque, etiquetas e caminho individual;
- o mesmo produto pode reaparecer em páginas diferentes, portanto deduplicação por ID é requisito, não otimização;
- a API respondeu com o User-Agent honesto do projeto e um `searchId` UUID, sem cookie, token ou cabeçalhos que fingissem navegação humana.

Os números e preços são voláteis. “3.000” é uma medição e pode ser um teto de consulta da fonte; não é promessa de que toda loja tenha exatamente 3.000 produtos. A V4 coleta todas as páginas que a fonte disponibilizar até `isLastPage = true`. Se a fonte expuser 5.000 itens, os 5.000 entram; se encerrar em 3.000, o sistema não afirma conhecer itens além disso.

No aceite de 2026-08-17, a janela vazia da Casas Bahia terminou em 84 páginas e 3.024 itens, alfabeticamente entre A e M, sem incluir “Smartphone”. A partição fixa `smartphone` declarou 339 itens em 10 páginas. A união publicou 3.310 IDs únicos, contou 53 sobreposições e trouxe o Edge 60 Pro. Com pausa de 0,5 s houve HTTP 429 recuperado por retry; com 1,5 s a rodada final terminou sem limitação em 199,1 s.

### 1.2 Relação com as integrações existentes

| Livelo | Inter — Sites parceiros (V3) | Inter — Compre direto (V4) |
|---|---|---|
| Loja dá pontos por real | Loja dá cashback e redireciona para parceiro | Produto tem preço, desconto e cashback |
| Uma página lógica por rodada | Uma resposta com todas as lojas | Muitas páginas por loja selecionada |
| Favoritas por nome/apelido | Favoritas por ID externo | Lojas selecionadas por ID; produtos por loja + ID |
| Cliente | Flutter autenticado | Busca e histórico no Flutter autenticado |
| Sem histórico decisório | Snapshot de favoritas | Catálogo atual + histórico de 30 dias |

Compartilhar infraestrutura genérica é permitido. Reutilizar `LojaInter`, `RetratoInter` ou tabelas da V3 para representar produtos é proibido: a semântica e o volume são diferentes.

---

## 2. Objetivos novos

| ID | Objetivo |
|---|---|
| **O12** | Permitir pesquisar produtos em um catálogo local, sem consultar o Inter durante o uso do aplicativo |
| **O13** | Coletar somente as lojas diretas escolhidas pela pessoa, independentemente de quantas existam na fonte |
| **O14** | Mostrar preço cheio, desconto, preço atual, cashback e preço líquido da mesma coleta |
| **O15** | Manter 30 dias de histórico para todos os produtos das lojas selecionadas |
| **O16** | Adicionar a coleta paginada sem colocar Livelo ou V3 em risco |

---

## 3. Escopo

### 3.1 Dentro

- Sincronizar o catálogo público de vendedores da área Compre direto no Inter.
- Selecionar e remover lojas sob a sessão administrativa existente.
- Coletar todas as páginas disponibilizadas para cada loja selecionada.
- Rodar três vezes ao dia, às 09h, 14h e 20h de Brasília.
- Criar tarefas independentes por loja, com no máximo duas simultâneas.
- Persistir catálogo atual e 30 dias de medições.
- Fazer busca local por nome de produto, limitada às lojas selecionadas.
- Exibir os campos comerciais disponíveis na listagem.
- Abrir o produto no domínio `shopping.inter.co` somente por ação da pessoa.
- Mostrar estado e horário de atualização por loja.
- Permitir disparo manual com cooldown próprio.

### 3.2 Fora

- Coletar produtos de lojas não selecionadas.
- Abrir automaticamente a página individual de cada produto.
- Coletar descrição completa, ficha técnica, avaliações, frete ou todas as variações/SKUs.
- Baixar, armazenar ou exibir imagens de produtos e lojas.
- Autenticar no Inter, montar carrinho, comprar ou calcular entrega por CEP.
- Unificar automaticamente produtos entre lojas por texto, GTIN ou EAN.
- Garantir que catálogos encerrados pela fonte em 3.000 itens estejam completos fora desse limite.
- Definir neste documento o esquema físico final ou contratar infraestrutura de banco.

### 3.3 O que este documento altera

| Decisão anterior | Situação na V4 |
|---|---|
| Cada fonte faz uma consulta lógica pequena por rodada | Continua na Livelo e na V3. A V4 é paginada por natureza e ganha orçamento, ritmo e isolamento próprios |
| RNF18: nenhuma requisição por loja na V3 | Continua na V3; não se aplica ao catálogo de produtos da V4 |
| RN25/RNF24: nenhum recurso visual de terceiro | Continua valendo; imagens retornadas pela V4 são ignoradas |
| Nenhum histórico entre execuções | Continua para a decisão de alerta da Livelo. A V4 guarda histórico apenas para consulta humana |
| `/inter` representa cashback de Sites parceiros | Continua igual; produtos entram em rotas filhas próprias |

Nenhuma rota, tabela, regra ou workflow existente é removido.

---

## 4. Métricas

| ID | Métrica | Alvo | Fonte |
|---|---|---|---|
| **MS14** | Cobertura por loja | Atingir `isLastPage = true` em 100% das lojas publicadas como sucesso | Log e execução por loja |
| **MS15** | Seleção respeitada | Zero consulta de produtos para loja não selecionada | Teste de orquestração |
| **MS16** | Consistência comercial | 100% dos campos de um card vêm da mesma medição | Fixture e teste de persistência |
| **MS17** | Busca do caso principal | “celular Motorola Edge 60 Pro” encontra Edge 60 Pro e rejeita Moto G | Teste de busca local |
| **MS18** | Frescor | Cada loja mostra atraso quando o último sucesso passa de 12 horas | Aplicativo |
| **MS19** | Retenção | Nenhuma medição com mais de 30 dias permanece após limpeza bem-sucedida | Consulta de manutenção |
| **MS20** | Isolamento | Falha de uma loja ou da V4 não interrompe outras lojas, Livelo ou V3 | Workflows e regressão |

---

## 5. Requisitos novos

### 5.1 Funcionais

| ID | Requisito |
|---|---|
| **RF34** | Obter e validar o catálogo de vendedores diretos do endpoint público do Shopping Inter |
| **RF35** | Permitir selecionar e remover vendedores por ID externo e slug sob autenticação |
| **RF36** | Criar uma coleta independente para cada loja selecionada em cada rodada |
| **RF37** | Paginar os produtos de uma loja até `isLastPage = true`, sem teto fixo de 3.000 itens |
| **RF38** | Gerar um UUID `searchId` por loja e mantê-lo em todas as páginas daquela coleta |
| **RF39** | Deduplicar produtos pelo ID externo dentro da mesma loja |
| **RF40** | Preservar nome, marca, categoria, preços, desconto, cashback, líquido, parcelamento, estoque, etiquetas e caminho do produto |
| **RF41** | Publicar o catálogo de uma loja somente após a conclusão válida de todas as páginas |
| **RF42** | Preservar o último catálogo válido da loja quando uma tentativa falhar |
| **RF43** | Pesquisar somente no banco e somente sobre lojas atualmente selecionadas |
| **RF44** | Mostrar resultados agrupados por loja e ordenados por menor preço atual |
| **RF45** | Guardar três medições diárias por produto e reter somente os últimos 30 dias |
| **RF46** | Exibir preço atual, mínimo, máximo e tabela cronológica do produto naquela loja |
| **RF47** | Registrar por loja total declarado, páginas, itens lidos, únicos, duplicados, duração e estado |
| **RF48** | Executar em workflow próprio nos três horários e por disparo manual com cooldown |
| **RF49** | Exibir catálogo anterior, falha recente, loja sem sucesso e dado atrasado como estados distintos |

### 5.2 Não-funcionais

| ID | Requisito | Alvo verificável |
|---|---|---|
| **RNF28** | Núcleo puro | Extração, deduplicação, normalização e montagem de snapshots não fazem I/O |
| **RNF29** | Precisão monetária | Python usa `Decimal`; Postgres usará `NUMERIC`; TypeScript mantém string até apresentação |
| **RNF30** | Pressão controlada | Páginas de uma loja são sequenciais e no máximo duas lojas são coletadas ao mesmo tempo |
| **RNF31** | Sem limite funcional de lojas | A interface não impõe máximo; o workflow distribui tarefas por loja selecionada |
| **RNF32** | Atomicidade por loja | Catálogo incompleto nunca substitui o último sucesso daquela loja |
| **RNF33** | Conteúdo hostil | Nome, marca, categoria e etiquetas são texto, nunca HTML executável |
| **RNF34** | Observabilidade | Log traz contagens e código controlado, sem payload completo nem dados sensíveis |
| **RNF35** | Compatibilidade | Busca, filtros, seleção e histórico funcionam sem JavaScript |
| **RNF36** | Recursos externos | Nenhuma imagem, fonte, script ou pixel de produto é carregado do Inter |
| **RNF37** | Isolamento | Módulos, processo, tabelas e workflow da V4 são independentes dos anteriores |
| **RNF38** | Regressão zero | Suítes de Livelo e V3 passam sem configuração ou dados da V4 |

### 5.3 Restrições novas

| ID | Restrição | Impacto |
|---|---|---|
| **C17** | A API é consumida por página pública, mas não possui contrato público estável identificado | Adaptador isolado, fixture e falha ruidosa |
| **C18** | A coleta é paginada e pode envolver dezenas de respostas por loja | Workflow e transação precisam ser por loja |
| **C19** | `pagination.total = 3000` pode ser teto da fonte | O sistema promete “tudo que a fonte expôs”, nunca catálogo universal da loja |
| **C20** | Produtos podem se repetir entre páginas | Contagens bruta e única são separadas; ID externo deduplica |
| **C21** | Preço, estoque e cashback mudam durante uma coleta longa | Cada loja exibe o momento da própria conclusão; não existe snapshot global simultâneo |
| **C22** | Quantidade de lojas selecionadas não tem teto funcional | Duração total cresce; tarefas isoladas e concorrência baixa evitam corrida descontrolada |
| **C23** | Produto equivalente pode ter IDs e nomes diferentes entre lojas | V4 não afirma equivalência automática |
| **C24** | A listagem não contém descrição e ficha técnica completas | Esses campos ficam fora em vez de gerar uma requisição por produto |
| **C25** | Histórico de milhares de produtos cresce rapidamente | Dimensionamento e schema são gate antes do código de persistência |

---

## 6. Regras de negócio novas

| ID | Regra |
|---|---|
| **RN53** | O catálogo de produtos só é consultado para lojas com seleção ativa no início da rodada |
| **RN54** | Seleção usa ID externo como identidade principal e slug como identidade secundária; nome serve para exibição e busca |
| **RN55** | Não existe limite funcional para a quantidade de lojas selecionadas |
| **RN56** | Uma tarefa recebe exatamente uma loja; sucesso ou falha dessa tarefa não altera o resultado das demais |
| **RN57** | O `searchId` é novo por tentativa de loja e permanece igual em todas as suas páginas |
| **RN58** | Cada página registra o total declarado; offsets avançam pelo limite retornado até `isLastPage`, mesmo quando esse total varia durante a tentativa |
| **RN59** | Não existe teto fixo de produtos. A coleta termina pela sinalização da fonte; offset, repetição ou margem de páginas incoerentes continuam sendo falhas estruturais |
| **RN60** | Offset sem avanço, fingerprint de página repetido ou páginas além da margem derivada do total declarado encerram a tentativa como falha de paginação |
| **RN61** | Produto repetido na mesma loja conta uma vez, pelo ID externo; valores da primeira ocorrência válida são preservados e a duplicata é contabilizada |
| **RN62** | IDs iguais em lojas diferentes são produtos distintos |
| **RN63** | Somente uma tentativa que alcançou `isLastPage` pode publicar. Até lá, dados ficam invisíveis em área de preparação |
| **RN64** | Falha preserva o último sucesso da loja e registra código controlado |
| **RN65** | Produto ausente de um novo catálogo completo fica inativo; não é apresentado com preço antigo como se estivesse disponível |
| **RN66** | Remover uma loja da seleção interrompe novas coletas e esconde seus produtos da busca pública; histórico expira normalmente em 30 dias |
| **RN67** | Busca ignora acento, caixa e pontuação; remove artigos/preposições comuns e exige todos os demais termos em qualquer ordem |
| **RN68** | “celular” e “smartphone” normalizam para o mesmo termo canônico; outros sinônimos exigem decisão documentada antes de entrar |
| **RN69** | “Ponto”, “Ponto Frio” e “Pontofrio” ajudam a localizar a loja direta `slug = ponto`, mas o vínculo final continua sendo pelo ID |
| **RN70** | Resultado público só vem do último catálogo válido das lojas atualmente selecionadas |
| **RN71** | Resultados são agrupados por loja e ordenados por preço atual crescente; empate resolve por nome e ID |
| **RN72** | Preço cheio, desconto, preço atual, cashback e líquido de um card pertencem à mesma medição |
| **RN73** | Preço líquido é rotulado “após cashback” e nunca apresentado como preço garantido de cobrança |
| **RN74** | Todo valor textual da fonte é preservado como texto; números existem para cálculo, ordem e histórico |
| **RN75** | Caminho clicável precisa ser relativo e resultar em HTTPS sob `shopping.inter.co`; qualquer outro destino é descartado |
| **RN76** | Imagens e thumbnails são ignoradas pelo domínio e pela persistência |
| **RN77** | Cada sucesso acrescenta uma medição para cada produto ativo da loja, mesmo que o valor não tenha mudado |
| **RN78** | Histórico é identificado por loja + produto externo e retido por 30 dias corridos |
| **RN79** | Limpeza de histórico só ocorre após operação bem-sucedida e nunca apaga o catálogo atual |
| **RN80** | O aplicativo mostra horário e estado por loja; não combina horários diferentes num carimbo global enganoso |
| **RN82** | HTTP 401/403 não recebe retry; timeout, 429 e 5xx respeitam no máximo três tentativas e o intervalo definido pelo adaptador |
| **RN83** | Se a fonte bloquear o acesso ou pedir interrupção, workflow e rotas da V4 são desativados; Livelo e V3 permanecem ativos |
| **RN84** | Quando a janela vazia truncar uma família necessária ao aceite, o coletor pode unir partições suplementares fixas e versionadas. O aplicativo nunca envia termos arbitrários à fonte; cada partição pagina integralmente e a união deduplica por ID |
| **RN85** | Total declarado variável gera até três tentativas completas por partição. Uma tentativa com total estável vence imediatamente; sem estabilidade, vence a candidata com mais produtos únicos válidos, depois mais itens lidos e, por fim, a mais recente |
| **RN86** | A melhor tentativa instável é publicada com qualidade `degradada`: atualiza produtos encontrados e medições, mas não inativa ausentes. Somente qualidade `completa` confirma desaparecimentos |

### 6.1 Campos da listagem

| Campo observado | Uso na V4 |
|---|---|
| `id` | Identidade do produto dentro da loja |
| `name` | Nome pesquisável e exibido |
| `sellerId`, `sellerName` | Conferência de pertencimento à loja consultada |
| `brand`, `categoryName` | Informação e busca auxiliar; podem vir do primeiro `sku` |
| `listPriceValue`, `listPrice` | Preço cheio numérico e texto da fonte |
| `priceValue`, `price` | Preço atual numérico e texto da fonte |
| `discountPriceValue`, `discountPrice` | Desconto absoluto |
| `discountPercentageValue`, `discountPercentage` | Desconto percentual |
| `fullCashbackValue`, `fullCashback` | Cashback em reais |
| `fullCashbackPercentageValue`, `fullCashbackPercentage` | Cashback percentual |
| `fullLiquidPriceValue`, `fullLiquidPrice` | Estimativa após cashback |
| `fullInstallmentsDescription` | Parcelamento publicado |
| `stock` | Estoque informado no primeiro `sku`, sem promessa de reserva |
| `tags` | Objetos editoriais; somente o campo `text` é preservado |
| `slug` | Caminho relativo, com variante numérica opcional, sujeito a RN75 |
| `image`, `images`, `thumbnails` | Ignorados por RN76 |
| `skus` | Somente o primeiro fornece marca, categoria e estoque; imagens e links são ignorados |

Texto e número são preservados separadamente. O texto mantém “Até”, moeda e forma editorial; o número permite ordenação e histórico sem passar por `float`.

### 6.2 Busca local

A caixa de busca nunca chama o Inter. Ela consulta somente o último catálogo válido das lojas selecionadas.

Normalização do caso principal:

```text
entrada:  "celular Motorola Edge 60 Pro"
tokens:   [smartphone, motorola, edge, 60, pro]
produto:  "Smartphone Motorola Edge 60 Pro 5G ..."
resultado: corresponde
```

“Smartphone Motorola Moto G06” não contém `edge`, `60` e `pro`, portanto é rejeitado mesmo que a busca ampla do Inter o considere relevante.

A V4 não mescla automaticamente Edge 60 Pro de 256 GB com 512 GB. Cada card mantém nome, ID e loja próprios; o olho da pessoa decide se as variantes são comparáveis.

### 6.3 Catálogo completo significa catálogo exposto

O sistema percorre todas as páginas disponibilizadas até `isLastPage` em cada partição. Ele não fixa 3.000, não para após a primeira categoria e não coleta somente destaques.

Isso não autoriza afirmar que o Radar conhece todos os produtos reais da varejista. A janela-base e a partição fixa `smartphone` representam o catálogo exposto nessas consultas. Novas partições exigem evidência real, termo versionado e revisão de volume; nunca nascem da caixa de busca do usuário.

### 6.4 Histórico

Cada sucesso da loja grava uma medição de todos os seus produtos ativos. Com três rodadas diárias, um produto continuamente disponível pode ter até aproximadamente 90 medições em 30 dias.

O histórico responde:

- preço atual;
- menor preço atual observado em 30 dias;
- maior preço atual observado em 30 dias;
- cashback de cada medição;
- quando o produto deixou de aparecer.

Não responde “melhor preço do mercado”, porque cobre somente as lojas selecionadas e somente o catálogo que o Inter expôs.

---

## 7. Arquitetura

### 7.1 Princípio

A V4 usa a mesma arquitetura hexagonal do projeto, mas com domínio próprio:

```text
workflow coordenador
        │
        ├── catálogo de lojas diretas ──→ seleção administrativa
        │
        └── matriz das lojas selecionadas (máximo 2 simultâneas)
                 │
                 └── coletor de uma loja
                        ├── páginas públicas sequenciais
                        ├── extrator e deduplicador puros
                        ├── publicação atômica do catálogo
                        └── histórico de 30 dias

site ──→ Postgres ──→ busca e histórico
```

O site nunca chama a API do Inter. O coletor nunca importa componentes do site. Livelo, V3 e V4 não chamam os pontos de entrada uns dos outros.

### 7.2 Fluxo por rodada

1. O coordenador valida `DATABASE_URL` antes da rede.
2. Sincroniza o catálogo de vendedores diretos em uma consulta.
3. Lê do banco os IDs/slugs das lojas selecionadas.
4. Produz uma matriz de tarefas, uma por loja.
5. O workflow executa no máximo duas tarefas ao mesmo tempo.
6. Cada tarefa gera um `searchId` por tentativa de partição e registra os totais declarados por página.
7. Avança offsets sequencialmente até `isLastPage`, primeiro na janela-base e depois nas partições fixas.
8. Valida itens, vendedor, decimais, links e paginação; total variável guarda a candidata e inicia outra tentativa, até três.
9. Uma candidata estável vence imediatamente; sem estabilidade, vence a tentativa completa com mais produtos únicos válidos.
10. Deduplica por ID e monta o catálogo escolhido em área invisível.
11. Em transação, publica produtos e medições; somente catálogo completo marca ausentes como inativos.
12. Registra qualidade, tentativas, intervalo dos totais e limpa medições com mais de 30 dias.
13. O coordenador resume sucessos e falhas; qualquer falha torna a rodada geral `parcial` ou `falha` e o workflow sai diferente de zero depois de preservar os sucessos.

### 7.3 Portas conceituais

```text
FonteDeLojasDiretas.listar() -> catálogo de vendedores
FonteDeProdutos.pagina(slug, search_id, offset, limite, busca_fixa) -> página de produtos
CatalogoDeLojasDiretas.listar_selecionadas() -> lojas
RepositorioDeProdutos.iniciar_loja(...) -> execução
RepositorioDeProdutos.publicar_loja(...) -> catálogo + medições
RepositorioDeProdutos.falhar_loja(...) -> estado controlado
```

As assinaturas definitivas e o esquema físico serão fechados no gate de persistência. O contrato comportamental deste documento não depende dos nomes finais.

### 7.4 Workflow e escala

O workflow `produtos-inter.yml` é exclusivo da V4. Um job coordenador gera JSON para uma matriz dinâmica. O job por loja usa `max-parallel: 2`, `permissions: contents: read`, timeout de 30 minutos e pausa de 1,5 s entre páginas.

Não há limite de lojas na interface. Selecionar dez lojas cria dez tarefas; selecionar três cria três. Concorrência baixa controla pressão sobre a fonte sem serializar todas num único processo sujeito ao timeout global.

O disparo manual usa o token existente somente para iniciar o workflow. Ele não recebe slug ou URL arbitrária do navegador: as lojas sempre são relidas do banco, impedindo transformar a action num proxy aberto.

---

## 8. Modelo de domínio e persistência

### 8.1 Estruturas conceituais

```text
LojaDiretaInter
  id_externo, slug, nome, selecionada, ativa

ProdutoDiretoInter
  loja_id, id_externo, nome, marca, categoria, caminho

OfertaProdutoInter
  momento, preços, desconto, cashback, líquido,
  parcelamento, estoque, etiquetas

PaginaProdutosInter
  offset, limite, total, ultima, produtos

ExecucaoLojaProdutos
  loja, início, conclusão, estado,
  qualidade, tentativas, total_declarado, intervalo dos totais,
  páginas, lidos, únicos, duplicados, código_falha
```

Objetos monetários usam `Decimal`. Coleções publicadas são imutáveis. Conteúdo externo nunca transporta HTML confiável.

### 8.2 Decisões já fechadas

- Identidade de loja: ID externo, com slug único como segunda garantia.
- Identidade de produto: loja interna + ID externo.
- Snapshot atual separado das medições históricas.
- Publicação atômica por loja.
- Histórico de 30 dias de todos os produtos das lojas selecionadas.
- Loja desmarcada não perde imediatamente seu histórico.
- Produto ausente fica inativo e não aparece como oferta atual.
- Execução geral e execução por loja são estados diferentes.

### 8.3 Decisões físicas adiadas

Antes de criar a migração da V4, uma etapa própria deve fechar:

- nomes e índices das tabelas;
- estratégia de área de preparação e troca atômica;
- se medições idênticas serão armazenadas integralmente ou compactadas sem mudar a semântica de três observações diárias;
- volume estimado para 3, 10 e 111 lojas;
- custo e limites reais do Neon;
- plano de migração, rollback e retenção;
- paginação da busca local e do histórico.

Nenhum código de persistência deve começar enquanto esse gate estiver aberto. “Não se preocupar com o banco agora” significa adiar o desenho físico, não apagar os requisitos de atomicidade e histórico.

---

## 9. Interface

### 9.1 Navegação planejada

| Rota | Acesso | Responsabilidade |
|---|---|---|
| `/inter` | Público | Cashback de Sites parceiros da V3, sem mudança |
| `/inter/produtos` | Público | Busca no catálogo atual das lojas diretas selecionadas |
| `/inter/produtos/lojas` | Sessão | Selecionar lojas, ver estado e forçar atualização |
| `/inter/produtos/historico/[loja]/[produto]` | Público | Resumo e tabela de 30 dias do produto naquela loja |

### 9.2 Busca de produtos e filtros no Flutter

A página inicia pela busca local; não despeja milhares de produtos sem consulta. No mobile V11, a área de Produtos não repete a administração da coleta: não há cartão de origem com botão “Escolher lojas” nem chip “+ escolher lojas”. Alterar quais vendedores o robô coleta continua sendo uma operação administrativa própria, fora da busca de ofertas.

O botão `Filtros` abre uma única folha de seleção. Os filtros de catálogo não aceitam texto livre: a pessoa escolhe uma opção já conhecida pelo sistema. Isso impede que uma marca digitada, uma categoria aproximada ou um slug copiado crie uma consulta ambígua ou não verificável.

#### Lojas

- Para conta administrativa, o aplicativo percorre todas as páginas de `GET /api/inter/produtos/lojas?filtro=acompanhadas`, e mostra somente os registros com `selecionada=true`.
- O rótulo informa a quantidade efetiva disponível para coleta — uma loja produz “1 para coleta”; seis produzem “6 para coleta”. Não existe teto visual imposto pelo aplicativo.
- A escolha contém “Todas as lojas” e uma opção por nome de loja. Ao escolher uma loja, o aplicativo envia somente seu `slug` já retornado pela API no parâmetro `loja`; nunca pede que a pessoa digite slug, ID, URL ou nome.
- Lojas não selecionadas para coleta não aparecem como opção e não podem ser incluídas por este filtro. O filtro reduz a visualização do catálogo local; ele não altera seleção, não aciona o robô e não consulta o Inter.
- A rota que enumera a seleção de coleta é administrativa. Em uma conta sem essa autorização, o aplicativo não tenta contornar a regra por outra fonte e mantém os filtros que seu contrato de leitura permite.

#### Categoria e preços

- Categoria permanece no controle separado “Categoria nesta tela”, fora da folha `Filtros`. Esse controle consulta `GET /api/inter/produtos/categorias` e escolhe um valor externo real, “Todas as categorias” ou “Sem categoria” quando disponível; nunca há categoria digitada, aproximada ou inventada.
- A folha `Filtros` não carrega nem lista categorias. Ela se mantém em meia tela e contém somente a seleção de Lojas e a faixa de preço.
- Marca deixa de ser filtro exposto na interface. O dado de marca pode continuar aparecendo no card quando fornecido pela origem, mas não há campo “Marca” para digitação.
- Preço mínimo e preço máximo são os únicos campos editáveis da folha, porque representam uma faixa numérica escolhida pela pessoa. O texto aceita vírgula decimal brasileira e segue para a validação já existente da API; dinheiro não é recalculado com `double` no Flutter.
- Aplicar a folha preserva a categoria já escolhida no controle próprio, reinicia somente a paginação da busca local e preserva o termo. Enquanto a nova página está sendo consultada, os cards do último resultado continuam montados e na mesma posição; eles só são substituídos quando a resposta nova chega, evitando o efeito de lista pulando a cada troca de loja. Falha, lista parcial, atualização atrasada, ausência de categoria e valor zero continuam estados distintos dos controles de filtro.

A URL usa `?q=` para funcionar sem JavaScript e permitir compartilhar a busca.

Cada grupo de loja mostra:

- nome da loja e horário do último sucesso;
- quantidade de resultados;
- cards ordenados por menor preço atual;
- preço cheio riscado quando diferente do atual;
- desconto absoluto e percentual;
- preço atual;
- cashback absoluto e percentual;
- “Após cashback: R$ ...”;
- parcelamento e disponibilidade;
- botão “Abrir no Shopping Inter”;
- link para histórico.

Nenhum card contém imagem externa. Valores ausentes somem com rótulo honesto; nunca viram zero.

### 9.3 Seleção de lojas

A página administrativa busca entre os 111 vendedores observados por nome e slug normalizados. “Ponto Frio” e “Pontofrio” encontram `Ponto`, mas a confirmação grava seu ID real.

Não existe limite visual ou de banco para a quantidade selecionada. A tela deixa explícito que cada loja acrescenta uma coleta paginada três vezes ao dia e mostra a quantidade de páginas da última execução.

Remover exige confirmação. A remoção desativa novas coletas e a exposição pública, mas não apaga imediatamente produto nem histórico.

### 9.4 Histórico

A página do produto mostra:

- preço e cashback atuais;
- mínimo e máximo de preço atual nos últimos 30 dias;
- tabela cronológica, mais recente primeiro;
- estado “não apareceu na coleta mais recente” quando aplicável.

A primeira entrega usa resumo + tabela, sem gráfico e sem JavaScript obrigatório.

### 9.5 Estados de falha

| Estado | Site |
|---|---|
| Loja selecionada nunca sincronizada | “Catálogo ainda não coletado” |
| Atualização em andamento | Continua mostrando o último sucesso e informa atualização |
| Falha recente com sucesso anterior | Mostra catálogo anterior e horário, com aviso da falha |
| Catálogo com mais de 12 horas | Marca “dados atrasados” |
| Produto ausente no último sucesso | Não aparece na busca atual; histórico informa ausência |
| Banco indisponível | Página de erro controlada; não consulta o Inter como fallback |

---

## 10. Segurança, privacidade e uso responsável

### 10.1 Comportamento na fonte

- Somente endpoints usados por páginas públicas.
- User-Agent honesto do projeto.
- Sem login, cookie, token, proxy, CAPTCHA ou rotação de identidade.
- Uma página por vez dentro da loja e no máximo duas lojas simultâneas.
- Até três tentativas para falha HTTP transitória ou total declarado variável.
- HTTP 401/403 encerra imediatamente.
- HTTP 429 respeita espera limitada e depois falha.
- Pedido explícito do titular interrompe a V4 até revisão.

A quantidade de lojas selecionadas é decisão da pessoa, mas não remove essas travas técnicas.

### 10.2 Conteúdo e links

Todo texto é hostil. `dangerouslySetInnerHTML` é proibido. Etiquetas não viram classes CSS arbitrárias. Caminhos são reconstruídos sob o domínio permitido; `javascript:`, domínio externo e URL absoluta inesperada são descartados.

### 10.3 Imagens e marcas

URLs de imagem são ignoradas. A página usa a identidade local Radar de Benefícios, sem logo do Inter ou das lojas. O rodapé mantém o aviso de não afiliação e orienta a conferir preço, estoque, frete e cashback antes da compra.

### 10.4 Privacidade

Busca pública não é registrada como perfil nem enviada à fonte. O robô coleta catálogos sem saber quem visitou o site. Seleção de lojas continua sendo preferência de uma única instalação, protegida pela sessão administrativa.

---

## 11. Testes

Os casos CT-200 em diante ficam catalogados em [`TESTES.md`](TESTES.md) antes de qualquer código.

### 11.1 Extrator e paginação

- Fixture com múltiplas páginas, última página e produto duplicado.
- JSON inválido, raiz incompatível, decimal fora do intervalo e texto excessivo.
- `searchId` constante nas páginas de uma tentativa e diferente na próxima.
- Offset crescente e interrupção em `isLastPage`.
- Catálogo acima de 3.000 itens sem teto artificial.
- Página repetida e offset travado falham ruidosamente.
- IDs iguais em lojas diferentes não colidem.
- Imagens e SKUs não entram no domínio.

### 11.2 Orquestração e persistência

- Somente selecionadas geram tarefas.
- Zero, três e dez lojas produzem matriz correspondente.
- Concorrência efetiva nunca passa de duas lojas.
- Uma falha não cancela sucessos das demais.
- Falha no meio das páginas preserva snapshot anterior.
- Total variável seleciona a tentativa completa com mais produtos únicos.
- Publicação degradada atualiza encontrados sem inativar ausentes.
- Publicação, inativação e medições são atômicas por loja.
- Histórico completo por 30 dias e expurgo do anterior.
- Códigos de falha não vazam URL de banco nem payload.

### 11.3 Site

- Busca normalizada e sinônimo celular/smartphone.
- Edge 60 Pro entra; Moto G não.
- Somente lojas selecionadas aparecem.
- Ordenação monetária usa número sem alterar o texto exibido.
- Campos ausentes não viram zero.
- Histórico calcula mínimo e máximo com precisão decimal.
- Mutação exige sessão; leitura é pública.
- Nenhuma imagem ou HTML externo é renderizado.
- Todas as telas e formulários funcionam sem JavaScript.

### 11.4 Aceite real

O primeiro aceite usa uma loja, depois Casas Bahia + Ponto, antes de ampliar:

1. Conferir catálogo de vendedores e slugs.
2. Coletar uma loja até a última página e comparar totais.
3. Confirmar deduplicação e duração.
4. Selecionar Casas Bahia e Ponto.
5. Rodar busca “celular Motorola Edge 60 Pro”.
6. Comparar preço, desconto, cashback e líquido com o Shopping Inter no mesmo momento.
7. Aguardar mais de uma rodada e conferir o histórico.
8. Injetar falha numa loja e confirmar preservação da outra.

---

## 12. Fases planejadas

| Fase | Entrega | Estado |
|---|---|---|
| **V4.0** | PRD, levantamento da fonte e casos CT-200+ | Este documento |
| **V4.1** | Medidor sem escrita, schema, migração e contratos de persistência | Implementada; falta fechar bytes e projeções |
| **V4.2** | Domínio puro, extrator paginado, adaptador HTTP e fixture | Implementada e validada contra a fonte real |
| **V4.3** | Coleta por loja, publicação atômica, retenção e primeira carga | Casas Bahia publicada no Neon; Ponto pendente |
| **V4.4** | Busca pública, seleção administrativa e histórico | Implementada; Edge 60 Pro confirmado no banco, smoke visual pendente |
| **V4.5** | Workflow matricial, disparo manual, observabilidade e aceite real | Implementada; deploy do follow-up pendente |

O aceite não começa pela interface: primeiro mede-se uma coleta completa de uma loja e fecha-se o volume observado antes de habilitar mais seleções.

---

## 13. Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Endpoint ou schema mudar | Catálogo para de atualizar | Adaptador isolado, fixture, validação e último sucesso |
| `total = 3000` ser teto | Cobertura parcial não óbvia | Janela-base + partições fixas justificadas; nunca prometer catálogo universal |
| Muitas lojas selecionadas | Workflow longo e alto volume | Matriz por loja, `max-parallel: 2`, páginas sequenciais e rollout gradual |
| Produtos repetidos entre páginas | Contagem e histórico duplicados | Deduplicação por loja + ID, métrica de duplicatas |
| Produto mudar durante paginação | Snapshot mistura instantes | Horário por conclusão e sem promessa de simultaneidade |
| Falha na página 80 de 84 | Catálogo incompleto | Área de preparação e publicação atômica |
| Histórico crescer demais | Custo ou limite do Neon | Gate de volume antes da migração e retenção de 30 dias |
| Link externo malicioso | Phishing/XSS | Reconstrução sob domínio fixo e conteúdo como texto |
| Comparar variantes diferentes | Decisão de compra errada | Sem unificação automática; nome completo e ID visíveis |
| Fonte bloquear a coleta | V4 indisponível | Sem evasão; desligamento isolado preserva V1–V3 |

---

## 14. Critérios de aceite da V4

A V4 só pode ser marcada implementada quando:

1. O catálogo de lojas diretas vem da fonte real e Ponto/Casas Bahia podem ser selecionadas.
2. Loja não selecionada não recebe nenhuma consulta de produto.
3. Cada partição de uma loja é percorrida até `isLastPage`, sem teto fixo no código.
4. Duplicatas são removidas por ID e contabilizadas.
5. Falha estrutural não publica catálogo incompleto; total variável só publica uma tentativa que chegou ao fim e não inativa ausentes.
6. Dez lojas selecionadas geram dez tarefas sem limite funcional e com no máximo duas simultâneas.
7. A busca pública lê somente o banco e somente lojas selecionadas.
8. “celular Motorola Edge 60 Pro” retorna Edge 60 Pro e não Moto G.
9. Card mostra preço cheio, desconto, atual, cashback e líquido da mesma coleta.
10. Histórico guarda três medições diárias e remove dados após 30 dias.
11. Nenhuma imagem, HTML externo ou credencial do Inter entra no produto.
12. Livelo e V3 continuam verdes e operacionais quando a V4 falha.
13. O aceite real com Casas Bahia e Ponto confirma valores contra a fonte no mesmo momento.

---

## 15. Decisões fechadas e gates abertos

### 15.1 Fechado

| Tema | Decisão |
|---|---|
| Fonte | Área Compre direto no Inter, separada de Sites parceiros |
| Seleção | Somente lojas escolhidas; sem limite funcional de quantidade |
| Cobertura | Todas as páginas expostas até `isLastPage`, sem teto fixo |
| Profundidade | Dados da listagem; nenhuma página individual por produto |
| Frequência | 09h, 14h e 20h de Brasília |
| Escala | Uma tarefa por loja, máximo duas simultâneas, páginas sequenciais |
| Identidade | Loja por ID/slug; produto por loja + ID externo |
| Pesquisa | Local no banco, termos completos normalizados, celular = smartphone |
| Interface | Resultados por loja, menor preço atual, sem imagens |
| Histórico | Todos os produtos das lojas selecionadas, retenção de 30 dias |
| Falha | Atomicidade e último sucesso por loja; total variável aceita melhor tentativa completa sem inativar ausentes; rodada geral pode ser parcial |

### 15.2 Aberto antes de ampliar o rollout

| Gate | Precisa fechar |
|---|---|
| Volume | Medir bytes e tempo de uma coleta completa real |
| Persistência | Validada para Casas Bahia; observar crescimento após novas rodadas |
| Custo | Projetar 3, 10 e 111 lojas por 30 dias no Neon |
| Timeout | Validar os 30 minutos com duas lojas simultâneas |
| Ritmo | 1,5 s funcionou para uma loja; revalidar ao habilitar Ponto |
| Primeira carga | Casas Bahia concluída; Ponto é o próximo gate antes de ampliar |

Esses gates não reabrem o comportamento de produto. Eles definem como cumprir o volume com segurança.

### 15.3 Registro da especificação

Em 2026-08-16, a fonte pública respondeu sem autenticação e com identificação honesta. O levantamento encontrou 111 vendedores diretos, confirmou Casas Bahia e Ponto e validou busca paginada de produtos com campos monetários e caminhos individuais. Casas Bahia e Ponto declararam 3.000 produtos e 84 páginas de 36 itens numa busca vazia. Também foi observada repetição de produto entre páginas, justificando RN61.

No levantamento inicial não houve coleta completa nem escrita. Em 2026-08-17, o contrato real revelou três diferenças que as fixtures antigas escondiam: raiz `sellers`, tags como objetos e caminhos relativos com variante `?v=`. Depois da correção, a migração `008` foi aplicada e a rodada 3 da Casas Bahia terminou em `sucesso`: 94 páginas, 3.363 itens lidos, 3.310 únicos, 53 sobreposições e Edge 60 Pro presente com preço de R$ 3.688,89 e 9% de cashback naquele momento. Ponto continua desmarcada até o próximo gate.

Ainda em 2026-08-17, uma rodada posterior mostrou que `pagination.total` pode variar durante todas as três tentativas da mesma partição. A V4.5.1 passou a concluir cada candidata até `isLastPage`, preferir qualquer tentativa estável e, se todas variarem, publicar a candidata completa com mais produtos únicos como `degradada`. Essa publicação atualiza encontrados e medições sem inativar ausentes; a migração `009` guarda qualidade, tentativas e intervalo dos totais.
