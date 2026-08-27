# `backend/robo/` — Robôs Python (coleta e persistência)

Núcleo do backend: robôs que coletam das **fontes públicas** (Livelo e Shopping
Inter) e gravam no Postgres (Neon). É processado separadamente pelo GitHub
Actions a cada 3×/dia; não tem servidor próprio.

## Domínios isolados

São **três integrações independentes**, cada uma com código, tabelas e workflow
próprios — não misturam regras nem se afetam:

1. **Livelo** — filtra lojas favoritas, calcula os alertas e grava o retrato
   para a API (V2). Entrada: `src/robo_livelo/principal.py`.
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
cp examples/.env.example .env   # preencha somente os valores locais
python -m robo_livelo.principal
python -m robo_livelo.principal_inter
python -m robo_livelo.principal_produtos_inter
```

- O coletor do Inter exige `DATABASE_URL`.
- As lojas monitoradas ficam em `config/lojas_favoritas.toml`, fora do código.
- O mapa completo de variáveis está em [`../../docs/CONFIGURACAO.md`](../../docs/CONFIGURACAO.md).

## Qualidade (gates)

```bash
ruff check .
python -m pytest --cov --cov-fail-under=90
```

- O núcleo puro (modelos, extratores, alertas e ranking) **não
  faz I/O**; o mundo entra por portas/adaptadores.
- Dinheiro, cashback e pontuação usam `Decimal`/`NUMERIC` — nunca `float`/`double`.

## Referências

- Requisitos e regras numeradas: [`../../docs/prd/PRD-LIVELO.md`](../../docs/prd/PRD-LIVELO.md) e deltas
  `PRD-V2/V3/V4/V5.md`.
- Reativação dos workflows de coleta: [`../../.github/README.md`](../../.github/README.md)
  e o estado atual em [`../../docs/PENDENCIAS.md`](../../docs/PENDENCIAS.md).
