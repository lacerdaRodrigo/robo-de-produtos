-- Acompanhamento e identidade historica sao conceitos distintos.
-- Registros existentes em loja representam acompanhamentos ativos.
ALTER TABLE loja
    ADD COLUMN IF NOT EXISTS acompanhada BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN loja.acompanhada IS
    'Preferencia de acompanhamento; FALSE preserva a identidade e o historico Livelo.';

-- Medicoes antigas podem depender exclusivamente de loja_id. Impedir a
-- exclusao fisica protege esses registros mesmo fora do fluxo normal de
-- desacompanhar, que passa a ser uma atualizacao de estado.
DO $$
DECLARE
    fk_nome TEXT;
BEGIN
    FOR fk_nome IN
        SELECT restricao.conname
          FROM pg_constraint restricao
          JOIN pg_class tabela ON tabela.oid = restricao.conrelid
          JOIN pg_namespace esquema ON esquema.oid = tabela.relnamespace
         WHERE esquema.nspname = current_schema()
           AND tabela.relname = 'pontuacao'
           AND restricao.contype = 'f'
           AND restricao.confrelid = 'loja'::regclass
           AND restricao.conkey = ARRAY[
               (
                   SELECT coluna.attnum::SMALLINT
                     FROM pg_attribute coluna
                    WHERE coluna.attrelid = 'pontuacao'::regclass
                      AND coluna.attname = 'loja_id'
                      AND NOT coluna.attisdropped
               )
           ]
    LOOP
        EXECUTE format('ALTER TABLE pontuacao DROP CONSTRAINT %I', fk_nome);
    END LOOP;

    ALTER TABLE pontuacao
        ADD CONSTRAINT pontuacao_loja_historica_fk
        FOREIGN KEY (loja_id) REFERENCES loja(id) ON DELETE RESTRICT;
END
$$;
