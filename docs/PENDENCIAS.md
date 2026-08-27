# Pendências

Lista viva do que ainda exige trabalho ou decisão. O histórico detalhado das
fases concluídas permanece no Git e no `CHANGELOG.md`; não fica misturado aqui
com ações abertas.

**Revisado em:** 27 de agosto de 2026  
**Estado das mudanças desta data:** local, ainda não publicado.

## Decisões fechadas nesta organização

- [x] Manter robôs Python, API Next.js, Postgres e Flutter separados.
- [x] Manter somente a interface Flutter; `site/` não deve ser recriado.
- [x] Remover o filtro residual da coluna inexistente `loja.favorita`.
- [x] Restaurar testes, lint, build e CI da API.
- [x] Fixar Flutter 3.44.1 no CI.
- [x] Corrigir os caminhos do versionamento e adicionar teste de regressão.
- [x] Separar exemplos de ambiente e criar `docs/CONFIGURACAO.md`.
- [x] Remover `backend/api/lib/flags.ts`, legado sem consumidores.
- [x] Remover por completo o canal SMTP/Gmail de alertas Livelo: código,
  credenciais, parâmetro de workflow, testes e guia.
- [x] Tornar falha de persistência Livelo fatal quando há Postgres configurado;
  sem outro canal, workflow verde com app desatualizado seria falha silenciosa.

## Publicação e ambiente

- [ ] Enviar/revisar a branch e observar a primeira execução remota dos gates de
  robô, API e Flutter. Código local não conta como publicado.
- [ ] Cadastrar `ALLOWED_ORIGINS` na Vercel com as origens HTTPS exatas do Flutter Web.
- [ ] Conferir `DATABASE_URL` nos GitHub Actions e na Vercel, sem copiar o valor
  para documentação ou log.
- [ ] Conferir `GITHUB_TOKEN_DISPARO` somente na Vercel, com permissão mínima de Actions.
- [ ] Aplicar `migracoes/009_coleta_degradada_produtos_inter.sql` e
  `migracoes/012_limpeza_administrativa.sql` no Neon, cada uma com autorização
  específica. A migração `011` continua adiada.
- [ ] Confirmar uma release depois da correção de `versao.yml`; pacote,
  `__version__` e `CHANGELOG.md` precisam mudar juntos.
- [ ] Migrar `backend/api/middleware.ts` para a convenção `proxy` antes de uma
  futura versão do Next remover o nome antigo. Hoje é apenas aviso de build.

## Segurança e autenticação

- [ ] Registrar e observar App Check em Web e iOS; manter
  `EXIGIR_APP_CHECK=false` até os três alvos estarem comprovados.
- [ ] Remover e recriar o token de depuração do App Check do Samsung que apareceu
  em log local; nunca registrar o novo valor.
- [ ] Acompanhar a migração futura indicada por `firebase_app_check` para Built-in Kotlin.
- [ ] Executar smoke no Samsung: `/status` → login → perfil → resumo → Livelo →
  cashback → produtos.

## Flutter

- [ ] Fazer o aceite visual final do Flutter Web em navegador real quando esse
  alvo voltar ao escopo.
- [ ] Validar launch screen, ícone e build iOS em macOS/Xcode ou aparelho iOS.
- [ ] Confirmar as jornadas de cashback e produtos com dados publicados depois
  das migrações e do deploy da branch.
- [ ] Decidir, antes de implementar, o destino da aba **Alertas**, hoje
  incompleta: remover do fluxo ou desenhar uma experiência nova nos protótipos
  Web e Mobile. O antigo histórico de e-mails não será restaurado por padrão.
- [ ] Avaliar separadamente simulador de pontos e favoritos pessoais. Eles foram
  citados como ideia, mas não há requisito aprovado nem implementação comprovada.

## Livelo

- [ ] Decidir a contradição da limpeza administrativa: catálogo Livelo vazio
  deve permanecer vazio, como o código atual, ou receber novamente um catálogo
  padrão. Não mudar a regra antes dessa decisão.
- [ ] Observar por duas ou três semanas se multiplicador 2,0× e piso 4 continuam
  úteis nos retratos exibidos pelo app.
- [ ] Se houver ruído comprovado, ajustar primeiro o padrão pela interface/API
  autorizada e criar exceções somente para as poucas lojas que precisarem.

## Inter Sites parceiros

- [ ] No Flutter publicado, selecionar as primeiras lojas desejadas, disparar
  uma atualização e conferir cashback, texto da condição e carimbo reais.

## Inter Compre direto

- [ ] Registrar bytes totais e projeções de duração/armazenamento para 3, 10 e
  111 lojas, mantendo três rodadas diárias e retenção de 30 dias.
- [ ] Validar a loja Ponto antes de ampliar a seleção.
- [ ] Depois da migração `009`, repetir o aceite de coleta degradada e confirmar
  que uma tentativa parcial não inativa produtos do último catálogo válido.

## Qualidade conhecida

- [ ] Investigar as três diferenças mínimas de golden tests Flutter que falharam
  localmente enquanto o CI remoto passava; não atualizar imagens às cegas.
- [ ] Rodar build iOS somente em ambiente Apple. Linux não consegue validar esse alvo.

## Evidência local mais recente

- Robô Python após retirar e-mail: **172 testes**, cobertura do núcleo **93,37%**.
- API: TypeScript, ESLint, Vitest e build já estavam verdes antes da retirada;
  a validação final desta nova mudança deve atualizar a contagem registrada.
- Nenhuma migração, publicação, coleta real ou envio externo foi executado nesta organização.
