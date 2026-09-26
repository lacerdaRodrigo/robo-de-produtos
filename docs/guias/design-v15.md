# Radar — contrato de design mobile V15

## Intenção

**Boas escolhas à vista.** Um aplicativo que torna preços, cashback e pontos
comparáveis sem fingir que são o mesmo benefício. Uma identidade única atende
todas as origens. A navegação explica o domínio antes de pedir uma busca.

Este documento descreve um design novo e o seu protótipo local. As regras de
produto vêm dos PRDs; aparência, composição, marca e movimento são próprios.

Entradas: [protótipo](../../design-app/mobile-v15/index.html),
[identidade e animações](../../design-app/mobile-v15/identidade.html),
[instruções de uso](../../design-app/mobile-v15/README.md),
[evidências de revisão](../../design-app/mobile-v15/review/VALIDACAO.md).

## Direção visual

Laranja brasa identifica ações e descoberta. Fundos de papel mantêm o claro
confortável; grafite e damasco mantêm hierarquia no escuro. As cores das origens
não alteram o sistema do aplicativo. Verde comunica resultado favorável;
vermelho comunica erro/destruição, não uma identidade concorrente.

Manrope variável é a família principal, incluída localmente. Preços usam números
tabulares, peso 800 e hierarquia maior que metadados. Textos de condições não
são resumidos pelo cliente nem substituídos por frases inventadas.

| Papel | Claro | Escuro |
|---|---|---|
| Fundo | `#F6F4F0` | `#222225` |
| Superfície | `#FFFDF9` | `#2B2B2E` |
| Superfície secundária | `#EEEAE4` | `#333337` |
| Texto principal | `#282629` | `#F6F0E9` |
| Texto secundário | `#70675F` | `#BFB7AE` |
| Ação principal | `#B6421E` | `#FFAC86` |
| Texto sobre ação | `#FFF8F3` | `#481B09` |
| Destaque suave | `#FBE6D9` | `#4B3027` |

Escala de espaço: 4, 8, 12, 16, 20, 24, 32, 40 e 48. Raios por função:
10 em controles, 18 em ofertas, 26 em destaque/folhas e circular apenas em
ícones/chips apropriados. Não aplicar o mesmo contêiner a todo tipo de conteúdo.

Tipografia de referência: apoio 12, rótulo 13, corpo 14, título de item 18,
título de tela 28, preço 30. A fonte cresce com a preferência do usuário;
não reduzir automaticamente textos longos para caber. A tela rola verticalmente.

## Marca e imagens

O símbolo é uma **etiqueta de compra com três sinais de descoberta**. O recorte
da etiqueta permanece legível em tamanho pequeno. Não há cifrão, brasão,
monograma forçado ou fachada de loja anexada ao logo.

O pacote inclui SVGs claro/escuro, marca horizontal, ícone e camadas Android.
A arte iOS é quadrada; o sistema deve aplicar sua máscara. A versão arredondada
é uma prévia, não uma máscara a ser aplicada duas vezes. A notificação usa
silhueta monocromática separada. A marca horizontal depende da Manrope incluída.

As duas imagens raster usam cerâmica, etiqueta, lente e sino: descoberta e
acompanhamento. Elas aparecem no acesso e em estados adequados, nunca em cada
card. Os catálogos não reservam espaços vazios para fotos indisponíveis.

No acesso compacto, a assinatura usa a marca horizontal oficial no claro e
símbolo mais palavra em contraste no escuro. A ilustração de descoberta ocupa
a largura útil com proporção responsiva, preservando a arte inteira sem cortar
seus objetos, e o título usa a escala de tela de 28–32 px, permitindo quebra
natural em larguras menores e com texto ampliado. O aviso técnico de Firebase e
API não é um cartão da composição visual de acesso. No Flutter, a variante
transparente da arte permite que o fundo use o papel claro ou o grafite escuro
do tema, sem criar um quadrado branco na tela escura.

[Briefs e inventário](../../design-app/mobile-v15/assets/PROMPTS.md).

## Arquitetura da experiência

Quatro destinos persistentes: **Início**, **Explorar**, **Meu radar**, **Perfil**.
Cada aba preserva a sua posição útil. Detalhes e folhas retornam ao contexto de
origem; abrir condições não deve limpar busca, filtro ou página.

| Tela / rota de revisão | Conteúdo e saída |
|---|---|
| `launch` | Marca animada → login ou sessão local existente. |
| `login` | Validação, senha visível, recuperação, entrada demonstrativa. |
| `recovery`, `recovery-sent` | Pedido simulado com confirmação e retorno ao acesso. |
| `home` | Cabeçalho, estado resumido, origens e acesso à Central; alertas não são renderizados como cartão de destaque na Home. |
| `explore` | Marca `radar.` com rótulo Explorar, retorno pelo botão Android/gesto, área segura do sistema, kicker `ESCOLHA SEU CAMINHO`, título responsivo em duas linhas, descrição curta e cards de Inter, Livelo e Pichau com descrição inequívoca; o hub não exibe campo de busca. |
| `inter` | Escolha entre Sites parceiros e Compre direto; cada card abre sua própria rota interna, sem renderizar o catálogo abaixo da escolha. |
| `partners` | Cashback por loja, principal/secundário, condições e acompanhamento. |
| `direct` | Produtos agrupados por loja, busca e filtros; preço, cashback e estimativa. |
| `livelo` | Cabeçalho Livelo/Catálogo com voltar e atualizar por ícone, título Lojas e pontos sem descrição redundante, busca com avanço, abas Lojas/No radar, filtros e cartões com categoria/última coleta, loja, pontuação, base, Clube, campanha, validade, acompanhamento, condições e histórico. Condições e abertura externa usam folhas próprias; o histórico mostra Clube quando o payload da medição o fornece, com título da loja, status Completa e paginação. |
| `pichau` | Cabeçalho Pichau/Catálogo com voltar e atualizar, título PCs gamer, busca com avanço, abas Todos/No radar, folha `Filtros · Pichau` com ordem Pix, disponibilidade, faixa de preço e ações Limpar/Aplicar filtros, cards com SKU, disponibilidade no canto direito, título longo em duas linhas, preços Pix/cartão e desconto; Detalhes reúne abertura externa e histórico. |
| `detail` | Identidade do item, valores, especificações, seguir e destino. |
| `watching` | Lista pessoal, origem, busca, remoção e desfazer. |
| `alerts` | Cabeçalho com `Voltar`, `Mudou. Você viu.` e preferências, abas `Todos`/`Não lidos`, filtro em folha, janela de 90 dias, feed de eventos, paginação e estado de leitura; o botão/gesto Android retorna à rota anterior e a barra inferior permanece visível no compacto. |
| `profile` | Conta, preferências, suporte, gestão autorizada e saída. |
| `appearance` | Claro, escuro, sistema e movimento reduzido. |
| `notifications` | Preferências por tipo e permissão demonstrativa independente. |
| `help`, `privacy` | Orientação, dados, limites e acesso ao suporte. |
| `report`, `reports` | Formulário validado, rascunho, protocolo e registros locais. |
| `admin`, `confirm` | Gestão por domínio, impacto, frase exata, cancelamento. |

Folhas reutilizáveis: condições, histórico, filtros do catálogo, filtros de
alertas, saída, destino externo, permissão e restauração da demonstração. A
folha de histórico usa cabeçalho centralizado com voltar/fechar, identificação
do produto, resumo de mínimo e máximo, total da janela de 30 dias e medições
com preço, cashback e após cashback alinhados à direita. Quando houver mais de
uma página, a folha mostra cinco medições por vez, o indicador `1 de N` (com o
número da página atual) e setas circulares de anterior/próxima.

## Composição e comportamento

1. **Catálogos:** título breve, busca, Todos/No radar e uma ação Filtros.
   Ordenação e combinações avançadas ficam na folha, não em vários blocos fixos.
2. **Lojas:** nome, benefício legível, contexto mínimo, condições completas,
   acompanhar e destino. Pontuação Clube não substitui a comum.
3. **Produtos:** nome/variante, preço, especificações úteis, acompanhar e detalhe.
   Histórico tem página própria na folha; o botão abre dados daquele item.
4. **Acompanhamento:** resposta otimista, bloqueio durante gravação, rollback
   em falha e desfazer remoção. A lista Acompanhadas é um recorte real.
5. **Busca:** consulta somente a amostra carregada neste protótipo. Na aplicação
   conectada, consulta exclusivamente a API/banco paginados, nunca coletores.
6. **Dinheiro:** centavos inteiros e valores fornecidos; não transformar estimativa
   após cashback em preço cobrado. Zero, ausência, parcial e falha são diferentes.
7. **Admin:** controles locais são demonstração de UX, não segurança. Produção
   exige autorização e validação no servidor; nenhuma operação remota foi criada.

## Movimento

| Interação | Receita |
|---|---|
| Abertura | Etiqueta entra, sinal expande, palavra aparece; 1,65 s e passagem ao acesso. |
| Entrada de tela | Opacidade e deslocamento horizontal curto, 300 ms. |
| Voltar | Deslocamento inverso, mantendo a posição útil. |
| Folha | Entrada vertical de 300 ms, saída de 160 ms e scrim discreto. |
| Toque | Escala 0,98, feedback imediato; nenhuma espera artificial de vários segundos. |
| Salvar | Estado pendente, confirmação ou reversão. |
| Carregar | Skeleton sem apagar conteúdo anterior durante atualização. |
| Confirmar | Desenho de traço, 600 ms; SVG disponível na galeria. |

Movimento reduzido respeita a preferência do sistema ou do usuário. Remove
pulso, zera deslocamentos perceptíveis e encurta a abertura. A animação não é
uma barra de progresso real do backend. No futuro Flutter, a splash do sistema
deve mostrar marca estática e combinar com a entrada Flutter, sem duplicar a espera.

## Acessibilidade e adaptação

- Controles do app com alvo de pelo menos 48 px, rótulos e estados semânticos.
- Preço, disponibilidade e benefício têm texto; cor não é a única informação.
- Contraste medido nos pares de texto; foco visível e retorno de foco nas folhas.
- Conteúdo atrás de modal fica inerte. Escape fecha e Tab permanece no diálogo.
- Ao abrir o teclado, uma folha reduz sua altura útil e sobe acima dele. Campos
  e ações de filtros continuam alcançáveis por rolagem, sem o teclado cobrir o
  valor em edição ou cortar opções de seleção.
- Texto de até 200%, larguras compactas e rolagem sem truncar condições.
- Direção RTL usa propriedades lógicas e espelha setas direcionais, não a marca.
- Movimento reduzido inclusive no skeleton e nos SVGs animados.
- Validação por leitor de tela em aparelho físico permanece um gate nativo.

## Tradução futura para Flutter

As skills mobile-design, acessibilidade, adaptação e convenções orientaram
hierarquia, separação de domínios, alvos de toque, estados e tokens. imagegen
foi usada para as duas ilustrações; logo e ícones são vetoriais próprios.

| No protótipo | Widget Flutter preferido |
|---|---|
| Moldura e abas | `Scaffold`, `SafeArea`, `NavigationBar` |
| Tema e valores visuais | `ThemeData`, `ColorScheme`, `TextTheme`, `ThemeExtension` |
| Busca e formulários | `SearchBar`/`TextFormField`, `Form`, validadores |
| Ações e escolhas | `FilledButton`, `OutlinedButton`, `TextButton`, `IconButton` |
| Todos/No radar | `SegmentedButton` ou tabs Material conforme composição |
| Folhas | `showModalBottomSheet`, `DraggableScrollableSheet`, `SafeArea` |
| Preferências | `SwitchListTile`, controles de seleção e `ListTile` |
| Feedback | `SnackBar`, `Semantics`, `AnimatedSwitcher` |
| Listas | `ListView.builder`/slivers com paginação no repositório da API |
| Movimento | `AnimationController`, curvas e preferência de reduzir animação |

Não converter o protótipo em WebView nem recriar controles padrão sem necessidade.
Widgets devem compartilhar o mesmo contrato e os mesmos tokens, com layout
adaptado por constraints, não pela largura fixa da moldura de revisão.

## Referências funcionais

Somente contratos de produto, não referências visuais:

- [Sites parceiros](../prd/PRD-INTER-CASHBACK.md).
- [Compre direto](../prd/PRD-INTER-PRODUTOS.md).
- [Catálogo Livelo](../prd/PRD-LIVELO-CATALOGO-ALERTAS-APP.md).
- [Pichau](../prd/PRD-PICHAU.md).
- [Central, suporte e privacidade](../prd/PRD-CENTRAL-ALERTAS-SUPORTE-PRIVACIDADE.md).
- [Administração](../prd/PRD-ADMINISTRACAO.md).

O fechamento do backend mobile V15 adiciona somente a leitura autenticada dos
acompanhamentos pessoais, o bloco `radar` do resumo e índices aditivos. Não há
acesso do Flutter ao banco, remoção de schema ou mudança da autorização.
Migration, publicação, hardware e aceite físico continuam discriminados no
[PRD de aceite Mobile V15](../prd/PRD-ACEITE-MOBILE-V15.md), nas
[pendências](../PENDENCIAS.md) e no [relatório visual](../../design-app/mobile-v15/review/VALIDACAO.md).
