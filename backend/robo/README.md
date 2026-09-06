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
- O workflow hospedado continua usando `.[pichau]` e SeleniumBase. Para a
  tentativa Android, instale `.[pichau-android]`, mantenha Appium/UiAutomator2
  em `127.0.0.1` e use `PICHAU_MODO_NAVEGADOR=android`. No Samsung 32-bit,
  UiAutomator2 abre o Chrome nativo e `websocket-client` lê o DOM pelo CDP
  local via ADB; não há download de ChromeDriver ARM32. A listagem Android
  usa `pageSize=100`, exige a faixa completa renderizada inclusive na última
  página e reconcilia por URL com SKU histórico quando o DOM não o publica.
- No Termux, instale `libxml2`, `libxslt` e `libpq` antes do ambiente Python.
  O Android ARM32 usa `psycopg` puro contra o `libpq` do Termux; os runners
  Linux e desktop continuam usando `psycopg[binary]`. Se o ambiente virtual
  tiver sido criado antes do ajuste de arquitetura, complete-o com
  `python -m pip install "psycopg>=3.2"`. O script
  `scripts/pichau-android-run.sh` lê um arquivo privado
  `PREFIX/etc/robo-pichau/env`, exige modo `600`/`400`, `sslmode` seguro,
  `flock`, `termux-wake-lock` e um `.venv`; `PICHAU_ANDROID_ADB_PORT` é
  opcional para uma ponte ADB local durante a validação; ele não imprime a
  `DATABASE_URL`.
  Na execução recorrente, o Chrome já aberto é lido diretamente pelo CDP local
  via ADB: o Appium/UiAutomator2 fica disponível para configuração,
  diagnóstico e recuperação, mas não bloqueia cada coleta com um novo boot.
  A extração devolve somente a grade principal e os campos comerciais mínimos;
  a URL, a faixa exibida e todos os cards esperados são validados antes de
  aceitar uma página. O intervalo Android é de 1–2 segundos entre páginas.
  `scripts/pichau-android-appium.sh` mantém o Appium local em uma sessão tmux;
  o descritor do `flock` é fechado antes de iniciar ADB/tmux, para o serviço
  persistente não bloquear o próximo job;
  `scripts/pichau-android-schedule.sh` agenda uma janela aproximada de seis
  horas, somente em rede não tarifada e sem exigir carregador, e
  `scripts/pichau-android-boot.sh` inicia o Appium e pode ser instalado no
  Termux:Boot. A bateria é uma condição operacional do Android: não há alerta
  automático; se o aparelho desligar por falta de bateria, a tentativa termina
  e o último catálogo válido permanece no banco.
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
