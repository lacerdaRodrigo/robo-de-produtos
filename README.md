# Radar de Benefícios — Livelo e Shopping Inter

Monitora benefícios em duas fontes públicas: avisa por e-mail quando uma loja favorita está com pontuação turbinada na Livelo e mostra o cashback e as condições das lojas escolhidas no Shopping Inter.

Sem servidor próprio. Os coletores rodam separadamente no GitHub Actions; um Postgres (Neon) guarda os catálogos e retratos, e um site em Next.js mostra cada fonte sem misturar suas regras.

> **Status:** a integração Livelo V2.0–V2.3 está em produção. A V3 do Shopping Inter está implementada e validada no workspace; a migração `006` foi aplicada e a primeira sincronização real, em 2026-08-14, cadastrou 381 lojas. A publicação do novo código no GitHub/Vercel ainda depende de enviar estas mudanças ao repositório remoto. Suíte atual: 189 testes no robô e 31 no site, com 91,85% de cobertura Python.

> **Planejamento:** a V4 está especificada, mas não implementada. Ela adicionará o catálogo de produtos da área **Compre direto no Inter**, coletando todas as páginas expostas somente das lojas escolhidas, com busca local e histórico de 30 dias. Veja o [`PRD-V4.md`](docs/PRD-V4.md).

## Como funciona

```text
Livelo         → extrator próprio → favoritas → alerta e retrato → e-mail + site
Shopping Inter → extrator próprio → catálogo → favoritas e retrato → site
Produtos Inter → planejado: lojas escolhidas → catálogo paginado → busca + histórico
```

Os dois coletores implementados fazem uma consulta lógica por execução e rodam três vezes ao dia. A V4 planejada será diferente: por conter produtos, paginará somente as lojas escolhidas, com ritmo e isolamento próprios. Nenhuma integração faz login; todas leem apenas fontes públicas.

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

## Rodando no GitHub Actions

Em **Settings → Secrets and variables → Actions**, crie:

- `EMAIL_REMETENTE`
- `SENHA_APP_GMAIL`
- `EMAIL_DESTINO`
- `DATABASE_URL` (opcional para a Livelo; obrigatório para o Shopping Inter)

Os workflows `robo.yml` e `inter.yml` rodam separadamente às 09h, 14h e 20h (horário de Brasília) e também aceitam disparo manual.

## Testes

```bash
pytest --cov --cov-fail-under=90
cd site
npm run checar
npm run testar
npm run build
```

## Uso responsável

Projeto pessoal e educacional, **sem afiliação com Livelo, Banco Inter ou as lojas exibidas**. Faz uma consulta lógica por fonte e execução, três vezes ao dia, identificando-se honestamente.

Se uma fonte bloquear o acesso ou pedir para parar, o coletor correspondente para. Nenhuma técnica de evasão de bloqueio será usada — a análise completa está na Seção 10 do PRD e nos PRDs V3 e V4.

## Licença

MIT. Veja [`LICENSE`](LICENSE).
