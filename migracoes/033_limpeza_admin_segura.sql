-- Limpeza administrativa por funções fixas: robo_api não recebe TRUNCATE.
-- Aplicar somente depois de conferir backup e alvo Neon, como proprietário.

CREATE OR REPLACE FUNCTION public.apagar_dados_livelo()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    TRUNCATE TABLE
        public.pontuacao,
        public.apelido,
        public.loja,
        public.parceiro_livelo,
        public.execucao,
        public.preferencia,
        public.disparo_manual
    RESTART IDENTITY;

    INSERT INTO public.preferencia (chave, valor) VALUES
        ('multiplicador_padrao', '2.0'),
        ('piso_pontos_padrao', '4'),
        ('assinante_clube', 'false');
END;
$$;

CREATE OR REPLACE FUNCTION public.resetar_dados_inter()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
BEGIN
    TRUNCATE TABLE
        public.cashback_inter,
        public.favorita_inter,
        public.execucao_inter,
        public.mapeamento_categoria_cashback_inter,
        public.loja_inter,
        public.disparo_manual_inter,
        public.medicao_produto_direto_inter,
        public.estagio_produto_inter,
        public.produto_direto_inter,
        public.oferta_direta_inter_atual,
        public.execucao_loja_produtos_inter,
        public.execucao_produtos_inter,
        public.loja_direta_inter
    RESTART IDENTITY;
END;
$$;

REVOKE ALL ON FUNCTION public.apagar_dados_livelo() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.resetar_dados_inter() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.apagar_dados_livelo() TO robo_api;
GRANT EXECUTE ON FUNCTION public.resetar_dados_inter() TO robo_api;
