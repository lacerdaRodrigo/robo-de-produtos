# Site — Pontuação Livelo

Página pública com a pontuação atual das lojas favoritas, mais a edição protegida por senha. Lê o mesmo banco Neon que o robô alimenta a cada execução.

O **porquê** de cada decisão está no [`PRD-V2.md`](../docs/PRD-V2.md) — aqui fica só como rodar.

## O que ele mostra

- Todas as 132 favoritas, em promoção ou não (RN24). É o que responde "quanto a Renner dá hoje?" sem abrir a Livelo
- Por loja: pontuação atual, base e o valor que dispara o alerta (RN30)
- Carimbo de atualização sempre visível, que fica vermelho quando envelhece (RN26)
- Nenhuma imagem, fonte ou script de terceiro (RN25) — a identidade é cor e tipografia do sistema
- Funciona com JavaScript desligado (RNF14), inclusive os formulários de edição

## Rodando local

```bash
cd site
npm install
cp ../.env.example ../.env   # preencha DATABASE_URL, SENHA_SITE e SEGREDO_SESSAO
DATABASE_URL=... SENHA_SITE=... SEGREDO_SESSAO=... npm run dev
```

As três variáveis são obrigatórias. Nenhuma delas tem prefixo `NEXT_PUBLIC_`: a credencial do banco vive só no servidor (PRD-V2 §9.0), e o navegador nunca fala com o Postgres.

```bash
npm run testar   # vitest
npm run checar   # tsc --noEmit
npm run build
```

## Deploy na Vercel

1. **New Project** apontando para este repositório
2. **Root Directory**: `site` — defina ainda na tela de import, antes do primeiro Deploy
3. Environment Variables: `DATABASE_URL`, `SENHA_SITE`, `SEGREDO_SESSAO`, em Production e Preview

`SENHA_SITE` é credencial de vida longa, sem segundo fator e sem revogação individual — o trade-off está aceito no PRD-V2 §9.0, e é por isso que ela precisa ser longa e aleatória. `SEGREDO_SESSAO` é independente: assina o cookie de sessão, e trocá-lo derruba as sessões abertas sem trocar a senha.

### Root Directory não é opcional aqui

A raiz do repositório é um projeto Python. Apontando o projeto da Vercel para ela, a detecção acha o `pyproject.toml` primeiro e falha antes de olhar qualquer subpasta:

```
Error: No python entrypoint found. Set "tool.vercel.entrypoint" in
pyproject.toml or define an entrypoint in one of: app.py, index.py, ...
```

Esse erro significa Root Directory errado, não problema no site. Duas armadilhas:

- **Redeploy não relê a configuração do projeto.** Depois de corrigir Root Directory, um push novo é o que dispara build com a configuração nova; Redeploy repete o snapshot do build anterior.
- Se o projeto foi criado apontando para a raiz e continua falhando mesmo com o campo certo, apagar e importar de novo — com Root Directory definido **na criação** — sai mais barato que investigar.

Manter robô e site no mesmo repositório é decisão registrada: a fonte da verdade (`docs/PRD.md`) precisa ser uma só. O preço é este campo, uma vez.

## Estrutura

```
site/
├── app/
│   ├── page.tsx          # pública: leitura, sem sessão
│   ├── entrar/           # login por senha única, com limite de tentativas
│   ├── admin/            # edição (RF17): padrões globais, limiar por loja, catálogo
│   └── rodape.tsx        # aviso de não afiliação (PRD-V2 §9.3) e versão
├── lib/
│   ├── banco.ts          # consultas; a única camada que fala com o Postgres
│   ├── sessao.ts         # cookie assinado, comparação em tempo constante
│   └── formato.ts        # pt-BR sem converter NUMERIC para `number`
└── testes/               # vitest sobre as funções puras de formato
```

Toda edição passa por Server Action, e **toda Server Action confere a sessão de novo**. A página `/admin` já barra a navegação, mas Server Action é um endpoint: quem souber o caminho pode chamar direto.
