# Validação das categorias vindas do JSON do Shopping Inter — 2026-09-04

## Objetivo

Registrar a prova em produção de que as categorias dos produtos do Shopping Inter já são entregues pela própria resposta JSON do Inter e persistidas no campo antigo `produto_direto_inter.categoria`.

Esta validação foi feita deliberadamente **sem usar como referência o módulo de categorização criado posteriormente no Radar**.

## Escopo da validação

A análise considera somente o fluxo:

```text
JSON do Shopping Inter
    ↓
item.categoryName ou sku.categoryName
    ↓
ProdutoDiretoInter.categoria
    ↓
produto_direto_inter.categoria
```

Não foram usados para concluir esta validação:

- `categoria_radar`;
- `categoria_externa_loja_inter`;
- `mapeamento_categoria_loja_inter`;
- `categoria_radar_id`;
- `categoria_externa_loja_inter_id`;
- `estado_classificacao`;
- qualquer regra de classificação, inferência ou mapeamento criada no trabalho posterior de categorias.

## Execução observada

Foi disparado manualmente o workflow `shopping-inter` na branch `main`.

Dados da execução:

- GitHub Actions run: **#98**;
- run ID: **33881332856**;
- evento: `workflow_dispatch`;
- branch: `main`;
- commit: `d48d0135b6973f71968fc478ae71bac0a36f458a`;
- versão do robô: **1.53.1**;
- execução no banco: **ID 13**;
- iniciada em: **2026-09-04T14:02:20.102Z**;
- concluída em: **2026-09-04T14:11:47.931Z**;
- estado final: **sucesso**;
- lojas planejadas: **6**;
- lojas com sucesso: **6**;
- lojas com falha: **0**.

## Evidência no código executado

No commit executado pela rodada, o extrator usa diretamente o conteúdo recebido no JSON do Inter:

```python
categoria=_texto_opcional(
    item.get("categoryName") or sku.get("categoryName"),
    MAX_TEXTO,
)
```

Portanto, a categoria externa é obtida nesta ordem:

1. `item.categoryName`;
2. se ausente, `sku.categoryName` do primeiro SKU válido;
3. se ambos estiverem ausentes, a categoria fica `None`.

Não há inferência por nome, marca, descrição ou taxonomia Radar nesse ponto do fluxo.

## Resultado por loja

| Loja | Produtos lidos | Produtos únicos/publicados | Duplicados | Com categoria | Sem categoria | Categorias distintas |
|---|---:|---:|---:|---:|---:|---:|
| Acer | 53 | 53 | 0 | 53 | 0 | 4 |
| Casa & Vídeo | 1.318 | 1.310 | 8 | 1.310 | 0 | 204 |
| Casas Bahia | 2.580 | 2.355 | 225 | 2.355 | 0 | 199 |
| Drogaria Araujo | 3.050 | 3.029 | 21 | 3.029 | 0 | 170 |
| Natura | 463 | 463 | 0 | 463 | 0 | 34 |
| Ponto | 2.581 | 2.355 | 226 | 2.355 | 0 | 196 |
| **Total de produtos únicos/publicados** | — | **9.565** | — | **9.565** | **0** | **510 globais** |

### Resultado principal

Dos **9.565 produtos únicos/publicados** nessa rodada:

- **9.565** estavam com `produto_direto_inter.categoria` preenchida;
- **0** estavam sem categoria;
- cobertura observada: **100%**;
- foram encontradas **510 strings de categoria distintas** entre as seis lojas.

A quantidade de categorias por loja não deve ser somada, porque uma mesma string pode aparecer em mais de uma loja.

## Exemplo completo: Acer

Os 53 produtos da Acer foram distribuídos em exatamente quatro categorias externas:

| Categoria | Produtos |
|---|---:|
| Monitores | 24 |
| Notebooks gamer | 14 |
| Acessórios e Periféricos | 11 |
| Notebooks | 4 |
| **Total** | **53** |

## Exemplos reais das categorias observadas na rodada

Abaixo estão exemplos consultados diretamente no campo externo `produto_direto_inter.categoria` após a execução:

| Categoria | Produtos |
|---|---:|
| Android | 386 |
| Mercado | 331 |
| Biscoito | 258 |
| Cozinha Modulada | 217 |
| Balas e Drops | 197 |
| Perfumes | 183 |
| Chocolate | 140 |
| Absorvente | 135 |
| Aparelhos de Depilação | 132 |
| Balcões e Fruteiras | 129 |
| Cozinhas | 128 |
| Fritadeiras | 127 |
| Cozinha Compacta | 124 |
| Salgadinhos e snacks | 122 |
| Smart TV | 120 |
| Secadores de Cabelo | 112 |
| Suplementos e Vitaminas | 103 |
| Pneus | 102 |
| Sofás | 102 |
| Pneus, Rodas e Calotas | 100 |
| Batom | 96 |
| Caixas Acústicas | 93 |
| Base | 91 |
| Conjuntos de Mesas e Cadeiras de Jantar | 90 |
| Corpo e Banho | 87 |
| Guarda-roupas e Roupeiros | 87 |
| Liquidificadores | 84 |
| Racks e Painéis | 78 |
| Fantasias e Acessórios | 76 |
| 2 Portas | 74 |

Também foram observadas categorias específicas como `Smartphones`, `Celulares`, `TVs`, `Notebooks`, `Micro-ondas`, `Ferramentas Manuais`, `Panelas de Pressão`, `Toalhas de Banho`, `Brinquedos`, entre muitas outras.

## Conclusão

A execução de 2026-09-04 confirma em produção que o Shopping Inter fornece informação de categoria no JSON consumido pelo robô e que o fluxo existente persiste essa informação em `produto_direto_inter.categoria`.

Nesta rodada, a informação externa foi suficiente para preencher a categoria de **100% dos 9.565 produtos publicados**, produzindo **510 categorias distintas**.

Isso significa que a origem externa já possui uma taxonomia rica e granular. Qualquer taxonomia própria do Radar deve ser tratada como uma camada separada de organização/mapeamento e não como substituta da categoria original entregue pelo Inter.

A categoria original deve continuar preservada como dado de origem.

## Ressalva histórica

Esta validação prova:

- o comportamento do robô no commit `d48d0135...`;
- a origem da categoria no JSON do Inter;
- os valores e a cobertura observados na execução ID 13 em 2026-09-04.

Ela **não prova que as mesmas 510 strings estavam presentes exatamente na execução de 2026-09-02**, porque `produto_direto_inter.categoria` é um campo mutável atualizado por coletas posteriores e não existe snapshot preservado daquele instante.

A execução de 2026-09-04 serve, portanto, como prova atual e reproduzível da origem e persistência das categorias externas.
