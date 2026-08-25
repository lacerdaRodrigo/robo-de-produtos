-- Shopping Inter (PRD-V3): catalogo completo, favoritas e snapshots separados
-- das tabelas da Livelo. Esta migracao e idempotente e deve ser aplicada
-- antes do primeiro deploy da V3.1.

CREATE TABLE IF NOT EXISTS loja_inter (
    id                           BIGSERIAL PRIMARY KEY,
    id_externo                   TEXT NOT NULL UNIQUE CHECK (char_length(id_externo) <= 200),
    slug                         TEXT NOT NULL UNIQUE CHECK (char_length(slug) <= 200),
    nome                         TEXT NOT NULL CHECK (char_length(nome) <= 200),
    nome_busca                   TEXT NOT NULL,
    slug_busca                   TEXT NOT NULL,
    cashback_principal_texto     TEXT NOT NULL CHECK (char_length(cashback_principal_texto) <= 300),
    cashback_principal_valor     NUMERIC(8, 2) CHECK (
                                     cashback_principal_valor BETWEEN 0 AND 1000
                                 ),
    cashback_secundario_texto    TEXT CHECK (char_length(cashback_secundario_texto) <= 300),
    cashback_secundario_valor    NUMERIC(8, 2) CHECK (
                                     cashback_secundario_valor BETWEEN 0 AND 1000
                                 ),
    etiqueta                     TEXT CHECK (char_length(etiqueta) <= 300),
    descricao_principal          TEXT CHECK (char_length(descricao_principal) <= 20000),
    descricao_secundaria         TEXT CHECK (char_length(descricao_secundaria) <= 20000),
    ativa                        BOOLEAN NOT NULL DEFAULT TRUE,
    vista_em                     TIMESTAMPTZ NOT NULL,
    atualizada_em                TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_loja_inter_nome_busca ON loja_inter (nome_busca);
CREATE INDEX IF NOT EXISTS idx_loja_inter_slug_busca ON loja_inter (slug_busca);

CREATE TABLE IF NOT EXISTS favorita_inter (
    loja_inter_id BIGINT PRIMARY KEY REFERENCES loja_inter (id) ON DELETE RESTRICT,
    criada_em     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS execucao_inter (
    id                     BIGSERIAL PRIMARY KEY,
    iniciada_em            TIMESTAMPTZ NOT NULL,
    concluida_em           TIMESTAMPTZ,
    estado                 TEXT NOT NULL CHECK (estado IN ('iniciada', 'sucesso', 'falha')),
    lojas_lidas            INTEGER NOT NULL DEFAULT 0 CHECK (lojas_lidas >= 0),
    lojas_validas          INTEGER NOT NULL DEFAULT 0 CHECK (lojas_validas >= 0),
    favoritas_encontradas  INTEGER NOT NULL DEFAULT 0 CHECK (favoritas_encontradas >= 0),
    codigo_falha           TEXT CHECK (codigo_falha IN (
                                 'rede', 'http', 'resposta_grande', 'json_invalido',
                                 'schema_invalido', 'catalogo_pequeno',
                                 'conflito_identidade', 'banco', 'inesperada'
                             )),
    versao                 TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_execucao_inter_inicio
    ON execucao_inter (iniciada_em DESC);
CREATE INDEX IF NOT EXISTS idx_execucao_inter_sucesso
    ON execucao_inter (concluida_em DESC) WHERE estado = 'sucesso';

CREATE TABLE IF NOT EXISTS cashback_inter (
    id                           BIGSERIAL PRIMARY KEY,
    execucao_inter_id            BIGINT NOT NULL REFERENCES execucao_inter (id) ON DELETE CASCADE,
    loja_inter_id                BIGINT NOT NULL REFERENCES loja_inter (id) ON DELETE RESTRICT,
    nome                         TEXT NOT NULL CHECK (char_length(nome) <= 200),
    cashback_principal_texto     TEXT CHECK (char_length(cashback_principal_texto) <= 300),
    cashback_principal_valor     NUMERIC(8, 2) CHECK (
                                     cashback_principal_valor BETWEEN 0 AND 1000
                                 ),
    cashback_secundario_texto    TEXT CHECK (char_length(cashback_secundario_texto) <= 300),
    cashback_secundario_valor    NUMERIC(8, 2) CHECK (
                                     cashback_secundario_valor BETWEEN 0 AND 1000
                                 ),
    etiqueta                     TEXT CHECK (char_length(etiqueta) <= 300),
    descricao_principal          TEXT CHECK (char_length(descricao_principal) <= 20000),
    descricao_secundaria         TEXT CHECK (char_length(descricao_secundaria) <= 20000),
    encontrada                   BOOLEAN NOT NULL,
    UNIQUE (execucao_inter_id, loja_inter_id)
);

CREATE INDEX IF NOT EXISTS idx_cashback_inter_execucao
    ON cashback_inter (execucao_inter_id);

CREATE TABLE IF NOT EXISTS disparo_manual_inter (
    id       BIGSERIAL PRIMARY KEY,
    momento  TIMESTAMPTZ NOT NULL DEFAULT now()
);
