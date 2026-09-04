# Plano de ação temporário — Produtos e Categorias no Mobile V11

> **DOCUMENTO TEMPORÁRIO DE EXECUÇÃO**
>
> Este arquivo é um checklist operacional. Ele não substitui o plano funcional nem o Design System e **deve ser excluído quando todas as etapas autorizadas estiverem concluídas e validadas**.
>
> Arquivo a excluir no encerramento: `docs/planos/PLANO-ACAO-TEMPORARIO-PRODUTOS-CATEGORIAS-V11.md`.

## 1. Objetivo

Orientar, em etapas pequenas e verificáveis, a futura implementação Flutter da evolução de Produtos e Categorias validada no protótipo experimental do Mobile V11.

O resultado pretendido é:

```text
Banco Inter
  → lojas selecionadas
  → categorias acompanhadas
  → ofertas relevantes

Produtos
  → catálogo persistido
  → filtro temporário de categoria
  → ofertas independentes com loja de origem
```

Este plano não autoriza alterações de backend, banco, schema, robô, workflows, Web ou produção.

## 2. Fontes de verdade

Usar nesta ordem:

1. regras de execução: `AGENTS.md`;
2. regras funcionais: `docs/planos/PLANO-MODIFICACAO-PRODUTOS.md`;
3. contrato visual: `design-app/SISTEMA-DESIGN-MOBILE-V11.md`;
4. referência visual original: `design-app/prototipo-mobile-redesign-novo-11.html`;
5. referência visual desta evolução: `design-app/prototipo-mobile-redesign-novo-11-produtos-categorias.html`;
6. diagnóstico: `docs/planos/RELATORIO-VALIDACAO-V11-PRODUTOS-CATEGORIAS.md`;
7. contratos reais disponíveis em `app/lib/core/api/`.

O protótipo experimental orienta montagem, hierarquia, espaçamento, estados e fluxo. Seus produtos, categorias, lojas, valores e datas são ilustrativos e não podem virar fixtures de produção ou enum fechado.

## 3. Referências diretas do protótipo

| Elemento | Referência no HTML experimental | Resultado esperado no Flutter |
| --- | --- | --- |
| Cartão de categorias acompanhadas | linhas 336–341 e 599–603 | Resumo compacto dentro de `Banco Inter > Compre direto` |
| Controle de categoria temporária | linhas 342–348 e 625–628 | Controle separado dos demais filtros em `Produtos` |
| Estados de carregamento e erro | linhas 353–361 e 630–632 | Feedback local, retry e preservação de contexto |
| Árvore pai/filha | linhas 398–418 | Lista vertical recolhível e rolável, nunca carrossel gigante |
| Tela Produtos | linhas 619–666 | Manter a tela existente e seus cartões por oferta |
| Origem da oferta | linhas 621 e 637–661 | Mostrar `loja · Banco Inter` sem criar produto canônico |
| Categorias acompanhadas | linha 751 | Seleção persistente com checkbox e estado parcial |
| Filtro temporário | linha 752 | Seleção única por radio e categoria pai incluindo descendentes |
| Estado da árvore e resumos | linhas 789–814 e 854–862 | Estado previsível, derivado do contrato e não do texto exibido |
| Busca, erro e retry | linhas 1070–1127 | Diferenciar sucesso, vazio, falha, parcial e atrasado |

As linhas podem mudar se o HTML experimental for formatado. Nessa hipótese, localizar os elementos pelos identificadores e textos indicados na tabela.

## 4. Arquivos Flutter diretamente relacionados

### Produtos

- `app/lib/features/produtos/pagina_produtos.dart`;
- `app/lib/features/produtos/controlador_busca_produtos.dart`;
- `app/lib/features/produtos/cartao_produto.dart`;
- `app/lib/features/produtos/formato_produtos.dart`;
- `app/lib/features/produtos/pagina_historico_produto.dart`, somente se a navegação for afetada;
- `app/lib/features/produtos/link_shopping_inter.dart`, somente se a ação existente for afetada.

### Banco Inter — Compre direto

- `app/lib/features/inter/pagina_compre_direto_inter.dart`;
- controlador existente de catálogo administrativo, somente no limite necessário para manter a seleção atual de lojas.

### Contrato mobile

- `app/lib/core/api/api.dart`;
- `app/lib/core/api/modelos.dart`;
- `app/lib/core/api/pagina.dart`, apenas se o contrato aprovado exigir.

### Componentes e navegação

- `app/lib/app/componentes/fundacao_visual.dart`, somente se um componente reutilizável comprovadamente pertencer ao Design System;
- `app/lib/app/componentes/estados.dart`;
- `app/lib/app/navegacao/moldura.dart`, somente para preservar o fluxo existente entre Produtos e Banco Inter;
- `app/lib/app/tema/tokens.dart`.

### Testes diretamente afetados

- `app/test/features/produtos/pagina_produtos_test.dart`;
- `app/test/features/produtos/controlador_busca_produtos_test.dart`;
- `app/test/features/produtos/modelos_produtos_test.dart`;
- `app/test/features/inter/pagina_compre_direto_inter_test.dart`;
- testes pontuais de `app/test/app/navegacao/moldura_test.dart` relacionados a Produtos/Compre direto.

Não alterar o teste comentado `Shopping Inter compacto possui somente os dois modos reais`. A decisão desse teste continua isolada conforme `AGENTS.md`.

## 5. Estado real encontrado antes da implementação

### O que já existe e deve ser reaproveitado

- busca paginada de produtos na API mobile;
- filtros de marca, categoria textual, loja e preços;
- debounce da busca;
- paginação e deduplicação por `lojaSlug + idExterno`;
- agrupamento visual de ofertas por loja;
- histórico independente por oferta/loja;
- seleção paginada de lojas do Compre direto;
- estados reutilizáveis de carregamento, vazio e falha;
- tokens e componentes compactos do V11;
- preservação da busca ao navegar entre áreas já cobertas por teste.

### Lacunas bloqueantes atuais

1. `Api.buscarProdutos` documenta `q` obrigatório com 2–100 caracteres. Isso não sustenta ainda o estado inicial `Todas as ofertas` mostrado no protótipo.
2. `ProdutoDireto.categoria` é somente texto opcional. Não existe no Flutter atual identidade estável de categoria Radar nem hierarquia pai/filha.
3. Não existe contrato mobile confirmado para listar categorias Radar.
4. Não existe contrato mobile confirmado para ler e salvar categorias acompanhadas.
5. O controlador atual limpa a lista no início de uma nova busca. Isso conflita com preservar o último resultado válido quando uma atualização falhar.
6. A configuração persistente de categorias ainda não tem ponto de entrada aprovado no Flutter; o protótipo propõe `Compre direto`, mas a proposta precisa ser aceita.

Não contornar essas lacunas com lista hardcoded, armazenamento somente local ou endpoint inventado.

## 6. Regras inegociáveis durante a execução

- [ ] Trabalhar somente no Flutter mobile quando a implementação for autorizada.
- [ ] Não alterar backend, schema, robô, workflows, Web ou produção.
- [ ] Não fazer o Flutter acessar Banco Inter ou banco de dados diretamente.
- [ ] Não transformar categorias ilustrativas em enum fechado.
- [ ] Não adicionar filtro, ordenação, comparação ou métrica não existente.
- [ ] Não unir ofertas por nome semelhante.
- [ ] Não calcular dinheiro ou cashback com `double`.
- [ ] Não converter ausência, falha, parcial, atraso ou vazio em zero.
- [ ] Manter paginação obrigatória.
- [ ] Preservar histórico e link seguro já existentes.
- [ ] Manter ofertas independentes por loja e identidade externa.
- [ ] Usar somente componentes, tokens e linguagem visual do V11.
- [ ] Não criar nova tela sem nova decisão explícita.
- [ ] Não executar golden, integração, E2E, smoke, performance ou testes Web.

## 7. Fase 0 — gates antes de codificar

Nenhuma alteração Flutter desta funcionalidade deve começar enquanto os itens bloqueantes aplicáveis estiverem abertos.

### Decisões de produto

- [x] Aprovar `Categorias acompanhadas` como nome de interface ou registrar o nome definitivo.
- [x] Aprovar o cartão-resumo e bottom sheet em `Banco Inter > Compre direto` como ponto de entrada.
- [x] Definir se salvar zero categorias significa nenhum interesse ativo ou se a operação deve ser impedida.
- [x] Confirmar que uma única configuração de categorias vale para todas as lojas selecionadas, conforme o plano funcional.
- [ ] Confirmar que o filtro de Produtos mostra somente categorias disponíveis no catálogo/interesse da pessoa.

### Contrato da API

- [x] Confirmar como a API identifica uma categoria Radar de forma estável.
- [x] Confirmar como pai, filhos, ordem, nome e estado ativo são retornados.
- [x] Confirmar como as categorias acompanhadas são lidas e persistidas.
- [x] Confirmar como a seleção de uma categoria pai inclui filhas futuras sem virar snapshot fechado no Flutter.
- [x] Confirmar como `GET /api/inter/produtos` representa o filtro por categoria Radar.
- [x] Confirmar se a listagem paginada aceita termo vazio; se não aceitar, alinhar o protótipo antes de implementar `Todas`.
- [ ] Confirmar como a resposta informa origem Inter, loja, parcialidade e atraso por oferta ou grupo.
- [ ] Confirmar política de erro e no máximo uma retentativa automática para leitura.

### Gate de saída

- [ ] As decisões estão registradas na fonte oficial apropriada.
- [x] O contrato real está disponível para leitura no Flutter.
- [x] Nenhuma etapa depende de nome de endpoint ou campo presumido.

## 8. Fase 1 — caracterizar e proteger o comportamento atual

### Ações

- [x] Ler somente os arquivos Flutter e testes diretamente afetados listados neste documento.
- [x] Confirmar os estados atuais de busca, paginação, filtros, retry, atraso e parcialidade.
- [ ] Confirmar como a Moldura preserva busca, página e posição ao trocar de área.
- [x] Adicionar ou ajustar apenas testes unitários/widgets que caracterizem comportamento existente necessário à mudança.
- [ ] Registrar qualquer diferença entre código real, contrato aprovado e protótipo antes de editar UI.

### Casos que devem permanecer protegidos

- [x] Duas ofertas de lojas diferentes com o mesmo nome continuam duas ofertas.
- [x] Deduplicação nunca usa título do produto.
- [x] Erro em página adicional preserva itens já carregados.
- [x] Histórico continua associado à loja e ao identificador externo corretos.
- [ ] Seleção de loja continua protegida por autorização existente.

### Gate de saída

- [x] Testes de caracterização diretamente afetados passam.
- [x] Nenhuma expectativa foi alterada apenas para acomodar uma implementação ainda inexistente.

## 9. Fase 2 — integrar os modelos de categoria ao Flutter

Esta fase somente começa depois que o contrato estiver confirmado. Ela não cria nem modifica o backend.

### Ações

- [x] Representar no cliente somente os campos realmente retornados pelo contrato de categoria.
- [x] Separar identidade estável de categoria do nome exibido.
- [x] Representar hierarquia sem limitar a profundidade aos exemplos do HTML.
- [x] Representar seleção persistente sem copiar a taxonomia inteira para estado local permanente.
- [x] Fazer parsing defensivo sem transformar ausência em categoria genérica.
- [x] Preservar compatibilidade com ofertas que ainda não tragam os novos campos, se o contrato autorizar transição.
- [x] Adicionar métodos em `Api` somente para rotas já aprovadas.
- [x] Manter valores monetários como texto/decimal do contrato existente.

### Testes unitários

- [x] Parsing de categoria raiz.
- [x] Parsing de categoria filha.
- [x] Nome longo e caracteres acentuados.
- [ ] Categoria inativa conforme semântica aprovada.
- [x] Campo ausente ou nulo sem categoria inventada.
- [x] Seleções persistidas conforme resposta real.
- [x] Erro de contrato produz falha explícita, não lista vazia enganosa.

### Gate de saída

- [x] Modelos são orientados a dados.
- [x] Nenhum exemplo como `Celulares`, `TVs` ou `Geladeiras` virou enum de produção.
- [x] Unitários diretamente afetados passam.

## 10. Fase 3 — criar o componente hierárquico reutilizável

### Referência visual

- árvore do HTML experimental nas linhas 398–418;
- configuração persistente na linha 751;
- filtro temporário na linha 752.

### Ações

- [x] Criar um componente de árvore pertencente ao domínio Produtos/Inter, sem promover prematuramente para componente global.
- [x] Renderizar dados recebidos do contrato, não filhos codificados no widget.
- [x] Permitir expandir e recolher categorias com filhos.
- [x] Mostrar hierarquia por recuo e agrupamento compatíveis com o V11.
- [x] Permitir nomes em múltiplas linhas.
- [x] Manter área de toque adequada.
- [x] Abrir o bottom sheet sempre no topo.
- [x] Permitir rolagem até as ações finais.
- [x] Preservar estado de expansão durante a edição corrente quando apropriado.
- [x] Usar checkbox e estado parcial para configuração persistente.
- [x] Usar seleção única para filtro temporário.
- [x] Comunicar no filtro temporário que categoria pai inclui descendentes.
- [x] Não carregar toda a árvore de forma diferente do contrato aprovado.

### Acessibilidade

- [x] Semântica informa nome, nível, expandido/recolhido e estado de seleção.
- [x] Controle continua utilizável com texto ampliado.
- [x] Claro e escuro mantêm contraste dos estados completo, parcial e desmarcado.

### Testes de widget

- [x] Pai expande e recolhe filhos.
- [x] Pai seleciona descendentes conforme a semântica do contrato.
- [x] Seleção parcial fica visível e semanticamente correta.
- [x] Filtro temporário permite somente uma seleção ativa.
- [x] Nome longo não gera overflow em 320 px.
- [x] Lista longa rola até `Salvar categorias`/`Ver ofertas`.
- [x] Reabertura começa no topo.

### Gate de saída

- [ ] O componente reproduz a linguagem da cópia experimental sem depender dos seus dados ilustrativos.
- [x] Widget tests diretamente afetados passam.

## 11. Fase 4 — categorias acompanhadas em Compre direto

### Referência visual

- cartão-resumo nas linhas 336–341 e 599–603 do HTML experimental;
- fluxo demonstrado: `Banco Inter > Compre direto > Configurar`.

### Ações

- [x] Inserir o resumo no fluxo compacto existente de `PaginaCompreDiretoInter` no local aprovado.
- [x] Manter busca, abas `Todas/Selecionadas`, paginação e seleção de lojas intactas.
- [x] Exibir resumo derivado da seleção persistida real.
- [x] Abrir o editor hierárquico no bottom sheet V11.
- [x] Carregar estado persistido ao abrir.
- [x] Cancelar sem alterar a seleção.
- [x] Salvar somente pelo método autorizado da API.
- [x] Mostrar carregamento durante o salvamento sem bloquear a tela inteira.
- [x] Em falha, manter a seleção anterior confirmada e permitir nova tentativa.
- [x] Aplicar a regra aprovada para zero categorias.
- [x] Não criar seleção diferente por loja.
- [x] Não acionar coleta automaticamente se o contrato não determinar isso.

### Testes de widget

- [x] Resumo exibe quantidade/nome conforme dados reais.
- [x] Configurar abre a árvore no topo.
- [x] Cancelar não chama persistência.
- [x] Salvar envia identidades estáveis, não rótulos.
- [x] Falha preserva estado anterior e apresenta mensagem.
- [x] Seleção das lojas continua funcionando depois da inclusão do cartão.
- [x] Tela não estoura em 320 px, claro e escuro, com texto ampliado.

### Gate de saída

- [x] A diferença entre loja selecionada e categoria acompanhada é evidente.
- [x] Nenhum fluxo administrativo novo foi criado.

## 12. Fase 5 — filtro temporário na tela Produtos

### Referência visual

- controle `Categoria nesta tela` nas linhas 342–348 e 625–628;
- bottom sheet de filtro temporário na linha 752.

### Ações

- [x] Manter `PaginaProdutos` como destino existente da Moldura.
- [x] Substituir a categoria textual livre pelo seletor hierárquico somente se o contrato aprovado permitir.
- [x] Manter marca, loja e preços existentes sem adicionar novos filtros.
- [x] Identificar visualmente o controle como `Filtro temporário`.
- [x] Informar que ele não altera categorias acompanhadas nem inicia coleta.
- [x] Enviar identidade de categoria no formato confirmado pela API.
- [x] Ao escolher categoria pai, consultar incluindo descendentes conforme responsabilidade definida no contrato.
- [x] Reiniciar paginação quando a categoria temporária mudar.
- [x] Manter termo e os demais filtros compatíveis.
- [x] Oferecer `Todas` somente se o contrato suportar catálogo paginado sem termo e sem categoria.
- [x] Não exibir categorias sem relação com o catálogo/interesse quando o contrato restringi-las.

### Testes de controlador/widget

- [x] Alterar categoria reinicia na página 1.
- [x] A categoria correta chega ao método `buscarProdutos`.
- [x] Escolher pai inclui resultados das filhas segundo a resposta simulada do contrato.
- [x] Selecionar categoria não altera a persistência de categorias acompanhadas.
- [x] Limpar filtro retorna ao estado aprovado.
- [ ] Busca/página/posição permanecem preservadas nas ações já cobertas.

### Gate de saída

- [x] Configuração persistente e filtro temporário não compartilham uma ação ambígua.
- [x] Nenhum chip horizontal ilimitado foi introduzido.

## 13. Fase 6 — ofertas separadas e origem explícita

### Referência visual

- agrupamentos por loja nas linhas 634–665;
- origem por cartão nas linhas 637–661.

### Ações

- [x] Preservar `_GrupoProdutosCompacto` ou estrutura equivalente agrupando visualmente por loja.
- [x] Preservar cada `ProdutoDireto` como oferta independente.
- [x] Exibir `lojaNome · Banco Inter` dentro do cartão compacto.
- [x] Manter marca e categoria como metadados, sem usá-los como identidade.
- [x] Manter histórico e link da própria oferta.
- [x] Manter deduplicação por loja + identificador externo enquanto esse for o contrato vigente.
- [x] Não ordenar nem comparar preços entre lojas sem funcionalidade aprovada.
- [x] Não criar cartão pai para nomes semelhantes.
- [x] Não usar o texto `Oferta separada` como dado real; essa expressão é apenas didática no HTML.
- [x] Classificar visualmente cabo em `Cabos` somente quando a API entregar essa categoria Radar.

### Testes de widget

- [x] Mesmo nome em Casas Bahia e Ponto gera dois cartões.
- [x] Cada cartão anuncia sua loja nas semânticas.
- [x] Cada cartão mostra sua própria origem Inter.
- [x] Histórico recebe loja e identificador da oferta tocada.
- [x] Ausência de categoria não inventa `Celulares`, `Outros` ou equivalente.

### Gate de saída

- [x] A interface não sugere produto canônico ou comparação automática.

## 14. Fase 7 — busca, preservação e retry

### Referência visual

- carregamento e erro nas linhas 630–632;
- comportamento da fixture visual nas linhas 1070–1127.

### Ações no controlador

- [x] Separar `último resultado válido` do estado da requisição corrente.
- [x] Não apagar imediatamente a lista válida ao iniciar uma atualização equivalente.
- [x] Definir quando uma nova busca legítima deve substituir a anterior conforme o plano funcional.
- [x] Preservar termo, categoria, lojas, filtros e página da requisição que falhou.
- [x] Aplicar no máximo uma retentativa automática somente para erro transitório, se essa responsabilidade pertencer ao cliente.
- [x] Não repetir automaticamente validação, autenticação ou autorização.
- [x] Cancelar/ignorar resposta antiga quando termo ou filtros mudarem.
- [x] Manter erro de primeira página diferente de erro ao carregar mais.
- [x] Manter vazio diferente de falha.

### Ações na interface

- [x] Busca sem termo mostra `Todas` somente quando o contrato permitir.
- [x] Um caractere continua respeitando a validação definida pela API.
- [x] Carregamento explica que a busca usa o catálogo salvo.
- [x] Erro com lista anterior mantém cartões visíveis e apresenta aviso não ambíguo.
- [x] `Tentar novamente` repete a mesma consulta sem perder contexto.
- [x] Parcial e atrasado usam componentes/cores V11 e não bloqueiam o uso do último catálogo válido.
- [x] Nova digitação inicia a consulta correta e reinicia paginação.

### Testes unitários/widgets

- [ ] Falha transitória executa apenas a quantidade de tentativas aprovada.
- [ ] Erro não transitório não repete automaticamente.
- [x] Retry manual conserva todos os parâmetros.
- [x] Falha preserva itens anteriores.
- [x] Resposta vazia substitui a lista somente depois de uma resposta válida.
- [x] Resposta antiga não sobrescreve termo mais recente.
- [x] Erro ao carregar mais preserva página e itens atuais.
- [x] Estados parcial, atrasado, vazio e falha têm apresentações diferentes.

### Gate de saída

- [x] O comportamento não depende da palavra `erro`; ela existe apenas no protótipo HTML.
- [x] Todos os testes diretamente afetados do controlador passam.

## 15. Fase 8 — integração de navegação e preservação de estado

### Ações

- [x] `Produtos > Escolher lojas` continua abrindo `Banco Inter > Compre direto`.
- [x] Retornar a Produtos mantém termo, categoria temporária, filtros, página e posição conforme a jornada aprovada.
- [x] Alteração real de lojas invalida/atualiza somente o necessário no catálogo visível.
- [x] Alteração de categorias acompanhadas reflete a resposta da API, sem filtragem paralela inventada no cliente.
- [x] Navegação inferior continua com os mesmos destinos do V11.
- [x] Perfil e Administração continuam fora das três áreas principais conforme desenho atual.

### Testes pontuais

- [x] Executar somente o teste diretamente relacionado de `moldura_test.dart` para Produtos/navegação.
- [x] Adicionar teste novo apenas se o comportamento novo não puder ser coberto nos testes da feature.
- [ ] Não descomentar nem adaptar o teste pendente do Shopping Inter compacto.

### Gate de saída

- [x] A jornada real continua funcionando sem nova rota ou tela.

## 16. Fase 9 — comparação visual e acessibilidade

### Estados a comparar com o HTML experimental

- [ ] `Compre direto` com cartão de categorias acompanhadas.
- [ ] Bottom sheet persistente no topo e no fim da rolagem.
- [ ] Produtos sem filtro temporário.
- [ ] Produtos com categoria folha.
- [ ] Produtos com categoria pai.
- [ ] Duas ofertas homônimas em lojas diferentes.
- [ ] Busca sem resultado.
- [ ] Erro com lista preservada.
- [ ] Retry.
- [ ] Parcial.
- [ ] Loja/grupo atrasado.

### Larguras e temas

- [ ] 320 px claro.
- [ ] 320 px escuro.
- [ ] largura mobile maior prevista nos widgets existentes.
- [ ] texto ampliado nos widgets afetados.
- [ ] teclado aberto nos bottom sheets que contenham campo de texto existente.

### Critérios visuais

- [ ] Sem overflow.
- [ ] Sem dados fictícios promovidos a reais.
- [ ] Sem Material genérico substituindo o V11.
- [ ] Mesma hierarquia, raios, cores, sombras e densidade do protótipo.
- [ ] Ações finais alcançáveis por rolagem.
- [ ] Claro e escuro preservam contraste.

Não criar ou atualizar goldens nesta fase.

## 17. Fase 10 — comandos de estabilização

Executar a cada bloco alterado:

```text
dart format <arquivos Dart alterados>
flutter analyze
flutter test <arquivo unitário/widget diretamente afetado>
```

Arquivos de teste candidatos, executados individualmente conforme o que mudou:

```text
flutter test test/features/produtos/modelos_produtos_test.dart
flutter test test/features/produtos/controlador_busca_produtos_test.dart
flutter test test/features/produtos/pagina_produtos_test.dart
flutter test test/features/inter/pagina_compre_direto_inter_test.dart
flutter test test/app/navegacao/moldura_test.dart --plain-name "Produtos é destino direto e preserva a busca entre áreas"
```

Não executar `flutter test` sem filtro por rotina. Não executar testes Web, golden, integração, E2E, smoke ou performance.

### Gate de saída

- [x] `dart format` aplicado aos arquivos alterados.
- [x] `flutter analyze` sem novos problemas.
- [x] Unitários/widgets diretamente afetados passam.
- [x] Divergências restantes do protótipo estão registradas, não escondidas.

> Pendência registrada: a comparação visual manual da Fase 9 permanece aberta
> para todos os estados e larguras listados abaixo. Nenhum golden ou teste Web
> foi criado ou executado para substituí-la.

## 18. Matriz mínima de aceitação

| Cenário | Resultado obrigatório |
| --- | --- |
| Selecionar Casas Bahia e Ponto | Ambas continuam selecionadas no fluxo existente |
| Configurar categorias | Seleção persistente vem e volta pela API autorizada |
| Selecionar pai | Descendentes atuais e futuros seguem a semântica do servidor |
| Selecionar somente Celulares | Cabo USB-C não aparece como celular |
| Filtrar por Acessórios | Cabo aparece conforme sua categoria Radar real |
| Filtrar na tela Produtos | Não altera categorias acompanhadas |
| Buscar Motorola | Ofertas homônimas de lojas diferentes ficam separadas |
| Exibir oferta | Loja e Banco Inter ficam compreensíveis |
| Busca falhar | Última lista válida não vira vazio |
| Tentar novamente | Termo, categoria, lojas, filtros e página são preservados |
| Loja atrasada | Estado é apresentado sem excluir o último retrato válido |
| Categoria ausente | Flutter não chuta categoria nem exibe fallback enganoso |
| Catálogo grande | Paginação permanece ativa |
| 320 px/texto ampliado | Não há overflow nem ação inacessível |

## 19. Condições para considerar a implementação concluída

- [ ] Todos os gates das fases autorizadas foram cumpridos.
- [ ] O local de categorias acompanhadas foi aprovado.
- [ ] O Flutter usa somente contrato real e autorizado.
- [ ] A taxonomia é orientada a dados.
- [ ] Lojas e categorias acompanhadas permanecem conceitos distintos.
- [ ] Categoria acompanhada e filtro temporário permanecem conceitos distintos.
- [ ] Ofertas continuam independentes entre lojas.
- [ ] Origem da oferta está explícita.
- [ ] Busca, paginação, retry, histórico e navegação não regrediram.
- [ ] Claro, escuro, 320 px e texto ampliado foram verificados.
- [ ] Somente testes autorizados foram usados.
- [ ] Nenhuma alteração fora do escopo foi realizada.
- [ ] Arquivos alterados, comandos e divergências restantes foram informados ao responsável.

## 20. Encerramento e exclusão deste plano

Esta é uma etapa obrigatória, mas só deve ser executada depois de toda a implementação autorizada estar realmente concluída.

- [ ] Revisar se existe item não concluído ou decisão ainda bloqueante.
- [ ] Transferir decisões permanentes relevantes para a documentação oficial apropriada, sem copiar o checklist inteiro.
- [ ] Preservar o plano funcional, o Design System, o protótipo V11 original, o protótipo experimental e o relatório de validação.
- [ ] Excluir **somente** `docs/planos/PLANO-ACAO-TEMPORARIO-PRODUTOS-CATEGORIAS-V11.md` usando uma edição rastreável.
- [ ] Confirmar na entrega final que o plano temporário foi removido.

Se qualquer gate continuar aberto, este arquivo não deve ser excluído nem a tarefa declarada concluída.
