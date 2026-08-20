# app-robo — Radar de Benefícios

Cliente multiplataforma (Flutter) do Radar de Benefícios. Atende Web, Android e iOS
com o mesmo código, isolado do site legado em `site/`.

> **Estado atual — Fase 2 (bootstrap):** projeto inicializado, tema/tokens aprovados e
> base testável. **Nenhuma tela de domínio migrada ainda.** O plano completo está em
> [`PLANO.md`](PLANO.md); o contrato de API que orienta as Fases 3+ está em
> [`FASE1-Contrato-API.md`](FASE1-Contrato-API.md).

## Alvo atual (importante)

Esta fase valida **somente Web** — não há emulador nem dispositivo móvel nesta máquina.
Android e iOS ficam como scaffold gerado pelo `flutter create`, sem build/validação
local até o plano chegar a essas plataformas.

## Como rodar (web)

```bash
flutter pub get
flutter run -d chrome        # desenvolvimento
flutter build web            # build de produção
```

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
- Contrato da API (paginação, erros, card de produto): `FASE1-Contrato-API.md`