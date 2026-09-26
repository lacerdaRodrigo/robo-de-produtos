# `app/` — Flutter mobile V15

Cliente Flutter do **Radar de Benefícios**. A jornada deste ciclo é somente
mobile V15 e consome exclusivamente a API autenticada em `../backend/api/`.

> **Estado atual:** as Fases 0 a 5 do piloto estão implementadas e a API da Fase 5
> já foi publicada. Autenticação, painéis de leitura e administração usam a API
> (sem prefixo de versão, por domínio).
> O design desta branch é exclusivamente mobile V15. A fonte visual clicável e o contrato completo estão em
> [`../design-app/mobile-v15/index.html`](../design-app/mobile-v15/index.html) e
> [`../docs/guias/design-v15.md`](../docs/guias/design-v15.md).
> O alvo Flutter é Android/iOS; o alvo Web foi removido do aplicativo. O
> protótipo HTML continua apenas como referência visual, e testes fora de
> unitários/widgets não são gate desta branch.

O catálogo Livelo completo está implementado no Android/iOS compacto. Ele
usa a API paginada e preserva filtros e posição nas mutações. Android/iOS
compactos e tablets nativos compartilham a moldura adaptativa; migration,
deploy e aceite físico são operações separadas da implementação local.

## Migração visual mobile V15

A moldura compacta usa os quatro destinos `Início`, `Explorar`, `Meu radar` e
`Perfil`, com tema claro/escuro V15, Manrope, marca `radar.` e componentes
reutilizáveis da fundação visual. O `Meu radar` lê a lista consolidada paginada
em `GET /api/alertas/acompanhamentos`, enquanto a Home consome o bloco pessoal
`radar` de `GET /api/resumo`. Ambos os contratos estão implementados; a
migration 029 foi confirmada aplicada. O aceite físico está no
[`../docs/prd/PRD-ACEITE-MOBILE-V15.md`](../docs/prd/PRD-ACEITE-MOBILE-V15.md).

Os assets oficiais usados pela jornada ficam em `assets/brand/`,
`assets/illustrations/` e `assets/fonts/`. O protótipo HTML é referência
visual, não é executado pelo app e não fornece dados de produção.

No Android Samsung compacto, o Início relê o resumo a cada 30 segundos
somente quando visível e em primeiro plano. A Livelo destaca apenas a melhor
loja acompanhada, mostra a próxima janela/atraso do robô e usa o botão
administrativo idempotente para pedir uma coleta sem chamar Livelo diretamente.
Cada card também permite consultar as últimas 30 pontuações salvas;
abrir o histórico nunca inicia uma coleta.

## Plataformas e identificadores

- projeto Firebase: `radarbeneficios`;
- Android `applicationId`: `br.com.radarbeneficios.app`;
- iOS bundle ID: `br.com.radarbeneficios.app`;
