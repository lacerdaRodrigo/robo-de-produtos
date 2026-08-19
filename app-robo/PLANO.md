# Plano do `app-robo` — Flutter Web, Android e iOS

**Status:** planejamento aprovado; implementação não iniciada  
**Data-base:** 19 de agosto de 2026  
**Repositório:** `lacerdaRodrigo/robo-livelo`  
**Referência observada na elaboração:** `main` na versão `1.30.2` (`46146c7`)  
**Pasta reservada para a futura implementação:** `app-robo/`

> Este documento registra o plano do piloto. A criação deste arquivo não autoriza criar telas, inicializar o Flutter, alterar banco, API, workflows, notificações ou substituir o site atual. Cada fase de implementação depende de pedido explícito do responsável pelo projeto.

---

## 1. Decisões já aprovadas

1. O novo cliente será desenvolvido em **Flutter**.
2. O mesmo código Flutter atenderá **Web, Android e iOS**, com adaptação responsiva por plataforma e tamanho de tela.
3. O futuro painel Flutter será o único painel de administração do produto.
4. O site atual em `site/` **não será removido nem interrompido durante a construção**.
5. O novo projeto ficará isolado em `app-robo/`.
6. Os robôs Python, o Postgres no Neon e os workflows atuais serão reutilizados. Não haverá cópia dos robôs dentro do Flutter.
7. Durante a transição, site atual e Flutter poderão consultar os mesmos dados e solicitar os mesmos robôs por uma API autenticada.
8. O piloto será fechado: inicialmente uma pessoa, com possibilidade de convidar poucas pessoas depois.
9. O produto terá notificações push automáticas e relatórios por e-mail.
10. Segurança, testes unitários e testes de componentes serão requisitos de primeira classe.
11. A identidade visual seguirá a direção **financeiro confiável**: azul-marinho, verde para ganho e visual sóbrio.

---

## 2. Objetivo

Transformar o Radar de Benefícios atual em um produto multiplataforma sem duplicar regras de negócio, banco ou robôs.

O Flutter deverá permitir consultar e, conforme a permissão, administrar:

- promoções e regras da Livelo;
- cashback dos Sites parceiros do Shopping Inter;
- lojas do Inter escolhidas para acompanhamento;
- produtos do Compre direto no Inter;
- preço atual, desconto, cashback e valor após cashback;
- histórico de 30 dias já previsto para produtos do Inter;
- favoritos, metas e preferências pessoais;
- execuções, filas, resultados e falhas dos robôs;
- alertas push e relatórios por e-mail;
- usuários convidados, aparelhos e sessões, apenas para o administrador.

O piloto deve provar que um único cliente Flutter pode atender Web, Android e iOS sem colocar o sistema atual em risco.

---

## 3. Estado atual que precisa ser preservado

Este plano foi construído a partir do código e da documentação existentes, e não substitui os PRDs atuais.

### 3.1 Componentes existentes

| Componente | Estado observado | Decisão para o piloto |
|---|---|---|
| Robôs | Python 3.11, domínio puro e adaptadores de I/O | Reutilizar sem copiar para o Flutter |
| Banco | Postgres no Neon | Continuar como fonte compartilhada de dados |
| Site | Next.js 15, React 19, TypeScript, publicado pela Vercel | Manter funcionando durante toda a transição |
| Livelo | Workflow `.github/workflows/robo.yml` | Manter isolado; horários atuais e disparo manual |
| Inter — Sites parceiros | Workflow `.github/workflows/inter.yml` | Manter isolado da Livelo e de produtos |
| Inter — Compre direto | Workflow `.github/workflows/produtos-inter.yml` | Manter matriz dinâmica e `max-parallel: 2` |
| Testes | Pytest/Ruff no robô e Vitest/TypeScript/build no site | Acrescentar Flutter sem enfraquecer os gates atuais |
| E-mail atual | Gmail via `smtplib`, conforme os documentos atuais | Não desligar antes da nova solução estar validada |
| Autenticação atual | Senha administrativa única e cookie assinado | Manter no site legado; criar autenticação por usuário para o Flutter |

### 3.2 Contratos que continuam obrigatórios

- O núcleo dos robôs não faz I/O; o mundo entra por portas/adaptadores.
- Dinheiro, cashback e pontuação não passam por `float`; usar `Decimal`/`NUMERIC` e representar valores com segurança nos contratos JSON.
- Textos obtidos de fontes externas são hostis e nunca são interpretados como HTML.
- Nenhum segredo aparece em log, repositório, bundle web, APK ou IPA.
- Os robôs não autenticam na Livelo nem no Banco Inter.
- Não haverá CAPTCHA, rotação de proxy ou técnica de evasão de bloqueio.
- Se uma fonte bloquear ou pedir interrupção, a integração afetada para; as demais permanecem isoladas.
- O Flutter nunca consulta diretamente Livelo ou Inter. Ele lê os dados persistidos pela API do produto.
- O Flutter nunca acessa o Neon nem dispara o GitHub Actions diretamente com um token embarcado.
- Falha recente, ausência de dados, dado atrasado, coleta parcial e valor zero são estados diferentes.
- Uma ação administrativa sempre deve ser revalidada no servidor, mesmo que o botão esteja escondido no cliente.

---

## 4. Arquitetura-alvo

```mermaid
flowchart TD
    Flutter["Flutter: Web, Android e iOS"] --> API["API autenticada"]
    Site["Site Next.js atual"] --> API
    API --> Neon["Postgres Neon"]
    API --> Actions["GitHub Actions"]
    Actions --> Robos["Robôs Python"]
    Robos --> Neon
    Robos --> Eventos["Eventos de notificação"]
    Eventos --> Canais["FCM e e-mail"]
```

### 4.1 Princípios

- **Uma regra, uma fonte:** cálculo, seleção, disparo, autorização e persistência não serão reimplementados em dois clientes.
- **Flutter é cliente:** apresenta dados, coleta intenção e chama contratos HTTP.
- **Servidor decide:** autenticação, autorização, cooldown, idempotência e validação ocorrem novamente na API.
- **Robô coleta uma vez:** o resultado gravado no Neon atende site atual, Flutter e notificações.
- **Catálogo completo no servidor, recorte no cliente:** o robô grava tudo que a fonte expuser para cada loja selecionada; a API pesquisa no banco e entrega somente uma página por resposta.
- **Migração reversível:** nenhuma fase exige apagar o `site/`.
- **Compatibilidade primeiro:** novas tabelas e endpoints serão aditivos enquanto o site legado estiver em produção.

### 4.2 API recomendada para a primeira etapa

A recomendação inicial é expor uma API versionada no backend já publicado com o site, por exemplo `site/app/api/v1/`, reaproveitando o acesso existente ao Neon e o disparo atual em `site/lib/github.ts`. Isso evita contratar e operar um segundo servidor durante o piloto.

Essa recomendação será confirmada em um gate técnico antes do código. Se as limitações reais da hospedagem ou do runtime impedirem push, relatórios ou tarefas necessárias, será produzido um registro de decisão antes de escolher outro backend. Não será criada infraestrutura nova por suposição.

Contratos iniciais esperados, ainda sem assinatura definitiva:

- autenticação e sessão;
- perfil, papel e preferências;
- leitura de Livelo;
- leitura e seleção de lojas do Inter;
- leitura, busca e histórico de produtos;
- favoritos e metas;
- solicitação e consulta de execução dos robôs;
- registro/remoção de token de push;
- central de notificações e relatórios;
- auditoria administrativa.

### 4.3 Coleta completa, busca no banco e paginação da API

Existe uma diferença obrigatória entre **coletar**, **guardar** e **mostrar**:

| Camada | Responsabilidade aprovada |
|---|---|
| Robô | Percorrer todas as páginas que a fonte disponibilizar para cada loja selecionada, sem teto fixo de produtos, e deduplicar por loja + ID externo |
| Banco | Manter o último catálogo válido e gravar uma nova medição de cada produto ativo em toda coleta bem-sucedida, com a retenção de 30 dias definida no PRD V4 |
| API | Pesquisar e filtrar no Postgres, usando o último catálogo válido, e devolver somente uma página de resultados por resposta |
| Flutter | Exibir a página recebida, permitir continuar o garimpo e pedir outras páginas; nunca baixar o catálogo inteiro para pesquisar no aparelho |

Exemplo aprovado: se uma televisão custa R$ 5.000 em uma medição e R$ 4.000 na seguinte, o catálogo atual mostra R$ 4.000 e o histórico do mesmo produto — identificado por loja + ID externo — preserva as duas medições enquanto estiverem dentro dos 30 dias. Se uma busca por `tv` encontrar 200 ofertas, as 200 ficam alcançáveis pelo usuário, mas chegam ao Flutter em páginas, e não em uma única resposta.

Isso não promete o catálogo universal da varejista. O sistema guarda **tudo que a fonte realmente expôs ao robô** nas consultas permitidas e concluídas. Uma limitação ou janela da própria fonte deve ser mostrada com estado honesto, conforme o PRD V4.

#### 4.3.1 Contrato inicial da busca de produtos

Exemplo conceitual, cuja assinatura final será fechada na Fase 1:

`GET /api/v1/inter/produtos?q=tv&page=1&por_pagina=20`

| Campo/regra | Limite inicial aprovado |
|---|---|
| `q` | Obrigatório para a busca do MVP; de 2 a 100 caracteres, permitindo termos como `tv` |
| `page` | Inteiro a partir de 1; padrão 1 |
| `por_pagina` | Padrão 20; máximo 50; não existe `all` nem outro modo sem paginação |
| Filtros | Executados no servidor; loja, marca, categoria e faixa de preço entram apenas com valores e formatos validados |
| Ordenação | Lista fixa aceita pela API; padrão estável por menor preço atual, depois nome e ID |
| Resultado | `itens`, `pagina`, `por_pagina`, `total_itens`, `total_paginas`, `tem_proxima`, horário e qualidade do catálogo |
| Histórico de um produto | Retenção de 30 dias; padrão 30 medições por página e máximo 100 |

Com 200 resultados e o padrão de 20, existem 10 páginas. O usuário pode percorrer todas, refinar por marca — Samsung, LG e outras que existirem no catálogo —, preço, categoria ou loja, sem perder resultados entre páginas. A API nunca corta silenciosamente o total encontrado.

A busca considera nome, marca e categoria persistidos. Sinônimos necessários para a experiência, como `tv`, `televisão` e `televisor`, serão um dicionário pequeno, versionado e coberto por testes; nenhum sinônimo será criado por adivinhação durante uma requisição.

Regras complementares:

- a caixa de busca nunca chama o Inter nem dispara coleta;
- uma coleta nova publica o catálogo por loja de forma atômica e preserva o último sucesso se falhar;
- produto ausente de uma coleta completa deixa de aparecer como oferta atual, mas seu histórico expira normalmente;
- todas as páginas usam a mesma busca, filtros e ordenação; não pode haver item perdido ou duplicado na navegação;
- o Flutter deve cancelar ou ignorar resposta de uma busca antiga quando a pessoa digitar outra;
- o formato exato de cursor/versão do catálogo e os índices do Postgres serão escolhidos na Fase 1 com teste de volume, sem mudar os limites funcionais acima.

### 4.4 Disparo dos robôs

Os workflows atuais continuam sendo os executores oficiais:

- `robo.yml` para Livelo;
- `inter.yml` para cashback de Sites parceiros;
- `produtos-inter.yml` para produtos das lojas escolhidas.

A API poderá solicitar `workflow_dispatch`, mas deverá:

1. exigir usuário autenticado e papel `admin`;
2. aceitar somente workflows conhecidos em lista fixa;
3. nunca aceitar arquivo, branch, URL ou slug arbitrário vindo do cliente;
4. aplicar cooldown e chave de idempotência;
5. impedir rodadas equivalentes simultâneas;
6. registrar solicitante, data, origem, workflow e resultado;
7. devolver estado consultável em vez de manter a tela bloqueada;
8. reler lojas selecionadas do banco, como o fluxo V4 já faz.

### 4.5 Fila e concorrência

O aplicativo mostrará `aguardando`, `em execução`, `sucesso`, `parcial`, `degradada` ou `falha`, conforme o domínio permitir. Uma solicitação repetida não deve criar outra execução equivalente.

O plano preserva a regra da V4: tarefas de produtos são por loja, páginas são sequenciais e há no máximo duas lojas simultâneas no workflow atual.

---

## 5. Usuários, propriedade dos dados e acesso

### 5.1 Modelo de acesso

- Não haverá cadastro público.
- O administrador será o responsável pelo projeto.
- Novas pessoas só entram por convite e e-mail autorizado.
- Papéis iniciais:
  - `admin`: administra usuários, lojas, regras, execuções, relatórios e zona de perigo;
  - `usuario`: consulta dados e administra apenas favoritos, metas e preferências próprias.
- A API é a fonte da autorização; a interface apenas reflete permissões.

### 5.2 Dados globais e pessoais

| Dados globais | Dados pessoais por usuário |
|---|---|
| Catálogo Livelo | Favoritos |
| Catálogo de lojas Inter | Metas de preço/cashback |
| Produtos e medições | Preferências de push e e-mail |
| Estado das coletas | Horário silencioso |
| Cashback e preços | Aparelhos e sessões |
| Histórico técnico | Histórico de notificações destinadas ao usuário |

Esta separação evita repetir milhares de produtos para cada pessoa e impede que favoritos e preferências vazem entre usuários.

### 5.3 Autenticação planejada

Para o piloto, a direção aprovada é autenticação fechada por convite. A proposta técnica é Firebase Authentication, usando um método sem senha própria do projeto ou um provedor suportado. A escolha exata do método de entrada será fechada antes da implementação.

O token emitido pelo provedor deverá ser validado pela API. Existir no provedor não basta: o e-mail também precisa estar autorizado e o perfil precisa estar ativo no banco do produto.

---

## 6. Segurança

### 6.1 Controles obrigatórios

- HTTPS em toda comunicação.
- Token de acesso curto e renovação conforme o provedor escolhido.
- Sessão revogável e opção de encerrar todas as sessões.
- Registro e remoção de aparelhos.
- Aviso de novo aparelho ou novo acesso quando tecnicamente disponível.
- Tokens sensíveis no armazenamento seguro da plataforma; nada sensível em preferências comuns.
- Firebase App Check planejado para Web, Android e iOS, sem tratá-lo como substituto da autenticação.
- Autorização por função e por proprietário do dado em cada endpoint.
- Rate limit por usuário, IP e operação sensível.
- Idempotência para ações repetíveis, especialmente disparos e notificações.
- Reautenticação ou confirmação reforçada para limpeza de domínio, revogação de usuários e outras ações destrutivas.
- Lista fixa de tabelas e transação atômica nas limpezas já definidas no PRD V5.
- Cabeçalhos de segurança, CORS restrito e validação explícita de origem no Web.
- Validação de esquema, tamanho, paginação e caracteres de todas as entradas.
- Logs estruturados com identificadores técnicos, nunca payload completo, credenciais ou dados desnecessários.
- Auditoria de login, convite, alteração de papel, disparo, exclusão, troca de preferências e envio de relatório.
- Dependências fixadas por lockfile e revisão automática de vulnerabilidades.
- Revisão orientada pelo OWASP MASVS para armazenamento, autenticação, rede, plataforma, código e privacidade.

### 6.2 Segredos

Segredos permitidos apenas no servidor ou em cofres das plataformas:

- `DATABASE_URL`;
- token de disparo do GitHub;
- credencial do provedor de e-mail;
- credencial de serviço para envio FCM;
- segredo de sessão/API;
- credenciais de assinatura e publicação.

Arquivos de configuração pública necessários ao SDK móvel não serão confundidos com credencial de serviço. Mesmo quando uma chave for pública por natureza, suas permissões e restrições deverão ser configuradas.

### 6.3 Privacidade e LGPD

Os PRDs atuais registram uso estritamente pessoal. Ao convidar outra pessoa, essa premissa muda. Antes do primeiro convite externo, o gate de privacidade exige:

- atualizar a análise de LGPD dos documentos atuais;
- publicar política de privacidade curta e clara;
- explicar quais dados são guardados e por quanto tempo;
- permitir revogar sessão, aparelho e notificações;
- permitir excluir os dados pessoais do usuário sem apagar os catálogos globais;
- limitar o conteúdo do push na tela bloqueada;
- não usar dados para publicidade ou finalidade não documentada.

---

## 7. Notificações push

### 7.1 Canal

Usar Firebase Cloud Messaging para Android, iOS e, se aprovado no gate do navegador, Web. O envio parte do servidor; o Flutter apenas solicita permissão, registra o token do aparelho e trata a abertura da notificação.

### 7.2 Eventos candidatos

- promoção Livelo cruza a regra do usuário;
- cashback de uma loja acompanhada cruza a meta definida;
- produto favorito alcança o preço ou valor após cashback desejado;
- queda relevante de preço;
- coleta solicitada termina;
- coleta falha ou fica degradada;
- dado acompanhado fica atrasado;
- novo aparelho ou evento de segurança.

Nenhum desses eventos será ativado por suposição. Cada regra precisa de requisito, dado disponível e teste antes de ser habilitada.

### 7.3 Anti-spam e confiabilidade

- Não reenviar o mesmo evento sem mudança relevante.
- Criar uma chave de idempotência por usuário, regra, entidade e estado observado.
- Respeitar horário silencioso e canal preferido.
- Permitir desligar categorias de notificação.
- Não incluir preço ou dado pessoal sensível na tela bloqueada quando o usuário escolher modo discreto.
- Ao tocar, abrir diretamente a entidade correspondente por deep link autenticado.
- Token inválido é removido; troca de usuário remove o vínculo local anterior.
- Falha no push não reverte uma coleta já publicada.

### 7.4 Caixa de saída de eventos

A implementação deve preferir uma caixa de saída persistente (`outbox`) gravada junto do resultado que origina a notificação. Um despachante envia FCM/e-mail e marca o evento como processado. Isso reduz perda e duplicação quando o processo termina entre gravar o preço e enviar a mensagem.

O schema e o executor da outbox serão decididos em migração própria; este documento não cria tabela.

---

## 8. Relatórios por e-mail

### 8.1 Entregas planejadas

- relatório diário automático;
- relatório manual solicitado pelo painel;
- relatório semanal como evolução posterior;
- aviso técnico de falha para o administrador.

O horário do relatório diário ainda será escolhido. Ele deve considerar o fim das últimas coletas do dia, especialmente o workflow de produtos, que começa depois dos demais.

### 8.2 Conteúdo do relatório

- melhores promoções Livelo;
- maiores cashbacks das lojas acompanhadas;
- produtos que atingiram metas;
- principais quedas de preço;
- quantidade de produtos e lojas atualizados;
- execuções com sucesso, degradação ou falha;
- dados atrasados;
- economia potencial, sempre rotulada como estimativa.

### 8.3 Provedor e transição

A proposta para o novo canal é Resend, sujeito a domínio verificado e validação do plano gratuito no momento da implementação. O Gmail atual não será desligado antes de o novo relatório ser entregue e conferido de verdade.

As lições de `docs/EMAIL.md` continuam válidas: e-mail deve ser verificado no cliente real, não somente no preview; HTML precisa ser compacto, textos externos escapados e imagens remotas controladas.

---

## 9. Funcionalidades do piloto

### 9.1 MVP

- login fechado;
- painel geral;
- consulta Livelo;
- consulta cashback Inter;
- seleção e descarte de lojas do Inter;
- seleção de lojas para coleta de produtos;
- pesquisa de produtos no catálogo persistido, por API paginada, sem baixar o catálogo inteiro no aparelho;
- preço, desconto, cashback e valor após cashback;
- histórico de 30 dias existente;
- favoritos e preferências pessoais;
- disparo administrativo dos robôs;
- status, duração, contagens e falhas;
- push configurável;
- relatório diário e manual;
- administração básica de convites, sessões e aparelhos;
- auditoria das ações administrativas.

### 9.2 Evoluções posteriores

- comparador entre lojas considerando preço, cashback e pontos quando houver uma regra documentada de conversão;
- metas de compra mais avançadas;
- priorização de favoritos na experiência, sem aumentar a pressão na fonte sem análise;
- relatório semanal;
- compartilhamento interno de oportunidade;
- centro de diagnóstico e exportação de logs sanitizados;
- tema escuro completo;
- central histórica de alertas.

### 9.3 Fora do piloto

- compra automática;
- carrinho, frete ou cálculo por CEP;
- autenticação na Livelo ou no Banco Inter;
- coleta disparada pela caixa de pesquisa do usuário;
- acesso direto do app a banco, Actions, Livelo ou Inter;
- cadastro público;
- monetização, publicidade ou abertura irrestrita;
- remoção do sistema atual antes do aceite final;
- unificação automática de produtos sem identificador confiável;
- afirmação de “melhor preço do mercado” com base apenas nas lojas monitoradas.

---

## 10. Experiência e design

### 10.1 Direção aprovada

**Financeiro confiável:** visual sóbrio, hierarquia forte, leitura rápida e destaque para valores que ajudam a decidir.

### 10.2 Paleta inicial

| Papel | Cor | Uso |
|---|---|---|
| Azul-marinho | `#102A43` | marca, menu, títulos e superfícies institucionais |
| Azul de ação | `#1769AA` | botões, links, foco e seleção |
| Verde de ganho | `#16803C` | cashback, economia, meta atingida e sucesso |
| Âmbar | `#B7791F` | atenção e dado envelhecendo |
| Vermelho | `#C53030` | erro e ação destrutiva |
| Fundo | `#F5F7FA` | fundo claro neutro |

Esses valores são tokens iniciais aprovados para o plano. Contraste deverá ser medido antes de congelar o tema em código.

### 10.3 Regras visuais

- Cards brancos, borda discreta, pouco efeito e espaçamento consistente.
- Preço atual escuro, grande e em negrito.
- **Após cashback em verde, grande e em negrito, com o mesmo peso visual do preço atual.**
- Economia pode aparecer como selo “Você economiza R$ X”, quando derivada de valores da mesma medição.
- Verde significa ganho/sucesso; não será usado para esconder funcionalidade nem para ação neutra.
- Vermelho fica reservado a erro e zona de perigo.
- Estado nunca será comunicado somente pela cor: usar texto e ícone.
- Números e datas usam formatação `pt-BR`, sem conversão monetária por `double`.
- Loading, vazio, atraso, falha, parcial e sem permissão terão estados próprios.
- Uma mutação não pode causar tela branca, salto para o topo ou perda silenciosa da página/filtro atual.
- Confirmações destrutivas devem dizer claramente o alvo e permitir cancelar.

### 10.4 Navegação adaptativa

No celular, a direção inicial é barra inferior com:

1. Início;
2. Livelo;
3. Inter;
4. Alertas;
5. Mais.

No Web, as mesmas áreas aparecem em menu lateral azul-marinho. Produtos, lojas e configurações ficam como destinos internos de Inter/Mais, sem sobrecarregar a navegação principal.

O layout não será apenas o site comprimido. Largura, densidade, alvo de toque e prioridade de conteúdo se adaptam ao dispositivo.

### 10.5 Dashboard

O painel inicial deve priorizar:

- promoções Livelo ativas;
- melhores cashbacks acompanhados;
- produtos monitorados;
- metas atingidas;
- última coleta e frescor por domínio;
- coletas em andamento;
- falhas que precisam de ação.

Os totais exibidos precisam ser reais e explicar o recorte: lojas encontradas, lojas escolhidas, produtos retornados ou produtos monitorados não são o mesmo número.

### 10.6 Acessibilidade

- contraste verificável;
- alvos de toque adequados;
- suporte a aumento de texto;
- foco visível e navegação por teclado no Web;
- rótulos semânticos para leitores de tela;
- orientação e tamanhos diferentes testados;
- animações reduzidas quando o sistema solicitar;
- mensagens claras em português, sem exigir vocabulário de PRD.

---

## 11. Estrutura futura do Flutter

Estrutura conceitual, a confirmar quando o projeto for inicializado:

```text
app-robo/
├── lib/
│   ├── app/                 # inicialização, rotas e tema
│   ├── core/                # contratos e utilidades realmente compartilhados
│   └── features/            # Livelo, Inter, produtos, alertas, conta
├── test/                    # unitários, widgets e goldens
│   ├── fixtures/
│   └── goldens/
├── integration_test/        # jornadas críticas
├── web/
├── android/
├── ios/
└── README.md
```

O gerenciador de estado, roteador, cliente HTTP, serialização e armazenamento seguro serão escolhidos somente na fase de bootstrap, comparando manutenção, suporte Web/mobile, testabilidade e documentação oficial. Este plano não fixa bibliotecas nem versões antes dessa validação.

---

## 12. Estratégia de testes

### 12.1 Princípio

O Flutter seguirá uma pirâmide com **muitos testes unitários e de widgets/componentes**, acompanhada por integração apenas nas jornadas críticas. O CI não tocará fontes reais, Neon de produção, GitHub real, FCM real ou e-mail real.

### 12.2 Camadas

| Camada | Cobertura planejada |
|---|---|
| Unitários Dart | formatação, busca, filtros, paginação, cashback, metas, anti-spam, permissões e estados |
| Widget/componentes | cards, valores, botões, modais, listas, paginação, loading, vazio, falha, responsividade e acessibilidade |
| Golden | cards e componentes críticos nos tamanhos aprovados; poucas telas-chave para evitar testes frágeis |
| Integração Flutter | login, consulta, acompanhar/descartar, disparar robô, consultar status, favorito e preferências |
| Contrato da API | request/response, erros, paginação, compatibilidade e idempotência |
| API | autenticação, autorização, validação, rate limit, cooldown e auditoria |
| Banco descartável | isolamento por usuário, transações, outbox, retenção e rollback |
| Robôs Python | preservar e ampliar Pytest/fakes/fixtures existentes |
| Segurança | acesso indevido, IDOR, payload hostil, repetição, token revogado e ausência de segredos |

### 12.3 Casos de regressão herdados dos commits recentes

- Acompanhar ou descartar loja não pode recarregar com tela branca.
- A ação deve preservar página, busca, ordenação e posição útil da navegação.
- Paginação deve mostrar dez itens quando esse for o contrato da tela e permitir chegar a todo o catálogo.
- O total deve distinguir vendedores/lojas de produtos retornados.
- Disparo de produtos com lojas selecionadas deve gerar as tarefas corretas.
- Rodada sem lojas deve terminar de modo controlado, sem execução enganosa.
- Preço “após cashback” deve ter destaque equivalente ao preço atual.
- Confirmação deve nascer de ação explícita e não reabrir em loop.
- Botão em processamento não deve criar disparo duplicado.
- Uma coleta com 3.310 produtos pode persistir todos eles, enquanto a resposta padrão da busca contém no máximo 20 itens.
- Uma busca com 200 resultados deve permitir percorrer dez páginas de 20 sem lacunas nem duplicações.
- Buscar `tv` deve encontrar os modelos compatíveis presentes no catálogo e permitir refinar por marca, categoria, loja e preço.
- Quando o preço muda de R$ 5.000 para R$ 4.000, o atual e as duas medições do histórico devem permanecer coerentes.

### 12.4 Gates do CI

- `flutter analyze` sem erro;
- formatação Dart verificada;
- testes unitários e de widgets;
- cobertura mínima de **90% nas regras de domínio, casos de uso e serviços críticos do Flutter**;
- testes golden aprovados deliberadamente;
- testes de integração críticos em ambiente controlado;
- build Flutter Web;
- build Android de validação;
- build iOS em runner compatível quando essa fase começar;
- Pytest com o gate atual de 90% e Ruff continuam verdes;
- TypeScript, Vitest e build do site legado continuam verdes enquanto ele existir;
- nenhum teste de CI acessa a rede real das fontes.

Todo bug corrigido deve receber teste de regressão antes do merge.

---

## 13. Observabilidade e operação

- Cada tela de domínio mostra quando os dados foram atualizados.
- O administrador vê última tentativa e último sucesso separadamente.
- Execução mostra duração, páginas, itens lidos, únicos, duplicados e qualidade quando disponíveis.
- Alertas internos distinguem falha do robô, falha de notificação e falha de relatório.
- IDs de correlação ligam solicitação da API, execução do workflow, gravação e envio.
- Métricas de volume protegem os planos gratuitos: usuários ativos, tokens, pushes, e-mails, armazenamento e tempo de Actions.
- Limites operacionais geram aviso antes de virar cobrança ou indisponibilidade.
- Logs exportados pelo painel serão sanitizados.
- Backup e restauração terão procedimento testado antes de qualquer limpeza em produção.

---

## 14. Custos e distribuição

O objetivo é operar o piloto dentro das faixas gratuitas, mas “grátis” não será tratado como garantia permanente. Limites e preços devem ser conferidos novamente no gate de publicação.

| Item | Direção do piloto | Observação |
|---|---|---|
| Flutter | Código aberto | Um código para Web, Android e iOS |
| FCM | Faixa sem custo | Push parte do servidor |
| Firebase Authentication | Faixa sem custo para poucos usuários | Não usar autenticação por telefone paga |
| Firebase App Check | Recurso sem custo na tabela consultada | Complementa, não substitui autenticação |
| Resend | Plano gratuito, se domínio e limites servirem | Gmail atual permanece até o aceite |
| Neon | Plano atual | Medir crescimento de histórico e eventos |
| GitHub Actions | Uso atual | Monitorar minutos e duração por loja |
| Vercel | Projeto atual | Confirmar capacidade da API antes de depender dela |
| Google Play | Publicação oficial | Taxa única de US$ 25 observada na documentação oficial |
| Apple App Store | Publicação oficial | Apple Developer Program de US$ 99 por ano |

Android pode ser testado por instalação direta antes da Play Store. iOS exige ferramentas e regras da Apple; distribuição oficial e TestFlight entram somente na fase própria.

---

## 15. Fases de execução

### Fase 0 — Planejamento

**Entrega:** este documento.  
**Não inclui:** código, tela, banco, API ou workflow.

### Fase 1 — Inventário e contratos

- mapear todas as consultas e Server Actions do Next.js;
- classificar leitura pública, leitura autenticada e mutação administrativa;
- documentar contratos JSON e erros;
- fechar busca no servidor, paginação padrão 20/máximo 50, ordenação estável e contrato do histórico;
- decidir estratégia de compatibilidade;
- confirmar API no backend atual ou registrar alternativa;
- definir identificadores do aplicativo e ambientes.

**Saída:** contrato aprovado, sem alterar o comportamento dos robôs.

### Fase 2 — Bootstrap do `app-robo`

- inicializar Flutter para Web, Android e iOS;
- criar tema e tokens do design aprovado;
- definir arquitetura interna e dependências após validação;
- preparar ambientes local/teste/produção;
- configurar análise, testes e CI do Flutter.

**Saída:** aplicativo vazio compilando nos alvos, com testes de fundação; nenhuma tela funcional migrada.

### Fase 3 — API compatível e autenticação

- endpoints versionados;
- autenticação por convite;
- perfis e papéis;
- validação de token no servidor;
- rate limit, auditoria e App Check;
- adaptadores para o site legado continuarem funcionando.

**Saída:** Flutter autenticado lendo dados falsos/controle; site atual intacto.

### Fase 4 — Piloto somente leitura

- Painel;
- Livelo;
- cashback Inter;
- produtos e histórico;
- busca no banco, filtros, frescor, estados e paginação sem catálogo inteiro no cliente;
- testes unitários, widgets, goldens e integração.

**Saída:** você consegue consultar o mesmo dado no Flutter Web/Android sem administrar ainda.

### Fase 5 — Administração compartilhada

- acompanhar e descartar lojas;
- escolher lojas de produtos;
- favoritos, metas e preferências;
- disparar robôs e acompanhar a fila;
- zona de perigo com proteção reforçada.

**Saída:** Flutter administra o backend; Next.js continua disponível como fallback.

### Fase 6 — Push e relatórios

- registro de aparelhos;
- outbox e idempotência;
- FCM;
- preferências e horário silencioso;
- relatório diário/manual;
- validação real em Android, iPhone e cliente de e-mail.

**Saída:** alertas confiáveis, sem repetição e sem derrubar coleta em falha de canal.

### Fase 7 — Segurança e piloto fechado

- testes OWASP selecionados;
- revisão de segredos e permissões;
- política de privacidade antes de convidar terceiros;
- backup/restauração;
- teste inicial somente com o administrador;
- expansão para duas ou três pessoas por convite.

### Fase 8 — Corte controlado

- comparar funções do Flutter com o painel atual;
- smoke Web, Android e iOS;
- confirmar estabilidade de notificações e relatórios;
- publicar Flutter Web como painel principal;
- manter o site atual como fallback pelo período aprovado;
- retirar apenas a interface administrativa legada quando houver decisão explícita.

Nenhuma fase autoriza apagar `site/`. A aposentadoria definitiva será uma decisão separada.

---

## 16. Critérios de sucesso do piloto

1. Web, Android e iOS usam o mesmo projeto Flutter.
2. O site atual continua disponível durante a construção.
3. Os três robôs atuais seguem isolados e atendem os dois clientes na transição.
4. Nenhum segredo está presente no cliente ou nos logs.
5. Usuário comum não executa ações de administrador.
6. Dados pessoais não vazam entre usuários.
7. Push repetido é bloqueado por idempotência.
8. Relatório não é enviado em duplicidade.
9. Falha no FCM/e-mail não apaga nem reverte coleta válida.
10. Preço e valor após cashback pertencem à mesma medição e recebem a hierarquia visual aprovada.
11. Paginação, filtro e posição não são perdidos por uma mutação.
12. Estados vazios, atrasados, parciais, degradados e de erro são honestos.
13. Testes novos e suítes antigas passam no CI.
14. Cobertura crítica do Flutter atinge pelo menos 90%.
15. Custos permanecem dentro dos limites aprovados ou o sistema avisa antes da expansão.
16. Todas as ofertas expostas por uma coleta válida são persistidas, sem teto artificial de 3.000 ou 3.310 produtos.
17. O Flutter recebe no máximo 50 produtos por resposta e consegue alcançar todos os resultados de uma busca por páginas, sem corte silencioso.

---

## 17. Gates que ainda exigem decisão

Estes itens não serão inventados durante a implementação:

- nome público definitivo do aplicativo;
- identificadores Android e iOS;
- método exato de login dentro do Firebase Authentication;
- domínio/remetente do novo relatório por e-mail;
- horário do relatório diário;
- backend definitivo da API após o inventário;
- bibliotecas Flutter de estado, rotas, HTTP e serialização;
- política exata de retenção de auditoria e notificações;
- período em que o Next.js ficará como fallback após o corte;
- quando pagar e publicar na Google Play e na App Store;
- regra matemática para comparar pontos Livelo com cashback em dinheiro.

Cada decisão deverá registrar evidência, impacto, testes e atualização deste plano/PRDs relacionados.

### 17.1 Melhorias recomendadas para discutir no momento certo

Os itens abaixo ficam registrados como **opções recomendadas, não como autorização para implementar agora**. Antes de iniciar cada um, o assistente deve explicar em linguagem simples: o que é, por que ajuda, em qual fase entra, possível custo, risco de não fazer e alternativa mais simples. O responsável decide então se aprova, adia ou descarta.

Uma opção pode virar pré-condição de segurança apenas quando a funcionalidade relacionada for realmente ativada. Exemplo: o relatório por Resend é opcional; se for escolhido para enviar a convidados, verificar um domínio deixa de ser opcional para essa entrega.

| Opção para conversa futura | Por que pode valer a pena | Quando discutir |
|---|---|---|
| Separar seleção operacional de loja e acompanhamento pessoal | Impede que o favorito de um convidado aumente automaticamente o trabalho dos robôs | Fases 1 e 5 |
| Definir consumidor da outbox com retry e fila de falhas | Evita perder ou repetir push/e-mail e não depende de uma função web ficar viva por muito tempo | Antes da Fase 6 |
| Política de compatibilidade entre versão do app e da API | Um celular pode ficar semanas sem atualizar; a API não deve quebrar o aplicativo antigo de surpresa | Fases 1 e 3 |
| Ambientes separados para desenvolvimento, piloto e produção | Teste de login, push, e-mail ou banco não atinge dados reais por engano | Fase 2 |
| Revisar as regras de alerta dos PRDs V3/V4 | Hoje esses documentos não enviam e-mail nem decidem se um preço é bom; qualquer nova regra precisa de limiar, repetição e teste | Antes da Fase 6 |
| Orçamentos de tempo/tamanho da API, índices, lista virtual e cache | Mantém a busca rápida quando o número de lojas e produtos crescer | Fases 1 e 4 |
| Cache somente de leitura, com horário visível | Ajuda em internet ruim sem permitir administração offline ou mostrar dado velho como atual | Depois da Fase 4 |
| Diagnóstico de falhas do app sem dados sensíveis | Facilita descobrir travamentos e relacioná-los à versão do app/API | Fases 2 e 7 |
| Metas de recuperação de backup (RPO/RTO) | Define quanto dado e tempo de indisponibilidade seriam aceitáveis após uma falha | Fase 7 |
| Testes nativos de permissão e recebimento de push | Testes Flutter não controlam sozinhos todos os diálogos e comportamentos do Android/iOS | Fase 6 |
| Persistência segura específica do Flutter Web | Navegador não oferece o mesmo cofre nativo de Android/iOS; exige sessão curta, CSP e estratégia suportada | Fase 3 |
| Validar App Check também na API | Enviar o token pelo app só ajuda se o servidor conferir sua validade | Fase 3 |
| Domínio verificado para o Resend | O domínio de teste atende apenas o dono da conta; convidados exigem remetente próprio validado | Fase 6 |
| Aviso de não afiliação com Livelo e Inter | Reduz confusão de marca nas telas de ajuda e nas listagens das lojas de aplicativos | Fase 8 |
| Requisitos reais de Google Play, TestFlight e aparelho físico | Contas novas e push nativo podem exigir testes, participantes, configuração APNs e dispositivos reais | Antes da publicação |
| Atualização recomendada/obrigatória e feature flags | Permite liberar ou interromper uma função com segurança sem quebrar todos os clientes | Fases 3 e 8 |

### 17.2 Decisões que permanecem abertas na paginação

Os limites funcionais de 20 por padrão e 50 no máximo estão aprovados. Na Fase 1 ainda será explicado e decidido:

- paginação por cursor ou por número de página com versão do catálogo;
- índices de busca adequados ao volume real no Neon;
- orçamento de tamanho e tempo de resposta medido, sem escolher número arbitrário agora;
- comportamento visual entre botão “próxima página” e carregamento progressivo;
- filtros que entram no primeiro MVP além de marca, categoria, loja e preço.

---

## 18. Referências internas

- [`../AGENTS.md`](../AGENTS.md) — instruções de entrada reconhecidas pelo Codex para trabalhar neste repositório.
- [`../CLAUDE.md`](../CLAUDE.md) — regras de arquitetura, segurança e trabalho dos agentes.
- [`../README.md`](../README.md) — visão geral e operação atual.
- [`../docs/PRD.md`](../docs/PRD.md) — fonte principal de requisitos Livelo.
- [`../docs/PRD-V2.md`](../docs/PRD-V2.md) — site, Neon, autenticação e regras de alerta.
- [`../docs/PRD-V3.md`](../docs/PRD-V3.md) — cashback dos Sites parceiros do Inter.
- [`../docs/PRD-V4.md`](../docs/PRD-V4.md) — produtos, paginação, histórico e isolamento por loja.
- [`../docs/PRD-V5.md`](../docs/PRD-V5.md) — limpeza administrativa e zona de perigo.
- [`../docs/PENDENCIAS.md`](../docs/PENDENCIAS.md) — estado real, gates e pendências.
- [`../docs/TESTES.md`](../docs/TESTES.md) — catálogo de testes existente.
- [`../docs/EMAIL.md`](../docs/EMAIL.md) — design e limitações reais do e-mail.
- [`../docs/ARQUITETURA.md`](../docs/ARQUITETURA.md) — histórico das decisões de arquitetura.
- [`../site/README.md`](../site/README.md) — rotas, sessão, Vercel e comportamento do site.
- [`../site/app/design-system.css`](../site/app/design-system.css) — referência visual atual, sem obrigar cópia literal.
- [`../.github/workflows/robo.yml`](../.github/workflows/robo.yml) — Livelo.
- [`../.github/workflows/inter.yml`](../.github/workflows/inter.yml) — cashback Inter.
- [`../.github/workflows/produtos-inter.yml`](../.github/workflows/produtos-inter.yml) — produtos Inter.
- [`../.github/workflows/testes.yml`](../.github/workflows/testes.yml) — quality gates atuais.

### 18.1 Commits recentes usados como lição de regressão

- [`e921769`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e92176928f02de4088921e2d98e07af38d033b19) — preservar paginação e permitir descartar lojas.
- [`3fd0257`](https://github.com/lacerdaRodrigo/robo-livelo/commit/3fd0257f55f35ac787d5d6dbe37becfecaa92904) — valor após cashback com o mesmo destaque do preço atual.
- [`1e66e14`](https://github.com/lacerdaRodrigo/robo-livelo/commit/1e66e148f0028fb6d4cc6a1947fc7a78b19b17d0) — disparar atualização de produtos das lojas selecionadas.
- [`e12225e`](https://github.com/lacerdaRodrigo/robo-livelo/commit/e12225e4a22ab60fd14e4d5ab1ec29fc68813550) — exibir total de lojas encontradas.
- [`dc633de`](https://github.com/lacerdaRodrigo/robo-livelo/commit/dc633def22922494d9f390cc86d80af047082c25) — refletir seleção sem aguardar novo snapshot.

---

## 19. Referências oficiais na Web

Estas referências devem ser reconsultadas nas fases correspondentes; preços, limites e requisitos de loja podem mudar.

### Flutter

- [Plataformas suportadas e integração](https://docs.flutter.dev/platform-integration)
- [Flutter Web](https://docs.flutter.dev/platform-integration/web)
- [Design adaptativo e responsivo](https://docs.flutter.dev/ui/adaptive-responsive)
- [Visão geral de testes](https://docs.flutter.dev/testing/overview)
- [Testes de integração](https://docs.flutter.dev/testing/integration-tests)
- [Segurança no Flutter](https://docs.flutter.dev/security)

### Firebase

- [Firebase Authentication para Flutter](https://firebase.google.com/docs/auth/flutter/start)
- [Firebase Cloud Messaging para Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
- [Receber mensagens no Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)
- [Firebase App Check no Flutter](https://firebase.google.com/docs/app-check/flutter/default-providers)
- [Preços e limites do Firebase](https://firebase.google.com/pricing)

### GitHub Actions

- [Executar workflow manualmente](https://docs.github.com/actions/managing-workflow-runs/manually-running-a-workflow)
- [API REST de workflows](https://docs.github.com/rest/actions/workflows)
- [Sintaxe de workflows](https://docs.github.com/actions/using-workflows/workflow-syntax-for-github-actions)

### E-mail e segurança

- [Resend — enviar e-mail](https://resend.com/docs/api-reference/emails/send-email)
- [Resend — preços](https://resend.com/pricing)
- [OWASP MASVS](https://mas.owasp.org/MASVS/)

### Distribuição

- [Apple Developer Program](https://developer.apple.com/programs/enroll/)
- [Google Play Console — cadastro](https://support.google.com/googleplay/android-developer/answer/6112435)

---

## 20. Regra para iniciar

Quando o responsável disser que chegou o momento de começar, a primeira entrega será a **Fase 1 — Inventário e contratos**. Não começar por telas. Depois do contrato aprovado, iniciar a fundação testável do Flutter em `app-robo/`, mantendo `site/`, banco e robôs atuais operacionais.
