-- Compatibilidade para o schema V4 aplicado durante o gate físico antes da
-- versão final da migração 007. Não remove dados e pode ser executada mais de
-- uma vez.

ALTER TABLE medicao_produto_direto_inter
    ADD COLUMN IF NOT EXISTS preco_lista_texto TEXT
        CHECK (char_length(preco_lista_texto) <= 500),
    ADD COLUMN IF NOT EXISTS desconto_texto TEXT
        CHECK (char_length(desconto_texto) <= 500),
    ADD COLUMN IF NOT EXISTS desconto_percentual_texto TEXT
        CHECK (char_length(desconto_percentual_texto) <= 500),
    ADD COLUMN IF NOT EXISTS preco_atual_texto TEXT
        CHECK (char_length(preco_atual_texto) <= 500),
    ADD COLUMN IF NOT EXISTS cashback_texto TEXT
        CHECK (char_length(cashback_texto) <= 500),
    ADD COLUMN IF NOT EXISTS cashback_percentual_texto TEXT
        CHECK (char_length(cashback_percentual_texto) <= 500),
    ADD COLUMN IF NOT EXISTS preco_liquido_texto TEXT
        CHECK (char_length(preco_liquido_texto) <= 500),
    ADD COLUMN IF NOT EXISTS parcelamento TEXT
        CHECK (char_length(parcelamento) <= 500),
    ADD COLUMN IF NOT EXISTS etiquetas TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE execucao_loja_produtos_inter
    DROP CONSTRAINT IF EXISTS execucao_loja_produtos_inter_codigo_falha_check;
ALTER TABLE execucao_loja_produtos_inter
    ADD CONSTRAINT execucao_loja_produtos_inter_codigo_falha_check
    CHECK (codigo_falha IN (
        'rede', 'http', 'resposta_grande', 'json_invalido', 'schema_invalido',
        'catalogo_pequeno', 'offset_incoerente', 'total_incoerente',
        'pagina_repetida', 'limite_paginacao', 'banco', 'inesperada'
    ));

ALTER TABLE estagio_produto_inter
    DROP CONSTRAINT IF EXISTS estagio_produto_inter_caminho_check;
ALTER TABLE estagio_produto_inter
    ADD CONSTRAINT estagio_produto_inter_caminho_check
    CHECK (
        char_length(caminho) <= 2000
        AND caminho LIKE '/%'
        AND caminho NOT LIKE '//%'
    );

ALTER TABLE produto_direto_inter
    DROP CONSTRAINT IF EXISTS produto_direto_inter_caminho_check;
ALTER TABLE produto_direto_inter
    ADD CONSTRAINT produto_direto_inter_caminho_check
    CHECK (
        char_length(caminho) <= 2000
        AND caminho LIKE '/%'
        AND caminho NOT LIKE '//%'
    );

CREATE INDEX IF NOT EXISTS idx_medicao_produto_direto_inter_expurgo
    ON medicao_produto_direto_inter (momento);
