-- Fase 5.2: reserva durável para disparos manuais pela API v1.
--
-- Esta migração é apenas o contrato de banco no repositório. Ela não deve ser
-- aplicada em produção sem uma autorização operacional separada. A reserva
-- impede dois toques/retries de acionarem o mesmo domínio mais de uma vez na
-- janela de cooldown, inclusive quando a API roda em instâncias serverless
-- diferentes.

CREATE TABLE IF NOT EXISTS solicitacao_disparo_app (
    id                  BIGSERIAL PRIMARY KEY,
    dominio             TEXT NOT NULL CHECK (dominio IN ('livelo', 'inter', 'produtos_inter')),
    chave_idempotencia  TEXT NOT NULL CHECK (
                            chave_idempotencia ~ '^[A-Za-z0-9_-]{16,100}$'
                        ),
    usuario_app_id      BIGINT REFERENCES usuario_app (id) ON DELETE SET NULL,
    estado              TEXT NOT NULL CHECK (estado IN ('reservada', 'aceita', 'falha')),
    ativa               BOOLEAN NOT NULL DEFAULT TRUE,
    codigo_falha        TEXT CHECK (codigo_falha IN ('sem-token', 'github', 'interno')),
    criada_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    concluida_em        TIMESTAMPTZ,
    UNIQUE (dominio, chave_idempotencia)
);

-- Só pode existir uma reserva/aceite dentro da janela para cada domínio.
-- A unicidade parcial é a trava transacional: duas instâncias serverless não
-- conseguem inserir duas solicitações ativas ao mesmo tempo.
CREATE UNIQUE INDEX IF NOT EXISTS idx_solicitacao_disparo_app_dominio_ativo
    ON solicitacao_disparo_app (dominio)
    WHERE ativa = TRUE;

CREATE INDEX IF NOT EXISTS idx_solicitacao_disparo_app_dominio_momento
    ON solicitacao_disparo_app (dominio, criada_em DESC);
