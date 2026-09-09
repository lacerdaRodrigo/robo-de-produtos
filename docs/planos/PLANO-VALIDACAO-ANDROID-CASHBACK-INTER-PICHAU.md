# Plano e registro — validação Android e Pichau

**Status:** encerrado — jornada do app, Wireless Debugging e coleta Pichau validados

**Data de início:** 2026-09-07

**Última atualização:** 2026-09-08

## Objetivo

Validar no Samsung conectado ao Wi-Fi o retorno do Termux:Boot após reinício,
o aplicativo mobile na jornada Pichau e a coleta Pichau com `pageSize=200`,
sem depender de cabo USB. Livelo e Inter estão fora deste ciclo.

## Ordem operacional

1. Confirmar ADB, Android desbloqueado, worker, Appium e job 7301 após o reboot.
2. Instalar/abrir o APK e validar a jornada Pichau no device.
3. Executar os testes unitários/widgets diretamente relacionados e os gates
   estáticos.
4. [x] Disparar coletas reais Pichau e medir o banco/logs do Android.
5. [x] Encerrar a validação após a execução real completa pelo Wi-Fi.
6. [x] Parear e validar Wireless Debugging como transporte operacional único,
   sem dependência de USB.

## Critérios de aceite

- Worker, Appium e job 7301 voltam após reinício e primeiro desbloqueio.
- Nenhuma coleta ocorre sem solicitação pendente.
- A execução real `34302348225` publica a coleta completa pelo Wi-Fi, sem cabo,
  com estado sucesso; o runner encerra em aproximadamente 2m20s incluindo a
  espera da fila.
- Nenhuma senha ou URL de banco aparece no repositório, nos logs ou no APK.

## Estado inicial desta execução

- O Samsung foi reiniciado e desbloqueado pelo responsável.
- O Wireless Debugging pareado foi confirmado como transporte operacional pelo
  Termux, sem cabo USB.
- `sys.boot_completed=1`.
- Processos Termux, Termux:API, Appium Settings e `tmux` estão presentes.
- A validação dos arquivos privados do Termux foi feita por comandos locais sem
  imprimir a credencial do banco.

## Registro de execução

- O retorno pós-reboot foi confirmado: `sys.boot_completed=1`, worker persistente,
  Appium em `127.0.0.1:4723` e job 7301 ativo, sem coleta pendente antes dos
  disparos.
- A execução `34141699813` fechou `1169/1169`, `1169` únicos e zero duplicados,
  mas levou `275831 ms` no runner; é evidência de integridade, não aprovação de
  tempo.
- A execução `34144116813` também fechou completa, com `1169/1169` e zero
  duplicados, em `221851 ms` de runner e `214234 ms` de coleta; serviu como
  evidência histórica antes do ajuste final.
- A execução `34148112344` validou o novo caminho `fetch` com prefetch:
  `1169/1169`, `1169` únicos, zero duplicados, `79630 ms` de coleta e
  `87479 ms` de runner. Foi a primeira rodada real dentro do alvo de 120 s.
- O caminho DOM recebeu preparação CDP para trazer o Chrome à frente e bloquear
  imagens, fontes e telemetria sem uso no catálogo. O caminho experimental de
  resposta de rede foi implementado com fallback para DOM e teste para eventos
  emitidos antes da confirmação do `Page.navigate`.
- A estratégia `fetch` foi ampliada para a primeira página e passou a
  pré-carregar as páginas restantes em paralelo depois de descobrir o total.
  Um ensaio técnico no mesmo Chrome leu as páginas 2–6 em aproximadamente
  36,5 segundos, com 1.169 itens e 200/200/200/200/169 por página.
- A estratégia de rede continua apenas experimental: a resposta SSR foi
  observada, mas a captura pelo cache do inspector não ficou confiável e não foi
  usada no aceite final.
- Após essa rodada, o transporte operacional foi consolidado em Wireless
  Debugging por Wi-Fi, com endpoint reutilizado ou descoberto por mDNS.
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
- O Wireless Debugging pareado passou a ser o transporte operacional do worker.
  A execução real `34302348225` confirmou a descoberta/conexão no Termux, o
  fallback Appium que abre a URL quando falta uma aba DevTools e a publicação
  completa sem cabo USB.

## Encerramento

O plano foi encerrado após a execução `34302348225`. Falhas futuras devem usar
o lease da fila e preservar o último snapshot válido; não reabrem este plano
automaticamente. O Chrome nativo pode aparecer no primeiro plano durante a
criação/recuperação da sessão Appium, porque a coleta usa uma aba DevTools real;
isso não é um modo headless.

O cabo USB não é requisito da validação operacional. A prova final foi feita
com o cabo desconectado; ele permanece apenas como recurso de configuração ou
recuperação.
