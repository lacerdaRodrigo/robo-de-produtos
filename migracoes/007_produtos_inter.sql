-- V4: catalogo local de produtos do Compre direto, isolado da V3.
-- A publicacao e atomica por loja: o processo prepara tudo em memoria e
-- esta migracao mantem snapshot atual e medicoes historicas separados.

CREATE TABLE IF NOT EXISTS loja_direta_inter (
    id              BIGSERIAL PRIMARY KEY,
    id_externo      TEXT NOT NULL UNIQUE CHECK (char_length(id_externo) <= 200),
    slug            TEXT NOT NULL UNIQUE CHECK (char_length(slug) <= 200),
    nome            TEXT NOT NULL CHECK (char_length(nome) <= 1000),
    nome_busca      TEXT NOT NULL,
    slug_busca      TEXT NOT NULL,
    selecionada     BOOLEAN NOT NULL DEFAULT FALSE,
    ativa           BOOLEAN NOT NULL DEFAULT TRUE,
    vista_em        TIMESTAMPTZ NOT NULL,
    atualizada_em   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_loja_direta_inter_nome_busca
    ON loja_direta_inter (nome_busca);
CREATE INDEX IF NOT EXISTS idx_loja_direta_inter_selecionada
    ON loja_direta_inter (selecionada, ativa) WHERE selecionada = TRUE;

CREATE TABLE IF NOT EXISTS execucao_loja_produtos_inter (
    id                      BIGSERIAL PRIMARY KEY,
    loja_direta_inter_id    BIGINT NOT NULL REFERENCES loja_direta_inter (id) ON DELETE RESTRICT,
    iniciada_em             TIMESTAMPTZ NOT NULL,
    concluida_em            TIMESTAMPTZ,
    estado                  TEXT NOT NULL CHECK (estado IN ('iniciada', 'sucesso', 'falha')),
    total_declarado         INTEGER NOT NULL DEFAULT 0 CHECK (total_declarado >= 0),
    paginas                 INTEGER NOT NULL DEFAULT 0 CHECK (paginas >= 0),
    itens_lidos             INTEGER NOT NULL DEFAULT 0 CHECK (itens_lidos >= 0),
    itens_unicos            INTEGER NOT NULL DEFAULT 0 CHECK (itens_unicos >= 0),
    duplicados              INTEGER NOT NULL DEFAULT 0 CHECK (duplicados >= 0),
    codigo_falha            TEXT CHECK (codigo_falha IN (
                                'rede', 'http', 'resposta_grande', 'json_invalido',
                                'schema_invalido', 'catalogo_pequeno', 'offset_incoerente',
                                'total_incoerente', 'pagina_repetida',
                                'limite_paginacao', 'banco', 'inesperada'
                            )),
    versao                  TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_execucao_loja_produtos_inter_loja
    ON execucao_loja_produtos_inter (loja_direta_inter_id, iniciada_em DESC);
CREATE INDEX IF NOT EXISTS idx_execucao_loja_produtos_inter_sucesso
    ON execucao_loja_produtos_inter (concluida_em DESC) WHERE estado = 'sucesso';

CREATE TABLE IF NOT EXISTS produto_direto_inter (
    id                              BIGSERIAL PRIMARY KEY,
    loja_direta_inter_id            BIGINT NOT NULL REFERENCES loja_direta_inter (id) ON DELETE RESTRICT,
    id_externo                      TEXT NOT NULL CHECK (char_length(id_externo) <= 200),
    nome                            TEXT NOT NULL CHECK (char_length(nome) <= 1000),
    nome_busca                      TEXT NOT NULL,
    marca                           TEXT CHECK (char_length(marca) <= 500),
    categoria                       TEXT CHECK (char_length(categoria) <= 500),
    caminho                         TEXT NOT NULL CHECK (
                                      caminho LIKE '/%' AND caminho NOT LIKE '//%'
                                  ),
    preco_cheio_texto               TEXT CHECK (char_length(preco_cheio_texto) <= 500),
    preco_cheio_valor               NUMERIC(14, 2) CHECK (preco_cheio_valor >= 0),
    preco_atual_texto               TEXT CHECK (char_length(preco_atual_texto) <= 500),
    preco_atual_valor               NUMERIC(14, 2) CHECK (preco_atual_valor >= 0),
    desconto_texto                  TEXT CHECK (char_length(desconto_texto) <= 500),
    desconto_valor                  NUMERIC(14, 2) CHECK (desconto_valor >= 0),
    desconto_percentual_texto       TEXT CHECK (char_length(desconto_percentual_texto) <= 500),
    desconto_percentual_valor       NUMERIC(5, 2) CHECK (desconto_percentual_valor BETWEEN 0 AND 100),
    cashback_texto                  TEXT CHECK (char_length(cashback_texto) <= 500),
    cashback_valor                  NUMERIC(14, 2) CHECK (cashback_valor >= 0),
    cashback_percentual_texto       TEXT CHECK (char_length(cashback_percentual_texto) <= 500),
    cashback_percentual_valor       NUMERIC(5, 2) CHECK (cashback_percentual_valor BETWEEN 0 AND 100),
    preco_liquido_texto             TEXT CHECK (char_length(preco_liquido_texto) <= 500),
    preco_liquido_valor             NUMERIC(14, 2) CHECK (preco_liquido_valor >= 0),
    parcelamento                    TEXT CHECK (char_length(parcelamento) <= 500),
    estoque                         TEXT CHECK (char_length(estoque) <= 500),
    etiquetas                       TEXT[] NOT NULL DEFAULT '{}',
    ativo                           BOOLEAN NOT NULL DEFAULT TRUE,
    atualizada_em                   TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (loja_direta_inter_id, id_externo)
);

CREATE INDEX IF NOT EXISTS idx_produto_direto_inter_busca
    ON produto_direto_inter (loja_direta_inter_id, ativo, preco_atual_valor, nome);
CREATE INDEX IF NOT EXISTS idx_produto_direto_inter_nome_busca
    ON produto_direto_inter (nome_busca);

CREATE TABLE IF NOT EXISTS medicao_produto_inter (
    id                                  BIGSERIAL PRIMARY KEY,
    produto_direto_inter_id             BIGINT NOT NULL REFERENCES produto_direto_inter (id) ON DELETE CASCADE,
    execucao_loja_produtos_inter_id     BIGINT NOT NULL REFERENCES execucao_loja_produtos_inter (id) ON DELETE CASCADE,
    momento                             TIMESTAMPTZ NOT NULL,
    preco_atual_valor                   NUMERIC(14, 2) CHECK (preco_atual_valor >= 0),
    cashback_valor                      NUMERIC(14, 2) CHECK (cashback_valor >= 0),
    preco_liquido_valor                 NUMERIC(14, 2) CHECK (preco_liquido_valor >= 0),
    UNIQUE (produto_direto_inter_id, execucao_loja_produtos_inter_id)
);

CREATE INDEX IF NOT EXISTS idx_medicao_produto_inter_historico
    ON medicao_produto_inter (produto_direto_inter_id, momento DESC);
CREATE INDEX IF NOT EXISTS idx_medicao_produto_inter_expurgo
    ON medicao_produto_inter (momento);
