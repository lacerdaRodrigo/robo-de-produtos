-- Fila durável dos disparos manuais Livelo e Inter executados no Samsung.
-- Criar as roles de grupo robo_dispatcher e robo_executor antes desta migration;
-- conceder associação ao login do Actions e ao login do executor, respectivamente.

CREATE TABLE IF NOT EXISTS coleta_android_fila (
    id                  BIGSERIAL PRIMARY KEY,
    fonte               TEXT NOT NULL CHECK (fonte IN ('livelo', 'inter')),
    github_run_id       BIGINT NOT NULL CHECK (github_run_id > 0),
    estado              TEXT NOT NULL DEFAULT 'pendente' CHECK (
                            estado IN ('pendente', 'executando', 'sucesso', 'falha')
                        ),
    tentativas          INTEGER NOT NULL DEFAULT 0 CHECK (tentativas >= 0),
    criada_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    iniciada_em         TIMESTAMPTZ,
    concluida_em        TIMESTAMPTZ,
    lease_ate           TIMESTAMPTZ,
    codigo_falha        TEXT CHECK (
                            codigo_falha IS NULL OR codigo_falha ~ '^[a-z0-9][a-z0-9_-]{0,79}$'
                        ),
    UNIQUE (fonte, github_run_id),
    CHECK (estado <> 'executando' OR lease_ate IS NOT NULL),
    CHECK (estado NOT IN ('sucesso', 'falha') OR concluida_em IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_coleta_android_fila_pendente
    ON coleta_android_fila (fonte, criada_em, id)
    WHERE estado IN ('pendente', 'executando');

CREATE OR REPLACE FUNCTION solicitar_coleta_android(p_fonte TEXT, p_github_run_id BIGINT)
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
    v_id BIGINT;
BEGIN
    IF p_fonte IS NULL OR p_fonte NOT IN ('livelo', 'inter')
       OR p_github_run_id IS NULL OR p_github_run_id <= 0 THEN
        RAISE EXCEPTION 'pedido de coleta inválido';
    END IF;

    INSERT INTO public.coleta_android_fila (fonte, github_run_id)
    VALUES (p_fonte, p_github_run_id)
    ON CONFLICT (fonte, github_run_id) DO NOTHING
    RETURNING id INTO v_id;

    IF v_id IS NULL THEN
        SELECT fila.id INTO v_id
          FROM public.coleta_android_fila AS fila
         WHERE fila.fonte = p_fonte AND fila.github_run_id = p_github_run_id;
    END IF;
    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION reivindicar_coleta_android(
    p_fonte TEXT,
    p_github_run_id BIGINT DEFAULT NULL,
    p_lease_segundos INTEGER DEFAULT 3600
)
RETURNS TABLE (id BIGINT, fonte TEXT, github_run_id BIGINT, tentativas INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    IF p_fonte IS NULL OR p_fonte NOT IN ('livelo', 'inter')
       OR p_lease_segundos IS NULL
       OR p_lease_segundos NOT BETWEEN 60 AND 21600 THEN
        RAISE EXCEPTION 'parâmetros da fila inválidos';
    END IF;

    RETURN QUERY
    WITH candidata AS (
        SELECT fila.id
          FROM public.coleta_android_fila AS fila
         WHERE fila.fonte = p_fonte
           AND (p_github_run_id IS NULL OR fila.github_run_id = p_github_run_id)
           AND (fila.estado = 'pendente' OR
                (fila.estado = 'executando' AND fila.lease_ate <= now()))
         ORDER BY fila.criada_em, fila.id
         FOR UPDATE SKIP LOCKED
         LIMIT 1
    )
    UPDATE public.coleta_android_fila AS fila
       SET estado = 'executando',
           tentativas = fila.tentativas + 1,
           iniciada_em = now(),
           concluida_em = NULL,
           lease_ate = now() + make_interval(secs => p_lease_segundos),
           codigo_falha = NULL
      FROM candidata
     WHERE fila.id = candidata.id
    RETURNING fila.id, fila.fonte, fila.github_run_id, fila.tentativas;
END;
$$;

CREATE OR REPLACE FUNCTION finalizar_coleta_android(
    p_id BIGINT,
    p_sucesso BOOLEAN,
    p_codigo_falha TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    IF p_id IS NULL OR p_sucesso IS NULL THEN
        RAISE EXCEPTION 'resultado de coleta inválido';
    END IF;
    IF NOT p_sucesso AND COALESCE(p_codigo_falha, '') !~ '^[a-z0-9][a-z0-9_-]{0,79}$' THEN
        RAISE EXCEPTION 'código de falha inválido';
    END IF;

    UPDATE public.coleta_android_fila
       SET estado = CASE WHEN p_sucesso THEN 'sucesso' ELSE 'falha' END,
           concluida_em = now(),
           lease_ate = NULL,
           codigo_falha = CASE WHEN p_sucesso THEN NULL ELSE p_codigo_falha END
     WHERE id = p_id AND estado = 'executando';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'pedido de coleta não reivindicado';
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION consultar_coleta_android(p_fonte TEXT, p_github_run_id BIGINT)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
    SELECT fila.estado
      FROM public.coleta_android_fila AS fila
     WHERE fila.fonte = p_fonte AND fila.github_run_id = p_github_run_id;
$$;

REVOKE ALL ON FUNCTION solicitar_coleta_android(TEXT, BIGINT) FROM PUBLIC;
REVOKE ALL ON FUNCTION reivindicar_coleta_android(TEXT, BIGINT, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION finalizar_coleta_android(BIGINT, BOOLEAN, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION consultar_coleta_android(TEXT, BIGINT) FROM PUBLIC;
GRANT USAGE ON SCHEMA public TO robo_dispatcher, robo_executor;
GRANT EXECUTE ON FUNCTION solicitar_coleta_android(TEXT, BIGINT) TO robo_dispatcher;
GRANT EXECUTE ON FUNCTION reivindicar_coleta_android(TEXT, BIGINT, INTEGER) TO robo_executor;
GRANT EXECUTE ON FUNCTION finalizar_coleta_android(BIGINT, BOOLEAN, TEXT) TO robo_executor;
GRANT EXECUTE ON FUNCTION consultar_coleta_android(TEXT, BIGINT) TO robo_executor;
