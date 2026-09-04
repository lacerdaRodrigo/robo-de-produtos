# Validação do plano de Produtos contra o Design Mobile V11

Data da validação: 3 de setembro de 2026.

Documentos confrontados:

- `AGENTS.md`;
- `design-app/SISTEMA-DESIGN-MOBILE-V11.md`;
- `design-app/prototipo-mobile-redesign-novo-11.html`;
- `docs/planos/PLANO-MODIFICACAO-PRODUTOS.md`.

Protótipo experimental produzido:

- `design-app/prototipo-mobile-redesign-novo-11-produtos-categorias.html`.

## A. Resumo executivo

O plano **cabe no V11 com ajustes visuais**.

Não foi necessário criar uma nova tela para validar a hipótese. A configuração persistente de `Categorias acompanhadas` foi acomodada no fluxo existente `Banco Inter > Compre direto`, por meio de um resumo compacto e de um bottom sheet hierárquico. A tela `Produtos` continuou sendo a tela existente e recebeu uma seleção de categoria claramente identificada como filtro temporário.

A solução experimental mantém estes conceitos separados:

1. lojas selecionadas definem de quais lojas do Banco Inter podem vir as ofertas;
2. categorias acompanhadas representam o interesse persistente da pessoa nessas lojas;
3. a categoria escolhida em `Produtos` somente filtra o catálogo já salvo;
4. cada oferta continua independente e conserva a loja de origem.

Não existe uma decisão bloqueante para continuar testando o protótipo HTML. Antes de implementar no Flutter, ainda é necessário aprovar formalmente o local proposto para `Categorias acompanhadas` e dispor do contrato de API autorizado.

## B. Mapa do fluxo atual

### V11 de referência antes da evolução experimental

```text
Autenticação
  ↓
Resumo
  ├── Serviços
  │     └── Banco Inter
  │           ├── Cashback
  │           └── Compre direto
  │                 ├── buscar loja
  │                 ├── ver todas/selecionadas
  │                 ├── selecionar loja
  │                 └── solicitar atualização
  └── Produtos
        ├── buscar no catálogo salvo
        ├── filtrar resultados
        ├── ver ofertas agrupadas por loja
        └── abrir oferta/histórico
```

O V11 já separava `Cashback Inter` de `Compre direto` e já possuía seleção de lojas em `Compre direto`. A tela `Produtos` já era um destino próprio na navegação inferior. Porém, o protótipo não possuía uma configuração persistente de categorias nem uma hierarquia de categorias.

### Fluxo acrescentado somente à cópia experimental

```text
Banco Inter
  ↓
Compre direto
  ├── Categorias acompanhadas → configurar árvore persistente
  └── Lojas → manter seleção existente
        ↓
Produtos
  ├── origem: lojas selecionadas · Banco Inter
  ├── categoria nesta tela → filtro temporário hierárquico
  ├── busca no catálogo salvo
  └── ofertas separadas por loja
```

Não foi criado onboarding, assistente em etapas nem nova área de produto.

## C. Plano versus protótipo

| Necessidade | V11 atual | Situação | Proposta validada na cópia experimental |
| --- | --- | --- | --- |
| Banco Inter continua escolhendo lojas | Já existe em `Banco Inter > Compre direto`, com busca, abas `Todas/Selecionadas` e ação de seleção | `OK` | Preservar integralmente o fluxo e seus componentes |
| Categorias acompanhadas | Não existe no HTML de referência | `AJUSTE VISUAL` | Resumo compacto em `Compre direto` abrindo bottom sheet; não criar tela nova |
| Lojas e categorias como camadas diferentes | Só a camada de lojas está representada | `AJUSTE VISUAL` | Textos e localização deixam explícito que as categorias se aplicam às lojas selecionadas |
| Categorias acompanhadas versus filtro temporário | A distinção não existe no V11 original | `CONFLITO COM V11` | Usar nomes, subtítulos e componentes diferentes; o filtro em `Produtos` declara que não altera o acompanhamento |
| Hierarquia pai/filha | Não existe | `AJUSTE VISUAL` | Árvore vertical recolhível, com recuo e linhas de agrupamento, adequada a telas pequenas |
| Seleção de categoria pai | Não existe | `AJUSTE VISUAL` | Checkbox com estado completo/parcial na configuração persistente; categoria pai do filtro inclui descendentes |
| Escala além de quatro categorias | Chips horizontais não escalam para uma taxonomia grande | `AJUSTE VISUAL` | Evitar carrossel de chips; usar grupos recolhíveis em região vertical rolável |
| Tela Produtos continua sendo a existente | Já existe na navegação principal | `OK` | Evoluir a própria tela; nenhuma nova tela de catálogo foi criada |
| Ofertas de lojas diferentes separadas | O agrupamento visual por loja já existe | `OK` | Repetir a oferta em cartões independentes sob Casas Bahia e Ponto; não criar produto canônico |
| Origem da oferta | A loja aparece no cabeçalho do grupo, mas não estava inequívoca em cada cartão | `AJUSTE VISUAL` | Mostrar `Loja · Banco Inter` em cada oferta e manter o grupo da loja |
| Busca no catálogo persistido | Campo e ação já existem | `OK` com ajuste de estados | Reforçar no carregamento que não há consulta ao Inter em tempo real |
| Busca sem resultado | Existe estado vazio genérico | `AJUSTE VISUAL` | Mensagem específica para nenhuma oferta e mínimo de dois caracteres |
| Falha e nova tentativa | Não havia demonstração completa no fluxo de Produtos | `AJUSTE VISUAL` | Preservar resultados anteriores, manter termo/filtros e oferecer `Tentar novamente` |
| Carregando | Não estava demonstrado nessa interação | `AJUSTE VISUAL` | Feedback local entre envio da busca e atualização da lista |
| Sucesso | A lista de resultados já representa o estado de sucesso | `OK` | Preservar cartões e paginação conceitual sem adicionar métrica |
| Parcial | O Design System prevê aviso parcial | `OK` com ajuste de texto | Aviso não bloqueante preservando o último catálogo válido |
| Atrasado/desatualizado | O sistema prevê distinção, mas a origem não estava exemplificada por loja | `AJUSTE VISUAL` | Marcar o retrato da loja Ponto como desatualizado sem convertê-lo em vazio ou erro |
| Claro, escuro e telas pequenas | São requisitos do V11 | `OK` | Novos elementos usam exclusivamente os tokens do V11 e foram verificados em 320 px e 430 px |
| Dados de categorias vindos de contrato | Ainda não há contrato implementado para essa evolução | `DEPENDÊNCIA DE BACKEND` | O HTML usa poucos exemplos ilustrativos; Flutter futuro não deve hardcodar a taxonomia |

## D. Decisões de produto realmente necessárias

### 1. Aprovar o local definitivo de Categorias acompanhadas no Flutter

O experimento propõe:

```text
Banco Inter > Compre direto
  └── cartão-resumo Categorias acompanhadas
        └── bottom sheet de configuração
```

Vantagens:

- reutiliza tela, navegação e bottom sheet existentes;
- mantém lojas e categorias no mesmo contexto do `Compre direto`;
- não polui a tela `Produtos` com configuração persistente;
- evita criar uma nova tela.

Limitação:

- o V11 original não especifica esse ponto de entrada; a cópia apenas valida que ele cabe visualmente.

Essa proposta precisa de aprovação antes de virar Flutter.

### 2. Definir o efeito de salvar zero categorias

O plano não determina se uma seleção vazia significa `nenhum interesse ativo` ou se deve ser impedida. O protótipo não inventa validação para isso. A regra deve ser fechada antes do contrato e da implementação.

### 3. Confirmar o nome de interface

O protótipo utiliza `Categorias acompanhadas` porque é a expressão mais clara para separar configuração persistente de filtro temporário. O plano ainda lista a nomenclatura final como pendente. Se outro nome for escolhido, deve preservar essa distinção semântica.

### 4. Reavaliar o componente somente com o volume real da taxonomia

A árvore recolhível suporta poucas ou dezenas de categorias e nomes longos sem depender de carrossel. Se o contrato real trouxer centenas de categorias irmãs no mesmo nível, será necessário decidir se a configuração recebe busca interna ou outro mecanismo. Nenhum desses recursos foi inventado nesta etapa.

## E. Alterações feitas no protótipo

### `design-app/prototipo-mobile-redesign-novo-11-produtos-categorias.html`

Foi criada uma cópia experimental; o HTML V11 de referência foi preservado.

Alterações em `Banco Inter > Compre direto`:

- cartão-resumo `Categorias acompanhadas`;
- bottom sheet de configuração persistente;
- categorias pai e filhas recolhíveis;
- checkboxes com estados selecionado, não selecionado e parcial;
- seleção de um pai refletida nos descendentes demonstrados;
- resumo da quantidade acompanhada após salvar;
- amostra de lojas alinhada às ofertas exibidas: Casas Bahia e Ponto selecionadas, Amazon não selecionada;
- seleção/desmarcação de loja refletida na origem e nos resultados de `Produtos`.

Alterações em `Produtos`:

- resumo das lojas selecionadas com origem `Banco Inter`;
- acesso de volta à seleção de lojas existente;
- controle `Categoria nesta tela`, identificado como filtro temporário;
- bottom sheet hierárquico de filtro por categoria;
- pesquisa explícita no catálogo salvo;
- ofertas agrupadas por loja de origem;
- `Casas Bahia · Banco Inter` ou `Ponto · Banco Inter` dentro de cada cartão;
- duas ofertas chamadas `Motorola Edge 60 Pro` mantidas em cartões diferentes;
- cabo USB-C classificado visualmente em `Cabos`, e não em `Celulares`;
- exemplos mínimos de TV e geladeira para validar outras categorias;
- estados carregando, sucesso, vazio, erro recuperável, parcial e desatualizado;
- erro preservando a última lista válida;
- ação `Tentar novamente` preservando busca e filtros.

Alterações de estilo:

- somente tokens, cores, raios, sombras e padrões já definidos pelo V11;
- árvore vertical rolável em vez de carrossel extenso de chips;
- suporte a claro/escuro;
- nenhuma largura horizontal excedente em 320 px e 430 px.

### `docs/planos/RELATORIO-VALIDACAO-V11-PRODUTOS-CATEGORIAS.md`

- registro do diagnóstico, conflitos, decisões, fluxos, riscos e validações desta etapa.

## F. Fluxo final proposto

### Fluxo 1 — lojas e categorias acompanhadas

```text
Serviços
  → Banco Inter
  → Compre direto
  → selecionar lojas
  → Configurar em Categorias acompanhadas
  → expandir/recolher grupos
  → selecionar pais ou folhas
  → Salvar categorias
```

A ordem não é imposta por onboarding: são duas configurações persistentes revisitáveis na mesma área.

### Fluxo 2 — visualizar todas as ofertas persistidas

```text
Produtos
  → Categoria nesta tela: Todas
  → ofertas separadas e agrupadas por loja
```

### Fluxo 3 — filtrar temporariamente por categoria

```text
Produtos
  → Categoria nesta tela
  → escolher categoria
  → Ver ofertas
```

O texto do componente e do bottom sheet informa que o acompanhamento persistente não é alterado.

### Fluxo 4 — buscar oferta

```text
Produtos
  → informar termo
  → Buscar
  → carregando
  → resultados do catálogo salvo
```

Ao buscar `Motorola`, Casas Bahia e Ponto permanecem em grupos separados e cada cartão mostra sua origem.

### Fluxo 5 — categoria pai e descendentes

Na configuração persistente, o checkbox pai marca as folhas demonstradas e pode mostrar estado parcial. No filtro temporário, escolher um pai inclui ofertas classificadas em suas categorias descendentes.

### Fluxo 6 — busca sem resultado

Um termo sem correspondência produz estado vazio, sem transformá-lo em erro ou iniciar coleta externa.

### Fluxo 7 — erro e nova tentativa

Para demonstração no HTML, digitar `erro` e executar a busca exibe o erro recuperável. A lista anterior permanece visível. `Tentar novamente` mantém o termo e os filtros; a nova resposta do protótipo vira vazio porque não existe oferta ilustrativa com esse termo.

O gatilho `erro` é exclusivamente uma fixture visual do protótipo e não representa regra, termo reservado ou contrato futuro.

## G. Riscos e dependências

- `DEPENDÊNCIA DE BACKEND`: a taxonomia, hierarquia, categorias disponíveis e seleção persistida precisam vir de contrato autorizado; não podem ser enum fixo no Flutter.
- `DEPENDÊNCIA DE BACKEND`: cada oferta precisa entregar categoria Radar, loja de origem e origem Inter de maneira confiável.
- `DEPENDÊNCIA DE BACKEND`: vazio, erro, parcial e atrasado precisam continuar semanticamente distintos na resposta da API.
- `DEPENDÊNCIA DE BACKEND`: a nova tentativa automática prevista no plano e seus limites devem respeitar a política real. O HTML demonstra o feedback visual e a tentativa manual, não implementa política de rede.
- `DEPENDÊNCIA DE BACKEND`: paginação continua obrigatória. A amostra local não autoriza carregar catálogo completo no Flutter.
- `DECISÃO DE PRODUTO`: aprovar o ponto de entrada experimental de categorias acompanhadas antes de implementar a tela real.
- `DECISÃO DE PRODUTO`: resolver seleção vazia e nomenclatura final.
- `AJUSTE VISUAL FUTURO`: confirmar com a taxonomia real se a árvore recolhível basta ou se o volume exige um recurso adicional aprovado.
- Os preços, percentuais, datas e produtos da cópia são ilustrativos; não são contrato nem dado real.
- O protótipo não resolve ofertas sem classificação. Conforme o plano, elas ficam na fila operacional e não devem receber categoria visual inventada.
- O protótipo não resolve reclassificação, retenção, coleta compartilhada, identidade de SKU ou produto canônico.

## Análise de UX obrigatória

1. **A diferença entre loja acompanhada e categoria acompanhada está clara?** Sim. As lojas continuam sendo cartões selecionáveis; as categorias aparecem como configuração global aplicada às lojas selecionadas.
2. **A diferença entre categoria acompanhada e filtro temporário está clara?** Sim. Os dois componentes têm títulos, subtítulos, controles e contextos diferentes. O filtro repete explicitamente que não muda o acompanhamento nem inicia coleta.
3. **Existe etapa redundante?** Não. A configuração persistente fica no Inter e a consulta temporária fica em Produtos. Não foi criado onboarding ou confirmação duplicada.
4. **O usuário entende de onde veio cada oferta?** Sim. A origem aparece no resumo da página, no agrupamento por loja e dentro de cada cartão.
5. **Existe risco de parecer que ofertas de lojas diferentes são um único produto?** O risco foi reduzido: nomes iguais aparecem em cartões e grupos independentes. Não há cartão pai, comparação automática ou agrupamento canônico.
6. **O fluxo ficou mais poluído que o V11 atual?** Houve aumento pequeno de densidade em `Compre direto`, limitado a um cartão-resumo. Em `Produtos`, um controle compacto substitui a ideia de muitos chips horizontais.
7. **Existe solução mais simples usando componentes existentes?** Esta é a solução mais simples encontrada: tela existente, cartão do mesmo vocabulário visual e bottom sheet já utilizado pelo V11.
8. **O design continua funcionando com muitas categorias?** A estrutura vertical recolhível suporta crescimento e nomes maiores melhor que chips. Centenas de irmãs no mesmo nível ainda exigem validação com dados reais.
9. **O fluxo pai/filha é compreensível?** Sim. Recuo, expansão, estado parcial e textos auxiliares comunicam a relação. O filtro temporário informa que um pai inclui suas filhas.
10. **Há decisão que o protótipo não resolve sozinho?** Sim: aprovação do ponto de entrada no Flutter, seleção vazia, nome final e eventual mecanismo para uma taxonomia extrema.

## Validações executadas

- sintaxe do JavaScript embutido verificada com `node --check`;
- execução em Google Chrome headless sem exceções JavaScript;
- fluxo `Produtos → filtro de categoria → Acessórios para celulares` retornando somente o cabo da amostra;
- fluxo de busca por `Motorola` retornando duas ofertas independentes, Casas Bahia e Ponto;
- fluxo de erro preservando duas ofertas anteriores e mantendo o termo;
- fluxo de nova tentativa mantendo o termo e diferenciando resposta vazia de erro;
- fluxo `Escolher lojas` abrindo `Banco Inter > Compre direto`;
- desmarcar Ponto atualizando a origem para `Casas Bahia · Banco Inter` e removendo da lista as ofertas da loja desmarcada;
- seleção de categoria pai marcando as seis folhas demonstradas;
- atualização do resumo após salvar categorias;
- nome de categoria longo quebrando em múltiplas linhas sem overflow em 320 px;
- árvore longa rolando até as ações finais e reabrindo sempre no início do conteúdo;
- claro em 320 px e escuro em 430 px;
- nenhum overflow horizontal detectado nas telas Produtos, Compre direto e nos dois bottom sheets em 320 px;
- nenhuma suíte de testes Flutter/Web, golden, integração, E2E ou regressão visual automatizada foi criada ou executada; a verificação no Chrome foi somente a inspeção local do protótipo desta etapa.

## H. O que não foi alterado

- Flutter não foi alterado;
- backend não foi alterado;
- banco e schema não foram alterados;
- robô/coletor não foi alterado;
- workflows não foram alterados;
- produção e publicação não foram alteradas;
- contratos e endpoints não foram inventados;
- filtros comerciais novos não foram criados;
- comparação entre lojas não foi criada;
- produto canônico não foi criado;
- painel ou fluxo administrativo novo não foi criado;
- o Design System V11 não foi reescrito;
- `design-app/prototipo-mobile-redesign-novo-11.html` permaneceu como referência intacta.
