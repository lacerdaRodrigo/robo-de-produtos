-- Diagnostico operacional seguro da fila Android Pichau.
-- Esta migration depende somente da 022; sua aplicação não depende da 023.
-- Aplicar por conexao direta e validar primeiro em branch temporaria de production.

ALTER TABLE pichau_android_fila
    ADD COLUMN IF NOT EXISTS diagnostico JSONB NOT NULL DEFAULT '{}'::jsonb;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint
         WHERE conname = 'pichau_android_fila_diagnostico_objeto_ck'
           AND conrelid = 'pichau_android_fila'::regclass
    ) THEN
        ALTER TABLE pichau_android_fila
            ADD CONSTRAINT pichau_android_fila_diagnostico_objeto_ck
            CHECK (jsonb_typeof(diagnostico) = 'object');
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM pg_constraint
         WHERE conname = 'pichau_android_fila_diagnostico_tamanho_ck'
           AND conrelid = 'pichau_android_fila'::regclass
    ) THEN
        ALTER TABLE pichau_android_fila
            ADD CONSTRAINT pichau_android_fila_diagnostico_tamanho_ck
            CHECK (octet_length(diagnostico::text) <= 2048);
    END IF;
END;
$$;

COMMENT ON COLUMN pichau_android_fila.diagnostico IS
    'Metadados operacionais validados, sem mensagens, HTML, URLs ou identificadores privados.';
