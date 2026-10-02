# PRD — Aceite físico do Mobile V15

**Status:** evidências históricas até 2026-09-19, rodadas no Samsung em
2026-09-27, 2026-09-28, 2026-09-30 e 2026-10-01, além de uma rodada parcial
anterior no Moto em 2026-09-29. A build `1.74.0+2026100103` passou 29/29
cenários no Samsung M13. Uma correção posterior de cabeçalho gerou a build
`1.74.0+2026100104`, ainda sem instalação física porque o ADB deste ambiente
não consegue iniciar o daemon. O aceite completo continua aberto; as evidências
não substituem as pendências abertas em
[`../PENDENCIAS.md`](../PENDENCIAS.md) nem autorizam publicação externa.

## Identificação

- Branch histórica do device: `codex/design-mobile-v15-definitivo`
- Branch de fechamento local: `main`
- Commit-base do APK retestado: `f1ffa13` — merge da implementação V15 e backend
- Device principal: Samsung SM-M135M, Android 14, conectado por ADB USB
- Application ID: `br.com.radarbeneficios.app`
- APK: `app/build/app/outputs/flutter-apk/app-debug.apk`, build `27503`, instalado com sucesso
- Início: 2026-09-19
- Credenciais: usadas somente durante o login; não são registradas neste arquivo

## Legenda

- ✅ **OK** — fluxo executado e aprovado; quando houve correção, unitário e
  widget diretamente afetados também passaram.
- ❌ **FALHOU** — erro reproduzido e não corrigido após três tentativas.
- 🟡 **BLOQUEADO** — depende de backend, deploy externo, autorização ou
  intervenção manual do aparelho.
- ⬜ **PENDENTE** — ainda não executado.

## Regras do ciclo

Cada correção pode ter no máximo três tentativas. Uma tentativa inclui
reprodução, correção, `dart format`, `flutter analyze`, unitário/widget
afetados, novo APK, instalação e repetição no aparelho. O backend necessário
ao V15 foi implementado, a migration 029 foi confirmada como aplicada pelo
responsável e o APK atual foi instalado contra a API publicada. Dependências
externas restantes continuam registradas como bloqueio e não consomem
tentativa enquanto não houver condição de execução.

### Runner local autorizado para o Samsung

`tools/mobile-device-acceptance/` contém o runner Appium local autorizado para
este plano. Ele exige somente o Samsung autorizado, configurado localmente por
`ANDROID_SERIAL`, preserva os dados instalados (`noReset=true`), usa a sessão já
autenticada sem receber senha e guarda as evidências fora do repositório com
permissões privadas. Não entra em CI, não cria fixtures de Production, não tenta
renovar sessão e não confirma ações irreversíveis. O runner cobre navegação e
leitura dos estados existentes;
aprovação automatizada só atualiza os cenários equivalentes depois da inspeção
das evidências e do resultado real. A exceção não libera E2E genérico, teste
visual automatizado ou o teste comentado de Shopping Inter compacto.

### Verificação focada do Compre direto — 2026-09-28

- ✅ APK `1.73.1+2026092801` instalado no Samsung SM-M135M por ADB, preservando
  os dados e a sessão já autenticada.
- ✅ `Perfil → Administração → Compre direto` abriu o catálogo administrativo
  completo. A busca encontrou Casas Bahia e a chave enviou sua seleção; sair e
  reabrir a lista confirmou `Selecionada: sim` pela leitura da API.
- ✅ A consulta direta somente leitura ao banco confirmou Casas Bahia ativa e
  selecionada. A coleta manual `36373453844` concluiu a execução `9` com uma
  loja, 58 páginas, 2.070 itens lidos, 1.927 únicos, 143 duplicados e qualidade
  `completa`. O agendamento não foi alterado.
- ✅ Em `Explorar → Banco Inter → Compre direto`, a busca `motorola` retornou
  66 ofertas da Casas Bahia. Um cartão real exibiu preço, cashback e acesso aos
  detalhes. O banco continha 1.927 produtos ativos dessa loja após a coleta.
- A verificação resolve o bloqueio que impedia seleção de lojas no perfil
  compacto. Não conclui paginação, histórico, comparação formal com o HTML V15,
  nem aceite para usuário sem papel administrativo.

### Rodada de navegação e catálogos — 2026-09-28

- ✅ Samsung SM-M135M, Android 14. APK `1.74.0+2026092802` instalado com
  `adb install -r` depois de comparar a assinatura; dados locais e sessão
  autenticada preservados. Commit-base `c8bc931a98af4e3083b91f2006c1c54f8c93b12c`;
  SHA-256 do APK `f3e2eec1d8756c903e8673529a825f4aaf15f964fad1cf3f062165a6d406761a`.
- ✅ Runner local: 13/13 cenários de navegação passaram. Foram abertos Início,
  Explorar, hub Banco Inter, Sites parceiros, Compre direto, Livelo, Pichau,
  Meu radar e Alertas; as rotas secundárias voltaram à origem com o back Android.
- ✅ O card Banco Inter da Home abriu o hub. Sites parceiros exibiu 379 lojas;
  `Ver condições` abriu o endereço real do Shopping Inter no Chrome e o back
  retornou ao app.
- ✅ Compre direto carregou 1.924 produtos da Casas Bahia, página 1 de 193.
  A página 2 mostrou outros produtos; um detalhe e o histórico com quatro
  medições reais abriram. A folha de filtros abriu; com o teclado visível, uma
  rolagem deixou `Limpar` e `Aplicar filtros` acessíveis. Não alterei
  acompanhamento nem apliquei filtro nessa tela.
- ✅ Pichau carregou 1.223 produtos reais. `Todos` retornou 1.223,
  `Disponíveis` 535 e `Esgotados` 688. A busca `Draconis` retornou dois produtos.
  Com preço mínimo de R$ 3.000 e ordenação por menor preço Pix, a API publicada
  retornou 1.088 produtos e o primeiro custava R$ 3.004,23; sem mínimo havia
  produtos abaixo de R$ 3.000. A página 2 abriu, assim como o detalhe e o
  histórico real com oito medições. Isso confirma a filtragem observada no APK
  atual; não houve deploy nesta rodada. Depois, limpei a busca e restaurei os
  filtros para Todos, sem preço mínimo/máximo.
- ✅ Capturas e JSON foram guardados fora do repositório, com permissões
  privadas, em `~/.local/state/radar-mobile-device-acceptance/evidence/20260929T021136Z/`
  (o nome usa UTC; a execução ocorreu em 28/09 no horário local). Exemplos:
  `manual/inter-direct-pagination-page2.png`,
  `manual/inter-direct-history.png`,
  `manual/inter-partner-external-link.png`,
  `manual/pichau-min-3000-results.png`, `manual/pichau-detail.png` e
  `manual/pichau-history.png`. Não houve login/logout, compra, escrita de
  acompanhamento, marcação de alertas, criação de fixtures ou alteração remota.
- 🟡 A rodada não encontrou alertas não lidos para exercitar filtros e leitura
  coletiva em várias páginas. Também não cobre cardinalidades físicas 9/10/11,
  conta comum, sessão expirada, todos os estados parciais/erro, leitura de tela,
  Moto G6 Play ou comparação formal de todas as telas com o HTML V15. Esses
  limites permanecem em [`../PENDENCIAS.md`](../PENDENCIAS.md).

### Build atual e navegação no Samsung M13 — 2026-09-30

- ✅ APK debug `1.74.0+2026100102`, commit `331c7c1cac60a80ff856523aee27d1820897732d`, SHA-256
  `8761e34e29374dbb3d1740aaf628f5385c0fd14bfd1a5cac525d2ea8e801a2ce`, instalado
  com `adb install -r` no Samsung SM-M135M (`RX8W105DHSY`, Android 14). A
  instalação preservou os dados locais e a sessão existente.
- ✅ Runner local: 14/14 cenários passaram. Home, Explorar, Meu radar, Perfil,
  Alertas, Livelo, Pichau, hub Inter, Sites parceiros e Compre direto abriram;
  a Central foi aberta pelo botão da Home e o back Android retornou à Home.
- ✅ A sessão atual mostrou quatro alertas não lidos na Home e 27 itens em Meu
  radar. Nenhum alerta foi lido, acompanhamento foi alterado, fixture criada ou
  dado remoto modificado nesta rodada.
- ✅ Pichau: em `Filtros → Disponibilidade → Fora do catálogo`, a API retornou
  zero produtos e a tela mostrou `Nenhum PC Gamer corresponde aos filtros
  atuais.`. `Limpar` restaurou `Todos` com 1.228 produtos. Erro e parcial não
  foram provocados.
- ✅ A ação de alertas agora é identificável pela árvore de acessibilidade do
  Android; o runner encontrou e tocou o botão, e o widget afetado confirmou o
  rótulo e a ação semânticos.
- Evidências privadas (JSON e capturas) em
  `~/.local/state/radar-mobile-device-acceptance/evidence/20261001T015735Z/`.
  A pasta usa UTC; a execução ocorreu em 30/09 no horário local.
- 🟡 Esta rodada só aplicou o filtro Pichau acima; não alterou alertas, não exercitou
  paginação da Central e não comparou formalmente todas as telas ao HTML V15.
  Quatro alertas não cobrem uma lista com mais de uma página. TalkBack e texto
  ampliado em todas as rotas também permanecem pendentes.

### Rodada completa de catálogos no M13 — 2026-10-01, build 103

- ✅ APK `1.74.0+2026100103`, `versionCode=2026100103`, commit
  `331c7c1cac60a80ff856523aee27d1820897732d`, SHA-256
  `8d7b61131266e5f1f16b86f27642181cfeb867239159ebcd81e8b5154402020f`,
  instalado no Samsung SM-M135M, Android 14. O runner local passou 29/29.
- ✅ Sites parceiros Inter: catálogo real, página 2, busca com resultados e
  sem resultados, categoria `Outros`, ordenação pelo nome da loja, filtros e
  back Android. Isso fecha o aceite físico desses comportamentos nesta build.
- ✅ Compre direto: catálogo real da Casas Bahia, busca com resultado e vazio,
  filtro `Acessórios`, aba `No radar`, limpeza/restauração, página 2 e back.
  Só havia uma loja selecionada; agrupamento de múltiplas lojas não estava
  disponível para conferir.
- ✅ Pichau: `Fora do catálogo` mostrou estado vazio; `Limpar` restaurou
  `Todos` com 1.228 produtos. Erro e parcial não foram provocados.
- ✅ Central: dois alertas não lidos; abas e filtro de origem exercitados. O
  recorte da origem mostrou estado vazio e voltar a `Todos` restaurou os itens.
  Não houve mutação de leitura; dois itens não cobrem paginação.
- ✅ Produtos, Livelo, Sites parceiros e Compre direto foram percorridos no
  estado e cardinalidades que os dados reais ofereciam. Não havia resultado
  natural com exatamente 9, 10 e 11 cards para validar todos os limites.
- ✅ Comparação manual lado a lado com o HTML V15 cobriu nove jornadas
  principais: Home, Explorar, hub Inter, Sites parceiros, Compre direto,
  Livelo, Pichau, Meu radar e Central. Foi encontrado um sobretexto laranja no
  hub Inter, ausente no HTML. A correção removeu esse elemento no código e no
  widget; a build 104 ainda precisa ser instalada e revista no M13. As telas
  secundárias de Perfil e a comparação formal de todas as telas continuam
  abertas.
- 🟡 A escala 200% foi exercitada até Compre direto. Após 14 passos o runner
  não alcançou `Aplicar filtros`, que ficou abaixo da área visível; isso não
  reproduziu overflow. O runner foi ajustado para rolar folhas longas e incluir
  subrotas de Perfil, mas a versão ajustada ainda não foi executada no aparelho.
- Evidências privadas em
  `~/.local/state/radar-mobile-device-acceptance/evidence/20261001T040639Z/`.
  Nenhum alerta ou acompanhamento foi alterado e nenhuma fixture foi criada.

### Correção local posterior — build 104

O cabeçalho do hub Inter agora segue o HTML, que não contém a sobrelinha
`ESCOLHA A EXPERIÊNCIA`; o widget valida sua ausência. A build debug
`1.74.0+2026100104` foi criada localmente com SHA-256
`97c10c66314b967b45e83a6c0e496ae1e632c9ceb05621e74ac784e17f4f1451`.
Esta sessão não conseguiu iniciar o ADB (`could not install *smartsocket*
listener: Operation not permitted`), então a instalação e a comparação física
desta build não foram confirmadas.

### Rodada Meu radar — 2026-09-27

- ✅ APK `1.73.1+2026092702` instalado com assinatura correspondente por
  `adb install -r`; os dados locais e a sessão existente foram preservados.
- ✅ Runner local: 13/13 cenários de navegação aprovados. A espera do cenário
  Meu radar usa o título estável `No seu radar`.
- ✅ Captura `meu-radar.png` inspecionada privadamente: cabeçalho abaixo da área
  segura do Android, busca e filtros na ordem V15. A conta retornou um
  acompanhamento Riachuelo em estado `Sem dados`; nenhum valor ilustrativo,
  condição ou data foi criado no cliente.
- ✅ `flutter test test/app/paginas/meu_radar_test.dart`,
  `flutter test test/app/componentes/fundacao_visual_test.dart`,
  `flutter analyze` e `git diff --check` passaram.
- As capturas e o resultado JSON permanecem fora do repositório, em diretório
  local com permissões privadas. Esta rodada não completa o aceite físico geral.
- 🟡 APK final `1.73.1+2026092703` instalado com assinatura correspondente e
  dados preservados. A nova execução parou no primeiro estado porque o app abriu
  na tela de acesso; nenhum cenário foi executado e o runner não tentou login.
  Esta build só altera o recuo superior da tela Meu radar, coberto pelos testes
  de widget e análise; a conferência física desse último recuo depende de uma
  sessão autenticada.

## Execução física atual — 2026-09-19

- ✅ Device `RX8W105DHS` (`Samsung SM-M135M`, Android 14) conectado por ADB USB.
- ✅ APK gerado com `flutter build apk --debug --build-number=27503` usando a
  API publicada e instalado com `adb install -r`.
- ✅ Primeiro acesso do APK passou pelo splash, pediu a permissão de
  notificações e abriu a Home com dados reais de Livelo, Banco Inter e Pichau.
- ✅ Migration `migracoes/029_indices_mobile_v15.sql` foi aplicada e confirmada
  pelo responsável com as duas instruções `CREATE` concluídas; não houve
  escrita adicional do Codex no banco durante o reteste.
- ✅ Foram percorridos Home, Explorar, Meu radar, Alertas, Inter parceiros,
  Inter Compre direto/Produtos, Livelo, Pichau, Perfil, Aparência, Ajuda,
  Relatar problema, Privacidade, Laboratório QA e Administração.
- ✅ Na continuação física, Livelo abriu a página `2` e o histórico real de
  Angeloni; Pichau abriu a página `2`, o histórico real do Draconis com `55`
  medições nos últimos `30` dias e o filtro `Esgotados`, que retornou `741`
  ofertas.
- ✅ Central de Alertas: leitura individual mudou `52` para `51` não lidos;
  `Marcar visíveis` zerou os itens carregados na página. Após reabrir, `33`
  alertas permaneceram fora da página carregada, comportamento compatível com
  a ação limitada aos itens visíveis e paginação.

> Nota de manutenção (2026-09-20): o registro acima é evidência do APK build
> `27503`, anterior à composição V15 da Central. A implementação atual usa
> `Marcar todos como lidos`, percorre todas as páginas do recorte e mantém a
> paginação; o aceite físico dessa versão ainda está pendente em
> `docs/PENDENCIAS.md`.
- ✅ Nenhuma remoção administrativa foi confirmada: a prévia Livelo abriu, a
  frase exata foi exigida e o botão permaneceu desabilitado sem confirmação.
- ✅ Bloqueio/desbloqueio com o app aberto preservou a rota administrativa e a
  sessão. Retrato/paisagem foram exercitados e o aparelho foi restaurado para
  rotação automática/retrato. Escala de fonte 200% foi exercitada em uma rota
  longa; não houve `RenderFlex overflow` no log, mas a cobertura completa por
  rota continua parcial.
- ✅ Offline controlado no APK `27503`: ao desligar o Wi‑Fi e reiniciar o app,
  a validação do perfil terminou em estado de falha com a ação `Tentar
  novamente`, sem permanecer indefinidamente na tela de carregamento. Depois
  da reassociação do Wi‑Fi, a reabertura do app retomou a Home real com `33`
  alertas; o botão também foi exercitado com a rede já em estado `COMPLETED`.
- 🟡 A distribuição privada por Drive continua dependente de OAuth externo;
  isso não impediu o APK local via ADB, mas ainda impede declarar a publicação
  privada concluída.

## Aceite funcional local — 2026-09-27

- ✅ Samsung `SM-M135M`, Android 14; sessão existente preservada.
- ✅ Build `1.73.1+2026092602`, API Production, App Check desativado conforme a
  configuração do piloto. APK universal instalado com `adb install -r`, após
  comparar o certificado; nenhum dado do app foi limpo.
- ✅ Commit-base `05e0109b3e2ce5f3a914c9637f64127dd67fecc6`; APK SHA-256
  `1c6e9db987c85ff2e1e46e249b784140bdfdf6319b6128e42d299d0d1128038d`.
- ✅ Os 13 cenários locais passaram: Home e quatro destinos, Explorar, hub
  Banco Inter, Sites parceiros e Compre direto, retorno Android entre as rotas,
  catálogos Livelo/Pichau, Meu radar, Central de Alertas e retornos para Home.
- ✅ Foram somente leituras e navegação. O teste não fez login/logout, não
  acompanhou lojas, não marcou alertas como lidos, não alterou preferências e
  não criou fixtures. A sessão atual mostrou Meu radar vazio e Compre direto
  com zero produtos; isso permanece uma condição real a reconciliar com as
  evidências históricas, não foi preenchido com dados artificiais.
- ✅ Evidências JSON e 13 capturas estão privadas em
  `~/.local/state/radar-mobile-device-acceptance/evidence/20260927T032012Z/`;
  cada arquivo tem modo `0600`, e o diretório fica fora do Git.
- 🟡 A primeira build de diagnóstico foi restrita a `arm64` e falhou ao abrir
  porque esta ROM inicia o processo como `armeabi-v7a`. Ela foi substituída
  pelo APK universal acima. Nenhum dado/cache foi limpo e essa primeira build
  não conta como aceite.
- 🟡 A rodada confirma a navegação e os estados que estavam visíveis; não
  substitui a conferência visual formal com o HTML V15 nem testa paginação,
  cards/histórico Inter sem produtos, leitura coletiva sem alertas pendentes,
  session expiry, conta comum ou fluxo FCM.

## Inspeção diagnóstica da build anterior — Moto G6 Play — 2026-09-29

- 🟡 O responsável abriu o APK no Motorola Moto G6 Play, Android 9, tela
  reportada como `720×1440`, por scrcpy. Na versão anterior às correções desta
  fatia, observou que Explorar mostrava cartões mais altos que o HTML V15, com
  capacidades/estados extras e sombra; os atalhos da Home mostravam contagens
  no lugar das descrições fixas da referência. A barra inferior e as barras do
  sistema também pareciam mais altas ou escuras que o protótipo.
- 🟡 Na Central aberta pelo sino da Home, tocar `Explorar` não fechou a rota e
  manteve `Início` selecionado. Esta foi a evidência física que motivou a
  correção de navegação e seleção; o botão/gesto Android já fazia o retorno à
  rota anterior.
- Esta inspeção descreve somente a build anterior às correções e não deve ser
  usada para avaliar esta branch.

## Conferência manual parcial da branch local — Moto G6 Play — 2026-09-29

- 🟡 APK debug desta branch instalado por atualização (`adb -s 0047447355
  install -r`), no Motorola Moto G6 Play, Android 9, resolução física
  `720×1440` (área Flutter observada em `360×720`). A sessão autenticada
  continuou ativa. Não houve limpeza de dados, logout, mutação de preferência,
  acompanhamento, leitura de alertas, pedido de permissão ou envio de relato.
- ✅ Home e Explorar abriram; Banco Inter mostrou as duas modalidades. Sites
  parceiros mostrou 379 lojas; a busca `Temu` retornou uma loja, e a categoria
  `Eletrônicos` mostrou o estado vazio com zero lojas. Ao limpar o recorte, as
  379 lojas voltaram. Compre direto exibiu 1.924 produtos; a categoria
  `Acessórios` retornou quatro e a busca `suporte` retornou sete, com o total
  restaurado ao limpar os filtros e a busca. A primeira abertura das categorias
  do Compre direto levou cerca de 22 s; em duas reaberturas as opções chegaram
  em aproximadamente 8–12 s. Livelo exibiu 256 lojas; `Casa e decoração`
  retornou 26 e `Limpar` restaurou as 256. Pichau exibiu 1.223 produtos;
  `Esgotados` retornou 688 e `Limpar` restaurou os 1.223. A aba `No radar` da
  Pichau mostrou o vazio real. Nenhuma busca ou filtro iniciou coleta ou gravou
  dados.
- ✅ Meu radar exibiu os dois itens existentes. A Central abriu vazia, exibiu
  os seletores separados de origem e tipo, e voltou à moldura pela aba
  Explorar. A rota Notificações e a folha V15 de permissão abriram; a folha foi
  fechada sem solicitar permissão.
- ✅ Aparência, Ajuda, Privacidade e Reportar problema abriram. A barra inferior
  permaneceu visível nas rotas secundárias; trocar para Explorar fechou também
  a rota Reportar problema aberta a partir de Ajuda. Back Android retornou de
  Explorar à Home. Só o tema claro foi observado; os controles de preferência
  permaneceram intactos.
- 🟡 Comparação manual com referências V15 disponíveis confirmou a estrutura da
  Home, Explorar, hub Inter e Aparência. As outras capturas foram inspecionadas
  quanto a hierarquia e comportamento, sem comparação formal de pixels tela a
  tela. As capturas sem dados pessoais estão em
  `~/.local/state/radar-mobile-device-acceptance/evidence/20260929-moto-g6-v15/`
  (diretório `0700`, arquivos `0600`, fora do Git).
- 🟡 O APK consulta a API publicada. A folha de alertas mostra o filtro de
  origem, mas esta conferência não o aplicou porque o endpoint publicado ainda
  não contém o parâmetro; os testes locais cobrem o contrato novo. Também
  continuam sem aceite no Moto: paginação nos limites, histórico, estados de
  erro/parcial, conta comum, sessão expirada, dark mode e envio/entrega FCM.
  Esta rodada parcial não conclui o aceite físico completo.

## Inventário de testes

O inventário mantém os resultados do ciclo anterior; `D-043` registra a rodada
local de 2026-09-27 e `D-044` a inspeção manual parcial do Moto em 2026-09-29,
cada uma com build e evidência próprios. Não reaproveitar estados históricos
como evidência da build desta branch.

| ID | Tela/jornada | Cenário | Resultado | Tentativas | Evidência/observação |
|---|---|---|---|---:|---|
| D-001 | Abertura | Splash, marca e transição para acesso | ✅ | 1 | `d001-abertura.png`, `d071-reopen-after-wait.png`; splash atual também observada no APK build `27502`. |
| D-002 | Login | Campos, foco e teclado | ✅ | 1 | `d002-login.png`, `d002-login-after-wait.png`; campos, teclado e foco observados. |
| D-003 | Login | Senha visível/oculta | ✅ | 1 | `d078-senha-visivel.png`; `Ocultar senha` e `password=false` observados após alternância. |
| D-004 | Login | Credencial válida | ✅ | 1 | `d010-after-login.png`, `d069-login-reentry-final.png`, `d082-final-login.png`; autenticação válida concluída três vezes. |
| D-005 | Login | Credencial inválida, erro e retry | ✅ | 1 | `d079-login-invalido.png`; resposta neutra `E-mail ou senha inválidos.` preservou a tela para retry. |
| D-006 | Recuperação | Validação, envio e feedback | 🟡 | 1 | `d080-recuperacao.png`, `d081-recuperacao-validacao.png`; tela e validação vazia aprovadas. Envio real de e-mail não foi disparado para não gerar efeito externo. |
| D-007 | Sessão | Fechar/reabrir app com sessão persistida | ✅ | 1 | `d060-after-unlock.png`, `d071-reopen-after-wait.png`; sessão retomada após reinício da Activity. |
| D-008 | Sessão | Logout e retorno ao acesso | ✅ | 1 | `d068-logout.png`, `d069-login-reentry-final.png`; logout retornou ao acesso e novo login funcionou. |
| D-009 | Moldura | Início, Explorar, Meu radar e Perfil | ✅ | 1 | `d020-explorar.png`, `d040-meu-radar.png`, `d050-perfil.png`; quatro destinos acessíveis. |
| D-010 | Início | Resumo real, carregamento e atualização | ✅ | 1 | APK atual abriu a Home com resposta real da API publicada, contagem de alertas e atualização após leitura. O campo `radar.destaque` permaneceu disponível no contrato da Central, sem cartão de alerta na Home compacta. Migration 029 confirmada aplicada. |
| D-011 | Início | Erro, parcial, ausência e retry | ⬜ | — | — |
| D-012 | Início | Cards Livelo, Inter e Pichau | ✅ | 1 | `d052-home-light-fixed-2.png`; rail horizontal exibiu contagens reais das três origens. |
| D-013 | Explorar | Cards, busca e abertura das subáreas | ✅ | 1 | `d020-explorar.png`, `d023-explorar-pichau.png`, `d021-livelo.png`, `d024-pichau.png`. |
| D-014 | Inter | Escolha Sites parceiros/Compre direto | ✅ | 1 | `device-v30-inter.png`, `d033-inter-produtos.png`; hub e duas modalidades acessíveis. |
| D-015 | Inter parceiros | Busca, filtros, ordenação e paginação | ✅ | 3 | Build `1.74.0+2026100103`, 29/29 passos. No M13: catálogo real, página 2, busca com resultado/vazio, categoria `Outros`, ordenação pelo nome e retorno Android. |
| D-016 | Inter parceiros | Acompanhar, desfazer, rollback e condições | ✅ | 1 | Natura foi acompanhada e removida novamente; mensagens de sucesso, condições e estado original foram restaurados. |
| D-017 | Inter parceiros | Abertura da URL real da API | ✅ | 1 | Revalidado em `1.74.0+2026092802`: `Ver condições` abriu a URL real do Shopping Inter no Chrome e o back retornou ao app. |
| D-018 | Inter direto | Produtos, lojas e categorias | 🟡 | 3 | Build `1.74.0+2026100103` percorreu produtos reais e categoria `Acessórios`; havia somente Casas Bahia selecionada, então o agrupamento com múltiplas lojas não pôde ser verificado. |
| D-019 | Inter direto | Filtros, busca, acompanhamento e histórico | ✅ | 3 | Build `1.74.0+2026100103` confirmou busca com resultado/vazio, categoria `Acessórios`, aba `No radar`, limpar/restaurar e página 2. Histórico real já havia sido aberto em rodada anterior; esta execução foi somente leitura. |
| D-020 | Livelo | Catálogo, busca, filtros e ordenação | ✅ | 2 | Catálogo real, busca por `ACER`, filtros de categoria/acompanhamento e ordenação `Nome A–Z` foram exercitados. Na rodada anterior no Moto, `Casa e decoração` retornou 26 de 256 lojas e limpar restaurou as 256. |
| D-021 | Livelo | Pontos, condições, campanhas e validade | ✅ | 1 | Cards reais exibiram pontos normal/Clube, campanha, condições e validade até `23/09/2026`. |
| D-022 | Livelo | Acompanhamento, paginação e histórico | ✅ | 1 | Angeloni foi acompanhada e removida novamente; página 2 e histórico real com medições foram abertos. |
| D-023 | Pichau | Catálogo, busca, filtros e disponibilidade | ✅ | 3 | `Draconis`, filtros reais, detalhe/histórico e `Fora do catálogo` foram exercitados; o último mostrou estado vazio e `Limpar` restaurou `Todos` com 1.228 produtos. Erro/parcial pertencem ao D-025. |
| D-024 | Pichau | Preço Pix/cartão, detalhe e histórico | ✅ | 2 | Em `1.74.0+2026092802`, Pix/cartão reais, filtro mínimo R$ 3.000 aplicado pela API e detalhe/histórico abriram; o histórico mostrou oito medições. Na rodada anterior no Moto, Draconis exibiu mínimo/máximo e histórico com 55 medições nos últimos 30 dias. |
| D-025 | Pichau | Acompanhamento, paginação e estados parciais | 🟡 | 1 | Acompanhamento foi desfeito/restaurado e página 2 foi aberta; estados parciais adicionais ainda não foram forçados. |
| D-026 | Meu radar | Contagens reais por origem | ✅ | 1 | Lista atual mostrou `74 acompanhamentos ativos`, com filtros Livelo/Inter e cartões reais. |
| D-027 | Meu radar | Vazio, explorar, alertas e atualização | 🟡 | 2 | A build `1.74.0+2026100103` mostrou 27 acompanhamentos na Home e em Meu radar; evidências históricas registram 74, zero e uma Riachuelo em `Sem dados`. A identidade/corte de dados ainda precisa ser reconciliada, sem completar valores ausentes. |
| D-028 | Alertas | Lista, vazio, filtros e paginação | 🟡 | 3 | Build `1.74.0+2026100103`: dois não lidos, abas e filtro por origem; a origem mostrou vazio e restaurar `Todos` trouxe os itens. Não houve leitura individual/coletiva; dois alertas não permitem testar paginação nem estado global vazio. |
| D-029 | Alertas | Leitura individual e coletiva | 🟡 | 2 | A evidência antiga do build 27503 marcou leituras, mas a ação atual percorre todas as páginas. No build 103 a rodada foi somente leitura; falta exercitar no M13 a ação individual e `Marcar todos como lidos` com alertas reais. |
| D-030 | Alertas | Preferências e push opcional | ✅ | 1 | `d073-alertas-preferencias.png`, `d074-permissao-notificacoes.png`, `d075-permissao-recusada.png`; preferências abertas e recusa preservou o histórico. |
| D-031 | Perfil | Tema claro, escuro e sistema | ✅ | 1 | `d052-home-light-fixed-2.png`, `d053-home-dark-fixed.png`, `d051-aparencia.png`; claro/escuro e tela de aparência verificados. |
| D-032 | Perfil | Movimento reduzido e preferências | ✅ | 1 | Aparência alternou redução de movimento para ativo e foi restaurada para desativado, junto com o tema claro. |
| D-033 | Suporte | Ajuda, privacidade e relato de problema | ✅ | 1 | `d061-ajuda.png`, `d062-reportar-problema.png`, `d063-reportar-validacao.png`, `d064-privacidade.png`; telas abertas e envio vazio validou o relato sem mutação. |
| D-034 | Perfil | Laboratório e logout | ✅ | 1 | `d067-laboratorio.png`, `d068-logout.png`; laboratório abriu e logout retornou ao acesso. |
| D-035 | Administração | Proteção, catálogo e ausência para usuário comum | 🟡 | 1 | Em `1.73.1+2026092801`, a conta autorizada abriu o catálogo Compre direto pelo Perfil e a seleção da Casas Bahia persistiu na API/banco. A validação de ausência para usuário comum exige outra conta/fixture e permanece pendente. |
| D-036 | Administração | Zona de perigo, prévia e confirmação | ✅ | 1 | `d066-admin-livelo-previa.png`; prévia, contagens e confirmação textual foram exibidas; botão destrutivo permaneceu desabilitado sem frase exata. |
| D-037 | Responsividade | Retrato, paisagem e teclado aberto | ✅ | 1 | Paisagem e restauração para retrato foram exercitadas; teclado abriu durante busca Inter/Pichau e foi fechado sem perder a jornada. |
| D-038 | Acessibilidade | Texto ampliado até 200% e alvos de toque | 🟡 | 2 | M13 em escala 2.0: Administração e 14 passos de rotas passaram sem overflow; em Compre direto, `Aplicar filtros` ficou abaixo da área visível. O runner agora rola a folha, mas falta repetir a cobertura em todas as rotas, alvos e TalkBack. |
| D-039 | Estados | Offline, atraso, falha, retry e sessão expirada | 🟡 | 1 | Offline/retry já foi observado em build anterior; sessão Firebase expirada, atraso controlado e estados vazios/parciais de todos os domínios ainda dependem de sessão de QA/condição externa. |
| D-040 | Visual | Comparação final com o protótipo V15 | 🟡 | 3 | Comparação manual no M13 cobriu nove jornadas principais contra o HTML V15. Corrigiu-se no código a sobrelinha extra do hub Inter; falta instalar/rever a build 104 e comparar as telas secundárias de Perfil e os estados/temas restantes. |
| D-041 | Device | Bloqueio e retomada via ADB | ✅ | 1 | Com a confirmação administrativa aberta, a tela foi apagada e desbloqueada; a mesma rota e sessão foram retomadas no APK. |
| D-042 | Instalação | Reinstalação do APK e abertura limpa | ✅ | 2 | APK debug local instalado por `adb install -r`; sessão persistiu e a Home carregou após a validação de acesso. |
| D-043 | Navegação | Rotas V15 e back Android com sessão existente | ✅ | 3 | 29/29 cenários passaram no build `1.74.0+2026100103`; evidências em `~/.local/state/radar-mobile-device-acceptance/evidence/20261001T040639Z/`. Sessão preservada; nenhum alerta ou acompanhamento foi alterado. |
| D-044 | Navegação e comparação parcial | Branch local no Moto, filtros e rotas secundárias | 🟡 | 1 | APK SHA-256 `c9fb9aa6b72a3463e9aa4813e5669b29b7e4eb46132324f69da0f2505807414e`; sessão preservada. Capturas `home-final.png`, `appearance-final.png`, `alerts-final.png`, `inter-direct-filter-applied-acessorios.png`, `inter-partners-filter-electronicos-empty.png`, `livelo-filter-casa-aplicado.png`, `pichau-filter-esgotados-aplicado.png`, `report-final.png` e demais telas ficam em `~/.local/state/radar-mobile-device-acceptance/evidence/20260929-moto-g6-v15/`. Buscas e filtros de catálogo foram aplicados e limpos sem mutação de dados; o filtro de origem da Central não foi aplicado porque a API publicada ainda não aceita esse parâmetro. É evidência histórica e não valida esta revisão no Samsung M13. |
| D-045 | Build e instalação final desta revisão | Build atual instalada no Samsung SM-M135M (M13) | 🟡 | 4 | A última APK gerada é `1.74.0+2026100104`, SHA-256 `97c10c66314b967b45e83a6c0e496ae1e632c9ceb05621e74ac784e17f4f1451`; ela não contém o parser Pichau corrigido nem a extração do hub Inter. A tentativa de gerar a build 105 falhou porque o Gradle Wrapper não pôde baixar a distribuição; ADB também falha ao iniciar neste ambiente (`could not install *smartsocket* listener: Operation not permitted`). |

## Correções realizadas

- `1/3` — Semântica do sino da Home: o rótulo do Android agora anuncia a
  Central e o total de alertas não lidos; o badge visual deixa de substituir o
  nome acessível. O widget diretamente afetado confirma o rótulo e a ação
  semântica. A build `1.74.0+2026100102` foi instalada no M13; o runner encontrou
  o botão, abriu a Central e retornou à Home pelo back Android.
- `1/3` — header compacto: marca passou a usar fundação visual compartilhada e
  alinhamento direcional correto em claro/escuro; validado no device e nos
  widgets de navegação.
- `1/3` — Home compacta: removida a composição antiga, com rail horizontal de
  origens e dados reais da API; validada em claro/escuro e nos widgets da Home.
- `1/3` — Cashback Inter: ações inferiores empilham em largura/texto ampliado
  para eliminar overflow em 320 px; widget diretamente afetado passou.
- `1/3` — Central de Alertas: valores de preço passaram de decimal bruto para
  moeda local (`R$ 2.092,88`) com formatação textual, sem `double` e sem
  alteração do payload/backend; validado no APK instalado (`d072`/`d076`) e no
  unitário de formatação.
- `1/3` — Gate de acesso: a consulta inicial de `/api/perfil` passou a ter
  timeout de 10 segundos; falha de rede exibe `EstadoFalha` e retry, sem
  deixar a abertura presa em `Validando seu acesso ao piloto…`. Widget test,
  build `27503` e cenário offline/reabertura no Samsung passaram.

## Bloqueios externos

### Verificação local posterior — 2026-10-01

- A build `1.74.0+2026100104` contém a correção visual do hub Inter. Depois
  disso, foi corrigida no modelo Pichau a leitura do estado parcial no envelope
  real da API, e o hub Inter foi extraído de `lojas.dart` para
  `features/inter/pagina_hub_shopping_inter.dart`; os resumos compartilhados
  ficaram em `app/componentes/resumo_fonte.dart`. O bloco administrativo sem
  referências foi removido; a tela ativa continua sendo `PaginaAdministracao`.
- `dart format --suppress-analytics` verificou os arquivos Flutter afetados e
  `dart analyze --suppress-analytics`, executado em todo o app com o SDK isolado
  em `/tmp`, concluiu com `No issues found!`. O comando Flutter convencional
  não consegue atualizar telemetria em `/home/rodrigo/.dart-tool`, somente
  leitura. Os testes focados de Pichau e, depois da extração, os widgets de
  moldura e Sites parceiros iniciaram, mas o runner não conseguiu abrir o
  socket local do Flutter Tester (`Operation not permitted`); nenhum desses
  testes produziu resultado nesta sandbox.
- Tentei gerar uma nova APK `2026100105`; o Gradle Wrapper não conseguiu
  baixar a distribuição por causa da rede restrita. Essa tentativa ocorreu
  antes da extração do hub. A APK 104 existente não contém as últimas alterações
  do modelo ou da composição Flutter, e continua sem instalação confirmada no
  M13. Repetir os gates, gerar uma build da revisão atual e instalá-la quando o
  ambiente Flutter/ADB estiver liberado.

- A distribuição privada por Drive falhou no CI `35471530166` com
  `invalid_grant` porque o refresh token OAuth expirou ou foi revogado. É
  necessário renovar/publicar a credencial externa antes do aceite da
  distribuição privada; isso não bloqueou o APK local instalado por ADB.
- Sessão expirada, atraso controlado, vazio controlado, usuário comum,
  paginação física completa e alguns históricos dependem de ambiente/contas ou
  de um roteiro manual adicional; permanecem amarelos ou pendentes, nunca foram
  marcados como verde por inferência.

## Fechamento histórico da validação até 2026-09-19

- Testes ✅: 29
- Testes ❌: 0
- Testes 🟡: 11
- Testes ⬜: 2
- Última validação estática concluída: `flutter analyze` — `No issues found!`, antes da correção local do modelo Pichau acima.
- Últimos unitários/widgets diretamente afetados concluídos: 95 — passaram antes da correção local do modelo Pichau acima.
- Último APK instalado no Samsung M13: build `1.74.0+2026100103`; a build 104 contém a correção visual do hub Inter, mas não foi instalada; a correção posterior do modelo Pichau ainda não gerou APK.

## Estado do fechamento local — 2026-09-19

- ✅ Backend: `npm run checar`, `npm run lint` (sem erros), `npm run build` e
  Vitest direcionado: 15 testes aprovados.
- ✅ Flutter: `dart format`, `flutter analyze` e o conjunto direcionado deste
  ciclo anterior: 56 testes aprovados; nesta rodada foram executados 95
  unitários/widgets direcionados, todos aprovados.
- ✅ Migration: `migracoes/029_indices_mobile_v15.sql` aplicada e confirmada
  pelo responsável; checksum
  `ec0394b66618b9606373a3a34dcdb97f183813e059f53d87abf41ff78d179a89`.
- ✅ APK/device: build `27503` compilada, instalada e revalidada no Samsung;
  29 cenários estão verdes, sem falha reproduzida não corrigida.
- 🟡 Os 13 cenários restantes estão divididos entre cobertura parcial e
  dependências de ambiente/conta: históricos, estados de sessão expirada,
  usuário comum, paginação completa, recuperação real, comparação visual formal
  e distribuição privada.
