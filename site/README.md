# Site — Pontuação Livelo

Página pública com a pontuação atual das lojas favoritas, mais a edição protegida por senha. Lê o mesmo banco Neon que o robô alimenta a cada execução.

O **porquê** de cada decisão está no [`PRD-V2.md`](../docs/PRD-V2.md) — aqui fica só como rodar.

## O que ele mostra

- Todas as 132 favoritas, em promoção ou não (RN24). É o que responde "quanto a Renner dá hoje?" sem abrir a Livelo
- Por loja: pontuação atual, base e o valor que dispara o alerta (RN30)
- A letra miúda da campanha, quando a própria Livelo publica uma (RN31) — dá para decidir se a promoção vale para a compra pretendida sem abrir o app dela
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

| URL | Nome no menu | Acesso | Faz |
|---|---|---|---|
| `/` | Painel | público | Todas as suas lojas em grade única, com busca por `?q=` e ordenar por `?ordenar=pontos\|alerta\|nome` (redesenho V4.6, 2026-08-13) |
| `/ajuda` | Ajuda | público | Perguntas e respostas sobre como o sistema decide |
| `/entrar` | — | público | Login. `?voltar=` devolve para a tela de origem |
| `/avisos` | Alertas | sessão, escondível | Padrão de todas as lojas e exceções (título da tela: "Quando me avisar") |
| `/lojas` | Lojas | sessão | Adicionar; remover em duas etapas; **Forçar atualização** |
| `/configuracoes` | — (ícone de engrenagem) | sessão | Liga/desliga pedaços da interface |

**O aviso próprio no cadastro pode ficar escondido — e por padrão continua visível (V2.3.4, invertido em 2026-08-12).** Existe desde que o limiar por loja virou possível: os campos "vezes acima do normal" e "mínimo de pontos" aparecem direto no formulário de `/lojas`, em branco. A flag `esconder_aviso_opcional_no_cadastro` controla isso — liga em `/configuracoes`, ícone de engrenagem no cabeçalho, mesmo sentido do toggle de Alertas abaixo: ligado (verde) sempre esconde. Guardada em cookie (`lib/flags.ts`), igual o tema, não no banco: é preferência de quem mexe no site, não dado que o robô lê, então não precisa de tabela nem migração. Ligada, o cadastro fica só com nome e categoria; `/avisos` continua sendo o lugar para o padrão global e para editar o limiar de uma loja já cadastrada, com ou sem a flag. O campo "Apelidos" saiu do formulário de cadastro (2026-08-12) — apelido de loja já cadastrada continua existindo e sendo reconhecido pelo robô (RN04), só não dá mais para cadastrar um na hora de criar a loja pelo site.

**A tela de Alertas inteira pode ficar escondida — e por padrão continua visível, como sempre foi.** É a mesma calibragem pendente de RN27/28 que motivou o aviso opcional acima, só que aplicada à tela inteira em vez de um campo: quem preferir não ver "Quando me avisar" até decidir usar limiar por loja liga `esconder_tela_alertas` em `/configuracoes`. Ligada, some "Alertas" do cabeçalho e do rodapé, some o botão "Ajustar alerta" dos cartões do Painel, e a rota `/avisos` redireciona para `/` mesmo digitada direto — nenhuma tela alcançável só pela URL vale aqui também. Mesmo mecanismo de cookie do `lib/flags.ts`, sem tabela nem migração.

**Nenhuma tela é alcançável só digitando a URL.** O cabeçalho aparece em todas, o menu muda conforme haja sessão, cada loja da lista tem atalho para ajustar o aviso dela, e toda ação redireciona de volta com um recado. Se alguma tela passar a exigir digitar endereço, é defeito.

**A linguagem da tela não é a do PRD.** O documento diz *multiplicador*, *piso* e *limiar*, porque são os nomes das colunas; a interface diz "vezes acima do normal" e "mínimo de pontos", e o termo técnico fica dentro do tooltip. Quem usa o site é uma pessoa só, e ela não deveria precisar do PRD aberto.

## O botão "Forçar atualização"

Pede ao GitHub que rode o robô na hora, em vez de esperar 9h, 14h ou 20h. Passa pelo Actions (`lib/github.ts`) porque a Vercel roda JavaScript e o robô é Python — reimplementar a leitura da Livelo aqui duplicaria RN21, RN23 e RN27 em duas linguagens, e duas fontes da verdade para a mesma regra é como se cria divergência silenciosa.

Exige `GITHUB_TOKEN_DISPARO` no ambiente: fine-grained, só este repositório, permissão *Actions: read and write*. Sem ele o botão aparece desabilitado explicando o que falta.

**Trava de 5 minutos** entre disparos (tabela `disparo_manual`, migração 004). RNF02 é compromisso de conduta, não detalhe técnico: um botão sem trava viraria dezenas de requisições à Livelo numa tarde de cadastro. Pedido recusado pelo GitHub não consome a janela.

Em `/lojas`, o bloco fica depois da tabela "Lojas cadastradas" — é a última coisa que se faz numa visita à tela, não a primeira, então não precisa competir por atenção com o formulário de cadastro.

## Tema claro/escuro (V2.3.3)

Botão no cabeçalho, ao lado de Entrar/Sair — cicla **automático → claro → escuro → automático** a cada clique. "Automático" segue `prefers-color-scheme` do sistema, sem gravar nada; escolher claro ou escuro grava um cookie (`tema`, `lib/tema.ts`) que vence tanto o claro quanto o escuro do sistema.

É um `<form>` de verdade, servido por uma Server Action (`acaoAlternarTema` em `app/acoes.ts`) — funciona com JavaScript desligado (RNF14), igual todo o resto do site. `app/layout.tsx` lê o cookie no servidor e escreve `data-tema` na tag `<html>`; `globals.css` decide a paleta a partir disso, sem nenhuma linha de JavaScript no navegador.

## Configurações (V2.3.4+)

Ícone de engrenagem no cabeçalho, ao lado do de tema — leva para `/configuracoes`. É onde ficam as flags de funcionalidade:

- **Aviso opcional no cadastro de loja** (`/lojas`) — desligado por padrão, até a calibragem do limiar global fechar (RN27/28, ver `docs/PENDENCIAS.md`).
- **Esconder a tela de Alertas** — desligado por padrão, a tela continua visível como sempre foi; quem ligar o interruptor esconde "Alertas" do menu, do rodapé e do botão "Ajustar alerta" no Painel, e bloqueia a rota `/avisos`.

Mesma ideia do tema — `lib/flags.ts` guarda cada flag num cookie próprio, não no banco. É preferência de quem edita o site, não regra que o robô consulta, então não precisa de tabela nem migração pra existir. Server Action de verdade (`acaoSalvarConfiguracoes` em `app/configuracoes/acoes.ts`), funciona sem JavaScript.

## Barra lateral e cor de ação (V4.6)

O cabeçalho fixo virou barra lateral: coluna fixa à esquerda a partir de 768px (Painel/Alertas/Lojas/Ajuda, com Configurações/Tema/Sair no rodapé da coluna), e uma barra superior compacta, com só os ícones, no celular. É sempre escura — não segue o tema claro/escuro do resto da página, do mesmo jeito que uma logomarca não trocaria de cor sozinha. O logo (`/public/logo.png`) ganhou um chip branco atrás dele ali: o quadrado "R$" da marca é quase branco, pensado pro fundo claro do resto do site, e sumia de contraste no fundo escuro da lateral sem isso.

A cor de ação geral (botões, links, foco de campo) virou indigo (`--marca`, em `globals.css`), e o rosa (`--acento`) ficou reservado só para o que pede atenção de verdade: cartão com `alertou`, etiqueta "Alerta ativo", o item "Turbinadas hoje" do resumo. Antes um só tom fazia as duas coisas; separar deixa "isso é um botão" e "isso é um alerta" visualmente distintos.

Ícones são SVG escritos à mão dentro de `componentes/cabecalho.tsx` — RN25 continua valendo, nenhum ícone vem de CDN. O restante do redesenho (Painel em destaque, tabela de Lojas, histórico de alertas) está em aberto — ver `docs/PENDENCIAS.md`.

## Tooltips sem JavaScript

`app/componentes/dica.tsx`: um `<button>` com `?` e um balão irmão. O CSS mostra o balão em `:hover` (mouse) e em `:focus-within` (teclado e toque — clicar dá foco). Nenhum estado, nenhum script, e o texto continua no DOM para leitor de tela achar pelo `aria-describedby`. No celular o balão vira fixo na base da janela, senão vazaria a tela quando o `?` estivesse perto da borda.

## Estrutura

```
site/
├── app/
│   ├── page.tsx          # pública: leitura, sem sessão
│   ├── ajuda/            # FAQ pública
│   ├── entrar/           # login por senha única, com limite de tentativas
│   ├── avisos/           # RF17: régua de alerta, global e por loja
│   ├── lojas/            # RF17: cadastro, com remoção em duas etapas
│   ├── componentes/      # barra lateral com menu, e a dica (tooltip)
│   └── rodape.tsx        # aviso de não afiliação (PRD-V2 §9.3) e versão
├── lib/
│   ├── banco.ts          # consultas; a única camada que fala com o Postgres
│   ├── sessao.ts         # cookie assinado, comparação em tempo constante
│   └── formato.ts        # pt-BR sem converter NUMERIC para `number`
└── testes/               # vitest sobre as funções puras de formato
```

Toda edição passa por Server Action, e **toda Server Action confere a sessão de novo**. A página `/admin` já barra a navegação, mas Server Action é um endpoint: quem souber o caminho pode chamar direto.
