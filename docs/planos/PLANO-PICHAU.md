# Plano — Integração Pichau

> **Decisões funcionais fechadas em 2026-09-05:** a primeira versão coleta
> somente a categoria **PC Gamer**, percorre o catálogo completo sem filtros
> adicionais, roda três vezes ao dia às 09h, 15h e 21h de Brasília,
> não armazena imagens, usa tabelas próprias da Pichau, mantém histórico de
> preços por 30 dias e oferece no card o link real do produto na Pichau.
> O caminho aprovado usa HTML renderizado com payload Next.js, mantendo HTTP e
> JSON-LD como fallback controlado.

> **Estado da execução em 2026-09-05:** o protótipo V11, a jornada Flutter
> mobile, o pacote `robo_pichau`, a migration, as rotas autenticadas da API e o
> workflow separado foram versionados e a migration `021_pichau_pc_gamer.sql`
> foi aplicada no banco. O parser do payload Next.js e a fonte SeleniumBase
> UC/CDP foram integrados ao workflow, mas nenhuma coleta paginada completa foi
> publicada e nenhum deploy foi declarado.

## 1. Objetivo

Adicionar a **Pichau** ao Radar de Benefícios como uma nova fonte independente de produtos e preços, preservando a arquitetura atual do projeto e preparando a integração para alimentar a área global de Produtos.

A Pichau deve aparecer em **Serviços**, ao lado de Livelo e Banco Inter, sem criar um novo destino principal na navegação inferior.

Este documento registra as decisões do domínio e o estado da implementação.
Pichau não altera semanticamente Banco Inter, Livelo ou a busca global de
Produtos; a operação completa continua condicionada à validação externa.

---

## 2. Princípios

1. **Pichau é uma fonte independente.** Não reutilizar tabelas, modelos ou regras do Inter como se fossem da Pichau.
2. **Coleta e apresentação permanecem separadas.** O robô acessa a fonte pública, persiste o retrato e o Flutter consulta somente a API/banco.
3. **Sem coleta durante a busca no aplicativo.** A tela Produtos sempre consulta o último catálogo persistido.
4. **Método limitado pela autorização da fonte.** O termo fornecido permite UC/CDP e resolução de CAPTCHA somente nas páginas públicas e dentro dos limites registrados; proxy, rotação de IP e técnicas fora do termo continuam proibidos.
5. **Precisão monetária.** Valores financeiros usam `Decimal` no Python, `NUMERIC` no Postgres e strings seguras nos contratos JSON.
6. **Origem sempre explícita.** Toda oferta precisa identificar que veio da Pichau.
7. **Falha da Pichau não pode interromper Livelo ou Inter.** Workflow, domínio e persistência devem ser isolados.
8. **O Radar controla o que interessa.** A integração deve nascer compatível com o plano global de categorias/interesses do Radar.
9. **Gate de viabilidade antes de código dependente da fonte.** Após o protótipo,
   uma prova real, executada do ambiente previsto e dentro da autorização,
   precisa obter HTML/JSON de catálogo, extrair uma página com identificador,
   URL e campos comerciais e confirmar os limites. Esse gate foi aprovado em
   UC/CDP dentro do termo fornecido; a primeira coleta completa continua sendo
   uma validação operacional separada.

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

Antes da implementação dependente da fonte, o gate de viabilidade deve ser
aprovado: a fonte real precisa responder ao ambiente do robô com conteúdo de
catálogo extraível, dentro do método autorizado, e confirmar contrato,
estabilidade, paginação, limites, `robots.txt`, termos públicos aplicáveis e
eventual endpoint estruturado usado pelo frontend. Esse resultado foi obtido
em duas execuções controladas; a coleta completa permanece como validação
operacional.

### Resultado do levantamento de 2026-09-05

Uma leitura pública da categoria observou listagem paginada, cards com preços
original/Pix/cartão, desconto, parcelamento e disponibilidade, além de página
2 por `?page=2`. A página individual observada também expôs marca, SKU, preços,
parcelamento e estado de indisponibilidade. As requisições diretas e os testes
transparentes com Playwright e SeleniumBase em modo comum, porém, receberam
403/manutenção e não entregaram o catálogo; por isso essa observação serve
para orientar fixtures e contrato, não para autorizar coleta fora do termo. A
confirmação operacional de uma coleta completa permanece pendente. O termo
fornecido autorizou a prova controlada em UC/CDP, com até 300 páginas por job,
intervalo de 2 a 5 segundos e parada após três falhas consecutivas; duas
execuções receberam `products.items`, o SKU `PCM-Pichau-Gamer-67332` e
`total_count=1169`, aprovando o gate de viabilidade.

---

## 4. Escopo inicial

### 4.1 Dentro do escopo

- criar domínio/coletor Pichau independente;
- coletar inicialmente somente `https://www.pichau.com.br/computadores/pichau-gamer`;
- percorrer todas as páginas da categoria PC Gamer, sem aplicar filtros de fabricante,
  processador, placa de vídeo, armazenamento, preço ou montagem;
- coletar somente conteúdo público;
- identificar produtos por chave externa estável quando possível;
- preservar origem, nome, marca, categoria externa e URL;
- preservar preços relevantes da mesma medição;
- registrar Pix e cartão separadamente;
- registrar parcelamento quando disponível;
- registrar disponibilidade/estoque quando a fonte fornecer informação confiável;
- guardar catálogo atual e histórico de preços conforme a política definida para Produtos;
- manter as medições de preço por 30 dias;
- publicar estado da coleta e horário do último sucesso;
- integrar Pichau ao catálogo de Serviços do aplicativo;
- exibir no card do produto uma ação para abrir a URL real na Pichau;
- preparar os produtos Pichau para classificação nas categorias globais do Radar;
- permitir que a futura busca global de Produtos encontre ofertas Pichau.

### 4.2 Fora do escopo inicial

- autenticar na Pichau;
- montar carrinho ou realizar compra;
- coletar categorias Pichau além de PC Gamer na primeira versão;
- limitar a coleta por interesses escolhidos pela pessoa na primeira versão;
- calcular frete por CEP;
- burlar bloqueios ou limites da fonte;
- baixar e armazenar imagens sem decisão específica;
- armazenar imagens de produtos;
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
- `url_produto`;
- `presente_no_catalogo`;
- `disponibilidade`, quando determinável: `disponivel`, `esgotado`,
  `pre_venda` ou `nao_informado`.

Quando `presente_no_catalogo = false`, a API e o aplicativo podem exibir
`fora_do_catalogo`. Ausência em uma coleta completa nunca será convertida em
`esgotado`.

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

O link do produto é dado de origem e deve chegar ao Flutter pela API. O app
abre esse link no navegador externo; não cria URL por conta própria e não
armazena imagens.

---

## 6. Estratégia de coleta

### Decisões de coleta da primeira versão

- A fonte aprovada para o workflow é o HTML renderizado pelo navegador, cujo
  payload Next.js estruturado enumera e pagina o catálogo; o adaptador HTTP e
  JSON-LD ficam como fallback controlado para testes ou operação autorizada.
- A listagem da categoria será a responsável por enumerar o catálogo e controlar
  a paginação.
- A página individual será consultada somente quando for necessária para
  confirmar ou completar campos como SKU, marca, disponibilidade ou condições
  comerciais que não estejam disponíveis na listagem.
- O robô não usará filtros adicionais da página PC Gamer na primeira versão.
  O escopo fixo da coleta é todo o catálogo da categoria.
- A coleta será agendada três vezes por dia, às 09h, 15h e 21h de Brasília,
  respeitando intervalo mínimo de seis horas entre execuções.
- A execução, os logs, o estado de publicação e as falhas da Pichau serão
  isolados das demais fontes, mesmo quando o horário for compartilhado.

### Fase 1 — Levantamento técnico

1. Revisar a categoria pública `computadores/pichau-gamer` como único escopo
   inicial.
2. Usar o payload Next.js embutido no HTML renderizado para catálogo e
   paginação.
3. Preservar o adaptador HTTP/JSON-LD somente como fallback controlado quando
   a fonte autorizada entregar uma resposta compatível.
4. Não persistir o HTML bruto nem imagens; o banco recebe somente o snapshot
   comercial normalizado.
5. Confirmar quais campos aparecem na listagem e quais exigem visita à página
   individual.
6. Confirmar paginação, IDs/SKUs, preço Pix, preço de cartão, parcelamento,
   etiquetas e disponibilidade.
7. Medir quantidade de páginas, duração, volume aproximado e custo de visitar
   páginas individuais.
8. Definir ritmo conservador, retries e cooldown respeitando a fonte pública.
9. Registrar explicitamente qualquer limitação observada.

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

Criar schema aditivo e próprio da Pichau, separado das tabelas da Livelo e do
Inter. A primeira versão terá, no mínimo, as seguintes tabelas:

- `pichau_execucao`: execução, horário, categoria/escopo, estado (`iniciada`,
  `sucesso`, `parcial`, `falha`), páginas, itens lidos, itens únicos,
  duplicados, versão e código controlado de falha;
- `pichau_produto`: identidade estável, SKU/ID externo, nome, marca, categoria
  externa, `url_produto`, `presente_no_catalogo`, disponibilidade e datas de
  criação/atualização;
- `pichau_medicao`: execução, produto, momento, preço original, preço Pix,
  desconto Pix, preço no cartão, parcelas, valor da parcela, `sem_juros`,
  estoque e etiquetas, preservando texto editorial e valor `NUMERIC` quando
  houver número confiável.

As medições com mais de 30 dias serão expurgadas conforme a política do
catálogo de Produtos. A identidade do produto permanece no banco mesmo quando
ele sai do catálogo, para permitir reativação sem duplicidade.

O catálogo atual lido pela API deve considerar somente produtos presentes na
última coleta completa. Uma coleta falha ou parcial não substitui o último
snapshot válido.

### Fase 5 — Orquestração

- execução independente;
- execução às 09h, 15h e 21h de Brasília, com intervalo mínimo de seis horas;
- agendamento em `headless2`, com `xvfb` disponível somente como modo manual de
  diagnóstico;
- publicação atômica do catálogo válido;
- último catálogo válido preservado quando uma tentativa falhar;
- métricas de páginas, itens lidos, únicos, duração e estado;
- falha isolada das demais fontes.

Após uma coleta completa e válida, produtos que não aparecerem no novo
catálogo serão marcados com `presente_no_catalogo = false`. A API poderá
representá-los como `fora_do_catalogo`; isso não altera a disponibilidade para
`esgotado`. Produtos explicitamente sinalizados pela Pichau como esgotados
recebem `disponibilidade = esgotado`.

### Fase 6 — API (implementada no repositório; publicação pendente)

Foram implementadas as rotas autenticadas:

- `GET /api/pichau/catalogo`, com busca server-side por nome, marca, SKU/ID,
  ordenação estável e paginação padrão de 20, máximo de 50;
- `GET /api/pichau/catalogo/{id_externo}/historico`, com limite de 30 dias e
  paginação própria;
- bloco `pichau` no `GET /api/resumo`, com estados de tentativa e qualidade.

A API não deve obrigar a tela Produtos a conhecer detalhes internos do scraper.
Deploy e primeira leitura de dados reais permanecem pendentes.

### Fase 7 — Flutter (entregue no ciclo mobile V11)

O recorte mobile foi implementado seguindo o design V11:

- [x] card de serviço próprio em **Serviços**;
- [x] catálogo interno subordinado a Serviços, com retorno ao hub;
- [x] busca por nome, marca e SKU enviada ao catálogo paginado da API;
- [x] cards próprios com preços Pix/cartão, disponibilidade, etiquetas e origem;
- [x] histórico somente leitura em folha usando o componente V11 existente;
- [x] ação **Ver na Pichau** com validação de URL `http`/`https`;
- [x] estados de loading, vazio, falha, parcial/atrasado, esgotado e fora do catálogo;
- [x] nenhum novo destino principal no `BottomDock`;
- [ ] alimentar a busca global de Produtos, que permanece inalterada na v1;
- [x] exibir estado real da fonte no card de Serviços quando o backend entregar esse bloco.

Na área de Produtos, o card Pichau deve mostrar a origem e oferecer a ação
**Ver na Pichau**, abrindo `url_produto` no navegador externo. O card não deve
exibir ou depender de imagem armazenada pelo Radar.

A navegação principal continua:

- Resumo;
- Serviços;
- Produtos.

---

## 7. Relação com categorias globais do Radar

A Pichau não deve definir a taxonomia do Radar.

Na primeira versão, o próprio escopo fixo `PC Gamer` será a origem da coleta.
A Pichau ainda fornecerá sua categoria externa quando ela estiver disponível,
por exemplo:

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

A seleção por interesses globais não limitará a coleta inicial. Ela poderá ser
adicionada no futuro, quando outras categorias Pichau entrarem no escopo e o
contrato global de Produtos estiver pronto.

---

## 8. Seleção do que acompanhar

Na primeira versão, a seleção é fixa e não depende de configuração do usuário:

1. a fonte está habilitada;
2. o robô coleta toda a categoria `PC Gamer`;
3. nenhum filtro adicional da Pichau é aplicado;
4. todos os produtos válidos da categoria entram no snapshot;
5. a classificação em categorias globais fica disponível para evolução futura.

Quando novas categorias forem aprovadas, o contrato poderá introduzir interesses
globais e recortes de coleta. Essa evolução não deve alterar a semântica do
catálogo PC Gamer já publicado.

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

O registro de identidade continua no banco quando o produto deixa de aparecer.
Somente uma coleta completa pode marcar `presente_no_catalogo = false`; uma
resposta parcial, erro de rede, página repetida ou catálogo incoerente mantém o
último estado válido. A ausência exposta ao app é `fora_do_catalogo`, nunca
`esgotado` por inferência.

As medições de preço ficam disponíveis por 30 dias. Se o produto voltar a ser
coletado nesse período ou depois, o SKU/ID estável deve reativar o mesmo
registro, sem misturar medições de outro item.

O `url_produto` pertence à oferta e deve ser preservado para o botão **Ver na
Pichau** no card do Flutter. Imagens não fazem parte da persistência.

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
- catálogo completo sem filtros adicionais da categoria PC Gamer;
- paginação que não avança, página repetida e total incoerente são rejeitados;
- produto ausente em coleta completa vira `fora_do_catalogo`, não `esgotado`;
- coleta parcial ou falha mantém o último estado válido;
- disponibilidade explícita da fonte é preservada separadamente da presença no catálogo;
- preço e histórico são guardados por 30 dias;
- URL real do produto é preservada sem armazenar imagem;
- limites de coleta e retries.

Os testes Flutter e os testes unitários de robô/API diretamente afetados estão
catalogados abaixo. Não foram criados testes de integração, E2E, smoke ou
regressão visual automatizada.

---

## 11. Observabilidade

Cada execução deve registrar de forma controlada:

- início/fim;
- categoria/escopo fixo (`PC Gamer` na primeira versão);
- páginas consultadas;
- itens recebidos;
- itens únicos;
- itens duplicados;
- itens classificados/não classificados;
- duração;
- estado final;
- códigos HTTP relevantes;
- em falhas de navegador, título, URL final, tamanho da resposta e presença
  de marcadores de desafio/manutenção/payload, sem registrar HTML, cookies ou
  headers;
- motivo controlado de falha.

Não registrar payloads completos, dados desnecessários ou informações sensíveis.

---

## 12. Próxima ordem recomendada — operação backend

O código backend foi concluído no repositório. A próxima execução autorizada deve:

1. executar o workflow isolado em ambiente autorizado;
2. validar snapshot, histórico de 30 dias e estados de presença/disponibilidade;
3. publicar API/workflow em ambiente autorizado e fazer a primeira coleta real;
4. decidir, em evolução separada, quando a Pichau alimentará a busca global;
5. só depois ampliar para outras categorias ou discutir equivalência automática
   entre fontes.

---

## 13. Critérios de aceite

A primeira versão da integração estará pronta quando:

- Pichau existir como fonte independente;
- nenhuma regra existente de Livelo ou Inter for reutilizada de forma semanticamente incorreta;
- coleta pública funcionar dentro do método autorizado;
- preços Pix e cartão forem preservados separadamente quando disponíveis;
- histórico não misturar medições de produtos/ofertas diferentes;
- produto ausente após coleta completa ser distinguido de produto esgotado;
- categorias Pichau puderem ser associadas às categorias oficiais do Radar;
- Produtos conseguir identificar claramente a origem Pichau;
- o card abrir o link real do produto na Pichau;
- nenhuma imagem ser armazenada pelo Radar;
- falha Pichau não afetar outras integrações;
- histórico de preços permanecer limitado a 30 dias;
- coleta ocorrer nos três horários definidos e registrar métricas de paginação;
- testes diretamente relacionados passarem;
- documentação final refletir limitações reais observadas.

---

## 14. Decisões fechadas e validações técnicas restantes

As decisões funcionais da primeira versão estão fechadas:

- escopo somente PC Gamer;
- catálogo completo da categoria, sem filtros adicionais;
- HTML renderizado com payload Next.js como fonte do workflow, HTTP/JSON-LD como fallback controlado;
- listagem para descoberta e paginação, página individual somente quando
  necessária para completar dados;
- tabelas próprias `pichau_execucao`, `pichau_produto` e `pichau_medicao`;
- histórico de preços por 30 dias;
- coleta às 09h, 15h e 21h de Brasília, com intervalo mínimo de seis horas;
- nenhuma imagem armazenada;
- estados distintos para disponibilidade, ausência e falha;
- link real do produto no card do Flutter;
- nenhuma equivalência automática com produtos de outras fontes.

Após a implementação, ainda é necessário validar tecnicamente em execução real,
sem reabrir essas decisões:

- endpoint, HTML ou JSON embutido realmente disponível na Pichau;
- campos reais da listagem e das páginas individuais;
- tamanho da página, total, última página e comportamento quando o catálogo muda
  durante a coleta;
- limites de requisição, retries, cooldown, `robots.txt` e termos públicos;
- custo operacional de consultar páginas individuais;
- mapeamento dos identificadores estáveis e dos valores de disponibilidade.

Essas validações devem registrar evidências reais da fonte e podem ajustar a
implementação técnica sem ampliar o escopo funcional aprovado neste plano.
