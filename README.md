# Radar de Benefícios — Livelo e Shopping Inter

Monitora benefícios em duas fontes públicas: avisa por e-mail quando uma loja favorita está com pontuação turbinada na Livelo e mostra o cashback e as condições das lojas escolhidas no Shopping Inter.

Sem servidor próprio. Os coletores rodam separadamente no GitHub Actions; um Postgres (Neon) guarda os catálogos e retratos, e um site em Next.js mostra cada fonte sem misturar suas regras.

> **Status:** Livelo V2.0–V2.3 e a V3 do Shopping Inter estão publicadas. A V4 de produtos passou pelo primeiro aceite real com a Casas Bahia em 2026-08-17: 111 vendedores sincronizados, 94 páginas coletadas, 3.310 produtos ativos e busca local do Motorola Edge 60 Pro confirmada no Neon. Suíte atual: 210 testes no robô e 38 no site, com 94,16% de cobertura do núcleo puro.

> **Aceite em andamento:** a V4 possui coletor, persistência, site e workflow matricial. Casas Bahia é a única loja de produtos selecionada; Ponto e o dimensionamento para mais lojas continuam como próximos gates. Veja o [`PRD-V4.md`](docs/PRD-V4.md).

## Como funciona

```text
Livelo         → extrator próprio → favoritas → alerta e retrato → e-mail + site
Shopping Inter → extrator próprio → catálogo → favoritas e retrato → site
Produtos Inter → lojas escolhidas → catálogo paginado + partição segura → busca + histórico
```

Os coletores rodam três vezes ao dia e permanecem isolados. A V4 pagina somente lojas escolhidas, com no máximo duas em paralelo e pausa de 1,5 s entre páginas. Nenhuma integração faz login; todas leem apenas fontes públicas.

## Documentação

| Documento | Para quê |
|---|---|
| **[`PRD.md`](docs/PRD.md)** | **Fonte da verdade.** Visão, requisitos, regras de negócio, arquitetura, modelo de dados, segurança e roadmap |
| [`docs/TESTES.md`](docs/TESTES.md) | Catálogo de casos de teste |
| **[`docs/PENDENCIAS.md`](docs/PENDENCIAS.md)** | O que falta fazer, em ordem. Lista viva |
| **[`docs/PRD-V2.md`](docs/PRD-V2.md)** | Planejamento da V2: data de validade, site próprio com edição (Next.js na Vercel, Postgres no Neon) e e-mail condicional |
| **[`docs/PRD-V3.md`](docs/PRD-V3.md)** | Fonte da verdade da V3: Shopping Inter separado da Livelo, com cashback e condições da promoção |
| **[`docs/PRD-V4.md`](docs/PRD-V4.md)** | Especificação da V4: catálogo completo exposto das lojas diretas escolhidas, busca local e histórico de 30 dias |
| [`docs/ROTEAMENTO_MODELOS_CODEX.md`](docs/ROTEAMENTO_MODELOS_CODEX.md) | Cola para escolher modelo e esforço antes de mudar o projeto |
| [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) | Histórico. Substituído pelo PRD, mantido pelo dicionário de lojas e categorias |
| [`CLAUDE.md`](CLAUDE.md) | Contexto para agentes de IA que trabalhem no projeto |

Decisão técnica não se explica aqui. Se você quer saber *por que* `requests` em vez de Playwright, ou por que não existe histórico entre execuções, está tudo no PRD.

## Rodando localmente

```bash
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -e ".[dev]"
cp .env.example .env           # preencha com seus dados
python -m robo_livelo.principal
python -m robo_livelo.principal_inter
python -m robo_livelo.principal_produtos_inter
```

O coletor do Inter exige `DATABASE_URL`. Para o e-mail da Livelo, você também vai precisar de uma **Senha de Aplicativo** do Gmail — não é a senha da conta:

1. Ative a verificação em 2 etapas na conta Google
2. Gere a senha em https://myaccount.google.com/apppasswords
3. Cole o código de 16 caracteres no `.env`

### Escolhendo lojas da Livelo

As lojas monitoradas ficam em `config/lojas_favoritas.toml`, fora do código:

```toml
[[loja]]
nome = "Casas Bahia"
apelidos = ["Casas Bahia Oficial"]
categoria = "Marketplace / Varejo Geral"
```

O campo `apelidos` existe porque o reconhecimento é por nome exato: se a Livelo passar a exibir uma variação do nome, ela precisa ser cadastrada aqui, senão a loja some do e-mail.

Opcionalmente, uma loja pode ter limiar próprio de alerta — `multiplicador` e `piso_pontos`. Ausentes, valem os padrões globais.

Com `DATABASE_URL` no ambiente, o catálogo passa a vir do Postgres e este arquivo vira **reserva**: se o banco não responder, a execução continua com o TOML e registra um aviso no log. Sem `DATABASE_URL`, o arquivo é a única fonte — que é o caso de quem clona o projeto e roda na própria máquina.

### Escolhendo lojas do Shopping Inter

Depois da primeira execução de `principal_inter`, entre no site, abra **Lojas Inter**, procure por nome e clique em **Acompanhar**. A página pública **Shopping Inter** passa a mostrar o cashback principal, a condição para não-correntista quando existir e a descrição completa da promoção. Todos os cartões usam o link genérico aprovado do Shopping Inter.

### Escolhendo lojas de produtos do Shopping Inter

Depois do job de preparação da V4, entre em **Produtos → Lojas de produtos** e selecione os vendedores desejados. O site nunca consulta o Inter durante uma busca: ele lê o último snapshot válido no Neon. A primeira loja validada é a Casas Bahia; amplie a seleção gradualmente.

## Rodando no GitHub Actions

Em **Settings → Secrets and variables → Actions**, crie:

- `EMAIL_REMETENTE`
- `SENHA_APP_GMAIL`
- `EMAIL_DESTINO`
- `DATABASE_URL` (opcional para a Livelo; obrigatório para o Shopping Inter)

Os workflows `robo.yml` e `inter.yml` rodam às 09h, 14h e 20h. `produtos-inter.yml` começa às 09h30, 14h30 e 20h30, gera uma matriz somente com lojas selecionadas e limita a concorrência a duas. Todos também aceitam disparo manual.

## Testes

```bash
pytest --cov --cov-fail-under=90
cd site
npm run checar
npm run testar
npm run build
```


## Versionamento e rastreabilidade

O projeto usa [Semantic Versioning](https://semver.org/lang/pt-BR/) e
[Conventional Commits](https://www.conventionalcommits.org/pt-br/). A versão não é editada
manualmente: o workflow `versao.yml` analisa os commits na `main`, atualiza
`pyproject.toml`, `src/robo_livelo/__init__.py`, `site/lib/versao.ts` e
`CHANGELOG.md`, cria a tag e publica uma GitHub Release.

| Prefixo | Impacto |
|---|---|
| `fix:` | patch — correção compatível |
| `feat:` | minor — funcionalidade compatível |
| `feat!:` ou `BREAKING CHANGE` | major — mudança incompatível |
| `docs:`, `test:`, `style:`, `chore:` | não cria versão sozinho |

O histórico público fica em [Releases](https://github.com/lacerdaRodrigo/robo-livelo/releases)
e no [CHANGELOG](CHANGELOG.md). O site também possui a tela **Histórico de versões**.

## Uso responsável

Projeto pessoal e educacional, **sem afiliação com Livelo, Banco Inter ou as lojas exibidas**. Faz consultas públicas controladas três vezes ao dia, com paginação e cooldown quando necessários, identificando-se honestamente.

Se uma fonte bloquear o acesso ou pedir para parar, o coletor correspondente para. Nenhuma técnica de evasão de bloqueio será usada — a análise completa está na Seção 10 do PRD e nos PRDs V3 e V4.

## Licença

MIT. Veja [`LICENSE`](LICENSE).
