# Continuidade do trabalho — Radar de Benefícios

**Atualizado em 22 de agosto de 2026**

Este arquivo é um ponto de retomada rápido. A fonte completa de requisitos
continua sendo `docs/prd/PRD-LIVELO.md`; o plano Flutter continua em
`app-robo/PLANO.md`.

## Última entrega concluída

A **Fase 4.2B — painel Livelo real no Android** foi concluída em 22 de agosto
de 2026, após o smoke físico no Samsung SM-M135M.

O Flutter segue apenas como cliente autenticado da API v1 hospedada no Next.js.
Não houve mudança no banco, nos robôs Python, nos workflows, no App Check nem
na interface legada em `site/`.

## O que foi implementado

- A aba **Livelo** deixou de mostrar o lugar-ocupante e agora consulta
  `GET /api/v1/livelo/painel`.
- Modelo `PontuacaoLivelo` e cliente `ApiV1.painelLivelo()` preservam todos os
  decimais como `String`; não há cálculo ou exibição por `double`.
- Busca por loja/categoria com debounce de 350 ms.
- Modos Maior pontuação, Em alerta e Nome A–Z. O modo Em alerta segue o
  contrato atual da API: é um filtro, mesmo aparecendo junto das opções de
  ordenação.
- Paginação de 20 itens por página, acionada apenas por **Carregar mais**;
  deduplicação pelo nome canônico, bloqueio de chamadas concorrentes e descarte
  de respostas antigas.
- Cartões mostram pontos atuais, base, alerta, Clube, promoção, validade e
  condições expansíveis. Links externos continuam fora desta fase.
- Estados próprios para carregamento, falha/retry, nenhuma coleta, catálogo
  vazio, busca vazia, atraso acima de 12 h, loja ausente, página adicional e
  fim da lista.

Arquivos principais:

- `app-robo/lib/features/livelo/controlador_painel_livelo.dart`
- `app-robo/lib/features/livelo/pagina_painel_livelo.dart`
- `app-robo/lib/features/livelo/cartao_livelo.dart`
- `app-robo/lib/features/livelo/formato_livelo.dart`

## Testes e builds já validados

| Verificação | Resultado |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | passou |
| `flutter analyze` | passou |
| `flutter test --coverage` | 59 testes passaram |
| Cobertura dos arquivos críticos Livelo | 93,00% (186/200 linhas) |
| `flutter build web` | artefato local gerado |
| `flutter build apk --debug` | APK local gerado |
| `pytest --cov --cov-fail-under=90` | 211 testes; 94,16% |
| Ruff | passou |
| `npm run checar && npm run testar && npm run build` em `site/` | TypeScript, 64 testes e build passaram |

Os CT-263 a CT-276 foram adicionados ao catálogo em `docs/TESTES.md`.

## Smoke físico concluído: Samsung SM-M135M

O app de depuração foi instalado e executado com:

```bash
cd app-robo
flutter run -d <id-do-samsung> \
  --dart-define=API_URL=https://robo-livelo.vercel.app \
  --dart-define=ATIVAR_APP_CHECK=true
```

Resultado confirmado no aparelho:

1. Login real e acesso à API com App Check ativo.
2. Primeira página Livelo e carimbo de atualização.
3. Busca por `Localiza` e por `Moda`.
4. Modos Maior pontuação, Em alerta e Nome A–Z.
5. Rotação entre retrato e paisagem, preservando a navegação inferior.

A API real expôs duas lojas em uma única página; portanto não havia botão
**Carregar mais** disponível no smoke. A paginação, a deduplicação e o descarte
de resposta antiga seguem comprovados pelo CT-269.

O resultado foi registrado em `docs/PENDENCIAS.md` e a Fase 4.2B foi marcada
como concluída no plano.

## Trabalho em andamento — Fase 4.3

A Fase 4.3 foi autorizada em 22 de agosto de 2026 e passou pelos gates locais.
O painel Inter passa a consumir `/api/v1/inter/cashback`, preserva textos e
percentuais como `String`, pagina sob demanda e mostra condições, ausência,
atraso após 24 h e falha recente da coleta sem apagar o último retrato válido.
O contrato agora expõe `ultima_tentativa_em` e `ultima_tentativa_estado` apenas
para esse diagnóstico. Não houve migração, acesso direto do Flutter ao banco ou
alteração nos robôs.

O `flutter analyze`, a formatação e os 73 testes Flutter passaram; a cobertura
da tela Inter é 98,95% e a do controlador é 97,67%. TypeScript, 65 testes
Vitest, build do site, 211 testes Python (94,16%) e Ruff também passaram.
Os builds Web e APK locais foram gerados. O smoke físico ficou adiado por
decisão do responsável; a fase não deve ser marcada concluída antes dele.

## Trabalho em andamento — Fase 4.4

A Fase 4.4 foi autorizada sem repetir testes durante a implementação. A nova
área interna **Produtos no Inter**, acessível pela aba Inter, consulta somente
`GET /api/v1/inter/produtos`: pesquisa com debounce, filtros de marca,
categoria, loja e faixa de preço, paginação manual e agrupamento por loja. Cada
card preserva textos monetários e abre o histórico paginado de 30 dias pela API.
Não houve dependência nova, migração, coleta, alteração nos robôs ou acesso
direto ao Neon.

No fechamento local, `dart format`, `flutter analyze`, os **87 testes Flutter**
e os builds Web/APK passaram. A cobertura crítica ficou em 91,89% na API,
92,23% no controlador, 90,15% na tela de busca, 98,68% no histórico e 100% nos
modelos. TypeScript, 65 testes Vitest, 211 testes Python (94,16%) e Ruff também
passaram. O `next build` compilou, mas falhou duas vezes ao interpretar a saída
válida de `tsc --showConfig` (Next 16.3.1/TypeScript 5.9.3); isso ficou
registrado como pendência técnica do site, sem mudança de dependência nesta
fatia. Falta o smoke físico no Samsung para encerrar a jornada de produtos.

## Alterações locais a preservar

Já existiam mudanças locais de documentação em `app-robo/PLANO.md`; elas
pertencem ao responsável e não devem ser descartadas. As mudanças da Fase 4.2B
também ainda estão locais e não foram publicadas.
