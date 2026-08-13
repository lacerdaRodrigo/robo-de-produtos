# Contexto para agentes de IA

Leia o [`PRD.md`](docs/PRD.md) antes de propor qualquer mudança. Ele é a fonte da verdade: requisitos (RF), requisitos não-funcionais (RNF), restrições (C) e regras de negócio (RN) são todos numerados e referenciados entre si e sempre atualizar as docs , se mudar alguma regra , teste e etc.

## O que é este projeto

Robô que lê a página pública de parceiros da Livelo, filtra as lojas favoritas do autor e envia um e-mail com as que estão com pontuação turbinada. Roda 3x ao dia no GitHub Actions. Desde a V2.1 tem um Postgres (Neon) como catálogo principal (TOML como reserva) e desde a V2.3 grava o retrato de cada execução nesse banco; um site em Next.js (`site/`) lê esses dados publicamente e permite editar o catálogo por senha única, inclusive disparando o robô manualmente.

## Regras de ouro

1. **O núcleo não faz I/O.** `modelos.py`, `extrator.py`, `categorias.py`, `alertas.py`, `retrato.py` e `montador_email.py` não podem importar `requests`, `smtplib`, `tomllib`, `os` nem `pathlib`. Existe um teste que falha se isso acontecer (CT-074). `beautifulsoup4` é permitido: transforma texto em estrutura, não abre conexão nem arquivo.
2. **O mundo entra por contrato.** Cinco portas em `portas.py`: `FonteDePagina`, `Notificador`, `CatalogoFavoritas`, `PreferenciasGlobais` e `RepositorioDeExecucao`. Nada de acesso externo fora dos adaptadores.
3. **Todo dado vindo do site é hostil.** Escapar antes de renderizar (RN07) e validar o domínio do link antes de colocá-lo no e-mail (§9.2).
4. **Falha nunca é silenciosa.** Erro encerra com código de saída diferente de zero (RNF06). "Sem promoção" e "robô quebrado" precisam ser distinguíveis (RN13).

## Nunca faça

| Proibição | Por quê |
|---|---|
| Autenticar na Livelo | O projeto só lê página pública. Não existe credencial da Livelo aqui |
| Qualquer técnica de evasão de bloqueio | Rotação de proxy, CAPTCHA, disfarce de User-Agent. Se bloquear, o projeto para (§10.1) |
| Imprimir segredo em log | O log do Actions é público. Nada de configuração completa, `smtplib` em modo debug ou traceback com credencial (§9.1) |
| Dar permissão de escrita ao workflow | `permissions: contents: read` é obrigatório (§9.4) |
| Visitar a página individual de cada parceiro | Multiplicaria as requisições por ~40. Uma requisição por execução (RNF02) |
| Guardar estado entre execuções | O robô é stateless por decisão (§1.4) |
| Usar `float` para pontuação | `Decimal`, sempre. `float` produz `2.9000000000000004` no e-mail (§5.4) |
| Reconhecer loja por substring | Match exato contra nome canônico ou apelido cadastrado (RN04) |

## Convenções

- **Português do Brasil** em código, nomes de variáveis, testes e documentação. Exceções: o que a ferramenta exige (`src/`, `__init__.py`, `conftest.py`, `pyproject.toml`) e nomes de bibliotecas de terceiros.
- Testes usam prefixo `teste_` em vez de `test_`, configurado no `pyproject.toml`.
- Testes de orquestração usam **fakes das portas**, não `mock.patch` sobre bibliotecas.
- Estrutura de pastas plana. Ver §4.4 do PRD antes de criar diretório novo.

## Ao mudar uma regra

Regras de negócio são numeradas e citadas em várias seções. Mudar uma exige varredura de consistência: PRD, `docs/TESTES.md` e `README.md`. Uma decisão que contradiz outra seção é bug de documentação, não detalhe.

## Antes de escrever código

A V1.0 está em produção (§11.1 do PRD). A V2.0 está em produção e **validada contra a página real** (2026-08-11): o extrator lê o payload `__NEXT_DATA__` (RF14), `Parceiro` tem `pontos_base`/`inicio_promocao`/`fim_promocao`/`campanha`, e o e-mail mostra validade (RN22) e distingue `CLUB` de `PROMOTION_CLUB` (RN23). A V2.1 está no ar desde 2026-08-11: o `DATABASE_URL` foi cadastrado, `montar_catalogo()` lê o Postgres com o TOML como reserva, e em produção o catálogo já vem do banco (132 lojas, 10 categorias, batendo com o arquivo).

A V2.2 está implementada: `alertas.py` decide o alerta por RN27 (múltiplo da base com piso) em vez da etiqueta da Livelo, com régua vinda da tabela `preferencia` (RN28) e suspeita de C07 sem guardar estado (RN29, ver PRD-V2 §6.3). O e-mail continua diário de propósito — cortar isso é RF16, da V2.4, e essa calibragem (ver `docs/PENDENCIAS.md`) ainda está em andamento.

A V2.3 está **fechada nas duas metades**: o robô grava o retrato de cada execução no banco (`retrato.py`, porta `RepositorioDeExecucao`, migração `002`), e o site Next.js em `site/` já lê isso — publicado na Vercel, com leitura pública, edição protegida por senha única e RN24/RN25/RN26/RN30 atendidas. O robô continua sem ler de volta o que grava: nenhuma decisão de alerta consulta o passado, então "stateless" segue valendo onde importa. A V2.3.1 (redesenho de informação: uma tela por tarefa), a V2.3.2 ("banco manda, e o site dispara": banco vazio agora vale de verdade, e o botão **Forçar atualização** do site dispara o `robo.yml`), a V2.3.3 (redesenho visual: cartões em grade com barra de progresso por loja, cabeçalho fixo com desfoque, menu renomeado — Painel/Alertas/Lojas/Ajuda, tema claro/escuro) e a V2.3.4 (flags de funcionalidade em `/configuracoes`, como interruptores onde ligado sempre esconde algo: o campo de aviso opcional no cadastro de loja pode ser escondido do formulário de Adicionar loja, e a tela de Alertas inteira pode ser escondida do menu/rodapé/Painel e da rota `/avisos` — as duas desligadas por padrão, então por padrão ambas ficam visíveis) também estão feitas. O Painel também mostra a letra miúda da campanha da Livelo (`legalTerms`) quando ela existe, para decidir se a promoção serve sem abrir o app.

A V2.3.2 está fechada: `robo.yml` ganhou o input `enviar_email` do `workflow_dispatch` (padrão `true`), o disparo manual do site manda `enviar_email: "false"` e `verificar_promocoes` pula só o notificador — o retrato continua gravado igual, o agendado continua mandando e-mail sempre. `GITHUB_TOKEN_DISPARO` está cadastrado na Vercel. A V2.4 (e-mail condicional, RF16) está **destravada** desde que o autor verificou o site publicado em 2026-08-13, mas ainda não começou — é regra de negócio diferente de `enviar_email`: RF16 decide por ter promoção ou não, `enviar_email` decide por quem pediu a execução.

O e-mail foi redesenhado em 2026-08-13 (bloco de cor sólida por oferta, descrição de campanha expansível sem JavaScript, marca "Pontuação Livelo" no topo e no rodapé) e o site ganhou logo própria no cabeçalho, rodapé e título do navegador — raciocínio completo, incluindo o orçamento de bytes contra o corte do Gmail (C05) e como regenerar os PNGs, em [`docs/EMAIL.md`](docs/EMAIL.md).

A ordem do que falta, e por quê essa ordem importa, está em [`docs/PENDENCIAS.md`](docs/PENDENCIAS.md). Não pule fase nem construa algo de uma fase posterior antes do gatilho dela ter acontecido.
