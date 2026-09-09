# `backend/robo/` — Robôs Python (coleta e publicação)

Núcleo do backend: robôs que coletam das **fontes públicas** (Livelo e Shopping
Inter e Pichau) e gravam no Postgres (Neon). É processado separadamente pelo GitHub
Actions a cada 3×/dia; não tem servidor próprio.

## Domínios isolados

São **quatro integrações independentes**, cada uma com código, tabelas e workflow
próprios — não misturam regras nem se afetam:

1. **Livelo** — publica o catálogo completo atual, calcula o retrato somente das
   acompanhadas e alerta quando a pontuação cruza a régua (V2). Entrada:
   `src/robo_livelo/principal.py`.
2. **Inter — Sites parceiros** — catálogo de cashback (V3). Entrada:
   `src/robo_livelo/principal_inter.py`.
3. **Inter — Compre direto** — coleta de produtos das lojas escolhidas, com busca
   e histórico de 30 dias (V4). Entrada: `src/robo_livelo/principal_produtos_inter.py`.
4. **Pichau — PC Gamer** — coleta pública independente, snapshot e histórico de
   preços de 30 dias. Entrada: `src/robo_pichau/principal.py`.

## Estrutura

```text
backend/robo/
├── src/robo_livelo/   # código (domínio puro + portas + adaptadores)
├── src/robo_pichau/   # coletor, extração, portas e publicação Pichau
├── testes/            # pytest (prefixo teste_)
├── config/            # lojas_favoritas.toml (reserva local da seleção Livelo)
├── scripts/           # utilitários e runner local Termux da Pichau
└── pyproject.toml     # dependências, versão, gates
```

## Como rodar

O pacote vive em `src/`. A partir desta pasta:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp ../../backend/api/examples/.env.example .env   # ou um .env com seus dados
python -m robo_livelo.principal
python -m robo_livelo.principal_inter
python -m robo_livelo.principal_produtos_inter
python -m robo_pichau.principal
python -m robo_pichau.principal --diagnostico
```

- O coletor do Inter exige `DATABASE_URL`.
- O diagnóstico Pichau lê somente a primeira página, valida `products.items` e
  não cria execução ou conexão no banco. A coleta normal exige `DATABASE_URL`.
- O workflow Pichau enfileira a execução no Postgres e aguarda o Android; ele
  não instala SeleniumBase nem coleta no Ubuntu. Para operação Android,
  instale `.[pichau-android]`, mantenha Appium/UiAutomator2
  em `127.0.0.1` e use `PICHAU_MODO_NAVEGADOR=android`. No Samsung 32-bit,
  UiAutomator2 abre o Chrome nativo e `websocket-client` lê o DOM pelo CDP
  local via ADB; não há download de ChromeDriver ARM32. A listagem Android
  usa `pageSize=200`, exige a faixa completa renderizada inclusive na última
  página e reconcilia por URL com SKU histórico quando o DOM não o publica.
- No Termux, instale `libxml2`, `libxslt` e `libpq` antes do ambiente Python.
  O Android ARM32 usa `psycopg` puro contra o `libpq` do Termux; os runners
  Linux e desktop continuam usando `psycopg[binary]`. Se o ambiente virtual
  tiver sido criado antes do ajuste de arquitetura, complete-o com
  `python -m pip install "psycopg>=3.2"`. O script
  `scripts/pichau-android-run.sh` lê um arquivo privado
  `PREFIX/etc/robo-pichau/env`, exige modo `600`/`400`, `sslmode` seguro,
  `flock`, `termux-wake-lock` e um `.venv`. O transporte operacional é
  Wireless Debugging por Wi-Fi: `PICHAU_ANDROID_UDID=auto` reutiliza um endpoint
  Wi-Fi já conectado pelo ADB e, quando necessário, descobre o serviço pareado
  por mDNS; em ambos os casos filtra o host privado definido em
  `PICHAU_ANDROID_WIFI_HOST`. IP, porta, serial, código de pareamento e
  credenciais ficam somente no arquivo privado e nunca são escritos em logs,
  documentação ou saída do workflow.
  A configuração privada usa este formato, sempre com valores reais somente no
  Termux:

  ```text
  PICHAU_ANDROID_TRANSPORTE=wifi
  PICHAU_ANDROID_UDID=auto
  PICHAU_ANDROID_WIFI_HOST=<IP_PRIVADO_DO_ANDROID>
  PICHAU_ANDROID_WIFI_SERVICE=adb-tls-connect._tcp
  ```
  A fronteira de segurança é local: Appium escuta somente em `127.0.0.1`, o
  CDP existe apenas na ponte ADB encaminhada localmente e nenhum desses
  serviços deve ser publicado no roteador ou por encaminhamento de portas. O
  runner usa `umask 077`, corrige os logs para `600` e não passa
  `DATABASE_URL` ao Appium, tmux, ADB ou Chrome; a credencial entra apenas no
  processo Python que publica. O Wireless Debugging deve permanecer pareado
  somente com dispositivos confiáveis e em uma rede privada. O telefone deve
  ser dedicado ao robô, sem contas pessoais, senhas salvas ou tokens no perfil
  Chrome. Bloquear a tela ou usar modo headless não substitui essas medidas.
  Na execução recorrente, o Chrome já aberto é lido diretamente pelo CDP local
  via ADB: o Appium/UiAutomator2 fica disponível para configuração,
  diagnóstico e recuperação, mas não bloqueia cada coleta com um novo boot.
  A extração devolve somente a grade principal e os campos comerciais mínimos;
  a URL, a faixa exibida e todos os cards esperados são validados antes de
  aceitar uma página. O intervalo Android é de 1–2 segundos entre páginas.
  Para medir a otimização, `PICHAU_ESTRATEGIA_LEITURA=fetch` ou `rede` pode ser
  definido somente no arquivo privado do Termux. `fetch` tenta o payload SSR
  dentro da sessão e, no Android, pré-carrega em paralelo as páginas restantes
  depois de descobrir o total; `rede` captura a resposta HTML antes da montagem
  completa do DOM. Ambos têm fallback automático para DOM. O caminho DOM traz o Chrome
  para frente e bloqueia imagens, fontes e telemetria sem uso no catálogo.
  `PICHAU_ANDROID_ORDENACAO` aceita somente as ordenações
  públicas `name-asc`, `name-desc`, `price-asc` e `price-desc`; ela muda apenas
  a ordem de leitura, não o conjunto esperado de produtos. O padrão é vazio.
  Os logs registram duração e contagens, nunca HTML, cookies ou credenciais; a
  publicação usa lotes de 100 na mesma transação. O fetch Android tem limite
  controlado e cancela uma avaliação CDP que perdeu o prazo antes do fallback,
  evitando deixar requisições pendentes no Chrome. Falha em qualquer página
  pré-carregada aborta a coleta; não há publicação parcial.
  `scripts/pichau-android-appium.sh` mantém o Appium local em uma sessão tmux;
  a sessão UiAutomator2 força o relançamento do Chrome quando o processo antigo
  ficou aberto sem publicar DevTools após bloqueio, reboot ou reconexão ADB.
  o descritor do `flock` é fechado antes de iniciar ADB/tmux, para o serviço
  persistente não bloquear o próximo job;
  `scripts/pichau-android-worker.sh` consulta a fila a cada 30 segundos e
  executa o runner somente quando há solicitação do GitHub. O
  `pichau-android-schedule.sh` mantém o job 7301 como watchdog de recuperação,
  sem coleta independente; a coleta recorrente é enfileirada pelo workflow às
  09h, 14h e 20h de Brasília. `scripts/pichau-android-boot.sh` inicia primeiro
  worker/watchdog e depois o Appium no Termux:Boot, sem aguardar o `/status` do
  Appium no boot, e registra `var/log/robo-pichau/boot.log`. Na ROM Samsung
  testada, o Android mantém o receiver do Termux:Boot pendente até o primeiro
  desbloqueio após reiniciar; essa limitação precisa ser resolvida
  operacionalmente antes de declarar o aparelho autônomo. A bateria é uma
  condição operacional do Android: não há alerta automático; se o aparelho
  desligar, a fila permanece recuperável e o último catálogo válido continua
  no banco.
- A migration `../../migracoes/022_pichau_android_fila.sql` cria a fila
  idempotente com lease, claim atômico e estados de sucesso/falha. O workflow
  usa exclusivamente o secret `PICHAU_DISPATCH_DATABASE_URL`; o telefone
  mantém a `DATABASE_URL` privada do Termux, sempre com SSL e permissões
  restritas às tabelas Pichau e à fila.
- Não há envio SMTP/e-mail ativo; a Livelo persiste catálogo, histórico e alertas para a API.
- Com `DATABASE_URL`, as acompanhadas vêm de `loja` no Postgres. Banco vazio é
  válido e não aciona o TOML; sem banco, o arquivo permite diagnóstico local.
- A publicação da Livelo grava o catálogo atual em `parceiro_livelo` e uma
  medição histórica de cada parceiro válido em `pontuacao`, em uma única
  transação. Acompanhamento e alertas continuam exclusivos de `loja`.

## Qualidade (gates)

```bash
ruff check .
python -m pytest --cov --cov-fail-under=90
```

- O núcleo puro (modelos, extratores, alertas, ranking e retratos) **não
  faz I/O**; o mundo entra por portas/adaptadores.
- Dinheiro, cashback e pontuação usam `Decimal`/`NUMERIC` — nunca `float`/`double`.

## Referências

- Requisitos e regras numeradas: [`../../docs/prd/PRD-LIVELO.md`](../../docs/prd/PRD-LIVELO.md) e deltas
  `PRD-V2/V3/V4/V5.md`.
- Reativação dos workflows de coleta: [`../../.github/README.md`](../../.github/README.md)
  e [`../../ARQUIVO-PROJETO.md`](../../ARQUIVO-PROJETO.md).
