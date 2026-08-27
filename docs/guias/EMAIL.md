# O e-mail e a marca — redesign de 2026-08-13

Registro do que mudou no e-mail diário e de onde veio a marca "Pontuação Livelo" (R$ virando ponto), pra quem mexer em `montador_email.py` ou nos assets do site depois não precisar reconstruir o raciocínio do zero.

## Por que mexer

O layout original (herdado da V2.0) fazia o trabalho — RN07, RN08, RN10 a RN12, RN22, RN23 todos corretos — mas era difícil de escanear rápido: card com borda fina cinza quase invisível, ponto do mesmo tamanho do resto do texto, categoria como título pesado repetido 7-8 vezes por e-mail. O pedido foi explícito: "o email vem todo feio, vamos melhorar ele para ser mais fácil de ver as promoções".

Passou por três rodadas até fechar:

1. **v1-v2**: card com borda + texto colorido. Rejeitado — "muito parecido com o atual", "cartão sumia no fundo branco" (a borda de 1px era claro demais pra notar).
2. **v3**: bloco de cor sólida (não mais borda fina) + ranking "3 melhores de hoje" no topo, ordenado por quantas vezes acima do normal (mesma conta de RN27). Aprovado o bloco de cor; o ranking saiu depois a pedido.
3. **v4-v5 (final)**: ranking removido, descrição da campanha (`descricao_campanha`, RN31) some abaixo de cada card com "…mais" pra expandir, e a marca (ver abaixo) assina o topo e o rodapé.

## O design final

Cada oferta é uma "ficha": bloco de cor sólida à esquerda com o número de pontos grande (`.bk`), informação da loja à direita (`.ib`) com nome, "X pontos por {moeda} 1" por extenso, badges (validade/Termina hoje!/Clube) e o link "Ver oferta". Categoria vira um selo colorido com contador ("Eletrônico · 3 lojas") em vez de título do tamanho do nome da loja.

A cor de cada categoria vem do mesmo ciclo de sempre (`_CORES`, agora com 6 tons curados em vez de 8 ad-hoc), aplicada uma vez por card via a custom property CSS `--c` no elemento `.bw` (o wrapper do card) — `.bk` e `.cta` leem `var(--c)` em vez de repetir `style='background:...'`/`style='color:...'` em cada elemento. Menos bytes, mesmo visual.

### Descrição expansível, sem JavaScript

`descricao_campanha` (letra miúda que a Livelo manda por trás de `legalTerms`, RN31) aparece abaixo do card:

- **Uma frase só** → aparece inteira, sem nada clicável (não faria sentido esconder o que já apareceu todo).
- **Mais de uma frase** → a primeira fica sempre visível; o resto entra num `<details>/<summary>` HTML puro, atrás de um "… mais" que vira "▲ menos" ao abrir. Sem JavaScript — Gmail (e a maioria dos clientes de e-mail) não roda script no corpo da mensagem, mas `<details>` é HTML declarativo, então funciona.

O "resto" (o que fica atrás do "…mais") **não repete a primeira frase** — só o texto que vem depois dela — e tem teto de 60 caracteres (`_LIMITE_RESTO` em `montador_email.py`), cortado sempre numa fronteira de espaço, nunca no meio de uma palavra. O regulamento completo continua a um clique em "Ver oferta", no site da Livelo — o e-mail não precisa reproduzir a letra miúda inteira.

### Por que o teto existe: C05

O Gmail corta a exibição de e-mails acima de ~102 KB e esconde o resto atrás de "Ver mensagem inteira" — é a restrição C05 do PRD, e o pior caso (as 132 favoritas do `config/lojas_favoritas.toml`, todas em promoção com Clube e descrição de campanha no mesmo dia) é o que `teste_pior_caso_cabe_no_limite_do_gmail` guarda. Esse teste é o motivo de três decisões deste redesign que, isoladas, pareceriam prematuras:

- CSS num único `<style>` no `<head>`, em vez de inline repetido em cada card (era a maior fatia do peso antigo).
- Nomes de classe curtos (`.bk`, `.ib`, `.mt`...) — cada letra a menos é um byte a menos multiplicado por até 132 cards.
- O teto de 60 caracteres no "resto" da descrição.

Com as 132 lojas, Clube, "Até X" e descrição de campanha longa em todas — cenário pior que qualquer dia real —, o e-mail fica em ~95,6 KB, com **~8,6 KB de folga** antes do corte do Gmail. Se esse teste falhar depois de uma mudança, o e-mail cresceu demais: revise `_ESTILO`, os nomes de classe, ou `_LIMITE_RESTO` antes de mexer no catálogo.

## A marca

### O processo

Pedido: um PNG "pra dar mais ar profissional", pro e-mail e pro site. A primeira ideia (barra de progresso do Painel virada em símbolo) foi rejeitada — abstrata demais, não lembrava dinheiro nem ponto. A segunda rodada trouxe quatro ideias em cima do que o sistema realmente faz — pontos, dinheiro, multiplicação —, e a escolhida foi:

**R$ vira ponto**: uma caixa neutra com "R$" (o real que você gasta), uma seta vermelha, e um círculo vermelho com "P" (o ponto que sobra maior que o normal). A própria forma conta a história da conversão — metade dinheiro, metade ponto — sem precisar de texto.

### Onde vive

- **Fonte vetorial**: `site/public/logo.svg` (112×112, mesma arte usada pra gerar todo o resto).
- **Site**: `<img src="/logo.png">` no cabeçalho (`site/app/componentes/cabecalho.tsx`, 22px) e no rodapé (`site/app/rodape.tsx`, 16px, opacidade reduzida), presentes em toda tela porque `Cabecalho`/`Rodape` são compartilhados.
- **Título do navegador**: `site/app/icon.png` e `site/app/apple-icon.png` (180×180) — convenção do Next.js App Router (`app/icon.png`), que gera sozinho as tags `<link rel="icon">`/`apple-touch-icon` no `<head>`. Não precisou de `favicon.ico` nem configuração manual.
- **E-mail**: `_LOGO_URL` em `montador_email.py`, apontando pra `https://robo-livelo.vercel.app/logo.png` — assina o topo (30×30) e, apagada, o rodapé (16×16, ao lado da versão).

### Por que URL hospedada no e-mail, e não base64 nem `<svg>` inline

A primeira versão embutia o PNG em base64 (`data:image/png;base64,...`), pensando em evitar o "Exibir imagens abaixo" que o Gmail mostra pra imagem remota. **Errado, confirmado ao vivo em 2026-08-13**: o Gmail simplesmente descarta `<img src="data:...">` no corpo de um e-mail recebido — sem aviso, sem placeholder de "mostrar imagem", a tag some. Funciona perfeitamente numa página web (é assim que os protótipos deste redesign foram revisados), não funciona em e-mail. É por isso que nenhum template de e-mail marketing do mercado embute logo em base64 — todos hospedam a imagem e apontam uma URL, que é exatamente o padrão que este e-mail usa agora.

`<svg>` inline também não é opção: o Gmail não renderiza SVG dentro do corpo do e-mail de forma confiável — por isso `site/public/logo.svg` é rasterizado pra PNG antes de qualquer uso fora do site.

Efeito colateral bom: tirar o base64 (~3,2 KB fixos, repetidos nos dois usos) devolveu ~6,3 KB de folga no orçamento do C05 — o pior caso (132 lojas, Clube, descrição de campanha longa em todas) caiu pra ~93 KB, **~11 KB de folga** antes do corte do Gmail.

### Como gerar os PNGs de novo, se a arte mudar

`site/public/logo.svg` é a fonte. Os PNGs foram gerados com [cairosvg](https://cairosvg.org/) — não é dependência do projeto (o núcleo não faz I/O e o site não precisa rasterizar nada em runtime), só uma ferramenta usada uma vez pra gerar os arquivos:

```bash
pip install cairosvg
python3 -c "
import cairosvg
for tamanho in (512, 180):
    cairosvg.svg2png(
        url='site/public/logo.svg',
        write_to=f'logo-{tamanho}.png',
        output_width=tamanho,
        output_height=tamanho,
    )
"
```

`logo-180.png` → copiar pra `site/app/icon.png`, `site/app/apple-icon.png` e `site/public/logo.png` (redeployar o site publica a nova `/logo.png`, que é a URL fixa que o e-mail já aponta — nada muda em `montador_email.py`).

## Testes

`testes/teste_montador_email.py`, CT-169 a CT-173: descrição com/sem "…mais", card sem descrição não ganha rodapé, corte no "resto" respeita fronteira de palavra, marca presente no topo e no rodapé (URL, nunca `data:`). O guarda de peso (`teste_pior_caso_cabe_no_limite_do_gmail`) ganhou uma descrição de campanha longa em todas as 132 lojas — antes do redesign ele não testava esse campo, e era a maior fatia de peso do e-mail novo.

## Duas lições do Gmail que valem para qualquer mudança futura no e-mail

Descobertas ao vivo em 2026-08-13, testando o e-mail de verdade na caixa de entrada — não dá pra confiar só no preview de navegador:

1. **`<style>` precisa morar dentro de `<head>`.** Sem head explícito, o Gmail descarta a folha de estilo inteira na sanitização e o e-mail vira texto corrido, sem cor nem layout nenhum.
2. **`<img src="data:...">` não sobrevive.** Vira PNG hospedado (ver acima).
3. **Custom property CSS (`--x`) num `style=` inline também não sobrevive.** A primeira versão deste redesign definia a cor da categoria uma vez (`style='--c:#e11d48'` no card) e deixava os filhos lerem `var(--c)`, pra economizar bytes. O Gmail remove `--c` do atributo `style` na sanitização (mas aceita `background`/`color` normalmente), então `var(--c)` caía no vazio e os blocos ficavam sem cor. A cor da categoria volta a ser `style='background:...'`/`style='color:...'` explícito em cada elemento que precisa dela.

Regra prática: **qualquer mudança de HTML/CSS no e-mail precisa ser confirmada abrindo o e-mail de verdade no Gmail** (disparar `gh workflow run robo.yml --ref main` e checar a caixa de entrada), não só olhando um preview em navegador — o Gmail sanitiza de um jeito que só aparece na entrega real.
