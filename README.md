# Radar de Benefícios — Livelo e Shopping Inter

Monitora benefícios em fontes públicas: avisa por e-mail quando uma loja favorita
está com pontuação turbinada na Livelo e mostra o cashback e as condições das lojas
escolhidas no Shopping Inter (incluindo produtos do Compre direto, com busca e
histórico de 30 dias).

Sem servidor próprio: os robôs Python rodam no GitHub Actions, um Postgres (Neon)
guarda os catálogos e retratos, e um cliente **Flutter** (Web, Android e iOS) mostra
cada fonte sem misturar suas regras.

> **Status:** Livelo V2.0–V2.3 e a V3 do Shopping Inter estão publicadas. A V4 de
> produtos passou pelo primeiro aceite real com a Casas Bahia em 2026-08-17:
> 3.310 produtos ativos e busca local confirmada no Neon. O Flutter (app/) está em
> redesign por telas; a interface Web legada (Next.js) foi desativada em 2026-08-24
> e a API (sem prefixo de versão) foi arquivada em `backend/api/`.

## Estrutura do repositório

```text
robo/
├── app/            # Flutter (Web, Android e iOS) — única interface
├── backend/
│   ├── robo/       # robôs Python (Livelo, Inter Sites, Inter Compre direto)
│   └── api/        # API autenticada (arquivada, não roda)
├── docs/           # PRDs e documentação
├── migracoes/      # schema do Postgres (Neon) — 001 a 012
├── design-app/     # protótipos visuais Web/Mobile
├── .github/        # workflows do GitHub Actions
└── CLAUDE.md       # contexto para agentes de IA
```

## Como funciona

```text
Livelo         → extrator próprio → favoritas → alerta e retrato → e-mail
Shopping Inter → extrator próprio → catálogo → favoritas e retrato
Produtos Inter → lojas escolhidas → catálogo paginado → busca + histórico
```

Os coletores rodam três vezes ao dia e permanecem isolados. A V4 pagina somente
lojas escolhidas, com no máximo duas em paralelo. Nenhuma integração faz login;
todas leem apenas fontes públicas.

## Documentação

| Documento | Para quê |
|---|---|
| **[`docs/prd/PRD-LIVELO.md`](docs/prd/PRD-LIVELO.md)** | **Fonte da verdade.** Requisitos, regras de negócio, arquitetura, segurança e roadmap |
| [`docs/TESTES.md`](docs/TESTES.md) | Catálogo de casos de teste |
| **[`docs/PENDENCIAS.md`](docs/PENDENCIAS.md)** | O que falta fazer, em ordem. Lista viva |
| [`docs/prd/PRD-LIVELO-V2.md`](docs/prd/PRD-LIVELO-V2.md) | V2: data de validade, site próprio (desativado) e e-mail condicional |
| [`docs/prd/PRD-INTER-CASHBACK.md`](docs/prd/PRD-INTER-CASHBACK.md) | V3: Shopping Inter, cashback e condições |
| [`docs/prd/PRD-INTER-PRODUTOS.md`](docs/prd/PRD-INTER-PRODUTOS.md) | V4: catálogo completo, busca local e histórico de 30 dias |
| [`docs/prd/PRD-ADMINISTRACAO.md`](docs/prd/PRD-ADMINISTRACAO.md) | V5: limpeza administrativa |
| [`docs/guias/ROTEAMENTO_MODELOS_CODEX.md`](docs/guias/ROTEAMENTO_MODELOS_CODEX.md) | Escolha de modelo/esforço antes de mudar o projeto |
| [`docs/guias/EMAIL.md`](docs/guias/EMAIL.md) | Design e lições do e-mail |
| [`docs/guias/ARQUITETURA.md`](docs/guias/ARQUITETURA.md) | Histórico, substituído pelo PRD |
| [`ARQUIVO-PROJETO.md`](ARQUIVO-PROJETO.md) | Estado e memória da reorganização; como reativar a API |
| [`CLAUDE.md`](CLAUDE.md) | Contexto para agentes de IA |
| [`CHANGELOG.md`](CHANGELOG.md) | Histórico de versões |

Cada pasta tem seu próprio `README.md` com contexto local:
[`app/`](app/README.md), [`backend/robo/`](backend/robo/README.md),
[`backend/api/`](backend/api/README.md), [`migracoes/`](migracoes/README.md),
[`design-app/`](design-app/README.md) e [`.github/`](.github/README.md).

## Como rodar o Flutter

```bash
cd app
flutter pub get
flutter run -d chrome          # web
flutter run -d <id-android>    # android
flutter build web
```

O app consome a API (`/api/*` por domínio, ex.: `/api/livelo`, `/api/inter`), que
hoje está arquivada — para desenvolvimento local aponte
`--dart-define=API_URL=...` para uma API em execução. Veja
[`app/README.md`](app/README.md).

## Como rodar os robôs (backend)

```bash
cd backend/robo
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp ../../backend/api/examples/.env.example .env   # preencha com seus dados
python -m robo_livelo.principal
python -m robo_livelo.principal_inter
python -m robo_livelo.principal_produtos_inter
```

As lojas monitoradas ficam em `backend/robo/config/lojas_favoritas.toml`, fora do
código. O coletor do Inter exige `DATABASE_URL`; o e-mail da Livelo exige uma
**Senha de Aplicativo** do Gmail. Veja [`backend/robo/README.md`](backend/robo/README.md).

## GitHub Actions

Em **Settings → Secrets and variables → Actions**, crie os segredos usados pelos
workflows. Os coletores rodam às 09h, 14h e 20h (produtos às 09h30/14h30/20h30).
Veja a lista completa em [`.github/README.md`](.github/README.md).

> **Nota sobre reativação:** com o pacote em `backend/robo/src/`, recolocar o CI
> de coleta em pé exige rodar a partir de `backend/robo/` e ajustar o caminho de
> `config/lojas_favoritas.toml`.

## Testes

```bash
cd backend/robo && ruff check . && python -m pytest --cov --cov-fail-under=90
cd app && flutter analyze && flutter test
```

## Versionamento e rastreabilidade

O projeto usa [Semantic Versioning](https://semver.org/lang/pt-BR/) e
[Conventional Commits](https://www.conventionalcommits.org/pt-br/). O workflow
`versao.yml` analisa os commits na `main`, atualiza versão, `CHANGELOG.md`, cria a
tag e publica uma GitHub Release.

| Prefixo | Impacto |
|---|---|
| `fix:` | patch — correção compatível |
| `feat:` | minor — funcionalidade compatível |
| `feat!:` ou `BREAKING CHANGE` | major — mudança incompatível |
| `docs:`, `test:`, `style:`, `chore:` | não cria versão sozinho |

## Uso responsável

Projeto pessoal e educacional, **sem afiliação com Livelo, Banco Inter ou as lojas
exibidas**. Faz consultas públicas controladas três vezes ao dia, com paginação e
cooldown quando necessários, identificando-se honestamente.

Se uma fonte bloquear o acesso ou pedir para parar, o coletor correspondente para.
Nenhuma técnica de evasão de bloqueio será usada.

## Licença

MIT. Veja [`LICENSE`](LICENSE).
