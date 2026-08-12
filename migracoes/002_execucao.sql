-- Retrato de cada execucao (PRD V2, secao 7.1 e RF15).
--
-- Ate aqui o robo era stateless: cada rodada mostrava o que estava ativo e
-- esquecia. O site da V2.3 precisa responder "quanto a Renner da hoje?" sem
-- abrir a Livelo (O5), e essa resposta so existe durante a execucao. Guardar
-- o retrato e o que transforma o robo em fonte do site.
--
-- Guarda apenas as lojas favoritas, nao os 254 parceiros: e o mesmo recorte
-- que a pagina publica exibe (PRD V2 9.3) e mantem o volume irrelevante
-- diante do free tier do Neon (C08).

CREATE TABLE IF NOT EXISTS execucao (
    id              SERIAL PRIMARY KEY,
    momento         TIMESTAMPTZ NOT NULL,
    parceiros_lidos INTEGER NOT NULL CHECK (parceiros_lidos >= 0),
    alertas         INTEGER NOT NULL CHECK (alertas >= 0),
    versao          TEXT NOT NULL
);

-- RN26: o carimbo da pagina e o `momento` da execucao mais recente. A
-- consulta do site ordena por aqui, entao o indice existe desde o primeiro
-- dia.
CREATE INDEX IF NOT EXISTS idx_execucao_momento ON execucao (momento DESC);

CREATE TABLE IF NOT EXISTS pontuacao (
    id               SERIAL PRIMARY KEY,
    execucao_id      INTEGER NOT NULL REFERENCES execucao (id) ON DELETE CASCADE,
    -- NULL quando a favorita nao apareceu na pagina naquela rodada (RN19):
    -- a linha existe para o site mostrar "nao encontrada", em vez de sumir
    -- com a loja e deixar o leitor achar que ela foi removida do catalogo.
    loja_id          INTEGER REFERENCES loja (id) ON DELETE CASCADE,
    nome             TEXT NOT NULL,
    pontos_atuais    NUMERIC(8, 2),
    pontos_base      NUMERIC(8, 2),
    pontos_clube     NUMERIC(8, 2),
    -- RN30: o numero que o site exibe como "dispara em". Guardado calculado
    -- porque depende da regua daquele momento, e a regua muda com o tempo.
    valor_de_disparo NUMERIC(8, 2),
    moeda            TEXT NOT NULL DEFAULT 'R$',
    prefixo_ate      BOOLEAN NOT NULL DEFAULT FALSE,
    em_promocao      BOOLEAN NOT NULL DEFAULT FALSE,
    alertou          BOOLEAN NOT NULL DEFAULT FALSE,
    campanha         TEXT,
    fim_promocao     TIMESTAMPTZ,
    link             TEXT
);

CREATE INDEX IF NOT EXISTS idx_pontuacao_execucao ON pontuacao (execucao_id);
