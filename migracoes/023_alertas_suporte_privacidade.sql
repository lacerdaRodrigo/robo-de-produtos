-- Central de Alertas, suporte e privacidade (V11).
-- Aplicar somente depois das migracoes 001..022, em uma conexao direta.
-- Nenhum dado global de Livelo/Inter e convertido em acompanhamento pessoal:
-- as tabelas abaixo sao uma camada aditiva por usuario_app.

CREATE TABLE IF NOT EXISTS acompanhamento_usuario (
    id             BIGSERIAL PRIMARY KEY,
    usuario_app_id BIGINT NOT NULL REFERENCES usuario_app (id) ON DELETE CASCADE,
    origem         TEXT NOT NULL CHECK (origem IN ('livelo', 'inter_cashback', 'inter_produto')),
    entidade_id    BIGINT NOT NULL CHECK (entidade_id > 0),
    criado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (usuario_app_id, origem, entidade_id)
);
CREATE INDEX IF NOT EXISTS idx_acompanhamento_usuario_origem
    ON acompanhamento_usuario (usuario_app_id, origem, entidade_id);

CREATE TABLE IF NOT EXISTS evento_alerta (
    id                    BIGSERIAL PRIMARY KEY,
    usuario_app_id        BIGINT NOT NULL REFERENCES usuario_app (id) ON DELETE CASCADE,
    acompanhamento_id     BIGINT REFERENCES acompanhamento_usuario (id) ON DELETE SET NULL,
    origem                TEXT NOT NULL CHECK (origem IN ('livelo', 'inter_cashback', 'inter_produto')),
    tipo                  TEXT NOT NULL CHECK (tipo IN ('preco', 'cashback', 'pontuacao')),
    entidade_id           BIGINT NOT NULL CHECK (entidade_id > 0),
    entidade_externa      TEXT,
    entidade_nome         TEXT NOT NULL CHECK (char_length(entidade_nome) BETWEEN 1 AND 1000),
    coleta_id             TEXT NOT NULL CHECK (char_length(coleta_id) BETWEEN 1 AND 120),
    valor_anterior        NUMERIC(20, 6),
    valor_atual           NUMERIC(20, 6) NOT NULL,
    unidade               TEXT NOT NULL CHECK (char_length(unidade) BETWEEN 1 AND 32),
    direcao               TEXT NOT NULL CHECK (direcao IN ('aumento', 'reducao')),
    lido                  BOOLEAN NOT NULL DEFAULT FALSE,
    criado_em             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (usuario_app_id, origem, tipo, entidade_id, coleta_id)
);
CREATE INDEX IF NOT EXISTS idx_evento_alerta_usuario_data
    ON evento_alerta (usuario_app_id, criado_em DESC, id DESC);
CREATE INDEX IF NOT EXISTS idx_evento_alerta_usuario_nao_lido
    ON evento_alerta (usuario_app_id, tipo, criado_em DESC) WHERE lido = FALSE;

CREATE TABLE IF NOT EXISTS preferencia_alerta (
    usuario_app_id BIGINT PRIMARY KEY REFERENCES usuario_app (id) ON DELETE CASCADE,
    push_global    BOOLEAN NOT NULL DEFAULT TRUE,
    preco          BOOLEAN NOT NULL DEFAULT TRUE,
    cashback       BOOLEAN NOT NULL DEFAULT TRUE,
    pontuacao      BOOLEAN NOT NULL DEFAULT TRUE,
    atualizado_em  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS token_fcm_app (
    id             BIGSERIAL PRIMARY KEY,
    usuario_app_id BIGINT NOT NULL REFERENCES usuario_app (id) ON DELETE CASCADE,
    token          TEXT NOT NULL CHECK (char_length(token) BETWEEN 20 AND 4096),
    plataforma     TEXT NOT NULL CHECK (plataforma IN ('android', 'ios', 'web', 'desconhecida')),
    versao_app    TEXT NOT NULL CHECK (char_length(versao_app) BETWEEN 1 AND 80),
    ativo          BOOLEAN NOT NULL DEFAULT TRUE,
    criado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (usuario_app_id, token)
);
CREATE INDEX IF NOT EXISTS idx_token_fcm_app_ativo
    ON token_fcm_app (usuario_app_id, atualizado_em DESC) WHERE ativo = TRUE;

CREATE TABLE IF NOT EXISTS notificacao_outbox_alerta (
    id             BIGSERIAL PRIMARY KEY,
    usuario_app_id BIGINT NOT NULL REFERENCES usuario_app (id) ON DELETE CASCADE,
    origem         TEXT NOT NULL CHECK (origem IN ('livelo', 'inter_cashback', 'inter_produto')),
    coleta_id      TEXT NOT NULL CHECK (char_length(coleta_id) BETWEEN 1 AND 120),
    estado         TEXT NOT NULL DEFAULT 'pendente'
                   CHECK (estado IN ('pendente', 'enviando', 'enviada', 'falha')),
    tentativas     INTEGER NOT NULL DEFAULT 0 CHECK (tentativas >= 0),
    proxima_tentativa_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultimo_erro    TEXT CHECK (ultimo_erro IS NULL OR char_length(ultimo_erro) <= 200),
    criado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (usuario_app_id, origem, coleta_id)
);
CREATE INDEX IF NOT EXISTS idx_outbox_alerta_pendente
    ON notificacao_outbox_alerta (proxima_tentativa_em, id)
    WHERE estado IN ('pendente', 'falha');

CREATE TABLE IF NOT EXISTS relato_problema_app (
    id             BIGSERIAL PRIMARY KEY,
    usuario_app_id BIGINT REFERENCES usuario_app (id) ON DELETE SET NULL,
    categoria      TEXT NOT NULL CHECK (categoria IN ('erro', 'dados', 'conta', 'outro')),
    mensagem       TEXT NOT NULL CHECK (char_length(mensagem) BETWEEN 1 AND 2000),
    tela           TEXT NOT NULL CHECK (char_length(tela) BETWEEN 1 AND 120),
    versao_app     TEXT NOT NULL CHECK (char_length(versao_app) BETWEEN 1 AND 80),
    sistema        TEXT CHECK (sistema IS NULL OR char_length(sistema) <= 200),
    requisicao_id  TEXT NOT NULL CHECK (char_length(requisicao_id) <= 100),
    criado_em      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_relato_problema_app_data
    ON relato_problema_app (criado_em DESC);

CREATE OR REPLACE FUNCTION criar_outbox_alerta()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO notificacao_outbox_alerta (usuario_app_id, origem, coleta_id)
    VALUES (NEW.usuario_app_id, NEW.origem, NEW.coleta_id)
    ON CONFLICT (usuario_app_id, origem, coleta_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_evento_alerta_outbox ON evento_alerta;
CREATE TRIGGER trg_evento_alerta_outbox
AFTER INSERT ON evento_alerta
FOR EACH ROW EXECUTE FUNCTION criar_outbox_alerta();

-- A coleta so chama estas funcoes depois de publicar uma transacao completa.
-- O INSERT e idempotente e o primeiro snapshot (sem anterior) e ignorado.
CREATE OR REPLACE FUNCTION gerar_alertas_livelo(p_execucao_id BIGINT)
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE v_total INTEGER;
BEGIN
    WITH candidatos AS (
        SELECT a.id acompanhamento_id, a.usuario_app_id, p.parceiro_livelo_id entidade_id,
               p.nome, p.pontos_atuais valor_atual,
               anterior.pontos_atuais valor_anterior,
               p.execucao_id::TEXT coleta_id
          FROM pontuacao p
          JOIN execucao atual ON atual.id = p.execucao_id AND atual.qualidade = 'completa'
          JOIN acompanhamento_usuario a
            ON a.origem = 'livelo' AND a.entidade_id = p.parceiro_livelo_id
          LEFT JOIN LATERAL (
              SELECT p2.pontos_atuais
                FROM pontuacao p2
                JOIN execucao anterior_exec
                  ON anterior_exec.id = p2.execucao_id
                 AND anterior_exec.qualidade = 'completa'
               WHERE p2.parceiro_livelo_id = p.parceiro_livelo_id
                 AND p2.execucao_id <> p.execucao_id
                 AND p2.execucao_id < p.execucao_id
               ORDER BY p2.execucao_id DESC, p2.id DESC LIMIT 1
          ) anterior ON TRUE
         WHERE p.execucao_id = p_execucao_id
           AND p.parceiro_livelo_id IS NOT NULL
           AND p.pontos_atuais IS NOT NULL
           AND anterior.pontos_atuais IS NOT NULL
           AND p.pontos_atuais IS DISTINCT FROM anterior.pontos_atuais
    ), inseridos AS (
        INSERT INTO evento_alerta (
            usuario_app_id, acompanhamento_id, origem, tipo, entidade_id,
            entidade_nome, coleta_id, valor_anterior, valor_atual, unidade, direcao
        )
        SELECT usuario_app_id, acompanhamento_id, 'livelo', 'pontuacao', entidade_id,
               nome, coleta_id, valor_anterior, valor_atual, 'pontos_por_real',
               CASE WHEN valor_atual > valor_anterior THEN 'aumento' ELSE 'reducao' END
          FROM candidatos
        ON CONFLICT (usuario_app_id, origem, tipo, entidade_id, coleta_id) DO NOTHING
        RETURNING id
    ) SELECT count(*) INTO v_total FROM inseridos;
    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION gerar_alertas_cashback_inter(p_execucao_id BIGINT)
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE v_total INTEGER;
BEGIN
    WITH candidatos AS (
        SELECT a.id acompanhamento_id, a.usuario_app_id, c.loja_inter_id entidade_id,
               c.nome, c.cashback_principal_valor valor_atual,
               anterior.cashback_principal_valor valor_anterior,
               c.execucao_inter_id::TEXT coleta_id
          FROM cashback_inter c
          JOIN execucao_inter atual ON atual.id = c.execucao_inter_id AND atual.estado = 'sucesso'
          JOIN acompanhamento_usuario a
            ON a.origem = 'inter_cashback' AND a.entidade_id = c.loja_inter_id
          LEFT JOIN LATERAL (
              SELECT c2.cashback_principal_valor
                FROM cashback_inter c2
                JOIN execucao_inter e2 ON e2.id = c2.execucao_inter_id AND e2.estado = 'sucesso'
               WHERE c2.loja_inter_id = c.loja_inter_id
                 AND c2.execucao_inter_id < c.execucao_inter_id
                 AND c2.cashback_principal_valor IS NOT NULL
               ORDER BY c2.execucao_inter_id DESC, c2.id DESC LIMIT 1
          ) anterior ON TRUE
         WHERE c.execucao_inter_id = p_execucao_id
           AND c.encontrada = TRUE
           AND c.cashback_principal_valor IS NOT NULL
           AND anterior.cashback_principal_valor IS NOT NULL
           AND c.cashback_principal_valor IS DISTINCT FROM anterior.cashback_principal_valor
    ), inseridos AS (
        INSERT INTO evento_alerta (
            usuario_app_id, acompanhamento_id, origem, tipo, entidade_id,
            entidade_nome, coleta_id, valor_anterior, valor_atual, unidade, direcao
        )
        SELECT usuario_app_id, acompanhamento_id, 'inter_cashback', 'cashback', entidade_id,
               nome, coleta_id, valor_anterior, valor_atual, 'percentual',
               CASE WHEN valor_atual > valor_anterior THEN 'aumento' ELSE 'reducao' END
          FROM candidatos
        ON CONFLICT (usuario_app_id, origem, tipo, entidade_id, coleta_id) DO NOTHING
        RETURNING id
    ) SELECT count(*) INTO v_total FROM inseridos;
    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION gerar_alertas_produtos_inter(p_execucao_loja_id BIGINT)
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE v_total INTEGER;
BEGIN
    WITH atual AS (
        SELECT m.produto_direto_inter_id entidade_id, p.id_externo, p.nome,
               m.execucao_loja_produtos_inter_id coleta_execucao, m.momento,
               m.preco_atual, m.cashback_percentual,
               loja.slug origem_loja, rodada.estado rodada_estado, rodada.qualidade
          FROM medicao_produto_direto_inter m
          JOIN produto_direto_inter p ON p.id = m.produto_direto_inter_id
          JOIN execucao_loja_produtos_inter rodada_loja
            ON rodada_loja.id = m.execucao_loja_produtos_inter_id
          JOIN execucao_produtos_inter rodada ON rodada.id = rodada_loja.execucao_produtos_inter_id
          JOIN loja_direta_inter loja ON loja.id = rodada_loja.loja_direta_inter_id
         WHERE m.execucao_loja_produtos_inter_id = p_execucao_loja_id
           AND rodada.estado IN ('sucesso', 'parcial')
           AND rodada_loja.estado = 'sucesso'
           AND rodada_loja.qualidade = 'completa'
    ), acompanhados AS (
        SELECT atual.*, a.id acompanhamento_id, a.usuario_app_id
          FROM atual JOIN acompanhamento_usuario a
            ON a.origem = 'inter_produto' AND a.entidade_id = atual.entidade_id
    ), tipos AS (
        SELECT a.*, 'preco'::TEXT tipo, a.preco_atual valor_atual,
               anterior.preco_atual valor_anterior, a.coleta_execucao::TEXT coleta_id,
               'reais'::TEXT unidade
          FROM acompanhados a
          LEFT JOIN LATERAL (
              SELECT m.preco_atual
                FROM medicao_produto_direto_inter m
                JOIN execucao_loja_produtos_inter anterior_rodada
                  ON anterior_rodada.id = m.execucao_loja_produtos_inter_id
                 AND anterior_rodada.estado = 'sucesso'
                 AND anterior_rodada.qualidade = 'completa'
               WHERE m.produto_direto_inter_id = a.entidade_id
                 AND m.execucao_loja_produtos_inter_id <> a.coleta_execucao
                 AND m.execucao_loja_produtos_inter_id < a.coleta_execucao
               ORDER BY m.momento DESC, m.id DESC LIMIT 1
          ) anterior ON TRUE
        UNION ALL
        SELECT a.*, 'cashback', a.cashback_percentual,
               anterior.cashback_percentual, a.coleta_execucao::TEXT, 'percentual'
          FROM acompanhados a
          LEFT JOIN LATERAL (
              SELECT m.cashback_percentual
                FROM medicao_produto_direto_inter m
                JOIN execucao_loja_produtos_inter anterior_rodada
                  ON anterior_rodada.id = m.execucao_loja_produtos_inter_id
                 AND anterior_rodada.estado = 'sucesso'
                 AND anterior_rodada.qualidade = 'completa'
               WHERE m.produto_direto_inter_id = a.entidade_id
                 AND m.execucao_loja_produtos_inter_id <> a.coleta_execucao
                 AND m.execucao_loja_produtos_inter_id < a.coleta_execucao
                 AND m.cashback_percentual IS NOT NULL
               ORDER BY m.momento DESC, m.id DESC LIMIT 1
          ) anterior ON TRUE
    ), inseridos AS (
        INSERT INTO evento_alerta (
            usuario_app_id, acompanhamento_id, origem, tipo, entidade_id, entidade_externa,
            entidade_nome, coleta_id, valor_anterior, valor_atual, unidade, direcao
        )
        SELECT usuario_app_id, acompanhamento_id, 'inter_produto', tipo, entidade_id,
               id_externo, nome, coleta_id, valor_anterior, valor_atual, unidade,
               CASE WHEN valor_atual > valor_anterior THEN 'aumento' ELSE 'reducao' END
          FROM tipos
         WHERE valor_atual IS NOT NULL AND valor_anterior IS NOT NULL
           AND valor_atual IS DISTINCT FROM valor_anterior
        ON CONFLICT (usuario_app_id, origem, tipo, entidade_id, coleta_id) DO NOTHING
        RETURNING id
    ) SELECT count(*) INTO v_total FROM inseridos;
    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION expurgar_alertas_suporte()
RETURNS VOID LANGUAGE sql AS $$
    DELETE FROM evento_alerta WHERE criado_em < now() - interval '90 days';
    DELETE FROM relato_problema_app WHERE criado_em < now() - interval '180 days';
    DELETE FROM notificacao_outbox_alerta WHERE criado_em < now() - interval '90 days';
$$;
