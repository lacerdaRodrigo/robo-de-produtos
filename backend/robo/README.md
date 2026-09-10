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
  Wi-Fi já conectado pelo ADB. Quando disponível, descobre o serviço pareado
  por mDNS; builds Termux sem suporte mDNS usam a porta fixa privada definida
  em `PICHAU_ANDROID_WIFI_PORT`. Em todos os casos o destino é filtrado por
  `PICHAU_ANDROID_WIFI_HOST`. IP, porta, serial, código de pareamento e
  credenciais ficam somente no arquivo privado e nunca são escritos em logs,
  documentação ou saída do workflow.
  A configuração privada usa este formato, sempre com valores reais somente no
  Termux:

  ```text
  PICHAU_ANDROID_TRANSPORTE=wifi
  PICHAU_ANDROID_UDID=auto
  PICHAU_ANDROID_WIFI_HOST=<IP_PRIVADO_DO_ANDROID>
  PICHAU_ANDROID_WIFI_PORT=<PORTA_PRIVADA_ADB>
  PICHAU_ANDROID_WIFI_SERVICE=adb-tls-connect._tcp
  ```
  A porta fixa é um fallback para o ADB local e não é publicada no roteador.
  Nesta ROM Samsung ela precisa ser reativada por USB após cada reboot; sem
  reboot, o aparelho continua autônomo com a tela bloqueada.
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
  `scripts/pichau-android-appium.sh` aceita `start`, `stop` e `status`; o runner
  mantém a sessão tmux somente durante a coleta e a encerra ao sair. A sessão
  UiAutomator2 força o relançamento do Chrome quando o processo antigo ficou
  aberto sem publicar DevTools após bloqueio, reboot ou reconexão ADB.
  `scripts/pichau-android-worker.sh` consulta a fila a cada 30 segundos como
  tarefa foreground rastreada pelo Termux e mantém wake/Wi-Fi lock durante toda
  a vida do daemon. O runner não libera esse lock quando foi iniciado pelo
  worker. `pichau-android-schedule.sh` agenda o job 7301 a cada 15 minutos com
  rede `any` e sem condições de bateria/armazenamento; o job chama
  `pichau-android-recover.sh`, que só assume o daemon quando o `flock` está
  livre. `pichau-android-status.sh` verifica checkout, configuração, worker,
  watchdog, fila e ADB sem imprimir identificadores privados.
  `scripts/pichau-android-boot.sh` registra o watchdog e transfere o próprio
  processo ao worker; Appium permanece desligado quando não há coleta. Instale
  esse arquivo como link simbólico, não como cópia separada, para o boot usar o
  checkout atualizado:

  ```bash
  mkdir -p "$HOME/.termux/boot" "$HOME/.termux/boot-backups"
  if [[ -e "$HOME/.termux/boot/pichau-android-boot.sh" \
      && ! -L "$HOME/.termux/boot/pichau-android-boot.sh" ]]; then
    mv "$HOME/.termux/boot/pichau-android-boot.sh" \
      "$HOME/.termux/boot-backups/pichau-android-boot.sh.bak"
  fi
  ln -sfn "$PREFIX/opt/robo/backend/robo/scripts/pichau-android-boot.sh" \
    "$HOME/.termux/boot/pichau-android-boot.sh"
  ```

  Não mantenha backups em `.termux/boot`: o Termux:Boot executa todos os
  arquivos dessa pasta, independentemente da extensão.

  O Samsung deve ser dedicado, permanecer carregando, usar Wi-Fi privado e
  manter Termux, Termux:API e Termux:Boot como bateria irrestrita e fora das
  listas de suspensão. Após reboot, o primeiro desbloqueio continua obrigatório;
  depois dele a tela pode ficar bloqueada durante as coletas. A operação só será
  aceita após nove execuções agendadas consecutivas em 72 horas.

  #### Recuperação após desligamento ou reboot

  Tela bloqueada é um estado normal de operação; aparelho desligado ou reiniciado
  é uma interrupção diferente. O worker e o watchdog recuperam processos
  enquanto o Android continua ligado, mas esta ROM Samsung Android 14 sem root
  pode desativar a Depuração por Wi‑Fi após reboot. Nesse caso, com o aparelho
  ligado e após o primeiro desbloqueio:

  1. ative “Depuração por Wi‑Fi” nas Opções do desenvolvedor;
  2. conecte um computador autorizado por USB e execute `adb tcpip 5555`;
  3. confirme `pichau-android-status.sh` e retire o cabo de dados;
  4. bloqueie a tela novamente e deixe o telefone carregando no Wi‑Fi.

  Não considerar provada a autonomia após qualquer reboot sem novo teste real.
  Se esse procedimento manual não for aceitável, o controlador deve ser
  reavaliado para uma máquina Linux residencial sempre ligada.
- A migration `../../migracoes/022_pichau_android_fila.sql` cria a fila
  idempotente com lease, claim atômico e estados de sucesso/falha. O workflow
  identifica como `executor-offline` uma pendência sem claim após 20 minutos;
  quando o publicador voltar, ele encerra essas linhas antigas antes do próximo
  claim, sem coletá-las horas depois. Falhas do runner usam categorias seguras de
  ADB, Appium, configuração, navegador, acesso, dados, banco e parcial. O workflow
  usa preferencialmente o secret `PICHAU_DISPATCH_DATABASE_URL`; o telefone
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
