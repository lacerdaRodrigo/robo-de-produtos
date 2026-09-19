# `app/` — Flutter (Web, Android e iOS)

Cliente Flutter mobile do **Radar de Benefícios**. Consome somente a API
autenticada em `../backend/api/`; esta branch de design não altera o backend.

> **Estado atual:** as Fases 0 a 5 do piloto estão implementadas e a API da Fase 5
> já foi publicada. Autenticação, painéis de leitura e administração usam a API
> (sem prefixo de versão, por domínio).
> O design desta branch é exclusivamente mobile V15. A fonte visual clicável e o contrato completo estão em
> [`../design-app/mobile-v15/index.html`](../design-app/mobile-v15/index.html) e
> [`../docs/guias/design-v15.md`](../docs/guias/design-v15.md).
> Web e testes visuais/automatizados fora de unitários e widgets permanecem
> preservados, mas não são gate desta branch.

O catálogo Livelo completo está implementado somente no Android compacto. Ele
usa a API paginada, preserva filtros e posição nas mutações e mantém Web, iOS e
layout amplo fora do pacote mobile documentado. Migração, deploy e smoke físico não fazem
parte da entrega local.

## Migração visual mobile V15

A moldura compacta usa os quatro destinos `Início`, `Explorar`, `Meu radar` e
`Perfil`, com tema claro/escuro V15, Manrope, marca `radar.` e componentes
reutilizáveis da fundação visual. O `Meu radar` exibe as contagens reais já
fornecidas por `/api/resumo`; a lista consolidada paginada depende de um
contrato de backend ainda não existente e está registrada em
[`../docs/planos/DEPENDENCIAS-BACKEND-MOBILE-V15.md`](../docs/planos/DEPENDENCIAS-BACKEND-MOBILE-V15.md).

Os assets oficiais usados pela jornada ficam em `assets/brand/`,
`assets/illustrations/` e `assets/fonts/`. O protótipo HTML é referência
visual, não é executado pelo app e não fornece dados de produção.

No Android Samsung compacto, o Início relê o resumo salvo a cada 30 segundos
somente quando visível e em primeiro plano. A Livelo destaca apenas a melhor
loja acompanhada, mostra a próxima janela/atraso do robô e usa o botão
administrativo idempotente para pedir uma coleta sem chamar Livelo diretamente.
Cada card também permite consultar as últimas 30 pontuações salvas;
abrir o histórico nunca inicia uma coleta.

## Plataformas e identificadores

- projeto Firebase: `radarbeneficios`;
- Android `applicationId`: `br.com.radarbeneficios.app`;
- iOS bundle ID: `br.com.radarbeneficios.app`;
-
