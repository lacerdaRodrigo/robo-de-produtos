# Contexto para agentes de IA

> **Design mobile V11:** [`AGENTS.md`](AGENTS.md) tem precedência operacional. O ciclo trabalha somente no Flutter mobile, usa `design-app/prototipo-mobile-redesign-novo-11.html` como fonte visual e `design-app/SISTEMA-DESIGN-MOBILE-V11.md` como contrato. Não exige Web, golden, integration, E2E ou suíte completa. Referências abaixo a Web e ao antigo canal de e-mail são históricas, não instruções nem estado ativo deste ciclo.

## Pendência manual — Shopping Inter compacto

O teste `Shopping Inter compacto possui somente os dois modos reais`, em
`app/test/app/navegacao/moldura_test.dart`, está isolado em um bloco comentado. A pipeline
registrou 193 testes aprovados e uma falha porque, após deixar de acompanhar a
loja, o teste esperava encontrar a ação `Acompanhar` e ela não estava na árvore
de widgets. O comportamento visual será conferido manualmente pelo responsável.

Até essa decisão, não remover o comentário, não mudar a expectativa e não alterar a
interface apenas para fazer esse cenário passar. Depois da validação manual,
registrar o comportamento aprovado, corrigir implementação ou teste conforme a
decisão e reativar o cenário.

Leia o [`PRD-LIVELO.md`](docs/prd/PRD-LIVELO.md) antes de propor qualquer mudança. Ele é a fonte da verdade: requisitos (RF), requisitos não-funcionais (RNF), restrições (C) e regras de negócio (RN) são todos numerados e referenciados entre si e sempre atualizar as docs , se mudar alguma regra , teste e etc.

## Regra zero — execução automática

Antes de qualquer alteração em código, documentação, workflow, teste, configuração ou até espaço/ponto-e-vírgula, o assistente deve:

1. Entender a tarefa, usando leitura ou inspeção sem alteração quando necessário.
2. Escolher automaticamente o modelo e o nível de esforço adequados.
3. Informar a escolha e o motivo em uma frase.
4. Fazer a menor alteração coerente e executar as validações relevantes, sem aguardar confirmação manual.

Leitura, busca e diagnóstico são permitidos para classificar a tarefa, desde que não mudem arquivos. Se o escopo mudar, classifique novamente. Um pedido de implementação cobre as edições, os testes e a documentação diretamente relacionados, mas não publicação, migração de produção, exclusão, envio real ou outra ação externa relevante. A referência prática fica em [`docs/guias/ROTEAMENTO_MODELOS_CODEX.md`](docs/guias/ROTEAMENTO_MODELOS_CODEX.md).

## Regra de produto — protótipo antes da implementação

### Regra visual inegociável

Nunca invente ou improvise um design para substituir o protótipo. O protótipo
que estamos construindo juntos é a fonte visual de verdade: a implementação
deve seguir sua estrutura, hierarquia, espaçamento, cores, estados e
navegação. Quando o protótipo não definir algo, peça uma decisão em vez de
usar uma tela genérica do Material ou criar uma solução visual por conta
própria.

Protótipo mobile oficial: [`prototipo-mobile-redesign-novo-11.html`](design-app/prototipo-mobile-redesign-novo-11.html).

Contrato visual oficial: [`SISTEMA-DESIGN-MOBILE-V11.md`](design-app/SISTEMA-DESIGN-MOBILE-V11.md).

No ciclo atual, toda nova funcionalidade mobile visível, tela, jornada ou
mudança relevante de navegação passa pelo protótipo V11 e pelo sistema de
design V11. Experiências não documentadas nesses dois arquivos ficam fora
do escopo até uma decisão explícita.

Ordem obrigatória:

1. confirmar o requisito e os limites conhecidos, sem inventar backend;
2. atualizar somente o protótipo mobile com dados claramente ilustrativos;
3. apresentar o fluxo ao responsável e obter a aprovação visual;
4. atualizar PRD e contratos afetados, quando houver mudança de regra ou dado;
5. somente então implementar no Flutter/API, com testes e documentação;
6. manter o protótipo mobile sincronizado se a implementação aprovada mudar.

Correção puramente interna, sem efeito percebido na interface, não exige tela
nova. Correção que altere comportamento visível deve atualizar o protótipo.

## O que é este projeto

Radar pessoal de benefícios com três integrações. A Livelo publica catálogo, histórico e alertas persistidos; o antigo envio por e-mail não está ativo. O Shopping Inter mantém o catálogo de Sites parceiros. A V4 coleta produtos da área Compre direto somente para lojas escolhidas, com busca local e histórico de 30 dias. Os domínios permanecem separados e usam o mesmo Postgres (Neon) somente como infraestrutura.

## Regras de ouro

1. **O núcleo não faz I/O.** Os módulos de domínio da Livelo e `modelos_inter.py`, `extrator_inter.py`, `ranking_inter.py` e `retrato_inter.py` não podem importar rede, banco, arquivo nem ambiente. Existe um teste de fronteira que falha se isso acontecer (CT-074/CT-188).
2. **O mundo entra por contrato.** As portas da Livelo ficam em `portas.py`; as do Inter, em `portas_inter.py`. Nada de acesso externo fora dos adaptadores correspondentes.
3. **Todo dado vindo do site é hostil.** Escapar antes de renderizar (RN07) e validar o domínio do link antes de colocá-lo no e-mail (§9.2).
4. **Falha nunca é silenciosa.** Erro encerra com código de saída diferente de zero (RNF06). "Sem promoção" e "robô quebrado" precisam ser distinguíveis (RN13).

## Nunca faça

| Proibição | Por quê |
|---|---|
| Autenticar na Livelo ou no Banco Inter | O projeto só lê fontes públicas. Não existe credencial dessas plataformas aqui |
| Qualquer técnica de evasão de bloqueio | Rotação de proxy, CAPTCHA, disfarce de User-Agent. Se bloquear, o projeto para (§10.1) |
| Imprimir segredo em log | O log do Actions é público. Nada de configuração completa, `smtplib` em modo debug ou traceback com credencial (§9.1) |
| Dar permissão de escrita ao workflow | `permissions: contents: read` é obrigatório (§9.4) |
| Visitar a página individual de cada parceiro ou produto | Multiplicaria as requisições. A V4 pagina listagens das lojas escolhidas, mas não abre milhares de detalhes (PRD-V4 §3.2) |
| Usar histórico para decidir alerta da Livelo | O alerta Livelo é stateless por decisão (§1.4). Snapshots do site e o histórico consultivo planejado da V4 não mudam essa regra |
| Usar `float` para pontuação | `Decimal`, sempre. `float` produz `2.9000000000000004` no e-mail (§5.4) |
| Reconhecer loja por substring | Match exato contra nome canônico ou apelido cadastrado (RN04) |

## Convenções

- **Português do Brasil** em código, nomes de variáveis, testes e documentação. Exceções: o que a ferramenta exige (`src/`, `__init__.py`, `conftest.py`, `pyproject.toml`) e nomes de bibliotecas de terceiros.
- Testes usam prefixo `teste_` em vez de `test_`, configurado no `pyproject.toml`.
- Testes de orquestração usam **fakes das portas**, não `mock.patch` sobre bibliotecas.
- Estrutura de pastas plana. Ver §4.4 do PRD antes de criar diretório novo.

## Documentação é parte da mudança

Toda inclusão, alteração ou remoção de funcionalidade deve atualizar a
documentação no mesmo ciclo. Isso inclui regra de negócio, dado, rota/API,
schema/migration, workflow, configuração, teste e jornada Flutter.

1. Use [`docs/README.md`](docs/README.md) para localizar a documentação do
   domínio antes de editar.
2. Atualize o PRD em `docs/prd/` quando comportamento, contrato, autorização,
   arquitetura, estado ou aceite mudar. Regras numeradas exigem varredura de
   todas as referências no PRD.
3. Atualize [`docs/testes/TESTES.md`](docs/testes/TESTES.md) quando os casos
   técnicos cobertos mudarem; o PRD registra estratégia e critérios de aceite.
4. Atualize [`docs/PENDENCIAS.md`](docs/PENDENCIAS.md): retire item concluído;
   mantenha aberto o que depende de ambiente externo, confirmação manual ou
   decisão futura. Git não prova estado de produção, migrations aplicadas ou
   secrets externos.
5. Plano implementado deixa de ser plano e deve ser incorporado ou movido para
   o PRD. Feature, arquivo, rota ou fluxo removido do código também sai da
   documentação; não preservar instrução histórica que possa orientar trabalho
   futuro incorretamente.
6. Ao criar, mover ou excluir documento/pasta, atualize `docs/README.md` e os
   links de entrada no `README.md` da raiz.

Uma decisão que contradiz código ou outra seção é bug de documentação, não
detalhe. Não encerre a tarefa somente porque o código compila ou os testes
passam: a documentação afetada também precisa estar consistente.

## Cadência de testes

- Trabalhe em lote: primeiro implemente e escreva ou ajuste os testes, sem rodar a suíte depois de cada pequena edição.
- Execute os testes relevantes no fechamento da tarefa ou antes do build previsto. Quando o fechamento já incluir build, a execução anterior ao build também é a validação final; não rode a mesma suíte duas vezes sem necessidade.
- Se essa validação encontrar falhas, corrija e rode somente os testes necessários durante o ajuste; ao estabilizar, confirme a suíte relevante uma vez.
- Não pule os gates finais nem declare aprovação sem evidência. Esta regra reduz a frequência das execuções, não a cobertura exigida.

## Antes de escrever código

A V1.0 está em produção (§11.1 do PRD). A V2.0 está em produção e **validada contra a página real** (2026-08-11): o extrator lê o payload `__NEXT_DATA__` (RF14), `Parceiro` tem `pontos_base`/`inicio_promocao`/`fim_promocao`/`campanha`, e o e-mail mostra validade (RN22) e distingue `CLUB` de `PROMOTION_CLUB` (RN23). A V2.1 está no ar desde 2026-08-11: o `DATABASE_URL` foi cadastrado, `montar_catalogo()` lê o Postgres com o TOML como reserva, e em produção o catálogo já vem do banco (132 lojas, 10 categorias, batendo com o arquivo).

A V2.2 está implementada: `alertas.py` decide o alerta por RN27 (múltiplo da base com piso) em vez da etiqueta da Livelo, com régua vinda da tabela `preferencia` (RN28) e suspeita de C07 sem guardar estado (RN29, ver PRD-V2 §6.3). O e-mail continua diário de propósito — cortar isso é RF16, da V2.4, e essa calibragem (ver `docs/PENDENCIAS.md`) ainda está em andamento.

A V2.3 está **fechada nas duas metades**: o robô grava o retrato de cada execução no banco (`retrato.py`, porta `RepositorioDeExecucao`, migração `002`), e o site Next.js em `site/` já lê isso — publicado na Vercel, com leitura pública, edição protegida por senha única e RN24/RN25/RN26/RN30 atendidas. O robô continua sem ler de volta o que grava: nenhuma decisão de alerta consulta o passado, então "stateless" segue valendo onde importa. A V2.3.1 (redesenho de informação: uma tela por tarefa), a V2.3.2 ("banco manda, e o site dispara": banco vazio agora vale de verdade, e o botão **Forçar atualização** do site dispara o `robo.yml`), a V2.3.3 (redesenho visual: cartões em grade com barra de progresso por loja, cabeçalho fixo com desfoque, menu renomeado — Painel/Alertas/Lojas/Ajuda, tema claro/escuro) e a V2.3.4 (flags de funcionalidade em `/configuracoes`, como interruptores onde ligado sempre esconde algo: o campo de aviso opcional no cadastro de loja pode ser escondido do formulário de Adicionar loja, e a tela de Alertas inteira pode ser escondida do menu/rodapé/Painel e da rota `/avisos` — as duas desligadas por padrão, então por padrão ambas ficam visíveis) também estão feitas. O Painel também mostra a letra miúda da campanha da Livelo (`legalTerms`) quando ela existe, para decidir se a promoção serve sem abrir o app.

A V2.3.2 está fechada: `robo.yml` ganhou o input `enviar_email` do `workflow_dispatch` (padrão `true`), o disparo manual do site manda `enviar_email: "false"` e `verificar_promocoes` pula só o notificador — o retrato continua gravado igual, o agendado continua mandando e-mail sempre. `GITHUB_TOKEN_DISPARO` está cadastrado na Vercel. A V2.4 (e-mail condicional, RF16) está **destravada** desde que o autor verificou o site publicado em 2026-08-13, mas ainda não começou — é regra de negócio diferente de `enviar_email`: RF16 decide por ter promoção ou não, `enviar_email` decide por quem pediu a execução.

A V3.0–V3.3 do Shopping Inter está **implementada e validada no workspace** desde 2026-08-14. O coletor usa o endpoint público fixo, mantém domínio/portas/tabelas/workflow separados da Livelo e não envia e-mail. A migração `006` foi aplicada no Neon e a primeira sincronização real gravou 381 lojas com estado `sucesso`; nenhuma favorita foi escolhida ainda. As rotas novas são `/inter` e `/inter/lojas`. O código ainda precisa ser enviado à `main` para o workflow `inter.yml` existir no GitHub e a Vercel publicar essas páginas. A fonte da verdade desta integração é o [`docs/prd/PRD-INTER-CASHBACK.md`](docs/prd/PRD-INTER-CASHBACK.md).

A V4 implementa a área Compre direto no Inter como terceira integração: seleciona qualquer quantidade de lojas, pagina o catálogo exposto, busca somente no banco e guarda 30 dias de histórico. Em 2026-08-17 o contrato real foi corrigido (`sellers` na raiz, caminhos relativos com `?v=`, tags como objetos e marca/categoria/estoque em `skus`), a migração incremental `008` foi aplicada e a primeira carga da Casas Bahia publicou 3.310 produtos. A janela vazia termina na letra M; por isso a coleta une uma partição fixa `smartphone`, que trouxe o Edge 60 Pro sem transformar o site em proxy. O workflow V4.5 usa matriz dinâmica, `max-parallel: 2` e pausa de 1,5 s. A correção V4.5.1 guarda até três tentativas completas quando o total varia, publica a maior como degradada sem inativar ausentes e requer aplicar a migração `009`. Ponto e o dimensionamento para mais lojas continuam pendentes.

O e-mail foi redesenhado em 2026-08-13 (bloco de cor sólida por oferta, descrição de campanha expansível sem JavaScript, marca "Pontuação Livelo" no topo e no rodapé) e o site ganhou logo própria no cabeçalho, rodapé e título do navegador — raciocínio completo, incluindo o orçamento de bytes contra o corte do Gmail (C05) e como regenerar os PNGs, em [`docs/guias/EMAIL.md`](docs/guias/EMAIL.md).

Um redesenho de navegação apelidado "V4.6" (nome do mockup que o originou, não é versão do projeto) começou na madrugada de 2026-08-12 para 13: o cabeçalho fixo virou barra lateral (coluna fixa em telas largas, barra compacta no celular), e a cor de ação geral separou do rosa de alerta — indigo (`--marca`) para botão/link/foco, rosa (`--acento`) só para o que pede atenção. O logo real entrou na barra lateral com um chip branco atrás — o quadrado "R$" da marca é quase branco, pensado pro fundo claro do resto do site, e sumia no fundo escuro da lateral sem isso. Nas fatias seguintes, ainda em 2026-08-13, o Painel ganhou o hero escuro com "Top 3 Oportunidade" e o botão "Ir para a Livelo" em cada cartão, a tabela de Lojas ganhou a coluna Limiar e o ícone de remover, e — depois que você mandou `novo.html` direto na `main` (mesmo mockup, confirmado idêntico) cobrando que o Painel estava "totalmente diferente" — o agrupamento por categoria saiu do Painel: virou uma grade única com ordenar (Maior pontuação / Em alerta / Nome A-Z, por link comum, sem JavaScript), igual ao mockup, com a busca cobrindo o que o índice de categoria fazia antes. Só a Central de Alertas (histórico dos e-mails enviados) segue pendente, detalhada em `docs/PENDENCIAS.md` — é funcionalidade nova de verdade (exige tabela e mudança em `principal.py`), não só reskin; o toggle de "e-mail automático" do mockup foi deliberadamente deixado de fora por esbarrar na V2.4 acima, e o "+X% avanço" do mockup também ficou de fora por virar `Number()` em texto na tela, o que a regra de ouro nº 7 já proíbe. Numa fatia seguinte, ainda em 2026-08-13, o botão "Forçar atualização" saiu do fim de `/lojas` e foi para a barra lateral, logo abaixo de "Lojas" — igual ao mockup. Essa mudança expôs um bug de verdade na barra compacta do celular (logado, a navegação ficava espremida a ~77px de largura, exigindo rolagem quase sem indício visual), corrigido escondendo o nome ao lado do logo abaixo de 480px — provavelmente a causa real de um "veio quebrado" relatado antes que não tinha sido reproduzido.

A ordem do que falta, incluindo publicação e smoke visual da V3 e os gates da V4, está em [`docs/PENDENCIAS.md`](docs/PENDENCIAS.md). Não trate código apenas presente no workspace como se já estivesse publicado nem documentação planejada como implementação.
