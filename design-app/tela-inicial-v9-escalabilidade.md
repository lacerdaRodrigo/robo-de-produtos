# Decisão de produto — tela inicial da V9

## Contexto

Livelo e Banco Inter representam hoje duas lojas/fontes com robôs próprios. No futuro, o aplicativo poderá receber outras lojas com seus respectivos robôs de coleta.

A tela inicial não deve crescer indefinidamente conforme novos robôs sejam adicionados. Ela deve continuar funcionando como um resumo rápido, enquanto a tela de Serviços concentra a navegação completa.

## Regra de escalabilidade

- A tela inicial mostra somente lojas e robôs que realmente existem no backend.
- Nenhuma integração futura deve ser simulada ou exibida antes de estar funcional.
- O resumo geral informa quantos robôs estão atualizados e quantos precisam de atenção.
- A área de atenção mostra somente robôs com falha recente, coleta parcial ou dados preservados.
- A lista principal da Home deve exibir no máximo três ou quatro robôs em formato compacto.
- Quando houver mais robôs, a Home oferece a ação **Ver todos os robôs**.
- A tela de Serviços contém a lista completa e a pesquisa.
- Lojas internas, produtos e resultados de coleta continuam dentro da tela do respectivo robô; não são listados individualmente na Home.

## Comportamento com dez robôs

Com dez robôs cadastrados, a tela inicial continua curta:

1. Exibe o estado geral das coletas.
2. Destaca os robôs que precisam de atenção.
3. Mostra no máximo três ou quatro robôs na lista principal.
4. Informa a quantidade total na ação **Ver todos os 10 robôs**.
5. Encaminha o usuário para Serviços para consultar os demais.

## Limite do backend atual

Na V9, somente Livelo e Banco Inter são apresentados porque são os serviços existentes no projeto atual. A regra acima documenta a evolução visual, mas não adiciona endpoints, dados, lojas ou funcionalidades fictícias.

Quando um novo robô for realmente implementado, o backend também precisará expor seu estado e seus dados. Só então ele deverá aparecer na Home e na tela de Serviços seguindo o mesmo padrão visual.

## Arquivo relacionado

- `design-app/prototipo-mobile-redesign-novo-9.html`

