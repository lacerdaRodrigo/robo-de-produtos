-- Fila durável para o workflow Pichau e o executor Android local.
-- Esta migration é apenas contrato versionado; a aplicação em produção exige
-- autorização operacional separada.

CREATE TABLE IF NOT EXISTS pichau_android_fila (
    id                  BIGSERIAL PRIMARY KEY,
    chave_idempotencia  TEXT NOT NULL UNIQUE CHECK (
                            char_length(chave_idempotencia) BETWEEN 1 AND 160
                        ),
    origem              TEXT NOT NULL CHECK (
                            origem IN ('schedule', 'workflow_dispatch')
                        ),
    github_run_id       BIGINT,
    estado              TEXT NOT NULL CHECK (
                            estado IN ('pendente', 'executando', 'sucesso', 'falha')
                        ),
    tentativas          INTEGER NOT NULL DEFAULT 0 CHECK (tentativas >= 0),
    criada_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    iniciada_em         TIMESTAMPTZ,
    concluida_em        TIMESTAMPTZ,
    lease_ate           TIMESTAMPTZ,
    execucao_id         BIGINT REFERENCES pichau_execucao(id) ON DELETE SET NULL,
    codigo_falha        TEXT CHECK (codigo_falha IS NULL OR char_length(codigo_falha) <= 80),
    CHECK (estado <> 'sucesso' OR concluida_em IS NOT NULL),
    CHECK (estado <> 'falha' OR concluida_em IS NOT NULL),
    CHECK (estado <> 'executando' OR lease_ate IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_pichau_android_fila_pendente
    ON pichau_android_fila (estado, criada_em, id)
    WHERE estado IN ('pendente', 'executando');

CREATE INDEX IF NOT EXISTS idx_pichau_android_fila_lease
    ON pichau_android_fila (lease_ate)
    WHERE estado = 'executando';
