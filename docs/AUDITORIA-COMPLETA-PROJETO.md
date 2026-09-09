# Auditoria completa do projeto

**Data de referência:** 2026-09-08.

**Escopo:** Git e histórico, GitHub, dependências, workflows, arquivos locais,
Neon/Postgres, distribuição da APK e executor Pichau no Samsung. Nenhum segredo
é reproduzido neste documento.

## Resultado executivo

Não foi encontrada credencial privada versionada nem vulnerabilidade conhecida
remanescente nas dependências Python/npm auditadas. Os três valores apontados
pelo secret scanning são chaves cliente do Firebase: aparecem na árvore atual
e no histórico, possuem restrição de aplicativo e de APIs no Google Cloud e
fazem parte da configuração distribuída do cliente. Elas não justificam
reescrever o histórico.

Os principais riscos restantes são externos: uma APK debug antiga ainda está
em artifact público do GitHub, `main`/`develop` não têm proteção, a
distribuição interna ainda usa assinatura debug e App Check desabilitado, e a
role dispatcher da Pichau mantém três permissões de sequência desnecessárias.

## Matriz de achados

| Severidade | Achado | Estado |
|---|---|---|
| Alta | Artifact antigo contém APK debug pública e não expirada | ação externa pendente |
| Alta para release | APK usa assinatura debug e App Check desabilitado | aceitável apenas internamente; release bloqueado |
| Média | `main` e `develop` sem ruleset/proteção | ação externa pendente |
| Média | Dependabot security updates e code scanning não habilitados | ação externa pendente |
| Média | Dispatcher Pichau tem três `USAGE` de sequências fora da fila | revogação SQL pendente, sem aplicação nesta auditoria |
| Média | Neon possui apenas branch `production` e nenhuma restrição de IP | decisão de infraestrutura pendente |
| Baixa | Branches remotas antigas acumuladas | lista preparada; nenhuma exclusão remota executada |
| Informativa | Três chaves Firebase aparecem em quatro ocorrências no histórico | configuração cliente restrita; alertas podem ser encerrados como falso positivo |

## Segredos e histórico

- `gitleaks` foi executado na árvore atual e em todas as refs.
- Foram encontradas quatro ocorrências, correspondentes a três chaves Firebase
  presentes em `google-services.json` e `firebase_options.dart`.
- A consulta read-only do Google Cloud confirmou restrição por Android, iOS ou
  navegador e por conjunto de APIs. Nenhuma API generativa/Vertex foi
  encontrada habilitada no projeto.
- `app/.env` e `backend/robo/.env` permanecem ignorados, fora do índice e
  com modo `0600`.
- Secret scanning e push protection do GitHub estão habilitados. Os três
  alertas antigos devem ser encerrados externamente como configuração cliente
  esperada, anexando a evidência das restrições.

Decisão: preservar o histórico. Reescrevê-lo traria risco de quebrar clones,
tags e referências sem remover um segredo real. Se surgir uma credencial
privada em auditoria futura, primeiro ela deve ser revogada/rotacionada e só
depois o histórico pode ser reescrito.

## Dependências e código

- Python: 12 dependências verificadas por `pip-audit`, sem vulnerabilidades
  conhecidas.
- Bandit: nenhum achado alto. Os seis médios são SQL montado apenas com
  constantes/placeholders e valores parametrizados; os cinco baixos envolvem
  subprocesso com argumentos internos e atraso aleatório não criptográfico.
- npm: Next foi atualizado de 16.3.1 para 16.3.4; Sharp e `js-yaml` foram
  atualizados no lockfile. `npm audit` terminou com zero vulnerabilidades.
- Flutter: foram registradas atualizações diretas disponíveis, mas não houve
  upgrade sem necessidade funcional. Dependabot agora monitora Pub.
- `ranking_inter.py`, seu teste isolado e `app/lib/inter_preview.dart`
  foram removidos porque não participavam do produto. O ranking real permanece
  coberto na API e no Flutter com comparação decimal textual.
- Vinte PNGs gerados por falhas visuais foram retirados do índice e
  `**/failures/` passou a ser ignorado.

## GitHub Actions

Correções aplicadas:

- Actions de terceiros fixadas por SHA completo;
- credenciais do checkout desativadas nos jobs somente de leitura;
- Dependabot corrigido para Python em `/backend/robo` e ampliado para npm,
  Pub e Actions;
- `npm audit --audit-level=high` adicionado ao CI;
- workflow Pichau restrito ao secret dedicado, sem fallback amplo;
- distribuição manual da APK restrita à `main`;
- ACL do Drive exige o destinatário exatamente como `reader`.
- runner Android tenta reutilizar primeiro um endpoint Wi-Fi ADB já conectado,
  reduzindo descoberta desnecessária sem ampliar o host permitido.

O workflow de versionamento conserva credenciais e `contents: write` porque
precisa publicar tag/release; os demais continuam com `contents: read`.

## APK, Drive e e-mail

A APK pública antiga foi baixada somente para análise:

- pacote esperado e build debug;
- certificado Android de debug;
- permissões Android reduzidas a rede/serviços esperados;
- nenhum segredo encontrado ao varrer o arquivo;
- componentes exportados compatíveis com autenticação Firebase/Google.

Isso não torna apropriada sua publicação: o artifact deve ser apagado do
GitHub. O fluxo atual não usa artifact e publica no Drive privado com escopo
`drive.file`, destinatário leitor, retenção de dez builds e e-mail ativo.
Como valores dos secrets não são legíveis pelo GitHub API, a ACL real atual
deve ser conferida externamente ou por nova execução controlada.

## Neon/Postgres

A conexão read-only confirmou TLS no cliente e roles Pichau sem
`SUPERUSER`, `CREATEDB`, `CREATEROLE`, replicação ou `BYPASSRLS`.

- `pichau_dispatcher`: `SELECT/INSERT` na fila.
- `pichau_publisher`: leitura/atualização da fila e escrita nas três tabelas
  Pichau.
- ambas têm `USAGE`, sem `CREATE`, no schema público.

Pendência exata: revogar do dispatcher o `USAGE` das sequências de
`pichau_execucao`, `pichau_produto` e `pichau_medicao`, preservando
somente a sequência da fila. A alteração não foi aplicada por ser produção.

O projeto Neon possui apenas a branch `production`, sem proteção de branch e
sem allowlist de IP. Criar uma branch de desenvolvimento/homologação e avaliar
restrições de rede evita testar evolução diretamente na base operacional.

## Executor Pichau no Samsung

A leitura do aparelho confirmou Android 14 atualizado, Wireless Debugging
ativo, ausência do transporte legado na porta 5555 e Appium em
`127.0.0.1:4723`. Os runners versionados exigem arquivo privado, SSL, nomes
de ambiente permitidos, logs em diretório `0700`, retenção de 14 dias,
Appium local e filtro do host mDNS.

Não foi possível ler o armazenamento privado do Termux por `run-as`, como
esperado. Logs públicos de falha foram revisados e não continham URL de banco,
chaves, e-mails, IPs ou tokens. Permanecem operacionais: validar o pareamento
após reboot sem USB, remover pareamento obsoleto/offline e confirmar no roteador
que não existe encaminhamento de porta para ADB/Appium.

## Limpeza do Git

Antes de qualquer remoção foi criado e verificado um bundle completo:

`/home/rodrigo/Estudos/robo-git-backups/robo-before-cleanup-2026-09-08.bundle`

O arquivo tem modo `0600` e inclui branches, tags, refs remotas e stash. As
branches locais totalmente incorporadas à `develop` já foram removidas; a
branch local `claude/v2-3-1-redesenho` foi preservada por conter um commit
único. O stash de PNGs também foi removido depois que os arquivos passaram a
ser ignorados, e continua recuperável pelo bundle.

Branches remotas já ancestrais de `develop` são candidatas à exclusão após
revisão humana:

`agent/busca-paginacao-ux`, `agent/corrige-inter-responsivo-paginacao`,
`agent/exibe-total-produtos-inter`, `agent/melhora-lojas-produtos-inter`,
`agent/simplifica-ux-menu`, `agent/v4-catalogo-produtos`,
`build/apk-1.54.0`, `claude/banco-manda`,
`claude/documentacao-v2-u7v8wf`, `claude/entender-projeto-main-1r2waq`,
`claude/pendencias-v2-1`, `claude/v2-2-alertas`,
`claude/v2-3-robo-grava`, `claude/v2-3-site`,
`codex/auditoria-mobile-v11`, `codex/mobile-v11`,
`docs/plano-categorias-inter-fonte-oficial`,
`docs/validacao-categorias-json-inter`, `feat/arquivar-site-e-api`,
`feat/categorias-inter-fonte-oficial`, `feat/distribuicao-apk-drive`,
`feat/pichau-android-fast-runner`, `feat/pichau-backend`, `limpeza`,
`master`, `re-desig2`, `re-design` e `redesign-mobile-novo`.

As branches remotas não incorporadas não foram apagadas. Precisam de análise
de conteúdo/PR, especialmente `agent/fix-total-incoerente-inter`,
`agent/redesign-front-e-versoes`, `claude/v2-3-1-redesenho`,
`codex/apk-main-20260901`, `feat/destaque-preco-apos-cashback`,
`fix/botao-produtos-inter` e `fix/inter-paginacao-lixeira`. As branches
Dependabot antigas e `feat/preco-liquido-em-destaque` estão superadas ou
patch-equivalentes, mas a exclusão continua sendo ação remota separada.

## Ações externas não executadas

1. Apagar o artifact público da APK antiga.
2. Encerrar os três alertas Firebase com a evidência de restrição.
3. Proteger `main` e `develop`, exigir PR/gates e habilitar exclusão de
   branch após merge.
4. Habilitar Dependabot security updates e code scanning.
5. Aplicar a revogação mínima das três sequências do dispatcher.
6. Criar ambiente Neon não produtivo e avaliar allowlist de IP.
7. Conferir ACL/OAuth do Drive e revisar/rotacionar credenciais Gmail antigas.
8. Criar assinatura release e ativar App Check antes de publicação pública.
9. Fechar o pareamento Wi-Fi/reboot da Pichau e revisar o roteador doméstico.

## Referências

- Firebase API keys:
  https://firebase.google.com/docs/projects/api-keys
- Firebase security checklist:
  https://firebase.google.com/support/guides/security-checklist
- Remoção de dados sensíveis do histórico:
  https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
- Segurança de GitHub Actions:
  https://docs.github.com/en/actions/reference/security/secure-use
