-- Aceita a melhor tentativa completa quando o total declarado varia entre
-- paginas. A qualidade separa um snapshot integral de uma atualizacao
-- degradada, que nao pode inativar produtos ausentes.

ALTER TABLE execucao_loja_produtos_inter
    ADD COLUMN IF NOT EXISTS qualidade TEXT
        CHECK (qualidade IN ('completa', 'degradada')),
    ADD COLUMN IF NOT EXISTS tentativas INTEGER
        CHECK (tentativas > 0),
    ADD COLUMN IF NOT EXISTS total_declarado_minimo INTEGER
        CHECK (total_declarado_minimo >= 0),
    ADD COLUMN IF NOT EXISTS total_declarado_maximo INTEGER
        CHECK (total_declarado_maximo >= 0);

UPDATE execucao_loja_produtos_inter
   SET qualidade = 'completa',
       tentativas = 1,
       total_declarado_minimo = total_declarado,
       total_declarado_maximo = total_declarado
 WHERE estado = 'sucesso'
   AND qualidade IS NULL;

ALTER TABLE execucao_loja_produtos_inter
    DROP CONSTRAINT IF EXISTS execucao_loja_produtos_inter_intervalo_total_check;
ALTER TABLE execucao_loja_produtos_inter
    ADD CONSTRAINT execucao_loja_produtos_inter_intervalo_total_check
    CHECK (
        total_declarado_minimo IS NULL
        OR total_declarado_maximo IS NULL
        OR total_declarado_minimo <= total_declarado_maximo
    );
