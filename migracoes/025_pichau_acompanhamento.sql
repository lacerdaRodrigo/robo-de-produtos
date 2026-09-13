-- Acompanhamento administrativo de produtos Pichau.
-- A migration e idempotente e deve ser aplicada pela operacao de banco;
-- este commit nao executa SQL nem publica ambiente.

ALTER TABLE pichau_produto
    ADD COLUMN IF NOT EXISTS acompanhada BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX IF NOT EXISTS idx_pichau_produto_acompanhada_nome
    ON pichau_produto (nome, id_externo)
    WHERE acompanhada = TRUE;

COMMENT ON COLUMN pichau_produto.acompanhada IS
    'Selecao administrativa do produto para acompanhamento; nao altera a coleta do catalogo.';
