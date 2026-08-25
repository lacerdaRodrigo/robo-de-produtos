# `backend/robo/` — Robôs Python (coleta e alerta)

Núcleo do backend: robôs que coletam das **fontes públicas** (Livelo e Shopping
Inter) e gravam no Postgres (Neon). É processado separadamente pelo GitHub
Actions a cada 3×/dia; não tem servidor próprio.

## Domínios isolados

São **três integrações independentes**, cada uma com código, tabelas e workflow
próprios — não misturam regras nem se afetam:

1. **Livelo** — filtra lojas favoritas e alerta por e-mail quando a pontuação
   cruza a régua (V2). Entrada: `src/robo_livelo/principal.py`.
2. **Inter — Sites parceiros** — catálogo de cashback (V3). Entrada:
   `src/robo_livelo/principal_inter.py`.
3. **Inter — Compre direto** — coleta de produtos das lojas escolhidas, com busca
   e histórico de 30 dias (V4). Entrada: `src/robo_livelo/principal_produtos_inter.py`.

## Estrutura

```text
backend/robo/
├── src/robo_livelo/   # código (domínio puro + portas + adaptadores)
├── testes/            # pytest (prefixo teste_)
├── config/            # lojas_favoritas.toml (catálogo Livelo)
├── scripts/           # utilitários (carregar_catalogo.py, medir_v4.py)
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
```

- O coletor do Inter exige `DATABASE_URL`.
- O e-mail da Livelo exige uma **Senha de Aplicativo** do Gmail (não é a senha).
- As lojas monitoradas ficam em `config/lojas_favoritas.toml`, fora do código.

## Qualidade (gates)

```bash
ruff check .
python -m pytest --cov --cov-fail-under=90
```

- O núcleo puro (modelos, extratores, alertas, ranking, montador de e-mail) **não
  faz I/O**; o mundo entra por portas/adaptadores.
- Dinheiro, cashback e pontuação usam `Decimal`/`NUMERIC` — nunca `float`/`double`.

## Referências

- Requisitos e regras numeradas: [`../../docs/PRD.md`](../../docs/PRD.md) e deltas
  `PRD-V2/V3/V4/V5.md`.
- Reativação dos workflows de coleta: [`../../.github/README.md`](../../.github/README.md)
  e [`../../ARQUIVO-PROJETO.md`](../../ARQUIVO-PROJETO.md).
