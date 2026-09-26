# Scripts Inter

`medir_v4.py` mede uma loja do Compre direto sem publicar no banco:

```bash
cd backend/robo
python scripts/inter/medir_v4.py --loja casas-bahia
```

A execução normal é feita por `python -m robo_inter.principal_inter` para Sites
parceiros e `python -m robo_inter.principal_produtos_inter` para Compre direto.
O worker celular chama as duas entradas em série; não confundir as fontes.
