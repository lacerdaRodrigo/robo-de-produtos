-- Registro dos disparos manuais do robo, pedidos pelo botao do site.
--
-- Existe por causa de RNF02, que e compromisso de conduta e nao detalhe
-- tecnico: o projeto se propoe a bater na pagina da Livelo poucas vezes por
-- dia, com identificacao honesta e sem evasao. Um botao sem trava
-- transformaria isso em dezenas de requisicoes numa tarde de cadastro.
--
-- A contagem mora no banco, e nao em memoria, pelo mesmo motivo da tabela de
-- tentativas de login: o site roda em funcoes serverless, e cada requisicao
-- pode cair numa instancia diferente.

CREATE TABLE IF NOT EXISTS disparo_manual (
    id      SERIAL PRIMARY KEY,
    momento TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_disparo_momento ON disparo_manual (momento DESC);
