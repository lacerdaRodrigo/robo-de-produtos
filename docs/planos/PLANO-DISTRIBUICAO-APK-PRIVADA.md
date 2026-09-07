# Plano — distribuição privada de APK após a `main`

**Status:** implementação versionada na branch `feat/distribuicao-apk-drive`;
bootstrap OAuth concluído e os três secrets do Drive cadastrados no GitHub. A
primeira execução distribuível ainda será validada pelo workflow antes do
merge.

O código de distribuição, o workflow e os testes unitários já estão no
repositório. A autorização OAuth está em **Testing**, com
`lacerdaa.rodrigo@gmail.com` como usuário de teste; isso permite a primeira
APK, mas o refresh token precisa ser renovado se o projeto continuar nesse
status por mais de sete dias. A publicação em **Production** continua como
pendência externa, pois exige concluir as informações públicas do OAuth.

**Decisões fechadas em 2026-09-06:** a distribuição interna será por Google
Drive privado; a conta proprietária da pasta será a mesma de `EMAIL_REMETENTE`;
somente `EMAIL_DESTINO` terá acesso; serão retidas as 10 APKs mais recentes;
uma APK poderá substituir a versão instalada no Samsung; e a APK de teste
apontará para a API de produção atual, pois ainda não existe homologação.

## 1. Objetivo e limite

Após cada push humano que for aprovado na `main`, gerar a APK Android atual do
Radar de Benefícios e disponibilizá-la exclusivamente para o destinatário
interno. O e-mail deve avisar que a versão está pronta e levar ao link privado
da APK no Drive.

Este plano cria **distribuição interna**, não um ambiente de homologação. A
APK continuará consultando `https://robo-de-produtos.vercel.app` e deverá dizer
isso no e-mail. Ela não cria banco, Firebase, API, secrets nem dados separados
de produção. Deploy automático da API, Google Play e uma variante Android
separada permanecem fora deste escopo.

## 2. Levantamento e decisões

| Tema | Conclusão adotada |
|---|---|
| Repositório | `lacerdaRodrigo/robo-de-produtos` é público; por isso uma APK enviada como artifact do GitHub Actions não atende ao requisito de acesso restrito. |
| CI atual | `.github/workflows/app-robo.yml` já valida Flutter em push, PR e execução manual. Hoje ele só cria `app-debug.apk` e faz upload como artifact numa execução manual. |
| Tamanho | As APKs existentes têm aproximadamente 52–64 MB. O Gmail limita anexos a 25 MB, portanto a APK não será anexada ao e-mail. |
| Canal | Google Drive privado, com ACL direta para `EMAIL_DESTINO`; não haverá permissão `anyone` nem `domain`. |
| Autenticação Drive | Usar OAuth da conta pessoal `EMAIL_REMETENTE` com escopo `drive.file`. Não usar service account: ela não tem quota própria de armazenamento para este caso. |
| Renovação OAuth | A primeira execução está em **Testing**, com a conta proprietária cadastrada como usuário de teste. Em modo Testing, um refresh token de escopos Drive pode expirar em sete dias; Production fica para a configuração pública posterior. |
| E-mail | Usar os secrets já existentes `EMAIL_REMETENTE`, `SENHA_APP_GMAIL` e `EMAIL_DESTINO`, por SMTP SSL do Gmail em `smtp.gmail.com:465`. |
| Ritmo | Para pushes novos na `main`, cancelar a execução anterior ainda em fila ou em andamento. Um e-mail já entregue não pode ser revogado, mas somente a última execução ainda ativa poderá concluir a distribuição. |
| Instalação | Manter o mesmo application id e assinatura de debug já usados pelo app. Assim a APK pode atualizar a instalação do Samsung; se houver uma instalação assinada por outra chave, o Android recusará a atualização e será preciso alinhar a assinatura antes. |
| Retenção | Manter somente as 10 APKs mais recentes identificadas como builds do Radar na pasta exclusiva; arquivos estranhos à automação nunca entram na limpeza. |

As referências externas usadas neste levantamento são a documentação do
[limite de anexos do Gmail](https://support.google.com/mail/answer/6584), do
[compartilhamento do Google Drive](https://developers.google.com/workspace/drive/api/guides/manage-sharing), do
[OAuth 2.0 do Google](https://developers.google.com/identity/protocols/oauth2)
e dos [artifacts do GitHub Actions](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts).

## 3. Resultado técnico proposto

### 3.1 Workflow — implementado

`.github/workflows/app-robo.yml` foi reestruturado em dois jobs:

1. `validar` preserva o gate atual: `flutter pub get`, `dart format`,
   `flutter analyze` e somente os testes unitários/widgets Flutter permitidos.
   Ele continua rodando em pushes, pull requests e `workflow_dispatch`.
2. `distribuir_apk` depende de `validar` e só pode rodar quando:
   - o evento for um push na `main` que não tenha sido criado por
     `github-actions[bot]`; ou
   - a execução manual informar explicitamente que deseja distribuir.

O workflow terá `concurrency` específico da `main`, com `cancel-in-progress:
true`. Validações de pull request não serão canceladas por essa fila de
distribuição. O commit automático do semantic-release não deve gerar uma
segunda APK/e-mail.

Não haverá `actions/upload-artifact` para APK. Mesmo em execução manual, a
saída distribuível será exclusivamente o arquivo privado no Drive; isso evita
publicar acidentalmente uma cópia em um repositório público.

Depois da validação, o job compila uma APK debug com:

- `--dart-define=API_URL=https://robo-de-produtos.vercel.app`;
- `--dart-define=ATIVAR_APP_CHECK=false`;
- `versionCode` monotônico derivado do número da execução e da tentativa;
- nome de arquivo contendo versão do app, número da execução e SHA curto.

O job não imprimirá em log conteúdo de OAuth, tokens, senha de aplicativo,
endereços de e-mail ou URL de conexão. Segredos entram apenas como variáveis de
ambiente do processo que precisa deles.

### 3.2 Publicação privada no Drive — implementada

O helper versionado
`.github/scripts/distribuir_apk_drive.py` instala as dependências somente no
runner (`google-auth` e `google-api-python-client`) e:

1. autenticar com `GOOGLE_DRIVE_OAUTH_CLIENT_JSON` e
   `GOOGLE_DRIVE_REFRESH_TOKEN`, usando exclusivamente `drive.file`;
2. enviar a APK para a pasta cujo id está em `GOOGLE_DRIVE_FOLDER_ID`;
3. marcar o arquivo com propriedades de app, por exemplo
   `radar_apk=true`, `run_id` e SHA, e tornar a operação idempotente: um rerun
   localiza o arquivo daquela execução antes de criar outro;
4. conceder acesso direto `type=user`, `role=reader` a `EMAIL_DESTINO` quando
   ele não for o próprio proprietário;
5. reler a ACL e confirmar que existe o proprietário e o destinatário, sem
   permissões `anyone` ou `domain`;
6. se a validação de acesso falhar, excluir apenas o upload recém-criado e
   falhar o job; e
7. ao terminar, ordenar somente os arquivos marcados da pasta por data de
   criação e apagar os mais antigos além dos 10 retidos.

A pasta do Drive será criada exclusivamente para essas APKs. A limpeza nunca
consultará ou apagará arquivos sem a propriedade `radar_apk=true`, nem arquivos
fora desse id de pasta. O link enviado será o `webViewLink` do arquivo: possuir
o link não substitui a ACL do Drive.

### 3.3 Aviso por e-mail — implementado

Somente após o upload e a ACL privada serem confirmados, o mesmo helper enviará
um e-mail de texto/HTML via SMTP SSL. A mensagem terá:

- assunto com a versão, número da execução e SHA curto;
- data e hora da geração;
- aviso visível de que é uma build interna debug e consulta a API de produção;
- link privado do Drive; e
- observação de que a APK substitui a app existente apenas se assinatura e
  application id forem compatíveis.

Não haverá anexo. Se compilação, upload ou verificação de ACL falhar, e-mail
algum será enviado. Se o SMTP falhar, o job falha e a APK privada é preservada;
o rerun deve reutilizar o mesmo upload e tentar somente a notificação, sem
duplicar arquivos.

## 4. Configuração externa

Antes do primeiro push distribuível, o responsável executará uma única
configuração fora do repositório:

1. criar um projeto dedicado no Google Cloud e habilitar a Google Drive API;
2. configurar a tela OAuth como externa; para a primeira execução ela está em
   **Testing**, com `lacerdaa.rodrigo@gmail.com` como usuário de teste;
3. criar um cliente OAuth de desktop para a conta `EMAIL_REMETENTE`;
4. executar localmente um pequeno bootstrap, autenticado como
   `EMAIL_REMETENTE`, para criar a pasta privada de APKs e obter o refresh
   token `drive.file`;
5. conferir que a pasta não tem compartilhamento por link, domínio ou público;
6. cadastrar nos GitHub Actions secrets, sem aspas extras ou quebras indevidas:

   - `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`;
   - `GOOGLE_DRIVE_REFRESH_TOKEN`;
   - `GOOGLE_DRIVE_FOLDER_ID`.

Os secrets já configurados permanecem como entrada do SMTP:
`EMAIL_DESTINO`, `EMAIL_REMETENTE` e `SENHA_APP_GMAIL`. Nenhuma credencial,
refresh token, client secret, senha de app ou URL de Drive será versionada.

O bootstrap foi executado localmente com o JSON OAuth fornecido, confirmou a
conta `lacerdaa.rodrigo@gmail.com`, criou/encontrou a pasta privada `Radar APKs
privadas` e gravou o refresh token somente no arquivo local temporário. Os
secrets `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`, `GOOGLE_DRIVE_REFRESH_TOKEN` e
`GOOGLE_DRIVE_FOLDER_ID` foram cadastrados no repositório sem imprimir seus
valores.

Service account, pasta pública, link “qualquer pessoa com o link”, anexar a APK
ao Gmail e GitHub artifact público são opções rejeitadas para este fluxo.

## 5. Implementação em arquivos

| Arquivo | Alteração realizada |
|---|---|
| `.github/workflows/app-robo.yml` | Separar validação e distribuição, limitar a distribuição à `main`/manual explícito, configurar concorrência, compilar e chamar o helper privado. |
| `.github/scripts/distribuir_apk_drive.py` | Implementar OAuth Drive, ACL fechada, retenção, idempotência e SMTP, sem logs de segredos. |
| `.github/scripts/configurar_drive_apk.py` | Oferecer bootstrap local não interativo após OAuth para criar/conferir pasta e orientar o cadastro dos três secrets novos. Não pode gravar tokens no repositório. |
| `.github/README.md` | Explicar os gatilhos, a ausência de artifact público, os secrets e o limite entre distribuição interna e deploy. |
| `docs/PENDENCIAS.md` | Continua sob alteração concorrente do outro agente; esta branch não incorpora mudanças nesse arquivo para não misturar escopos. A pendência de Production/OAuth permanece externa. |
| `docs/testes/TESTES.md` | Continua sob alteração concorrente do outro agente; os testes unitários isolados do helper estão em `.github/scripts/test_distribuir_apk_drive.py`. |

## 6. Testes e aceite

O helper foi isolado nas funções de Drive e SMTP para permitir testes
unitários sem rede. A validação local atual cobre:

- upload e nomeação da APK;
- reutilização do arquivo em rerun;
- permissão direta somente para o destinatário;
- rejeição de ACL com `anyone` ou `domain`, seguida da remoção segura do upload
  recém-criado;
- retenção exata das 10 APKs marcadas, sem tocar em arquivo não marcado;
- falha de SMTP mantendo o arquivo privado e deixando o workflow vermelho;
- ausência de e-mail quando build, upload ou ACL falhar.

Além desses testes, a implementação executará `dart format --output=none`,
`flutter analyze` e somente os testes Flutter unitários/widgets diretamente
afetados pelo workflow atual. O novo helper Python terá sua validação unitária
diretamente relacionada; não serão adicionados testes Web, integração, E2E,
smoke ou performance neste ciclo.

Comandos executados localmente:

```text
python3 -m unittest discover -s .github/scripts -p 'test_*.py' -v
python3 -m py_compile .github/scripts/distribuir_apk_drive.py .github/scripts/configurar_drive_apk.py
git diff --check
```

O bootstrap OAuth foi validado contra a Google Drive API real. A execução
manual do workflow ainda é o aceite final de build, upload, ACL e e-mail.

O aceite externo será uma execução manual controlada após a configuração:

1. confirmar que a APK aparece na pasta correta e apenas o proprietário e
   `EMAIL_DESTINO` conseguem abri-la;
2. tentar abrir com uma conta não autorizada e confirmar negação de acesso;
3. conferir o e-mail, metadados, link e o aviso de API de produção;
4. instalar no Samsung sobre a versão existente e confirmar a atualização;
5. efetuar mais de 10 execuções controladas ou simular a listagem para provar
   que somente builds marcadas antigas são removidas;
6. abrir pull request e push na `main` para confirmar que PR só valida e a
   última `main` aprovada distribui uma vez.

## 7. Critérios de aceite

- Push humano aprovado na `main` entrega uma APK privada e um e-mail com link
  funcional para `EMAIL_DESTINO`.
- O mesmo push não expõe APK em artifact público, anexo de e-mail, repositório
  ou permissão pública do Drive.
- PRs validam, mas não distribuem; commits do bot não duplicam distribuição.
- Nova `main` cancela a distribuição anterior ainda não concluída.
- Drive conserva no máximo 10 APKs identificadas pela automação, sem remover
  arquivos alheios.
- Falhas não enviam sucesso enganoso nem expõem segredos nos logs.
- A comunicação e a documentação deixam explícito que se trata de teste contra
  a API de produção, não homologação.

## 8. Pendências que este plano não resolve

- Criar ambiente de homologação real, com API, banco, Firebase e secrets
  próprios.
- Automatizar deploy/rollback da API e uma publicação pública na Google Play.
- Criar assinatura de release própria e proteger keystore/credenciais de
  produção.
- Definir política de compatibilidade entre versões antigas do app e da API.
- Fazer aceite móvel completo de funcionalidades que não façam parte desta
  distribuição técnica.

Ao implementar este plano, seu conteúdo deve ser incorporado à documentação de
CI e de publicação aplicável; ele não deve continuar sendo tratado como
instrução operacional vigente em paralelo ao código.
