# PRD — Distribuição privada do aplicativo Android

**Versão:** v1.1 — assinatura release implementada; provisionamento externo pendente

**Status vigente em 2026-09-26:** workflow e helper de distribuição privada já
existem. Esta branch troca a build debug por release assinada, mas a criação e
guarda da chave, cadastro dos secrets, renovação do OAuth e primeiro aceite no
Samsung continuam pendentes. A variável `ANDROID_RELEASE_ENABLED` mantém a
distribuição desligada até esses pré-requisitos serem confirmados. A execução
`34148748135` é evidência histórica da distribuição debug anterior, não prova
da nova assinatura release.

Este PRD registra o contrato vigente de distribuição interna do APK. Ele não
cria um ambiente de homologação, não publica na Google Play e não substitui a
documentação operacional dos segredos do GitHub Actions.

## 1. Objetivo e limites

Depois de um push humano na `main`, o GitHub Actions valida o aplicativo e, com
`ANDROID_RELEASE_ENABLED=true`, gera uma APK release assinada e a disponibiliza
somente para o destinatário interno por meio de uma pasta privada do Google
Drive. O destinatário recebe um e-mail com o link autorizado.

A APK distribuída:

- é uma build `release` com o mesmo application id e uma assinatura estável
  mantida pelo responsável;
- consulta a API de produção em `https://robo-de-produtos.vercel.app`;
- desativa o App Check por `--dart-define=ATIVAR_APP_CHECK=false`;
- é distribuição privada, não publicação na Google Play nem homologação.

Ficam fora deste contrato ambiente de homologação, deploy da API, publicação na
Google Play e distribuição pública.

## 2. Contrato funcional

| ID | Regra |
|---|---|
| RF-APK-01 | `app-robo.yml` valida dependências, formatação, análise e testes mobile antes de qualquer distribuição. |
| RF-APK-02 | Pull requests apenas validam. A distribuição ocorre em push na `main` feito por pessoa ou em execução manual com `distribuir=true`, somente quando `ANDROID_RELEASE_ENABLED=true`. |
| RF-APK-03 | Execuções da `main` usam concorrência própria e cancelam a distribuição anterior ainda ativa; commits de `github-actions[bot]` não geram uma segunda entrega. |
| RF-APK-04 | O build usa `flutter build apk --release`, exige assinatura configurada, número monotônico derivado da execução/tentativa e nome com versão, execução e SHA curto. |
| RF-APK-05 | A APK não é anexada ao e-mail nem publicada como artifact do GitHub; o único canal de entrega é o arquivo privado do Drive. |
| RF-APK-06 | O Drive usa OAuth com escopo `drive.file`, pasta identificada por secret e ACL direta para o proprietário e `EMAIL_DESTINO`. Permissões `anyone`, `domain` e usuários não autorizados fazem a execução falhar. |
| RF-APK-07 | O upload é idempotente por execução: rerun reutiliza/atualiza o arquivo identificado por `run_key`, sem duplicar a APK. Somente arquivos marcados `radar_apk=true` na pasta configurada entram na retenção, limitada às 10 versões mais recentes. |
| RF-APK-08 | O e-mail SMTP SSL só é enviado depois da confirmação do upload e da ACL. A mensagem informa versão, execução, SHA, API de produção, natureza release privada e limitações de atualização por assinatura/application id. |
| RF-APK-09 | Falha de build, upload ou ACL não envia e-mail. Falha de SMTP mantém a APK privada e deixa o workflow vermelho para permitir rerun. |

## 3. Implementação versionada

| Arquivo | Responsabilidade |
|---|---|
| `.github/workflows/app-robo.yml` | Gate Flutter, build da APK, concorrência e acionamento condicional da distribuição. |
| `.github/scripts/distribuir_apk_drive.py` | OAuth Drive, upload idempotente, verificação de ACL, retenção e SMTP. |
| `.github/scripts/configurar_drive_apk.py` | Atalho local para o bootstrap OAuth; não grava credenciais no repositório. |
| `.github/scripts/test_distribuir_apk_drive.py` | Testes unitários das regras do helper sem rede. |
| `.github/README.md` | Operação do workflow e nomes dos secrets. |

Os secrets usados pelo job incluem `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS` e `ANDROID_KEY_PASSWORD`, além
de `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`,
`GOOGLE_DRIVE_REFRESH_TOKEN`, `GOOGLE_DRIVE_FOLDER_ID`, `EMAIL_REMETENTE`,
`EMAIL_DESTINO` e `SENHA_APP_GMAIL`. Nenhum valor de secret, token ou senha é
versionado ou impresso no log.

A chave usa o alias `radar-release`. A identidade deve ter cópia offline
criptografada fora do repositório, do Drive de distribuição e do runner. O
workflow decodifica o JKS em arquivo temporário com permissão `0600`, apaga-o ao
fim do passo e verifica a assinatura com `apksigner`. O Gradle não usa chave
debug como fallback: sem as quatro variáveis de assinatura, a tarefa release
falha.

## 4. Estado de aceite

### Confirmado

- bootstrap OAuth e criação/conferência da pasta privada;
- cadastro dos três secrets do Drive no GitHub Actions;
- execução manual `34148748135`, com APK debug histórica enviada ao Drive,
  ACL privada confirmada e e-mail enviado; ela não valida a nova assinatura;
- testes unitários do helper e compilação sintática Python.

### Externo e ainda pendente

- gerar a chave permanente, guardar a cópia offline criptografada, cadastrar os
  quatro secrets e habilitar `ANDROID_RELEASE_ENABLED` somente depois de
  conferir a impressão digital do certificado;
- renovar o `GOOGLE_DRIVE_REFRESH_TOKEN` ou publicar o cliente OAuth em
  `Production`; a execução `35471530166` falhou com `invalid_grant`;
- desinstalar a APK debug no Samsung, instalar a primeira release assinada e
  autenticar novamente; depois disso, validar atualização com `adb install -r`;
- confirmar visualmente, com a conta destinatária e uma conta não autorizada,
  o acesso permitido e negado no Drive;
- confirmar em uma execução posterior o comportamento de push na `main` e a
  retenção após mais de 10 builds.

Esses itens não impedem considerar a implementação do fluxo concluída, mas
continuam registrados em [`docs/PENDENCIAS.md`](../PENDENCIAS.md) porque não
podem ser provados somente pelo repositório.
