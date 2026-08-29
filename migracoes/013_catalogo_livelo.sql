-- Catálogo completo da última coleta válida da Livelo.
--
-- `loja` continua representando somente as lojas acompanhadas. Esta migração
-- é aditiva: não escolhe lojas e não apaga escolhas existentes. Em uma base
-- nova, portanto, o catálogo pode ter centenas de parceiros e `loja` começar
-- vazia. A publicação do robô liga uma loja ao parceiro correspondente dentro
-- da mesma transação que grava a execução.

CREATE TABLE IF NOT EXISTS parceiro_livelo (
    id                       BIGSERIAL PRIMARY KEY,
    id_externo               TEXT NOT NULL UNIQUE,
    nome                     TEXT NOT NULL,
    categorias               TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    pontos_atuais            NUMERIC(8, 2) NOT NULL,
    pontos_anteriores        NUMERIC(8, 2),
    pontos_base              NUMERIC(8, 2),
    pontos_clube             NUMERIC(8, 2),
    moeda                    TEXT NOT NULL,
    prefixo_ate              BOOLEAN NOT NULL DEFAULT FALSE,
    em_promocao              BOOLEAN NOT NULL DEFAULT FALSE,
    campanha                 TEXT,
    descricao_campanha       TEXT,
    inicio_promocao          TIMESTAMPTZ,
    fim_promocao             TIMESTAMPTZ,
    link                     TEXT,
    ativo                    BOOLEAN NOT NULL DEFAULT TRUE,
    atualizado_execucao_id   INTEGER NOT NULL REFERENCES execucao (id) ON DELETE RESTRICT,
    criado_em                TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_parceiro_livelo_ativo_nome
    ON parceiro_livelo (ativo, nome);

ALTER TABLE loja
    ADD COLUMN IF NOT EXISTS parceiro_livelo_id BIGINT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'loja_parceiro_livelo_fk'
    ) THEN
        ALTER TABLE loja
            ADD CONSTRAINT loja_parceiro_livelo_fk
            FOREIGN KEY (parceiro_livelo_id)
            REFERENCES parceiro_livelo (id)
            ON DELETE SET NULL;
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_loja_parceiro_livelo
    ON loja (parceiro_livelo_id)
    WHERE parceiro_livelo_id IS NOT NULL;
