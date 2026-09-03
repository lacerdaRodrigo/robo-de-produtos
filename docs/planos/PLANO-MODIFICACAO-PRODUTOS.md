# Plano — Evolução Global da Área Produtos

## 1. Objetivo

Evoluir a área **Produtos** do Radar de Benefícios para trabalhar com produtos de múltiplas fontes, preservando a seleção atual de lojas e adicionando uma segunda camada global de interesse por categoria.

A regra central passa a ser:

```text
Fonte habilitada
  ↓
Lojas selecionadas, quando a fonte possuir lojas
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
- a coleta e/ou persistência passa a restringir o catálogo ao escopo escolhido quando a fonte permitir isso de forma confiável.

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

1. **Onde procurar?** — fonte/loja selecionada.
2. **O que procurar?** — categoria do Radar selecionada.

---

## 3. Princípios inegociáveis

1. **A seleção de lojas existente continua válida.**
2. **Categorias são uma camada adicional, não substituta.**
3. **As categorias oficiais pertencem ao Radar, não às fontes externas.**
4. **Cada fonte continua isolada na coleta e nas regras específicas.**
5. **Produtos identifica claramente a origem de cada oferta.**
6. **Busca no Flutter consulta somente o banco/API.** Nunca consulta a fonte ao digitar.
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
├── Tablets
├── Smartwatches
├── TVs
└── Áudio

Informática
├── Notebooks
├── PC Gamer
├── Placas de vídeo
├── Processadores
├── Memória RAM
├── SSD
├── Monitores
├── Teclados
├── Mouses
└── Headsets

Casa
├── Panelas
├── Air Fryer
├── Geladeiras
├── Fogões
└── Aspiradores
```

Essa árvore é ilustrativa. A implementação inicial deve conter somente as categorias realmente escolhidas para o primeiro rollout.

---

## 5. Por que a categoria precisa ser do Radar

Cada fonte pode usar nomes diferentes para a mesma família de produtos.

Exemplo:

```text
Radar: Celulares

Fonte A → Celulares e Smartphones
Fonte B → Smartphones
Fonte C → Telefonia
Fonte D → Aparelhos celulares
```

Todos podem apontar para:

```text
categoria_radar = celulares
```

Outro exemplo:

```text
Radar: PC Gamer

Pichau → Pichau Gamer
Outra fonte → Computador Gamer
Outra fonte → Desktop Gamer
Outra fonte → PC Gaming
```

Todos podem apontar para:

```text
categoria_radar = pc-gamer
```

O Radar não deve criar uma categoria nova automaticamente só porque a fonte usou um nome diferente.

---

## 6. Mapeamento por fonte

Cada integração é responsável por traduzir suas categorias externas para categorias oficiais do Radar.

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
mapeamento_categoria_fonte
--------------------------
fonte
identificador_categoria_externa
nome_categoria_externa
categoria_radar_id
ativo
```

Exemplos:

```text
Inter/Casas Bahia | Celulares e Smartphones | Celulares
Inter/Ponto       | Smartphones             | Celulares
Pichau            | Pichau Gamer            | PC Gamer
Pichau            | Notebook                | Notebooks
```

Os nomes físicos finais das tabelas devem ser definidos na fase de schema, não antecipados por este plano.

---

## 7. Classificação: ordem de confiança

A classificação não deve depender apenas de palavras no nome do produto.

Ordem recomendada:

### Nível 1 — Identificador/categoria estruturada da fonte

Melhor cenário.

A fonte fornece categoria, subcategoria, slug, ID ou breadcrumb estável.

Exemplo:

```text
Pichau
Computadores > Pichau Gamer
```

Mapeamento:

```text
Pichau Gamer → Radar: PC Gamer
```

### Nível 2 — Mapeamento específico da loja/fonte

Quando lojas dentro da mesma fonte possuem taxonomias próprias, o adaptador pode possuir regra explícita por origem.

Exemplo:

```text
Casas Bahia / Inter → Celulares e Smartphones → Celulares
Ponto / Inter       → Smartphones → Celulares
```

### Nível 3 — Metadados complementares

Marca, nome, breadcrumb e atributos podem ajudar quando a categoria estruturada é insuficiente.

Nunca usar uma palavra isolada como prova suficiente.

Exemplo de falso positivo:

```text
Cabo USB para smartphone Samsung
```

Apesar de conter `smartphone`, o item não deve virar `Celulares`.

### Nível 4 — Não classificado

Se não houver confiança suficiente:

```text
categoria_radar = null / não classificado
```

É melhor perder temporariamente uma classificação do que poluir o catálogo com produto incorreto.

---

## 8. Seleção global de categorias

A pessoa poderá escolher quais categorias deseja que façam parte do Radar.

Exemplo:

```text
Categorias acompanhadas

[x] Celulares
[x] PC Gamer
[ ] TVs
[ ] Geladeiras
[ ] Panelas
```

Essas categorias são globais.

Isso significa que `PC Gamer` pode receber produtos de:

- Pichau;
- lojas selecionadas do Banco Inter;
- Kabum no futuro;
- Terabyte no futuro;
- outras fontes futuras.

Desde que cada origem possua mapeamento confiável para `PC Gamer`.

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

Depois, globalmente:

```text
Categorias

[x] Celulares
[x] PC Gamer
```

O resultado pretendido é:

```text
Casas Bahia → somente produtos relevantes de Celulares/PC Gamer
Ponto       → somente produtos relevantes de Celulares/PC Gamer
Samsung     → somente produtos relevantes de Celulares/PC Gamer
Motorola    → somente produtos relevantes de Celulares/PC Gamer
...
```

A loja continua sendo condição necessária para fontes em que a seleção de loja já faz parte do produto.

---

## 10. Fontes sem seleção de lojas

Nem toda fonte precisa ter uma lista de 112 lojas como o Inter.

Exemplo Pichau:

```text
Fonte: Pichau
Categorias acompanhadas:
[x] PC Gamer
[x] Placa de vídeo
[ ] Periféricos
```

Nesse caso:

```text
Pichau
  ↓
Categorias selecionadas
  ↓
Produtos Pichau relevantes
```

Portanto, a regra global é flexível:

```text
Fonte
  ↓
Seleção de loja, se aplicável
  ↓
Seleção de categoria
  ↓
Produto
```

---

## 11. Estratégia de coleta

Existem dois cenários possíveis por fonte.

### Cenário A — Fonte permite filtro confiável antes da coleta

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

### Cenário B — Fonte não permite filtro confiável

Nesse caso:

1. coleta o escopo mínimo necessário disponibilizado pela fonte;
2. classifica localmente;
3. somente publica/persiste o conjunto que pertence às categorias escolhidas, se isso não comprometer integridade e histórico;
4. registra as limitações reais da fonte.

A estratégia deve ser definida por adaptador. Não impor a mesma técnica a todas as fontes.

---

## 12. Evolução da tela Produtos

A página **Produtos permanece como destino principal**.

Ela deixa progressivamente de significar apenas:

```text
Produtos do Compre direto do Inter
```

E passa a representar:

```text
Produtos conhecidos pelo Radar nas fontes configuradas
```

Exemplo de interface conceitual:

```text
Produtos

[Todos] [Celulares] [PC Gamer]

Buscar produto...

Celulares

Motorola Edge 60 Pro
- Casas Bahia / Banco Inter
- Ponto / Banco Inter
- Motorola / Banco Inter

PC Gamer

PC Gamer Ryzen 7 ...
- Pichau
- Casas Bahia / Banco Inter
```

A implementação visual final deve seguir o sistema de design vigente e não este desenho textual.

---

## 13. Filtro por categoria na tela Produtos

A seleção de categoria da tela Produtos é um **filtro de visualização**, não uma nova coleta.

Exemplo:

```text
Todos | Celulares | PC Gamer
```

Ao escolher `Celulares`:

- consulta o banco/API;
- retorna somente produtos classificados como `Celulares`;
- mantém origem da oferta;
- não acessa Inter, Pichau ou outra fonte em tempo real.

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

Quando houver Pichau/Kabum/outras fontes com o mesmo produto, elas podem aparecer também, desde que a classificação e identidade sejam confiáveis.

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

A primeira fase deste plano **não precisa resolver produto canônico entre fontes**.

Inicialmente, Produtos pode continuar exibindo ofertas agrupadas por origem/categoria.

A unificação automática do mesmo produto entre fontes só deve acontecer depois de existir estratégia confiável para:

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
- criar mecanismo de seleção das categorias acompanhadas;
- manter produtos Inter funcionando como hoje.

### Fase 2 — Mapeamento Inter

- estudar categorias reais retornadas pelas lojas selecionadas;
- mapear somente as categorias inicialmente escolhidas;
- não tentar resolver todas as 112 lojas antecipadamente;
- produtos sem mapeamento permanecem não classificados.

### Fase 3 — API de Produtos

Evoluir a busca para aceitar categoria do Radar sem remover imediatamente os contratos atuais.

Exemplo conceitual:

```text
Produtos
- termo
- categoria_radar
- fonte
- loja
- marca
- preço mínimo/máximo
- paginação
```

Os nomes finais dos parâmetros devem respeitar os contratos atuais e ser definidos na implementação.

### Fase 4 — Flutter

- adicionar filtro/seleção de categoria na área Produtos;
- preservar busca, paginação, filtros e rolagem existentes;
- mostrar origem explicitamente;
- não inventar comparação entre fontes sem backend correspondente.

### Fase 5 — Pichau

Adicionar Pichau já usando as categorias oficiais do Radar.

### Fase 6 — Novas fontes

Kabum, Terabyte e outras fontes futuras entram repetindo o mesmo contrato:

```text
categoria externa
  ↓
mapeamento da fonte
  ↓
categoria Radar
```

---

## 18. Taxonomia inicial recomendada

Não implementar uma árvore completa agora.

Começar somente com categorias aprovadas para uso real.

Uma primeira lista candidata para discussão:

- Celulares;
- Notebooks;
- PC Gamer;
- Smartwatches;
- TVs;
- Placas de vídeo;
- Processadores;
- SSD;
- Monitores;
- Teclados;
- Mouses;
- Headsets.

Itens como Panelas, Geladeiras, Air Fryer e outros podem ser adicionados quando houver interesse real de monitoramento.

Essa lista não é decisão final de produto. Deve ser aprovada antes da implementação.

---

## 19. Administração e configuração

Deve existir uma forma autenticada/autorizada de:

- listar categorias do Radar;
- ativar/desativar categorias acompanhadas;
- visualizar categorias não classificadas encontradas nas fontes;
- adicionar/corrigir mapeamentos quando necessário;
- revisar impacto antes de ampliar escopo.

Não é necessário expor edição arbitrária de taxonomia a usuário comum.

A forma exata da administração precisa respeitar os fluxos administrativos já existentes no projeto.

---

## 20. Tratamento de categorias desconhecidas

Quando uma fonte retornar nova categoria externa não mapeada:

1. registrar a categoria externa de forma observável;
2. não criar categoria Radar automaticamente;
3. não classificar produtos por suposição;
4. disponibilizar a pendência para revisão administrativa;
5. adicionar mapeamento somente após decisão.

Exemplo:

```text
Fonte: X
Categoria externa: Telefonia e Comunicação
Estado: não mapeada
```

Depois da revisão:

```text
Telefonia e Comunicação → Celulares
```

ou outra categoria correta.

---

## 21. Testes previstos

### Categorias

- categoria Radar ativa/inativa;
- slug único;
- hierarquia válida quando usada;
- categoria desconhecida não é criada automaticamente.

### Mapeamento

- categoria externa conhecida mapeia corretamente;
- alias da fonte mapeia corretamente;
- categoria desconhecida permanece sem classificação;
- palavra no nome do produto não sobrescreve categoria estruturada confiável;
- falso positivo como `cabo para smartphone` não vira `Celulares`.

### Seleção

- loja não selecionada continua fora da coleta do Inter;
- categoria não selecionada não aparece no catálogo global quando a política da fase exigir filtragem;
- selecionar múltiplas categorias retorna união correta;
- remover categoria não remove outras categorias selecionadas.

### Produtos

- filtro `Celulares` retorna somente ofertas classificadas;
- origem permanece correta;
- busca + categoria funcionam juntas;
- paginação permanece estável;
- filtros existentes continuam funcionando;
- histórico continua associado à oferta correta.

### Regressão

- Livelo não é afetada;
- Cashback Inter não é afetado;
- seleção de lojas do Compre direto continua funcionando;
- produtos Inter existentes permanecem acessíveis durante a migração aditiva.

---

## 22. Observabilidade

A evolução deve permitir responder:

- quantas lojas estão selecionadas por fonte;
- quantas categorias Radar estão ativas;
- quantos produtos foram classificados por categoria;
- quantos ficaram não classificados;
- quais categorias externas ainda não possuem mapeamento;
- quanto cada recorte de coleta custa em páginas/tempo;
- quais fontes permitem filtrar antes da coleta e quais exigem filtragem local.

Esses dados são operacionais e não precisam virar métricas visuais para usuário final sem decisão específica.

---

## 23. Ordem de implementação recomendada

1. Aprovar conceito e nomes: `Categorias`, `Interesses` ou outro termo final de interface.
2. Definir taxonomia inicial mínima.
3. Levantar categorias reais das lojas Inter atualmente selecionadas.
4. Desenhar schema aditivo para categoria Radar e mapeamentos.
5. Implementar domínio e persistência das categorias.
6. Implementar seleção global de categorias.
7. Mapear as primeiras categorias do Inter.
8. Evoluir API de Produtos para filtrar por categoria Radar.
9. Evoluir Flutter Produtos mantendo o design V11.
10. Validar que seleção de lojas continua intacta.
11. Implementar Pichau já no novo modelo.
12. Medir redução de volume e custo de coleta.
13. Somente depois discutir produto canônico e comparação automática entre lojas/fontes.

---

## 24. Critérios de aceite

A evolução inicial estará pronta quando:

- seleção de lojas do Inter continuar funcionando como antes;
- existir catálogo controlado de categorias Radar;
- for possível selecionar mais de uma categoria;
- categorias externas das fontes puderem ser mapeadas para categorias Radar;
- produto desconhecido puder permanecer não classificado;
- tela Produtos puder filtrar pelas categorias escolhidas sem consultar fontes ao vivo;
- origem de cada produto/oferta permanecer explícita;
- busca, filtros, paginação e histórico existentes não sofrerem regressão;
- Pichau puder ser adicionada ao mesmo modelo sem alterar a taxonomia global;
- Livelo e Cashback Inter continuarem isolados;
- testes diretamente afetados passarem.

---

## 25. Decisões pendentes antes de implementação

- nome de interface: `Categorias`, `Interesses`, `Coleções` ou outro;
- primeiras categorias realmente necessárias;
- se categoria pai será necessária já na primeira versão;
- onde a seleção global de categorias ficará no Flutter;
- se a filtragem ocorre antes da coleta, depois da coleta ou de forma híbrida em cada fonte;
- política de retenção para produtos que deixam de pertencer ao escopo selecionado;
- como administrar categorias externas não mapeadas;
- quando iniciar a etapa de produto canônico entre fontes.

Nenhuma dessas decisões deve ser resolvida por suposição durante a implementação. O objetivo deste plano é preservar a lógica atual e adicionar uma camada global de interesse de forma controlada e extensível.
