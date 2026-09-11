# PRD — Distribuição privada do aplicativo Android

**Versão:** v1.0 — implementada

**Status vigente em 2026-09-09:** o fluxo está versionado na `main`, com
workflow, publicação privada no Google Drive, notificação por e-mail e testes
unitários do helper. A execução manual `34148748135` confirmou build, upload,
ACL privada e notificação. A validação manual da instalação no Samsung e a
confirmação visual de acesso pela conta destinatária continuam externas ao
repositório.

Este PRD registra o contrato vigente de distribuição interna do APK. Ele não
cria um ambiente de homologação, não publica na Google Play e não substitui a
documentação operacional dos segredos do GitHub Actions.

## 1. Objetivo e limites

Depois de um push humano na `main`, o GitHub Actions valida o aplicativo,
gera uma APK Android de teste e a disponibiliza somente para o destinatário
interno por meio de uma pasta privada do Google Drive. O destinatário recebe
um e-mail com o link autorizado.

A APK distribuída:

- é uma build `debug` com o mesmo application id e assinatura debug do app;
- consulta a API de produção em `https://robo-de-produtos.vercel.app`;
- desativa o App Check por `--dart-define=ATIVAR_APP_CHECK=false`;
- não representa homologação nem uma publicação de release.

Ficam fora deste contrato ambiente de homologação, deploy da API, assinatura
release, publicação na Google Play e distribuição pública.

## 2. Contrato funcional

| ID | Regra |
|---|---|
| RF-APK-01 | `app-robo.yml` valida dependências, formatação, análise e testes mobile antes de qualquer distribuição. |
| RF-APK-02 | Pull requests apenas validam. A distribuição ocorre em push na `main` feito por pessoa ou em execução manual com `distribuir=true`. |
| RF-APK-03 | Execuções da `main` usam concorrência própria e cancelam a distribuição anterior ainda ativa; commits de `github-actions[bot]` não geram uma segunda entrega. |
| RF-APK-04 | O build usa `flutter build apk --debug`, número monotônico derivado da execução/tentativa e nome com versão, execução e SHA curto. |
| RF-APK-05 | A APK não é anexada ao e-mail nem publicada como artifact do GitHub; o único canal de entrega é o arquivo privado do Drive. |
| RF-APK-06 | O Drive usa OAuth com escopo `drive.file`, pasta identificada por secret e ACL direta para o proprietário e `EMAIL_DESTINO`. Permissões `anyone`, `domain` e usuários não autorizados fazem a execução falhar. |
| RF-APK-07 | O upload é idempotente por execução: rerun reutiliza/atualiza o arquivo identificado por `run_key`, sem duplicar a APK. Somente arquivos marcados `radar_apk=true` na pasta configurada entram na retenção, limitada às 10 versões mais recentes. |
| RF-APK-08 | O e-mail SMTP SSL só é enviado depois da confirmação do upload e da ACL. A mensagem informa versão, execução, SHA, API de produção, natureza debug e limitações de atualização por assinatura/application id. |
| RF-APK-09 | Falha de build, upload ou ACL não envia e-mail. Falha de SMTP mantém a APK privada e deixa o workflow vermelho para permitir rerun. |

## 3. Implementação versionada

| Arquivo | Responsabilidade |
|---|---|
| `.github/workflows/app-robo.yml` | Gate Flutter, build da APK, concorrência e acionamento condicional da distribuição. |
| `.github/scripts/distribuir_apk_drive.py` | OAuth Drive, upload idempotente, verificação de ACL, retenção e SMTP. |
| `.github/scripts/configurar_drive_apk.py` | Atalho local para o bootstrap OAuth; não grava credenciais no repositório. |
| `.github/scripts/test_distribuir_apk_drive.py` | Testes unitários das regras do helper sem rede. |
| `.github/README.md` | Operação do workflow e nomes dos secrets. |

Os secrets usados pelo job são `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`,
`GOOGLE_DRIVE_REFRESH_TOKEN`, `GOOGLE_DRIVE_FOLDER_ID`, `EMAIL_REMETENTE`,
`EMAIL_DESTINO` e `SENHA_APP_GMAIL`. Nenhum valor de secret, token ou senha é
versionado ou impresso no log.

## 4. Estado de aceite

### Confirmado

- bootstrap OAuth e criação/conferência da pasta privada;
- cadastro dos três secrets do Drive no GitHub Actions;
- execução manual `34148748135`, com APK
  `robo-app-debug-1.64.0-34148748135-db433367.apk` compilada, enviada ao Drive,
  ACL privada confirmada e e-mail enviado;
- testes unitários do helper e compilação sintática Python.

### Externo e ainda pendente

- colocar o cliente OAuth do Drive em `Production`; enquanto permanecer em
  `Testing`, o refresh token pode exigir renovação após o prazo do Google;
- instalar a APK sobre a versão existente no Samsung e confirmar a atualização;
- confirmar visualmente, com a conta destinatária e uma conta não autorizada,
  o acesso permitido e negado no Drive;
- confirmar em uma execução posterior o comportamento de push na `main` e a
  retenção após mais de 10 builds.

Esses itens não impedem considerar a implementação do fluxo concluída, mas
continuam registrados em [`docs/PENDENCIAS.md`](../PENDENCIAS.md) porque não
podem ser provados somente pelo repositório.

