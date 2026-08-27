# Contexto para agentes de IA

Leia primeiro o [`docs/prd/PRD-LIVELO.md`](docs/prd/PRD-LIVELO.md). Ele é a
fonte atual das regras numeradas. Consulte o delta do domínio afetado e
[`docs/PENDENCIAS.md`](docs/PENDENCIAS.md) para separar código local, publicado,
pendente e histórico.

## Regra zero — execução automática

Antes de alterar código, documentação, workflow, teste ou configuração:

1. entenda a tarefa por leitura e diagnóstico sem mudanças;
2. escolha modelo e esforço adequados;
3. informe a escolha e o motivo em uma frase;
4. faça a menor mudança coerente e valide sem aguardar confirmação manual.

Implementação autorizada cobre edições, testes e documentação diretamente
relacionados. Não cobre publicação, migração de produção, envio real, remoção de
legado fora do escopo ou outra ação externa relevante. O roteiro de escolha fica
em [`docs/guias/ROTEAMENTO_MODELOS_CODEX.md`](docs/guias/ROTEAMENTO_MODELOS_CODEX.md).

## Protótipo antes de mudança visível

Nova tela, jornada, funcionalidade visível ou mudança relevante de navegação
passa primeiro por `design-app/prototipo-web.html` e
`design-app/prototipo-mobile.html`, recebe aprovação visual, atualiza contratos
necessários e só então entra no Flutter/API. Correção interna sem efeito visual
não exige protótipo novo.

## O que é este projeto

Radar pessoal de benefícios com três integrações isoladas:

- Livelo: coleta lojas favoritas, calcula alertas e grava retratos.
- Inter Sites parceiros: coleta cashback das lojas escolhidas.
- Inter Compre direto: coleta todos os produtos expostos pelas lojas escolhidas,
  com busca no Postgres e histórico de 30 dias.

Os robôs Python rodam no GitHub Actions e gravam no Neon. A API Next.js em
`backend/api/` autentica e entrega dados paginados. Um único Flutter em `app/`
atende Web, Android e iOS. A antiga interface `site/` foi removida; a API está
ativa e não é um site substituto.

## Decisão Livelo vigente

O canal SMTP/Gmail de alertas foi retirado em 27 de agosto de 2026 por decisão do
responsável. Não existem `montador_email.py`, `Notificador`, `Mensagem`, segredo
Gmail ou parâmetro `enviar_email` no fluxo atual. Não reintroduza esse canal por
inferência de documentos históricos. E-mails de autenticação do Firebase são
outro assunto e permanecem no app.

Sem o canal antigo, persistir o retrato é o produto da coleta Livelo: se o
Postgres configurado falhar, a execução precisa falhar. `RepositorioNulo` existe
somente para diagnóstico local sem `DATABASE_URL`.

## Regras de ouro

1. **O núcleo não faz I/O.** Domínio recebe dados e devolve dados; rede, arquivo,
   relógio, ambiente e banco entram na orquestração ou nos adaptadores.
2. **O mundo entra por contrato.** Livelo, Inter Sites e Inter Produtos mantêm
   portas e adaptadores próprios.
3. **Dado externo é hostil.** Validar, escapar e nunca executar texto/HTML vindo
   da Livelo ou do Inter. Link Livelo só é persistido para domínio permitido.
4. **Falha nunca é silenciosa.** Distinguir falha, parcial, atrasado, ausente e zero.
5. **Uma coleta, vários consumidores.** Robôs gravam uma vez; API, Flutter e
   futuras integrações leem o Postgres.
6. **Cliente não recebe segredo.** Nada de `DATABASE_URL`, Firebase Admin ou token
   GitHub em Flutter Web, APK ou IPA.
7. **Financeiro não usa ponto flutuante.** Python usa `Decimal`, banco usa
   `NUMERIC` e contratos transportam texto seguro quando necessário.

## Nunca faça

| Proibição | Motivo |
|---|---|
| Autenticar na Livelo ou no Banco Inter | O projeto lê somente fontes públicas |
| Usar proxy rotativo, CAPTCHA, disfarce ou evasão | Se houver bloqueio deliberado, o coletor para |
| Imprimir segredo em log | Actions e diagnósticos podem ser expostos |
| Dar escrita no repositório ao workflow de coleta | Coletores usam `contents: read` |
| Fazer o Flutter acessar Neon, Actions, Livelo ou Inter | O cliente fala apenas com a API |
| Buscar na fonte enquanto o usuário digita | Pesquisa consulta somente o Postgres |
| Cortar paginação silenciosamente | Todo resultado encontrado continua alcançável |
| Reconhecer loja por substring | Nome canônico/apelido usa correspondência exata |
| Usar histórico para decidir alerta Livelo | A decisão atual é stateless |

## Estado técnico verificado em 27 de agosto de 2026

- API reconstruída em `backend/api/`, com TypeScript, ESLint, Vitest e build.
- CI local inclui robô, API e Flutter; execução remota depende do envio da branch.
- Filtro residual de `loja.favorita` foi removido porque a tabela `loja` já é o catálogo.
- Workflow de versão teve os caminhos corrigidos; a próxima release real ainda
  precisa provar a sincronização entre pacote, `__version__` e changelog.
- Flutter usa versão 3.44.1 no CI. Web e Android foram compilados na auditoria;
  iOS exige macOS/Xcode.
- Migrações `009` e `012` ainda aparecem como ação operacional pendente; `011`
  permanece adiada.
- Nenhuma mudança local deve ser descrita como publicada sem evidência do GitHub/Vercel.

## Convenções e testes

- Português do Brasil em código, testes e documentação, salvo nomes exigidos por ferramenta.
- Pytest usa prefixo `teste_`, conforme `backend/robo/pyproject.toml`.
- Testes de orquestração usam fakes das portas; nenhum teste toca fonte real,
  Neon de produção, FCM real ou serviço real de autenticação.
- Trabalhe em lote. No fechamento, rode os gates relevantes uma vez; se falhar,
  corrija o necessário e confirme novamente.
- Mudança de regra numerada exige varredura em PRDs, `docs/TESTES.md`, README e testes.
- Estrutura `features` do Flutter é exceção deliberada; não reorganize o Python por ela.

## Produtos Inter

- Percorrer todas as páginas expostas por cada loja escolhida; não há teto de
  3.000 ou 3.310 produtos.
- Identidade histórica é loja + ID externo. Não mesclar por título semelhante.
- Publicação é atômica e mantém o último catálogo válido diante de coleta inválida.
- A API filtra e pagina no servidor: 20 itens por padrão, máximo de 50.
- O sistema promete o que a fonte expôs numa coleta válida, não o catálogo
  universal da varejista.

A ordem atual do trabalho está em [`docs/PENDENCIAS.md`](docs/PENDENCIAS.md).
