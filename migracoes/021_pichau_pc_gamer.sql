-- Catalogo publico de PCs Gamer da Pichau.
-- A migration e idempotente, mas deve ser aplicada pela operacao de banco;
-- este commit nao executa migrations nem publica ambiente.

CREATE TABLE IF NOT EXISTS pichau_execucao (
    id                BIGSERIAL PRIMARY KEY,
    iniciada_em       TIMESTAMPTZ NOT NULL,
    concluida_em      TIMESTAMPTZ,
    estado            TEXT NOT NULL CHECK (estado IN ('iniciada', 'sucesso', 'parcial', 'falha')),
    qualidade         TEXT CHECK (qualidade IS NULL OR qualidade IN ('completa', 'degradada')),
    total_declarado   INTEGER NOT NULL DEFAULT 0 CHECK (total_declarado >= 0),
    paginas           INTEGER NOT NULL DEFAULT 0 CHECK (paginas >= 0),
    itens_lidos       INTEGER NOT NULL DEFAULT 0 CHECK (itens_lidos >= 0),
    itens_unicos      INTEGER NOT NULL DEFAULT 0 CHECK (itens_unicos >= 0),
    duplicados        INTEGER NOT NULL DEFAULT 0 CHECK (duplicados >= 0),
    tentativas        INTEGER NOT NULL DEFAULT 1 CHECK (tentativas >= 1),
    codigo_falha      TEXT,
    versao            TEXT NOT NULL,
    CHECK (concluida_em IS NULL OR concluida_em >= iniciada_em)
);

CREATE TABLE IF NOT EXISTS pichau_produto (
    id                    BIGSERIAL PRIMARY KEY,
    id_externo            TEXT NOT NULL UNIQUE,
    sku                   TEXT,
    nome                  TEXT NOT NULL,
    nome_busca            TEXT NOT NULL,
    marca                 TEXT,
    marca_busca           TEXT NOT NULL DEFAULT '',
    categoria_externa     TEXT NOT NULL DEFAULT 'PC Gamer',
    url_produto           TEXT NOT NULL,
    disponibilidade       TEXT NOT NULL DEFAULT 'nao_informado'
                          CHECK (disponibilidade IN ('disponivel', 'esgotado', 'pre_venda', 'nao_informado')),
    presente_no_catalogo  BOOLEAN NOT NULL DEFAULT TRUE,
    visto_em              TIMESTAMPTZ NOT NULL,
    atualizado_em         TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE pichau_produto
    ADD COLUMN IF NOT EXISTS marca_busca TEXT NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS pichau_medicao (
    id                    BIGSERIAL PRIMARY KEY,
    execucao_id           BIGINT NOT NULL REFERENCES pichau_execucao(id) ON DELETE CASCADE,
    produto_id            BIGINT NOT NULL REFERENCES pichau_produto(id) ON DELETE CASCADE,
    momento               TIMESTAMPTZ NOT NULL,
    preco_original        NUMERIC(14,2),
    preco_original_texto  TEXT,
    preco_pix             NUMERIC(14,2),
    preco_pix_texto       TEXT,
    desconto_pix          NUMERIC(6,2),
    desconto_pix_texto    TEXT,
    preco_cartao          NUMERIC(14,2),
    preco_cartao_texto    TEXT,
    parcelamento          TEXT,
    valor_parcela_texto   TEXT,
    sem_juros             BOOLEAN,
    estoque_texto         TEXT,
    etiquetas              TEXT[] NOT NULL DEFAULT '{}',
    UNIQUE (execucao_id, produto_id)
);

CREATE INDEX IF NOT EXISTS idx_pichau_produto_catalogo_nome
    ON pichau_produto (nome, id_externo)
    WHERE presente_no_catalogo = TRUE;
CREATE INDEX IF NOT EXISTS idx_pichau_produto_busca
    ON pichau_produto (nome_busca, marca_busca, sku);
CREATE INDEX IF NOT EXISTS idx_pichau_medicao_produto_momento
    ON pichau_medicao (produto_id, momento DESC);
CREATE INDEX IF NOT EXISTS idx_pichau_execucao_estado_momento
    ON pichau_execucao (estado, iniciada_em DESC);
