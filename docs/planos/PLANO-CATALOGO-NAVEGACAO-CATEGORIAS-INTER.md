# Plano — Catálogo navegável de categorias do Shopping Inter

**Estado:** proposta baseada em leitura real do catálogo; nenhuma alteração de API, banco, robô ou Flutter foi feita por este plano.

**Leitura realizada em:** 04/09/2026, em transação `READ ONLY` sobre o catálogo ativo das lojas diretas selecionadas e ativas.

## 1. Problema a resolver

O Shopping Inter envia a categoria externa de cada produto em `categoryName` ou, quando necessário, no primeiro `sku.categoryName`. Esse valor é a fonte funcional oficial do Radar e deve continuar sendo preservado exatamente como veio da origem.

O problema não é a falta de categoria: é volume e heterogeneidade. Uma lista plana com centenas de valores é correta, mas não é uma forma boa de a pessoa encontrar uma categoria na interface mobile.

Não é objetivo deste plano alterar a categoria de um produto, deduzir uma categoria pelo nome, criar equivalências automáticas ou substituir a taxonomia do Inter.

## 2. Fotografia real do catálogo

A consulta considerou somente:

- `produto_direto_inter.ativo = TRUE`;
- lojas `selecionada = TRUE`;
- lojas `ativa = TRUE`;
- `NULL`, vazio ou somente espaços como o agrupamento funcional `Sem categoria`.

| Medida | Resultado |
|---|---:|
| Produtos ativos consultáveis | 9.436 |
| Categorias externas distintas | 513 |
| Categorias com 10 ou mais produtos | 204 |
| Categorias com somente um produto | 88 |
| Categorias com menos de cinco produtos | 226 |
| Categorias presentes em somente uma loja | 295 |
| Categorias com 50 ou mais produtos | 48 |
| Categorias com 100 ou mais produtos | 18 |

Os valores mais frequentes já mostram por que não existe uma hierarquia segura apenas pelo texto: `Mercado` tem 331 produtos, `Android` 272, `Biscoito` 258, `Cozinha Modulada` 215, `Balas e Drops` 197 e `2 Portas` 90. Alguns são departamentos, outros são tipo de produto e outros são atributos. O Radar não pode inferir que `Android` pertence a uma categoria pai, nem que `2 Portas` deve ser unido a geladeiras.

### 2.1 Cobertura acumulada

| Cobertura dos produtos ativos | Número de categorias necessárias |
|---|---:|
| 50% | 42 |
| 70% | 94 |
| 80% | 138 |
| 90% | 216 |

As 40 categorias mais frequentes cobrem somente 48,88% dos produtos. Portanto, uma tela que mostre apenas “categorias populares” esconderia mais da metade do catálogo e não pode ser a única navegação.

> **Substituído como direção de UX em 04/09/2026.** A proposta de uma lista
> alfabética com categorias frequentes continua sendo uma alternativa técnica
> para expor os valores brutos, mas não é a jornada escolhida para evoluir o
> produto. A proposta atual, o inventário integral e a justificativa estão em
> [`CATALOGO-CATEGORIAS-INTER-AGRUPAMENTO-PROPOSTO.md`](CATALOGO-CATEGORIAS-INTER-AGRUPAMENTO-PROPOSTO.md).
>
> Nenhuma das duas propostas foi implementada neste momento.

## 3. Proposta anterior (não seguir para implementação)

Criar uma camada de **navegação**, não uma nova taxonomia.

Cada item continua identificado pelo valor externo exato do Inter. A camada adicional só apresenta esse mesmo valor com informações de uso:

- nome externo exato;
- quantidade de produtos ativos;
- quantidade de lojas selecionadas que o possuem;
- ordem por relevância ou por letra;
- `Sem categoria` somente quando houver produto realmente sem categoria na origem.

Nenhum item recebe categoria pai, slug interno, tradução, sinônimo, classificação automática ou mapeamento editorial.

## 4. Jornada mobile proposta

O controle atual “Categoria nesta tela” continua separado do modal de Lojas e preço.

1. Estado inicial: mostra `Todas`.
2. Toque no controle: abre um seletor próprio de categorias, ocupando tela suficiente para navegação; não usar uma folha curta com centenas de chips.
3. Primeiro bloco: **Mais frequentes**, com as categorias de maior quantidade e a contagem visível. Esse bloco é um atalho, não um limite.
4. Segundo bloco: **Explorar todas**, organizado alfabeticamente por letras. A pessoa toca uma letra e escolhe uma categoria exata da lista correspondente.
5. Ações fixas: `Todas as categorias` e, quando aplicável, `Sem categoria`.
6. Ao confirmar, o app envia o valor externo exato já retornado pela API e preserva busca, página e posição útil da lista de produtos.

A interação continua sendo de escolha, sem campo livre que aceite uma categoria inexistente. Se, no futuro, a navegação por letras se mostrar insuficiente, uma busca local dentro do seletor pode ser discutida separadamente; ela não pode consultar o Inter nem alterar o valor enviado ao filtro.

## 5. Contrato de dados necessário

O endpoint de categorias deve continuar derivado somente dos produtos ativos das lojas selecionadas. Para permitir a navegação proposta, cada categoria deve incluir:

```text
valor                 valor externo exato; NULL somente para ausência na origem
nome                  valor para exibição; “Sem categoria” somente no fallback
produtos_ativos       contagem de produtos ativos nesse valor
lojas_com_produtos    contagem distinta de lojas selecionadas
selecionada           preferência já existente, quando aplicável
```

Ordenações permitidas:

- `relevancia`: `produtos_ativos DESC`, depois nome externo;
- `alfabetica`: nome externo, sem alterar sua identidade;
- `Sem categoria`: sempre como ação funcional própria, não como texto gravado no produto.

O catálogo de produtos continua paginado. A lista de categorias é metadado de navegação e deve ser paginada ou carregada por letra caso o volume cresça além do aceitável para o mobile.

## 6. O que permanece proibido

- Agrupar `Android`, `Celulares` e `Smartphones` como se fossem equivalentes.
- Tratar `2 Portas` como categoria de geladeira por inferência.
- Criar uma categoria interna “Eletrônicos”, “Casa” ou “Moda” e mover produtos automaticamente para ela.
- Esconder categorias com poucos produtos.
- Fazer produto sem categoria desaparecer.
- Consultar a fonte externa durante a navegação ou a digitação.
- Usar `double` para qualquer dado monetário.

## 7. Próximas etapas, após aprovação

1. Ajustar o contrato de leitura de categorias para devolver contagens reais e testar a query agregada.
2. Atualizar o seletor mobile para os blocos “Mais frequentes” e “Explorar todas por letra”.
3. Cobrir widgets para: lista grande, categoria nova, categoria de um produto, `Sem categoria`, troca de loja e preservação de posição.
4. Validar manualmente com o catálogo real antes de remover qualquer caminho antigo.

## 8. Critérios de aceite

- As 513 categorias atuais continuam acessíveis, inclusive as 88 com um único produto.
- Uma categoria nova do Inter aparece sem migration, enum ou release do aplicativo.
- A pessoa consegue chegar a uma categoria rara sem digitar texto livre nem percorrer centenas de chips em uma folha curta.
- O filtro chega ao endpoint como valor externo exato.
- A categoria não altera seleção de lojas, coleta, preço, cashback, paginação nem histórico.
- A interface não inventa parentesco entre categorias externas.
