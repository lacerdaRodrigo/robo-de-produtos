# Relatório de teste em device — Mobile V15

## Identificação

- Branch histórica do device: `codex/design-mobile-v15-definitivo`
- Branch de fechamento local: `codex/backend-mobile-v15-fechamento`
- Commit-base: `e4abb46` — plano de backend e reteste Mobile V15
- Device principal: Samsung SM-M135M, Android 14, conectado por ADB USB
- Application ID: `br.com.radarbeneficios.app`
- APK: `app/build/app/outputs/flutter-apk/app-debug.apk`, instalado com sucesso
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
ao V15 foi implementado localmente; migration, publicação e reteste físico
continuam separados no plano e não consomem tentativa enquanto bloqueados.

## Inventário de testes

| ID | Tela/jornada | Cenário | Resultado | Tentativas | Evidência/observação |
|---|---|---|---|---:|---|
| D-001 | Abertura | Splash, marca e transição para acesso | ✅ | 1 | `d001-abertura.png`, `d071-reopen-after-wait.png`; splash e transição observadas. |
| D-002 | Login | Campos, foco e teclado | ✅ | 1 | `d002-login.png`, `d002-login-after-wait.png`; campos, teclado e foco observados. |
| D-003 | Login | Senha visível/oculta | ✅ | 1 | `d078-senha-visivel.png`; `Ocultar senha` e `password=false` observados após alternância. |
| D-004 | Login | Credencial válida | ✅ | 1 | `d010-after-login.png`, `d069-login-reentry-final.png`, `d082-final-login.png`; autenticação válida concluída três vezes. |
| D-005 | Login | Credencial inválida, erro e retry | ✅ | 1 | `d079-login-invalido.png`; resposta neutra `E-mail ou senha inválidos.` preservou a tela para retry. |
| D-006 | Recuperação | Validação, envio e feedback | 🟡 | 1 | `d080-recuperacao.png`, `d081-recuperacao-validacao.png`; tela e validação vazia aprovadas. Envio real de e-mail não foi disparado para não gerar efeito externo. |
| D-007 | Sessão | Fechar/reabrir app com sessão persistida | ✅ | 1 | `d060-after-unlock.png`, `d071-reopen-after-wait.png`; sessão retomada após reinício da Activity. |
| D-008 | Sessão | Logout e retorno ao acesso | ✅ | 1 | `d068-logout.png`, `d069-login-reentry-final.png`; logout retornou ao acesso e novo login funcionou. |
| D-009 | Moldura | Início, Explorar, Meu radar e Perfil | ✅ | 1 | `d020-explorar.png`, `d040-meu-radar.png`, `d050-perfil.png`; quatro destinos acessíveis. |
| D-010 | Início | Resumo real, carregamento e atualização | 🟡 | 1 | `d052-home-light-fixed-2.png`, `d053-home-dark-fixed.png`; a API agora possui `radar.destaque` real, mas migration/deploy e nova conferência física ainda estão pendentes. |
| D-011 | Início | Erro, parcial, ausência e retry | ⬜ | — | — |
| D-012 | Início | Cards Livelo, Inter e Pichau | ✅ | 1 | `d052-home-light-fixed-2.png`; rail horizontal exibiu contagens reais das três origens. |
| D-013 | Explorar | Cards, busca e abertura das subáreas | ✅ | 1 | `d020-explorar.png`, `d023-explorar-pichau.png`, `d021-livelo.png`, `d024-pichau.png`. |
| D-014 | Inter | Escolha Sites parceiros/Compre direto | ✅ | 1 | `device-v30-inter.png`, `d033-inter-produtos.png`; hub e duas modalidades acessíveis. |
| D-015 | Inter parceiros | Busca, filtros, ordenação e paginação | ⬜ | — | — |
| D-016 | Inter parceiros | Acompanhar, desfazer, rollback e condições | ⬜ | — | — |
| D-017 | Inter parceiros | Abertura da URL real da API | ⬜ | — | — |
| D-018 | Inter direto | Abas, produtos, lojas e categorias | 🟡 | 1 | `d033-inter-produtos.png`, `d034-inter-products-tab.png`, `d035-inter-products-list.png`; hub, aba Produtos e lista reais aprovados; abas/categorias restantes continuam no aceite manual. |
| D-019 | Inter direto | Filtros, busca, acompanhamento e histórico | ⬜ | — | — |
| D-020 | Livelo | Catálogo, busca, filtros e ordenação | 🟡 | 1 | `d021-livelo.png`; catálogo real aberto. Busca, filtros e ordenação físicos completos continuam pendentes. |
| D-021 | Livelo | Pontos, condições, campanhas e validade | 🟡 | 1 | Dados reais renderizados no catálogo; cobertura física completa de condições/campanhas/validade continua pendente. |
| D-022 | Livelo | Acompanhamento, paginação e histórico | ⬜ | — | — |
| D-023 | Pichau | Catálogo, busca, filtros e disponibilidade | 🟡 | 1 | `d024-pichau.png`; catálogo real aberto. Busca/filtros/disponibilidade em todos os estados continuam pendentes. |
| D-024 | Pichau | Preço Pix/cartão, detalhe e histórico | ⬜ | — | — |
| D-025 | Pichau | Acompanhamento, paginação e estados parciais | ⬜ | — | — |
| D-026 | Meu radar | Contagens reais por origem | ✅ | 1 | `d040-meu-radar.png`; evidência física histórica das contagens reais. A lista consolidada nova está coberta por widget/API e aguarda device após deploy. |
| D-027 | Meu radar | Vazio, explorar, alertas e atualização | 🟡 | 1 | `d040-meu-radar.png`, `d041-alertas.png`; explorar/alertas acessíveis; fixture QA e nova lista paginada aguardam migration/deploy. |
| D-028 | Alertas | Lista, vazio, filtros e paginação | 🟡 | 1 | `d072-alertas-formatado.png`, `d076-alertas-filtro-preco.png`; lista e filtro Preço aprovados; vazio/paginação físicos continuam pendentes. |
| D-029 | Alertas | Leitura individual e coletiva | ⬜ | — | — |
| D-030 | Alertas | Preferências e push opcional | ✅ | 1 | `d073-alertas-preferencias.png`, `d074-permissao-notificacoes.png`, `d075-permissao-recusada.png`; preferências abertas e recusa preservou o histórico. |
| D-031 | Perfil | Tema claro, escuro e sistema | ✅ | 1 | `d052-home-light-fixed-2.png`, `d053-home-dark-fixed.png`, `d051-aparencia.png`; claro/escuro e tela de aparência verificados. |
| D-032 | Perfil | Movimento reduzido e preferências | ⬜ | — | — |
| D-033 | Suporte | Ajuda, privacidade e relato de problema | ✅ | 1 | `d061-ajuda.png`, `d062-reportar-problema.png`, `d063-reportar-validacao.png`, `d064-privacidade.png`; telas abertas e envio vazio validou o relato sem mutação. |
| D-034 | Perfil | Laboratório e logout | ✅ | 1 | `d067-laboratorio.png`, `d068-logout.png`; laboratório abriu e logout retornou ao acesso. |
| D-035 | Administração | Proteção, acesso e ausência para usuário comum | 🟡 | 1 | `d065-administracao.png`; conta autorizada viu a Zona de perigo. Usuário comum exige outra conta/fixture e permanece pendente. |
| D-036 | Administração | Zona de perigo, prévia e confirmação | ✅ | 1 | `d066-admin-livelo-previa.png`; prévia, contagens e confirmação textual foram exibidas; botão destrutivo permaneceu desabilitado sem frase exata. |
| D-037 | Responsividade | Retrato, paisagem e teclado aberto | ⬜ | — | — |
| D-038 | Acessibilidade | Texto ampliado até 200% e alvos de toque | ⬜ | — | — |
| D-039 | Estados | Offline, atraso, falha, retry e sessão expirada | ⬜ | — | — |
| D-040 | Visual | Comparação final com o protótipo V15 | 🟡 | 1 | Claro/escuro, Home, Explorar, Livelo, Pichau, Inter, Alertas, Perfil e suporte foram renderizados; permanece a divergência de dados reais da Home descrita em D-010. |
| D-041 | Device | Bloqueio e retomada via ADB | ✅ | 1 | `d060-after-unlock.png`; aparelho bloqueado/desbloqueado e jornada retomada. |
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

## Bloqueios externos

- A nova resposta real (`radar.destaque`) ainda não foi publicada no ambiente
  usado pelo APK histórico. Não foi criado dado fictício no Flutter; o
  checkpoint está em `PLANO-BACKEND-E-RETESTE-MOBILE-V15.md`.
- Os cenários offline, sessão expirada, vazio controlado, usuário comum,
  paginação física completa e links externos dependem de ambiente/contas ou de
  um roteiro manual adicional; permanecem amarelos ou pendentes, nunca foram
  marcados como verde por inferência.

## Fechamento

- Testes ✅: 19
- Testes ❌: 0
- Testes 🟡: 10
- Testes ⬜: 13
- Última validação estática: `flutter analyze` — `No issues found!`
- Unitários/widgets diretamente afetados nesta implementação local: 56 — todos passaram
- Último APK instalado: `app/build/app/outputs/flutter-apk/app-debug.apk` — sucesso

## Estado do fechamento local — 2026-09-19

- ✅ Backend: `npm run checar`, `npm run lint` (sem erros), `npm run build` e
  Vitest direcionado: 15 testes aprovados.
- ✅ Flutter: `dart format`, `flutter analyze` e o conjunto direcionado deste
  ciclo: 56 testes aprovados.
- 🟡 Migration: `migracoes/029_indices_mobile_v15.sql` ainda não aplicada;
  checksum `ec0394b66618b9606373a3a34dcdb97f183813e059f53d87abf41ff78d179a89`.
- 🟡 Deploy/APK/device: aguardam confirmação da aplicação da migration. Não
  houve publicação nem nova marcação verde por inferência.
- ⬜ Os 42 cenários físicos não foram reclassificados nesta etapa; as linhas
  acima preservam a evidência histórica e o próximo reteste deve atualizar
  cada ID com check verde ou vermelho, sem deixar falha persistente.
