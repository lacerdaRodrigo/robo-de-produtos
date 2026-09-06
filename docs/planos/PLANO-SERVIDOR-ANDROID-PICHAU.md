# Plano — Samsung como executor local da Pichau

**Status:** executor rápido Android e publicação no Postgres estão implementados;
uma coleta rápida completa foi comprovada no Samsung. Três execuções
consecutivas, reboot autônomo, credencial exclusiva e validação API/Flutter
continuam pendentes.

**Última atualização:** 2026-09-06

Este plano trata um telefone Android como executor local do robô Pichau
conectado ao Wi‑Fi. O Samsung pode operar fora do notebook, usando somente a
própria bateria, desde que esteja conectado a uma rede Wi‑Fi não tarifada e
tenha Appium, Termux e Job Scheduler locais. O aparelho não é servidor da API,
banco ou cliente direto do aplicativo.

O carregador é opcional e será conectado manualmente somente quando o
responsável considerar necessário. O agendamento não exige carregamento e não
há alerta automático de bateria. Se a bateria acabar durante uma coleta, o
aparelho pode desligar e a tentativa será interrompida; o último catálogo
válido continuará preservado no Postgres.

O cabo USB e o notebook são necessários apenas para a configuração inicial,
diagnóstico e recuperação após reboot quando o Wi‑Fi ou a depuração sem fio
forem desligados. A execução recorrente não depende do cabo nem do notebook.

```text
Samsung/Termux → robô Pichau → Postgres → API → aplicativo Flutter
```

O workflow do GitHub continua separado e não depende do telefone.

## 1. Realidade do aparelho e limite da prova

O levantamento disponível identificou:

- Samsung SM-M135M;
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
  o Python, `pageSize=100`, validação de URL/faixa de paginação e exigência da
  quantidade exata de cards em cada página, inclusive na última; uma coleta
  com itens únicos abaixo do total é rejeitada como parcial e não substitui o
  snapshot válido;
- quando o DOM não expõe SKU, a identidade transitória usa o slug completo da
  URL; na publicação, uma consulta em lote reconcilia a URL com o SKU
  histórico, preservando a identidade já conhecida sem criar produto novo;
- `python -m robo_pichau.principal --diagnostico`, que lê somente a primeira
  página, valida `products.items`, SKU, URL HTTPS, preço e disponibilidade, e
  não cria execução no banco;
- extra opcional `.[pichau-android]` para o cliente Python do Appium;
- `backend/robo/scripts/pichau-android-run.sh`, com configuração privada,
  SSL obrigatório na `DATABASE_URL`, `flock`, `termux-wake-lock` e logs sem
  segredos;
- `pichau-android-appium.sh`, que mantém o servidor Appium restrito a
  `127.0.0.1:4723` em uma sessão tmux e reconecta o ADB Wi‑Fi configurado;
- `pichau-android-schedule.sh`, que registra um job persistente aproximado de
  seis em seis horas, somente em rede não tarifada, sem exigir carregador;
- `pichau-android-boot.sh`, para ser copiado para a pasta de boot do
  Termux:Boot e reativar o agendamento após reinicialização;
- testes unitários do adaptador, do diagnóstico sem banco e da exigência de
  `DATABASE_URL` no modo normal.

Nenhum workflow GitHub, código Web, Livelo, Inter, migration ou API foi
alterado para depender do telefone.

## 3. Banco e credencial

As tabelas `pichau_execucao`, `pichau_produto` e `pichau_medicao` já são o
contrato de publicação. O telefone não executará migration. Antes de considerar
a operação contínua como produção, um administrador deve confirmar por consulta
somente leitura que as três tabelas existem e criar uma credencial exclusiva
para o robô Pichau.

A credencial deve ter somente:

- `CONNECT` no banco e `USAGE` no schema usado pelas tabelas;
- `SELECT`, `INSERT`, `UPDATE` e `DELETE` nas três tabelas Pichau;
- `USAGE` e `SELECT` nas sequências das três tabelas, necessárias aos IDs;
- nenhum privilégio em tabelas Livelo, Inter, usuários ou administração;
- conexão por SSL (`sslmode=require`, `verify-ca` ou `verify-full`).

O administrador deve executar a criação de role e os `GRANT`s fora do
telefone, usando senha gerada fora do Git. A URL final deve ser gravada apenas
no arquivo privado do Termux, com modo `600` ou `400`. O runner recusa URL sem
`sslmode` seguro e nunca imprime a URL. A prova de 2026-09-06 usou a
`DATABASE_URL` operacional já disponível somente para validar o caminho de
publicação; ela não encerra a pendência da role exclusiva.

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

No Samsung SM-M135M, a sessão nativa iniciou, o CDP local retornou o DOM e o
diagnóstico SSR/Appium encontrou `total=1169`, `itens=36`, `skus=36`,
`precos=36` e disponibilidade `disponivel`. O diagnóstico não criou conexão
ou execução no banco. A coleta rápida DOM/CDP posterior também foi aprovada;
reinicialização e estabilidade prolongada continuam pendentes.

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
`pageSize=100` reduziu a coleta de 33 para 12 páginas. As execuções 18 e 19
foram mantidas como histórico de tentativas rejeitadas: a 18 teve
`itens_unicos=1163`/6 duplicados e a 19 foi recusada como parcial. A execução
22 corrigiu a espera da última página e publicou `sucesso`, qualidade
`completa`, `total_declarado=1169`, `paginas=12`, `itens_lidos=1169`,
`itens_unicos=1169` e `duplicados=0`, em aproximadamente 3m55s. O Postgres
confirmou 1.169 produtos presentes e 1.169 medições na execução 22. Registros
inativos das tentativas anteriores permanecem para histórico e não aparecem no
catálogo da API, que filtra `presente_no_catalogo=TRUE`.

Ainda falta conferir o resultado pela API autenticada e pelo aplicativo Flutter:

- execução `sucesso` em `pichau_execucao`;
- produtos em `pichau_produto`;
- medições Pix/cartão em `pichau_medicao`;
- ausência de imagem, HTML bruto e cookie persistido;
- catálogo legível no aplicativo Flutter.

### Fase 4 — agendamento

Depois da coleta manual aprovada, o Samsung executou:

1. manter ou executar `pichau-android-appium.sh` para configuração/recuperação;
2. executar `pichau-android-schedule.sh`;
3. copiar `pichau-android-boot.sh` para a pasta de boot do Termux, ajustando
   `PICHAU_REPO_ROOT` se o clone não estiver em `PREFIX/opt/robo`;
4. conferir o job pelo `termux-job-scheduler --pending`;
5. reiniciar o aparelho e confirmar que o job continua presente;
6. confirmar que duas chamadas sobrepostas são ignoradas pelo `flock`.

Em 2026-09-06, o job persistente `7301` foi criado e conferido com período de
`21600000ms`, rede `NOT_METERED` e sem a opção `--charging`. A prova de
reinicialização e a concorrência ainda não foram encerradas.

O período é aproximado; a primeira versão não promete horários exatos de
09h, 15h e 21h. O Job Scheduler usa uma janela de aproximadamente seis horas e
rede não tarifada. `--charging` não é configurado. A restrição de bateria
baixa do Android pode adiar o job, sem notificação automática; o responsável
deve observar o aparelho quando quiser acompanhar esse risco.

### Fase 5 — observação

O telefone só é aceito como executor quando houver três execuções consecutivas
bem-sucedidas, reinicialização com retorno do agendamento, falha preservando o
snapshot anterior, `itens_unicos=total_declarado`, `duplicados=0` e nenhuma
concorrência. Temperatura, bateria e armazenamento
devem ser observados manualmente, mas não criam alerta automático nem tornam o
carregador obrigatório. Livelo e Inter só podem ser avaliados depois disso.

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
