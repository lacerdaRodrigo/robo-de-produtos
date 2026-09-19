# Dependências de backend para o mobile V15

## Registro desta branch

Esta branch altera somente o cliente Flutter e sua documentação. Nenhum
arquivo do backend, migration, workflow, ambiente ou publicação foi alterado.

## Lacuna encontrada — lista consolidada de acompanhamentos

O novo destino `Meu radar` precisa, quando o contrato estiver disponível, de
uma leitura autenticada, paginada e consolidada dos acompanhamentos pessoais
do usuário. A resposta deve distinguir pelo menos:

- origem: Livelo, Inter Sites parceiros, Inter Compre direto ou Pichau;
- identificador e nome exibível da entidade;
- tipo de entidade, estado/atividade e link de continuação quando aplicável;
- paginação, total e estado de ausência, parcialidade ou falha.

Hoje a API fornece contagens agregadas em `/api/resumo`, eventos em
`/api/alertas` e mutações por origem em endpoints especializados. Esses
contratos não permitem montar uma lista única sem inventar dados ou consultar
fontes externas no cliente. O Flutter, portanto, mostra apenas as contagens
reais que já chegam no resumo e encaminha a pessoa para Explorar/Alertas.

## Lacuna encontrada — detalhe ilustrativo da Home

O protótipo V15 apresenta na Home uma composição de produto, preço anterior e
preço atual. A resposta atual de `/api/resumo` entrega atividade recente e
contagens por origem, mas não entrega um item/preço real suficiente para
preencher essa composição. O Flutter mantém a hierarquia visual, usa a
atividade real quando disponível e não promove o produto/preço do protótipo a
dado de produção.

Para fechar a paridade visual com dados reais, a API deverá definir um campo de
atividade recente com origem, nome exibível, identificador, valor anterior,
valor atual, unidade, direção, estado de qualidade e instante da coleta. O
contrato deve manter valores financeiros como texto decimal exato; o cliente
não deve recalcular dinheiro com `double`.

## Trabalho necessário fora desta tarefa

1. Definir o contrato no PRD aplicável da Central de Alertas e dos domínios,
   incluindo autorização, ordenação, filtros e paginação.
2. Implementar e testar a rota agregada na API, sem unir Livelo, Inter Sites
   parceiros, Inter Compre direto e Pichau em uma única regra de domínio.
3. Só então acrescentar o modelo Dart e substituir o resumo por uma lista
   paginada no `Meu radar`.

Essa decisão exige alteração de backend e permanece pendente; não foi criada
uma rota fictícia nesta migração.

## Gates externos ainda pendentes

- comparação manual das telas Flutter com `design-app/mobile-v15/index.html`;
- validação em Android físico, incluindo texto em 200%, claro/escuro e
  estados de erro/offline;
- ícone, splash nativo e aceite operacional do aparelho dedicado quando a
  entrega for distribuída.
