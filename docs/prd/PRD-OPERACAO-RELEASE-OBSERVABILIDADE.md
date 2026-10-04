# PRD — Operação, compatibilidade e observabilidade

**Status:** contrato documentado no repositório; configuração dos provedores,
ambientes e ensaios externos continua pendente.

Este documento registra as garantias que o repositório consegue exigir e
separa essas garantias da configuração real de Vercel, GitHub, Firebase, Neon e
da distribuição Android. Não habilita deploy, telemetria externa ou alteração
de Production.

## 1. Compatibilidade entre API e aplicativo

Enquanto o responsável não definir uma janela de suporte e uma versão mínima
aceita, a API deve preservar o contrato usado pelos APKs já distribuídos:

- manter rotas, métodos, significados e campos existentes;
- adicionar campos de resposta como opcionais para clientes antigos;
- não tornar obrigatório um parâmetro ou campo de requisição que antes era
  opcional;
- não renomear nem remover rotas ou campos durante uma publicação compatível;
- registrar o contrato atual em [`../openapi.json`](../openapi.json) e revisar
  alterações de rota, segurança, entrada e resposta junto dos handlers;
- não rejeitar um APK antigo por versão mínima enquanto essa regra não tiver
  sido decidida e comunicada.

Uma mudança incompatível exige contrato/rota paralela, plano de migração e uma
decisão explícita sobre o prazo de suporte. A especificação OpenAPI atual é o
inventário do contrato, mas não demonstra sozinha qual versão está publicada
nem quais APKs continuam instalados.

O workflow Android versiona e identifica o artefato privado; a API não publica
um identificador de release junto com cada resposta. A associação exata entre
APK, commit da API e deployment requer evidência do provedor de deploy.

O CI da API mantém bloqueante a auditoria de dependências de produção. A
auditoria completa do lockfile também bloqueia qualquer alerta alto/crítico,
cadeia ou dependência diferente da exceção temporária descrita em
[`PENDENCIAS.md`](../PENDENCIAS.md): o alerta GHSA-vfj7-8cjw-p6xm em `braces`,
alcançado somente pelo preset de lint de desenvolvimento. O verificador
`backend/api/scripts/auditar-dependencias.mjs` confere os pacotes, a cadeia e a
classificação `dev` no lockfile. Remover a exceção quando houver release oficial
corrigido.

## 2. Logs e correlação

O formato comum proposto para eventos operacionais é JSON com:

| Campo | Conteúdo permitido |
|---|---|
| `timestamp` | Instante UTC do evento. |
| `severity` | `info`, `warning` ou `error`. |
| `service` / `component` | API, coletor, worker ou workflow e seu domínio. |
| `event` | Nome estável da operação, sem conteúdo de usuário. |
| `result` / `error_code` | Estado controlado, sem mensagem externa bruta. |
| `request_id` | `x-request-id` da API/cron quando existir. |
| `execution_id` | ID da coleta, fila ou execução do GitHub Actions quando existir. |
| `duration_ms` | Duração da operação quando medida. |

Eventos concluídos usam `info`; tentativas, atraso e parcial usam `warning`;
falhas finais usam `error`. O mesmo ID deve ser propagado entre chamada e
processamento quando o contrato já oferece esse campo. Ausência de um ID deve
permanecer explícita; não fabricar correlação.

Não registrar tokens, cabeçalhos de autenticação, App Check, UID, e-mail, IP,
corpos de requisição/resposta, payload FCM, conteúdo de relatos ou exceções
externas integrais. Usar códigos de erro controlados. O log local do worker
continua restrito ao aparelho e com a retenção descrita em
[`PRD-EXECUCAO-COLETORES.md`](PRD-EXECUCAO-COLETORES.md); os logs do provedor de
API/Actions continuam sujeitos à configuração externa de acesso e retenção.

Várias rotas autenticadas e de cron já geram ou propagam `x-request-id` em suas
respostas, e o worker já registra execução e resultado. A cobertura ainda não é
uniforme entre handlers. Isso não equivale a uma implementação completa do
formato comum nem a um destino central de logs.

## 3. Deploy e monitoramento

O workflow `app-robo.yml` valida o Flutter e distribui uma APK debug privada
após push humano na `main` ou execução manual com `distribuir=true`. A entrega
depende dos secrets de Drive e e-mail; não exige assinatura release. A
assinatura debug pode variar entre execuções, e reinstalar pode apagar dados
locais. O workflow de CI executa
qualidade da API; este checkout não contém evidência de um workflow próprio que
publique a API. A Vercel pode usar integração Git configurada fora do
repositório; o modo real precisa ser conferido antes de criar uma segunda
automação.

Qualquer fluxo futuro de publicação deve ter ambiente de validação separado,
aprovação de Production e bloqueio até o gate WAF previsto. O repositório não
cria ambientes, reviewers, secrets nem regras do provedor. Nenhum deploy é
autorizado por este documento.

`GET /api/status` responde apenas `{ "saudavel": true }`. Essa resposta não
confirma banco, autenticação, atualização dos catálogos, estado dos workers ou
entrega FCM. Monitoramento útil precisa correlacionar pelo menos disponibilidade
da API, conclusão real dos coletores (não só enqueue), atraso por domínio,
falhas de autenticação/App Check e contagens da outbox, sem expor dados pessoais
na rota pública.

O destino central, os destinatários de alertas, a retenção e os acessos ainda
precisam de uma escolha e configuração externas. Até lá, usar os logs privados
e os históricos dos serviços já existentes sem afirmar cobertura centralizada.

## 4. Rollback por superfície

| Superfície | Estado verificável | Gate antes de considerar rollback aceito |
|---|---|---|
| API | O mecanismo do deployment Vercel não é versionado neste checkout. | Confirmar integração e procedimento no projeto Vercel e ensaiar em homologação antes de Production. |
| Banco | O PRD Neon descreve restore em destino isolado; o primeiro restore ainda não foi aceito. | Fazer backup real, conferir ACL e restaurar em branch/banco descartável antes de qualquer limpeza destrutiva. |
| Robôs | O worker Samsung atualiza in-place e não tem rollback automático. O procedimento operacional e as limitações estão em `PRD-EXECUCAO-COLETORES.md`. | Ensaiar parada, recuperação/reinstalação e retomada no M13; não declarar autonomia após reboot. |
| Aplicativo | A distribuição privada retém APKs debug, condicionada ao OAuth e à retenção configurados. A assinatura pode variar por execução. | Instalar a APK distribuída e testar reinstalação/retorno no aparelho, registrando se foi necessário desinstalar a anterior e o impacto nos dados locais. |

Não substituir rollback de API por restauração de banco, nem limpeza de dados
por rollback de aplicação. Cada procedimento precisa registrar artefato,
identidade/versão, responsável, resultado e impacto observado, sem dados
sensíveis.

## 5. Pendências externas relacionadas

- escolher/configurar destino central, retenção e alertas;
- definir a janela de suporte e a versão mínima do aplicativo;
- confirmar integração Git e aprovação de ambientes no Vercel/GitHub;
- configurar homologação e secrets separados;
- configurar WAF antes de publicação dependente dele;
- executar os ensaios de rollback e de restore nos ambientes descartáveis e no
  aparelho-alvo.

Esses itens permanecem em [`../PENDENCIAS.md`](../PENDENCIAS.md) até haver
evidência externa ou decisão do responsável.
