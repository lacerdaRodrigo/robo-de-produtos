# Robô de Pontuação Turbinada — Livelo

Monitora as lojas parceiras da Livelo, filtra só as que importam pra você e avisa por e-mail, 3x ao dia, quando alguma está com pontuação turbinada.

Sem servidor, sem banco de dados, sem custo. Roda inteiro no GitHub Actions.

> **Status: V1.0 funcionando.** Rodou fim a fim contra a página real: 254 parceiros lidos, 22 promoções encontradas. 71 testes verdes, 94% de cobertura. Falta configurar os segredos no GitHub para a primeira execução agendada.

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
| **[`docs/PRD-V2.md`](docs/PRD-V2.md)** | Planejamento da V2: data de validade, página no GitHub Pages e e-mail condicional |
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

## Rodando no GitHub Actions

Em **Settings → Secrets and variables → Actions**, crie:

- `EMAIL_REMETENTE`
- `SENHA_APP_GMAIL`
- `EMAIL_DESTINO`

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
