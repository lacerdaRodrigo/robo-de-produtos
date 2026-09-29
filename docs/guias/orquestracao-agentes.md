# Orquestração de agentes Codex

## Objetivo

O agente principal é o gerente da tarefa: mantém a conversa com o responsável,
entende o resultado desejado, distribui partes independentes, acompanha os
subagentes e responde com uma conclusão integrada. As regras do projeto e o
escopo autorizado continuam valendo para todos os agentes.

Os agentes são threads do Codex que podem ser inspecionadas pela interface ou
pelo comando `/agent` no CLI interativo. Não são processos de terminal separados
nem ficam trabalhando depois que a execução termina.

## Papéis disponíveis

| Perfil | Uso | Acesso de escrita |
|---|---|---|
| `investigador` | Rastrear comportamento, código, configuração, logs e histórico antes de decidir uma correção. | Somente leitura |
| `planejador` | Transformar o pedido original e as evidências da investigação em um plano executável, com aceite e validação. | Somente leitura |
| `clarificador` | Resolver dúvidas consultando o pedido, as regras e as decisões registradas; separar o que exige resposta do responsável. | Somente leitura |
| `designer_flutter` | Implementar uma tela ou estado Flutter Android/iOS conforme HTML e regras V15. | Escrita no workspace, limitada à tarefa |
| `implementador` | Corrigir um problema de código com escopo e critérios definidos. | Escrita no workspace, limitada à tarefa |
| `revisor_ci` | Revisar diff e evidências de GitHub Actions disponíveis na sessão. | Somente leitura |

Os perfis ficam em `.codex/agents/`. Eles herdam as skills e os MCPs da sessão
quando configurados e autorizados; a configuração não cria conexão nem concede
acesso a sistemas externos. Para Flutter, use as versões das skills em
`.agents/skills/`, que seguem o contrato V15 deste projeto.

## Fluxo de trabalho

1. O gerente resume o resultado esperado e os critérios de aceite, consulta
   `AGENTS.md` e começa por `docs/README.md` para localizar a documentação
   necessária.
2. Antes de editar, registra o estado existente com `git status` e separa
   mudanças preexistentes da tarefa atual.
3. Se a causa não estiver clara, delega o rastreamento ao `investigador`. Análise
   de CI ou outras leituras independentes podem ocorrer em paralelo.
4. Em tarefas com várias etapas, entrega ao `planejador` o pedido original junto
   das evidências do investigador. O plano deve definir objetivo, escopo,
   critérios de aceite verificáveis, arquivos/áreas envolvidas, ordem das etapas,
   dependências, validação/documentação e riscos. Deve separar fatos de hipóteses
   e apontar decisões realmente bloqueantes. O planejador não edita código.
5. O gerente confere que o plano atende ao pedido e às regras do projeto. Se
   houver dúvidas, consulta o `clarificador` antes de perguntar ao responsável.
   Ele verifica o pedido original, as instruções, a documentação de domínio e as
   decisões já registradas. Questões factuais respondidas por essas fontes são
   resolvidas sem interromper o responsável.
6. Para decisões simples, reversíveis e sem risco material, usa o padrão
   conservador registrado e declara a premissa. Não deduz autorização, preferência
   pessoal ou aceite de risco. Se escopo, produção, segurança, dinheiro ou perda
   de dados dependerem de uma resposta não documentada, o gerente faz uma
   pergunta curta e específica, junto da recomendação do clarificador e sua
   justificativa, e informa que seguirá essa recomendação após 30 segundos sem
   resposta.
7. Durante a janela de 30 segundos, continua as partes independentes. Se o
   responsável responder no prazo, usa a resposta; se não, segue a recomendação,
   registra a premissa e não pergunta de novo. O `clarificador` agrupa dúvidas
   relacionadas e sugere a melhor opção, mas não fala diretamente com o
   responsável. A falta de resposta não amplia o escopo nem autoriza push, deploy,
   publicação ou outra operação externa não solicitada.
   Se nenhuma opção segura couber no escopo autorizado, deixa pendente somente a
   etapa dependente e explica o impedimento.
8. Com as dúvidas resolvidas, encaminha a execução ao `designer_flutter` ou ao
   `implementador` sem criar uma etapa extra de aprovação quando o pedido já
   autorizou o trabalho. Mantém um único agente alterando cada conjunto de
   arquivos por vez; depois integra as mudanças, examina o diff e delega a revisão
   ao `revisor_ci`.
9. Executa somente a validação autorizada e diretamente relacionada. Em tarefas
   Flutter, aplica os gates e limites de teste de `AGENTS.md`.
10. A resposta final lista arquivos alterados, comandos e resultados, estado de CI
   comprovado e divergências ou bloqueios restantes.

## Registro de preferências

Preferências duráveis dadas pelo responsável devem ser registradas nesta seção
ou na documentação específica do domínio, em termos curtos e aplicáveis. Use-as
em tarefas futuras quando forem pertinentes. A conversa e os agentes não
transformam uma inferência em autorização; atualize o registro quando o
responsável corrigir uma premissa.

- Em dúvidas simples, reversíveis e sem risco material, escolha o caminho
  conservador mais adequado, registre a premissa e continue o trabalho.
- Quando uma dúvida exigir a opinião do responsável, faça uma pergunta com a
  recomendação e o motivo. Dê 30 segundos para resposta e continue o trabalho
  independente durante esse período.
- Sem resposta após 30 segundos, siga a recomendação dentro do escopo autorizado,
  registre a premissa e não repita a pergunta. Isso não autoriza uma operação
  externa que não tenha sido solicitada.
- Se não houver caminho seguro dentro do escopo, deixe pendente somente a etapa
  dependente; não paralise o restante da tarefa.

## Git, CI e autonomia

- Preserve alterações que já estavam no workspace. Nunca use reset, checkout ou
  staging amplo para limpar o estado de outra tarefa.
- `designer_flutter` e `implementador` devem editar os arquivos atribuídos; não
  devem parar em recomendações quando o gerente delegou implementação. Os agentes
  de investigação, planejamento, clarificação e revisão continuam somente leitura.
- Quando o responsável solicitar publicação, o gerente cria uma branch da tarefa,
  roda os gates aplicáveis e revisa o diff. Faz commit somente dos arquivos da
  tarefa, publica a branch para executar CI e integra em `main` somente depois de
  todos os gates obrigatórios passarem. Confere também o CI do commit integrado.
  Se um gate falhar ou houver alteração preexistente inseparável, interrompe a
  publicação e informa a evidência. Não contorna proteções do repositório.
- Push, merge, publicação, deploy, dispatch ou reexecução de workflow exigem
  instrução explícita. A consulta de CI é somente leitura.
- Só declare GitHub Actions aprovado quando houver um run identificado e seu
  resultado corresponder ao commit em questão. Diferencie execução agendada de
  execução manual e sinalize quando a conexão ou os registros não estiverem
  disponíveis.
- Perfis de agente não criam uma rotina permanente. Uma tarefa local agendada é
  uma configuração separada do Codex desktop e, para acessar este repositório,
  depende do computador ligado, do aplicativo desktop aberto e de uma instrução
  agendada configurada e revisada.
