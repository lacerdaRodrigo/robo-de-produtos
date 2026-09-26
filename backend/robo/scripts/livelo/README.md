# Scripts Livelo

`carregar_catalogo.py` é utilitário administrativo para criar/carregar o
catálogo inicial a partir de `config/livelo/lojas_favoritas.toml`:

```bash
cd backend/robo
python scripts/livelo/carregar_catalogo.py
```

Ele lê `DATABASE_URL` do `.env`; não rode contra o Neon de produção sem
autorização e backup. A coleta recorrente usa `python -m
robo_livelo.principal` e é agendada pelo worker celular.
