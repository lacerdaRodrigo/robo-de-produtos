# Pendências

Lista viva somente do que continua aberto. Histórico concluído permanece no Git e nos PRDs; não deve voltar a governar o ciclo atual.

O contrato operacional da branch `re-design` é o [`AGENTS.md`](../AGENTS.md): Flutter mobile, protótipo mobile como fonte visual, unitários/widgets afetados e Web/goldens/integration/E2E fora do gate.

## Ciclo mobile atual

- [ ] Concluir a Central de Alertas somente após fechar seu contrato de dados e histórico; o estado atual continua parcial/placeholder.
- [ ] Fazer conferências manuais no Samsung quando uma entrega mobile exigir aceite físico. Isso não vira smoke automatizado neste ciclo.

## Ações operacionais externas

- [ ] Confirmar operacionalmente a aplicação das migrations `016_preserva_historico_livelo.sql` e `017_qualidade_livelo.sql`. Elas são tratadas externamente; este repositório não registra confirmação de aplicação.
- [ ] Validar a migration `020_categorias_inter_fonte_oficial.sql` em ambiente descartável e decidir sua aplicação somente com autorização explícita. Ela remove a taxonomia Radar obsoleta depois de confirmar que não há seleção legada de categorias.
- [ ] Implementar e validar o mapeamento versionado de navegação do catálogo Inter já aprovado. O recorte deve permanecer dinâmico para qualquer quantidade de lojas ativas e selecionadas, incluindo categorias novas e compartilhadas entre lojas.
- [ ] Fechar o rollout externo do App Check antes de exigir enforcement. Não declarar Web/iOS observados nem enforcement ativo sem confirmação.
- [ ] Confirmar a revogação/rotação de qualquer credencial Gmail antiga e remover secrets externos obsoletos, se ainda existirem. O código e os workflows atuais não possuem envio SMTP/e-mail ativo.

## Legado preservado ou incerto

- [ ] Decidir em ciclo próprio o destino de `ranking_inter.py`, `LINK_SHOPPING_INTER` e `app/lib/inter_preview.dart`; permanecem por contrato de teste/PRD ou possível uso manual.
- [ ] Planejar, em migration futura separada, eventual remoção das tabelas legadas `oferta_direta_inter_atual` e `disparo_manual*`. Não há remoção de schema neste ciclo.
- [ ] Reavaliar o painel Livelo legado somente quando o layout não compacto e a compatibilidade da rota `/api/livelo/painel` deixarem de ser necessários.

## Testes e plataformas adiados

- Goldens, integration, E2E, smoke automatizado, performance e regressão visual continuam preservados para outro ciclo.
- O suporte Web permanece no repositório, mas não é alvo visual nem gate obrigatório da branch mobile.
- Nenhum item acima autoriza deploy, coleta real, alteração de secrets, aplicação de migration ou mudança em produção.
