# Plano e registro — validação Android e Pichau

**Status:** em execução — jornada do app e transporte validados; série de tempo pendente

**Data de início:** 2026-09-07

**Última atualização:** 2026-09-08

## Objetivo

Validar no Samsung conectado por USB o retorno do Termux:Boot após reinício,
o aplicativo mobile na jornada Pichau e a coleta Pichau com `pageSize=200`. A
configuração de ADB sem fio será preparada como alternativa, sem remover o
cabo durante esta validação. Livelo e Inter estão fora deste ciclo.

## Ordem operacional

1. Confirmar ADB, Android desbloqueado, worker, Appium e job 7301 após o reboot.
2. Instalar/abrir o APK e validar a jornada Pichau no device.
3. Executar os testes unitários/widgets diretamente relacionados e os gates
   estáticos.
4. Disparar três coletas reais Pichau em intervalos mínimos de seis horas.
5. Medir cada rodada no banco e nos logs do Android.
6. [x] Parear e validar Wireless Debugging mantendo o USB conectado e o
   transporte local do worker preservado.

## Critérios de aceite

- Worker, Appium e job 7301 voltam após reinício e primeiro desbloqueio.
- Nenhuma coleta ocorre sem solicitação pendente.
- Três coletas Pichau consecutivas publicam 1.169/1.169, zero duplicados,
  estado completo/sucesso e duração inferior a 120 segundos.
- Nenhuma senha ou URL de banco aparece no repositório, nos logs ou no APK.

## Estado inicial desta execução

- O Samsung `SM-M135M` foi reiniciado e desbloqueado pelo responsável.
- A conexão de gerenciamento permanece `RX8W105DHSY device usb`; o host também
  validou o endpoint Wireless Debugging `192.168.2.128:35613` sem remover o
  cabo.
- `sys.boot_completed=1`.
- Processos Termux, Termux:API, Appium Settings e `tmux` estão presentes.
- A validação dos arquivos privados do Termux será feita por comandos locais sem
  imprimir a credencial do banco.

## Registro de execução

- O retorno pós-reboot foi confirmado: `sys.boot_completed=1`, worker persistente,
  Appium em `127.0.0.1:4723` e job 7301 ativo, sem coleta pendente antes dos
  disparos.
- A execução `34141699813` fechou `1169/1169`, `1169` únicos e zero duplicados,
  mas levou `275831 ms` no runner; é evidência de integridade, não aprovação de
  tempo.
- A execução `34144116813` também fechou completa, com `1169/1169` e zero
  duplicados, em `221851 ms` de runner e `214234 ms` de coleta; o alvo de 120 s
  continua aberto.
- A execução `34148112344` validou o novo caminho `fetch` com prefetch:
  `1169/1169`, `1169` únicos, zero duplicados, `79630 ms` de coleta e
  `87479 ms` de runner. É a primeira rodada real dentro do alvo de 120 s.
- O caminho DOM recebeu preparação CDP para trazer o Chrome à frente e bloquear
  imagens, fontes e telemetria sem uso no catálogo. O caminho experimental de
  resposta de rede foi implementado com fallback para DOM e teste para eventos
  emitidos antes da confirmação do `Page.navigate`.
- A estratégia `fetch` foi ampliada para a primeira página e passou a
  pré-carregar as páginas restantes em paralelo depois de descobrir o total.
  Um ensaio técnico no mesmo Chrome leu as páginas 2–6 em aproximadamente
  36,5 segundos, com 1.169 itens e 200/200/200/200/169 por página.
- A estratégia de rede continua apenas experimental: a resposta SSR foi
  observada, mas a captura pelo cache do inspector não ficou confiável e não é
  contada como uma das três coletas aceitas.
- Após essa rodada, o ADB TCP temporário foi encerrado (`service.adb.tcp.port=0`)
  e o arquivo privado passou a usar o serial USB `RX8W105DHSY`; o cabo segue
  conectado. Essa configuração falhou porque o worker roda dentro do próprio
  Android. O executor foi corrigido para usar novamente `127.0.0.1:5555`,
  mantendo o USB do host conectado para gerenciamento.
- As execuções automáticas `34158686905` e `34174437207` falharam logo após a
  troca para o serial USB. O diagnóstico identificou a ausência de um endpoint
  ADB acessível pelo Android; o runner agora registra o pré-voo e rejeita essa
  configuração. A execução `34182214027` confirmou a correção com publicação
  completa em aproximadamente 73,5 segundos de coleta.
- A aceitação manual do aplicativo no Samsung foi concluída: Serviços → Pichau,
  catálogo real com 1.169 ofertas, paginação nas páginas 1 e 2 de 59, busca
  `ryzen`, histórico com 7 medições, abertura do SKU no Chrome e retorno ao app.
  A tela permaneceu utilizável no modo noturno do sistema e foi restaurada ao
  modo claro.
- O Wireless Debugging pareado foi validado no host e no Termux com
  `adb get-state=device` em `192.168.2.128:35613`. O cabo USB continua conectado
  e o worker não foi migrado para esse endpoint: sua configuração operacional
  permanece `127.0.0.1:5555`.

## Política de tentativa

Se uma coleta real falhar ou não cumprir qualquer critério, a sequência de três
rodadas será reiniciada. Diagnóstico e correção podem ocorrer imediatamente,
mas as novas coletas reais respeitarão pelo menos seis horas entre execuções.

O cabo USB não será removido durante a validação da Pichau. O ADB sem fio foi
pareado e validado como alternativa com o cabo conectado; a prova sem cabo fica
para uma operação posterior específica.
