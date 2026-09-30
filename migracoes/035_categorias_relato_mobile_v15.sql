-- Alinha novas categorias de suporte ao formulário mobile V15.
-- Valores legados são mantidos para que relatos antigos continuem válidos.
ALTER TABLE relato_problema_app
    DROP CONSTRAINT IF EXISTS relato_problema_app_categoria_check;

ALTER TABLE relato_problema_app
    ADD CONSTRAINT relato_problema_app_categoria_check
    CHECK (categoria IN (
        'erro', 'dados', 'conta', 'outro',
        'catalog', 'access', 'notification', 'privacy', 'other'
    ));
