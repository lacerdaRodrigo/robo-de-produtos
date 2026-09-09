# Pendências

Lista viva somente do que continua aberto em 2026-09-08. Trabalho concluído
permanece no Git e nos PRDs.

## Mobile

- [ ] Concluir a Central de Alertas após fechar contrato de dados, histórico e
  estados; a implementação atual continua parcial.
- [ ] Validar manualmente no Samsung a paginação de Produtos, Livelo, Sites
  parceiros e Compre direto nos limites de 9, 10 e 11 cards.
- [ ] Validar no Samsung a combinação, remoção individual e limpeza dos
  recortes contextuais de Produtos, inclusive `Outros / novas categorias`.
- [ ] Decidir manualmente o comportamento após deixar de acompanhar uma loja no
  Shopping Inter compacto: `Acompanhar` continua visível na lista ou o cartão
  sai da árvore durante o reposicionamento. O teste em
  `app/test/app/navegacao/moldura_test.dart` permanece comentado.
- [ ] Publicar e validar externamente o contrato Pichau de acompanhamento antes
  de distribuir uma APK com a ação habilitada: rota PATCH, resumo, persistência
  e migration correspondente.
- [ ] Decidir se e quando a Pichau entra na busca global de Produtos.

## Pichau no Samsung

- [ ] Confirmar o Wireless Debugging como transporte único: pareamento privado,
  descoberta mDNS e execução após reboot/primeiro desbloqueio sem cabo.
- [ ] Completar mais duas coletas consecutivas em até 120 segundos, com
  `itens_lidos = itens_unicos = total_declarado`, zero duplicados e intervalo
  mínimo de seis horas. A primeira rodada válida terminou em cerca de 73,5 s.
- [ ] Remover o endpoint ADB pareado que aparece offline e confirmar no roteador
  doméstico que não existe encaminhamento de porta para ADB ou Appium.
- [ ] Decidir operacionalmente como lidar com o primeiro desbloqueio após
  reiniciar; o `BootReceiver` não é `directBootAware`.

## Segurança e GitHub — ações externas

- [ ] Apagar o artifact público antigo que contém uma APK debug. O workflow
  atual não publica APK como artifact.
- [ ] Encerrar os três alertas de secret scanning das chaves Firebase como
  configuração cliente esperada, anexando a evidência das restrições por
  aplicativo/API.
- [ ] Criar rulesets para `main` e `develop`, exigir pull request e checks
  obrigatórios, e habilitar exclusão automática da branch após merge.
- [ ] Habilitar Dependabot security updates e code scanning no repositório.
- [ ] Revisar as branches remotas listadas em
  `docs/AUDITORIA-COMPLETA-PROJETO.md` e excluir somente as incorporadas ou
  comprovadamente obsoletas.
- [ ] Conferir a ACL atual da pasta/arquivos de APK no Drive e a validade do
  OAuth; o destinatário deve permanecer apenas como `reader`.
- [ ] Revisar e rotacionar credenciais Gmail/OAuth antigas ou sem uso. O envio
  de e-mail da distribuição da APK está ativo.

## Banco e ambientes

- [ ] Revogar da role `pichau_dispatcher` o `USAGE` das sequências de
  `pichau_execucao`, `pichau_produto` e `pichau_medicao`, preservando
  somente a sequência da fila. Exige autorização para produção.
- [ ] Criar branch/ambiente Neon de desenvolvimento ou homologação e avaliar
  allowlist de IP; hoje existe somente `production`.
- [ ] Confirmar operacionalmente a aplicação das migrations
  `016_preserva_historico_livelo.sql` e `017_qualidade_livelo.sql`.
- [ ] Validar `020_categorias_inter_fonte_oficial.sql` em ambiente
  descartável e decidir aplicação com autorização explícita.
- [ ] Publicar a API com os identificadores/contratos novos antes da APK
  correspondente para evitar incompatibilidade entre cliente e servidor.
- [ ] Definir backup, restauração testada e checklist de migrations antes de
  novas alterações produtivas.

## Release, observabilidade e produto

- [ ] Criar ambiente de homologação separado de produção, incluindo Firebase,
  banco, API e secrets.
- [ ] Configurar assinatura Android de release e guardar keystore, senhas e
  credenciais em secrets protegidos.
- [ ] Fechar o rollout do App Check antes de ativar enforcement.
- [ ] Preparar publicação na Google Play: nome, ícone, screenshots,
  classificação etária, política de privacidade e ficha de segurança de dados.
- [ ] Definir deploy/rollback da API e do aplicativo com aprovação entre
  ambientes.
- [ ] Centralizar logs de app, API e robôs com correlação, retenção e
  sanitização.
- [ ] Criar monitoramento para API, robôs, dados atrasados, autenticação e App
  Check.
- [ ] Completar runbooks dos robôs Livelo e Inter e documentar a API em
  OpenAPI/Swagger.
- [ ] Revisar LGPD, exclusão de conta, suporte e fluxo de “Reportar problema”.

## Escopo adiado

- Integration, E2E, smoke automatizado, performance e regressão visual não
  fazem parte do gate mobile atual.
- Flutter Web permanece no repositório, mas não é alvo visual deste ciclo.
- Nenhum item desta lista autoriza deploy, mudança de secret, migration,
  alteração produtiva ou exclusão remota.
