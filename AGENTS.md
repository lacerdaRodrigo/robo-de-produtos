# Instruções para o Codex

**Escopo:** todo o repositório `robo-livelo`.

Este é o arquivo de entrada do Codex. Ele não substitui a documentação do produto. Antes de propor ou executar trabalho, siga a ordem abaixo.

## 1. Leitura obrigatória

1. Leia o [`CLAUDE.md`](CLAUDE.md) inteiro. As regras dele também valem para o Codex.
2. Leia o [`docs/prd/PRD-LIVELO.md`](docs/prd/PRD-LIVELO.md), fonte principal de requisitos e regras numeradas.
3. Leia somente os deltas relacionados à tarefa:
   - [`docs/PRD-LIVELO-V2.md`](docs/PRD-LIVELO-V2.md): site, banco, autenticação e alertas Livelo;
   - [`docs/PRD-INTER-CASHBACK.md`](docs/PRD-INTER-CASHBACK.md): cashback dos Sites parceiros do Inter;
   - [`docs/PRD-INTER-PRODUTOS.md`](docs/PRD-INTER-PRODUTOS.md): produtos do Compre direto, coleta, busca e histórico;
   - [`docs/PRD-ADMINISTRACAO.md`](docs/PRD-ADMINISTRACAO.md): limpeza administrativa e zona de perigo;
   - [`app/PLANO.md`](app/PLANO.md): piloto Flutter Web, Android e iOS.
4. Consulte [`docs/PENDENCIAS.md`](docs/PENDENCIAS.md) e o código/branch atuais para separar o que está implementado, publicado, pendente ou apenas planejado.
5. Ao mexer em regra ou teste, consulte também [`docs/TESTES.md`](docs/TESTES.md), [`README.md`](README.md) e a documentação específica afetada.

Nunca trate plano como código pronto nem memória de conversa como prova do estado do repositório. Confira arquivos, commits e testes. Se não houver evidência, diga que é hipótese ou sugestão.

## 2. Regra zero para execução automática

Antes de alterar código, documentação, workflow, teste ou configuração:

1. entenda a tarefa por leitura e diagnóstico sem mudanças;
2. escolha automaticamente o modelo e o nível de esforço adequados;
3. informe a escolha e o motivo em uma frase simples;
4. execute a menor mudança coerente e as validações relevantes, sem aguardar confirmação manual.

Se o escopo mudar materialmente, faça uma nova classificação. Um pedido de implementação autoriza as edições, os testes e a documentação diretamente relacionados, mas não autoriza publicar, migrar banco de produção, apagar o legado, enviar notificações reais ou realizar outra ação externa relevante.

## 3. Como conversar com o responsável

- Use português do Brasil e linguagem direta, adequada a quem ainda está aprendendo desenvolvimento.
- Não invente requisito, estado, credencial, custo, limite ou comportamento.
- Sugestões são bem-vindas, mas devem vir separadas do que já foi aprovado.
- Antes de implementar uma sugestão opcional, explique: o que é, por que fazer, quando entra, custo/risco e alternativa simples; depois aguarde a decisão.
- Quando houver mais de uma opção relevante, apresente uma recomendação clara e os principais trade-offs.
- Informe exatamente o que foi alterado, como foi validado e o que não foi executado.

## 4. Regras técnicas que não podem regredir

- O núcleo Python não faz I/O; integrações entram por portas e adaptadores.
- Livelo, Inter Sites parceiros e Inter Compre direto continuam como domínios, processos, tabelas e workflows isolados.
- O site atual em `site/` permanece vivo até uma decisão explícita de corte.
- O Flutter é cliente da API: não acessa Neon, GitHub Actions, Livelo ou Inter diretamente.
- Os robôs gravam uma vez no Postgres e atendem o site legado, o Flutter e as notificações.
- Dinheiro, cashback e pontuação usam `Decimal`/`NUMERIC` e contratos seguros; nunca `float`/`double` para cálculo financeiro.
- Texto e links de fonte externa são hostis: validar, escapar e nunca executar como HTML.
- Nenhum segredo pode entrar em log, repositório, bundle Web, APK ou IPA.
- Não autenticar na Livelo/Inter e não usar proxy rotativo, CAPTCHA, disfarce ou técnica de evasão.
- Falha, coleta parcial, dado atrasado, ausência de dado e valor zero são estados diferentes.
- Ações administrativas são revalidadas no servidor, com autorização, auditoria, idempotência e proteção contra repetição.

## 5. Produtos, busca e histórico

- Para cada loja direta selecionada, o robô percorre todas as páginas que a fonte disponibilizar; não existe teto artificial de 3.000 ou 3.310 produtos.
- O banco mantém o último catálogo válido e medições históricas de todos os produtos ativos, conforme retenção do PRD V4.
- A pesquisa consulta somente o Postgres. Digitar no app nunca chama o Inter nem inicia uma coleta.
- O Flutter nunca recebe o catálogo completo: a API filtra no servidor e entrega páginas, inicialmente 20 itens e no máximo 50 por resposta, conforme [`app/PLANO.md`](app/PLANO.md).
- Todos os resultados encontrados continuam alcançáveis por paginação. Não cortar total silenciosamente, duplicar ou perder itens entre páginas.
- A identidade histórica é loja + ID externo do produto. Não mesclar variantes ou produtos entre lojas por semelhança textual.
- O sistema promete tudo que a fonte expôs numa coleta válida, não o catálogo universal de uma varejista.

## 6. Trabalho no `app/`

### Regra visual inegociável

Nunca invente ou improvise um design para substituir o protótipo. O protótipo
que estamos construindo juntos é a fonte visual de verdade: reproduza sua
estrutura, hierarquia, espaçamento, cores, estados e navegação antes de criar
ou alterar a interface no Flutter. Se algo não estiver definido nele, pare e
peça uma decisão; não preencha a lacuna com uma tela genérica do Material.

Protótipo mobile no workspace atual: [`prototipo-mobile.html`](/home/rodrigo/Estudos/robo/design-app/prototipo-mobile.html).

- Não inicialize Flutter, crie telas, banco, API ou workflow apenas porque existe um plano.
- Quando houver autorização para começar, siga a Fase 1 do plano: inventário e contratos antes de telas.
- Toda nova funcionalidade visível, tela, jornada ou mudança relevante de navegação deve ser desenhada primeiro nos dois protótipos de `design-app/`: [`prototipo-web.html`](design-app/prototipo-web.html) e [`prototipo-mobile.html`](design-app/prototipo-mobile.html).
- A implementação real só começa depois que o responsável validar a experiência no protótipo. Se a mudança afetar apenas uma plataforma, registre o motivo e mantenha a outra coerente.
- O protótipo não substitui requisitos nem autoriza inventar contrato, dado ou backend. Depois da aprovação visual, atualize PRD/contratos quando necessário e só então implemente com testes.
- Correção interna sem mudança visual não exige criar uma tela nova. Se uma correção alterar comportamento percebido, atualize também os protótipos para evitar divergência.
- Um único projeto Flutter deve atender Web, Android e iOS com layout adaptativo.
- Preserve os tokens e as regras de design aprovados no plano.
- Escreva muitos testes unitários e de widgets/componentes; mantenha os testes de integração nas jornadas críticas.
- A estrutura por `features` em `app/` é uma exceção deliberada à convenção plana dos módulos Python. Não reorganize o Python por causa dela.
- Itens da seção de melhorias opcionais do plano não estão autorizados automaticamente.

## 7. Alterações, testes e documentação

- Faça a menor mudança coerente com o pedido e preserve alterações do usuário.
- Toda correção de bug recebe teste de regressão quando tecnicamente possível.
- Trabalhe em lote: implemente a mudança e escreva ou ajuste os testes sem executar a suíte após cada pequena edição.
- Rode os testes relevantes no fechamento da tarefa ou antes do build previsto. Se o fechamento já incluir build, a execução que antecede o build vale como validação final; não duplique a suíte sem motivo.
- Se a validação final falhar, corrija e repita somente os testes necessários até estabilizar; depois confirme a suíte relevante uma vez.
- Não enfraqueça os gates atuais de Pytest, Ruff, Vitest, TypeScript e build do site.
- Código Flutter deve passar por análise, formatação, testes unitários/widgets e builds previstos para a fase.
- Testes não acessam fontes reais, Neon de produção, FCM real ou e-mail real.
- Ao mudar uma regra numerada, faça varredura de consistência nos PRDs, testes e README relacionados.
- Não execute migração de produção, limpeza, publicação em loja, remoção do `site/` ou envio real sem autorização explícita para essa ação.
- Se um teste não puder ser executado, registre isso claramente; nunca diga que passou sem evidência.

## 8. Definição de concluído

Uma tarefa só está concluída quando:

1. o pedido aprovado foi atendido sem ampliar silenciosamente o escopo;
2. as regras existentes foram preservadas ou a mudança foi documentada;
3. os testes relevantes passaram, ou a impossibilidade foi informada;
4. segurança, compatibilidade do site legado e dados históricos foram considerados;
5. para mudança visível, os protótipos Web e Mobile foram aprovados e continuam coerentes com a implementação;
6. o responsável recebeu um resumo simples dos arquivos, validações e decisões ainda abertas.
