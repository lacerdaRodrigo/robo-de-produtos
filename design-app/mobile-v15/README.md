# Radar · Mobile V15

Protótipo mobile independente, navegável e com estado local. A direção visual é
**Boas escolhas à vista**: etiqueta de descoberta, laranja brasa, papel e grafite.

## Abrir

Abra [index.html](index.html) no navegador. Para servir a pasta localmente:

```bash
python3 -m http.server 4175 --bind 127.0.0.1
```

Depois acesse `http://127.0.0.1:4175`. Não requer instalação de dependências.
Fontes, imagens, ícones e scripts estão na própria pasta.

- Conta de demonstração: `demo@radar.app` / `radar123`.
- **Explorar demo** permite entrar sem preencher o formulário.
- [Identidade & movimento](identidade.html): logos, imagens, downloads e animações repetíveis.
- [Guia de design e cobertura](../../docs/guias/design-v15.md).
- [Validação e limitações](review/VALIDACAO.md).
- [Briefs das imagens](assets/PROMPTS.md).

## O que funciona

23 telas, além das folhas de condições, filtros, histórico e confirmações:

| Jornada | Comportamento |
|---|---|
| Abertura e acesso | Marca animada, login validado, senha visível, recuperação simulada, retomada de sessão e saída. |
| Início e exploração | Mudanças não lidas, atalhos por origem e navegação em quatro abas. |
| Banco Inter | Escolha explícita entre Sites parceiros e Compre direto. |
| Sites parceiros | Busca de lojas, cashback principal e secundário, condições completas, seguir/deixar de seguir, filtros e paginação. |
| Compre direto | Busca por produto/variante, agrupamento por loja, filtros, preço de compra, cashback, estimativa, detalhe e histórico. |
| Livelo | Lojas, pontos comuns/base/Clube, condições, campanhas, validade, acompanhamento e histórico. Não é catálogo de produtos. |
| Pichau | PCs gamer, Pix/cartão, disponibilidade, ausência do catálogo, filtros, detalhe e histórico. |
| Meu radar | Lista conjunta ou por origem, busca, remoção e desfazer. |
| Central | Eventos paginados, origem/tipo, leitura individual e coletiva. |
| Conta | Tema claro/escuro/sistema, movimento reduzido, preferências, permissão simulada, ajuda e privacidade. |
| Suporte | Validação, rascunho preservado, registros locais e cópia de protocolo. |
| Administração | Perfil demonstrativo restrito, prévia do impacto, frase de confirmação e limpeza local isolada por domínio. |

A amostra tem 64 itens: 14 lojas Inter, 14 parceiros Livelo, 24 ofertas do
Compre direto e 12 PCs. Listas exibem até 10 itens por página; históricos, 5;
Central, 3. Isso demonstra paginação, não uma integração com a API.

As alterações de acompanhamento são otimistas, com bloqueio de envio duplicado,
feedback, rollback em falha e opção de desfazer remoção. Tema, filtros,
acompanhamentos, leitura, preferências e relatos sobrevivem ao recarregamento.
A sessão de teste usa `sessionStorage`; senhas não são gravadas.

## Laboratório fora do aplicativo

Os controles laterais — abaixo do celular em viewport pequeno — permitem:

- Abrir qualquer tela sem percorrer a jornada inteira.
- Conferir conteúdo, carregamento, atualização, vazio, sem resultado, offline,
  atraso, parcial, erro com/sem dados e sessão expirada.
- Alternar tema, largura de 320/390/430 px, texto de 100/130/200%, RTL e movimento.
- Revisar o perfil administrador e restaurar somente os dados desta demonstração.
- Repetir a abertura animada.

Links úteis: [Pichau escuro](index.html?screen=pichau&theme=dark),
[acesso](index.html?screen=login),
[compacto com texto ampliado](index.html?screen=direct&width=320&text=2),
[gestão demonstrativa](index.html?screen=admin&role=admin).

Parâmetros de revisão não constituem autenticação real. O seletor de papel não
deve ser transportado para o aplicativo conectado.

## Imagens e movimento

- `assets/brand/`: símbolo claro/escuro, marca, ícone, versões raster,
  camadas adaptativas Android e notificação monocromática.
- `assets/illustrations/`: duas composições raster originais para acesso e
  acompanhamento; desenhos SVG próprios para busca vazia e indisponibilidade.
- `assets/motion/`: abertura e confirmação em SVG animado.
- `assets/fonts/`: Manrope variável e licença OFL.

Abertura funcional: 1,65 s no protótipo. Telas entram em 300 ms, folhas saem em
160 ms. Preferência do sistema e controle do usuário reduzem o movimento.
As animações não são vídeos, GIFs ou arquivos Lottie: são SVG/CSS.

## Limite honesto da entrega

Todos os dados são ilustrativos. Não há requisições ao backend, coleta de lojas,
cadastro real, envio de e-mail, push real, atendimento ou exclusão remota.
Os links externos abrem os portais oficiais após confirmação, não ofertas
inventadas. Imagens de identidade não representam produtos do catálogo.

O protótipo não é um APK nem substitui a autorização no servidor. Uma futura
implementação Flutter deve consumir a API paginada, preservar os contratos dos
domínios e usar widgets Material 3 com os tokens documentados.

## Organização e checagens

`data.js` contém apenas fixtures; `core.js`, regras puras de consulta;
`ui.js`, componentes e telas; `app.js`, navegação, ações e persistência.
`tokens.css` centraliza a base visual; `app.css` monta as telas.

```bash
node --check js/data.js
node --check js/core.js
node --check js/ui.js
node --check js/app.js
node --check js/identity.js
node --test tests/core.test.js
```

A revisão interativa opcional usa `node review/verify.mjs`, com Node que suporte
`WebSocket`, o servidor local acima e um Chrome de revisão na porta 9225.
Use um perfil descartável: a revisão restaura a amostra e altera apenas o estado
local do protótipo. Instruções e resultados em [VALIDACAO.md](review/VALIDACAO.md).
