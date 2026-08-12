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

## Content-Security-Policy e o nonce

A política tem nonce por requisição (`middleware.ts`), e não cabeçalho estático. Motivo registrado porque custou um deploy quebrado:

`script-src 'self'` parece certo e não é. O Next embute o payload de dados da página em `<script>` **inline** — 43 deles. Com a política estrita sem nonce, o navegador recusa todos, o React encontra um stream vazio, dispara `Error: Connection closed` e **apaga o HTML que o servidor mandou correto**. O sintoma é cruel: com JavaScript desligado a página funciona; com JavaScript ligado, fica em branco.

Verificar por `curl` não pega isso — o HTML servido está perfeito. Só abrindo no navegador.

O preço do nonce é a página deixar de ser estática: nonce muda a cada requisição e não sobrevive a cache. Com 3 execuções por dia e visitas de uma pessoa, uma consulta por visita é irrelevante — e o carimbo de RN26 passa a nunca mostrar idade de cache.

## Telas

| URL | Nome | Acesso | Faz |
|---|---|---|---|
| `/` | Pontuação | público | Todas as suas lojas, turbinadas primeiro, com busca por `?q=` |
| `/ajuda` | Ajuda | público | Perguntas e respostas sobre como o sistema decide |
| `/entrar` | — | público | Login. `?voltar=` devolve para a tela de origem |
| `/avisos` | Quando me avisar | sessão | Padrão de todas as lojas e exceções |
| `/lojas` | Cadastrar lojas | sessão | Adicionar; remover em duas etapas |

**Nenhuma tela é alcançável só digitando a URL.** O cabeçalho aparece em todas, o menu muda conforme haja sessão, cada loja da lista tem atalho para ajustar o aviso dela, e toda ação redireciona de volta com um recado. Se alguma tela passar a exigir digitar endereço, é defeito.

**A linguagem da tela não é a do PRD.** O documento diz *multiplicador*, *piso* e *limiar*, porque são os nomes das colunas; a interface diz "vezes acima do normal" e "mínimo de pontos", e o termo técnico fica dentro do tooltip. Quem usa o site é uma pessoa só, e ela não deveria precisar do PRD aberto.

## Tooltips sem JavaScript

`app/componentes/dica.tsx`: um `<button>` com `?` e um balão irmão. O CSS mostra o balão em `:hover` (mouse) e em `:focus-within` (teclado e toque — clicar dá foco). Nenhum estado, nenhum script, e o texto continua no DOM para leitor de tela achar pelo `aria-describedby`. No celular o balão vira fixo na base da janela, senão vazaria a tela quando o `?` estivesse perto da borda.

Cada balão tem **uma frase dizendo o que é e um exemplo com número de verdade**, separados — é o exemplo que faz a ficha cair, e ele só funciona visivelmente apartado da definição. O texto evita o vocabulário do PRD: nada de "limiar", "piso" ou "correspondência exata".

Os dois números que se repetem em cada uma das 131 lojas — *normal da loja* e *avisa a partir de* — são explicados **uma vez, numa legenda acima da lista**, e não por cartão. Um `?` por cartão daria mais de 200 ícones na mesma página, e o que deveria chamar atenção viraria textura de fundo.

## Estrutura

```
site/
├── app/
│   ├── page.tsx          # pública: leitura, sem sessão
│   ├── ajuda/            # FAQ pública
│   ├── entrar/           # login por senha única, com limite de tentativas
│   ├── avisos/           # RF17: régua de alerta, global e por loja
│   ├── lojas/            # RF17: cadastro, com remoção em duas etapas
│   ├── componentes/      # cabeçalho com menu, e a dica (tooltip)
│   └── rodape.tsx        # aviso de não afiliação (PRD-V2 §9.3) e versão
├── lib/
│   ├── banco.ts          # consultas; a única camada que fala com o Postgres
│   ├── sessao.ts         # cookie assinado, comparação em tempo constante
│   └── formato.ts        # pt-BR sem converter NUMERIC para `number`
└── testes/               # vitest sobre as funções puras de formato
```

Toda edição passa por Server Action, e **toda Server Action confere a sessão de novo**. A página `/admin` já barra a navegação, mas Server Action é um endpoint: quem souber o caminho pode chamar direto.
