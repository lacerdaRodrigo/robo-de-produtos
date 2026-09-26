-- Taxonomia editorial das lojas de Sites parceiros do Inter.
-- A fonte pública do Inter não fornece categoria; o catálogo usa o
-- mapeamento aprovado pelo servidor e cai em `outros` quando ainda não há
-- classificação para uma loja.

CREATE TABLE IF NOT EXISTS categoria_cashback_inter (
    codigo       TEXT PRIMARY KEY CHECK (codigo IN (
        'beleza', 'casa', 'eletronicos', 'esporte', 'moda', 'outros', 'pets'
    )),
    nome         TEXT NOT NULL UNIQUE,
    ordem        SMALLINT NOT NULL UNIQUE CHECK (ordem > 0)
);

INSERT INTO categoria_cashback_inter (codigo, nome, ordem) VALUES
    ('beleza', 'Beleza', 1),
    ('casa', 'Casa', 2),
    ('eletronicos', 'Eletrônicos', 3),
    ('esporte', 'Esporte', 4),
    ('moda', 'Moda', 5),
    ('outros', 'Outros', 6),
    ('pets', 'Pets', 7)
ON CONFLICT (codigo) DO UPDATE SET
    nome = EXCLUDED.nome,
    ordem = EXCLUDED.ordem;

CREATE TABLE IF NOT EXISTS mapeamento_categoria_cashback_inter (
    loja_inter_id  BIGINT PRIMARY KEY REFERENCES loja_inter (id) ON DELETE CASCADE,
    categoria      TEXT NOT NULL REFERENCES categoria_cashback_inter (codigo),
    atualizado_em  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mapeamento_categoria_cashback_inter_categoria
    ON mapeamento_categoria_cashback_inter (categoria);
