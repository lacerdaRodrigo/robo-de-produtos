# Robô de Pontuação Turbinada — Livelo

Monitora as lojas parceiras da Livelo, filtra só as que importam pra você e avisa por e-mail, 3x ao dia, quando alguma está com pontuação turbinada.

Sem servidor, sem banco de dados, sem custo. Roda inteiro no GitHub Actions.

> **Status: V2.0 em produção e validada contra a página real** (2026-08-11): 254 parceiros lidos, 31 em promoção. O extrator lê o payload JSON da página em vez de raspar o HTML, e o e-mail mostra validade da promoção, pontuação base e marcação de Clube. O catálogo de lojas vem do Postgres (V2.1), com o arquivo como reserva, e o alerta é decidido por múltiplo da pontuação base, não pela etiqueta da Livelo (V2.2). 139 testes verdes, 96% de cobertura.

## Como funciona

```
página da Livelo → extrator → filtro por loja favorita → montador → e-mail
```

Uma requisição HTTP por execução, três execuções por dia. O robô nunca faz login na Livelo — lê apenas a página pública de parceiros.

## Documentação

| Documento | Para quê |
|---|---|
| **[`PRD.md`](docs/PRD.md)** | **Fonte da verdade.** Visão, requisitos, regras de negócio, arquitetura, modelo de dados, segurança e roadmap |
| [`docs/TESTES.md`](docs/TESTES.md) | Catálogo de casos de teste |
| **[`docs/PENDENCIAS.md`](docs/PENDENCIAS.md)** | O que falta fazer, em ordem. Lista viva |
| **[`docs/PRD-V2.md`](docs/PRD-V2.md)** | Planejamento da V2: data de validade, site próprio com edição (Next.js na Vercel, Postgres no Neon) e e-mail condicional |
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
```

Você vai precisar de uma **Senha de Aplicativo** do Gmail — não é a senha da conta:

1. Ative a verificação em 2 etapas na conta Google
2. Gere a senha em https://myaccount.google.com/apppasswords
3. Cole o código de 16 caracteres no `.env`

### Escolhendo suas lojas

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

## Rodando no GitHub Actions

Em **Settings → Secrets and variables → Actions**, crie:

- `EMAIL_REMETENTE`
- `SENHA_APP_GMAIL`
- `EMAIL_DESTINO`
- `DATABASE_URL` (opcional — sem ele, o catálogo vem do TOML)

O workflow roda às 09h, 14h e 20h (horário de Brasília) e também sob disparo manual.

## Testes

```bash
pytest
```

## Uso responsável

Projeto pessoal e educacional, **sem qualquer afiliação com a Livelo**. Faz uma requisição por execução à página pública de parceiros, três vezes ao dia, identificando-se honestamente.

Se a Livelo bloquear o acesso ou pedir para parar, o projeto para. Nenhuma técnica de evasão de bloqueio será usada — a análise completa está na Seção 10 do PRD.

## Licença

MIT. Veja [`LICENSE`](LICENSE).
