-- Estado global de acompanhamento dos produtos Pichau.
-- Esta migration e idempotente; aplicar pela operacao de banco antes do merge.

ALTER TABLE pichau_produto
    ADD COLUMN IF NOT EXISTS acompanhada BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_pichau_produto_acompanhada
    ON pichau_produto (acompanhada, nome, id_externo)
    WHERE acompanhada = TRUE;

COMMENT ON COLUMN pichau_produto.acompanhada IS
    'Selecao administrativa global para acompanhamento de produto Pichau.';
