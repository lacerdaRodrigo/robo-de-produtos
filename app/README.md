# `app/` — Flutter (Web, Android e iOS)

Cliente multiplataforma do **Radar de Benefícios**. Atende Web, Android e iOS com
o mesmo código, consumindo somente a API autenticada em `../backend/api/`.

> **Estado atual:** as Fases 0 a 5 do piloto estão implementadas e a API da Fase 5
> já foi publicada. Autenticação, painéis de leitura e administração usam a API
> (sem prefixo de versão, por domínio).
> O design atual é exclusivamente mobile. A fonte visual clicável e o contrato completo estão em
> [`../design-app/prototipo-mobile-redesign-novo-11.html`](../design-app/prototipo-mobile-redesign-novo-11.html) e
> [`../design-app/SISTEMA-DESIGN-MOBILE-V11.md`](../design-app/SISTEMA-DESIGN-MOBILE-V11.md).
> Web e testes visuais/automatizados fora de unitários e widgets permanecem
> preservados, mas não são gate desta branch.

O catálogo Livelo completo está implementado somente no Android compacto. Ele
usa a API paginada, preserva filtros e posição nas mutações e mantém Web, iOS e
layout amplo fora do pacote mobile documentado. Migração, deploy e smoke físico não fazem
parte da entrega local.

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
