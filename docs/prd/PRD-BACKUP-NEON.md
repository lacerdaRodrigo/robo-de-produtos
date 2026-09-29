# PRD — Backup criptografado do Neon

**Versão:** 1.0 — automação versionada; ativação operacional pendente  
**Status em 2026-09-26:** workflow, script e testes unitários implementados.
O responsável confirmou a aplicação das migrations `033` e `034`. A role de
grupo `radar_backup` existe pelo contrato da migration 034; a configuração da
credencial de login, secrets, Drive, primeira execução e restauração
descartável ainda está pendente.

## Objetivo e limites

Criar uma cópia semanal recuperável do banco Neon sem usar a credencial de
escrita da API ou do Samsung. O GitHub Actions produz um dump custom Postgres,
criptografa-o localmente com `age` e envia apenas o arquivo cifrado a uma pasta
privada Google Drive. A retenção é de até 12 cópias semanais.

O job não aplica migrations, não restaura banco, não lê uma chave privada, não
publica arquivos brutos e não deve ser usado como autorização para modificar
produção. A restauração sempre começa em um banco descartável ou branch nova.

## Controles implementados

- `.github/workflows/backup-neon.yml` roda segunda-feira às 05:15 UTC ou por
  execução manual; limita a duração e usa `contents: read`.
- `NEON_BACKUP_DATABASE_URL` é uma conexão dedicada com usuário de leitura e
  SSL obrigatório. O script retira a senha dos argumentos do `pg_dump` e a usa
  somente em arquivo `.pgpass` temporário modo `0600`, removido ao terminar.
- `pg_dump` 18 (cliente compatível com a versão 18 do Neon) usa
  `--format=custom --no-owner --no-acl` para produzir a cópia lógica. `age`
  cifra antes do upload. O dump em claro fica temporariamente no runner, não
  entra no log e é apagado em sucesso ou falha.
- A pasta e os arquivos precisam ter ACL exclusiva do proprietário. O helper
  falha fechado se encontrar usuário extra, grupo, domínio ou link público.
- Upload é idempotente por `GITHUB_RUN_ID`. A retenção opera somente em arquivos
  dentro da pasta configurada e marcados com a propriedade privada
  `radar_neon_backup`.
- Testes unitários simulam falha do dump, limpeza do material em claro, formato
  de saída, ACL e retenção. Não provam acesso real ao Neon/Drive nem restauração.

## Configuração externa necessária

1. Conferir por leitura a existência da role de grupo `radar_backup` e os
   grants definidos por `migracoes/034_role_backup_readonly.sql`. A migration
   foi aplicada e confirmada pelo responsável em 2026-09-26; não a reaplicar.
   Ela cria apenas a role `NOLOGIN` e grants de leitura, sem senha ou login.
2. Criar uma role de login exclusiva, com senha gerada no provedor, associá-la a
   `radar_backup` e construir `NEON_BACKUP_DATABASE_URL` usando essa conta e
   `sslmode=require`. Não usar `radar_api`, `radar_samsung`, credencial owner ou
   os secrets de dispatch; a role de login não deve receber outra role nem
   privilégios próprios de escrita.
3. Gerar um par age localmente. Guardar a identidade privada em armazenamento
   offline/seguro e cadastrar somente o recipient público em
   `BACKUP_AGE_RECIPIENT`. Não enviar a chave privada ao runner ou ao Drive.
4. Cadastrar no GitHub Actions `NEON_BACKUP_DATABASE_URL`,
   `BACKUP_AGE_RECIPIENT`, `GOOGLE_DRIVE_OAUTH_CLIENT_JSON` e
   `GOOGLE_DRIVE_REFRESH_TOKEN`. Executar localmente o subcomando `bootstrap`
   com o OAuth já autorizado para criar/conferir a pasta privada; cadastrar o
   ID impresso em `GOOGLE_DRIVE_BACKUP_FOLDER_ID`.
5. Fazer uma execução manual, conferir o resultado do job e ACL da pasta sem
   baixar/compartilhar o backup. Restaurar uma cópia em um banco descartável
   usando a chave privada offline e conferir schema e dados essenciais.

Os passos 2–5 continuam abertos em `docs/PENDENCIAS.md`. Nenhum secret foi
cadastrado nem backup restaurado nesta sessão. A migration 033 instala funções
administrativas de limpeza; sua aplicação não significa que elas foram aceitas
para uso. Não executá-las antes do primeiro restore descartável e do aceite
destrutivo isolado.

## Restauração e limitações

O arquivo precisa ser baixado da pasta privada e descriptografado localmente
com a identidade age, sem copiar a identidade para o repositório ou CI. Antes
de sobrescrever qualquer ambiente, conferir versão do Postgres, extensões,
migrations necessárias, roles/grants e o destino. O dump omite owner e ACL por
projeto; ele não restaura usuários globais nem substitui o provisionamento de
schema/grants. A ordem de recuperação é: criar destino isolado, aplicar o schema
compatível, restaurar dados com `pg_restore`, conferir consultas essenciais e
só então decidir um corte separado. Não há rollback automático do Neon.

O backup tem dados pessoais e comerciais. A criptografia protege o conteúdo
armazenado no Drive, mas não protege contra perda da chave privada, comprometimento
da conta GitHub/Google, adulteração ou dump inconsistente. O aceite só se fecha
depois de uma restauração real e documentada em ambiente descartável.
