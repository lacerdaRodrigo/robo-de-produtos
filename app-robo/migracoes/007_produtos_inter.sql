-- V4: catalogo local de produtos do Compre direto, isolado da V3.
--
-- A rodada possui uma execucao coordenadora e uma execucao por loja. Cada
-- loja prepara o catalogo em staging e publica identidades + medicoes numa
-- unica transacao. Assim uma falha nunca apaga o ultimo snapshot valido.

CREATE TABLE IF NOT EXISTS loja_direta_inter (
    id              BIGSERIAL PRIMARY KEY,
    id_externo      TEXT NOT NULL UNIQUE CHECK (char_length(id_externo) <= 200),
    slug            TEXT NOT NULL UNIQUE CHECK (char_length(slug) <= 200),
    nome            TEXT NOT NULL CHECK (char_length(nome) <= 1000),
    nome_busca      TEXT NOT NULL,
    selecionada     BOOLEAN NOT NULL DEFAULT FALSE,
    ativa           BOOLEAN NOT NULL DEFAULT TRUE,
    vista_em        TIMESTAMPTZ NOT NULL,
    atualizada_em   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_loja_direta_inter_busca
    ON loja_direta_inter (nome_busca);
CREATE INDEX IF NOT EXISTS idx_loja_direta_inter_selecionada
    ON loja_direta_inter (nome) WHERE selecionada = TRUE AND ativa = TRUE;

CREATE TABLE IF NOT EXISTS execucao_produtos_inter (
    id                  BIGSERIAL PRIMARY KEY,
    iniciada_em         TIMESTAMPTZ NOT NULL,
    concluida_em        TIMESTAMPTZ,
    estado              TEXT NOT NULL CHECK (estado IN ('iniciada', 'sucesso', 'parcial', 'falha')),
    lojas_planejadas    INTEGER NOT NULL DEFAULT 0 CHECK (lojas_planejadas >= 0),
    lojas_sucesso       INTEGER NOT NULL DEFAULT 0 CHECK (lojas_sucesso >= 0),
    lojas_falha         INTEGER NOT NULL DEFAULT 0 CHECK (lojas_falha >= 0),
    codigo_falha        TEXT CHECK (codigo_falha IN (
                            'rede', 'http', 'resposta_grande', 'json_invalido',
                            'schema_invalido', 'catalogo_pequeno', 'banco', 'inesperada'
                        )),
    versao              TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_execucao_produtos_inter_sucesso
    ON execucao_produtos_inter (concluida_em DESC) WHERE estado = 'sucesso';

CREATE TABLE IF NOT EXISTS execucao_loja_produtos_inter (
    id                          BIGSERIAL PRIMARY KEY,
    execucao_produtos_inter_id  BIGINT NOT NULL REFERENCES execucao_produtos_inter (id)
                                  ON DELETE CASCADE,
    loja_direta_inter_id        BIGINT NOT NULL REFERENCES loja_direta_inter (id)
                                  ON DELETE RESTRICT,
    iniciada_em                 TIMESTAMPTZ NOT NULL,
    concluida_em                TIMESTAMPTZ,
    estado                      TEXT NOT NULL CHECK (estado IN ('iniciada', 'sucesso', 'falha')),
    total_declarado             INTEGER CHECK (total_declarado >= 0),
    paginas                     INTEGER NOT NULL DEFAULT 0 CHECK (paginas >= 0),
    produtos_lidos              INTEGER NOT NULL DEFAULT 0 CHECK (produtos_lidos >= 0),
    produtos_unicos             INTEGER NOT NULL DEFAULT 0 CHECK (produtos_unicos >= 0),
    duplicados                  INTEGER NOT NULL DEFAULT 0 CHECK (duplicados >= 0),
    codigo_falha                TEXT CHECK (codigo_falha IN (
                                    'rede', 'http', 'resposta_grande', 'json_invalido',
                                    'schema_invalido', 'catalogo_pequeno', 'offset_incoerente',
                                    'total_incoerente', 'pagina_repetida',
                                    'limite_paginacao', 'banco', 'inesperada'
                                )),
    UNIQUE (execucao_produtos_inter_id, loja_direta_inter_id)
);

CREATE INDEX IF NOT EXISTS idx_execucao_loja_produtos_inter_loja
    ON execucao_loja_produtos_inter (loja_direta_inter_id, concluida_em DESC);

CREATE TABLE IF NOT EXISTS estagio_produto_inter (
    execucao_loja_produtos_inter_id BIGINT NOT NULL
                                      REFERENCES execucao_loja_produtos_inter (id)
                                      ON DELETE CASCADE,
    id_externo                      TEXT NOT NULL CHECK (char_length(id_externo) <= 200),
    nome                            TEXT NOT NULL CHECK (char_length(nome) <= 1000),
    nome_busca                      TEXT NOT NULL,
    caminho                         TEXT NOT NULL CHECK (
                                        char_length(caminho) <= 2000
                                        AND caminho LIKE '/%'
                                        AND caminho NOT LIKE '//%'
                                    ),
    marca                           TEXT CHECK (char_length(marca) <= 500),
    categoria                       TEXT CHECK (char_length(categoria) <= 500),
    parcelamento                    TEXT CHECK (char_length(parcelamento) <= 500),
    estoque                         INTEGER CHECK (estoque BETWEEN 0 AND 10000000),
    etiquetas                       TEXT[] NOT NULL DEFAULT '{}',
    preco_lista_texto               TEXT CHECK (char_length(preco_lista_texto) <= 500),
    preco_lista                     NUMERIC(14, 2) CHECK (preco_lista >= 0),
    desconto_texto                  TEXT CHECK (char_length(desconto_texto) <= 500),
    desconto_valor                  NUMERIC(14, 2) CHECK (desconto_valor >= 0),
    desconto_percentual_texto       TEXT CHECK (char_length(desconto_percentual_texto) <= 500),
    desconto_percentual             NUMERIC(5, 2) CHECK (desconto_percentual BETWEEN 0 AND 100),
    preco_atual_texto               TEXT NOT NULL CHECK (char_length(preco_atual_texto) <= 500),
    preco_atual                     NUMERIC(14, 2) NOT NULL CHECK (preco_atual >= 0),
    cashback_texto                  TEXT CHECK (char_length(cashback_texto) <= 500),
    cashback_valor                  NUMERIC(14, 2) CHECK (cashback_valor >= 0),
    cashback_percentual_texto       TEXT CHECK (char_length(cashback_percentual_texto) <= 500),
    cashback_percentual             NUMERIC(5, 2) CHECK (cashback_percentual BETWEEN 0 AND 100),
    preco_liquido_texto             TEXT CHECK (char_length(preco_liquido_texto) <= 500),
    preco_liquido                   NUMERIC(14, 2) CHECK (preco_liquido >= 0),
    PRIMARY KEY (execucao_loja_produtos_inter_id, id_externo)
);

CREATE TABLE IF NOT EXISTS produto_direto_inter (
    id                      BIGSERIAL PRIMARY KEY,
    loja_direta_inter_id    BIGINT NOT NULL REFERENCES loja_direta_inter (id)
                              ON DELETE RESTRICT,
    id_externo              TEXT NOT NULL CHECK (char_length(id_externo) <= 200),
    nome                    TEXT NOT NULL CHECK (char_length(nome) <= 1000),
    nome_busca              TEXT NOT NULL,
    caminho                 TEXT NOT NULL CHECK (
                                char_length(caminho) <= 2000
                                AND caminho LIKE '/%'
                                AND caminho NOT LIKE '//%'
                            ),
    marca                   TEXT CHECK (char_length(marca) <= 500),
    categoria               TEXT CHECK (char_length(categoria) <= 500),
    ativo                   BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em               TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (loja_direta_inter_id, id_externo)
);

CREATE INDEX IF NOT EXISTS idx_produto_direto_inter_busca
    ON produto_direto_inter (loja_direta_inter_id, nome_busca) WHERE ativo = TRUE;

CREATE TABLE IF NOT EXISTS medicao_produto_direto_inter (
    id                                  BIGSERIAL PRIMARY KEY,
    produto_direto_inter_id             BIGINT NOT NULL REFERENCES produto_direto_inter (id)
                                          ON DELETE RESTRICT,
    execucao_loja_produtos_inter_id     BIGINT NOT NULL
                                          REFERENCES execucao_loja_produtos_inter (id)
                                          ON DELETE CASCADE,
    momento                             TIMESTAMPTZ NOT NULL,
    preco_lista_texto                   TEXT CHECK (char_length(preco_lista_texto) <= 500),
    preco_lista                         NUMERIC(14, 2) CHECK (preco_lista >= 0),
    desconto_texto                      TEXT CHECK (char_length(desconto_texto) <= 500),
    desconto_valor                      NUMERIC(14, 2) CHECK (desconto_valor >= 0),
    desconto_percentual_texto           TEXT CHECK (char_length(desconto_percentual_texto) <= 500),
    desconto_percentual                 NUMERIC(5, 2) CHECK (desconto_percentual BETWEEN 0 AND 100),
    preco_atual_texto                   TEXT NOT NULL CHECK (char_length(preco_atual_texto) <= 500),
    preco_atual                         NUMERIC(14, 2) NOT NULL CHECK (preco_atual >= 0),
    cashback_texto                      TEXT CHECK (char_length(cashback_texto) <= 500),
    cashback_valor                      NUMERIC(14, 2) CHECK (cashback_valor >= 0),
    cashback_percentual_texto           TEXT CHECK (char_length(cashback_percentual_texto) <= 500),
    cashback_percentual                 NUMERIC(5, 2) CHECK (cashback_percentual BETWEEN 0 AND 100),
    preco_liquido_texto                 TEXT CHECK (char_length(preco_liquido_texto) <= 500),
    preco_liquido                       NUMERIC(14, 2) CHECK (preco_liquido >= 0),
    parcelamento                        TEXT CHECK (char_length(parcelamento) <= 500),
    estoque                             INTEGER CHECK (estoque BETWEEN 0 AND 10000000),
    etiquetas                           TEXT[] NOT NULL DEFAULT '{}',
    UNIQUE (execucao_loja_produtos_inter_id, produto_direto_inter_id)
);

CREATE INDEX IF NOT EXISTS idx_medicao_produto_direto_inter_historico
    ON medicao_produto_direto_inter (produto_direto_inter_id, momento DESC);
CREATE INDEX IF NOT EXISTS idx_medicao_produto_direto_inter_expurgo
    ON medicao_produto_direto_inter (momento);
