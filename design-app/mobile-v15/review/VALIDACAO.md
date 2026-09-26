# V15 — revisão e evidências

Entrega: protótipo mobile local, com dados demonstrativos. Não é homologação
do aplicativo conectado nem declaração de funcionamento de serviços externos.

## Resultado executado

- **10/10 testes unitários** em `tests/core.test.js`.
- **18/18 grupos de revisão interativa** em `review/verify.mjs`.
- **88 combinações de tela**: 22 rotas estáticas × dois temas × texto 100/200%,
  na moldura de 320 px. A abertura é verificada separadamente, com/sem movimento.
- Sem overflow horizontal detectado no conteúdo ou navegação nessas combinações.
- Revisão adicional de viewport mobile, direção RTL, estados e folha de filtros.
- Após o ajuste final dos rótulos, mais 16 combinações dos quatro catálogos
  passaram sem overflow. Molduras de 430 px também mantiveram a largura nos
  viewports de 681, 800 e 1024 px. A galeria coube em 320 px; seus dois SVGs
  carregaram com animações ativas. Um clique de ponteiro real abriu as condições.
- Sem exceções JavaScript, avisos/erros de console ou recursos locais HTTP 4xx/5xx
  nas jornadas da execução registrada.

Resultado legível por máquina: [results.json](results.json).

O roteiro usa elementos reais do protótipo, preenche formulários, aciona botões,
confere resultados e recarrega a página. Não chama APIs externas nem realiza
compras, exclusões remotas, envio de mensagens ou solicitação real de push.

## Jornadas conferidas

1. Abertura animada chega ao login; preferência de reduzir movimento é respeitada.
2. Login valida email/senha, permite revelar senha, bloqueia envio duplicado e não
   grava senha em storage.
3. Recuperação preserva email; navegação cancela retorno assíncrono tardio.
4. Inter oferece os dois modos; condições exibem o texto do item, retêm foco e
   encaminham ao portal oficial somente mediante confirmação.
5. Paginação não acumula itens; Acompanhadas é um recorte real.
6. Acompanhamento tem estado pendente, remoção, desfazer, persistência e rollback.
7. Compre direto diferencia variantes, valida faixa monetária e filtra loja.
8. Livelo distingue pontuação comum de Clube; histórico troca páginas reais.
9. Pichau separa esgotado, ausente, preço desconhecido e histórico sem medição.
10. Abas, detalhe e retorno preservam busca, página e posição útil.
11. Leitura da Central atualiza os contadores; a Home não exibe cartão de alerta.
12. Permissão opcional, preferências, tema e movimento persistem.
13. Suporte valida tamanho, preserva texto na falha, gera protocolo e escapa HTML.
14. Sessão expirada retoma contexto; logout mantém acompanhamentos locais.
15. Administração tem restrição demonstrativa, frase exata e efeito isolado.
16. Todas as telas são renderizadas na matriz claro/escuro e texto ampliado.
17. Estados, modal, foco de teclado, RTL e viewport compacto são revisados.
18. Diagnósticos do navegador não apresentam erros nas jornadas acima.

## Ciclos de crítica e correção

A revisão das skills não foi encerrada na primeira renderização. Antes da nota,
foram procuradas falhas por três perspectivas: clareza de produto, composição
visual e comportamento técnico. Correções realizadas:

| Problema encontrado | Correção e evidência |
|---|---|
| Moldura encolhia dependendo do conteúdo do catálogo. | Coluna de largura explícita no estúdio; adaptação em viewport pequeno. |
| Tokens de fonte herdados da raiz não recalculavam com a escala. | Tokens tipográficos calculados no dispositivo; corpo de 28 px em escala 200%. |
| Catálogos tinham apresentação demais antes da primeira oferta. | Removidos eyebrow e texto promocional repetido; título de catálogo compacto. |
| Rótulo da navegação partia palavra no modo mais compacto/ampliado. | Navegação se reorganiza em duas linhas de ações nesse caso extremo. |
| Termos longos competiam por largura com texto ampliado. | “PCs gamer” e o filtro “No radar” mantêm o significado sem partir palavras. |
| O alerta ocupava a área principal da Home. | A Home mantém o estado resumido e o acesso à Central no cabeçalho; o evento completo fica na Central. |
| Operação de formulário podia redirecionar após o usuário sair da tela. | Navegação invalida a operação pendente. |
| Limpar filtros apagava busca e modo de acompanhamento. | Limpeza preserva esses dois contextos; teste confere os resultados. |
| Troca entre folhas podia perder o elemento de retorno de foco. | Referência inicial é preservada ao passar de condições para destino externo. |
| Mensagem de faixa inválida não recebia foco. | Erro focalizável e anunciado, sem fechar o formulário. |

Uma execução inicial do roteiro teve erro de escape no próprio seletor de
revisão; ele foi corrigido e a execução final completa passou. Isso não foi
registrado como falha do aplicativo nem ocultado no resultado final.

## Evidência visual

- [Início claro](final-inicio.png).
- [Sites parceiros](final-inter.png).
- [Compre direto](final-direto.png).
- [Livelo escuro](final-livelo.png).
- [Pichau escuro](final-pichau.png).
- [Acesso com ilustração original](final-acesso.png).
- [Compacto com texto ampliado](final-compacto.png).
- [Galeria de identidade](final-identidade.png).

São capturas de revisão, não imagens a serem usadas como telas estáticas no app.
O comportamento continua no HTML/JS e pode ser reproduzido pelos controles.

## Contraste medido

Razões calculadas por luminância relativa dos tokens, sem arredondar cores:

| Par | Claro | Escuro |
|---|---:|---:|
| Texto principal / fundo | 13,66:1 | 14,02:1 |
| Texto secundário / fundo | 5,04:1 | 8,01:1 |
| Texto secundário / superfície | 5,45:1 | 7,12:1 |
| Texto de ação / botão | 5,27:1 | 8,00:1 |
| Ação / fundo | 5,05:1 | 8,69:1 |
| Apoio / destaque suave | 4,59:1 | 6,05:1 |
| Sucesso / superfície semântica | 5,96:1 | 7,00:1 |
| Aviso / superfície semântica | 5,19:1 | 7,08:1 |
| Erro / superfície semântica | 5,24:1 | 6,58:1 |

Todos esses pares superam 4,5:1. Isso verifica os pares listados, não certifica
automaticamente todos os pixels, navegadores ou leitores de tela.

## Scorecard crítico

Avaliação do protótipo após as revisões, não selo de aprovação de produção:

| Dimensão | Avaliação | Evidência e limite |
|---|---|---|
| Hierarquia | 8/10 | Preço/benefício domina o card; catálogos perderam introdução redundante. |
| Contenção | 8/10 | Uma cor de identidade; ordenação e opções avançadas concentradas na folha. |
| Espaçamento | 8/10 | Escala compartilhada, listas separadas de cards, rolagem em texto ampliado. |
| Identidade visual | 8/10 | Marca vetorial própria, tipografia local, cerâmica e paleta papel/grafite. |
| Movimento e feedback | 8/10 | Abertura, transições, skeleton, pendência, rollback, desfazer e redução. |
| Adequação nativa | Ainda não homologada | Padrões preparados para Material 3; não foi construído ou testado um APK. |
| Estados | 8/10 | Vazio, carregando, sem resultado, parcial, atrasado, offline e falhas distintos. |
| Acessibilidade | Gate nativo aberto | Contrastes, foco, labels, RTL e escala revisados; falta TalkBack/VoiceOver real. |
| Diagnósticos | 10/10 no recorte executado | 18 grupos aprovados, sem avisos/erros capturados; não equivale a toda plataforma. |
| Organização | 8/10 | Dados, consulta pura, componentes, controlador, tokens e testes separados. |

A exigência máxima das skills para acessibilidade/adequação nativa não é
declarada cumprida sem evidência em aparelho. A entrega está pronta para
revisão do **protótipo**, não para publicação como aplicativo de produção.

## Como repetir

Na pasta do protótipo, execute as checagens de sintaxe e unitários do README.
Para a revisão de navegador, inicie o servidor local e um perfil Chrome isolado:

```bash
python3 -m http.server 4175 --bind 127.0.0.1
```

Em outro terminal:

```bash
radar_review_profile=$(mktemp -d /tmp/radar-v15-review.XXXXXX)
google-chrome --headless=new --disable-gpu --no-first-run \
  --remote-debugging-port=9225 --user-data-dir="$radar_review_profile" about:blank
```

Em um terceiro terminal, na mesma pasta do protótipo:

```bash
node review/verify.mjs
```

O roteiro altera apenas a amostra local da origem `127.0.0.1:4175`. Ao terminar,
encerre os dois processos com Ctrl+C. Não conecte o roteiro a um perfil pessoal
nem a um ambiente de produção. `review/export-assets.mjs` usa o mesmo Chrome
para renderizar os PNGs do ícone, caso seja necessário repetir o export.

## O que permanece externo a esta entrega

- Flutter, APK, widgets/testes de plataforma e adaptação final a dispositivos.
- Login/recuperação reais, API paginada, autorização de servidor e persistência remota.
- Push FCM, deep links, permissões reais e desassociação do aparelho no logout.
- Envio real de suporte, retenção no servidor e entrega de e-mail.
- Validação de máscaras Android/iOS, splash nativa, teclado e leitor de tela físico.
- Coleta, disponibilidade operacional das origens, produção e publicação.

Nenhuma dessas etapas foi representada como concluída por uma interação local.
