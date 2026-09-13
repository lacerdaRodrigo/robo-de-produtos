-- Permissões mínimas para o publicador Pichau gerar alertas pessoais.
-- Depende da migration 026 e deve ser aplicada pela operação do banco.
-- As funções usam SECURITY DEFINER para não expor ao robô acesso direto às
-- tabelas pessoais da Central nem exigir grants amplos no publicador.

ALTER FUNCTION criar_outbox_alerta()
    SECURITY DEFINER;
ALTER FUNCTION criar_outbox_alerta()
    SET search_path = pg_catalog, public, pg_temp;

ALTER FUNCTION gerar_alertas_pichau_com_push(BIGINT, BOOLEAN)
    SECURITY DEFINER;
ALTER FUNCTION gerar_alertas_pichau_com_push(BIGINT, BOOLEAN)
    SET search_path = pg_catalog, public, pg_temp;

ALTER FUNCTION gerar_alertas_pichau(BIGINT)
    SECURITY DEFINER;
ALTER FUNCTION gerar_alertas_pichau(BIGINT)
    SET search_path = pg_catalog, public, pg_temp;

GRANT EXECUTE ON FUNCTION gerar_alertas_pichau(BIGINT) TO pichau_publisher;
