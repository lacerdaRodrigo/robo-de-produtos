-- Limite de tentativas de login do site (PRD V2, secao 9.0).
--
-- A autenticacao e por senha unica, e senha unica sem limite de tentativas
-- cai por forca bruta. A contagem mora no banco, e nao em memoria, porque o
-- site roda em funcoes serverless: cada requisicao pode cair numa instancia
-- diferente, e um contador em memoria protegeria uma instancia so.

CREATE TABLE IF NOT EXISTS tentativa_login (
    id      SERIAL PRIMARY KEY,
    origem  TEXT NOT NULL,
    momento TIMESTAMPTZ NOT NULL DEFAULT now(),
    sucesso BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_tentativa_origem_momento
    ON tentativa_login (origem, momento DESC);
