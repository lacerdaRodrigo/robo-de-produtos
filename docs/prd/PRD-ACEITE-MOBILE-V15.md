# PRD — Aceite físico do Mobile V15

**Status:** registro completo da validação Android/iOS executada até 2026-09-19.
Os cenários continuam sendo evidência, não substituem as pendências abertas em
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

## Inventário de testes

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
| D-015 | Inter parceiros | Busca, filtros, ordenação e paginação | 🟡 | 1 | Lista real de parceiros, busca por `Multi` e filtros foram abertos; ordenação e paginação física completa ainda não foram percorridas. |
| D-016 | Inter parceiros | Acompanhar, desfazer, rollback e condições | ✅ | 1 | Natura foi acompanhada e removida novamente; mensagens de sucesso, condições e estado original foram restaurados. |
| D-017 | Inter parceiros | Abertura da URL real da API | ✅ | 1 | `Ver condições` abriu a URL real do Shopping Inter no Chrome e o retorno voltou ao app sem perder a jornada. |
| D-018 | Inter direto | Abas, produtos, lojas e categorias | 🟡 | 1 | Hub real, modos Sites parceiros/Compre direto, abas `Todas`, `Selecionadas` e `Produtos`, árvore `Eletrônicos → Computadores` e atalhos de busca foram observados; retorno completo e todas as folhas ainda não foram percorridos. |
| D-019 | Inter direto | Filtros, busca, acompanhamento e histórico | ⬜ | — | — |
| D-020 | Livelo | Catálogo, busca, filtros e ordenação | ✅ | 1 | Catálogo real, busca por `ACER`, filtros de categoria/acompanhamento e ordenação `Nome A–Z` foram exercitados. |
| D-021 | Livelo | Pontos, condições, campanhas e validade | ✅ | 1 | Cards reais exibiram pontos normal/Clube, campanha, condições e validade até `23/09/2026`. |
| D-022 | Livelo | Acompanhamento, paginação e histórico | ✅ | 1 | Angeloni foi acompanhada e removida novamente; página 2 e histórico real com medições foram abertos. |
| D-023 | Pichau | Catálogo, busca, filtros e disponibilidade | 🟡 | 1 | Busca `Draconis`, Pix/cartão, `Esgotado` e filtro `Esgotados` foram exercitados; cobertura do estado `Disponíveis` ainda falta. |
| D-024 | Pichau | Preço Pix/cartão, detalhe e histórico | ✅ | 1 | Draconis exibiu Pix/cartão reais, mínimo/máximo e histórico com `55` medições nos últimos `30` dias. |
| D-025 | Pichau | Acompanhamento, paginação e estados parciais | 🟡 | 1 | Acompanhamento foi desfeito/restaurado e página 2 foi aberta; estados parciais adicionais ainda não foram forçados. |
| D-026 | Meu radar | Contagens reais por origem | ✅ | 1 | Lista atual mostrou `74 acompanhamentos ativos`, com filtros Livelo/Inter e cartões reais. |
| D-027 | Meu radar | Vazio, explorar, alertas e atualização | 🟡 | 1 | Meu radar cheio, filtro Livelo, buscas reais e busca `zzzzzz` com estado vazio foram executados; remoção e paginação completa continuam pendentes. |
| D-028 | Alertas | Lista, vazio, filtros e paginação | 🟡 | 1 | Lista real, filtros `Todos`/`Preço` e paginação implícita foram observados; estado vazio e paginação física completa continuam pendentes. |
| D-029 | Alertas | Leitura individual e coletiva (build 27503) | ✅ | 1 | Evidência histórica: `Marcar lido` reduziu `52` para `51`; `Marcar visíveis` zerou os itens carregados. A versão atual precisa de novo aceite físico porque a ação agora percorre todas as páginas. |
| D-030 | Alertas | Preferências e push opcional | ✅ | 1 | `d073-alertas-preferencias.png`, `d074-permissao-notificacoes.png`, `d075-permissao-recusada.png`; preferências abertas e recusa preservou o histórico. |
| D-031 | Perfil | Tema claro, escuro e sistema | ✅ | 1 | `d052-home-light-fixed-2.png`, `d053-home-dark-fixed.png`, `d051-aparencia.png`; claro/escuro e tela de aparência verificados. |
| D-032 | Perfil | Movimento reduzido e preferências | ✅ | 1 | Aparência alternou redução de movimento para ativo e foi restaurada para desativado, junto com o tema claro. |
| D-033 | Suporte | Ajuda, privacidade e relato de problema | ✅ | 1 | `d061-ajuda.png`, `d062-reportar-problema.png`, `d063-reportar-validacao.png`, `d064-privacidade.png`; telas abertas e envio vazio validou o relato sem mutação. |
| D-034 | Perfil | Laboratório e logout | ✅ | 1 | `d067-laboratorio.png`, `d068-logout.png`; laboratório abriu e logout retornou ao acesso. |
| D-035 | Administração | Proteção, acesso e ausência para usuário comum | 🟡 | 1 | `d065-administracao.png`; conta autorizada viu a Zona de perigo. Usuário comum exige outra conta/fixture e permanece pendente. |
| D-036 | Administração | Zona de perigo, prévia e confirmação | ✅ | 1 | `d066-admin-livelo-previa.png`; prévia, contagens e confirmação textual foram exibidas; botão destrutivo permaneceu desabilitado sem frase exata. |
| D-037 | Responsividade | Retrato, paisagem e teclado aberto | ✅ | 1 | Paisagem e restauração para retrato foram exercitadas; teclado abriu durante busca Inter/Pichau e foi fechado sem perder a jornada. |
| D-038 | Acessibilidade | Texto ampliado até 200% e alvos de toque | 🟡 | 1 | Escala Android `2.0` foi exercitada em Administração com conteúdo rolável e sem `RenderFlex overflow`; cobertura física de todas as rotas ainda é parcial. |
| D-039 | Estados | Offline, atraso, falha, retry e sessão expirada | 🟡 | 1 | Correção `1/3`: perfil inicial ganhou timeout de 10 s e o offline exibiu falha/retry no APK `27503`; sessão Firebase expirada e atraso controlado ainda dependem de fixture/conta. |
| D-040 | Visual | Comparação final com o protótipo V15 | 🟡 | 1 | Home, Explorar, Livelo, Pichau, Inter, Alertas, Perfil, suporte, claro e escuro foram renderizados no APK atual; comparação formal tela a tela com o HTML V15 ainda não foi fechada. |
| D-041 | Device | Bloqueio e retomada via ADB | ✅ | 1 | Com a confirmação administrativa aberta, a tela foi apagada e desbloqueada; a mesma rota e sessão foram retomadas no APK. |
| D-042 | Instalação | Reinstalação do APK e abertura limpa | ✅ | 1 | `flutter build apk --debug`, `adb install -r` e `d071-reopen-after-wait.png`; APK abriu e passou pelo splash. |

## Correções realizadas

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

- A distribuição privada por Drive falhou no CI `35471530166` com
  `invalid_grant` porque o refresh token OAuth expirou ou foi revogado. É
  necessário renovar/publicar a credencial externa antes do aceite da
  distribuição privada; isso não bloqueou o APK local instalado por ADB.
- Sessão expirada, atraso controlado, vazio controlado, usuário comum,
  paginação física completa e alguns históricos dependem de ambiente/contas ou
  de um roteiro manual adicional; permanecem amarelos ou pendentes, nunca foram
  marcados como verde por inferência.

## Fechamento

- Testes ✅: 29
- Testes ❌: 0
- Testes 🟡: 11
- Testes ⬜: 2
- Última validação estática: `flutter analyze` — `No issues found!`
- Unitários/widgets diretamente afetados nesta implementação local: 95 — todos passaram
- Último APK instalado: `app/build/app/outputs/flutter-apk/app-debug.apk`, build `27503` — sucesso

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
