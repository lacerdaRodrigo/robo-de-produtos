# CHANGELOG

<!-- version list -->

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
