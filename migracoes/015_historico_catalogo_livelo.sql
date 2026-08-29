-- Histórico da Livelo para todo parceiro válido coletado.
--
-- `loja_id` continua representando apenas o acompanhamento. A identidade da
-- medição passa a ser o parceiro do catálogo, estável mesmo sem acompanhamento.

ALTER TABLE pontuacao
    ADD COLUMN IF NOT EXISTS parceiro_livelo_id BIGINT;

-- Recupera a identidade das medições antigas que já pertenciam a uma loja
-- acompanhada. Não inventa passado para parceiros que nunca foram gravados.
UPDATE pontuacao AS p
   SET parceiro_livelo_id = l.parceiro_livelo_id
  FROM loja AS l
 WHERE p.parceiro_livelo_id IS NULL
   AND p.loja_id = l.id
   AND l.parceiro_livelo_id IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'pontuacao_parceiro_livelo_fk'
    ) THEN
        ALTER TABLE pontuacao
            ADD CONSTRAINT pontuacao_parceiro_livelo_fk
            FOREIGN KEY (parceiro_livelo_id)
            REFERENCES parceiro_livelo (id)
            ON DELETE SET NULL;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_pontuacao_parceiro_execucao
    ON pontuacao (parceiro_livelo_id, execucao_id DESC)
    WHERE parceiro_livelo_id IS NOT NULL;
