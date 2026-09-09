# PRD — distribuição interna da APK

**Status:** implementado; distribuição restrita à `main`.

**Última atualização:** 2026-09-08.

## Objetivo

Depois que uma alteração aprovada chega à `main`, gerar uma APK Android
interna, armazená-la em uma pasta privada do Google Drive e avisar o
destinatário por e-mail. Este fluxo é distribuição técnica interna, não
publicação na Google Play nem ambiente de homologação.

## Gatilhos e limites

- Pull requests e pushes em outras branches somente validam o Flutter.
- Push humano na `main` pode distribuir.
- `workflow_dispatch` distribui apenas quando executado na `main` e com a
  entrada `distribuir=true`.
- Commits do `github-actions[bot]` não distribuem.
- A APK não é publicada como artifact do GitHub.
- A build atual é `debug`, usa assinatura de debug, consulta a API de produção
  e compila com App Check desabilitado. Não deve ser tratada como release.

## Contrato do Drive e e-mail

O helper `.github/scripts/distribuir_apk_drive.py` usa o escopo
`drive.file` e:

1. publica na pasta identificada por `GOOGLE_DRIVE_FOLDER_ID`;
2. marca o arquivo com propriedades da automação e reutiliza o upload em rerun;
3. permite na ACL somente o proprietário e `EMAIL_DESTINO`;
4. exige `role=reader` para o destinatário e rejeita acesso de escrita,
   comentário, grupo, domínio, link público ou usuário desconhecido;
5. conserva as dez APKs marcadas mais recentes, sem tocar em arquivos alheios;
6. envia o e-mail somente depois de validar a ACL.

O e-mail leva o link privado e informa que a build é interna e usa a API de
produção. A APK não é anexada.

## Segredos externos

Os valores existem somente nos GitHub Actions secrets:

- `GOOGLE_DRIVE_OAUTH_CLIENT_JSON`;
- `GOOGLE_DRIVE_REFRESH_TOKEN`;
- `GOOGLE_DRIVE_FOLDER_ID`;
- `EMAIL_DESTINO`;
- `EMAIL_REMETENTE`;
- `SENHA_APP_GMAIL`.

Nenhum valor, token, endereço privado ou link de arquivo deve aparecer no Git
ou nos logs. O OAuth precisa permanecer válido; enquanto o consentimento
estiver em modo de teste, a renovação do token é uma pendência operacional.

## Gates

O job de distribuição depende do gate Flutter. O helper possui testes unitários
para escaping das consultas, retenção, ACL privada, rejeição de link público,
usuário desconhecido e permissões elevadas.

## Pendências antes de publicação pública

- criar assinatura de release e proteger keystore/senhas;
- ativar e aplicar App Check no ambiente correspondente;
- criar homologação separada de produção;
- concluir ficha, privacidade, classificação e distribuição na Google Play;
- confirmar periodicamente a ACL real do Drive e a validade do OAuth.
