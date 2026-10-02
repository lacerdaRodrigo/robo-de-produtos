# PRD — Distribuição privada do aplicativo Android

**Versão:** v1.2 — APK debug para testes restaurada

**Status vigente em 2026-10-02:** a distribuição interna volta a gerar APK
debug e enviá-la à pasta privada do Drive. O fluxo não exige keystore release,
secrets de assinatura nem a variável `ANDROID_RELEASE_ENABLED`. O OAuth do
Drive, a pasta privada e o e-mail continuam necessários. A execução histórica
`34148748135` comprovou o envio da APK debug; a autorização OAuth renovada
precisa de uma nova execução bem-sucedida para ser confirmada.

Este contrato cobre somente a distribuição privada de APKs para testes. Não
publica na Google Play, não é uma release estável e não substitui a
documentação operacional dos secrets do GitHub Actions.

## 1. Objetivo e limites

Depois de um push humano na `main` que altere `app/**` ou o workflow/helper de
distribuição, o GitHub Actions valida o aplicativo e, se os gates passarem,
gera uma APK debug e a disponibiliza na pasta privada do Google Drive. Uma
execução manual distribui somente quando `distribuir=true`. O destinatário
recebe um e-mail com o link autorizado.

A APK distribuída:

- é gerada por `flutter build apk --debug` e usa a assinatura debug do runner;
- consulta a API de produção em `https://robo-de-produtos.vercel.app`;
- desativa o App Check por `--dart-define=ATIVAR_APP_CHECK=false`;
- serve para testes internos, não para publicação na Google Play;
- pode receber uma assinatura diferente em cada execução do runner. Instalar
  outra execução pode exigir desinstalar a APK anterior, o que apaga os dados
  locais do aplicativo.

A configuração Gradle que exige assinatura estável continua aplicável a builds
release feitas separadamente. Ela não é usada pela distribuição debug atual.

## 2. Contrato funcional

| ID | Regra |
|---|---|
| RF-APK-01 | `app-robo.yml` valida dependências, formatação, análise e testes mobile antes de qualquer distribuição. |
| RF-APK-02 | Pull requests apenas validam. Pushes na `main` que alterem `app/**` ou o workflow/helper acionam a distribuição; execução manual distribui somente com `distribuir=true`. |
| RF-APK-03 | Execuções da `main` usam concorrência própria e cancelam a distribuição anterior ainda ativa; commits de `github-actions[bot]` não geram uma segunda entrega. |
| RF-APK-04 | O build usa `flutter build apk --debug`, número monotônico derivado da execução/tentativa e nome com versão, execução e SHA curto; não exige keystore release. |
| RF-APK-05 | A APK não é anexada ao e-mail nem publicada como artifact do GitHub; o único canal de entrega é o arquivo privado do Drive. |
| RF-APK-06 | O Drive usa OAuth com escopo `drive.file`, pasta identificada por secret e ACL direta para o proprietário e `EMAIL_DESTINO`. Permissões `anyone`, `domain` e usuários não autorizados fazem a execução falhar. |
| RF-APK-07 | O upload é idempotente por execução: rerun reutiliza/atualiza o arquivo identificado por `run_key`, sem duplicar a APK. Somente arquivos marcados `radar_apk=true` na pasta configurada entram na retenção, limitada às 10 versões mais recentes. |
| RF-APK-08 | O e-mail SMTP SSL só é enviado depois da confirmação do upload e da ACL. Identifica a APK como debug de teste e avisa que reinstalar pode exigir desinstalação e apagar dados locais. |
| RF-APK-09 | Falha de build, upload ou ACL não envia e-mail. Falha de SMTP mantém a APK privada e deixa o workflow vermelho para permitir rerun. |

## 3. Implementação versionada

| Arquivo | Responsabilidade |
|---|---|
| `.github/workflows/app-robo.yml` | Gate Flutter, build debug, concorrência e acionamento da distribuição. |
| `.github/scripts/distribuir_apk_drive.py` | OAuth Drive, upload idempotente, verificação de ACL, retenção e SMTP. |
| `.github/scripts/configurar_drive_apk.py` | Atalho local para o bootstrap OAuth; não grava credenciais no repositório. |
| `.github/scripts/test_distribuir_apk_drive.py` | Testes unitários das regras do helper sem rede. |
| `.github/README.md` | Operação do workflow e nomes dos secrets. |

Os secrets usados pelo job são `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`,
`GOOGLE_DRIVE_REFRESH_TOKEN`, `GOOGLE_DRIVE_FOLDER_ID`, `EMAIL_REMETENTE`,
`EMAIL_DESTINO` e `SENHA_APP_GMAIL`. Os secrets
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
e `ANDROID_KEY_PASSWORD` não são necessários neste fluxo. Nenhum valor de
secret, token ou senha é versionado ou impresso no log.

## 4. Estado de aceite

### Confirmado

- bootstrap OAuth e criação/conferência da pasta privada;
- cadastro dos secrets do Drive e e-mail no GitHub Actions;
- execução manual `34148748135`, com APK debug enviada ao Drive, ACL privada
  confirmada e e-mail enviado;
- testes unitários do helper e compilação sintática Python.

### Externo e ainda pendente

- executar novamente a distribuição manual após a renovação OAuth e confirmar
  upload, ACL privada e e-mail;
- confirmar visualmente, com a conta destinatária e uma conta não autorizada,
  o acesso permitido e negado no Drive;
- validar a instalação de uma APK debug e a reinstalação após outra execução;
  se for necessária a desinstalação, confirmar o impacto nos dados locais;
- confirmar em uma execução posterior o comportamento de push na `main` e a
  retenção após mais de 10 builds.

A credencial OAuth só será considerada validada novamente após upload bem
sucedido. As verificações que dependem de contas, dispositivo ou serviço externo
continuam em [`docs/PENDENCIAS.md`](../PENDENCIAS.md).
