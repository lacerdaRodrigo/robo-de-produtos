# PRD — Pichau PC Gamer

**Status:** jornada mobile e coleta Android versionadas; a correção de ciclo
limpo, autorrecuperação única e diagnóstico estruturado está implementada e
validada, e a migration passou pela validação branch-first e foi aplicada em
produção. A correção aguarda implantação no Samsung e aceite real. A execução
`34519730452`, em 2026-09-10, falhou como `pichau-acesso`. Uma coleta anterior
passou no mesmo commit também deixando o Chrome aberto: o processo residual é
um risco real agora eliminado, mas não ficou comprovado como causa isolada.
Essa falha reiniciou o gate de nove execuções agendadas em 72 horas.

**Última atualização:** 2026-09-10

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

`GET /api/pichau/catalogo?q=&aba=todas|acompanhadas&disponibilidade=todas|disponiveis|esgotados&ordenar=nome|preco|desconto&pagina=&por_pagina=`.

Na jornada mobile V11, `aba`, `disponibilidade` e `ordenar` são filtros do
retrato persistido e continuam server-side; a digitação não consulta a fonte
externa. Cada item também informa `acompanhada: boolean`. O Flutter preserva
o filtro, a busca e a página durante as ações e usa estado otimista somente
até a confirmação da API.

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
acompanhada
```

### Histórico

`GET /api/pichau/catalogo/{id_externo}/historico?pagina=&por_pagina=`

O backend implementado limita as medições aos últimos 30 dias e preserva a
identidade do produto mesmo quando ele sair do catálogo. A resposta do
histórico é usada pela folha V11 para mostrar as medições de Pix e cartão sem
recalcular valores financeiros no app.

### Acompanhamento

`PATCH /api/pichau/catalogo/{id_externo}/acompanhamento`

```json
{ "acompanhada": true }
```

A operação é idempotente, exige autorização administrativa e não inicia coleta.
O resumo do catálogo expõe `total_catalogo` e `acompanhadas`. Produtos
acompanhados que saírem do catálogo continuam retornáveis na aba
`acompanhadas`, com `presente_no_catalogo=false`, estado **Fora do catálogo**
e histórico preservado.

O cliente Flutter para esse contrato está versionado nesta fase mobile. A
rota PATCH, a persistência do acompanhamento e sua migration não foram
alteradas neste ciclo, pois a regra operacional da branch restringe a entrega
ao app; a publicação da API/migration é um gate externo antes de distribuir a
APK com a ação habilitada.

### Resumo de Serviços

`GET /api/resumo` agora inclui o bloco `pichau`, com estado, último sucesso,
última tentativa, qualidade, produtos ativos e produtos esgotados. Os estados
`atualizado`, `atrasado`, `atualizando`, `parcial`, `falha_recente`,
`degradado`, `sem_dados` e `indisponivel` continuam distintos.

## Persistência e coleta — implementada e validada

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
1.169; as execuções finais confirmaram a coleta completa com esse tamanho e a
reconciliação por URL.
Quando o DOM não informa SKU, o publicador reconcilia a URL em lote com a
identidade histórica e preserva o SKU já persistido.

Cada sessão Android começa sem estado de aplicativo: enumera pelo `dumpsys`
somente tarefas recentes `type=standard`, valida e limita seus IDs, remove cada
uma com `am stack remove` e aciona `KEYCODE_HOME`. Esse é o equivalente sem
coordenada ao botão Samsung “Fechar tudo”; tarefas Home/Recents não são alvo e o
conteúdo do `dumpsys` não entra no log. Depois, executa
`am force-stop com.android.chrome`, confirma a ausência do processo, abre a URL
pública permitida diretamente por ADB e aguarda o DevTools. Appium/UiAutomator2
só cria uma sessão nativa se essa inicialização direta falhar; as capacidades
mantêm `noReset` e `forceAppLaunch` e incluem `shouldTerminateApp`. Na saída, o
driver é encerrado, tarefas recentes são removidas novamente, o Chrome é
forçado a parar com confirmação, a Home volta ao primeiro plano e a ponte CDP é
removida. Sem outra exceção, falhar essa confirmação impede a publicação; com
uma causa anterior, a limpeza é repetida sem mascará-la. O trap do runner também
repete a limpeza em sucesso, falha ou sinal.

A execução real `34302348225` confirmou a operação completa depois da correção
do arranque do Chrome sem aba DevTools: 1.173 produtos foram publicados com
qualidade completa, sem publicação parcial. O workflow encerrou em
aproximadamente 2m20s; o tempo de coleta observado na execução anterior foi de
aproximadamente 69s.

O workflow separado `.github/workflows/pichau.yml` está versionado para 09h,
14h e 20h de Brasília, além do disparo manual. Ele cria uma solicitação
idempotente em `pichau_android_fila` cuja chave combina `github_run_id` e
`github.sha`, aguarda o worker Termux e só termina com sucesso depois que o
Android publica a coleta. O Ubuntu não executa fallback.
O workflow usa `PICHAU_DISPATCH_DATABASE_URL`; o fallback para o secret amplo
`DATABASE_URL` permanece somente para recuperação controlada. O telefone mantém
a credencial privada do publicador no Termux. Em falhas de navegador, o robô
registra somente metadados seguros; mensagem de exceção, HTML, título, URL,
cookies, headers e identificadores privados não são persistidos nem enviados ao
workflow.

## Otimização de tempo Android — implementação versionada e encerrada

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
paralelo somente por fetch, cada uma com a mesma validação. Uma página cujo
fetch falha não tenta navegar a aba compartilhada dentro da thread: ela fica
pendente e volta ao fluxo sequencial normal, no qual o fallback DOM continua
disponível. Isso impede várias conexões CDP de navegarem simultaneamente a
única aba do Chrome. O caminho rede
preserva eventos CDP emitidos antes da confirmação de `Page.navigate` e também
retorna ao DOM quando a resposta não pode ser capturada. O aparelho pode
definir `PICHAU_ANDROID_ORDENACAO` no arquivo privado com uma das ordenações
públicas `name-asc`, `name-desc`, `price-asc` ou `price-desc`; isso só altera a
ordem das páginas e mantém a validação do total, faixa e quantidade de itens.
Em uma medição real, `name-asc` fechou em 255,2 segundos por produzir três
fallbacks para DOM; por isso a ordenação permanece desabilitada no arquivo
privado operacional, embora continue disponível para nova medição controlada.

A meta de tempo foi encerrada após as coletas rápidas completas. O aceite de
conteúdo continua exigindo
`itens_lidos = itens_unicos = total_declarado`, zero duplicados e nenhuma
publicação parcial; o tempo total do workflow continua incluindo a espera da
fila e pode variar conforme o worker Android.

## Estabilização de sessão e diagnóstico estruturado

Depois dos retries de página existentes, `navegador`, `rede`, HTTP
408/425/429/5xx e catálogo incompleto permitem uma única recuperação completa.
O primeiro conjunto de produtos é descartado, o Chrome é fechado, há cooldown
de 10 segundos e uma nova fonte inicia do zero. Não existe terceira sessão.
Bloqueio ou desafio explícito, manutenção, HTTP 401/403, configuração, dados
inválidos, banco e resultado parcial não repetem. Nenhum produto é publicado
antes de a sessão escolhida terminar completa e de o fechamento do Chrome ser
confirmado.

A migration independente `024_pichau_android_diagnostico.sql`, que depende
somente da `022` e não aplica a `023`, acrescenta `diagnostico JSONB NOT NULL
DEFAULT '{}'` à fila. O banco limita o valor a objeto de até 2 KiB; o código
aceita apenas versão, estado/etapa, página/estratégia, tentativa de
página/sessão, recuperação, duração, contagens, total declarado, status HTTP,
execução, código seguro e resumo compacto da primeira falha. Mensagem de
exceção, HTML, título, URL, cookie, header, IP, porta, serial, perfil e
credencial não fazem parte do vocabulário.

Em 2026-09-10, a `024` foi aplicada somente numa branch temporária derivada de
`production`, sem a `023`. A validação confirmou a coluna `jsonb` obrigatória
com default `{}`, as constraints de objeto e 2 KiB, a compatibilidade das 47
linhas existentes e os grants mínimos dos dois papéis operacionais. A branch
temporária foi descartada sem alterar `production`. Depois da confirmação do
responsável, a migration foi aplicada em `production`; uma verificação somente
de leitura confirmou novamente coluna, constraints, 47 linhas com `{}` e os
grants esperados.

O worker remove `DATABASE_URL` do ambiente do runner e passa apenas o ID
numérico da fila. O runner lê sua configuração privada e entrega credencial e
ID somente ao processo Python publicador; Appium, ADB e Chrome não os recebem.
O publicador atualiza o diagnóstico com `WHERE id = ? AND estado =
'executando'`. O comando `fila_android wait` imprime mudanças em pares
`chave=valor`, emite `warning` na recuperação, `error` na falha e preenche o
resumo do Actions. Um código granular validado prevalece sobre a categoria do
exit code; `{}`, JSON inválido ou linha produzida por telefone/workflow antigo
mantém o comportamento anterior sem expor o conteúdo recusado.

## Executor Android local — hardening de disponibilidade versionado

O uso de um telefone Android conectado ao Wi‑Fi residencial foi separado do
workflow hospedado. O telefone não será servidor da API, não será acessado
diretamente pelo Flutter e não hospedará o banco; ele apenas executará o robô
e publicará no Postgres/API já existentes.

O plano separado está em
[`docs/planos/PLANO-SERVIDOR-ANDROID-PICHAU.md`](../planos/PLANO-SERVIDOR-ANDROID-PICHAU.md).
O pacote agora possui `FontePichauAndroid`, o modo
`PICHAU_MODO_NAVEGADOR=android`, diagnóstico sem banco e scripts de Appium,
lock, wake-lock, logs e agendamento. No Samsung Android 14, Chrome
e ABI `armeabi-v7a/armeabi` 32-bit, Termux/Termux:Boot/Termux:API, Appium e
UiAutomator2 foram instalados e o diagnóstico real foi aprovado. Como não há
ChromeDriver oficial Linux ARM32, a execução recorrente conecta diretamente
ao Chrome nativo pelo CDP local encaminhado por ADB; Appium/UiAutomator2 fica
para configuração, diagnóstico e recuperação. HTML, cookies e imagens
continuam somente em memória.

Este executor não é headless: o Chrome nativo pode aparecer no primeiro plano
quando a URL é aberta por ADB ou quando o Appium recupera a sessão, porque o
DevTools precisa de uma aba real do navegador Android. A tela pode permanecer
bloqueada durante a operação; isso não transforma o Chrome em um navegador
headless nem expõe o servidor Appium na rede. A segurança não depende da janela
ficar invisível: Appium fica
preso a `127.0.0.1`, o CDP usa somente encaminhamento ADB local e o runner não
passa a credencial do banco para Appium, tmux, ADB ou Chrome. Configuração e
logs operacionais ficam privados (`600`), e o telefone deve ser dedicado, sem
contas pessoais, senhas salvas ou tokens no perfil Chrome. Wireless Debugging
deve permanecer pareado apenas com dispositivos confiáveis e sem portas
publicadas no roteador.

O Samsung é um executor dedicado: deve permanecer carregando, conectado ao
Wi-Fi privado, com proteção de bateria habilitada quando disponível e Termux,
Termux:API e Termux:Boot configurados como bateria irrestrita e fora das listas
de suspensão da Samsung. O daemon mantém wake/Wi-Fi lock continuamente. O
agendamento não exige `--charging`, para que uma desconexão breve do cabo não
bloqueie a recuperação. O Android 14 pode exigir o primeiro desbloqueio após
reiniciar para liberar o receiver; depois desse desbloqueio a tela pode voltar a
ficar bloqueada. Cabo USB/notebook ficam restritos à configuração inicial e à
recuperação quando Wi-Fi ou depuração sem fio forem desligados.

Tela bloqueada não significa aparelho desligado: enquanto o Android permanece
ligado, o worker foreground e o watchdog 7301 recuperam o processo sem abrir o
Termux. Nesta ROM Samsung Android 14 sem root, um desligamento ou reboot pode
desativar a Depuração por Wi‑Fi e interromper o transporte fixo; o telefone não
tem privilégio para religar essa função sozinho. O runbook de recuperação é:

1. ligar o aparelho e fazer o primeiro desbloqueio;
2. ativar “Depuração por Wi‑Fi” nas Opções do desenvolvedor;
3. conectar temporariamente um computador autorizado por USB e executar
   `adb tcpip 5555`;
4. confirmar `pichau-android-status.sh` e retirar o cabo de dados antes de
   bloquear novamente a tela.

Enquanto essa limitação existir, a operação recorrente não deve depender do
cabo USB, mas a recuperação pós-reboot depende dele. Não se considera provada
autonomia total após desligamento sem novo teste real. Se a intervenção manual
for inaceitável, a decisão correta é avaliar um controlador Linux residencial
sempre ligado; isso é uma mudança de arquitetura separada, não uma promessa de
que o Android sem root possa substituir o controlador.

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
Depois dela, o executor passou a depender do Wireless Debugging pareado no
próprio Wi-Fi; o cabo USB não faz parte do transporte operacional. A execução
`34302348225` confirmou o caminho sem cabo, fila, worker, Chrome/Appium e
publicação depois do ajuste que abre explicitamente a URL quando não existe
aba DevTools.
Durante o boot frio, o endpoint `/json` do Chrome pode responder JSON parcial ou
sem uma aba por alguns segundos; o adaptador aguarda a estabilização dentro de
um limite finito antes de recriar a sessão Appium, sem transformar essa condição
transitória em falha definitiva.
A execução `34306849805` confirmou esse fluxo corrigido sem cabo, com fila,
worker, Appium, Chrome e publicação concluídos em 2m17s.
Livelo e Inter permanecem fora desta prova.

## Workflow GitHub Actions e fila Android — contrato versionado, aceite em observação

O workflow Pichau é o disparador único da coleta. O cron segue os mesmos
horários de Livelo e Inter (`09h`, `14h` e `20h` de Brasília), e o botão manual
usa a mesma fila. Cada execução combina `github_run_id` e o `github.sha` de 40
caracteres na chave idempotente, insere um trabalho `pendente` e aguarda até 20
minutos os estados `sucesso` ou `falha`. O uso da chave existente dispensa nova
coluna ou migration e mantém legíveis as linhas antigas sem SHA.

O worker `pichau-android-worker.sh` é iniciado diretamente pelo Termux:Boot,
sem ser destacado em tmux: o script de boot transfere o processo com `exec`, o
Termux mantém a tarefa foreground e o worker conserva wake/Wi-Fi lock durante
toda a vida do daemon. Ele consulta a fila a cada 30 segundos e reivindica um
trabalho com `FOR UPDATE SKIP LOCKED`. O lease de 30 minutos continua permitindo
recuperar uma execução abandonada.

Depois do claim e antes de abrir o Chrome, o executor exige que não existam
alterações locais versionadas, busca somente `origin/main` sem prompt interativo
e avança o checkout exclusivamente por fast-forward. Em seguida confirma por
ancestralidade que o HEAD local contém o SHA que disparou o workflow. Isso
aceita um release automático posterior ao disparo, como ocorreu entre
`4a3e91b` e `e64a003`, mas não aceita branch divergente, checkout sujo, falha de
rede ou commit ausente. Quando o HEAD muda, o mesmo Python do worker reinstala
o projeto editável com o extra `pichau-android`, garantindo também o alinhamento
das dependências. Falha de Git ou instalação termina a fila como
`pichau-checkout` e a coleta nem inicia. Solicitações antigas sem SHA ainda
atualizam até a `main`, preservando a compatibilidade operacional.

O job 7301 chama `pichau-android-recover.sh` a cada 15 minutos com rede `any`,
sem condições de bateria ou armazenamento. O recuperador tenta iniciar o mesmo
daemon; o `flock` torna a chamada inofensiva quando o worker principal está
ativo. Appium não permanece carregado no boot: o runner o inicia sob demanda e
o encerra ao terminar, reduzindo processos ociosos no aparelho antigo.

Uma solicitação que permanecer `pendente` por 20 minutos é informada pelo
workflow como `executor-offline`. A credencial restrita do dispatcher não ganha
permissão de update; quando o publicador voltar, o worker encerra pendências
antigas como `falha/executor-offline` antes do próximo claim, impedindo que
pipelines já encerradas sejam coletadas horas depois. Trabalhos `executando` não
são expirados por essa limpeza e continuam protegidos pelo lease. Falhas
reivindicadas chegam ao workflow nas categorias seguras do runner ou, quando o
publicador já registrou diagnóstico, em códigos mais granulares como
`pichau-rede`, `pichau-http-503` e `pichau-catalogo-incompleto`.

O comando `pichau-android-status.sh` verifica checkout, arquivo privado, lock do
worker, wake lock de propriedade do worker, watchdog, banco da fila e ADB Wi-Fi
sem imprimir URL, host, porta ou serial. O arquivo do Termux:Boot deve ser um
link para o checkout em `PREFIX/opt/robo`, evitando divergência após `git pull`.
Backups ficam fora de `.termux/boot`, porque todos os arquivos presentes nessa
pasta são executados durante a inicialização.

O `android-tools` instalado neste Samsung não implementa a consulta mDNS no
servidor ADB local. O runner reutiliza conexões existentes e aceita uma porta
Wi-Fi fixa privada como fallback, sempre combinada ao host validado do próprio
aparelho. A porta não é publicada no roteador. Esta ROM desliga o transporte
ADB Wi-Fi após reboot; nesse caso, a chave deve ser ligada novamente e a porta
reativada por USB antes de devolver o telefone à operação bloqueada.

Na recuperação do Chrome após reboot, a sessão Appium permanece em contexto
nativo UiAutomator2. Esse contexto não implementa o timeout W3C `pageLoad`; o
adaptador não envia esse comando e mantém os limites finitos na navegação CDP
que realmente lê o catálogo.

Nenhum token GitHub é armazenado no Android. O Appium fica restrito a
`127.0.0.1`; o executor usa Wireless Debugging pareado, com descoberta mDNS e
filtro por host privado configurado somente no Termux. IP, porta, serial,
código de pareamento, chave ADB e credenciais não entram nos logs nem no
workflow. A migration `022_pichau_android_fila.sql` já foi aplicada; a `024`
passou pela validação branch-first e também foi aplicada em produção. As
execuções reais `34081623450`, `34136108063` e `34302348225` confirmaram o
caminho GitHub → fila → worker Android → banco/API. As credenciais mínimas
separadas estão configuradas; o fallback para `DATABASE_URL` permanece
funcional.

O novo aceite operacional exige uma coleta manual inicial após implantação e
nove execuções agendadas consecutivas durante 72 horas, com tela bloqueada e
sem abrir o Termux. Todas devem ser reivindicadas uma vez e concluir dentro do
workflow. Qualquer falha reinicia a janela depois da correção. Se
`executor-offline` persistir com o aparelho dedicado, carregando e configurado
como nunca suspender, esta ROM/aparelho não será aceita como servidor; a coleta
deve ser planejada com controlador Linux residencial separado.

A coleta manual inicial `34424475472` passou em 2026-09-09 com a tela em
`Dozing`: fila `pendente → executando → sucesso`, uma tentativa, seis páginas,
1.176 itens lidos/únicos, zero duplicados e publicação concluída em cerca de 97
segundos de runner. Depois da execução, Appium voltou ao estado ocioso e worker,
watchdog, fila e ADB Wi-Fi permaneceram saudáveis. Essa prova inicia a
observação, mas não substitui as nove execuções agendadas.

Uma segunda execução manual, `34425228841` (job 43), foi disparada em
2026-09-09 com o aparelho fora de alcance e sem cabo de dados disponível para
intervenção. A fila passou novamente por `pendente → executando → sucesso`, com
uma tentativa, e o workflow terminou verde. Esse resultado reforça que a
operação normal bloqueada via Wi‑Fi não depende da presença física do notebook;
continua sendo evidência manual e não substitui as nove execuções agendadas do
gate de 72 horas.

A execução `34427865543` (job 46) falhou em 2026-09-09 depois que cinco páginas
perderam o fetch e tentaram o fallback DOM concorrentemente na mesma aba do
Chrome. O resultado `pichau-acesso` veio dos timeouts WebSocket dessa disputa,
não do bloqueio de tela. A correção deixou o prefetch paralelo restrito ao fetch
e serializou qualquer fallback DOM; a contraprova `34428373217` terminou com
sucesso e catálogo completo.

A correção foi implantada no Samsung pelo commit `4940436` e validada pela
execução `34429829770` (fila 48) em 2026-09-09. Com a tela em `Dozing` e o
descanso de 30 segundos restaurado, o trabalho passou por
`pendente → executando → sucesso` em uma tentativa: seis páginas, 1.176 itens
lidos/únicos, zero duplicados e publicação completa. O workflow terminou verde
em 2min16s. Nesta coleta todos os cinco fetches do prefetch passaram
(`pendentes=0`), portanto ela comprova ausência de regressão no caminho normal;
o caminho de falha concorrente permanece coberto pelo teste unitário CT-398.
Essa execução reiniciou, naquele momento, o gate das nove coletas agendadas em
72 horas.

Em 2026-09-10, a execução `34519730452` falhou novamente como
`pichau-acesso`. Uma coleta anterior no mesmo commit havia passado também com o
Chrome aberto ao final. Logo, deixar o navegador aberto não explica sozinho a
falha e deixa de ser comportamento aceito: o contrato vigente sempre começa e
termina com Chrome parado. A `34519730452` reinicia o gate; a nova janela só
começa depois da implantação no Samsung e da coleta manual real registrada.

Em 2026-09-11, a execução `34544816986` (fila 52) falhou como
`pichau-dados` em 5min29s. A fila terminou com `diagnostico={}` e sem
`execucao_id`, provando que o Samsung ainda executava o checkout anterior e não
a estabilização já enviada à `main`. Logo depois, o responsável abriu Recentes
e acionou manualmente “Fechar tudo”; a execução `34545283501` (fila 53) passou
em uma tentativa e 3min24s. A comparação não isola toda a causa interna do
Chrome, mas comprova que a pilha recente é uma variável operacional relevante.
No mesmo aparelho, a automação nova foi validada criando uma tarefa Chrome:
antes havia uma tarefa padrão e processo ativo; depois de `am stack remove`,
restaram zero tarefas padrão, zero processo Chrome e a Home ficou em primeiro
plano. A falha da fila 52 reinicia novamente o gate de 72 horas.

## Jornada mobile V11 entregue

- `PaginaProgramas` apresenta o card Pichau junto de Livelo e Banco Inter.
- `DestinoCompacto.pichau` é uma subárea e não aparece no `BottomDock`.
- `PaginaPichau` usa a fundação visual V11, busca server-side, paginação,
  loading, vazio, erro, atraso/parcial, cards próprios e histórico em folha.
- A jornada mobile também possui abas Todas/Acompanhadas, filtros de
  disponibilidade, ordenação por nome/preço Pix/desconto, acompanhamento
  autorizado com rollback em erro e distinção visual entre esgotado e fora do
  catálogo.
- `url_launcher` recebe apenas URLs validadas por
  `linkSeguroPichau`.
- Claro/escuro e as larguras mobile de 320, 390 e 430 px são cobertos pelos
  testes diretamente afetados.

## Estado operacional do executor Android

O hardening anterior e a migration desta revisão estão implantados; a limpeza
de tarefas recentes está validada localmente e no aparelho, mas ainda depende
do envio à `main`, atualização do checkout do Samsung e coleta manual real antes
da nova observação de 72 horas. O telefone precisa
permanecer carregando, no Wi‑Fi e com a depuração sem fio disponível; a tela
pode ficar bloqueada depois do primeiro desbloqueio pós-reboot. O cabo USB não
faz parte da execução recorrente. A inclusão da Pichau na busca global de
Produtos e a evolução do acompanhamento são decisões de produto/API separadas.

## Critérios de aceite

Para o ciclo mobile, a jornada é aceita quando o card abre a subárea Pichau
dentro de Serviços, o catálogo é paginado, busca/aba/filtros preservam o
recorte solicitado, os preços Pix e cartão permanecem separados, o histórico
abre pelo componente existente, os estados não se confundem, URLs inválidas
não viram ações externas, o acompanhamento faz rollback em falha e Livelo,
Inter e o `BottomDock` continuam sem alteração semântica.

A integração Pichau Android só volta ao estado pronto depois da coleta manual
da correção e do gate de 72 horas. Catálogo,
persistência, API autenticada e Wireless Debugging anteriores continuam
validados; ciclo de Chrome, diagnóstico no Actions e disponibilidade contínua
aguardam a nova prova. Evoluções de produto/API e o aceite operacional
permanecem listados separadamente em
[`docs/PENDENCIAS.md`](../PENDENCIAS.md).
