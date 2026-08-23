# app-robo — Radar de Benefícios

Cliente multiplataforma (Flutter) do Radar de Benefícios. Atende Web, Android e iOS
com o mesmo código, isolado do site legado em `site/`.

> **Estado atual:** as Fases 0 a 5 do piloto estão implementadas; autenticação,
> painéis de leitura e administração continuam usando somente a API v1. No
> redesign incremental, identidade, abertura, login responsivo e a nova moldura
> já receberam aceite no Samsung conectado. O Módulo 3 — Início foi aprovado e
> implementado localmente com o novo resumo autenticado: 147 testes Flutter,
> 91,29% de cobertura e builds Web/APK passaram. Publicação da rota e instalação
> do APK não foram executadas; Web e iOS ainda precisam de aceite visual.
> O plano técnico está em [`PLANO.md`](PLANO.md) e a ordem visual por telas em
> [`PLANO-REDESIGN-POR-TELAS.md`](PLANO-REDESIGN-POR-TELAS.md).

## Plataformas e identificadores

- projeto Firebase: `radarbeneficios`;
- Android `applicationId`: `br.com.radarbeneficios.app`;
- iOS bundle ID: `br.com.radarbeneficios.app`;
- Web, Android e iOS usam as opções públicas geradas em `lib/firebase_options.dart`;
- não existe chave administrativa, senha de usuário ou acesso ao Neon no bundle.

## Preparação do Firebase

No Console Firebase, habilite **Authentication → E-mail/senha**. O piloto não
possui cadastro público: o usuário é criado pelo responsável no console e seu
e-mail também precisa estar convidado e ativo na tabela `usuario_app` da API.

Para atualizar a configuração depois de alterar os apps registrados:

```bash
flutterfire configure \
  --project=radarbeneficios \
  --platforms=android,ios,web \
  --android-package-name=br.com.radarbeneficios.app \
  --ios-bundle-id=br.com.radarbeneficios.app
```

`firebase_options.dart` e `google-services.json` contêm configuração pública do
cliente Firebase, não credenciais do Firebase Admin.

## Como rodar

```bash
flutter pub get
flutter run -d chrome
flutter run -d <id-android>
flutter build web
```

`API_URL` pode ser definido com `--dart-define=API_URL=https://...`. Chamadas
privadas enviam o ID token no Bearer automaticamente. O endpoint
`/api/v1/status` permanece público; `/api/v1/resumo` é autenticado e lê somente
o Postgres do servidor, sem chamar Livelo ou Inter ao atualizar o Início.

O piloto publicado usa:

```bash
flutter run -d <id-android> \
  --dart-define=API_URL=https://robo-livelo.vercel.app
```

App Check deve ser ativado em rollout: primeiro registre e observe os provedores
no Console Firebase; depois compile com `--dart-define=ATIVAR_APP_CHECK=true`.
No Web, informe também `FIREBASE_RECAPTCHA_SITE_KEY`. Só após validar tokens nas
três plataformas defina `EXIGIR_APP_CHECK=true` na API.

Builds debug usam os provedores de depuração oficiais do App Check. O token que
aparece no console deve ser cadastrado no Firebase para teste, nunca commitado.
Builds release usam Play Integrity no Android, App Attest com fallback no iOS e
reCAPTCHA v3 no Web.

O token de depuração do Samsung SM-M135M foi registrado e aceito em 2026-08-20;
o APK com `ATIVAR_APP_CHECK=true` abriu a área autenticada. A API continua com
`EXIGIR_APP_CHECK=false` até o mesmo smoke passar em Web e iOS.

## Qualidade (gates)

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter build web
```

O CI roda esses mesmos gates em `.github/workflows/app-robo.yml` a cada push/PR,
sem enfraquecer os gates de Python (`testes.yml`/Ruff/Pytest) e do site.

## Referência de design

- Paleta e direção visual aprovadas: `PLANO.md §10.2`
- Ordem e aceite das novas telas: `PLANO-REDESIGN-POR-TELAS.md`
- Fontes vetoriais da marca: `../design-app/assets/logo-radar.svg`
- Regras de segurança/dinheiro (sem `double`, sem segredo no cliente): `PLANO.md §6`
- Contrato da API (paginação e erros): `../site/lib/api.ts`
