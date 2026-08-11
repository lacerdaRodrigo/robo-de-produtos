# Contexto para agentes de IA

Leia o [`PRD.md`](docs/PRD.md) antes de propor qualquer mudança. Ele é a fonte da verdade: requisitos (RF), requisitos não-funcionais (RNF), restrições (C) e regras de negócio (RN) são todos numerados e referenciados entre si e sempre atualizar as docs , se mudar alguma regra , teste e etc.

## O que é este projeto

Robô que lê a página pública de parceiros da Livelo, filtra as lojas favoritas do autor e envia um e-mail com as que estão com pontuação turbinada. Roda 3x ao dia no GitHub Actions. Sem servidor, sem banco de dados, sem front-end.

## Regras de ouro

1. **O núcleo não faz I/O.** `modelos.py`, `extrator.py`, `categorias.py` e `montador_email.py` não podem importar `requests`, `smtplib`, `tomllib`, `os` nem `pathlib`. Existe um teste que falha se isso acontecer (CT-074). `beautifulsoup4` é permitido: transforma texto em estrutura, não abre conexão nem arquivo.
2. **O mundo entra por contrato.** Três portas em `portas.py`: `FonteDePagina`, `Notificador`, `CatalogoFavoritas`. Nada de acesso externo fora dos adaptadores.
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

A V1.0 está em produção (§11.1 do PRD). A V2 está planejada em [`docs/PRD-V2.md`](docs/PRD-V2.md) e parcialmente iniciada: o banco no Neon existe e está populado (V2.1), mas o robô ainda lê do TOML — a troca de adaptador ainda não foi feita.

A ordem do que falta, e por quê essa ordem importa, está em [`docs/PENDENCIAS.md`](docs/PENDENCIAS.md). Hoje isso começa pela V2.0 (extrator lendo o payload JSON): é a base de que as demais fases da V2 dependem. Não pule fase nem construa algo de uma fase posterior antes do gatilho dela ter acontecido.
