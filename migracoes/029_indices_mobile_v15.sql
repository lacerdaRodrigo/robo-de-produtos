-- Índices aditivos para a lista consolidada e o destaque pessoal do Mobile V15.
-- Aplicar manualmente em conexão direta/unpooled, fora de uma transação.
-- Nenhuma tabela, coluna ou linha existente é removida ou alterada.

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_acompanhamento_usuario_lista_v15
    ON acompanhamento_usuario (usuario_app_id, atualizado_em DESC, id DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_evento_alerta_nao_lido_v15
    ON evento_alerta (usuario_app_id, criado_em DESC, id DESC)
    WHERE lido = FALSE;
