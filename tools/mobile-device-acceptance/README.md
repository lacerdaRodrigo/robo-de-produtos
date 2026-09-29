# Aceite local no Samsung SM-M135M

Runner local autorizado para executar cenários funcionais no Samsung dedicado,
conforme [`docs/prd/PRD-ACEITE-MOBILE-V15.md`](../../docs/prd/PRD-ACEITE-MOBILE-V15.md).
Usa Appium `3.8.0` e UiAutomator2 `8.7.0`, com servidor limitado a
`127.0.0.1`; não é executado pelo CI.

## Pré-requisitos

- Node.js 20.19+ e npm 10+;
- Flutter/Android SDK, `adb` e `apksigner` disponíveis no `PATH`;
- somente o Samsung SM-M135M autorizado conectado por ADB USB;
- app instalado com a mesma assinatura debug para permitir atualização sem
  remover os dados locais;
- usuário já autenticado no app. O runner não coleta nem recebe credenciais.

## Execução

```bash
export ANDROID_SERIAL="serial-do-Samsung-autorizado"
export DEVICE_ACCEPTANCE_BUILD_NUMBER="numero-novo-desta-rodada"
tools/mobile-device-acceptance/build-install.sh
tools/mobile-device-acceptance/run-local.sh
```

O build verifica a assinatura antes de `adb install -r`; se não coincidir,
interrompe sem desinstalar o app nem apagar seus dados. O número de build deve
ser informado em `DEVICE_ACCEPTANCE_BUILD_NUMBER` e ser novo para cada rodada.
O nome de versão é lido de `app/pubspec.yaml`, para instalar o
código atual sem rebaixar a versão exibida. O APK mantém o conjunto ABI universal
para respeitar a ABI que esta ROM Samsung seleciona ao iniciar o processo.

O runner exige que `ANDROID_SERIAL` identifique o Samsung SM-M135M autorizado
como único device ADB. Ele mantém `noReset=true` e não chama limpeza de dados,
migrations, ferramentas de fixture ou endpoints de escrita fora das ações
normais de navegação cobertas pelo roteiro. Se a sessão estiver expirada, ele
para sem tentar fazer login.

Screenshots, resultado JSON e log Appium ficam em
`~/.local/state/radar-mobile-device-acceptance/`, com permissões privadas e
fora do Git. As capturas podem conter dados da conta; não as copiar para PR ou
artefatos públicos. O log Appium fica privado e o runner só registra nome do
cenário e resultado, sem imprimir a árvore da tela ou textos dinâmicos.

O runner não cobre estado de login/logout, usuário comum, sessão Firebase
revogada, eventos FCM novos, atraso de backend, paginação em cardinalidades
forçadas, função destrutiva da migration 033, App Check/Play, outro aparelho,
reboot do Samsung ou coleta com o USB fisicamente desconectado. Esses casos
continuam nas pendências com suas dependências descritas.
