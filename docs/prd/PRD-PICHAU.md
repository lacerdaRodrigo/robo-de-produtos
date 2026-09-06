# PRD — Pichau PC Gamer

**Status:** jornada mobile V11 e código backend implementados; migration
aplicada no banco, com deploy e aceite operacional da fonte ainda pendentes.

**Última atualização:** 2026-09-05

## Objetivo

Adicionar a Pichau como fonte independente de PCs Gamer no Radar, mantendo a
fonte subordinada a **Serviços** e sem criar um quarto destino no `BottomDock`.
O aplicativo deve consultar somente o catálogo persistido pela API e permitir
abrir o produto real na Pichau.

Este documento incorpora o recorte mobile e o backend executados a partir de
[`planos/PLANO-PICHAU.md`](../planos/PLANO-PICHAU.md). O coletor, o banco e a
publicação da API não são considerados aplicados ou publicados apenas por
existirem no repositório.

## Gate obrigatório de viabilidade da fonte

Para qualquer fonte externa de catálogo, inclusive uma retomada da Pichau,
uma prova técnica pequena, real e dentro do método autorizado é obrigatória **antes** de criar
código dependente da fonte (coletor, persistência, API, workflow ou catálogo
Flutter). O protótipo visual pode precedê-la, mas não é evidência de que a
integração funcionará.

A prova deve executar do ambiente previsto para o robô, obter uma resposta
real de catálogo (não uma página de bloqueio), extrair ao menos uma página com
identificador, URL e campos comerciais esperados e registrar a permissão,
limites e método autorizado. Para esta execução, o termo fornecido autoriza
UC/CDP e resolução de CAPTCHA dentro do domínio, volume, intervalo e limites
registrados em `docs/PENDENCIAS.md`. O gate foi aprovado com duas execuções
controladas; a coleta completa ainda precisa ser validada operacionalmente.
Proxy, rotação de IP e qualquer técnica fora do termo continuam proibidos.

## Escopo funcional da primeira versão

- Categoria acompanhada: **PC Gamer**.
- Catálogo completo da categoria, sem filtros de usuário na coleta.
- Pichau aparece como card próprio em **Serviços**.
- O card abre uma subárea interna de Serviços, com botão de retorno.
- O catálogo é paginado; busca por nome, marca e SKU é server-side.
- O card do produto mostra nome, marca, origem, categoria, preço Pix,
  preço original e desconto quando disponíveis, preço no cartão, parcelamento,
  etiquetas e disponibilidade.
- **Ver na Pichau** abre somente uma URL `http` ou `https` fornecida pela API,
  usando o navegador externo.
- O card oferece **Histórico** em uma folha/modal baseada no componente V11 já
  existente. A tela inicial não expõe o histórico inteiro; ele aparece sob
  demanda e é somente leitura.
- Nenhuma imagem de produto é armazenada ou necessária para o card.

## Estados de produto e fonte

O cliente mantém estados semanticamente distintos:

- carregando;
- catálogo atualizado;
- catálogo vazio;
- falha sem retrato válido;
- falha recente preservando o último retrato válido;
- coleta parcial ou atrasada preservando o último retrato válido;
- produto disponível;
- produto explicitamente esgotado pela Pichau;
- produto fora do catálogo após uma coleta completa.

A ausência de preço permanece como ausência. Ela não é convertida para `R$ 0,00`.
A ausência do catálogo não é convertida em esgotado.

## Contrato esperado da API

Todas as rotas são autenticadas e o Flutter não acessa a Pichau nem o banco
diretamente.

### Catálogo

`GET /api/pichau/catalogo?q=&pagina=&por_pagina=`

O contrato paginado usa `por_pagina` padrão 20 e limite máximo 50, além de
ordenação estável por nome e identificador. Cada item deve fornecer, quando a
fonte possuir o valor:

```text
id_externo
sku
origem
nome
marca
categoria_externa
url_produto
presente_no_catalogo
disponibilidade
preco_original_texto
preco_pix_texto
desconto_pix_texto
preco_cartao_texto
parcelamento
sem_juros
etiquetas
atualizado_em
```

### Histórico

`GET /api/pichau/catalogo/{id_externo}/historico?pagina=&por_pagina=`

O backend implementado limita as medições aos últimos 30 dias e preserva a
identidade do produto mesmo quando ele sair do catálogo. A resposta do
histórico é usada pela folha V11 para mostrar as medições de Pix e cartão sem
recalcular valores financeiros no app.

### Resumo de Serviços

`GET /api/resumo` agora inclui o bloco `pichau`, com estado, último sucesso,
última tentativa, qualidade, produtos ativos e produtos esgotados. Os estados
`atualizado`, `atrasado`, `atualizando`, `parcial`, `falha_recente`,
`degradado`, `sem_dados` e `indisponivel` continuam distintos.

## Persistência e coleta — código implementado, operação pendente

O pacote independente `backend/robo/src/robo_pichau/` usa as tabelas próprias
`pichau_execucao`, `pichau_produto` e `pichau_medicao` da migration
`migracoes/021_pichau_pc_gamer.sql`, conserva o último snapshot válido em
falhas/parciais e marca ausência somente após coleta completa. A disponibilidade
`esgotado` só vem de indicação explícita da fonte.

O coletor tem SeleniumBase UC/CDP como caminho padrão do workflow, retries
limitados a três tentativas por página, espera aleatória de 2 a 5 segundos,
limite de 300 páginas por job, validação de URL/domínio, controle de
paginação, deduplicação e fallback para HTTP/JSON-LD em testes ou operação
controlada. O parser lê o payload `products.items` embutido pelo Next.js e
ignora imagens. Fixtures sanitizadas exercitam o núcleo sem representar
catálogo real. Durante o levantamento de 2026-09-05, as requisições diretas e
os testes transparentes com Playwright e SeleniumBase em modo comum receberam
`403` da Cloudflare ou uma página de manutenção, sem catálogo. Com o termo de
autorização fornecido, duas execuções controladas em UC/CDP receberam o
payload `products.items`, o SKU `PCM-Pichau-Gamer-67332` e `total_count=1169`.
Ainda não foi executada a coleta paginada completa nem a publicação externa.

O workflow separado `.github/workflows/pichau.yml` está versionado para 09h,
15h e 21h de Brasília, com intervalos mínimos de seis horas, `DATABASE_URL` em
secret e sem alterar os demais robôs. A migration foi aplicada, mas a primeira
execução ainda depende da validação operacional da fonte e da publicação do
workflow. Em falhas de navegador, o robô registra somente metadados seguros da
resposta: título, URL final, tamanho e marcadores de desafio/manutenção/payload;
HTML, cookies e headers não são persistidos nem enviados ao log.
O agendamento usa `headless2`; uma execução manual pode selecionar `xvfb` para
comparar os modos sem alterar o padrão agendado.

## Executor Android local — proposta separada

Está em avaliação o uso de um telefone Android conectado ao Wi‑Fi residencial
como executor local da coleta Pichau. O telefone não será servidor da API, não
será acessado diretamente pelo Flutter e não hospedará o banco; ele apenas
executará o robô e publicará no Postgres/API já existentes.

O plano separado está em
[`docs/planos/PLANO-SERVIDOR-ANDROID-PICHAU.md`](../planos/PLANO-SERVIDOR-ANDROID-PICHAU.md).
Essa alternativa ainda não faz parte da operação aprovada, não altera o
workflow hospedado do GitHub e só poderá avançar após uma prova de uma página,
uma coleta completa e a validação de estabilidade do Android em segundo plano.

## Jornada mobile V11 entregue

- `PaginaProgramas` apresenta o card Pichau junto de Livelo e Banco Inter.
- `DestinoCompacto.pichau` é uma subárea e não aparece no `BottomDock`.
- `PaginaPichau` usa a fundação visual V11, busca server-side, paginação,
  loading, vazio, erro, atraso/parcial, cards próprios e histórico em folha.
- `url_launcher` recebe apenas URLs validadas por
  `linkSeguroPichau`.
- Claro/escuro e as larguras mobile de 320, 390 e 430 px são cobertos pelos
  testes diretamente afetados.

## Pendências de operação desta entrega

- Configurar/deployar a API e o workflow e executar a primeira coleta real.
- Validar a primeira coleta completa após a resposta 403/manutenção observada;
  a autorização fornecida já cobre o caminho UC/CDP usado no workflow.
- Inclusão da Pichau na busca global de Produtos.

## Critérios de aceite

Para o ciclo mobile, a jornada é aceita quando o card abre a subárea Pichau
dentro de Serviços, o catálogo é paginado, os preços Pix e cartão permanecem
separados, o histórico abre pelo componente existente, os estados não se
confundem, URLs inválidas não viram ações externas e Livelo, Inter e o
`BottomDock` continuam sem alteração semântica.

A integração completa somente poderá ser declarada pronta após implementar e
validar coletor, persistência, API autenticada, retenção de 30 dias e operação
externa. Isso permanece pendente em
[`docs/PENDENCIAS.md`](../PENDENCIAS.md).
