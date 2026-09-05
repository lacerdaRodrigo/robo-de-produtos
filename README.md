# Radar de Benefícios — Livelo e Shopping Inter

Monitora benefícios em fontes públicas: publica catálogo, histórico e alertas da
Livelo e mostra cashback, condições e produtos do Shopping Inter, com busca e
histórico de 30 dias. O antigo canal SMTP/e-mail não está ativo no código atual.

Sem servidor próprio: os robôs Python rodam no GitHub Actions, um Postgres (Neon)
guarda os catálogos e retratos, e um cliente **Flutter** (Web, Android e iOS) mostra
cada fonte sem misturar suas regras.

> **Ciclo atual:** o Flutter está em redesign **mobile-only**, governado por
> [`AGENTS.md`](AGENTS.md) e pelo protótipo mobile. Web permanece no repositório,
> mas não é alvo nem gate deste ciclo. Central de Alertas, fechamento externo do
> App Check e confirmação operacional das migrations 016/017 continuam pendentes.

## Estrutura do repositório

```text
robo/
├── app/            # Flutter (Web, Android e iOS) — única interface
├── backend/
│   ├── robo/       # robôs Python (Livelo, Inter Sites, Inter Compre direto)
│   └── api/        # API autenticada consumida pelo Flutter
├── docs/           # PRDs e documentação
├── migracoes/      # schema versionado do Postgres; aplicação é operação externa
├── design-app/     # protótipo mobile atual e referências preservadas
├── .github/        # workflows do GitHub Actions
├── AGENTS.md       # contrato operacional da branch re-design
└── CLAUDE.md       # contexto histórico complementar
```

## Como funciona

```text
Livelo         → extrator próprio → catálogo atual + histórico completo → alerta das acompanhadas
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
| [`docs/prd/PRD-CATEGORIAS-INTER-FONTE-OFICIAL.md`](docs/prd/PRD-CATEGORIAS-INTER-FONTE-OFICIAL.md) | Delta: categorias externas do Shopping Inter e limpeza da taxonomia Radar |
| [`docs/prd/PRD-ADMINISTRACAO.md`](docs/prd/PRD-ADMINISTRACAO.md) | V5: limpeza administrativa |
| [`docs/guias/ROTEAMENTO_MODELOS_CODEX.md`](docs/guias/ROTEAMENTO_MODELOS_CODEX.md) | Escolha de modelo/esforço antes de mudar o projeto |
| [`ARQUIVO-PROJETO.md`](ARQUIVO-PROJETO.md) | Estado e memória da reorganização; como reativar a API |
| [`CLAUDE.md`](CLAUDE.md) | Contexto para agentes de IA |
| [`CHANGELOG.md`](CHANGELOG.md) | Histórico de versões |

Cada pasta tem seu próprio `README.md` com contexto local:
[`app/`](app/README.md), [`backend/robo/`](backend/robo/README.md),
[`backend/api/`](backend/api/README.md), [`migracoes/`](migracoes/README.md),
[`design-app/`](design-app/README.md) e [`.github/`](.github/README.md).

## Como rodar o Flutter

```bash
make dev                       # Android conectado, usando a branch atual
make dev DEVICE=emulator-5554  # escolhe outro Android
make apk                       # gera o APK de release para instalar manualmente
```

O alvo detecta o primeiro Android disponível e executa o checkout atual. Para
trocar a API ou o App Check, passe `API_URL=...` e `APP_CHECK=true` no comando.
Após `make apk`, o arquivo fica em
`app/build/app/outputs/flutter-apk/app-release.apk`.

O app consome a API autenticada (`/api/*` por domínio, ex.: `/api/livelo`,
`/api/inter`). Para desenvolvimento local, aponte
`--dart-define=API_URL=...` para a instância desejada. Veja
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

Com `DATABASE_URL`, as lojas acompanhadas ficam no Postgres; o TOML é reserva
somente para indisponibilidade e não repõe um banco que respondeu vazio. Os
robôs publicam seus retratos no banco e não possuem notificador SMTP ativo. Veja
[`backend/robo/README.md`](backend/robo/README.md).

## GitHub Actions

Em **Settings → Secrets and variables → Actions**, crie os segredos usados pelos
workflows. Os coletores rodam às 09h, 14h e 20h (produtos às 09h30/14h30/20h30).
Veja a lista completa em [`.github/README.md`](.github/README.md).

> **Nota sobre reativação:** com o pacote em `backend/robo/src/`, recolocar o CI
> de coleta em pé exige rodar a partir de `backend/robo/` e ajustar o caminho de
> `config/lojas_favoritas.toml`.

## Validação no ciclo mobile

```bash
cd app
dart format --output=none --set-exit-if-changed lib test
flutter analyze
find test -type f -name '*_test.dart' \
  ! -name 'app_smoke_test.dart' \
  ! -name 'controlador_painel_livelo_test.dart' \
  ! -name 'pagina_painel_livelo_test.dart' \
  -print0 | xargs -0 flutter test --exclude-tags 'golden || web'
```

Rode TypeScript/ESLint ou Ruff apenas quando o componente correspondente for
alterado. Goldens, integration, E2E, smoke, performance e Web não são gates do
ciclo atual; os testes existentes permanecem preservados.

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
