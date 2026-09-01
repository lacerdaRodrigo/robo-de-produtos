# App Check — configuração e rollout

## Providers do aplicativo

| Plataforma | Debug | Profile/release |
| --- | --- | --- |
| Android | `AndroidDebugProvider` | `AndroidPlayIntegrityProvider` |
| iOS | `AppleDebugProvider` | `AppleAppAttestWithDeviceCheckFallbackProvider` |

O projeto tem configuração Firebase para Android e iOS. Plataformas sem
`FirebaseOptions` retornam o estado de configuração pendente antes de ativar o
App Check.

## Dois controles independentes

- Flutter: `ATIVAR_APP_CHECK=true` ativa o provider e o envio do token para a
  API customizada. Ausente ou `false`, não pede nem envia token.
- Backend: somente `EXIGIR_APP_CHECK=true` exige e valida
  `X-Firebase-AppCheck`. Ausente ou `false`, mantém o rollout desligado; a
  autenticação Firebase continua obrigatória.

O SDK injeta tokens automaticamente em serviços Firebase compatíveis, mas não
em uma API HTTP customizada. Por isso o app obtém `getToken()` e adiciona o
header explicitamente.

## Desenvolvimento local Android

1. Execute `make dev-app-check API_URL=http://10.0.2.2:3000` em `app/` com um
   emulador Android e um backend local. Em aparelho físico, use uma URL de
   teste acessível pelo aparelho.
2. Obtenha do log local o token gerado pelo provider de debug.
3. Cadastre-o em Firebase Console > App Check > aplicativo Android > Manage
   debug tokens.
4. Não copie o token para código, arquivo versionado ou relatório.

O valor permanece externo ao repositório. Um token comprometido deve ser
removido no console.

## Variáveis por ambiente

| Ambiente | Flutter/build | Backend |
| --- | --- | --- |
| Local sem App Check | `ATIVAR_APP_CHECK=false` | `EXIGIR_APP_CHECK=false` |
| Local com debug provider | `ATIVAR_APP_CHECK=true` | `EXIGIR_APP_CHECK=false` durante preparação; `true` somente no teste local controlado |
| Build distribuído | `ATIVAR_APP_CHECK=true` | não se aplica ao artefato mobile |
| Produção após rollout | build já distribuído com App Check | `EXIGIR_APP_CHECK=true` |

O backend também precisa de `FIREBASE_PROJECT_ID` e de credencial Firebase
Admin via `FIREBASE_SERVICE_ACCOUNT_JSON` ou Application Default Credentials.
Esses valores são exclusivos do servidor e nunca entram no Flutter.

## Ativação externa futura

Sem alterar produção durante a preparação:

1. Registrar o aplicativo Android no App Check com Play Integrity e confirmar
   o aplicativo/assinatura de distribuição no Google Play.
2. Registrar o aplicativo iOS no App Check com App Attest e confirmar que a
   assinatura/provisionamento preserva o entitlement de produção incluído no
   projeto. O código usa DeviceCheck como fallback em versões sem App Attest.
3. Gerar e cadastrar novamente os tokens de debug necessários, mantendo-os em
   armazenamento seguro e fora do Git.
4. Distribuir e validar os builds com `ATIVAR_APP_CHECK=true` enquanto
   `EXIGIR_APP_CHECK` continua `false`.
5. Confirmar requisições válidas do Android e, se publicado, do iOS.
6. Somente então alterar externamente `EXIGIR_APP_CHECK` para `true` no
   ambiente de produção e testar ausência, token inválido e token válido.

O enforcement de produtos Firebase no console é separado do gate desta API
customizada e deve ser habilitado somente após observar os clientes válidos.
