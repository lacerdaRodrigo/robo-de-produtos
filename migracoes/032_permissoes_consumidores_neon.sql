-- Permissoes por consumidor no Neon novo.
-- Aplicar depois de 031, como neondb_owner, antes de cadastrar as URLs nos
-- servicos. Nao concede acesso a fila diretamente para a API.

DO $$
DECLARE
    v_role TEXT;
BEGIN
    FOREACH v_role IN ARRAY ARRAY[
        'robo_api',
        'robo_coletor',
        'radar_api',
        'radar_actions_robo',
        'radar_actions_pichau',
        'radar_samsung'
    ] LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = v_role) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN INHERIT', v_role);
        END IF;
    END LOOP;

    IF EXISTS (
        SELECT 1 FROM pg_catalog.pg_roles
         WHERE rolname IN (
             'robo_api', 'robo_coletor', 'robo_dispatcher', 'robo_executor',
             'pichau_dispatcher', 'pichau_publisher'
         ) AND rolcanlogin
    ) THEN
        RAISE EXCEPTION 'grupo de permissao configurado como login';
    END IF;
END;
$$;

GRANT USAGE ON SCHEMA public TO
    robo_api, robo_coletor, robo_dispatcher, robo_executor,
    pichau_dispatcher, pichau_publisher;

-- A API precisa do CRUD usado pelos endpoints autenticados/admin, mas nao
-- consulta nem altera as filas internas dos executores.
DO $$
DECLARE
    v_objeto RECORD;
BEGIN
    FOR v_objeto IN
        SELECT c.relname
          FROM pg_catalog.pg_class c
          JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public'
           AND c.relkind IN ('r', 'p')
           AND c.relname NOT IN ('coleta_android_fila', 'pichau_android_fila')
    LOOP
        EXECUTE format(
            'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.%I TO robo_api',
            v_objeto.relname
        );
    END LOOP;

    FOR v_objeto IN
        SELECT c.relname
          FROM pg_catalog.pg_class c
          JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'public'
           AND c.relkind = 'S'
           AND c.relname NOT IN (
               'coleta_android_fila_id_seq', 'pichau_android_fila_id_seq'
           )
    LOOP
        EXECUTE format(
            'GRANT USAGE, SELECT ON SEQUENCE public.%I TO robo_api',
            v_objeto.relname
        );
    END LOOP;
END;
$$;

-- O executor pode publicar catálogos e históricos, mas não lê nem altera
-- contas, tokens, acompanhamentos, eventos, preferências ou relatos pessoais.
GRANT SELECT ON TABLE public.preferencia, public.favorita_inter TO robo_coletor;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE
    public.loja,
    public.apelido,
    public.execucao,
    public.pontuacao,
    public.parceiro_livelo,
    public.loja_inter,
    public.execucao_inter,
    public.cashback_inter,
    public.loja_direta_inter,
    public.execucao_produtos_inter,
    public.execucao_loja_produtos_inter,
    public.estagio_produto_inter,
    public.produto_direto_inter,
    public.medicao_produto_direto_inter,
    public.oferta_direta_inter_atual,
    public.pichau_execucao,
    public.pichau_produto,
    public.pichau_medicao
TO robo_coletor;

-- Pichau tem uma fila própria: o Actions enfileira, o Samsung reivindica e
-- atualiza diagnóstico/resultado. O dispatcher não pode alterar ou apagar.
GRANT SELECT, UPDATE ON TABLE public.pichau_android_fila TO robo_coletor;
GRANT SELECT, INSERT ON TABLE public.pichau_android_fila TO pichau_dispatcher;
GRANT USAGE, SELECT ON SEQUENCE public.pichau_android_fila_id_seq TO pichau_dispatcher;
REVOKE UPDATE, DELETE ON TABLE public.pichau_android_fila FROM pichau_dispatcher;

GRANT USAGE, SELECT ON SEQUENCE
    public.loja_id_seq,
    public.apelido_id_seq,
    public.execucao_id_seq,
    public.pontuacao_id_seq,
    public.parceiro_livelo_id_seq,
    public.loja_inter_id_seq,
    public.execucao_inter_id_seq,
    public.cashback_inter_id_seq,
    public.loja_direta_inter_id_seq,
    public.execucao_produtos_inter_id_seq,
    public.execucao_loja_produtos_inter_id_seq,
    public.produto_direto_inter_id_seq,
    public.medicao_produto_direto_inter_id_seq,
    public.pichau_execucao_id_seq,
    public.pichau_produto_id_seq,
    public.pichau_medicao_id_seq
TO robo_coletor;

REVOKE ALL ON TABLE public.coleta_android_fila, public.pichau_android_fila FROM PUBLIC;
REVOKE ALL ON SEQUENCE
    public.coleta_android_fila_id_seq,
    public.pichau_android_fila_id_seq
FROM PUBLIC;
REVOKE ALL ON TABLE public.coleta_android_fila, public.pichau_android_fila FROM robo_api;
REVOKE ALL ON SEQUENCE
    public.coleta_android_fila_id_seq,
    public.pichau_android_fila_id_seq
FROM robo_api;

-- SECURITY DEFINER fica restrito às funções de publicação. O search_path
-- fechado impede que objetos temporários/substituídos desviem a execução.
ALTER FUNCTION public.criar_outbox_alerta() SECURITY DEFINER;
ALTER FUNCTION public.criar_outbox_alerta()
    SET search_path = pg_catalog, public, pg_temp;
ALTER FUNCTION public.gerar_alertas_livelo(BIGINT) SECURITY DEFINER;
ALTER FUNCTION public.gerar_alertas_livelo(BIGINT)
    SET search_path = pg_catalog, public, pg_temp;
ALTER FUNCTION public.gerar_alertas_livelo_com_push(BIGINT, BOOLEAN) SECURITY DEFINER;
ALTER FUNCTION public.gerar_alertas_livelo_com_push(BIGINT, BOOLEAN)
    SET search_path = pg_catalog, public, pg_temp;
ALTER FUNCTION public.gerar_alertas_cashback_inter(BIGINT) SECURITY DEFINER;
ALTER FUNCTION public.gerar_alertas_cashback_inter(BIGINT)
    SET search_path = pg_catalog, public, pg_temp;
ALTER FUNCTION public.gerar_alertas_produtos_inter(BIGINT) SECURITY DEFINER;
ALTER FUNCTION public.gerar_alertas_produtos_inter(BIGINT)
    SET search_path = pg_catalog, public, pg_temp;
ALTER FUNCTION public.gerar_alertas_produtos_inter_com_push(BIGINT, BOOLEAN)
    SECURITY DEFINER;
ALTER FUNCTION public.gerar_alertas_produtos_inter_com_push(BIGINT, BOOLEAN)
    SET search_path = pg_catalog, public, pg_temp;
ALTER FUNCTION public.gerar_alertas_pichau(BIGINT) SECURITY DEFINER;
ALTER FUNCTION public.gerar_alertas_pichau(BIGINT)
    SET search_path = pg_catalog, public, pg_temp;
ALTER FUNCTION public.gerar_alertas_pichau_com_push(BIGINT, BOOLEAN)
    SECURITY DEFINER;
ALTER FUNCTION public.gerar_alertas_pichau_com_push(BIGINT, BOOLEAN)
    SET search_path = pg_catalog, public, pg_temp;
ALTER FUNCTION public.expurgar_alertas_suporte()
    SET search_path = pg_catalog, public, pg_temp;

REVOKE ALL ON FUNCTION public.criar_outbox_alerta() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.gerar_alertas_livelo(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.gerar_alertas_livelo_com_push(BIGINT, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.gerar_alertas_cashback_inter(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.gerar_alertas_produtos_inter(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.gerar_alertas_produtos_inter_com_push(BIGINT, BOOLEAN)
    FROM PUBLIC;
REVOKE ALL ON FUNCTION public.gerar_alertas_pichau(BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.gerar_alertas_pichau_com_push(BIGINT, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.expurgar_alertas_suporte() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.gerar_alertas_livelo(BIGINT) TO robo_coletor;
GRANT EXECUTE ON FUNCTION public.gerar_alertas_cashback_inter(BIGINT) TO robo_coletor;
GRANT EXECUTE ON FUNCTION public.gerar_alertas_produtos_inter(BIGINT) TO robo_coletor;
GRANT EXECUTE ON FUNCTION public.gerar_alertas_pichau(BIGINT) TO pichau_publisher;
GRANT EXECUTE ON FUNCTION public.expurgar_alertas_suporte() TO robo_api;

-- Os dispatchers gravam somente os pedidos; as funções isolam as filas reais.
GRANT EXECUTE ON FUNCTION public.solicitar_coleta_android(TEXT, BIGINT)
    TO robo_dispatcher;
GRANT EXECUTE ON FUNCTION public.reivindicar_coleta_android(TEXT, BIGINT, INTEGER)
    TO robo_executor;
GRANT EXECUTE ON FUNCTION public.finalizar_coleta_android(BIGINT, BOOLEAN, TEXT)
    TO robo_executor;
GRANT EXECUTE ON FUNCTION public.consultar_coleta_android(TEXT, BIGINT)
    TO robo_executor;

-- Logins de consumidores: ficam NOLOGIN até as senhas serem provisionadas por
-- canal seguro, fora desta migration e do repositório.
GRANT robo_api TO radar_api;
GRANT robo_dispatcher TO radar_actions_robo;
GRANT pichau_dispatcher TO radar_actions_pichau;
GRANT robo_coletor, robo_executor, pichau_publisher TO radar_samsung;
