# CHANGELOG

<!-- version list -->

## v1.44.0 (2026-08-29)


## v1.43.0 (2026-08-26)

### Features

- **app**: Versao do app no rodape da navegacao
  ([`1f58f78`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/1f58f789f94555fdedd7efc5014621b59bcf642d))


## v1.42.0 (2026-08-26)

### Chores

- **ci**: Remove workflow temporário de regenerar goldens
  ([`9b32756`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/9b3275665ba97c5780aea55bd851688389a04edd))

### Features

- **api**: Loga detalhe do erro de token quando DEBUG_AUTH=true
  ([`1a8a0e1`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/1a8a0e18dc304032ef7c8bebc6d0a13dd916ceca))


## v1.41.0 (2026-08-26)

### Bug Fixes

- **api**: Resolve firebase-admin ERR_REQUIRE_ESM no serverless
  ([`014702c`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/014702ca93fb6e60f6fdab3207e60544f5afa285))

- **ci**: Pina GitPython 3.1.50 no versao.yml
  ([`e37fc4c`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/e37fc4c7caefe75df504c01b507d935e52d27aa7))

- **ci**: Pina semantic-release em 10.4.1 e corrige caminho do catálogo
  ([`5cc2542`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/5cc254285fc5fd6246e5f00fcbfe69b8a7244814))

### Chores

- **ci**: Workflow temporário de regenerar goldens no runner
  ([`f171bc1`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/f171bc1db637cd704950b996b5175f1a761309fe))

### Documentation

- Adiciona README em cada pasta e atualiza raiz
  ([`5933f5c`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/5933f5c57939774e38119bc91c962aa1f62367ca))

- Reorganiza docs em subpastas e remove referências ao site legado
  ([`430ed84`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/430ed84c32caf312907260bf4d1ee2158d5490fd))

- **prd**: Renomeia PRDs por domínio/ação
  ([`74036ca`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/74036cab4d255f31dd4712bc89355c17ab9b1ab0))

### Features

- Desativa site Next.js e arquiva API em app-robo/apis
  ([`01aba7d`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/01aba7d7ac34465e905d2ac748996f8a63409075))

- **robo**: E-mail opcional — sem credencial roda igual
  ([`bf8e49a`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/bf8e49a52c394cd0de5c4c1c41b466cd808ca218))

### Refactoring

- Consolida backend Python em app-robo/backend
  ([`1a778e2`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/1a778e2c57fc47d61d525b40e4fa34b4cf5f318e))

- Renomeia raiz robo-livelo para robo e reorganiza pastas
  ([`59ea599`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/59ea5996d8d07a7f45fc17eaa26524f19253e883))

- **api**: Remove prefixo v1 e renomeia para caminhos por domínio
  ([`93c7e49`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/93c7e497b1f94afd1698ca79d41b0ad2c1b5ea82))

### Testing

- **app**: Regenera golden da lateral Web e remove restos de diff
  ([`0b4e709`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/0b4e709fb90bae02b31094ef205579932779e654))

- **app**: Usa goldens gerados no runner do CI (referência do gate)
  ([`a833ee3`](https://github.com/lacerdaRodrigo/robo-de-produtos/commit/a833ee34cfbd1231c8190e0d17beaa88dacc78a3))


## v1.40.0 (2026-08-23)

### Features

- **app-robo**: Redesenha busca e histórico de produtos
  ([`ba40f2c`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ba40f2cc6228ddf5aa7f3ec56ebb808f3852955a))


## v1.39.0 (2026-08-23)

### Features

- **app-robo**: Implementa hubs de lojas e inter
  ([`20b6d56`](https://github.com/lacerdaRodrigo/robo-livelo/commit/20b6d56724fd1ec88b7440c573840382f05ff137))


## v1.38.0 (2026-08-23)

### Features

- **app-robo**: Implementa módulos 1 a 3 do redesign
  ([`b39d357`](https://github.com/lacerdaRodrigo/robo-livelo/commit/b39d357a5ad24e48cb4304b2c7048ee4871a89b5))


## v1.37.0 (2026-08-23)

### Features

- **app-robo**: Implementa abertura animada da nova identidade
  ([`bdbb2ee`](https://github.com/lacerdaRodrigo/robo-livelo/commit/bdbb2ee8deafa663bd2ad473cdce0f52d1fecfee))


## v1.36.0 (2026-08-23)

### Bug Fixes

- Usa dominio movel publico no app
  ([`d032a79`](https://github.com/lacerdaRodrigo/robo-livelo/commit/d032a79d5219834a17121629abe59cb9a8a1572b))

### Documentation

- Atualiza planos e adota prototipo primeiro
  ([`045df46`](https://github.com/lacerdaRodrigo/robo-livelo/commit/045df465e1c059b9f1a55f29cdf5cd09a6451c17))

### Features

- Adiciona prototipos web e mobile do Radar
  ([`f58c1db`](https://github.com/lacerdaRodrigo/robo-livelo/commit/f58c1db752d10f12f4f8d974928ea4beeb2ee650))


## v1.35.0 (2026-08-22)

### Documentation

- Registra versao 1.34.0
  ([`d3a3cc4`](https://github.com/lacerdaRodrigo/robo-livelo/commit/d3a3cc4df00e72ec06e71064ed75f04ab9e8eed2))

### Features

- Conclui painéis Flutter de benefícios
  ([`40b33c5`](https://github.com/lacerdaRodrigo/robo-livelo/commit/40b33c5188cab31da2167e9ad4de6a4134c90fd9))

- Publica administracao no app Flutter
  ([`39dcad4`](https://github.com/lacerdaRodrigo/robo-livelo/commit/39dcad40e1299fbde37a99d3aec23ad8505805f8))


## v1.34.0 (2026-08-21)

### Documentation

- Registra versao 1.33.0
  ([`2776bb0`](https://github.com/lacerdaRodrigo/robo-livelo/commit/2776bb0536d464a3294d39ca82e98179e4d2bbad))

### Features

- Adapta navegacao para Android
  ([`cb3c8b4`](https://github.com/lacerdaRodrigo/robo-livelo/commit/cb3c8b49c0181f6cd68a84becfb71875f7197b5f))


## v1.33.0 (2026-08-21)

### Documentation

- Fecha rollout autenticado da fase 3B
  ([`97341ba`](https://github.com/lacerdaRodrigo/robo-livelo/commit/97341bab849d976867da8f6c9dad0d49c4d132e1))

### Features

- Aplica retencao da auditoria da API
  ([`d96ec33`](https://github.com/lacerdaRodrigo/robo-livelo/commit/d96ec33f98aa4f89aa4ac407cce570c378786b20))


## v1.32.2 (2026-08-21)

### Bug Fixes

- Empacota Firebase Admin na API
  ([`e796b98`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e796b98a90958e8396d42263eceaea166233fd7b))


## v1.32.1 (2026-08-21)

### Bug Fixes

- Adia carregamento do Firebase App Check
  ([`79c69e0`](https://github.com/lacerdaRodrigo/robo-livelo/commit/79c69e0b44f2b0de75e91ab5e754a3f0c2aa5ec7))


## v1.32.0 (2026-08-21)

### Features

- Conclui autenticacao por convite no Flutter
  ([`28b3166`](https://github.com/lacerdaRodrigo/robo-livelo/commit/28b3166fdca514100f4910dcf32be4c696f35ea4))


## v1.31.0 (2026-08-20)

### Documentation

- Adiciona instruções para o Codex
  ([`62a561a`](https://github.com/lacerdaRodrigo/robo-livelo/commit/62a561a3ce20cf2211d15ac033bea7ffa1c837a5))

- **app-robo**: Adiciona plano do piloto Flutter
  ([`7b18075`](https://github.com/lacerdaRodrigo/robo-livelo/commit/7b1807597d2e2f1ed5dc77a3e44405bfc035ab05))

- **app-robo**: Detalha catálogo e paginação da API
  ([`4ec42ee`](https://github.com/lacerdaRodrigo/robo-livelo/commit/4ec42ee910d9a7e4d031cb33fc635a808b7072cb))

### Features

- **app-robo**: Inicio do Flutter e API v1 de leitura
  ([`732de42`](https://github.com/lacerdaRodrigo/robo-livelo/commit/732de423257fb6ff41a98c512f17437f7048ca48))


## v1.30.2 (2026-08-19)

### Bug Fixes

- **inter**: Preserva paginação e permite descartar lojas
  ([#33](https://github.com/lacerdaRodrigo/robo-livelo/pull/33),
  [`e921769`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e92176928f02de4088921e2d98e07af38d033b19))


## v1.30.1 (2026-08-19)

### Bug Fixes

- **inter**: Deixa preço após cashback no mesmo destaque
  ([#32](https://github.com/lacerdaRodrigo/robo-livelo/pull/32),
  [`3fd0257`](https://github.com/lacerdaRodrigo/robo-livelo/commit/3fd0257f55f35ac787d5d6dbe37becfecaa92904))


## v1.30.0 (2026-08-19)

### Features

- **inter**: Destaca preço após cashback
  ([#31](https://github.com/lacerdaRodrigo/robo-livelo/pull/31),
  [`13d60dc`](https://github.com/lacerdaRodrigo/robo-livelo/commit/13d60dc651c6e2ea1932a0dd810627a442bf6fa4))


## v1.29.6 (2026-08-19)

### Bug Fixes

- **inter**: Adiciona botão para atualizar produtos selecionados
  ([`1e66e14`](https://github.com/lacerdaRodrigo/robo-livelo/commit/1e66e148f0028fb6d4cc6a1947fc7a78b19b17d0))


## v1.29.5 (2026-08-18)

### Bug Fixes

- **site**: Adiciona botao de atualizacao da livelo
  ([`12cb627`](https://github.com/lacerdaRodrigo/robo-livelo/commit/12cb627dfb2bbf9c53ae93926c039e53052617a7))


## v1.29.4 (2026-08-18)

### Bug Fixes

- **inter**: Exibe loja selecionada sem esperar snapshot
  ([`dc633de`](https://github.com/lacerdaRodrigo/robo-livelo/commit/dc633def22922494d9f390cc86d80af047082c25))


## v1.29.3 (2026-08-18)

### Bug Fixes

- **site**: Reflete selecao nas consultas imediatamente
  ([`71ad5e2`](https://github.com/lacerdaRodrigo/robo-livelo/commit/71ad5e2aa4016c74c91b8f291da29824788c58c2))


## v1.29.2 (2026-08-18)

### Bug Fixes

- **livelo**: Nao reidrata lojas nao escolhidas
  ([`3af4f9c`](https://github.com/lacerdaRodrigo/robo-livelo/commit/3af4f9cd96a28cbf1fca4043630f6456b2a09ac3))


## v1.29.1 (2026-08-18)

### Bug Fixes

- **site**: Mostra total de lojas encontradas
  ([`e12225e`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e12225e4a22ab60fd14e4d5ab1ec29fc68813550))


## v1.29.0 (2026-08-18)

### Features

- **livelo**: Separa descobertas de lojas favoritas
  ([`d574ddd`](https://github.com/lacerdaRodrigo/robo-livelo/commit/d574ddde70689b6634d57db1ee71c82de65bb0f5))


## v1.28.4 (2026-08-18)

### Bug Fixes

- **site**: Atualiza inter ao selecionar loja
  ([`5cef360`](https://github.com/lacerdaRodrigo/robo-livelo/commit/5cef36004b5fed31e84f912b08fa3f36fee831f2))


## v1.28.3 (2026-08-18)

### Bug Fixes

- **livelo**: Reidrata catalogo apos limpeza
  ([`3c67f58`](https://github.com/lacerdaRodrigo/robo-livelo/commit/3c67f587bae91acfe30a9b43ada547be99092c7d))


## v1.28.2 (2026-08-18)

### Bug Fixes

- **site**: Inclui oferta atual no reset do Inter
  ([`8084f82`](https://github.com/lacerdaRodrigo/robo-livelo/commit/8084f8245f402a6ccbdf6a633502374e7c7ee649))


## v1.28.1 (2026-08-18)

### Bug Fixes

- **produtos-inter**: Preserve best catalog on unstable totals
  ([`4141e5b`](https://github.com/lacerdaRodrigo/robo-livelo/commit/4141e5bbb986b27d1b80eff3cc55f724bb71c5f9))


## v1.28.0 (2026-08-17)

### Features

- **inter**: Contabiliza produtos ativos das lojas
  ([`79512c4`](https://github.com/lacerdaRodrigo/robo-livelo/commit/79512c49004fa2154fa4328d6bd1a695d4bbdd5b))

- **inter**: Exibe total de produtos coletados
  ([`0eceadd`](https://github.com/lacerdaRodrigo/robo-livelo/commit/0eceadd2f3e33baf6904c4353d57e6d03f37498f))


## v1.27.0 (2026-08-17)

### Bug Fixes

- **inter**: Preserva busca após selecionar loja
  ([`ff7884b`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ff7884b9c00906582e5457abb6f6048167780030))

### Code Style

- **inter**: Redesenha diálogo de remoção
  ([`61f5f35`](https://github.com/lacerdaRodrigo/robo-livelo/commit/61f5f353afb3066b1f92eefeaf925cc628fd73c2))

### Features

- **inter**: Adiciona confirmação segura em tela
  ([`e6b5c09`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e6b5c095c4cc127775a4c8b6eff5db611c19bb9c))

- **inter**: Melhora gestão das lojas de produtos
  ([`72718af`](https://github.com/lacerdaRodrigo/robo-livelo/commit/72718af120a16437872d0b6aef9614857c394241))

- **inter**: Pagina todas as lojas de produtos
  ([`5fb1add`](https://github.com/lacerdaRodrigo/robo-livelo/commit/5fb1add289fc35bf47ddff09095cd65631ce2e3f))


## v1.26.0 (2026-08-17)

### Bug Fixes

- **inter**: Corrige resumo responsivo
  ([`58c260a`](https://github.com/lacerdaRodrigo/robo-livelo/commit/58c260a0fcd74746801d41d4bd1fd2c3029e697c))

- **inter**: Pagina catalogo completo no banco
  ([`9be5f98`](https://github.com/lacerdaRodrigo/robo-livelo/commit/9be5f98dcbb4c3fb30f78a50dd24490d9aedd235))

### Features

- **inter**: Pagina todas as lojas de dez em dez
  ([`203fb8b`](https://github.com/lacerdaRodrigo/robo-livelo/commit/203fb8b7a8f780848cd7baa2d3f837edf822b617))


## v1.25.0 (2026-08-17)

### Bug Fixes

- **site**: Restaura listas ao limpar a busca
  ([`a419e2b`](https://github.com/lacerdaRodrigo/robo-livelo/commit/a419e2be50d760bf4585224da80dedd06555f10e))

- **site**: Usa tokens visuais da paginacao
  ([`ef0fc65`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ef0fc652d2ff34f4fa09f18aebd5028e45d4a41e))

### Features

- **site**: Adiciona busca progressiva reutilizavel
  ([`07a45fb`](https://github.com/lacerdaRodrigo/robo-livelo/commit/07a45fb64dfc1ca9995d3a4c8c301127633a8941))

- **site**: Adiciona paginacao segura
  ([`bb732f9`](https://github.com/lacerdaRodrigo/robo-livelo/commit/bb732f9388573f12192e97965e23ef118e89eea4))

- **site**: Ativa busca progressiva nas lojas de produtos
  ([`bf39672`](https://github.com/lacerdaRodrigo/robo-livelo/commit/bf39672a6f0b4070f906fd7853b7fbb4384c8230))

- **site**: Ativa busca progressiva nas lojas Livelo
  ([`7a283cd`](https://github.com/lacerdaRodrigo/robo-livelo/commit/7a283cd6f9634feda7ad8c02ff31e595c48ce1fe))

- **site**: Ativa busca progressiva nos produtos Inter
  ([`b12576a`](https://github.com/lacerdaRodrigo/robo-livelo/commit/b12576a1bff4ac07b5996d4e6c22e6f4904a4707))

- **site**: Estiliza paginacao responsiva
  ([`5ef7e48`](https://github.com/lacerdaRodrigo/robo-livelo/commit/5ef7e48e4dbc0c67914bea27ca233819b0164521))

- **site**: Simplifica pontos e pagina lojas
  ([`3f990f6`](https://github.com/lacerdaRodrigo/robo-livelo/commit/3f990f6ebf33ae4035d8c9ce03c205a936be53ab))

### Refactoring

- **site**: Remove busca duplicada do Inter
  ([`2c1f874`](https://github.com/lacerdaRodrigo/robo-livelo/commit/2c1f8743aa3c9d173d73a318e9d6092f4d3f2e44))

- **site**: Reutiliza busca progressiva nas lojas Inter
  ([`6e69773`](https://github.com/lacerdaRodrigo/robo-livelo/commit/6e697733001cc6f7af52d6401ca8b4a08a8ff7c1))

- **site**: Reutiliza busca progressiva no cashback
  ([`c099010`](https://github.com/lacerdaRodrigo/robo-livelo/commit/c0990107d20dca64014a8137e6c584a7a4af217d))

### Testing

- **site**: Cobre paginacao de lojas
  ([`9b0d6e1`](https://github.com/lacerdaRodrigo/robo-livelo/commit/9b0d6e1160508d64cd8ae46903817a0007df6bba))


## v1.24.0 (2026-08-17)

### Bug Fixes

- Remove seletor de areas do Inter
  ([`4330d70`](https://github.com/lacerdaRodrigo/robo-livelo/commit/4330d70b3c60f6da73fc703dcf30ba334c8d4e8b))

- Remove seletor de areas duplicado
  ([`117f538`](https://github.com/lacerdaRodrigo/robo-livelo/commit/117f5389df01f656959622d94551f25735104b57))

- Remove seletor de areas duplicado
  ([`468d932`](https://github.com/lacerdaRodrigo/robo-livelo/commit/468d932b19413f5d4ff228c6286777c58f00465f))

- Remove seletor de areas duplicado
  ([`922bbb7`](https://github.com/lacerdaRodrigo/robo-livelo/commit/922bbb7ff91cdac566886c41a26894b373b21b6f))

### Code Style

- **ux**: Alinha seletor de duas areas
  ([`2b2ed24`](https://github.com/lacerdaRodrigo/robo-livelo/commit/2b2ed2447bad3a5ff5059975b79ae956c8e0b695))

- **ux**: Apresenta fluxos em grupos simples
  ([`338f582`](https://github.com/lacerdaRodrigo/robo-livelo/commit/338f58257e7d3e245b4dddd86df7ec0bb67b5c23))

### Features

- **ux**: Organiza menu por Livelo e Banco Inter
  ([`ec9b81d`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ec9b81d05d51c467e07857d215bdb058550def9d))

- **ux**: Reduz seletor para Livelo e Banco Inter
  ([`576e3d7`](https://github.com/lacerdaRodrigo/robo-livelo/commit/576e3d76d3f29ef11bd2ee7e7daf9ba3a4ba0e4a))

### Refactoring

- Remove seletor de areas sem uso
  ([`9d73933`](https://github.com/lacerdaRodrigo/robo-livelo/commit/9d73933f4983938430d072b03c7da5127e43c956))


## v1.23.0 (2026-08-17)

### Features

- **site**: Publica novo front responsivo e estabiliza coleta Inter
  ([`67deb39`](https://github.com/lacerdaRodrigo/robo-livelo/commit/67deb39f8c26a6eaae15ef0735d1c8be87eb591a))


## v1.22.1 (2026-08-17)

### Bug Fixes

- **inter**: Valida contrato real do catalogo V4
  ([`a6800a1`](https://github.com/lacerdaRodrigo/robo-livelo/commit/a6800a1fb86e41b3d4bd36c5752691d9b74b9f9a))


## v1.22.0 (2026-08-17)

### Bug Fixes

- **ci**: Mede cobertura apenas do nucleo puro
  ([`9d68d5a`](https://github.com/lacerdaRodrigo/robo-livelo/commit/9d68d5ae42a6a3a987cd22a7d5e83e8792940214))

### Features

- **inter**: Adiciona catalogo de produtos V4
  ([`ffd86c4`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ffd86c47eca71bf11fc7df8a1a5879dd50368476))


## v1.21.0 (2026-08-15)

### Features

- **inter**: Adiciona integração do Shopping Inter V3
  ([`25adb2e`](https://github.com/lacerdaRodrigo/robo-livelo/commit/25adb2ee37f0c42d0a78db02bba61153d08412af))


## v1.20.0 (2026-08-13)

### Features

- **site**: "Forçar atualização" vai pro menu, abaixo de Lojas
  ([`2d4b70a`](https://github.com/lacerdaRodrigo/robo-livelo/commit/2d4b70a7402cf4b61f0d6f76cbd17353ac3b2359))


## v1.19.0 (2026-08-13)

### Features

- **site**: Painel vira grade única com ordenar, igual ao mockup V4.6
  ([`0eeb93e`](https://github.com/lacerdaRodrigo/robo-livelo/commit/0eeb93efc7ae39aa798e0093cb255030d57e9efc))


## v1.18.0 (2026-08-13)

### Features

- **site**: Tabela de Lojas ganha coluna Limiar e ícone de remover (V4.6, 3/3)
  ([`9ac2578`](https://github.com/lacerdaRodrigo/robo-livelo/commit/9ac257892e04638861bebc0f490c0542685c8e2d))


## v1.17.0 (2026-08-13)

### Features

- **site**: Painel ganha hero com Top 3 Oportunidade (V4.6, 2/3)
  ([`47985d5`](https://github.com/lacerdaRodrigo/robo-livelo/commit/47985d5b700ff196cdf36c4f068f4e8d98d45e12))


## v1.16.0 (2026-08-13)

### Features

- **site**: Redesenha navegação como barra lateral (V4.6, 1/3)
  ([`8e81cb1`](https://github.com/lacerdaRodrigo/robo-livelo/commit/8e81cb1ef147c1ebe4f8ef256399006de83dfe0e))


## v1.15.3 (2026-08-13)

### Bug Fixes

- Logo do e-mail vira URL hospedada, nao base64
  ([`2fcde74`](https://github.com/lacerdaRodrigo/robo-livelo/commit/2fcde74a5a6e89cbb7dd3779858c25cc6e359c95))


## v1.15.2 (2026-08-13)

### Bug Fixes

- Cor por categoria volta a ser inline, nao custom property
  ([`c87a313`](https://github.com/lacerdaRodrigo/robo-livelo/commit/c87a313393946b0d2a77e1bfd32771b6ff7a53cb))


## v1.15.1 (2026-08-13)

### Bug Fixes

- Move o <style> do e-mail para dentro de <head>
  ([`6f0f5bc`](https://github.com/lacerdaRodrigo/robo-livelo/commit/6f0f5bc7cd130e11803831129fad03d73248be16))


## v1.15.0 (2026-08-13)

### Features

- Redesenha o e-mail e cria a marca "Pontuação Livelo"
  ([`5d34517`](https://github.com/lacerdaRodrigo/robo-livelo/commit/5d34517b2ccb0c9c5b25fff5e73262e65391da12))


## v1.14.0 (2026-08-13)

### Documentation

- Confirma conferência visual do e-mail real (RN22/RN23/C05)
  ([`ed962bd`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ed962bd62236c3b35e37086a7bfeae1f4ceb92c4))

- Confirma verificação do site publicado, destrava V2.4
  ([`93fecc6`](https://github.com/lacerdaRodrigo/robo-livelo/commit/93fecc62b6dc6a903474e35479e14bb03a8d477d))

- Marca filtro do Gmail de e-mail sem promoção como feito
  ([`2fe42bf`](https://github.com/lacerdaRodrigo/robo-livelo/commit/2fe42bf2b54dda80ce9f480acfd6695a1164c4a8))

- Marca senha de app do Gmail como revogada e secret atualizado
  ([`f854106`](https://github.com/lacerdaRodrigo/robo-livelo/commit/f8541060045acfc44e74925b01e6d91250a3ccb8))

- Marca senha do Neon rotacionada e GITHUB_TOKEN_DISPARO confirmado
  ([`f34d99b`](https://github.com/lacerdaRodrigo/robo-livelo/commit/f34d99b250cb1ee5eedfc23c807aac50af183bf0))

### Features

- Dispara robo em silencio quando o site pede atualizacao
  ([`ea7a2b5`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ea7a2b5644a451b618ce35dc4263277db704b610))


## v1.13.1 (2026-08-13)

### Bug Fixes

- **site**: Inverte logica do toggle de aviso opcional e remove apelidos do cadastro
  ([`2d30e54`](https://github.com/lacerdaRodrigo/robo-livelo/commit/2d30e54c84734c3613b91f3cbae3284a969f1ed5))


## v1.13.0 (2026-08-12)

### Features

- **site**: Permite esconder a tela de Alertas inteira em /configuracoes
  ([`886f827`](https://github.com/lacerdaRodrigo/robo-livelo/commit/886f827c02abee94e8ba7cd32632076e088c169c))


## v1.12.1 (2026-08-12)

### Bug Fixes

- **site**: Protege pontuacoes() contra falha do banco no Painel
  ([`e8dacc2`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e8dacc200fa5812a915fdbcf2bec7cdaf3523788))


## v1.12.0 (2026-08-12)

### Bug Fixes

- Corrige formatação da docstring que quebrava o ruff format
  ([`e92fa0d`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e92fa0d68a6d3e114e09b0eab475ebafebe4e57b))

### Features

- Exibe a letra miúda da campanha no Painel (RN31)
  ([`45fc221`](https://github.com/lacerdaRodrigo/robo-livelo/commit/45fc22186ab499b26b6a11de79a17c8810e6dce2))


## v1.11.0 (2026-08-12)

### Features

- **site**: Esconde o aviso opcional no cadastro atrás de uma flag em /configuracoes (V2.3.4)
  ([`ef366f5`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ef366f541235703f71d0c259021aeaceba7bdc01))

### Refactoring

- **site**: Flag do aviso opcional vira cookie, não banco
  ([`66a2526`](https://github.com/lacerdaRodrigo/robo-livelo/commit/66a25266868c1f08ab6f35d54053605ca999c3b7))


## v1.10.1 (2026-08-12)

### Bug Fixes

- **site**: Move o botão de forçar atualização para o fim de /lojas e adiciona tema claro/escuro
  ([`5194cd6`](https://github.com/lacerdaRodrigo/robo-livelo/commit/5194cd6ffc8099262aa44393ca549bfb5ad80caa))


## v1.10.0 (2026-08-12)

### Features

- **site**: Redesenho visual V2.3.3 — cartões em grade, barra de progresso, cabeçalho fixo
  ([`ca2fdbe`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ca2fdbed7bc232d0569eb820e12e3fb74211e662))


## v1.9.0 (2026-08-12)

### Documentation

- Atualiza CLAUDE.md, README e PENDENCIAS pro estado real (V2.3 fechada, v1.8.0)
  ([`a29518b`](https://github.com/lacerdaRodrigo/robo-livelo/commit/a29518b000dd355bd38bf57ebcd592fa22d0a09f))

### Features

- **site**: Aviso opcional já no cadastro de loja
  ([`8866d90`](https://github.com/lacerdaRodrigo/robo-livelo/commit/8866d900d083f182c5bf3a40231878eafa76c7f5))


## v1.8.0 (2026-08-12)

### Features

- Banco vazio vale, e o site pode disparar o robo
  ([`ef8395a`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ef8395aebfcdbce4d2eb7340600da70facb25824))


## v1.7.0 (2026-08-12)

### Features

- **site**: Uma tela por tarefa, linguagem de gente e ajuda embutida
  ([`53b72db`](https://github.com/lacerdaRodrigo/robo-livelo/commit/53b72db0d1d08b94120b05c8d04a2ed8bda39534))


## v1.6.1 (2026-08-12)

### Bug Fixes

- CSP com nonce — a politica anterior apagava a pagina no navegador
  ([`68e15c7`](https://github.com/lacerdaRodrigo/robo-livelo/commit/68e15c7c052e1ca38cea19b8524f184455ef9cfb))

### Documentation

- Root Directory da Vercel e a armadilha do Redeploy
  ([`ea71978`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ea719789c2285e3bd7021bc8b835fc1597d089bf))


## v1.6.0 (2026-08-12)

### Features

- Site publico com edicao protegida (V2.3, metade 2)
  ([`2f15a01`](https://github.com/lacerdaRodrigo/robo-livelo/commit/2f15a018bc954b8973680ae3c66bd501afd14c6c))


## v1.5.0 (2026-08-12)

### Features

- Robo grava o retrato de cada execucao (V2.3, metade 1)
  ([`103863a`](https://github.com/lacerdaRodrigo/robo-livelo/commit/103863a481fca1490fb53854bdca18d9d3721baa))


## v1.4.0 (2026-08-12)

### Documentation

- DATABASE_URL cadastrada, V2.1 no ar
  ([`5b16dda`](https://github.com/lacerdaRodrigo/robo-livelo/commit/5b16dda88aa41b6ef0857a0a354ffa508b0ffedc))

### Features

- V2.2 - alerta por multiplo da base, nao pela etiqueta da Livelo
  ([`23eb3e7`](https://github.com/lacerdaRodrigo/robo-livelo/commit/23eb3e71e46fd38a72e523d67e668dfae9a90b4f))


## v1.3.0 (2026-08-12)

### Build System

- **deps**: Bump actions/checkout from 4 to 7
  ([`c6a0169`](https://github.com/lacerdaRodrigo/robo-livelo/commit/c6a0169e258d8c2e21526fa924af30ffccd36f49))

- **deps**: Bump actions/setup-python from 5 to 7
  ([`b94eed0`](https://github.com/lacerdaRodrigo/robo-livelo/commit/b94eed0a08d6372e7ba64e27f7b3f850461f22ec))

### Chores

- MS3 falha de hora em hora, nao a cada 5 minutos
  ([`094c0ae`](https://github.com/lacerdaRodrigo/robo-livelo/commit/094c0ae51d9a612e1c7368472bc7e031ac371120))

- Workflow temporario que falha de proposito para validar MS3
  ([`db80db0`](https://github.com/lacerdaRodrigo/robo-livelo/commit/db80db0d7e43bfb40d94039b01e4927312e74560))

### Code Style

- Quebra o CT-105 em variaveis para o ruff format aceitar
  ([`4e1655c`](https://github.com/lacerdaRodrigo/robo-livelo/commit/4e1655c276e6aa426c78e1dd4e5b04261b27c76a))

### Documentation

- Registra o run da falha proposital e a cadencia horaria do MS3
  ([`fe0423a`](https://github.com/lacerdaRodrigo/robo-livelo/commit/fe0423aaf8521110d5796c5e6db9582080e66b83))

### Features

- V2.1 - catalogo do banco com o arquivo de reserva, e RN23 com dois rotulos
  ([`e226fbc`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e226fbc7ef7e5848e2d1dfa4d6983e00815a4743))


## v1.2.0 (2026-08-11)

### Bug Fixes

- Dispara diagnostico por push, nao workflow_dispatch
  ([`e0744ab`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e0744ab4632a799220284f0d89b348ec1e9b40d2))

### Chores

- Diagnostico busca a lista completa de parceiros na arvore
  ([`af8ccfb`](https://github.com/lacerdaRodrigo/robo-livelo/commit/af8ccfb6eea1c8e9c6a1d26b94ad01ec5ba8d46d))

- Diagnostico inspeciona partnerList do componente de listagem
  ([`ffa7e73`](https://github.com/lacerdaRodrigo/robo-livelo/commit/ffa7e734ad356220617b1e66c58e1a1b4e425ad9))

- Diagnostico investiga onde vive a grade completa de parceiros
  ([`f3b8aba`](https://github.com/lacerdaRodrigo/robo-livelo/commit/f3b8abadf44c48d04aa994db56d5578dfad5ea5f))

- Remove workflow temporario de diagnostico do payload
  ([`faf316e`](https://github.com/lacerdaRodrigo/robo-livelo/commit/faf316ef616984f16f2941ba2ace8c37c51ceb5f))

- Workflow temporario para inspecionar o payload JSON da Livelo
  ([`3d850d3`](https://github.com/lacerdaRodrigo/robo-livelo/commit/3d850d30e796162620dd1dc026b57dc50642ef20))

### Documentation

- Lista de pendencias por fase
  ([`fc24426`](https://github.com/lacerdaRodrigo/robo-livelo/commit/fc2442657c58e59e0bd0d88046cda64b57e76a5c))

- Varredura de consistencia da documentacao V2
  ([`bdbe282`](https://github.com/lacerdaRodrigo/robo-livelo/commit/bdbe2829f7a6ae3a9e86f1c5f5a77c73949d37f4))

### Features

- V2.0 - extrator le o payload JSON da pagina (RF14)
  ([`245d917`](https://github.com/lacerdaRodrigo/robo-livelo/commit/245d9178ba9c0596e3542e6fda327b51d68d7fc3))


## v1.1.0 (2026-08-10)

### Features

- Catalogo de lojas no Postgres (Neon)
  ([`9fa7b91`](https://github.com/lacerdaRodrigo/robo-livelo/commit/9fa7b91390f5e30e98eae40dcb1a9a1ac1bb3db2))


## v1.0.0 (2026-08-10)

- Initial Release
