# app-robo — Radar de Benefícios

Cliente multiplataforma (Flutter) do Radar de Benefícios. Atende Web, Android e iOS
com o mesmo código, isolado do site legado em `site/`.

> **Estado atual — Fase 4.3 em validação local:** projeto Firebase `radarbeneficios`
> conectado para Web, Android e iOS; login fechado por e-mail/senha, recuperação,
> token na API e gate de convite validados em produção. A migração 010 está no
> Neon, o primeiro convite foi vinculado e o smoke real passou no Samsung
> SM-M135M em 2026-08-20. As telas de domínio continuam no piloto somente leitura
> e o Flutter será a única interface ao fim da transição.
> A Fase 4 começou pelo Android: a navegação inferior adaptativa já foi validada
> no Samsung em retrato, e o painel Livelo real está implementado, testado e
> com builds locais Web/APK gerados e smoke físico concluído no Samsung. O
> painel somente leitura de cashback Inter passou pelos gates locais e aguarda
> apenas o smoke físico no Samsung; o Flutter
> continua lendo exclusivamente a API v1.
> A Fase 4.4 passou pelos gates locais: a busca paginada de produtos, filtros,
> agrupamento por loja e histórico continuam somente leitura e não acessam o
> banco diretamente. Ainda falta o smoke físico no Samsung; o build do site
> legado tem uma pendência técnica independente no Next.js.
> O plano completo e as decisões de contrato estão em [`PLANO.md`](PLANO.md);
> a implementação viva da paginação e dos erros está em `site/lib/api.ts`.

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
privadas enviam o ID token no Bearer automaticamente. O endpoint `/api/v1/status`
permanece público.

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
- Regras de segurança/dinheiro (sem `double`, sem segredo no cliente): `PLANO.md §6`
- Contrato da API (paginação e erros): `../site/lib/api.ts`
