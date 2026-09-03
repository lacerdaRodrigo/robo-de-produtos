# Plano — Evolução da Área Produtos do Banco Inter

## 1. Objetivo

Evoluir a área **Produtos** do Radar de Benefícios para organizar os produtos do Banco Inter por categorias próprias do Radar, preservando a seleção atual de lojas e adicionando uma segunda camada de interesse por categoria.

Nesta etapa, o catálogo de Produtos será formado **somente pelos produtos do Banco Inter vindos das lojas acompanhadas pela pessoa**. Integrações adicionais de produtos não fazem parte deste plano.

A regra central passa a ser:

```text
Banco Inter — Compre direto
  ↓
Lojas acompanhadas/selecionadas
  ↓
Categorias do Radar selecionadas
  ↓
Produtos relevantes persistidos
  ↓
Tela Produtos
```

A seleção de lojas **não é removida**.

Exemplo no Banco Inter:

- existem aproximadamente 112 lojas disponíveis;
- a pessoa continua escolhendo quais lojas deseja monitorar, como já ocorre hoje;
- depois escolhe quais categorias de produtos interessam;
- a coleta e/ou persistência passa a restringir o catálogo ao escopo escolhido quando a loja permitir isso de forma confiável.

---

## 2. Problema atual

Hoje, no Compre direto do Banco Inter, a principal decisão é a loja.

Exemplo:

```text
Banco Inter
  ↓
Casas Bahia selecionada
  ↓
Ponto selecionado
  ↓
Outras lojas selecionadas
  ↓
coleta grande de produtos dessas lojas
```

Isso pode trazer milhares de itens que não fazem parte do interesse atual da pessoa.

Uma loja selecionada pode vender:

- celulares;
- TVs;
- geladeiras;
- cabos;
- móveis;
- brinquedos;
- panelas;
- eletrodomésticos;
- informática;
- dezenas de outros grupos.

Selecionar a loja não significa querer acompanhar todo o catálogo dela.

O objetivo deste plano é separar duas decisões que hoje estão parcialmente acopladas:

1. **Onde procurar?** — loja do Banco Inter selecionada.
2. **O que procurar?** — categoria do Radar selecionada.

---

## 3. Princípios inegociáveis

1. **A seleção de lojas existente continua válida.**
2. **Categorias são uma camada adicional, não substituta.**
3. **As categorias oficiais pertencem ao Radar, não às lojas externas.**
4. **As diferenças entre as lojas do Inter são tratadas por mapeamentos explícitos.**
5. **Produtos identifica claramente a loja de origem de cada oferta.**
6. **Busca no Flutter consulta somente o banco/API.** Nunca consulta o Banco Inter ao digitar.
7. **Não classificar por aproximação insegura quando houver dúvida.**
8. **Ausência de classificação não deve virar categoria incorreta.**
9. **Não criar centenas de categorias antecipadamente.** A taxonomia cresce conforme necessidade real.
10. **Precisão financeira e estados de coleta existentes continuam preservados.**

---

## 4. Conceito novo: Categoria do Radar

O Radar passa a possuir uma taxonomia própria e controlada.

Exemplo inicial:

```text
Eletrônicos
├── Celulares
├── Acessórios para celulares
│   ├── Cabos
│   ├── Carregadores
│   ├── Capas e películas
│   └── Suportes
├── Tablets
├── Smartwatches
├── TVs
└── Áudio

Informática
├── Notebooks
├── Placas de vídeo
├── Processadores
├── Memória RAM
├── SSD
├── Monitores
├── Teclados
├── Mouses
└── Headsets

Eletrodomésticos
├── Air Fryer
├── Geladeiras
├── Fogões
└── Aspiradores

Casa
├── Cozinha
│   ├── Panelas
│   └── Utensílios
└── Sala
    ├── Móveis
    └── Decoração
```

Essa árvore é ilustrativa. A implementação inicial deve conter somente as categorias realmente escolhidas para o primeiro rollout.

### Regras da hierarquia

- cada categoria possui identificador e `slug` estáveis, independentemente do texto apresentado pela loja;
- cada produto recebe inicialmente uma categoria principal, preferencialmente a categoria folha mais específica;
- selecionar uma categoria pai inclui seus descendentes na consulta;
- categorias de ambiente, como `Cozinha` e `Sala`, organizam tipos mais específicos, como `Panelas`, `Móveis` e `Decoração`;
- um produto não deve ser colocado em várias categorias principais apenas para aumentar sua chance de aparecer;
- classificações secundárias ou etiquetas somente devem ser adicionadas depois de existir uma necessidade real aprovada.

Exemplos:

```text
Panela de pressão → Casa > Cozinha > Panelas
Sofá retrátil     → Casa > Sala > Móveis
Smart TV          → Eletrônicos > TVs
Geladeira         → Eletrodomésticos > Geladeiras
```

---

## 5. Por que a categoria precisa ser do Radar

Cada loja do Banco Inter pode usar nomes diferentes para a mesma família de produtos.

Exemplo:

```text
Radar: Celulares

Casas Bahia / Inter → Celulares e Smartphones
Ponto / Inter       → Smartphones
Samsung / Inter     → Telefonia
Motorola / Inter    → Aparelhos celulares
```

Todos podem apontar para:

```text
categoria_radar = celulares
```

O Radar não deve criar uma categoria nova automaticamente só porque uma loja usou um nome diferente.

Uma loja pode possuir centenas de categorias externas. Isso não significa que o Radar terá a mesma quantidade de categorias. O mapeamento é muitos-para-um: várias categorias externas podem apontar para uma única categoria oficial.

Exemplo:

```text
Casas Bahia / Telefonia móvel       ─┐
Ponto / Smartphones                  ├→ Radar: Celulares
Motorola / Aparelhos celulares      ─┘
```

Uma loja com 200 categorias externas pode, portanto, alimentar uma taxonomia Radar menor, controlada e coerente.

---

## 6. Mapeamento por loja do Inter

A integração do Banco Inter é responsável por traduzir as categorias externas de cada loja para categorias oficiais do Radar.

Conceitualmente:

```text
categoria_radar
---------------
id
nome
slug
categoria_pai
ativo
```

E:

```text
categoria_externa_loja_inter
-----------------------------
id
loja_inter
identificador_categoria_externa
nome_categoria_externa
breadcrumb_externo
primeira_observacao_em
ultima_observacao_em
estado
```

E:

```text
mapeamento_categoria_loja_inter
--------------------------------
categoria_externa_loja_inter_id
categoria_radar_id
ativo
versao_mapeamento
```

Exemplos:

```text
Inter/Casas Bahia | Celulares e Smartphones | Celulares
Inter/Ponto       | Smartphones             | Celulares
Inter/Ponto       | TV e Vídeo              | TVs
Inter/Casas Bahia | Refrigeradores          | Geladeiras
```

A oferta observada deve preservar, conceitualmente:

```text
oferta
------
loja_inter
identificador_produto_externo
categoria_externa_loja_inter_id
categoria_radar_id                 // anulável enquanto pendente
estado_classificacao
motivo_classificacao
versao_mapeamento
classificado_em
```

Desse modo, mesmo um produto ainda não classificado mantém sua loja, categoria externa, breadcrumb e motivo da pendência. Ele não fica perdido nem é colocado artificialmente em uma categoria incorreta.

Os nomes físicos finais das tabelas devem ser definidos na fase de schema, não antecipados por este plano.

---

## 7. Classificação: ordem de confiança

A classificação não deve depender apenas de palavras no nome do produto.

Ordem recomendada:

### Nível 1 — Identificador/categoria estruturada da loja

Melhor cenário.

A loja fornece categoria, subcategoria, slug, ID ou breadcrumb estável.

Exemplo:

```text
Ponto / Inter
Telefonia > Smartphones
```

Mapeamento:

```text
Smartphones → Radar: Celulares
```

Uma categoria externa ampla não deve ser tratada como prova absoluta. Algumas lojas podem colocar celulares e acessórios no mesmo departamento. Sempre que existir uma subcategoria ou tipo de produto mais específico, ele prevalece sobre o nome amplo do departamento.

### Nível 2 — Mapeamento específico da loja

Como as lojas do Inter podem possuir taxonomias próprias, o adaptador pode possuir regra explícita por loja.

Exemplo:

```text
Casas Bahia / Inter → Celulares e Smartphones → Celulares
Ponto / Inter       → Smartphones → Celulares
```

### Nível 3 — Tipo do produto e metadados complementares

Tipo do produto, marca, nome, breadcrumb e atributos podem ajudar quando a categoria estruturada é insuficiente.

Nunca usar uma palavra isolada como prova suficiente.

Exemplo de falso positivo:

```text
Cabo USB para smartphone Samsung
```

Apesar de conter `smartphone`, o item não deve virar `Celulares`.

Quando houver evidência suficiente, ele deve ser classificado pela sua função principal:

```text
Eletrônicos
├── Celulares
└── Acessórios para celulares
    ├── Cabos
    ├── Carregadores
    ├── Capas e películas
    └── Suportes
```

Exemplo:

```text
Categoria externa: Telefonia > Smartphones
Produto: Cabo USB-C para smartphone
Tipo do produto: Cabo

Resultado: Eletrônicos > Acessórios para celulares > Cabos
```

`Periféricos` deve ser reservado, em princípio, para itens como mouse, teclado, webcam e controle. Cabo de carregamento de celular deve usar `Acessórios para celulares > Cabos`, salvo decisão diferente na taxonomia aprovada.

### Nível 4 — Não classificado

Se não houver confiança suficiente:

```text
categoria_radar = null / não classificado
```

É melhor perder temporariamente uma classificação do que poluir o catálogo com produto incorreto.

### Estados da classificação

`Não classificado` não será uma categoria comum do Radar. Será uma fila operacional com estados explícitos:

```text
classificado
categoria_externa_nao_mapeada
sem_categoria_na_origem
classificacao_ambigua
erro_de_classificacao
```

- `classificado`: existe mapeamento aprovado para uma categoria do Radar;
- `categoria_externa_nao_mapeada`: a loja informou a categoria, mas ainda não existe mapeamento;
- `sem_categoria_na_origem`: a loja não informou categoria utilizável;
- `classificacao_ambigua`: existem sinais conflitantes ou insuficientes;
- `erro_de_classificacao`: houve uma falha técnica durante o processamento.

Nos quatro últimos estados, `categoria_radar_id` permanece nulo, mas o produto continua armazenado com os dados externos e o motivo. A administração apresenta esses registros em **Pendentes de classificação** ou **Não classificados**.

---

## 8. Seleção de categorias para as lojas acompanhadas

A pessoa poderá escolher quais categorias deseja que façam parte do Radar.

Exemplo:

```text
Categorias acompanhadas

[x] Celulares
[x] TVs
[x] Geladeiras
[x] Panelas
[ ] Móveis
```

Essas categorias valem para todas as lojas do Banco Inter que a pessoa acompanha. Cada loja pode usar um nome externo diferente, mas todos os nomes aprovados apontam para a mesma categoria do Radar.

Quando uma categoria pai for selecionada, suas categorias filhas também participam da consulta. Quando somente `Celulares` estiver selecionada, cabos, carregadores, capas e películas não devem aparecer. Esses itens exigem a seleção de `Acessórios para celulares` ou de uma de suas categorias filhas.

---

## 9. Relação com a seleção de lojas do Banco Inter

O funcionamento atual de seleção das lojas permanece.

Exemplo:

```text
Banco Inter — Compre direto

[x] Casas Bahia
[x] Ponto
[x] Samsung
[x] Motorola
[x] Loja 5
[x] Loja 6
[x] Loja 7
[x] Loja 8
[x] Loja 9
[x] Loja 10
```

Depois, para todas as lojas acompanhadas:

```text
Categorias

[x] Celulares
[x] TVs
[x] Geladeiras
[x] Panelas
```

O resultado pretendido é:

```text
Casas Bahia → somente produtos das categorias escolhidas
Ponto       → somente produtos das categorias escolhidas
Samsung     → somente produtos das categorias escolhidas
Motorola    → somente produtos das categorias escolhidas
...
```

A loja acompanhada continua sendo condição necessária: escolher uma categoria não habilita automaticamente uma loja que a pessoa não selecionou.

---

## 10. Escopo atual: somente Banco Inter

O fluxo desta etapa é único:

```text
Banco Inter — Compre direto
  ↓
Lojas acompanhadas/selecionadas
  ↓
Categorias selecionadas
  ↓
Produtos relevantes dessas lojas
```

Nenhuma integração adicional de produtos faz parte desta etapa. Uma eventual expansão futura deverá ter plano e autorização próprios.

---

## 11. Estratégia de coleta

Existem dois cenários possíveis conforme os recursos oferecidos por cada loja dentro da integração do Inter.

### Descoberta das categorias externas

O robô deve sincronizar a árvore ou a lista de categorias externas das lojas acompanhadas quando esse dado estiver disponível. Descobrir 200 categorias externas não cria 200 categorias do Radar e não exige necessariamente baixar todos os produtos.

Fluxo recomendado:

```text
loja acompanhada
  ↓
sincronizar IDs, nomes e breadcrumbs das categorias externas
  ↓
consultar os mapeamentos aprovados
  ↓
identificar quais categorias externas atendem às categorias Radar selecionadas
  ↓
coletar e classificar produtos
```

Quando a loja não oferecer um catálogo separado de categorias, elas serão descobertas progressivamente durante a coleta dos produtos.

### Cenário A — Loja permite filtro confiável antes da coleta

Preferível.

Exemplo:

```text
Casas Bahia
  ↓
consulta/filtro Celulares
  ↓
somente celulares
```

Vantagens:

- menos requisições;
- menor tempo de execução;
- menos banco;
- menos histórico inútil;
- menor risco de rate limit;
- menor custo operacional.

### Cenário B — Loja não permite filtro confiável

Nesse caso:

1. coleta o escopo mínimo necessário disponibilizado pela loja;
2. preserva a observação e os dados externos necessários para não perder o produto;
3. classifica localmente;
4. publica no catálogo selecionado somente o conjunto classificado nas categorias acompanhadas;
5. encaminha produtos sem classificação para a fila operacional correspondente;
6. registra as limitações reais da loja.

A estratégia deve ser definida pelo comportamento real da loja/adaptador. Não impor a mesma técnica a todas as lojas sem validar o contrato disponível.

### Lotes, paginação e retomada

Uma execução que encontre, por exemplo, 2.000 produtos em 200 categorias externas não deve realizar gravações isoladas e descontroladas. O processamento deve usar lotes, paginação e operações idempotentes.

O checkpoint deve identificar, quando aplicável:

```text
execucao_coleta
loja
categoria_externa
pagina/cursor
estado
```

Se a coleta parar na página 12, ela deve conseguir continuar do ponto seguro correspondente. Reprocessar a mesma página não pode duplicar produto, oferta ou registro de histórico.

### Retentativas da coleta do Inter

Para falhas temporárias, a política inicial será:

```text
tentativa inicial
  ↓ falhou temporariamente
segunda tentativa após espera curta
  ↓ falhou temporariamente
terceira e última tentativa após espera maior
```

- aplicar espera progressiva com variação aleatória para evitar novas chamadas simultâneas;
- respeitar `Retry-After` quando houver resposta `429`;
- repetir apenas timeout, falha de conexão, `408`, `429` e erros `5xx` transitórios;
- não repetir automaticamente requisição inválida, categoria inexistente, falha de autorização ou resposta incompatível;
- repetir somente a página/categoria afetada, quando o contrato permitir;
- depois de esgotar as tentativas, registrar `falha` ou `parcial`, preservar dados anteriores e permitir nova tentativa no próximo ciclo agendado.

As quantidades e os intervalos exatos devem ficar configuráveis, sem repetição infinita.

---

## 12. Evolução da tela Produtos

A página **Produtos permanece como destino principal** e continua representando:

```text
Produtos do Compre direto do Inter vindos das lojas acompanhadas
```

Exemplo de interface conceitual:

```text
Produtos

[Todos] [Celulares] [TVs] [Geladeiras] [Panelas]

Buscar produto...

Celulares

Motorola Edge 60 Pro
- Casas Bahia / Banco Inter
- Ponto / Banco Inter
- Motorola / Banco Inter

TVs

Smart TV 50" ...
- Ponto / Banco Inter
- Casas Bahia / Banco Inter
```

A implementação visual final deve seguir o sistema de design vigente e não este desenho textual.

---

## 13. Filtro por categoria na tela Produtos

A seleção de categoria da tela Produtos é um **filtro de visualização**, não uma nova coleta.

Exemplo:

```text
Todos | Celulares | TVs | Geladeiras | Panelas
```

Ao escolher `Celulares`:

- consulta o banco/API;
- retorna somente produtos classificados como `Celulares`;
- mantém origem da oferta;
- não acessa o Banco Inter em tempo real.

---

## 14. Busca

A busca continua local ao catálogo persistido.

Exemplo:

```text
Categoria: Celulares
Busca: Edge 60 Pro
```

Resultado:

```text
Edge 60 Pro
- Casas Bahia / Banco Inter
- Ponto / Banco Inter
- Motorola / Banco Inter
```

O resultado considera somente ofertas persistidas das lojas do Banco Inter acompanhadas pela pessoa.

### Falha e nova tentativa da busca

A busca digitada no Flutter consulta somente a API e o banco do Radar. Uma falha nessa busca não inicia coleta nem chama o Banco Inter.

Para erros transitórios de leitura:

1. o aplicativo realiza no máximo uma nova tentativa automática após uma espera curta;
2. se a falha continuar, apresenta uma mensagem de erro e a ação `Tentar novamente`;
3. a ação repete exatamente o termo, categoria, lojas, filtros e página da requisição que falhou;
4. os últimos resultados válidos podem permanecer visíveis com indicação de desatualização/erro; eles não devem ser convertidos em uma lista vazia;
5. nova digitação substitui a busca anterior e reinicia a paginação da nova consulta.

Não repetir automaticamente erros de validação, autenticação ou autorização. Estados `vazio`, `falha`, `parcial`, `atrasado` e `sem dado` continuam distintos.

---

## 15. Produto versus oferta

Este plano deve preservar uma distinção importante.

### Oferta

Representa um item observado numa origem específica.

Exemplo:

```text
Edge 60 Pro
Origem: Banco Inter / Casas Bahia
Preço: R$ X
```

### Produto canônico

Representaria o produto real independente da loja.

Exemplo:

```text
Motorola Edge 60 Pro 256 GB
```

com várias ofertas abaixo dele.

A primeira fase deste plano **não precisa resolver produto canônico entre lojas**.

Inicialmente, Produtos pode continuar exibindo ofertas agrupadas por origem/categoria.

A unificação automática do mesmo produto entre lojas só deve acontecer depois de existir estratégia confiável para:

- EAN/GTIN;
- MPN/código de fabricante;
- modelo;
- variante/capacidade/cor;
- ou outra identidade aprovada.

Não comparar itens apenas porque os nomes parecem semelhantes.

---

## 16. Histórico

O histórico continua pertencendo à oferta/origem medida.

Exemplo:

```text
Edge 60 Pro — Casas Bahia / Inter
09:00 R$ X
14:00 R$ Y
20:00 R$ Z
```

E, separadamente:

```text
Edge 60 Pro — Ponto / Inter
09:00 R$ A
14:00 R$ B
20:00 R$ C
```

Se futuramente houver produto canônico, esses históricos poderão ser apresentados juntos sem perder a origem individual.

---

## 17. Migração do modelo atual

A mudança deve ser aditiva e progressiva.

### Fase 1 — Categorias do Radar

- criar catálogo mínimo de categorias oficiais;
- criar hierarquia com categoria pai e folhas específicas;
- criar mecanismo de seleção das categorias acompanhadas;
- manter produtos Inter funcionando como hoje.

### Fase 2 — Mapeamento Inter

- estudar categorias reais retornadas pelas lojas selecionadas;
- registrar categorias externas com ID, nome, breadcrumb e loja;
- mapear somente as categorias inicialmente escolhidas;
- não tentar resolver todas as 112 lojas antecipadamente;
- preservar produtos sem mapeamento na fila de classificação;
- implementar reclassificação idempotente depois da aprovação de um mapeamento;
- implementar paginação, checkpoint e retentativas limitadas na coleta.

### Fase 3 — API de Produtos

Evoluir a busca para aceitar categoria do Radar sem remover imediatamente os contratos atuais.

Exemplo conceitual:

```text
Produtos
- termo
- categoria_radar
- loja
- marca
- preço mínimo/máximo
- paginação
```

Os nomes finais dos parâmetros devem respeitar os contratos atuais e ser definidos na implementação.

A API deve incluir descendentes quando receber uma categoria pai e distinguir resposta vazia de falha, resultado parcial ou dado atrasado.

### Fase 4 — Flutter

- adicionar filtro/seleção de categoria na área Produtos;
- preservar busca, paginação, filtros e rolagem existentes;
- mostrar origem explicitamente;
- implementar a nova tentativa limitada da busca preservando seu estado;
- apresentar vazio, falha, parcial e desatualizado como estados diferentes;
- não inventar comparação entre lojas sem backend correspondente.

### Fase 5 — Estabilização do catálogo Inter

- revisar categorias externas ainda não mapeadas;
- medir falhas, páginas processadas, tempo e volume persistido;
- medir o tamanho e a idade da fila de classificação;
- corrigir mapeamentos sem perder a seleção atual de lojas;
- validar o comportamento das lojas selecionadas antes de ampliar a taxonomia.

---

## 18. Taxonomia inicial recomendada

Não implementar uma árvore completa agora.

Começar somente com categorias aprovadas para uso real.

Uma primeira lista candidata para discussão:

- Celulares;
- Acessórios para celulares;
- Cabos;
- Carregadores;
- Capas e películas;
- Suportes;
- Tablets;
- Notebooks;
- Smartwatches;
- TVs;
- Áudio;
- Placas de vídeo;
- Processadores;
- SSD;
- Monitores;
- Teclados;
- Mouses;
- Headsets;
- Geladeiras;
- Fogões;
- Air Fryer;
- Aspiradores;
- Cozinha;
- Panelas;
- Utensílios;
- Sala;
- Móveis;
- Decoração.

Essa lista não é decisão final de produto. Deve ser aprovada antes da implementação.

---

## 19. Administração e configuração

Deve existir uma forma autenticada/autorizada de:

- listar categorias do Radar;
- ativar/desativar categorias acompanhadas;
- visualizar categorias não classificadas encontradas nas lojas do Inter;
- filtrar pendências por loja, categoria externa, estado e quantidade de produtos afetados;
- adicionar/corrigir mapeamentos quando necessário;
- visualizar o impacto e confirmar a reclassificação em lote;
- revisar impacto antes de ampliar escopo.

Não é necessário expor edição arbitrária de taxonomia a usuário comum.

A forma exata da administração precisa respeitar os fluxos administrativos já existentes no projeto.

---

## 20. Tratamento de categorias desconhecidas

Quando uma loja do Inter retornar nova categoria externa não mapeada:

1. registrar a categoria externa de forma observável;
2. não criar categoria Radar automaticamente;
3. não classificar produtos por suposição;
4. armazenar os produtos observados com `categoria_radar_id = null` e o estado específico da pendência;
5. disponibilizar a pendência para revisão administrativa;
6. adicionar mapeamento somente após decisão.

Exemplo:

```text
Loja Inter: Ponto
Categoria externa: Telefonia e Comunicação
Estado: não mapeada
```

Depois da revisão:

```text
Telefonia e Comunicação → Celulares
```

ou outra categoria correta.

Depois que um mapeamento for aprovado, um processamento em lote deve reclassificar automaticamente os produtos pendentes que possuem a mesma loja e categoria externa. Essa reclassificação não deve consultar novamente o Banco Inter quando os identificadores e metadados necessários já estiverem persistidos.

O processamento deve registrar a versão do mapeamento aplicado, ser idempotente e permitir correção posterior sem duplicar ofertas ou históricos.

---

## 21. Testes previstos

Os testes devem ser implementados junto da fase diretamente afetada. No ciclo mobile V11, continuam autorizados somente unitários e widgets diretamente relacionados. Testes de backend/API descritos abaixo pertencem à fase correspondente e não autorizam alteração de backend neste ciclo.

Nenhum teste automatizado deve depender do Banco Inter real. Respostas externas devem ser simuladas de forma determinística.

### Unitários de categoria e classificação

- categoria Radar ativa/inativa;
- slug único;
- hierarquia sem ciclos e com relacionamento pai/filho válido;
- selecionar categoria pai inclui seus descendentes;
- categoria desconhecida não é criada automaticamente;
- categoria externa conhecida mapeia corretamente;
- alias da loja mapeia corretamente;
- várias categorias externas podem mapear para a mesma categoria Radar;
- categoria desconhecida permanece sem classificação;
- os estados `categoria_externa_nao_mapeada`, `sem_categoria_na_origem`, `classificacao_ambigua` e `erro_de_classificacao` não são confundidos;
- palavra no nome do produto não sobrescreve categoria estruturada confiável;
- `cabo para smartphone` não vira `Celulares`;
- cabo com evidência suficiente vai para `Acessórios para celulares > Cabos`;
- categoria externa ampla não sobrescreve um tipo de produto específico e confiável.

### Unitários da coleta e dos mapeamentos

- loja não selecionada continua fora da coleta do Inter;
- sincronizar categorias externas não cria categorias Radar automaticamente;
- lote repetido não duplica produto, oferta ou histórico;
- checkpoint permite retomar da página/cursor correto;
- produto sem mapeamento é armazenado e encaminhado à fila operacional;
- aprovar mapeamento reclassifica pendentes da mesma loja/categoria externa;
- repetir reclassificação é idempotente;
- timeout, falha de conexão, `408`, `429` e `5xx` transitório acionam somente as tentativas previstas;
- `429` respeita `Retry-After`;
- erro de validação, autorização ou resposta incompatível não entra em repetição automática;
- esgotar retentativas preserva dados anteriores e registra estado `falha` ou `parcial`.

### Unitários automatizados da API de Produtos

Esses testes devem chamar handlers/serviços da API diretamente, com autenticação, repositórios e integrações externas controlados por doubles/mocks.

- categoria não selecionada não aparece no catálogo de Produtos quando a política da fase exigir filtragem;
- selecionar múltiplas categorias retorna união correta;
- remover categoria não remove outras categorias selecionadas;
- filtro `Celulares` retorna somente ofertas classificadas;
- filtro de categoria pai inclui ofertas das categorias filhas;
- `Celulares` não retorna cabos, carregadores, capas ou películas;
- origem permanece correta;
- busca + categoria funcionam juntas;
- busca + loja + marca + preço funcionam juntas;
- paginação permanece estável;
- categoria ou filtro inválido retorna erro de validação, não resultado vazio;
- catálogo sem correspondência retorna vazio válido;
- falha, parcial, atrasado, ausência de dado e zero permanecem diferentes;
- filtros existentes continuam funcionando;
- histórico continua associado à oferta correta.

### Widgets Flutter diretamente afetados

- categorias pai e filhas são apresentadas conforme o estado do design V11;
- seleção de categorias preserva as lojas acompanhadas;
- busca preserva termo, categoria, filtros e página ao usar `Tentar novamente`;
- nova busca reinicia sua própria paginação e substitui a requisição anterior;
- carregando, vazio, erro, parcial, atrasado e sucesso são apresentados corretamente;
- última lista válida não vira lista vazia quando ocorre erro transitório;
- claro/escuro e larguras cobertas não possuem overflow.

### Regressão unitária/widget

- Livelo não é afetada;
- Cashback Inter não é afetado;
- seleção de lojas do Compre direto continua funcionando;
- produtos Inter existentes permanecem acessíveis durante a migração aditiva.

---

## 22. Observabilidade

A evolução deve permitir responder:

- quantas lojas do Inter estão selecionadas;
- quantas categorias Radar estão ativas;
- quantos produtos foram classificados por categoria;
- quantos ficaram pendentes em cada estado de classificação;
- há quanto tempo cada pendência aguarda mapeamento;
- quais categorias externas ainda não possuem mapeamento;
- quanto cada recorte de coleta custa em páginas/tempo;
- qual foi o último checkpoint bem-sucedido por loja/categoria;
- quantas retentativas ocorreram e por qual motivo;
- quais lojas permitem filtrar antes da coleta e quais exigem filtragem local.

Esses dados são operacionais e não precisam virar métricas visuais para usuário final sem decisão específica.

---

## 23. Ordem de implementação recomendada

1. Aprovar conceito e nomes: `Categorias`, `Interesses` ou outro termo final de interface.
2. Definir taxonomia inicial mínima, com categorias pai e folhas específicas.
3. Levantar categorias reais das lojas Inter atualmente selecionadas.
4. Desenhar schema aditivo para categorias Radar, categorias externas, mapeamentos, estados de classificação e checkpoints.
5. Implementar domínio e persistência das categorias.
6. Implementar descoberta/sincronização das categorias externas das lojas acompanhadas.
7. Implementar a fila de classificação, reclassificação idempotente e administração dos mapeamentos.
8. Mapear as primeiras categorias do Inter.
9. Implementar paginação, checkpoint e retentativas limitadas da coleta.
10. Implementar a seleção de categorias aplicada às lojas acompanhadas.
11. Evoluir API de Produtos para filtrar por categoria Radar e descendentes.
12. Evoluir Flutter Produtos mantendo o design V11 e os estados de retentativa.
13. Validar que seleção de lojas continua intacta.
14. Medir redução de volume, custo de coleta e tamanho da fila de classificação.
15. Revisar categorias não mapeadas e estabilizar as lojas acompanhadas.
16. Somente depois discutir produto canônico e comparação automática entre lojas.

---

## 24. Critérios de aceite

A evolução inicial estará pronta quando:

- seleção de lojas do Inter continuar funcionando como antes;
- existir catálogo hierárquico e controlado de categorias Radar;
- for possível selecionar mais de uma categoria;
- categorias externas das lojas do Inter puderem ser mapeadas para categorias Radar;
- múltiplas categorias externas puderem apontar para uma única categoria Radar sem criar categorias automáticas;
- produto desconhecido permanecer armazenado com estado e motivo de classificação explícitos;
- produtos pendentes puderem ser reclassificados em lote sem nova consulta ao Inter e sem duplicação;
- acessórios como cabos não forem classificados como celulares apenas por conterem `smartphone` no nome;
- paginação, checkpoint e retentativas limitadas preservarem dados em falhas parciais;
- tela Produtos puder filtrar pelas categorias escolhidas sem consultar o Banco Inter ao vivo;
- selecionar categoria pai incluir corretamente seus descendentes;
- nova tentativa da busca preservar termo, categoria, filtros, lojas e página;
- origem de cada produto/oferta permanecer explícita;
- busca, filtros, paginação e histórico existentes não sofrerem regressão;
- Livelo e Cashback Inter continuarem isolados;
- testes diretamente afetados passarem.

---

## 25. Decisões pendentes antes de implementação

- nome de interface: `Categorias`, `Interesses`, `Coleções` ou outro;
- primeiras categorias realmente necessárias;
- onde a seleção de categorias ficará no Flutter;
- se a filtragem ocorre antes da coleta, depois da coleta ou de forma híbrida em cada loja;
- política de retenção para produtos que deixam de pertencer ao escopo selecionado;
- prazo de retenção e arquivamento dos registros da fila de classificação;
- valores configurados para intervalos e limites das retentativas;
- desenho final do fluxo administrativo de revisão e aprovação dos mapeamentos;
- quando iniciar a etapa de produto canônico entre lojas.

Nenhuma dessas decisões deve ser resolvida por suposição durante a implementação. O objetivo deste plano é preservar a lógica atual do Banco Inter e adicionar uma camada de interesse por categoria de forma controlada.
