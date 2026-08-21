-- Identidade e protecoes da API usada pelo Flutter (PLANO, Fase 3B).
--
-- O Firebase prova quem apresentou o token. Esta tabela responde uma pergunta
-- diferente: essa pessoa foi convidada, continua ativa e qual papel possui no
-- Radar? Existir no Firebase nunca concede acesso sozinho.

CREATE TABLE IF NOT EXISTS usuario_app (
    id            BIGSERIAL PRIMARY KEY,
    email         TEXT NOT NULL CHECK (char_length(email) BETWEEN 3 AND 320),
    firebase_uid  TEXT UNIQUE CHECK (
                      firebase_uid IS NULL
                      OR char_length(firebase_uid) BETWEEN 1 AND 128
                  ),
    papel         TEXT NOT NULL DEFAULT 'usuario'
                  CHECK (papel IN ('admin', 'usuario')),
    ativo         BOOLEAN NOT NULL DEFAULT TRUE,
    convidado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
    vinculado_em  TIMESTAMPTZ,
    ultimo_acesso_em TIMESTAMPTZ,
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- E-mail no Firebase nao diferencia caixa. A unicidade tambem nao pode.
CREATE UNIQUE INDEX IF NOT EXISTS idx_usuario_app_email_normalizado
    ON usuario_app (lower(email));

-- Rate limit persistente: a Vercel pode atender cada requisicao em uma
-- instancia diferente, portanto contador em memoria nao protegeria a API.
-- A chave e um HMAC; IP, UID e e-mail nunca sao gravados nesta tabela.
CREATE TABLE IF NOT EXISTS limite_requisicao_app (
    chave_hash    TEXT PRIMARY KEY CHECK (char_length(chave_hash) = 64),
    janela_inicio TIMESTAMPTZ NOT NULL DEFAULT now(),
    quantidade    INTEGER NOT NULL DEFAULT 1 CHECK (quantidade > 0),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_limite_requisicao_app_atualizado
    ON limite_requisicao_app (atualizado_em);

-- Auditoria tecnica, sem payload, token, e-mail ou IP bruto. A politica de
-- retencao continua sendo um gate do PLANO; esta migracao nao apaga linhas.
CREATE TABLE IF NOT EXISTS auditoria_app (
    id               BIGSERIAL PRIMARY KEY,
    usuario_app_id   BIGINT REFERENCES usuario_app (id) ON DELETE SET NULL,
    identidade_hash  TEXT CHECK (
                         identidade_hash IS NULL
                         OR char_length(identidade_hash) = 64
                     ),
    origem_hash      TEXT NOT NULL CHECK (char_length(origem_hash) = 64),
    requisicao_id    TEXT NOT NULL CHECK (char_length(requisicao_id) <= 100),
    acao             TEXT NOT NULL CHECK (char_length(acao) <= 100),
    resultado        TEXT NOT NULL CHECK (
                         resultado IN ('sucesso', 'negado', 'falha')
                     ),
    codigo           TEXT NOT NULL CHECK (char_length(codigo) <= 100),
    momento          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_auditoria_app_momento
    ON auditoria_app (momento DESC);
CREATE INDEX IF NOT EXISTS idx_auditoria_app_usuario
    ON auditoria_app (usuario_app_id, momento DESC);
