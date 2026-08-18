-- Esquema inicial do catalogo de lojas favoritas (PRD V2, secao 8.1).
--
-- A garantia mora na camada mais baixa possivel: as regras que o codigo
-- poderia violar por engano viram restricao do banco.

CREATE TABLE IF NOT EXISTS loja (
    id            SERIAL PRIMARY KEY,
    nome          TEXT NOT NULL UNIQUE,
    categoria     TEXT NOT NULL,
    favorita      BOOLEAN NOT NULL DEFAULT TRUE,
    -- NULL significa "usa o padrao global" (RN28).
    multiplicador NUMERIC(5, 2) CHECK (multiplicador > 0),
    piso_pontos   NUMERIC(6, 2) CHECK (piso_pontos >= 0),
    criada_em     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RN04 exige correspondencia exata: "CEA" para C&A, "Booking com" para
-- Booking.com. O apelido e unico entre TODAS as lojas, nao apenas dentro
-- de uma — duas lojas com o mesmo apelido seria ambiguidade silenciosa.
CREATE TABLE IF NOT EXISTS apelido (
    id      SERIAL PRIMARY KEY,
    loja_id INTEGER NOT NULL REFERENCES loja (id) ON DELETE CASCADE,
    texto   TEXT NOT NULL UNIQUE
);

CREATE INDEX IF NOT EXISTS idx_apelido_loja ON apelido (loja_id);

-- Padroes globais e preferencias: multiplicador, piso, assinante_clube.
CREATE TABLE IF NOT EXISTS preferencia (
    chave TEXT PRIMARY KEY,
    valor TEXT NOT NULL
);

INSERT INTO preferencia (chave, valor) VALUES
    ('multiplicador_padrao', '2.0'),
    ('piso_pontos_padrao', '4'),
    ('assinante_clube', 'false')
ON CONFLICT (chave) DO NOTHING;
