-- Categorias do Shopping Inter passam a ser a fonte funcional oficial.
--
-- As migrations 018/019 permanecem no histórico, mas a taxonomia Radar e a
-- classificação derivada deixam de participar do runtime. A preferência da
-- pessoa passa a guardar o valor externo exato recebido do Inter; NULL representa
-- o agrupamento funcional "Sem categoria" e nunca é gravado sobre o dado bruto
-- do produto.

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM categoria_radar_acompanhada LIMIT 1) THEN
        RAISE EXCEPTION
            'existem categorias Radar acompanhadas; migracao exige revisao manual antes da limpeza';
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS categoria_inter_acompanhada (
    usuario_app_id  BIGINT NOT NULL
                      REFERENCES usuario_app (id) ON DELETE CASCADE,
    categoria       TEXT CHECK (
                      categoria IS NULL OR (
                        btrim(categoria) <> '' AND char_length(categoria) <= 500
                      )
                    ),
    selecionada_em  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE NULLS NOT DISTINCT (usuario_app_id, categoria)
);

CREATE INDEX IF NOT EXISTS idx_categoria_inter_acompanhada_categoria
    ON categoria_inter_acompanhada (categoria, usuario_app_id);

-- Remove primeiro os consumidores/FKs da taxonomia antiga.
DROP TABLE IF EXISTS categoria_radar_acompanhada;

ALTER TABLE produto_direto_inter
    DROP COLUMN IF EXISTS categoria_externa_loja_inter_id,
    DROP COLUMN IF EXISTS categoria_radar_id,
    DROP COLUMN IF EXISTS estado_classificacao,
    DROP COLUMN IF EXISTS motivo_classificacao,
    DROP COLUMN IF EXISTS mapeamento_categoria_loja_inter_id,
    DROP COLUMN IF EXISTS versao_mapeamento,
    DROP COLUMN IF EXISTS classificado_em;

DROP TABLE IF EXISTS mapeamento_categoria_loja_inter;
DROP TABLE IF EXISTS categoria_externa_loja_inter;
DROP TABLE IF EXISTS categoria_radar;
DROP FUNCTION IF EXISTS impedir_ciclo_categoria_radar();

CREATE INDEX IF NOT EXISTS idx_produto_direto_inter_categoria_ativa
    ON produto_direto_inter (categoria, loja_direta_inter_id)
    WHERE ativo = TRUE;

COMMENT ON TABLE categoria_inter_acompanhada IS
    'Categorias externas exatas do Shopping Inter acompanhadas pela pessoa; categoria NULL representa Sem categoria.';
COMMENT ON COLUMN produto_direto_inter.categoria IS
    'Categoria externa original recebida do Shopping Inter; NULL significa ausência na origem.';
