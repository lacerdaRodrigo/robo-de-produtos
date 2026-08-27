# Configuração por ambiente

Este documento é a fonte única para saber **qual configuração existe, onde ela
fica e quem pode recebê-la**. Ele registra nomes e responsabilidades, nunca os
valores reais dos segredos.

GitHub Actions, Vercel e Flutter são processos independentes. Por isso uma
configuração compartilhada, como `DATABASE_URL`, precisa ser cadastrada em cada
servidor que a utiliza. Neon armazena o banco, mas não injeta automaticamente a
credencial nos outros provedores.

## Regra de segurança

- Segredos reais ficam somente no provedor que os utiliza e no gerenciador de
  senhas do responsável.
- Nenhum segredo entra no Git, log, Flutter Web, APK ou IPA.
- O Flutter recebe apenas identificadores e chaves públicas de cliente.
- Arquivos `.env` são apenas para desenvolvimento local e continuam ignorados.
- Os exemplos versionados contêm valores evidentemente falsos.

## GitHub Actions — robôs Python

| Nome | Tipo | Quem usa | Observação |
|---|---|---|---|
| `DATABASE_URL` | segredo | Livelo, Inter Sites e Inter Produtos | Mesma credencial lógica usada pela API, cadastrada separadamente no GitHub |
| `LIMIAR_PARCEIROS` | configuração | Livelo | O workflow usa `150` diretamente |
| `LIMIAR_LOJAS_INTER` | configuração | Inter Sites | O workflow usa `100` diretamente |
| `CAMINHO_CONFIG` | configuração local | Livelo | Opcional; padrão `config/lojas_favoritas.toml` |

Modelo local: `backend/robo/examples/.env.example`.

## Vercel — API

| Nome | Tipo | Obrigatoriedade | Observação |
|---|---|---|---|
| `DATABASE_URL` | segredo | obrigatória | A API lê e administra o Postgres; nunca vai para o Flutter |
| `FIREBASE_PROJECT_ID` | identificador público | obrigatória | Precisa corresponder à conta de serviço e ao projeto do app |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | segredo | obrigatória na Vercel | JSON Firebase Admin em uma linha |
| `SEGREDO_LIMITE_API` | segredo | obrigatória | HMAC usado para pseudonimizar identificadores do rate limit |
| `GITHUB_TOKEN_DISPARO` | segredo | necessária para disparo manual | Token fine-grained, restrito ao repositório e a Actions |
| `EXIGIR_APP_CHECK` | flag pública do servidor | obrigatória | Manter `false` até Web, Android e iOS estarem validados |
| `ALLOWED_ORIGINS` | lista pública | necessária para Flutter Web | Origens HTTPS exatas, separadas por vírgula |
| `DEBUG_AUTH` | diagnóstico | opcional | Manter ausente/`false` em produção; ativar somente durante incidente controlado |

Modelo local: `backend/api/examples/.env.example`.

## Flutter — valores de compilação

O projeto não carrega arquivo `.env`. Os valores entram com `--dart-define` ou
pelos alvos do `app/Makefile`.

| Nome | Tipo | Observação |
|---|---|---|
| `API_URL` | público | URL base HTTPS da API; padrão `https://robo-de-produtos.vercel.app` |
| `ATIVAR_APP_CHECK` | flag pública | Ativa os provedores de App Check do cliente |
| `FIREBASE_RECAPTCHA_SITE_KEY` | chave pública de cliente | Necessária apenas no Flutter Web com App Check |

`firebase_options.dart`, `google-services.json` e `GoogleService-Info.plist`
contêm configuração pública do cliente Firebase. Eles não substituem e não
podem conter a conta de serviço Firebase Admin.

Exemplo:

```bash
flutter run -d chrome \
  --dart-define=API_URL=https://robo-de-produtos.vercel.app \
  --dart-define=ATIVAR_APP_CHECK=false
```

## Neon

Neon é a origem do `DATABASE_URL` e hospeda as tabelas. Ele não deve ser usado
como cofre genérico para Firebase, GitHub ou configurações do Flutter.
O aplicativo nunca se conecta diretamente ao Neon.

## Teste destrutivo isolado

`ACEITE_F5_DESCARTAVEL=true` existe somente para o teste administrativo em
banco descartável. O próprio teste recusa qualquer banco cujo nome não comece
com `radar_aceite_f5_`. Essa chave não deve existir na Vercel nem nos workflows
normais.

## Rotação de um segredo

1. Criar o valor novo no serviço de origem.
2. Atualizar somente os provedores que aparecem nas tabelas acima.
3. Validar o fluxo afetado sem registrar o valor em log.
4. Revogar o valor antigo depois da validação.
5. Anotar data e motivo da rotação em `docs/PENDENCIAS.md`, sem copiar o valor.

Para `DATABASE_URL`, atualizar GitHub Actions e Vercel. Para Firebase Admin e
token de disparo, atualizar somente Vercel.
