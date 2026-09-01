# Auditoria técnica e funcional completa do projeto

**Data da auditoria:** 29/08/2026

**Branch/escopo efetivo:** `re-design`; Flutter mobile compacto, API, robôs, banco, integrações e automações que alimentam o mobile. O Flutter Web, o protótipo Web e a aplicação/site Web foram deliberadamente excluídos conforme `AGENTS.md`.

**Natureza:** análise estática, testes unitários/widgets autorizados, consultas HTTP somente leitura e consulta SQL explicitamente `READ ONLY`. Nenhum código, dado, migration, workflow ou ambiente foi alterado.

## Como ler os resultados

- `FEITO`: há evidência do fluxo necessário e os contratos encontrados fecham ponta a ponta.
- `PARCIAL`: existe fluxo real, mas falta uma parte, cobertura, estado ou garantia relevante.
- `NÃO FEITO`: intenção ou interface existe, mas a implementação necessária não existe.
- `QUEBRADO`: há evidência reproduzível de comportamento incorreto, falha ou regra violada.
- `DUPLICADO`: duas implementações concorrentes/equivalentes permanecem no projeto.
- `NÃO USADO`: existe código/tabela/artefato sem consumidor de produção encontrado.
- `INCERTO`: a conclusão depende de ambiente externo, credencial ou operação que não pôde ser validada sem extrapolar a auditoria.

A contagem oficial é a da **Tabela mestre**. Itens amplos não são recontados em cada seção.

## Resultado executivo

O projeto tem uma arquitetura coerente — Flutter → API autenticada → Postgres, e robôs separados para Livelo, cashback de Sites parceiros e produtos do Compre direto — e a maioria dos contratos HTTP do Flutter possui rota correspondente. O código, porém, ainda não representa um produto integralmente operacional: o banco acessível pela credencial local está migrado, mas vazio (zero catálogo, zero acompanhamentos, zero produtos e nenhuma execução); o histórico Livelo pode ser apagado ao deixar de acompanhar uma loja; filtros paginados do Inter produzem conclusões apenas sobre as páginas carregadas; o “melhor cashback” ignora a regra de considerar somente acompanhadas; a central de alertas e ações de conta são placeholders; e um widget mobile falha em teste por uma composição inválida de `ListTile`.

Também há uma camada antiga convivendo com a nova: painel Livelo antigo e catálogo novo, dois catálogos de Sites parceiros no mobile, disparos antigos e idempotentes, funções de banco antigas, uma tabela de oferta atual nunca usada e um executável de preview com mocks. Isso amplia o risco de correções serem aplicadas à implementação errada.

## Evidência operacional obtida sem mutação

- `GET https://robo-de-produtos.vercel.app/api/status`: HTTP 200 e `{"saudavel":true}`.
- `GET` sem token em `/api/resumo`, `/api/livelo/catalogo`, `/api/inter/cashback` e `/api/inter/produtos?q=celular`: HTTP 401 estruturado, confirmando proteção no deployment consultado.
- Banco apontado por `backend/robo/.env`, em transação `READ ONLY`: todas as tabelas esperadas das migrations 001–015 e colunas de qualidade da 009 existem. Contagens: 1 usuário ativo; 0 lojas Livelo acompanhadas; 0 favoritas Inter; 0 lojas diretas selecionadas; 0 parceiros Livelo ativos; 0 produtos ativos; 0 ofertas na tabela `oferta_direta_inter_atual`; nenhuma execução Livelo, cashback Inter ou produtos.
- Não foi possível provar que a `DATABASE_URL` local é exatamente a mesma configurada na Vercel; essa ligação permanece `INCERTO`.

# RELATÓRIO POR ÁREA

## Arquitetura, API e segurança

### Comunicação e isolamento dos domínios — FEITO

O Flutter centraliza HTTP em `app/lib/core/api/cliente.dart` e `api.dart`; não há acesso a Neon, Livelo ou Inter no bundle. A API lê Postgres por `backend/api/lib/banco*.ts`; somente os robôs em `backend/robo/src/robo_livelo` acessam as fontes externas. Cashback de Sites parceiros (`principal_inter.py`) e produtos do Compre direto (`principal_produtos_inter.py`) têm modelos, execuções e tabelas separados.

### Autenticação e autorização — FEITO, com lacunas operacionais

Login e recuperação usam Firebase Auth (`autenticador_firebase.dart`). E-mail precisa estar verificado no cliente e em `autenticacao-api.ts`. A API liga convite por e-mail ao UID em `banco-autenticacao.ts`; todas as rotas de dados exigem bearer token. Mutações e administração exigem `papel: "admin"` no servidor, não apenas ocultação visual. Rate limit por origem/usuário/operação e auditoria pseudonimizada estão implementados.

Lacunas:

- exceções inesperadas durante autenticação retornam 500, mas o `catch` não registra auditoria de falha (`PARCIAL`);
- App Check depende de dois flags de build/deployment. Nos `.env` locais `EXIGIR_APP_CHECK=false`; o estado efetivo da Vercel e dos builds distribuídos não foi comprovado (`INCERTO`);
- os dois `.env` locais ignorados contêm segredos amplos; `app/.env` não é carregado pelo Flutter e mistura credenciais de backend em diretório de cliente. Ambos têm modo 664. Não estão versionados, mas a organização/permissão local é excessiva (`PARCIAL`).

### Tratamento HTTP — PARCIAL

Timeout de 20 s, bearer/App Check, JSON e erros 4xx/5xx são centralizados no Flutter. Entretanto, rotas de leitura como resumo, cashback e produtos deixam exceções de banco escaparem; uma resposta 500 HTML/não JSON vira `ErroDeRede('resposta JSON inválida')`, perdendo o código real. O status público retorna somente `saudavel`, enquanto `StatusApi` e seu teste esperam também `api`; o parser tolera a ausência, e esse método não tem consumidor de produção.

## Navegação, Início, conta e tema

### Navegação mobile — FEITO

As quatro áreas do protótipo — Início, Livelo, Banco Inter e Buscar produtos — estão em `DestinoCompacto`. Os painéis são instanciados sob demanda e mantidos em `IndexedStack`, preservando controlador, busca, página e rolagem durante a troca de área. Administração fica fora das quatro áreas e só é oferecida ao papel admin.

### Início — FEITO

`PaginaInicio` chama `/api/resumo` ao abrir, ao retomar, no pull-to-refresh e a cada 30 s apenas enquanto a tela compacta está ativa e o app está em primeiro plano. O backend lê os três domínios com `Promise.allSettled`, preserva estados independentes e distingue atualizado, atrasado, atualizando, parcial, degradado, falha recente, sem dados e indisponível. Falha de atualização preserva o último resumo.

### Tema claro/escuro — QUEBRADO em um ponto

Persistência Android (`SharedPreferences` via `MainActivity.kt`) e iOS (`UserDefaults` via `AppDelegate.swift`) está implementada e o controlador mantém a escolha da sessão quando a gravação falha. Porém o teste “controle do cabeçalho alterna o mobile claro e escuro” falha: `ControleAparenciaRadar.linha` usa `ListTile` dentro do `DecoratedBox` do rodapé da gaveta sem `Material` intermediário; o Flutter dispara a asserção de tinta/fundo invisível. A função de persistência isolada passa, mas a jornada pela gaveta está quebrada em debug/teste.

### Alertas e conta — PARCIAL/NÃO FEITO

A folha de alertas consulta somente `/api/resumo` e mostra contagens/estados agregados. Ela própria declara que histórico, lidos e não lidos dependem de endpoint ausente. O protótipo mostra eventos individualizados, mas não existem tabela, endpoint, DTO nem lista correspondente. “Segurança e acesso” e “Integrações” são cartões estáticos com seta, sem callback ou tela. Logout e acesso à Administração são reais.

## Livelo

### Coleta e persistência — FEITO

Fluxo: workflow `robo.yml` (09h/14h/20h Brasília ou manual) → `PaginaLiveloHttp` → `extrair_parceiros` → regras de alerta → `RepositorioPostgres.registrar` em transação → `execucao`, `parceiro_livelo` e `pontuacao` → API → Flutter.

Há validação de IDs estáveis, deduplicação, sanitização de HTML legal, limiar mínimo de parceiros, catálogo atual, retrato histórico para todo parceiro e publicação atômica. Ausência de promoção não é confundida com falha de extração. A fonte HTTP, contudo, repete também erros HTTP permanentes; a política documentada fala em falhas transitórias (`PARCIAL`).

### Catálogo, busca e paginação — PARCIAL

Flutter recebe somente a página pedida e implementa busca, abas Todas/Acompanhadas/Alertas, categoria, ordenação, carregar mais, loading, vazio, erro e retry. O backend, porém, carrega o catálogo ativo inteiro, filtra/ordena em memória e só então pagina. A regra “catálogo completo não vai para o Flutter” está cumprida; paginação no banco/eficiência não está.

### Acompanhamento — QUEBRADO por perda de histórico

O botão, callback, PATCH admin, validação, persistência e rollback otimista existem. Ao remover acompanhamento, `alterarAcompanhamentoParceiroLivelo` executa `DELETE FROM loja`. A FK original `pontuacao.loja_id REFERENCES loja(id) ON DELETE CASCADE` continua ativa mesmo após a migration 015 adicionar `parceiro_livelo_id`. As medições novas de parceiros acompanhados preenchem ambos os campos. Resultado: deixar de acompanhar pode apagar todas as medições históricas ligadas à loja, embora a identidade estável do parceiro permaneça. O endpoint de histórico então perde passado real.

### Alertas Livelo — FEITO, com diagnóstico parcial

O alerta só pode ser ativado em loja acompanhada. A regra autoritativa está em Python/Decimal: pontuação efetiva ≥ `max(base × multiplicador, piso)`, sobrescrita por loja, tratamento de Clube e fallback controlado quando base é desconhecida. API/Flutter apenas exibem `alerta` persistido. A detecção RN29 de base degenerada gera apenas log; não marca a execução nem chega ao resumo/mobile, portanto o usuário pode ver “atualizado” apesar da suspeita (`PARCIAL`).

`pontos_anteriores` existe em modelo, tabela, API e Flutter, mas nunca é calculado/preenchido pelo extrator; permanece nulo (`NÃO FEITO`).

### Histórico, links e atualização manual — PARCIAL

Histórico devolve as 30 medições mais recentes e tem loading/erro/vazio. Links só aparecem se HTTPS, mas qualquer host HTTPS é aceito, não apenas Livelo/domínio parceiro confiável. A atualização manual Livelo é admin, dispara workflow idempotente e consulta API a cada 30 s até `ultimaColeta` mudar; não há limite/timeout, logo pode consultar indefinidamente se o workflow falhar sem novo retrato.

### Coexistência antiga — DUPLICADO/NÃO USADO

`/api/livelo/painel`, `ControladorPainelLivelo`, `PaginaPainelLivelo` e `CartaoLivelo` convivem com `/catalogo` e a nova tela mobile. O painel antigo ainda serve layout não compacto, mas não é a implementação autoritativa do redesign mobile. Funções antigas de banco (`lojasComExcecao`, `salvarLimiarDaLoja`, `adicionarLoja`, `removerLoja`, disparo manual antigo) não têm chamadas de produção encontradas.

## Banco Inter — Sites parceiros e cashback

### Coleta — FEITO, com workflow excessivo

O robô valida JSON, identidades, mínimo de 100 lojas e publica snapshot completo em transação. Falha recente é gravada separadamente e o último snapshot válido permanece consultável. O workflow `inter.yml`, porém, executa em todo `push`, além das três janelas diárias e do manual, contrariando a frequência/cortesia documentada e gerando consultas externas desnecessárias (`QUEBRADO`).

### Catálogo e acompanhamento — PARCIAL/QUEBRADO

`GET /api/inter/cashback` devolve catálogo completo paginado ao cliente, última tentativa, último sucesso e ausência sem transformar em zero. Assim como Livelo, lê/ordena o conjunto inteiro no servidor antes de paginar. PATCH de favorita persiste em `favorita_inter`, exige admin e tem atualização otimista/rollback no Flutter.

A aba compacta “Sites parceiros” usa `GET /api/inter/lojas`, endpoint admin. A aba é exibida também para usuário comum e imediatamente recebe 403. Além disso, os chips “Acompanhadas” e “Maior cashback” das duas telas filtram/ordenam apenas `_controlador.itens`, isto é, páginas já carregadas. Podem afirmar “nenhuma acompanhada” ou “maior cashback” sem considerar o restante do catálogo.

O destaque do hero `_capturarMelhorOferta` pega o primeiro item encontrado da primeira página ordenada e não exige `favorita`; viola a regra documentada de melhor oferta entre lojas acompanhadas.

### Regras monetárias e abertura externa — QUEBRADO/NÃO FEITO

Flutter compara cashback por `BigInt`, mas `ordenarCashbacksInter` no backend usa `Number` e subtração sobre NUMERIC textual para uma decisão de ranking. Isso duplica a regra e viola a restrição de não usar ponto flutuante em regra financeira.

Nenhuma tela compacta oferece “Abrir Shopping Inter”, apesar de existir a constante não usada `LINK_SHOPPING_INTER`. O refresh manual de cashback existe no backend e na tela ampla, mas é explicitamente ocultado no hub compacto (`mostrarAtualizacao:false`).

### Duplicação funcional

Após a evolução que tornou `/cashback` um catálogo completo, as abas “Cashback” e “Sites parceiros” apresentam essencialmente as mesmas lojas com busca, chips, cards e acompanhamento implementados duas vezes. Para leitura do usuário, `/cashback` é o retrato autoritativo; `/lojas` é administração. A separação atual aumenta divergência de filtro, permissão e estado.

## Banco Inter — Compre direto / produtos

### Catálogo de lojas e seleção — FEITO/PARCIAL

O robô sincroniza vendedores diretos em `loja_direta_inter`; o admin lista e seleciona por `/api/inter/produtos/lojas`. A resposta inclui última execução, estado e páginas por loja, mas `LojaDireto.parse` descarta esses campos e a administração mobile não os mostra. Remover seleção também não pede a confirmação prevista no PRD.

### Coleta de produtos — FEITO

O fluxo pagina a fonte até o fim com `searchId`, detecta offset/página repetida, deduplica por ID, repete até três vezes quando o total varia e publica o melhor candidato como degradado. Cada loja é transacional; falha preserva o snapshot anterior; catálogo completo desativa ausentes e catálogo degradado não os apaga. A rodada consolida sucesso/parcial/falha e usa matriz com `max-parallel: 2`. Retenção de medições é 30 dias.

Não há recuperação de execução `iniciada` abandonada por cancelamento abrupto. Sem execução posterior, o resumo pode ficar “atualizando” indefinidamente (`PARCIAL`).

### Busca — FEITO

Flutter exige dois caracteres, debounce de 350 ms, consulta `/api/inter/produtos` e preserva busca/filtros/página ao navegar. Backend normaliza acentos/stopwords e `celular → smartphone`, consulta somente Postgres, aplica filtros de marca/categoria/loja/preço e pagina no SQL. O catálogo completo não é enviado. Valores monetários continuam strings no JSON e são formatados no Flutter sem `double`.

O envelope de atualização/qualidade é parcial: `statusCatalogoProdutos` usa a execução de loja mais recente global, não o conjunto de lojas/resultados consultados. Uma loja recém-falha ou atualizada pode rotular todos os resultados e esconder qualidade/frescor das demais.

### Histórico e abertura — PARCIAL

Histórico pagina medições, calcula mínimo/máximo no banco e preserva páginas já carregadas se o próximo fetch falhar. API retorna `ativo`, mas `ProdutoDireto.parse` ignora o campo; a UI não informa que o item deixou o catálogo atual. O link de produto é reconstruído sob `https://shopping.inter.co`, rejeita autoridade, esquema e `..`, e abre externamente com erro visível.

### Código/tabela sem uso

- `oferta_direta_inter_atual` foi criada na migration 012 e aparece apenas em contagem/aceite de limpeza; produção deriva a oferta atual por `LATERAL` sobre a última medição.
- `buscarProdutosDiretos` (LIMIT 500), `totalProdutosDiretos`, `correspondeBuscaProdutos`, `moeda` e `percentual` não têm consumidor de produção.
- O refresh manual `produtos_inter` é suportado pela API/workflow, mas não é mostrado no mobile compacto.

## Administração

### Catálogos e preferências — FEITO

Administração mobile chama rotas reais para CRUD/regra Livelo, preferências globais, favoritas de Sites parceiros e seleção do Compre direto. O backend revalida papel e corpo, e as tabelas persistem o resultado. Não há dados ilustrativos promovidos a reais.

### Disparos — PARCIAL

O fluxo ativo reserva `solicitacao_disparo_app` por domínio/chave, impõe cooldown de 5 min e dispara nomes fixos de workflow. Flutter gera chave opaca válida e a preserva após erro de rede. Se o servidor responde `cooldown`, porém, a resposta vira exceção; o widget não absorve `espera_segundos` nem atualiza o contador local, permitindo retries inúteis até uma leitura posterior.

As tabelas/funções antigas `disparo_manual*`, `esperaAteProximoDisparo*` e `registrarDisparo*` coexistem com o mecanismo idempotente. Não são usadas pelo endpoint atual; a limpeza ainda as conta/trunca.

### Limpeza — INCERTO operacionalmente

GET de resumo, frase exata cruzada entre Flutter/servidor, papel admin, transação e separação Livelo/Inter estão implementados. Testes unitários passam. O único aceite real de rollback/repetição usa banco descartável e foi deliberadamente excluído porque depende de `ACEITE_F5_DESCARTAVEL=true` e é destrutivo; portanto não se afirma funcionamento operacional completo.

## Banco e persistência

As migrations 001–015 estão materializadas no banco consultado, inclusive autenticação, disparo idempotente, catálogo/histórico Livelo e qualidade de produtos. NUMERIC/checks e FKs cobrem valores e estados. Auditoria e medições de produto têm retenção de 30 dias implementada.

O banco está sem qualquer dado de negócio ou execução. Mesmo com o código implementado, a experiência real ligada a esse banco seria “sem dados” em todos os domínios. Como não foi possível provar que a Vercel usa essa mesma credencial, o vínculo deployment↔banco é incerto; o banco em si está comprovadamente vazio.

# MAPA DE REGRAS DE NEGÓCIO

| Regra | Status | Onde executa | Evidência/conclusão |
|---|---|---|---|
| Flutter é cliente da API e não acessa Neon/Livelo/Inter | FEITO | Flutter `ClienteApi`; API `banco*.ts`; robôs `adaptadores*.py` | Separação respeitada. |
| Livelo, Sites parceiros e Compre direto são domínios separados | FEITO | três workflows, três execuções e conjuntos de tabelas | Estados e falhas independentes. |
| Catálogo completo não vai ao Flutter | FEITO | paginação das rotas/DTOs | Todos devolvem página; Livelo/cashback ainda materializam tudo no servidor. |
| Busca de produto nunca consulta fonte externa ao digitar | FEITO | `ControladorBuscaProdutos` → API → SQL | Robô é o único consumidor da fonte Inter. |
| Busca de produto exige pelo menos 2 caracteres e debounce | FEITO | Flutter e rota `/inter/produtos` | 350 ms no cliente, validação repetida no servidor. |
| `celular` equivale a `smartphone` | FEITO | Python na persistência e TS na consulta | Normalização compatível. |
| Valores monetários/pontos não usam `double` para cálculo | PARCIAL | Python `Decimal`, Flutter string/BigInt; backend Inter usa `Number` no ranking | Apresentação está exata; ranking cashback viola a regra. |
| Zero, ausência, falha, parcial e atraso são estados distintos | FEITO | schemas, resumo e widgets | Coberto em modelos/widgets e testes. |
| Livelo alerta só loja acompanhada | FEITO | rota `/alerta`, banco e card | Servidor é autoritativo. |
| Alerta Livelo usa base×multiplicador e piso | FEITO | `alertas.py` | Decimal, preferência global e sobrescrita por loja. |
| Clube altera pontuação efetiva somente para assinante | FEITO | `pontuacao_efetiva`/`merece_alerta` | `CLUB` é suprimido para não assinante; `PROMOTION_CLUB` preservado. |
| Site Livelo estruturalmente inválido não publica | FEITO | extrator + limiar em `principal.py` | Falha ruidosa antes da persistência. |
| Suspeita de base Livelo degenerada não deve parecer normal | PARCIAL | `suspeita_de_base_degenerada` | Só log; API/mobile podem continuar verdes. |
| Desacompanhar não deve apagar histórico | QUEBRADO | `DELETE loja` + FK `pontuacao.loja_id ON DELETE CASCADE` | Histórico pode ser removido. |
| Link de Livelo deve ser HTTPS confiável | PARCIAL | Flutter `_linkHttpsValido` | Exige HTTPS, mas aceita host arbitrário. |
| Snapshot válido Inter é atômico e falha preserva o anterior | FEITO | `RepositorioInterPostgres` | Execução falha separada do último sucesso. |
| Cashback ordena encontrados/positivos/valor/nome | QUEBRADO | `ordenarCashbacksInter` | Semântica existe, mas usa `Number` em valor financeiro. |
| Melhor cashback considera somente acompanhadas | QUEBRADO | `_capturarMelhorOferta` | Não filtra `favorita` e considera só a primeira página. |
| Filtro “Acompanhadas” considera o catálogo inteiro | QUEBRADO | filtros locais em cashback/sites | Só páginas carregadas. |
| Selecionar/acompanhhar não dispara coleta | FEITO | PATCHs só alteram tabelas de preferência | Coleta ocorre por workflow/manual. |
| Frequência Inter é 3 vezes/dia + manual | QUEBRADO | `.github/workflows/inter.yml` | `on: push` adiciona execuções. |
| Produto publica por loja de forma atômica | FEITO | staging/transação em `adaptadores_produtos_inter.py` | Falha preserva último snapshot. |
| Coleta degradada não desativa ausentes | FEITO | `catalogo_completo=not degradada` | Evita perda falsa por fonte variável. |
| Produto atual vem da última medição válida | FEITO | SQL `LATERAL` em `banco-produtos-inter.ts` | Tabela “atual” não é usada. |
| Histórico de produto retém 30 dias | FEITO | expurgo do repositório | Índice próprio e testes unitários. |
| Página/busca/posição são preservadas nas ações | PARCIAL | `IndexedStack`, controladores, rollback otimista | Bom em Livelo/produtos; filtros Inter globais são locais/incompletos. |
| Administração é protegida por autorização | FEITO | `papel: admin` em todas as mutações/rotas admin | Ocultação Flutter não é a única barreira. |
| Disparo manual é idempotente e tem cooldown | PARCIAL | `solicitacao_disparo_app`, API, Flutter | Backend correto; cliente não incorpora cooldown devolvido em erro. |
| Limpeza preserva tabelas técnicas e isola domínios | INCERTO | `limpeza.ts` | Código/teste unitário existe; aceite destrutivo não foi executado. |
| Segredos não ficam no cliente | PARCIAL | bundle Flutter não contém segredo; `app/.env` local contém credenciais backend | Arquivo é ignorado, mas está mal localizado e permissivo. |

# MATRIZ FLUTTER ↔ BACKEND

| Funcionalidade | Flutter | Endpoint | Backend | Banco/integração | Resposta | Status | Problema |
|---|---|---|---|---|---|---|---|
| Saúde | `Api.status` | `GET /api/status` | route pública | N/A | parser tolera ausência | NÃO USADO | Sem consumidor; DTO/teste espera `api`, rota não envia. |
| Resumo Início | `Api.resumo` | `GET /api/resumo` | `carregarResumoInicio` | três consultas Postgres | compatível | FEITO | Exceção total pode virar 500 não estruturado. |
| Perfil | `Api.perfil` | `GET /api/perfil` | autenticação/convite | `usuario_app` | compatível | FEITO | — |
| Painel Livelo antigo | `painelLivelo` | `GET /api/livelo/painel` | consulta retrato antigo | `execucao/pontuacao` | compatível | DUPLICADO | Coexiste com catálogo novo. |
| Catálogo Livelo | `catalogoLivelo` | `GET /api/livelo/catalogo` | filtro/ordem/página | `parceiro_livelo/loja/execucao` | compatível | PARCIAL | Pagina só após carregar tudo no servidor. |
| Acompanhar Livelo | `alterarAcompanhamentoLivelo` | `PATCH .../acompanhamento` | valida/admin/CTE | `loja` | compatível | QUEBRADO | Desacompanhar pode apagar histórico por cascade. |
| Alerta Livelo | `alterarAlertaLivelo` | `PATCH .../alerta` | valida/admin | `loja.alerta_ativo` | compatível | FEITO | Só acompanhada. |
| Histórico Livelo | `historicoLivelo` | `GET .../historico` | últimas 30 | `pontuacao/execucao` | compatível | PARCIAL | Dados podem ter sido apagados ao desacompanhar. |
| Admin lojas Livelo | métodos CRUD | `GET/POST /livelo/lojas`; `PATCH/DELETE /lojas/:id` | valida/admin | `loja/apelido` | compatível | FEITO | — |
| Preferências Livelo | métodos de preferências | `GET/PATCH /livelo/preferencias` | valida/admin | `preferencia` | compatível | FEITO | — |
| Cashback Inter | `painelCashbackInter` | `GET /api/inter/cashback` | snapshot/filter/order/página | `execucao_inter/cashback_inter/loja_inter` | compatível | PARCIAL | Ranking usa Number; paginação em memória. |
| Admin Sites parceiros | `lojasInter`/`alterarFavoritaInter` | `GET/PATCH /api/inter/lojas` | admin | `loja_inter/favorita_inter` | compatível | QUEBRADO | Aba é acessível a usuário comum, endpoint não. |
| Buscar produtos | `buscarProdutos` | `GET /api/inter/produtos` | valida/filtros/SQL paginado | catálogo local Postgres | compatível | FEITO | Estado global de qualidade não representa cada loja. |
| Histórico produto | `historicoProduto` | `GET /api/inter/produtos/historico` | SQL paginado/min/max | `medicao_*` | parcialmente usado | PARCIAL | Campo `ativo` da resposta é ignorado. |
| Lojas Compre direto | `lojasDiretas`/`alterarSelecaoLojaDireta` | `GET/PATCH /api/inter/produtos/lojas` | admin | `loja_direta_inter` + execuções | parcialmente usado | PARCIAL | Metadados operacionais são descartados pelo DTO Flutter. |
| Estado de disparo | `estadoDisparo` | `GET /api/administracao/disparos` | admin | `solicitacao_disparo_app` | compatível | FEITO | — |
| Solicitar disparo | `solicitarDisparo` | `POST /api/administracao/disparos` | reserva + GitHub | DB + GitHub Actions | compatível | PARCIAL | Cooldown de erro não atualiza cliente. |
| Resumo/limpeza | `resumoLimpeza`/`executarLimpeza` | `GET/POST /api/administracao/limpeza/:dominio` | admin + frase + transação | Postgres | compatível | INCERTO | Aceite destrutivo não executado. |

Não foi encontrada chamada Flutter apontando para rota inexistente, método HTTP divergente ou parâmetro obrigatório com nome incompatível. O problema predominante não é “404 de contrato”, mas resposta parcialmente utilizada, permissão incoerente com a UI e semântica incompleta sobre paginação/estado.

# COMPONENTES/FUNCIONALIDADES REPETIDAS

| Capacidade | Livelo | Inter / Sites parceiros | Inter / Compre direto | Início/compartilhado |
|---|---|---|---|---|
| Busca | FEITO: servidor, nome/categoria | FEITO, mas aba Sites é admin | FEITO: DB, ≥2 chars, debounce | N/A |
| Paginação ao Flutter | FEITO | FEITO | FEITO | N/A |
| Paginação no banco | PARCIAL: lista inteira em memória | PARCIAL: lista inteira em memória | FEITO | N/A |
| Filtros | FEITO no servidor | QUEBRADO: chips globais só em páginas carregadas | FEITO no servidor | N/A |
| Loading/vazio/erro/retry | FEITO | FEITO | FEITO | FEITO |
| Estado atrasado/falha/parcial | FEITO | FEITO | FEITO | FEITO e independente |
| Acompanhamento/seleção | QUEBRADO ao remover (histórico) | FEITO para admin; UI comum inconsistente | FEITO para admin | Resumo somente leitura |
| Histórico | FEITO, limitado a 30 itens | NÃO FEITO | FEITO, paginado/30 dias | Alertas históricos NÃO FEITO |
| Persistência | Postgres | Postgres | Postgres | Tema nativo; sessão Firebase |
| Atualização manual compacta | PARCIAL: existe, polling sem teto | NÃO FEITO | NÃO FEITO | Pull-to-refresh apenas API |
| Links externos | PARCIAL: HTTPS sem host fixo | NÃO FEITO | FEITO: host fixo | N/A |
| Regra financeira | Python Decimal; Flutter textual | QUEBRADO no ranking TS Number | Decimal/NUMERIC/string | Somente apresentação |
| Testes relevantes | unit/widget passam no catálogo | unit/widget passam | unit/widget passam | tema/gaveta tem 1 falha |

# DUPLICAÇÕES

## Painel Livelo antigo versus catálogo novo

- **Onde:** `/api/livelo/painel` + `PaginaPainelLivelo` versus `/api/livelo/catalogo` + `PaginaCatalogoLiveloAndroid`.
- **Usada:** catálogo novo no Android/iOS compacto; painel antigo no layout legado.
- **Autoritativa mobile:** catálogo novo.
- **Risco:** regras/filtros/cards recebem correções diferentes; backend mantém duas consultas e dois DTOs.

## Cashback versus Sites parceiros no hub Inter

- **Onde:** `PaginaCashbackInter` e `_CatalogoSitesParceiros`, com `/inter/cashback` e `/inter/lojas`.
- **Usada:** ambas as abas mobile.
- **Autoritativa:** `/cashback` para leitura do retrato; `/lojas` para administração.
- **Risco:** duas buscas, filtros e mutações visualmente equivalentes, mas uma rota é usuário e outra admin; filtros já divergem.

## Regra de ranking/decimal

- **Onde:** Python `ranking_inter.py`, TypeScript `ordenarCashbacksInter`, Flutter `compararDecimaisInter`.
- **Usada:** TypeScript no endpoint e Flutter nos chips locais; Python só em testes.
- **Autoritativa recomendável:** backend, com comparação decimal exata.
- **Risco:** TS usa `Number`, Flutter usa BigInt e Python tem uma terceira implementação; ordem pode divergir.

## Disparos manuais antigo e atual

- **Onde:** `disparo_manual`, `disparo_manual_inter`, funções `esperaAteProximoDisparo*`/`registrarDisparo*` versus `solicitacao_disparo_app`/`disparos-api.ts`.
- **Usada:** apenas a implementação idempotente nova.
- **Autoritativa:** `solicitacao_disparo_app`.
- **Risco:** manutenção/limpeza contam tabelas que já não representam o mecanismo ativo.

## Normalização e formatação

- **Onde:** Python extratores/modelos, TypeScript `formato*.ts`, Flutter `core/formato.dart` e formatos por feature.
- **Usada:** várias camadas por necessidade de persistência/consulta/apresentação.
- **Autoritativa:** normalização persistida deve ter vetor de contrato comum; apresentação permanece no Flutter.
- **Risco:** parte é duplicação necessária, mas sem testes cruzados de contrato. O caso `celular→smartphone` hoje coincide; cashback decimal já diverge.

# CÓDIGO EXISTENTE MAS NÃO UTILIZADO / LEGADO

| Item | Classificação | Evidência |
|---|---|---|
| `app/lib/inter_preview.dart` e `_ClientePreview` | NÃO USADO em produção | Segundo `main`, JSONs fixos; não é importado pelo `main.dart`. Útil apenas como preview manual. |
| `Api.status`/`StatusApi` | NÃO USADO | Referência somente no teste; app inicia por Firebase/perfil/resumo. |
| `ranking_inter.py` | NÃO USADO | Importado somente por `teste_ranking_inter.py`; produção ordena em TS. |
| `LINK_SHOPPING_INTER` | NÃO USADO | Somente teste; nenhum botão Inter usa o link. |
| `oferta_direta_inter_atual` | NÃO USADO | Sem INSERT/SELECT de produção; apenas migration e limpeza/aceite. |
| `buscarProdutosDiretos`, `totalProdutosDiretos` | NÃO USADO | Implementação antiga; rota usa versão paginada. |
| `correspondeBuscaProdutos`, `moeda`, `percentual` em TS | NÃO USADO | Apenas testes ou nenhuma chamada; Flutter apresenta valores. |
| Funções antigas de lojas/disparo em `banco.ts`/`banco-inter.ts` | NÃO USADO | Sem referências de produção. |
| `disparo_manual*` | LEGADO | Não recebe novos disparos pela API atual; ainda é limpo/contado. |
| `PaginaEmBreve` | PLACEHOLDER ativo no layout legado | “Alertas” amplo mostra “Ainda não implementado”; no mobile a folha parcial substitui a rota. |
| “Segurança e acesso” e “Integrações” | PLACEHOLDER ativo | Cards com seta, sem ação. |
| `test/**/failures/*.png` | ARTEFATO NÃO USADO | Imagens de diffs antigos, fora dos testes unit/widget executados. |

Não foram encontrados `TODO`/`FIXME` de produção relevantes. A ausência desses marcadores não significa conclusão: os placeholders são expressos em widgets/textos e divergências de contrato.

# DOCUMENTAÇÃO X IMPLEMENTAÇÃO

- `prototipo-mobile.html`, `UI_SPEC.md` e `PLANO-EXECUCAO-REDESIGN.md` são coerentes sobre as quatro áreas e o fluxo mobile. A estrutura principal foi implementada.
- O protótipo mostra eventos individuais na folha de Alertas; o código mostra apenas resumo e declara o endpoint ausente.
- O protótipo mostra “Segurança e acesso” e “Integrações” como ações; no código são cards inertes.
- O PRD Inter exige melhor oferta entre acompanhadas; o código usa qualquer loja encontrada.
- O PRD de produtos pede estado da coleta/páginas na seleção de lojas; o backend envia, o Flutter descarta.
- `docs/PENDENCIAS.md` afirma que migrations 009/012 (e trechos posteriores) ainda precisam ser aplicadas, mas o banco consultado já possui todas as tabelas/colunas até 015. A documentação está desatualizada.
- O mesmo documento mantém fases 4.3/4.4 como pendentes apesar de código e testes locais existentes; gates físicos/deployment continuam realmente pendentes.
- `backend/api/README.md` menciona variáveis de e-mail do fluxo do robô; não existe módulo SMTP/e-mail ativo no código atual e `SENHA_APP_GMAIL` não tem consumidor.
- `.github/workflows/app-robo.yml` ainda executa todos os testes, goldens e build Web em cada push, contradizendo o escopo/testes autorizados desta branch mobile. Não foi executado nesta auditoria.

# TABELA MESTRE

Esta é a lista contada. “Testes” informa evidência existente/executada, não cobertura integral.

| ID | Área | Funcionalidade/regra | Status | Flutter | API | Backend | Banco/integração | Testes | Problema/observação |
|---|---|---|---|---|---|---|---|---|---|
| ARQ-01 | Arquitetura | Flutter usa somente API | FEITO | Sim | Sim | Sim | API concentra dados | API/client | Sem acesso externo/DB no app. |
| ARQ-02 | Arquitetura | Integrações externas ficam nos robôs | FEITO | N/A | Lê DB | Sim | Livelo/Inter | Pytest | Correto. |
| ARQ-03 | Arquitetura | Três domínios separados | FEITO | Sim | Sim | Sim | tabelas/workflows separados | Pytest/Vitest | Correto. |
| API-01 | API | Health público/deployment | FEITO | Método existe | `GET /status` | Sim | N/A | curl HTTP 200 | Deployment responde saudável. |
| API-02 | API | Uso do health pelo app | NÃO USADO | Sem consumidor | Responde | Sim | N/A | teste com fixture divergente | Campo `api` ausente na rota real. |
| API-03 | API | Erros estruturados | PARCIAL | Trata JSON | Parcial | catches inconsistentes | DB | cliente/Vitest | 500 não JSON perde código. |
| AUT-01 | Autenticação | Login Firebase | FEITO | Sim | token | Sim | Firebase | widgets/Vitest | Fluxo real. |
| AUT-02 | Autenticação | E-mail verificado + convite | FEITO | Sim | Sim | Sim | `usuario_app` | widgets/Vitest | Dupla validação. |
| AUT-03 | Autenticação | Recuperação de senha neutra | FEITO | Sim | N/A | Firebase | Firebase | widgets | Não enumera conta. |
| AUT-04 | Autenticação | Logout | FEITO | Sim | N/A | Firebase | Firebase | widgets | Real. |
| AUT-05 | Autorização | Papel admin no servidor | FEITO | Oculta ações | Sim | Sim | `usuario_app` | Vitest/widgets | Servidor autoritativo. |
| AUT-06 | Segurança | Rate limit e auditoria | FEITO | Recebe erros | Sim | Sim | tabelas próprias | Vitest | Hash e retenção. |
| AUT-07 | Segurança | Auditar exceção inesperada de auth | PARCIAL | N/A | 500 | Parcial | auditoria | Vitest parcial | Catch não audita. |
| AUT-08 | Segurança | App Check efetivo | INCERTO | Flag de build | Flag servidor | Implementado | Firebase | unitário | Local está off; deployment/build desconhecidos. |
| AUT-09 | Segurança | CORS e cliente nativo | FEITO | Nativo sem Origin | Middleware | Sim | N/A | análise | Auth/App Check protegem dados. |
| ENV-01 | Ambiente | Organização de segredos locais | PARCIAL | `.env` desnecessário | config não no diretório API | robô carrega `.env` | arquivos 664 | inspeção | Segredos amplos duplicados/mal localizados. |
| NAV-01 | Mobile | Quatro áreas compactas | FEITO | Sim | N/A | N/A | N/A | widgets | Igual ao protótipo. |
| NAV-02 | Mobile | Preservar busca/página/posição entre áreas | FEITO | IndexedStack/controladores | N/A | N/A | memória | widgets | Jornada preservada. |
| HOME-01 | Início | Resumo dos três domínios | FEITO | Sim | `/resumo` | Sim | Postgres | widget/Vitest | Ponta a ponta em código. |
| HOME-02 | Início | Polling só quando visível | FEITO | 30 s/lifecycle | `/resumo` | Sim | Postgres | widget | Correto. |
| HOME-03 | Início | Estados independentes | FEITO | Sim | Sim | `allSettled` | três domínios | widget/Vitest | Zero/falha/parcial não se confundem. |
| THEME-01 | Tema | Claro/escuro persistido nativamente | FEITO | Sim | N/A | Kotlin/Swift | prefs locais | unitários | Android/iOS. |
| THEME-02 | Tema | Alternar pela gaveta | QUEBRADO | Asserção `ListTile` | N/A | N/A | N/A | 1 widget falhou | Falta Material entre fundo e tile. |
| ALT-01 | Alertas | Folha de resumo | PARCIAL | Sim | Usa `/resumo` | Sem eventos | só contagens | widgets indiretos | Não reproduz lista do protótipo. |
| ALT-02 | Alertas | Histórico/lidos/não lidos | NÃO FEITO | Declara ausência | Endpoint ausente | Ausente | tabela ausente | nenhum | Funcionalidade inexistente. |
| CONTA-01 | Conta | Acesso à Administração e logout | FEITO | Sim | Rotas reais | Sim | auth/DB | widgets | Protegido por papel. |
| CONTA-02 | Conta | Segurança e acesso | NÃO FEITO | Card inerte | Ausente | Ausente | N/A | nenhum | Placeholder. |
| CONTA-03 | Conta | Integrações | NÃO FEITO | Card inerte | Ausente | Ausente | N/A | nenhum | Placeholder. |
| LIV-01 | Livelo | Extração/catálogo externo | FEITO | N/A | N/A | extrator real | Livelo | Pytest | IDs, HTML, Decimal. |
| LIV-02 | Livelo | Validação/dedupe/limiar | FEITO | N/A | N/A | Sim | fonte | Pytest | Não publica catálogo estruturalmente pequeno. |
| LIV-03 | Livelo | Publicação atual + histórico atômico | FEITO | Lê | Lê | transação | Postgres | Pytest | Todo catálogo válido. |
| LIV-04 | Livelo | Agenda 3×/dia + manual | FEITO | Manual admin | disparo | workflow | GitHub | análise | 09/14/20. |
| LIV-05 | Livelo | Retry apenas transitório | PARCIAL | N/A | N/A | retry amplo | Livelo | Pytest parcial | Também repete 4xx permanente. |
| LIV-06 | Livelo | Paginação integral | PARCIAL | Recebe página | Pagina | lista toda em memória | Postgres | Vitest/widget | Não pagina consulta DB. |
| LIV-07 | Livelo | Busca/abas/categoria/ordem | FEITO | Sim | parâmetros iguais | Sim | Postgres | unit/widget/Vitest | Compatível. |
| LIV-08 | Livelo | Acompanhar loja | FEITO | Botão/rollback | PATCH | CTE/admin | `loja` | widget/Vitest | Persiste e confirma. |
| LIV-09 | Livelo | Desacompanhar preservando histórico | QUEBRADO | Chama PATCH | DELETE lógico | DELETE `loja` | FK cascade | análise SQL | Pode apagar medições. |
| LIV-10 | Livelo | Alerta somente acompanhada | FEITO | Botão condicionado | PATCH admin | valida | `alerta_ativo` | widget/Vitest | Correto. |
| LIV-11 | Livelo | Cálculo base×multiplicador+piso | FEITO | Exibe | N/A | Decimal Python | preferências | Pytest | Autoritativo no robô. |
| LIV-12 | Livelo | Regra Clube | FEITO | Rotula | N/A | Python | payload Livelo | Pytest | Sem alerta indevido. |
| LIV-13 | Livelo | Base ausente | FEITO | Estado | N/A | fallback promoção+piso | payload | Pytest | Ausência não vira zero. |
| LIV-14 | Livelo | Base degenerada visível ao usuário | PARCIAL | Não | Não | Só log | execução não marcada | Pytest núcleo | Pode parecer saudável. |
| LIV-15 | Livelo | Pontos anteriores | NÃO FEITO | Campo existe | Campo existe | Nunca calcula | sempre nulo | nenhum E2E | Estrutura sem dado. |
| LIV-16 | Livelo | Histórico 30 medições | FEITO | Tela | GET | SQL | `pontuacao` | widget/API | Limite fixo, sem paginação. |
| LIV-17 | Livelo | Link externo confiável | PARCIAL | Valida HTTPS | Passa link | fonte hostil | N/A | widget parcial | Host arbitrário aceito. |
| LIV-18 | Livelo | Poll após refresh manual | PARCIAL | 30 s sem teto | resumo/catalogo | workflow | GitHub/DB | widget parcial | Pode continuar indefinidamente. |
| LIV-19 | Livelo | Painel antigo + catálogo novo | DUPLICADO | Duas telas/controllers | Duas rotas | Duas consultas | mesmos retratos | ambos testados | Nova é autoritativa mobile. |
| LIV-20 | Livelo | Funções antigas de banco | NÃO USADO | N/A | Sem rota ativa | Declaradas | Postgres | testes pontuais | Sem referências. |
| LIV-21 | Livelo | Loading/vazio/erro/atraso/ausência | FEITO | Sim | Envelope | Sim | Postgres | widgets | Estados distintos. |
| INT-01 | Inter Sites | Extração/identidade/limiar | FEITO | N/A | N/A | Sim | fonte Inter | Pytest | Catálogo real. |
| INT-02 | Inter Sites | Snapshot atômico e último válido | FEITO | Exibe fallback | API expõe tentativa | Sim | Postgres | Pytest/widgets | Falha não apaga sucesso. |
| INT-03 | Inter Sites | Frequência 3×/dia + manual | QUEBRADO | N/A | disparo | `on: push` extra | GitHub | análise | Consultas além do contrato. |
| INT-04 | Inter Sites | Paginação integral | PARCIAL | Recebe página | Pagina | lista toda em memória | Postgres | Vitest/widget | Não pagina consulta DB. |
| INT-05 | Inter Sites | Ranking financeiro exato | QUEBRADO | BigInt local | TS `Number` | duplicado | NUMERIC | testes separados | Viola regra sem double. |
| INT-06 | Inter Sites | Zero/ausência/não encontrada | FEITO | Sim | Sim | Sim | snapshot | widgets/Pytest | Estados distintos. |
| INT-07 | Inter Sites | Acompanhar/favoritar | FEITO | Otimista/rollback | PATCH admin | valida | `favorita_inter` | widget/Vitest | Persistente. |
| INT-08 | Inter Sites | Aba acessível ao usuário comum | QUEBRADO | Aba visível | GET exige admin | 403 | `loja_inter` | análise | Usuário comum vê erro inevitável. |
| INT-09 | Inter Sites | Filtros globais do catálogo | QUEBRADO | Filtra páginas locais | Sem filtro favorita global | N/A | catálogo paginado | widget não cobre páginas | Resultado enganoso. |
| INT-10 | Inter Sites | Melhor oferta entre acompanhadas | QUEBRADO | Não filtra favorita | primeira página | N/A | snapshot | análise | Regra do PRD violada. |
| INT-11 | Inter Sites | Abrir Shopping Inter | NÃO FEITO | Sem ação | N/A | Constante sem uso | N/A | nenhum | Jornada ausente. |
| INT-12 | Inter Sites | Refresh manual no mobile | NÃO FEITO | Oculto | Suportado | Suportado | GitHub | desktop/widget | Backend sem consumidor mobile. |
| INT-13 | Inter Sites | Abas Cashback/Sites equivalentes | DUPLICADO | Duas UIs | Duas leituras | Lógicas diferentes | mesmas lojas | widgets | Permissão/filtros divergem. |
| INT-14 | Inter Sites | Ranking Python | NÃO USADO | N/A | N/A | Só teste | N/A | Pytest | Produção usa TS. |
| INT-15 | Inter Sites | `LINK_SHOPPING_INTER` | NÃO USADO | Sem consumidor | N/A | Constante | N/A | só Vitest | Reflete ação não implementada. |
| INT-16 | Inter Sites | Condições principal/secundária | FEITO | Card | DTO completo | extrai/persiste | snapshot | widget/Pytest | Ausência recebe texto honesto. |
| INT-17 | Inter Sites | Falha recente/atraso | FEITO | Sim | Metadados | Sim | execuções | widgets/Vitest | Último sucesso preservado. |
| PRO-01 | Compre direto | Sincronizar vendedores | FEITO | Admin lê | GET lojas | fonte real | `loja_direta_inter` | Pytest | Identidade persistida. |
| PRO-02 | Compre direto | Selecionar lojas | FEITO | Toggle/rollback | PATCH admin | valida | Postgres | widget/Vitest | Seleção não coleta. |
| PRO-03 | Compre direto | Exibir estado/páginas por loja | PARCIAL | DTO ignora | API envia | SQL envia | execuções | API teste parcial | Funcionalidade backend não usada. |
| PRO-04 | Produtos | Paginar toda fonte | FEITO | N/A | N/A | offset/searchId | Inter | Pytest | Detecta repetição/limite. |
| PRO-05 | Produtos | Retry total variável e dedupe | FEITO | N/A | N/A | até 3/melhor candidato | Inter | Pytest | Marca degradada. |
| PRO-06 | Produtos | Publicação atômica por loja | FEITO | Lê snapshot | Lê DB | transação/staging | Postgres | Pytest | Falha preserva anterior. |
| PRO-07 | Produtos | Degradada preserva ausentes | FEITO | Exibe qualidade | API | Sim | Postgres | Pytest | Não desativa falsamente. |
| PRO-08 | Produtos | Consolidar sucesso/parcial/falha | FEITO | Resumo | API | Sim | execuções | Pytest/Vitest | Estados distintos. |
| PRO-09 | Produtos | Agenda e concorrência | FEITO | N/A | manual possível | matriz max 2 | GitHub | análise | Três janelas, sem push. |
| PRO-10 | Produtos | Recuperar execução abandonada | PARCIAL | Mostra atualizando | Reflete última | Sem timeout/stale | execuções | nenhum | Pode ficar iniciada. |
| PRO-11 | Produtos | Busca somente no banco | FEITO | HTTP API | GET | SQL | Postgres | unit/widget/Vitest | Sem consulta externa. |
| PRO-12 | Produtos | Normalização/sinônimo | FEITO | Envia texto | TS | Python/TS | `nome_busca` | Pytest/Vitest | `celular→smartphone`. |
| PRO-13 | Produtos | Mínimo 2 chars/debounce | FEITO | 350 ms | valida | Sim | N/A | unit/widget | Compatível. |
| PRO-14 | Produtos | Filtros e paginação SQL | FEITO | Sim | parâmetros iguais | SQL | Postgres | unit/widget | Marca/categoria/loja/preços. |
| PRO-15 | Produtos | Dinheiro como string | FEITO | Formata sem double | string | Decimal/NUMERIC | Postgres | unit/Pytest | Ausência não vira zero. |
| PRO-16 | Produtos | Frescor/qualidade por resultado | PARCIAL | Exibe um estado | global | última execução global | múltiplas lojas | Vitest parcial | Pode rotular conjunto incorretamente. |
| PRO-17 | Produtos | Oferta atual pela última medição | FEITO | Recebe | SQL lateral | Sim | medições | análise/Pytest | Autoritativo. |
| PRO-18 | Produtos | Tabela `oferta_direta_inter_atual` | NÃO USADO | N/A | N/A | N/A | vazia/sem consultas | aceite limpeza | Legado estrutural. |
| PRO-19 | Produtos | Funções antigas/formatação TS | NÃO USADO | N/A | rota não usa | Declaradas | Postgres | testes isolados | Busca antiga LIMIT 500. |
| PRO-20 | Produtos | Histórico paginado/min/max/30d | FEITO | Tela/retry | GET | SQL/expurgo | medições | widget/Pytest | Preserva página anterior. |
| PRO-21 | Produtos | Informar produto inativo | PARCIAL | Ignora `ativo` | Envia | SQL | produto | nenhum widget | Estado previsto não aparece. |
| PRO-22 | Produtos | Link Shopping seguro | FEITO | Host fixo/launcher | caminho | valida origem no robô | Inter | unit/widget | Erro é apresentado. |
| PRO-23 | Produtos | Refresh manual mobile | NÃO FEITO | Oculto no compacto | Suportado | Suportado | GitHub | nenhum mobile | Backend sem consumidor mobile. |
| PRO-24 | Produtos | Loading/vazio/erro/retry | FEITO | Sim | Envelope | Sim | Postgres | widgets | Inclusive erro ao carregar mais. |
| ADM-01 | Administração | CRUD/regras Livelo | FEITO | Sim | GET/POST/PATCH/DELETE | valida | Postgres | widget/Vitest | Completo. |
| ADM-02 | Administração | Preferências Livelo | FEITO | Sim | GET/PATCH | valida | Postgres | widget/Vitest | Completo. |
| ADM-03 | Administração | Favoritas Sites parceiros | FEITO | Sim | GET/PATCH | valida | Postgres | widget/Vitest | Completo para admin. |
| ADM-04 | Administração | Seleção Compre direto | FEITO | Sim | GET/PATCH | valida | Postgres | widget/Vitest | Completo. |
| ADM-05 | Administração | Disparo idempotente | FEITO | Chave opaca | GET/POST | reserva/GitHub | Postgres/Actions | unit/Vitest | Backend correto. |
| ADM-06 | Administração | Cooldown no cliente | PARCIAL | Não absorve erro | Envia espera | Sim | Postgres | unit parcial | Retry inútil possível. |
| ADM-07 | Administração | Limpeza operacional | INCERTO | Confirmação | GET/POST | transação | Postgres | unit; aceite pulado | Não testada destrutivamente. |
| ADM-08 | Administração | Confirmar remoção de loja direta | PARCIAL | Sem confirmação | PATCH | Persiste | Postgres | widget | Diverge do PRD. |
| ADM-09 | Administração | Disparo antigo e novo | DUPLICADO | Usa novo | Usa novo | Ambos existem | três tabelas | testes | Novo é autoritativo. |
| ADM-10 | Administração | Tabelas/funções de disparo antigas | NÃO USADO | N/A | Sem consumidor | Sem chamadas | `disparo_manual*` | limpeza apenas | Legado. |
| ADM-11 | Administração | Frase/papel/isolamento na limpeza | FEITO | Sim | Sim | Sim | tabelas por domínio | unitários | Código consistente. |
| DB-01 | Banco | Migrations 001–015 aplicadas | FEITO | N/A | Compatível | Compatível | verificado read-only | introspecção | Docs estão atrasadas. |
| DB-02 | Operação | Dados/coletas disponíveis no banco consultado | QUEBRADO | Mostraria sem dados | Resumo vazio | Nenhuma execução | tudo zero | consulta read-only | Sistema sem conteúdo operacional. |
| DB-03 | Banco | Constraints/FKs/NUMERIC | FEITO | strings | strings | valida | Postgres | introspecção/testes | Exceto cascade histórico indevido. |
| DB-04 | Banco | Retenção produto 30 dias | FEITO | Histórico | API | expurgo | medições | Pytest | Implementada. |
| DB-05 | Banco | Retenção auditoria 30 dias | FEITO | N/A | auth | limpeza oportunista | auditoria | Vitest | Implementada. |
| DB-06 | Operação | Vercel usa o banco consultado | INCERTO | URL aponta Vercel | Deployment externo | env não legível | credencial local | curl/SQL separados | Não há prova de identidade. |
| OPS-01 | Operação | API dispara workflows corretos | FEITO | Admin | nomes fixos | GitHub client | Actions | Vitest/análise | Livelo/inter/produtos mapeados. |
| OPS-02 | Operação | Secrets e últimas execuções GitHub | INCERTO | N/A | depende token | depende Actions | GitHub | não acessado | Configuração externa não provada. |
| OPS-03 | CI | Workflow respeita ciclo mobile | PARCIAL | N/A | N/A | `app-robo.yml` | Actions | análise | Ainda roda goldens, todos testes e build Web. |
| TST-01 | Qualidade | Flutter analyze | FEITO | — | — | — | — | passou | Sem issues. |
| TST-02 | Qualidade | Widgets/unitários mobile selecionados | QUEBRADO | 1 falha | — | — | — | 135 passaram, 1 falhou no lote principal; 39 adicionais passaram | Falha tema/gaveta. |
| TST-03 | Qualidade | API tipos/lint/unitários | FEITO | — | — | — | — | 94 passaram | Aceite destrutivo excluído. |
| TST-04 | Qualidade | Robô lint/unitários | FEITO | — | — | — | — | Ruff + 178 passaram | Sem rede. |
| TST-05 | Qualidade | Aceite limpeza descartável | INCERTO | — | — | — | banco descartável | não executado | Categoria destrutiva/integrada proibida. |
| TST-06 | Qualidade | PNGs de falhas antigas | NÃO USADO | N/A | N/A | N/A | arquivos | não executados | Artefatos preservados. |
| DOC-01 | Documentação | Fontes mobile atuais | FEITO | protótipo/spec/plano | N/A | N/A | N/A | comparação | Hierarquia principal coerente. |
| DOC-02 | Documentação | `PENDENCIAS.md` reflete código/banco | PARCIAL | Fases antigas | N/A | N/A | migrations já aplicadas | comparação | Checklist contraditório/desatualizado. |
| DOC-03 | Documentação | README API/fluxo de e-mail | PARCIAL | N/A | README | SMTP ausente | senha sem uso | busca de referências | Canal antigo não existe. |
| DEV-01 | Desenvolvimento | Preview Inter mockado | NÃO USADO | Segundo `main` | Cliente falso | N/A | JSON hardcoded | nenhum produção | Ferramenta manual, não funcionalidade real. |

# RESUMO FINAL

## FUNCIONALIDADES COMPLETAS

Arquitetura API-only; separação dos três domínios; login, convite, verificação, reset e logout; autorização admin; rate limit/auditoria; navegação e retenção de estado; resumo/polling; persistência do tema; coleta e regras centrais Livelo; coleta atômica de cashback; coleta/pesquisa/histórico de produtos; CRUD administrativo; disparos idempotentes no backend; schema/migrations; estados de loading/vazio/erro; testes API/robô e análise Flutter.

## FUNCIONALIDADES PARCIAIS

Erros HTTP, auditoria de exceções, organização de segredos, central resumida de alertas, paginação Livelo/cashback apenas após carga integral no servidor, diagnóstico Livelo não exposto, validação de link Livelo, polling manual sem teto, metadados de lojas diretas descartados, execução abandonada sem recuperação, qualidade global de produtos, produto inativo não exibido, cooldown não incorporado, confirmação de remoção e documentação/CI desatualizados.

## FUNCIONALIDADES NÃO IMPLEMENTADAS

Histórico/lidos/não lidos de alertas, Segurança e acesso, Integrações, pontos anteriores Livelo, abertura do Shopping Inter em Sites parceiros e refresh manual de cashback/produtos no mobile compacto.

## FUNCIONALIDADES QUEBRADAS

Histórico Livelo apagável ao desacompanhar; teste/jornada de tema pela gaveta; frequência Inter adicional em push; ranking financeiro TS com `Number`; aba Sites parceiros para usuário comum; filtros globais aplicados somente às páginas carregadas; melhor oferta sem filtrar acompanhadas; banco consultado sem dados/coletas.

## DUPLICAÇÕES

Painel/catálogo Livelo; Cashback/Sites parceiros no hub; ranking decimal em Python/TS/Flutter; disparos antigos/novos.

## CÓDIGO NÃO UTILIZADO/LEGADO

Health no app, preview mockado, ranking Python, link Shopping Inter, tabela oferta atual, busca de produtos antiga, helpers TS de formatação, funções antigas de lojas/disparos, tabelas `disparo_manual*` e PNGs de falhas antigas.

## PROBLEMAS DE COMUNICAÇÃO FLUTTER ↔ BACKEND

Não há rota Flutter inexistente. Há: health com campo divergente e sem uso; aba usuário chamando endpoint admin; metadados de lojas diretas e `ativo` de produto ignorados; cooldown não consumido; endpoints de refresh sem consumidor compacto; 500 potencialmente não JSON; alertas sem endpoint próprio.

## REGRAS DE NEGÓCIO INCONSISTENTES

Ranking cashback com ponto flutuante, melhor oferta fora das acompanhadas, filtros paginados tratados como globais, desacompanhar apagando histórico, Inter coletando em push e diagnóstico Livelo não alterando o estado publicado.

## PONTOS INCERTOS

App Check no deployment/build distribuído; identidade entre banco local e Vercel; secrets/estado recente do GitHub Actions; limpeza em banco descartável; funcionamento com dados reais após primeira carga, pois o banco consultado está vazio.

# PRÓXIMOS PASSOS

## CRÍTICO

1. Corrigir a perda de histórico ao desacompanhar Livelo, incluindo estratégia de FK/migration e teste de regressão de dados.
2. Confirmar qual banco a Vercel e os workflows usam; inicializar/validar coletas reais e investigar por que o banco consultado nunca teve execução.
3. Remover `on: push` do coletor Inter ou formalizar a nova frequência, evitando consumo externo não previsto.
4. Tornar ranking cashback decimal exato no backend e cobrir valores limítrofes.
5. Corrigir filtros/melhor oferta Inter para operar no catálogo completo e somente nas acompanhadas quando a regra exigir.

## ALTO

1. Não expor a aba admin “Sites parceiros” ao usuário comum, ou criar leitura autorizada coerente.
2. Corrigir a composição `DecoratedBox`/`ListTile` da gaveta e restaurar a suíte widget verde.
3. Definir e implementar a central de alertas real (schema, endpoint, DTO, estados lido/não lido) antes de apresentar eventos fictícios.
4. Expor e tratar por loja frescor/qualidade de produtos; recuperar execuções `iniciada` abandonadas.
5. Padronizar erros 500 JSON e consumir cooldown do backend no Flutter.
6. Rever permissões/localização dos `.env` e confirmar App Check antes de torná-lo obrigatório.

## MÉDIO

1. Mover paginação Livelo/cashback para SQL ou justificar/limitar explicitamente o volume.
2. Preservar/exibir `ativo`, execução e páginas das lojas/produtos já enviados pela API.
3. Implementar links/refresh compactos previstos ou remover affordances/documentação correspondente.
4. Fazer RN29 afetar qualidade/estado visível, não apenas log.
5. Dar teto e estado terminal ao polling pós-disparo.
6. Consolidar painel Livelo antigo, abas Inter e regras decimais duplicadas.

## BAIXO

1. Remover ou isolar preview, helpers, tabela e funções legadas somente após confirmação de compatibilidade/migration.
2. Atualizar `PENDENCIAS.md`, README e workflow de CI para o escopo da branch.
3. Limpar artefatos antigos de falha quando houver autorização específica.

# COMANDOS E GATES EXECUTADOS

- `flutter analyze` — passou.
- `flutter test` com 26 arquivos unitários/widgets sem golden/smoke — 135 passaram e 1 falhou (`aparencia_test.dart`).
- 39 widgets adicionais selecionados por nome nos cinco arquivos que também contêm goldens — passaram; nenhum golden/Web foi executado.
- `npm run checar` e `npm run lint` — passaram.
- `vitest run --exclude testes/limpeza-descartavel.teste.ts` — 14 arquivos, 94 testes, todos passaram.
- `ruff check src testes` — passou.
- `pytest -q` — 178 testes, todos passaram.
- `curl` somente GET para health e quatro recusas autenticadas — comportamento descrito acima.
- introspecção SQL em transação `READ ONLY` — schema e contagens descritos acima.
- `git status --short` permaneceu vazio antes da criação deste relatório; nenhum arquivo de projeto foi alterado.

## Divergências/limites restantes

Não foram executados golden, integração, E2E, smoke, performance, Web, migrations, workflows ou limpeza. Não houve login com conta real nem chamada autenticada ao deployment. Não houve coleta contra Livelo/Inter durante a auditoria. Essas operações exigiriam ambiente/efeito externo ou contrariariam o escopo da branch; por isso os pontos correspondentes foram marcados `INCERTO`, não presumidos como feitos.
