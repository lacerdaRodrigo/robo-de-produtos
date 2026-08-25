# Arquitetura do Projeto — documento histórico

> ⚠️ **Este documento foi substituído pelo [`PRD.md`](PRD.md), que é a fonte da verdade do projeto.**
>
> Ele fica preservado por registrar o raciocínio original. O **dicionário de lojas e categorias** do Passo 1 já foi convertido em `config/lojas_favoritas.toml`, onde os nomes foram conferidos contra a página real e ganharam apelidos quando a Livelo exibe grafia diferente (ex.: C&A aparece como "CEA").
>
> **Decisões abaixo que o PRD substituiu:**
> - Correspondência **parcial** de nomes → agora é match exato com apelidos cadastrados (PRD RN04).
> - Alerta de quebra dentro do extrator → passou para o caso de uso (PRD §6.4).
> - `SEMPRE_ENVIAR` como interruptor → eliminado; o robô envia em toda execução (PRD RF10).
> - Extrator fazendo requisição HTTP → separado em porta `FonteDePagina` (PRD §4.2).
> - Estrutura de pastas do final deste documento → substituída pela da Seção 4.4 do PRD.

Este documento reúne as decisões técnicas tomadas antes de programar, organizadas pelos 4 passos originais do projeto.

---

## Passo 1 — Dicionário de Categorias

Regra geral: a pontuação turbinada é dada pela **loja**, não pelo produto — então cada loja é classificada uma única vez, numa categoria fixa.

| Categoria | Lojas |
|---|---|
| Marketplace / Varejo Geral | Mercado Livre, Shopee, Casas Bahia, Magalu, Extra, Pontofrio |
| Eletro | Fast Shop, Kabum! |
| Moda | Renner, C&A, Riachuelo, Dafiti, Hering, Nike |
| Beleza | Natura, O Boticário, Sephora, Eudora, Avon, Época Cosméticos, Beleza na Web |
| Farmácia | Drogaria São Paulo, Drogarias Pacheco, Farmácias App |
| Pet | Petz, Petlove |
| Viagem | Booking.com, Decolar, Localiza, Movida |
| Mercado / Alimentação | Carrefour Mercado, Angeloni |
| Casa & Construção | Camicado, ABC da Construção, Telhanorte |
| Transporte / Telecom | Uber, Claro, TIM |

**Decisões:**
- ❌ **Amazon** não é parceira de acúmulo da Livelo — não pode entrar.
- ❌ **Papelaria** foi descartada: só existe Faber-Castell como parceiro "puro" do segmento, não compensa criar uma categoria pra uma loja só.
- ✅ **Piso de boost:** qualquer aumento de pontuação conta, mesmo que pequeno (ex: de 1 para 2 pontos). Sem filtro de valor mínimo.
- A comparação de nomes ignora acentuação e caixa alta/baixa, e usa correspondência parcial (ex: "Casas Bahia Oficial" ainda reconhece "Casas Bahia") — com cuidado pra não confundir nomes parecidos (ex: "Ponto" ≠ "Pontofrio").

---

## Passo 2 — Robô Extrator

**Tecnologia escolhida:** `requests` + `BeautifulSoup` + `lxml`.

Testado contra a página real (`https://www.livelo.com.br/juntar-pontos/todos-os-parceiros`) e confirmado que ela é renderizada no servidor — os dados já vêm prontos no HTML, sem precisar de navegador (Playwright).

> **Plano B:** se no futuro a Livelo blindar o site com proteção anti-bot e o `requests` parar de funcionar, a alternativa documentada é trocar para Playwright (navegador headless). Fica só como comentário no código, não implementado, pra não pesar o projeto à toa.

**Decisões de comportamento:**
- ✅ **1 única requisição por execução** — só a página com a lista de todos os parceiros. Decidimos **não** visitar a página individual de cada loja (o que traria a data de validade da promoção) porque isso multiplicaria as requisições (~40 a mais) e aumentaria o risco de bloqueio por parte da Livelo. Custo não compensa o benefício.
- ✅ **Sem histórico entre execuções.** O robô não guarda o que já foi enviado antes — a cada execução, mostra tudo que está ativo naquele momento, mesmo que seja a mesma promoção do dia anterior. *(Uma ideia de histórico com comparação entre execuções e gráfico de tendência foi cogitada e descartada — mantém o projeto simples.)*
- ✅ **Tentativa automática (retry):** se a requisição falhar (timeout, instabilidade), o robô tenta novamente até 2-3 vezes com um pequeno intervalo, antes de desistir.
- ✅ **Alerta de quebra:** se o robô encontrar muito menos parceiros do que o normal (ex: menos de 50, quando o esperado é 200+), ele força um erro proposital. Isso aciona a notificação nativa de falha do GitHub Actions — sinal de que a Livelo mudou o layout do site e o scraper precisa de ajuste. Sem esse alerta, "site quebrado" e "nenhuma promoção hoje" pareceriam a mesma coisa.

---

## Passo 3 — Montador de E-mail

**Formato:** HTML (com fallback em texto simples para clientes de e-mail antigos).

**Regras de exibição:**
- Agrupado por categoria, cada uma com uma cor de identificação visual
- Dentro de cada categoria, lojas ordenadas por pontuação (maior primeiro)
- Quando a loja tiver um valor extra exclusivo pra assinante do Clube Livelo, ambos os valores aparecem
- ❌ Sem data de validade da promoção (decisão ligada à do Passo 2 — não vale o risco de mais requisições)
- Botão de call-to-action ("Ver oferta") linkando direto pra página do parceiro na Livelo — importante manter o link da Livelo (não o site da loja direto), porque é assim que a pontuação é validada

O layout visual (cores, hierarquia, espaçamento) foi validado com um protótipo antes da implementação.

---

## Passo 4 — Agendamento

**Plataforma:** GitHub Actions, em repositório **público** (uso como peça de portfólio/currículo).

**Frequência:** 3x ao dia — 09h, 14h e 20h (horário de Brasília, UTC-3, fixo o ano todo já que o Brasil não usa mais horário de verão).

```yaml
cron: "0 12,17,23 * * *"   # 12h/17h/23h UTC = 09h/14h/20h BR
```

**Segurança:** credenciais nunca ficam no código, mesmo com o repositório público:

| Variável | Onde vive localmente | Onde vive em produção |
|---|---|---|
| `EMAIL_REMETENTE` | `.env` (gitignored) | GitHub Secret |
| `SENHA_APP_GMAIL` | `.env` (gitignored) | GitHub Secret |
| `EMAIL_DESTINO` | `.env` (gitignored) | GitHub Secret |
| `SEMPRE_ENVIAR` | `.env` (opcional) | variável direta no workflow |

**Workflows separados:**
- `robo.yml` — roda o robô nos 3 horários + botão manual (`workflow_dispatch`)
- `testes.yml` — roda `pytest` + `ruff` a cada `git push`

**Extras de manutenção automática:**
- `dependabot.yml` — abre Pull Requests sozinho quando uma dependência tiver atualização de segurança
- `ruff` — checa formatação e problemas comuns de código a cada push, junto do `testes.yml`

---

## Ferramentas usadas (resumo)

| Ferramenta | Papel |
|---|---|
| Python 3.11 | linguagem |
| `requests` | baixa a página da Livelo |
| `beautifulsoup4` + `lxml` | interpreta o HTML e extrai os dados |
| `python-dotenv` | lê variáveis de ambiente localmente |
| `smtplib` (nativo) | envia o e-mail via Gmail |
| `pytest` | testes automatizados |
| `ruff` | lint + formatação de código |
| GitHub Actions | agendamento + CI de testes |
| GitHub Secrets | armazenamento seguro de credenciais |
| Dependabot | atualização automática de dependências |

---

## Estrutura de pastas

```
livelo-bot/
├── .github/
│   ├── workflows/
│   │   ├── robo.yml
│   │   └── testes.yml
│   └── dependabot.yml
├── src/
│   └── robo_livelo/
│       ├── __init__.py
│       ├── categorias.py
│       ├── extrator.py          # busca e interpreta os dados da Livelo
│       ├── montador_email.py    # monta o HTML do e-mail
│       └── principal.py         # orquestra tudo e envia
├── testes/
│   ├── fixtures/
│   │   └── exemplo_parceiros.html
│   ├── conftest.py
│   ├── teste_categorias.py
│   ├── teste_extrator.py
│   ├── teste_montador_email.py
│   └── teste_principal.py
├── docs/
│   ├── ARQUITETURA.md
│   └── TESTES.md
├── .env.example
├── .env                  # nunca commitado
├── .gitignore
├── pyproject.toml        # dependências + config do pytest/ruff
├── LICENSE
└── README.md
```

**Convenção de nomenclatura:** todo o código, nomes de pasta, variáveis e testes estão em **português do Brasil** — exceto o que é exigido por convenção de ferramenta (`src/`, `__init__.py`, `conftest.py`, `pyproject.toml`, `.gitignore`, `.env`, nomes de bibliotecas de terceiros como `requests` e `pytest`, e palavras-chave da própria linguagem Python).

**Rodando localmente:**
```bash
python -m robo_livelo.principal
```
