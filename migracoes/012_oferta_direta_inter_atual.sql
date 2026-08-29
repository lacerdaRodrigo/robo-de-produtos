-- Repara a divergência histórica entre o schema de produção e as migrações.
--
-- A tabela já existe em produção e integra a lista fixa da limpeza Inter do
-- PRD-V5. O CREATE idempotente permite reconstruir um banco descartável sem
-- alterar instalações que já possuem a estrutura.

CREATE TABLE IF NOT EXISTS oferta_direta_inter_atual (
    produto_direto_inter_id         BIGINT PRIMARY KEY
                                      REFERENCES produto_direto_inter (id)
                                      ON DELETE CASCADE,
    execucao_loja_produtos_inter_id BIGINT NOT NULL
                                      REFERENCES execucao_loja_produtos_inter (id)
                                      ON DELETE RESTRICT,
    momento                         TIMESTAMPTZ NOT NULL,
    parcelamento                    TEXT CHECK (char_length(parcelamento) <= 300),
    estoque                         INTEGER CHECK (estoque BETWEEN 0 AND 10000000),
    etiquetas                       TEXT[] NOT NULL DEFAULT '{}',
    preco_lista_texto               TEXT CHECK (char_length(preco_lista_texto) <= 300),
    preco_lista                     NUMERIC(12, 2) CHECK (
                                        preco_lista BETWEEN 0 AND 100000000
                                    ),
    desconto_texto                  TEXT CHECK (char_length(desconto_texto) <= 300),
    desconto_valor                  NUMERIC(12, 2) CHECK (
                                        desconto_valor BETWEEN 0 AND 100000000
                                    ),
    desconto_percentual_texto       TEXT CHECK (
                                        char_length(desconto_percentual_texto) <= 300
                                    ),
    desconto_percentual             NUMERIC(5, 2) CHECK (
                                        desconto_percentual BETWEEN 0 AND 100
                                    ),
    preco_atual_texto               TEXT NOT NULL CHECK (
                                        char_length(preco_atual_texto) <= 300
                                    ),
    preco_atual                     NUMERIC(12, 2) NOT NULL CHECK (
                                        preco_atual BETWEEN 0 AND 100000000
                                    ),
    cashback_texto                  TEXT CHECK (char_length(cashback_texto) <= 300),
    cashback_valor                  NUMERIC(12, 2) CHECK (
                                        cashback_valor BETWEEN 0 AND 100000000
                                    ),
    cashback_percentual_texto       TEXT CHECK (
                                        char_length(cashback_percentual_texto) <= 300
                                    ),
    cashback_percentual             NUMERIC(5, 2) CHECK (
                                        cashback_percentual BETWEEN 0 AND 100
                                    ),
    preco_liquido_texto             TEXT CHECK (char_length(preco_liquido_texto) <= 300),
    preco_liquido                   NUMERIC(12, 2) CHECK (
                                        preco_liquido BETWEEN 0 AND 100000000
                                    )
);

CREATE INDEX IF NOT EXISTS idx_oferta_direta_inter_preco
    ON oferta_direta_inter_atual (preco_atual);
