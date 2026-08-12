# CHANGELOG

<!-- version list -->

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
