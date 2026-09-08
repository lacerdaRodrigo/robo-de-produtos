# PRD — Pichau PC Gamer

**Status:** jornada mobile V11, executor Android, fila Postgres e workflow
Pichau integrado ao Android estão versionados; diagnóstico e três coletas
rápidas consecutivas foram aprovados no aparelho. A fila foi aplicada, o
worker/watchdog foi validado sem trabalho pendente e a execução real
`34081623450` publicou 1.169 produtos e 1.169 medições pelo caminho completo.
`34136108063` repetiu o caminho completo com o secret separado. A meta de tempo
continua pendente; a
API e o catálogo no aplicativo já foram conferidos. O código de boot foi
corrigido e o retorno pós-reboot foi validado sem abrir o Termux; o primeiro
desbloqueio da tela do Samsung ainda é necessário.

**Última atualização:** 2026-09-07

## Objetivo

Adicionar a Pichau como fonte independente de PCs Gamer no Radar, mantendo a
fonte subordinada a **Serviços** e sem criar um quarto destino no `BottomDock`.
O aplicativo deve consultar somente o catálogo persistido pela API e permitir
abrir o produto real na Pichau.

Este documento reúne o recorte mobile e o backend executados para a Pichau. O
coletor, o banco e a publicação da API não são considerados aplicados ou
publicados apenas por existirem no repositório.

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
controladas e a coleta completa foi validada operacionalmente no Samsung em
2026-09-06.
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
limitados a três tentativas por página, espera aleatória de 2 a 5 segundos no
workflow hospedado,
limite de 300 páginas por job, validação de URL/domínio, controle de
paginação, deduplicação e fallback para HTTP/JSON-LD em testes ou operação
controlada. O parser lê o payload `products.items` embutido pelo Next.js e
ignora imagens. Fixtures sanitizadas exercitam o núcleo sem representar
catálogo real. Durante o levantamento de 2026-09-05, as requisições diretas e
os testes transparentes com Playwright e SeleniumBase em modo comum receberam
`403` da Cloudflare ou uma página de manutenção, sem catálogo. Com o termo de
autorização fornecido, duas execuções controladas em UC/CDP receberam o
payload `products.items`, o SKU `PCM-Pichau-Gamer-67332` e `total_count=1169`.
No Samsung, as execuções 6 e 8 percorreram 33 páginas, publicaram 1.169
produtos e 1.169 medições com qualidade `completa`. A execução concorrente 7
falhou com código `acesso` antes de publicar e o snapshot anterior permaneceu
válido. O caminho Android rápido usa `pageSize=200`, extrai a grade principal
por CDP e exige a quantidade esperada de cartões, inclusive na última página.
A sondagem real confirmou 200 cards na primeira página, 169 na sexta e total
1.169; a primeira coleta completa com esse novo tamanho ainda precisa ser
medida dentro do intervalo operacional de seis horas.
Quando o DOM não informa SKU, o publicador reconcilia a URL em lote com a
identidade histórica e preserva o SKU já persistido.

O workflow separado `.github/workflows/pichau.yml` está versionado para 09h,
14h e 20h de Brasília, além do disparo manual. Ele cria uma solicitação
idempotente em `pichau_android_fila`, aguarda o worker Termux e só termina com
sucesso depois que o Android publica a coleta. O Ubuntu não executa fallback.
O workflow usa `PICHAU_DISPATCH_DATABASE_URL`; o fallback para o secret amplo
`DATABASE_URL` permanece somente para recuperação controlada. O telefone mantém
a credencial privada do publicador no Termux. Em falhas de navegador, o
robô registra somente metadados seguros; HTML, cookies e headers não são
persistidos nem enviados ao log.

## Otimização de tempo Android — implementação versionada, aceite pendente

As execuções rápidas 23 e 24 fecharam em 225 e 227 segundos. A publicação em
lotes de 100 foi validada novamente em duas execuções reais: a primeira fechou
em 354,6 segundos e a seguinte, com cancelamento da avaliação CDP presa, em
237,4 segundos, ambas com 1.169/1.169 itens e 1.169 medições publicadas. A
execução `34136108063` com credenciais separadas fechou em 214,3 segundos de
runner, com 205,9 segundos de coleta e o mesmo resultado completo. Para
reduzir esse tempo sem alterar o contrato do catálogo, o publicador Android
grava produtos e medições em lotes de 100 dentro da mesma transação,
preservando a reconciliação de identidade por URL, a inativação após coleta
completa, a retenção de 30 dias e a preservação do snapshot anterior em
qualquer falha. A migration `022_pichau_android_fila.sql` adiciona somente a
fila operacional; foi aplicada no banco operacional em 2026-09-07 e não altera
o schema do catálogo. As roles `pichau_dispatcher` e `pichau_publisher` foram
configuradas com grants mínimos, e o secret separado do dispatcher foi validado
na execução `34136108063`.

O runner e o coletor registram tempos de preparo, cada página, coleta e
publicação somente em logs operacionais seguros. A configuração privada
`PICHAU_ESTRATEGIA_LEITURA` aceita `dom` (padrão), `fetch` e `rede`. O caminho
DOM traz a aba Chrome para frente, desabilita cache e bloqueia imagens, fontes
e telemetria que não entram no modelo. O caminho `fetch` tenta ler o payload SSR
dentro da sessão; o caminho `rede` captura a resposta HTML após
`Network.loadingFinished`, antes da montagem completa dos cards. Status,
domínio, total, página e quantidade esperada são validados; qualquer falha
retorna somente aquela página ao caminho DOM atual. O fallback não reduz as
garantias de catálogo completo e não persiste HTML, imagens, cookies ou
headers.

O caminho fetch usa timeout próprio de 50 segundos e termina a avaliação
JavaScript/CDP que perdeu o prazo antes de cair para o DOM. Na coleta Android,
a primeira página descobre o total e as páginas restantes são pré-carregadas em
paralelo, cada uma com a mesma validação e fallback individual. O caminho rede
preserva eventos CDP emitidos antes da confirmação de `Page.navigate` e também
retorna ao DOM quando a resposta não pode ser capturada. O aparelho pode
definir `PICHAU_ANDROID_ORDENACAO` no arquivo privado com uma das ordenações
públicas `name-asc`, `name-desc`, `price-asc` ou `price-desc`; isso só altera a
ordem das páginas e mantém a validação do total, faixa e quantidade de itens.
Em uma medição real, `name-asc` fechou em 255,2 segundos por produzir três
fallbacks para DOM; por isso a ordenação permanece desabilitada no arquivo
privado operacional, embora continue disponível para nova medição controlada.

A meta operacional é o runner completo terminar em até 120 segundos. A
otimização só será declarada concluída após três coletas reais consecutivas
dentro do limite, com `itens_lidos = itens_unicos = total_declarado` e zero
duplicados. Falhas, coletas acima do limite, bloqueios e resultados parciais
mantêm a fase aberta para nova medição e correção; as tentativas reais
respeitam o intervalo mínimo autorizado de seis horas.

## Executor Android local — implementação versionada, uma coleta completa aprovada

O uso de um telefone Android conectado ao Wi‑Fi residencial foi separado do
workflow hospedado. O telefone não será servidor da API, não será acessado
diretamente pelo Flutter e não hospedará o banco; ele apenas executará o robô
e publicará no Postgres/API já existentes.

O plano separado está em
[`docs/planos/PLANO-SERVIDOR-ANDROID-PICHAU.md`](../planos/PLANO-SERVIDOR-ANDROID-PICHAU.md).
O pacote agora possui `FontePichauAndroid`, o modo
`PICHAU_MODO_NAVEGADOR=android`, diagnóstico sem banco e scripts de Appium,
lock, wake-lock, logs e agendamento. No Samsung SM-M135M, Android 14, Chrome
e ABI `armeabi-v7a/armeabi` 32-bit, Termux/Termux:Boot/Termux:API, Appium e
UiAutomator2 foram instalados e o diagnóstico real foi aprovado. Como não há
ChromeDriver oficial Linux ARM32, a execução recorrente conecta diretamente
ao Chrome nativo pelo CDP local encaminhado por ADB; Appium/UiAutomator2 fica
para configuração, diagnóstico e recuperação. HTML, cookies e imagens
continuam somente em memória.

O Samsung pode executar fora do notebook, conectado ao Wi‑Fi e usando somente
a própria bateria. Appium, Termux e Job Scheduler ficam locais; o carregador é
uma ação manual opcional e o agendamento não usa a condição `--charging` nem
envia alerta automático de bateria. Se o aparelho desligar por falta de
energia, a tentativa pode ser interrompida sem substituir o último catálogo
válido. O Termux:Boot foi instalado e o script atualizado inicia worker,
watchdog 7301 e Appium, com log em `var/log/robo-pichau/boot.log`; no Samsung
testado, contudo, o Android 14 mantém esse receiver pendente na tela de
bloqueio porque ele não é `directBootAware`. Assim, o primeiro desbloqueio
após reiniciar ainda é uma ação operacional necessária. Cabo USB/notebook
ficam restritos à configuração inicial, diagnóstico e recuperação quando Wi‑Fi
ou depuração sem fio forem desligados.

A prova de publicação foi feita com a `DATABASE_URL` operacional disponível no
ambiente, sempre por SSL; isso não substitui a criação externa da role
Postgres exclusiva para operação contínua. As execuções 22, 23 e 24
percorreram 12 páginas e publicaram `1169/1169` itens, zero duplicados e
1.169 medições; as execuções 23 e 24 terminaram em 225 e 227 segundos.
O retorno após reinicialização foi testado por USB em 2026-09-07 sem abrir o
Termux: enquanto a tela estava bloqueada, o Android manteve
`com.termux.boot.BootReceiver` como `PENDING OFFLOAD`, com
`directBootAware=false`; após o primeiro desbloqueio, o receiver executou o
script e o worker, Appium e job 7301 ficaram ativos. A API autenticada e o
catálogo no aplicativo foram conferidos após as execuções reais
`34081623450` e `34136108063`. A execução `34148112344` validou o prefetch com
`1169/1169`, zero duplicados, `79630 ms` de coleta e `87479 ms` de runner.
Depois dela, o executor voltou ao ADB USB pelo serial `RX8W105DHSY`; a porta
TCP temporária foi desligada e o cabo permanece conectado.
Livelo e Inter permanecem fora desta prova.

## Workflow GitHub Actions e fila Android — implementado e validado em execução real

O workflow Pichau é o disparador único da coleta. O cron segue os mesmos
horários de Livelo e Inter (`09h`, `14h` e `20h` de Brasília), e o botão manual
usa a mesma fila. Cada execução usa `github_run_id` como chave idempotente,
insere um trabalho `pendente` e aguarda até 20 minutos os estados `sucesso` ou
`falha`.

O worker `pichau-android-worker.sh` é iniciado pelo Termux:Boot depois que o
Android libera o receiver, consulta a fila a cada 30 segundos e reivindica
somente um trabalho com `FOR UPDATE SKIP LOCKED`. O lease de 30 minutos permite
recuperar uma solicitação abandonada após queda do aparelho. O job 7301
continua apenas como watchdog de uma rodada; ele não executa uma coleta sem
solicitação do GitHub. O boot inicia o worker antes do Appium e não espera o
endpoint do Appium ficar pronto; a coleta normal continua fazendo sua própria
espera controlada.

Nenhum token GitHub é armazenado no Android. O Appium fica restrito a
`127.0.0.1`; o ADB TCP local necessário ao executor pode expor a porta 5555 na
interface do aparelho e continua sujeito à configuração segura de depuração do
Android. A migration `022_pichau_android_fila.sql` já foi aplicada e as
execuções reais `34081623450` e `34136108063` confirmaram o caminho GitHub →
fila → worker Android → banco/API. As credenciais mínimas separadas estão
configuradas; o fallback para `DATABASE_URL` permanece funcional.

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

- Decidir se o primeiro desbloqueio após reinicialização é aceitável ou se a
  tela de bloqueio será removida explicitamente; o código não altera essa
  proteção. O executor também depende do ADB local TCP `127.0.0.1:5555`, que
  nesta prova foi reativado por USB e ainda não tem persistência comprovada
  após reboot. Depois disso, validar uma falha preservando o snapshot anterior
  e a ausência de duas coletas simultâneas.
- Validar em três coletas reais consecutivas o alvo de até 120 segundos,
  respeitando o intervalo mínimo de seis horas; as coletas atuais estão
  completas, mas ainda acima do alvo.
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
