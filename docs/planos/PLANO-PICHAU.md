# Plano — Integração Pichau

## 1. Objetivo

Adicionar a **Pichau** ao Radar de Benefícios como uma nova fonte independente de produtos e preços, preservando a arquitetura atual do projeto e preparando a integração para alimentar a área global de Produtos.

A Pichau deve aparecer em **Serviços**, ao lado de Livelo e Banco Inter, sem criar um novo destino principal na navegação inferior.

Este plano é de implementação futura. Ele não altera o comportamento atual do Banco Inter, da Livelo ou da busca de produtos até que suas fases sejam executadas e validadas.

---

## 2. Princípios

1. **Pichau é uma fonte independente.** Não reutilizar tabelas, modelos ou regras do Inter como se fossem da Pichau.
2. **Coleta e apresentação permanecem separadas.** O robô acessa a fonte pública, persiste o retrato e o Flutter consulta somente a API/banco.
3. **Sem coleta durante a busca no aplicativo.** A tela Produtos sempre consulta o último catálogo persistido.
4. **Sem técnicas de evasão.** Nada de CAPTCHA bypass, rotação de proxy, disfarce de identidade ou contorno de bloqueios.
5. **Precisão monetária.** Valores financeiros usam `Decimal` no Python, `NUMERIC` no Postgres e strings seguras nos contratos JSON.
6. **Origem sempre explícita.** Toda oferta precisa identificar que veio da Pichau.
7. **Falha da Pichau não pode interromper Livelo ou Inter.** Workflow, domínio e persistência devem ser isolados.
8. **O Radar controla o que interessa.** A integração deve nascer compatível com o plano global de categorias/interesses do Radar.

---

## 3. Evidência inicial da fonte

A área pública de computadores gamer da Pichau expõe cards com informações comerciais suficientes para coleta, incluindo:

- nome do produto;
- preço de referência/original;
- preço à vista/Pix;
- percentual de desconto no Pix;
- preço total no cartão;
- quantidade de parcelas;
- valor da parcela;
- indicação de parcelamento sem juros;
- disponibilidade/estoque quando exposta;
- etiquetas promocionais;
- caminho/URL do produto;
- categoria e filtros da navegação;
- SKU/identificador quando disponível na página do produto;
- marca e especificações quando expostas de forma pública e estável.

A área de periféricos segue estrutura comercial semelhante e indica que uma única integração Pichau pode atender diferentes famílias de produtos, sem criar um robô separado por categoria.

Antes da implementação, a fonte real deve ser levantada novamente para confirmar contrato, estabilidade, paginação, limites, `robots.txt`, termos públicos aplicáveis e eventual endpoint estruturado usado pelo frontend.

---

## 4. Escopo inicial

### 4.1 Dentro do escopo

- criar domínio/coletor Pichau independente;
- coletar somente conteúdo público;
- identificar produtos por chave externa estável quando possível;
- preservar origem, nome, marca, categoria externa e URL;
- preservar preços relevantes da mesma medição;
- registrar Pix e cartão separadamente;
- registrar parcelamento quando disponível;
- registrar disponibilidade/estoque quando a fonte fornecer informação confiável;
- guardar catálogo atual e histórico de preços conforme a política definida para Produtos;
- publicar estado da coleta e horário do último sucesso;
- integrar Pichau ao catálogo de Serviços do aplicativo;
- preparar os produtos Pichau para classificação nas categorias globais do Radar;
- permitir que a futura busca global de Produtos encontre ofertas Pichau.

### 4.2 Fora do escopo inicial

- autenticar na Pichau;
- montar carrinho ou realizar compra;
- calcular frete por CEP;
- burlar bloqueios ou limites da fonte;
- baixar e armazenar imagens sem decisão específica;
- coletar avaliações/comentários de usuários;
- tentar identificar automaticamente produtos equivalentes entre lojas por aproximação textual;
- criar comparação automática de preço entre produtos que ainda não possuam identidade canônica confiável;
- criar centenas de categorias antecipadamente;
- alterar a lógica de Livelo ou Inter para acomodar regras específicas da Pichau.

---

## 5. Modelo comercial mínimo da Pichau

A integração precisa distinguir campos que hoje podem aparecer condensados em outras fontes.

### Identidade da oferta

- `fonte = pichau`;
- `id_externo` ou SKU estável;
- `nome`;
- `marca`, quando disponível;
- `categoria_externa`;
- `caminho/url`;
- `ativo/disponivel` quando determinável.

### Medição comercial

- `preco_original_texto`;
- `preco_original_valor`;
- `preco_pix_texto`;
- `preco_pix_valor`;
- `desconto_pix_texto`;
- `desconto_pix_percentual`;
- `preco_cartao_texto`;
- `preco_cartao_valor`;
- `parcelas`;
- `valor_parcela`;
- `sem_juros`;
- `estoque` ou estado de disponibilidade, quando confiável;
- `etiquetas`;
- `momento` da medição.

Nenhum campo ausente deve virar zero por conveniência.

---

## 6. Estratégia de coleta

### Fase 1 — Levantamento técnico

1. Revisar a categoria pública `computadores/pichau-gamer` e outras categorias candidatas.
2. Identificar se o frontend usa endpoint público estruturado para catálogo, filtros e paginação.
3. Preferir endpoint público estável quando ele reproduzir os dados exibidos no site.
4. Usar HTML público como alternativa quando não houver contrato estruturado adequado.
5. Confirmar paginação, IDs, categorias, preço Pix, cartão e disponibilidade.
6. Medir quantidade de páginas, duração e volume aproximado de dados.
7. Definir ritmo conservador, retries e cooldown.
8. Registrar explicitamente qualquer limitação observada.

### Fase 2 — Núcleo puro

Criar modelos, normalização e extração sem I/O para:

- identidade do produto/oferta;
- preços;
- parcelamento;
- etiquetas;
- categoria externa;
- deduplicação;
- validação de páginas/respostas;
- resultado de uma coleta.

### Fase 3 — Adaptadores

Implementar adaptadores próprios para:

- fonte HTTP Pichau;
- persistência Postgres;
- relógio/log quando necessário;
- configuração das categorias/escopos acompanhados.

### Fase 4 — Persistência

Criar schema aditivo e isolado da Pichau ou, caso o Plano de Modificação de Produtos já tenha introduzido uma camada global de ofertas, persistir por essa camada mantendo a origem `pichau` explícita.

A decisão final do schema deve ocorrer somente depois de definir a ordem de implementação entre este plano e o plano global de Produtos.

### Fase 5 — Orquestração

- execução independente;
- publicação atômica do catálogo válido;
- último catálogo válido preservado quando uma tentativa falhar;
- métricas de páginas, itens lidos, únicos, duração e estado;
- falha isolada das demais fontes.

### Fase 6 — API

Expor somente os contratos necessários ao Flutter e à futura busca global.

A API não deve obrigar a tela Produtos a conhecer detalhes internos do scraper.

### Fase 7 — Flutter

Adicionar Pichau em **Serviços** seguindo o design V11:

- card de serviço próprio;
- estado da fonte;
- capacidades reais;
- acesso à configuração específica da Pichau quando implementada;
- sem novo destino principal no `BottomDock`.

A navegação principal continua:

- Resumo;
- Serviços;
- Produtos.

---

## 7. Relação com categorias globais do Radar

A Pichau não deve definir a taxonomia do Radar.

Ela fornece sua categoria externa, por exemplo:

```text
Pichau: Computadores > Pichau Gamer
```

O Radar poderá mapear isso para:

```text
Radar: PC Gamer
```

Outro exemplo:

```text
Pichau: Periféricos > Teclado
Radar: Teclados
```

O mapeamento pertence à integração da fonte, enquanto a categoria oficial pertence ao Radar.

Produtos sem correspondência confiável permanecem não classificados até existir decisão explícita.

---

## 8. Seleção do que acompanhar

A Pichau deve respeitar o mesmo princípio global planejado para Produtos:

1. a fonte está habilitada;
2. o usuário escolhe as categorias/interesses do Radar que deseja acompanhar;
3. o adaptador Pichau traduz esses interesses para os recortes que a fonte suporta;
4. a coleta evita conteúdo fora do interesse quando a fonte permitir filtro confiável;
5. a persistência mantém somente o escopo definido pela regra de produto.

Não coletar todo o catálogo da Pichau por padrão se a fonte permitir limitar a coleta de forma confiável ao conjunto desejado.

---

## 9. Histórico e identidade

Cada oferta Pichau deve manter histórico próprio.

Exemplo:

```text
Produto/oferta Pichau
  ├─ 09:00 → Pix R$ X / cartão R$ Y
  ├─ 14:00 → Pix R$ X2 / cartão R$ Y2
  └─ 20:00 → Pix R$ X3 / cartão R$ Y3
```

No primeiro momento, identidade da Pichau significa **o mesmo item dentro da Pichau**.

Afirmar que uma oferta Pichau e uma oferta Casas Bahia representam exatamente o mesmo produto será uma etapa separada e exigirá identificador confiável, como EAN/GTIN, MPN/modelo ou outra regra específica aprovada.

PCs montados com configurações específicas não devem ser considerados equivalentes apenas porque possuem CPU/GPU parecidos.

---

## 10. Testes previstos

Criar somente os testes necessários às partes implementadas.

Backend/robô:

- extração de preço original;
- extração de preço Pix;
- extração de desconto Pix;
- extração de cartão e parcelamento;
- ausência de opcionais não vira zero;
- `Decimal` preservado;
- deduplicação por ID/SKU;
- categoria externa preservada;
- mapeamento para categoria Radar quando conhecido;
- produto desconhecido permanece não classificado;
- falha de página não publica catálogo inválido;
- último sucesso é preservado;
- limites de coleta e retries.

API/Flutter somente quando seus contratos forem implementados.

---

## 11. Observabilidade

Cada execução deve registrar de forma controlada:

- início/fim;
- categoria/escopo solicitado;
- páginas consultadas;
- itens recebidos;
- itens únicos;
- itens classificados/não classificados;
- duração;
- estado final;
- códigos HTTP relevantes;
- motivo controlado de falha.

Não registrar payloads completos, dados desnecessários ou informações sensíveis.

---

## 12. Ordem recomendada

1. Aprovar o **Plano de Modificação de Produtos** e a taxonomia mínima inicial.
2. Fazer levantamento técnico atualizado da Pichau.
3. Definir o contrato Pichau com os campos realmente disponíveis.
4. Implementar coletor isolado.
5. Implementar persistência/histórico.
6. Mapear as primeiras categorias oficiais do Radar.
7. Expor API necessária.
8. Adicionar Pichau a Serviços.
9. Fazer a Pichau alimentar a busca global de Produtos.
10. Só depois discutir equivalência automática do mesmo produto entre fontes.

---

## 13. Critérios de aceite

A primeira versão da integração estará pronta quando:

- Pichau existir como fonte independente;
- nenhuma regra existente de Livelo ou Inter for reutilizada de forma semanticamente incorreta;
- coleta pública funcionar sem evasão;
- preços Pix e cartão forem preservados separadamente quando disponíveis;
- histórico não misturar medições de produtos/ofertas diferentes;
- categorias Pichau puderem ser associadas às categorias oficiais do Radar;
- Produtos conseguir identificar claramente a origem Pichau;
- falha Pichau não afetar outras integrações;
- testes diretamente relacionados passarem;
- documentação final refletir limitações reais observadas.

---

## 14. Decisões que ainda precisam ser tomadas durante a implementação

- endpoint estruturado público versus HTML;
- categorias iniciais Pichau que entrarão no primeiro rollout;
- política exata de retenção histórica compartilhada com Produtos;
- uso ou não de URL de imagem externa;
- periodicidade de coleta da Pichau;
- schema físico final, dependendo da execução prévia do plano global de Produtos;
- identificadores confiáveis disponíveis para futura comparação entre fontes.

Nenhuma dessas decisões deve ser inventada antes do levantamento da fonte e da validação do modelo global de Produtos.
