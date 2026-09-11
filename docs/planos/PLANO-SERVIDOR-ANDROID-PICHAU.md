# Plano — Samsung como executor local da Pichau

**Status:** registro histórico da primeira prova. Não usar as instruções antigas
de worker tmux/Appium no boot como runbook vigente. As falhas sem claim de
2026-09-09 invalidaram o encerramento da disponibilidade contínua; o contrato
atual, o worker foreground e o gate de 72 horas estão no
[`PRD-PICHAU.md`](../prd/PRD-PICHAU.md).

**Última atualização:** 2026-09-09

Este plano registrou a prova de um telefone Android como executor local do robô
Pichau. Para a nova operação, o Samsung é dedicado, permanece carregando e usa
Termux/Termux:API/Termux:Boot fora das listas de suspensão. O aparelho não é
servidor da API, banco ou cliente direto do aplicativo.

O cabo USB e o notebook são necessários apenas para a configuração inicial,
diagnóstico e recuperação após reboot quando o Wi‑Fi ou a depuração sem fio
forem desligados. A execução recorrente não depende do cabo nem do notebook.

```text
Samsung/Termux → robô Pichau → Postgres → API → aplicativo Flutter
```

O workflow do GitHub é o disparador da coleta, mas não acessa o telefone
diretamente. Ele grava uma solicitação na fila Postgres; o worker Termux busca
essa solicitação e o workflow aguarda o resultado.

## 1. Realidade do aparelho e limite da prova

O levantamento disponível identificou:

- Samsung Android;
- Android 14;
- aproximadamente 3,8 GB de RAM;
- Chrome instalado;
- apenas ABI `armeabi-v7a/armeabi`, 32 bits;
- Termux, Termux:Boot e Termux:API instalados.

A ABI 32-bit tornou a instalação de Python, Selenium/Appium e UiAutomator2 o
primeiro gate. O ChromeDriver oficial não publica binário Linux ARM32 para
este aparelho. O Appium/UiAutomator2 permanece local para configuração,
diagnóstico e recuperação; na execução recorrente o adaptador conecta
diretamente ao Chrome já aberto pelo protocolo DevTools local, encaminhado por
ADB, evitando o boot lento de uma nova sessão UiAutomator2 em cada job.
Não será usado proxy, bypass, rotação de IP ou outro mecanismo inseguro.

A primeira prova cobre somente a categoria pública **Pichau PC Gamer**. Livelo,
Inter Sites parceiros e Inter Compre direto não serão movidos para o aparelho
nesta etapa.

## 2. O que foi implementado no repositório

- `FontePichauAndroid`, separado do SeleniumBase UC/CDP do GitHub;
- `PICHAU_MODO_NAVEGADOR=android`, com Chrome nativo e CDP direto via ADB;
  Appium/UiAutomator2 continua disponível para configuração e recuperação;
- retries limitados a três tentativas, intervalo Android de 1–2 segundos,
  limite de 300 páginas, marcadores de bloqueio/manutenção e diagnóstico sem
  HTML bruto;
- extração dos cards da grade principal dentro do Chrome, payload mínimo para
  o Python, `pageSize=200`, validação de URL/faixa de paginação e exigência da
  quantidade exata de cards em cada página, inclusive na última; uma coleta
  com itens únicos abaixo do total é rejeitada como parcial e não substitui o
  snapshot válido;
- quando o DOM não expõe SKU, a identidade transitória usa o slug completo da
  URL; na publicação, uma consulta em lote reconcilia a URL com o SKU
  histórico, preservando a identidade já conhecida sem criar produto novo;
- publicação de produtos e medições em lotes de 100, na mesma transação, com
  validação de colisões antes da primeira escrita, sem migration nova;
- telemetria segura de preparo, páginas, coleta e publicação, registrando
  somente duração e contagens operacionais;
- `PICHAU_ESTRATEGIA_LEITURA=dom|fetch|rede`, configurável somente no arquivo
  privado do aparelho: `fetch` lê a primeira página, descobre o total e
  pré-carrega as seguintes em paralelo, com fallback automático para DOM;
- `PICHAU_ANDROID_ORDENACAO` opcional, limitado às ordenações públicas
  `name-asc`, `name-desc`, `price-asc` e `price-desc`, para medir uma ordem
  pública alternativa sem alterar o conjunto esperado de produtos;
- `python -m robo_pichau.principal --diagnostico`, que lê somente a primeira
  página, valida `products.items`, SKU, URL HTTPS, preço e disponibilidade, e
  não cria execução no banco;
- extra opcional `.[pichau-android]` para o cliente Python do Appium;
- `backend/robo/scripts/pichau-android-run.sh`, com configuração privada,
  SSL obrigatório na `DATABASE_URL`, `flock`, `termux-wake-lock` e logs sem
  segredos;
- `pichau-android-appium.sh`, que aceita `start|stop|status` e mantém o servidor
  restrito a `127.0.0.1:4723` somente durante a coleta;
- `pichau-android-worker.sh`, que consulta a fila Postgres a cada 30 segundos
  como tarefa foreground, mantém wake/Wi-Fi lock e executa o runner somente
  quando há pedido;
- `pichau-android-schedule.sh` e `pichau-android-recover.sh`, que mantêm o job
  7301 como recuperação idempotente do daemon, sem coleta independente;
- `pichau-android-status.sh`, diagnóstico seguro de checkout, worker, watchdog,
  fila e ADB;
- `pichau-android-boot.sh`, instalado como link para o checkout na pasta do
  Termux:Boot, que agenda o watchdog e transfere o processo ao worker; o
  diagnóstico fica em `PREFIX/var/log/robo-pichau/boot.log`. Os scripts usam o
  interpretador absoluto do Termux, pois o boot executa os arquivos diretamente
  e o `/usr/bin/env` do Linux não existe nesse ambiente;
- `migracoes/022_pichau_android_fila.sql`, que cria a fila idempotente com
  estados, claim atômico, lease e índice operacional;
- workflow `.github/workflows/pichau.yml`, que agenda 09h30/14h30/20h30 de
  Brasília, entre Livelo e Inter,
  enfileira e aguarda o resultado Android;
- testes unitários do adaptador, do diagnóstico sem banco e da exigência de
  `DATABASE_URL` no modo normal.

Nenhum código Web, Livelo, Inter, migration de catálogo ou API foi alterado
para depender do telefone. O runner do telefone não executa migrations
automaticamente; a migration 022 é exclusivamente operacional para
a fila Pichau e foi aplicada no banco operacional em 2026-09-07. As roles
`pichau_dispatcher` e `pichau_publisher` foram criadas com grants mínimos: o
dispatcher só lê/insere na fila; o publicador lê/atualiza a fila e publica nas
três tabelas Pichau, com uso das sequências. O secret
`PICHAU_DISPATCH_DATABASE_URL` foi configurado no GitHub e a URL do publicador
foi instalada somente no arquivo privado do Termux, modo `600`; nenhum valor
de credencial é versionado ou registrado em log.

## 3. Banco e credencial

As tabelas `pichau_execucao`, `pichau_produto`, `pichau_medicao` e
`pichau_android_fila` formam o contrato de publicação e coordenação. A migration
022 foi aplicada no banco operacional. A consulta de grants confirmou as
permissões das roles exclusivas e a execução `34136108063` validou a operação
contínua com elas.

A credencial deve ter somente:

- `CONNECT` no banco e `USAGE` no schema usado pelas tabelas;
- `SELECT`, `INSERT`, `UPDATE` e `DELETE` nas três tabelas Pichau;
- `USAGE` e `SELECT` nas sequências das três tabelas, necessárias aos IDs;
- `SELECT`, `INSERT`, `UPDATE` e `DELETE` em `pichau_android_fila`, sem acesso
  às tabelas dos outros domínios;
- `USAGE` e `SELECT` na sequência de `pichau_android_fila`;
- nenhum privilégio em tabelas Livelo, Inter, usuários ou administração;
- conexão por SSL (`sslmode=require`, `verify-ca` ou `verify-full`).

As senhas foram geradas fora do Git, as roles foram aplicadas no banco
operacional autorizado e as URLs foram gravadas somente no secret/arquivo
privado do Termux, com modo `600`. O runner recusa URL sem `sslmode` seguro e
nunca imprime a URL. A execução `34136108063` confirmou que as permissões
separadas funcionam no caminho completo.

## 4. Fases operacionais

### Fase 0 — preparar o aparelho

1. Instalar Termux, Termux:Boot e Termux:API pela mesma fonte oficial; não
   misturar builds de fontes diferentes.
2. Abrir o Termux:Boot uma vez, desativar otimizações de bateria para os três
   aplicativos e manter o aparelho no Wi‑Fi. O carregador não é pré-requisito;
   seu uso fica a critério manual do responsável.
3. Conferir novamente ABI, espaço livre, temperatura, bateria e processos em
   segundo plano.

### Fase 1 — preparar o ambiente

No Termux, instalar Git, Python, OpenSSL e `util-linux`; clonar o repositório
em `/data/data/com.termux/files/usr/opt/robo` ou ajustar `PICHAU_REPO_ROOT`.
Criar `.venv` e instalar:

```text
pip install -e ".[pichau-android]"
python -m pip install "psycopg>=3.2"
```

No ARM32 do Termux, a segunda linha é a garantia explícita do driver puro
contra o `libpq` local; em uma instalação nova o marcador de arquitetura do
`pyproject.toml` já seleciona essa variante. Validar imports de `psycopg`,
`lxml`, `requests`, `robo_pichau` e o parser.
Instalar e testar o servidor Appium, o driver UiAutomator2, ADB e Java
somente se houver versões nativas compatíveis com 32-bit. O servidor deve
escutar em `127.0.0.1:4723`.

### Fase 2 — gate Appium e diagnóstico — aprovado em 2026-09-06

Configurar `PICHAU_MODO_NAVEGADOR=android` e, se necessário,
`PICHAU_ANDROID_DEVICE_NAME`/`PICHAU_ANDROID_UDID`. Primeiro comprovar que o
Appium inicia, UiAutomator2 abre o Chrome, uma página de teste retorna HTML e o
driver termina sem processo órfão.

Depois executar:

```text
python -m robo_pichau.principal --diagnostico
```

O diagnóstico deve encontrar `products.items`, uma URL HTTPS da Pichau, preço
e disponibilidade. O SKU continua obrigatório quando o payload SSR/Appium o
oferece; no caminho recorrente DOM/CDP, que não expõe SKU, a identidade é
reconciliada por URL na publicação. Ele registra apenas contagem, título, URL,
tamanho e marcadores seguros; não publica, não cria `pichau_execucao` e não
grava HTML, cookie ou imagem.

No Samsung Android, a sessão nativa iniciou, o CDP local retornou o DOM e o
diagnóstico SSR/Appium encontrou `total=1169`, `itens=36`, `skus=36`,
`precos=36` e disponibilidade `disponivel`. O diagnóstico não criou conexão
ou execução no banco. A coleta rápida DOM/CDP posterior foi aprovada. Após
abrir o Termux:Boot uma vez e corrigir os interpretadores dos scripts, o reboot
de 2026-09-07 executou o `pichau-android-boot.sh` sem abrir o Termux; depois do
primeiro desbloqueio, o `boot.log` registrou worker, watchdog 7301 e Appium
ativos. Como o receiver `com.termux.boot.BootReceiver` é `directBootAware=false`,
nenhum worker/Appium inicia enquanto a tela está bloqueada. O boot totalmente
autônomo continua como decisão operacional; o teste não autoriza remover a
segurança da tela de bloqueio.

### Fase 3 — primeira coleta real — aprovada em 2026-09-06

Somente após o diagnóstico aprovado, criar o arquivo privado de configuração e
executar o runner local. A execução normal exige `DATABASE_URL`, coleta todas
as páginas dentro do limite existente e publica em uma transação. Uma falha ou
coleta parcial registra a tentativa sem substituir o último snapshot válido. O
runner não cria alerta de bateria; se o Android interromper a coleta por falta
de energia, o mesmo comportamento de falha preserva o último snapshot válido.

Nas execuções 6 e 8, o Samsung percorreu 33 páginas e publicou `sucesso` com
qualidade `completa`, `total_declarado=1169`, `itens_lidos=1169`,
`itens_unicos=1169`, `duplicados=0`, 1.169 produtos e 1.169 medições. Uma
tentativa concorrente de acesso (execução 7) falhou antes da publicação e não
substituiu esse snapshot. O banco confirmou que os produtos PC Gamer presentes
continuam em 1.169.

A otimização direta pelo DOM reduziu o transporte por página de aproximadamente
1,4 MB de HTML/scripts para cerca de 10–22 KB. O parâmetro público
`pageSize=100` reduziu a coleta de 33 para 12 páginas. A sondagem no Chrome
confirmou `pageSize=200` com 200 cards na primeira página, 169 na sexta e total
1.169, o que reduz a coleta prevista para 6 páginas. As execuções 18 e 19
foram mantidas como histórico de tentativas rejeitadas: a 18 teve
`itens_unicos=1163`/6 duplicados e a 19 foi recusada como parcial. A execução
22 corrigiu a espera da última página e publicou `sucesso`, qualidade
`completa`, `total_declarado=1169`, `paginas=12`, `itens_lidos=1169`,
`itens_unicos=1169` e `duplicados=0`, em aproximadamente 3m55s. A execução 23,
com a reconciliação em lote por URL, repetiu `1169/1169`, zero duplicados e
1.169 medições em 225 segundos (3m45s). A execução 24 repetiu o mesmo resultado
em 227 segundos (3m47s). Depois, a publicação em lotes foi validada em duas
execuções reais adicionais: a primeira fechou em 354,6 segundos e a seguinte,
com cancelamento de avaliações CDP presas, em 237,4 segundos, ambas completas
com 1.169 produtos e 1.169 medições publicados. O Postgres confirmou 1.169
produtos presentes. A tentativa adicional com `name-asc` fechou em 255,2
segundos, com três páginas em fallback DOM, e por isso essa opção não ficou
habilitada no arquivo privado operacional.
Registros inativos das tentativas anteriores permanecem para
histórico e não aparecem no catálogo da API, que filtra
`presente_no_catalogo=TRUE`.

O resultado da execução real `34081623450` foi conferido pela API autenticada e
o catálogo voltou a aparecer no aplicativo Flutter. Os checks técnicos da fase
continuam descritos abaixo:

- execução `sucesso` em `pichau_execucao`;
- produtos em `pichau_produto`;
- medições Pix/cartão em `pichau_medicao`;
- ausência de imagem, HTML bruto e cookie persistido;
- catálogo legível no aplicativo Flutter.

### Fase 4 — workflow e fila Android — prova histórica, disponibilidade reaberta

O disparo recorrente deve ocorrer depois da Livelo e antes do Inter:
`09h30`, `14h30` e `20h30` de Brasília, configurados no workflow como
`30 12,17,23 * * *` UTC. O disparo manual usa exatamente o mesmo caminho.

O workflow não coleta no Ubuntu. Ele instala somente o pacote Python da fila,
insere uma solicitação com `github_run_id` como chave idempotente e aguarda o
estado terminal por até 20 minutos. Uma solicitação nunca reivindicada é
informada como `executor-offline`; quando o publicador volta, ele encerra a
pendência antes de qualquer novo claim. Não há fallback silencioso nem coleta
tardia de uma pipeline já encerrada.

No Samsung:

1. manter aplicada a migration `022_pichau_android_fila.sql` no banco autorizado;
2. configurar a credencial privada da fila no arquivo `env`, sempre com SSL;
3. atualizar o checkout em `PREFIX/opt/robo`;
4. instalar `pichau-android-boot.sh` como link para esse checkout;
5. manter os três aplicativos Termux fora das listas de suspensão, com o
   Samsung dedicado, carregando e no Wi-Fi privado;
6. reiniciar, desbloquear uma vez e executar `pichau-android-status.sh`;
7. validar uma coleta manual e nove agendadas consecutivas em 72 horas.

O worker persistente consulta a fila a cada 30 segundos como processo
foreground e mantém wake/Wi-Fi lock. O claim usa lock transacional e lease de
30 minutos; se o processo cair, o job 7301 tenta relançar o daemon. O `flock`
local continua impedindo duas coletas Android simultâneas.

### Fase 5 — observação histórica invalidada para disponibilidade contínua

O telefone já fechou três execuções consecutivas bem-sucedidas (22, 23 e 24),
com `itens_unicos=total_declarado` e `duplicados=0`. As pipelines reais
`34081623450` e `34136108063` também aguardaram o worker e terminaram com 1.169
produtos e 1.169 medições publicadas. O código de inicialização está pronto e o
retorno pós-reboot foi validado após o primeiro desbloqueio: o worker e o
Appium ficaram ativos sem abrir o Termux, com o job 7301 persistido. O Android
pode exigir esse primeiro desbloqueio para liberar o receiver; isso é uma
condição operacional conhecida. Depois das falhas `34158686905` e
`34174437207`, o
executor passou a usar Wireless Debugging por Wi-Fi, reutilizando um endpoint
ADB Wi-Fi já conectado ou descobrindo-o por mDNS, sempre com filtro pelo host
privado configurado no Termux. A execução `34182214027` confirmou novamente
fila, coleta completa e publicação; `34302348225` confirmou o transporte
operacional sem cabo e a recuperação do Chrome sem aba DevTools. No
APK,
a jornada Pichau foi aceita no aparelho com catálogo, paginação, busca,
histórico, link externo e retorno. O hardening local de credenciais, logs e
superfície Appium/CDP foi incorporado ao runner e aos scripts. O risco residual
é operacional: Wireless Debugging continua sendo um canal administrativo e
deve ficar pareado somente com dispositivos confiáveis em rede privada.
As execuções posteriores `34370533995` e `34395714110` permaneceram sem claim e
mostraram que as provas manuais não validaram a sobrevivência contínua do
worker. Temperatura, bateria e armazenamento devem ser observados manualmente;
o carregador agora é requisito operacional. IP, porta, serial,
código de pareamento, chave ADB e credenciais nunca entram em documentação,
logs ou saída do workflow. Livelo e Inter só podem ser avaliados depois disso.

### Fase 6 — validar a redução de tempo — encerrada

A implementação versionada mede o tempo completo do runner, de cada página, da
coleta e da publicação. O alvo é concluir uma coleta completa em até 120
segundos, preservando `itens_lidos = itens_unicos = total_declarado` e zero
duplicados. `fetch` e `rede` são opt-in e devem ser definidos somente no arquivo
privado do Termux; o valor padrão continua `dom`. O DOM otimizado mantém o
Chrome ativo e bloqueia recursos sem uso no catálogo.

O procedimento foi executado e encerrado: o aparelho foi atualizado, a
estratégia `fetch` preservou a validação de cada página, o banco recebeu todos
os itens/medições esperados e a execução final foi repetida pelo workflow real.
Não há nova rodada obrigatória deste plano.

Na execução `34136108063`, o caminho `fetch` fechou 1.169/1.169 em 205,9 segundos
de coleta e 214,3 segundos de runner, ainda acima do alvo de 120 segundos.
Depois disso, o caminho fetch passou a usar timeout próprio de 50 segundos e a
pré-carregar em paralelo as páginas restantes, sem publicar página parcial. Um
ensaio técnico leu as páginas 2–6 em aproximadamente 36,5 segundos; isso ainda
precisa de confirmação em coletas reais completas. A estratégia rede preserva os
eventos CDP de resposta que chegam antes do retorno de `Page.navigate` e cai para
DOM quando necessário. A ordenação opcional deve ser
medida somente com um valor público permitido; ela não autoriza reduzir o
intervalo entre páginas, omitir páginas ou paralelizar a coleta.

A execução `34302348225` encerrou a validação operacional após a correção do
arranque do Chrome sem aba DevTools: publicou a coleta completa e terminou em
aproximadamente 2m20s de workflow. A coleta anterior `34300874227` publicou
1.173 produtos em aproximadamente 69s. O critério encerrado exige catálogo
completo, zero duplicados e nenhuma publicação parcial; a espera da fila faz
parte do tempo total do workflow e pode variar.

Se o aparelho estiver sem Wi‑Fi, ADB, banco ou acesso operacional, a tentativa
falha de forma recuperável e não substitui o último snapshot válido. Isso é uma
condição operacional conhecida, não uma pendência de implementação.

## 5. Critério para abandonar a alternativa Android

Interromper a alternativa se Termux for encerrado durante a coleta, o Chrome ou
Appium não forem estáveis, o aparelho não suportar a duração/memória, o banco
não puder ser acessado com SSL e role restrita, ou cada execução exigir
intervenção manual. Nesse caso, avaliar VM/VPS Linux autorizada ou feed oficial
da Pichau.

## 6. Referências operacionais

- [Termux](https://github.com/termux/termux-app)
- [Termux:Boot](https://github.com/termux/termux-boot)
- [Termux:API Job Scheduler](https://github.com/termux/termux-api-package/blob/master/scripts/termux-job-scheduler.in)
- [UiAutomator2/Appium](https://appium.io/docs/en/2.0/quickstart/uiauto2-driver/)
- [SeleniumBase UC Mode](https://github.com/seleniumbase/SeleniumBase/blob/master/help_docs/uc_mode.md)
