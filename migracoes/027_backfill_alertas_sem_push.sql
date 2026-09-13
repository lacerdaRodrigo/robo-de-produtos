-- Ponte única das seleções legadas para o acompanhamento pessoal.
-- Depende da migration 026 e deve ser executada uma única vez pela operação.
-- A operação aborta se houver mais de um usuário ativo, evitando atribuição
-- silenciosa de dados pessoais à conta errada.

DO $$
DECLARE
    v_usuario_id BIGINT;
    v_usuarios BIGINT;
BEGIN
    SELECT min(id), count(*) INTO v_usuario_id, v_usuarios
      FROM usuario_app
     WHERE ativo = TRUE;
    IF v_usuarios <> 1 THEN
        RAISE EXCEPTION 'backfill exige exatamente um usuario_app ativo; encontrados: %', v_usuarios;
    END IF;

    INSERT INTO acompanhamento_usuario (usuario_app_id, origem, entidade_id)
    SELECT v_usuario_id, 'livelo', loja.parceiro_livelo_id
      FROM loja
     WHERE loja.acompanhada = TRUE
       AND loja.parceiro_livelo_id IS NOT NULL
    ON CONFLICT (usuario_app_id, origem, entidade_id) DO UPDATE
        SET atualizado_em = now();

    INSERT INTO acompanhamento_usuario (usuario_app_id, origem, entidade_id)
    SELECT v_usuario_id, 'pichau', produto.id
      FROM pichau_produto produto
     WHERE produto.acompanhada = TRUE
    ON CONFLICT (usuario_app_id, origem, entidade_id) DO UPDATE
        SET atualizado_em = now();
END;
$$;

-- Recupera apenas rodadas posteriores ao último evento Inter conhecido.
-- A função sem push grava na Central, mas o trigger não cria outbox.
DO $$
DECLARE
    v_ultima_rodada BIGINT;
    v_execucao_id BIGINT;
BEGIN
    SELECT COALESCE(max(rodada.id), 0) INTO v_ultima_rodada
      FROM evento_alerta evento
      JOIN execucao_loja_produtos_inter loja
        ON loja.id::TEXT = evento.coleta_id
      JOIN execucao_produtos_inter rodada
        ON rodada.id = loja.execucao_produtos_inter_id
     WHERE evento.origem = 'inter_produto';

    FOR v_execucao_id IN
        SELECT loja.id
          FROM execucao_loja_produtos_inter loja
          JOIN execucao_produtos_inter rodada
            ON rodada.id = loja.execucao_produtos_inter_id
         WHERE rodada.id > v_ultima_rodada
           AND rodada.estado IN ('sucesso', 'parcial')
           AND loja.estado = 'sucesso'
           AND loja.qualidade = 'completa'
         ORDER BY loja.id
    LOOP
        PERFORM gerar_alertas_produtos_inter_com_push(v_execucao_id, FALSE);
    END LOOP;
END;
$$;
