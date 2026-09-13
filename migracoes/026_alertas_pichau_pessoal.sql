-- Alertas pessoais do Pichau e geração após a finalização das coletas.
-- Depende das migrations 023 e 025. Aplicar somente pela operação do banco.

ALTER TABLE acompanhamento_usuario
    DROP CONSTRAINT IF EXISTS acompanhamento_usuario_origem_check;
ALTER TABLE acompanhamento_usuario
    ADD CONSTRAINT acompanhamento_usuario_origem_check
    CHECK (origem IN ('livelo', 'inter_cashback', 'inter_produto', 'pichau'));

ALTER TABLE evento_alerta
    DROP CONSTRAINT IF EXISTS evento_alerta_origem_check;
ALTER TABLE evento_alerta
    ADD CONSTRAINT evento_alerta_origem_check
    CHECK (origem IN ('livelo', 'inter_cashback', 'inter_produto', 'pichau'));

ALTER TABLE notificacao_outbox_alerta
    DROP CONSTRAINT IF EXISTS notificacao_outbox_alerta_origem_check;
ALTER TABLE notificacao_outbox_alerta
    ADD CONSTRAINT notificacao_outbox_alerta_origem_check
    CHECK (origem IN ('livelo', 'inter_cashback', 'inter_produto', 'pichau'));

ALTER TABLE evento_alerta
    ADD COLUMN IF NOT EXISTS notificar_push BOOLEAN NOT NULL DEFAULT TRUE;

CREATE OR REPLACE FUNCTION criar_outbox_alerta()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp AS $$
BEGIN
    IF NEW.notificar_push THEN
        INSERT INTO notificacao_outbox_alerta (usuario_app_id, origem, coleta_id)
        VALUES (NEW.usuario_app_id, NEW.origem, NEW.coleta_id)
        ON CONFLICT (usuario_app_id, origem, coleta_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_evento_alerta_outbox ON evento_alerta;
CREATE TRIGGER trg_evento_alerta_outbox
AFTER INSERT ON evento_alerta
FOR EACH ROW EXECUTE FUNCTION criar_outbox_alerta();

-- A data de criacao do acompanhamento define o primeiro snapshot pessoal.
-- Assim, seguir um item novo nao gera alerta com uma mudanca anterior ao follow.
CREATE OR REPLACE FUNCTION gerar_alertas_livelo_com_push(
    p_execucao_id BIGINT,
    p_notificar_push BOOLEAN
)
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
                 AND anterior_exec.momento >= a.criado_em
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
            entidade_nome, coleta_id, valor_anterior, valor_atual, unidade, direcao,
            notificar_push
        )
        SELECT usuario_app_id, acompanhamento_id, 'livelo', 'pontuacao', entidade_id,
               nome, coleta_id, valor_anterior, valor_atual, 'pontos_por_real',
               CASE WHEN valor_atual > valor_anterior THEN 'aumento' ELSE 'reducao' END,
               p_notificar_push
          FROM candidatos
        ON CONFLICT (usuario_app_id, origem, tipo, entidade_id, coleta_id) DO NOTHING
        RETURNING id
    ) SELECT count(*) INTO v_total FROM inseridos;
    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION gerar_alertas_livelo(p_execucao_id BIGINT)
RETURNS INTEGER LANGUAGE sql AS $$
    SELECT gerar_alertas_livelo_com_push($1, TRUE);
$$;

CREATE OR REPLACE FUNCTION gerar_alertas_produtos_inter_com_push(
    p_execucao_loja_id BIGINT,
    p_notificar_push BOOLEAN
)
RETURNS INTEGER LANGUAGE plpgsql AS $$
DECLARE v_total INTEGER;
BEGIN
    WITH atual AS (
        SELECT m.produto_direto_inter_id entidade_id, p.id_externo, p.nome,
               m.execucao_loja_produtos_inter_id coleta_execucao, m.momento,
               m.preco_atual, m.cashback_percentual,
               loja.slug origem_loja, rodada.estado rodada_estado
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
        SELECT atual.*, a.id acompanhamento_id, a.usuario_app_id, a.criado_em
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
                 AND anterior_rodada.concluida_em >= a.criado_em
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
                 AND anterior_rodada.concluida_em >= a.criado_em
               WHERE m.produto_direto_inter_id = a.entidade_id
                 AND m.execucao_loja_produtos_inter_id <> a.coleta_execucao
                 AND m.execucao_loja_produtos_inter_id < a.coleta_execucao
                 AND m.cashback_percentual IS NOT NULL
               ORDER BY m.momento DESC, m.id DESC LIMIT 1
          ) anterior ON TRUE
    ), inseridos AS (
        INSERT INTO evento_alerta (
            usuario_app_id, acompanhamento_id, origem, tipo, entidade_id, entidade_externa,
            entidade_nome, coleta_id, valor_anterior, valor_atual, unidade, direcao,
            notificar_push
        )
        SELECT usuario_app_id, acompanhamento_id, 'inter_produto', tipo, entidade_id,
               id_externo, nome, coleta_id, valor_anterior, valor_atual, unidade,
               CASE WHEN valor_atual > valor_anterior THEN 'aumento' ELSE 'reducao' END,
               p_notificar_push
          FROM tipos
         WHERE valor_atual IS NOT NULL AND valor_anterior IS NOT NULL
           AND valor_atual IS DISTINCT FROM valor_anterior
        ON CONFLICT (usuario_app_id, origem, tipo, entidade_id, coleta_id) DO NOTHING
        RETURNING id
    ) SELECT count(*) INTO v_total FROM inseridos;
    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION gerar_alertas_produtos_inter(p_execucao_loja_id BIGINT)
RETURNS INTEGER LANGUAGE sql AS $$
    SELECT gerar_alertas_produtos_inter_com_push($1, TRUE);
$$;

CREATE OR REPLACE FUNCTION gerar_alertas_pichau_com_push(
    p_execucao_id BIGINT,
    p_notificar_push BOOLEAN
)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp AS $$
DECLARE v_total INTEGER;
BEGIN
    WITH atuais AS (
        SELECT m.produto_id entidade_id, p.id_externo, p.nome,
               m.preco_pix valor_atual, m.momento, m.execucao_id coleta_execucao
          FROM pichau_medicao m
          JOIN pichau_produto p ON p.id = m.produto_id
          JOIN pichau_execucao execucao
            ON execucao.id = m.execucao_id
           AND execucao.estado = 'sucesso'
           AND execucao.qualidade = 'completa'
         WHERE m.execucao_id = p_execucao_id
           AND m.preco_pix IS NOT NULL
    ), acompanhados AS (
        SELECT atuais.*, a.id acompanhamento_id, a.usuario_app_id, a.criado_em
          FROM atuais
          JOIN acompanhamento_usuario a
            ON a.origem = 'pichau' AND a.entidade_id = atuais.entidade_id
    ), candidatos AS (
        SELECT a.*, anterior.preco_pix valor_anterior
          FROM acompanhados a
          LEFT JOIN LATERAL (
              SELECT m2.preco_pix
                FROM pichau_medicao m2
                JOIN pichau_execucao execucao_anterior
                  ON execucao_anterior.id = m2.execucao_id
                 AND execucao_anterior.estado = 'sucesso'
                 AND execucao_anterior.qualidade = 'completa'
               WHERE m2.produto_id = a.entidade_id
                 AND m2.execucao_id <> a.coleta_execucao
                 AND m2.momento < a.momento
                 AND execucao_anterior.concluida_em >= a.criado_em
                 AND m2.preco_pix IS NOT NULL
               ORDER BY m2.momento DESC, m2.id DESC LIMIT 1
          ) anterior ON TRUE
    ), inseridos AS (
        INSERT INTO evento_alerta (
            usuario_app_id, acompanhamento_id, origem, tipo, entidade_id, entidade_externa,
            entidade_nome, coleta_id, valor_anterior, valor_atual, unidade, direcao,
            notificar_push
        )
        SELECT usuario_app_id, acompanhamento_id, 'pichau', 'preco', entidade_id,
               id_externo, nome, coleta_execucao::TEXT, valor_anterior, valor_atual,
               'reais', CASE WHEN valor_atual > valor_anterior THEN 'aumento' ELSE 'reducao' END,
               p_notificar_push
          FROM candidatos
         WHERE valor_anterior IS NOT NULL
           AND valor_atual IS DISTINCT FROM valor_anterior
        ON CONFLICT (usuario_app_id, origem, tipo, entidade_id, coleta_id) DO NOTHING
        RETURNING id
    ) SELECT count(*) INTO v_total FROM inseridos;
    RETURN v_total;
END;
$$;

CREATE OR REPLACE FUNCTION gerar_alertas_pichau(p_execucao_id BIGINT)
RETURNS INTEGER LANGUAGE sql SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp AS $$
    SELECT gerar_alertas_pichau_com_push($1, TRUE);
$$;
