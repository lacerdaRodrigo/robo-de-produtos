-- Classifica somente categorias externas cuja identidade já coincide
-- exatamente com um slug Radar. Não usa nome de produto, marca ou similaridade.
-- A migration 018 preservou as pendências; esta registra decisões auditáveis
-- para o subconjunto canônico e atualiza o catálogo já existente.

WITH candidatas AS (
    SELECT externa.id AS categoria_externa_loja_inter_id,
           radar.id AS categoria_radar_id,
           COALESCE((
               SELECT max(anterior.versao_mapeamento)
                 FROM mapeamento_categoria_loja_inter anterior
                WHERE anterior.categoria_externa_loja_inter_id = externa.id
           ), 0) + 1 AS versao_mapeamento
      FROM categoria_externa_loja_inter externa
      JOIN categoria_radar radar
        ON radar.slug = externa.identificador_categoria_externa
       AND radar.ativo = TRUE
     WHERE externa.estado <> 'ignorada'
       AND NOT EXISTS (
           SELECT 1
             FROM mapeamento_categoria_loja_inter ativo
            WHERE ativo.categoria_externa_loja_inter_id = externa.id
              AND ativo.ativo = TRUE
       )
), mapeamentos_criados AS (
    INSERT INTO mapeamento_categoria_loja_inter (
        categoria_externa_loja_inter_id,
        categoria_radar_id,
        versao_mapeamento,
        ativo,
        motivo
    )
    SELECT categoria_externa_loja_inter_id,
           categoria_radar_id,
           versao_mapeamento,
           TRUE,
           'identificador externo coincide exatamente com slug Radar'
      FROM candidatas
    ON CONFLICT (categoria_externa_loja_inter_id, versao_mapeamento)
    DO NOTHING
    RETURNING categoria_externa_loja_inter_id
)
UPDATE categoria_externa_loja_inter externa
   SET estado = 'mapeada'
 WHERE externa.id IN (SELECT categoria_externa_loja_inter_id FROM mapeamentos_criados)
    OR EXISTS (
        SELECT 1
          FROM mapeamento_categoria_loja_inter mapa
         WHERE mapa.categoria_externa_loja_inter_id = externa.id
           AND mapa.ativo = TRUE
    );

UPDATE produto_direto_inter produto
   SET categoria_externa_loja_inter_id = externa.id,
       categoria_radar_id = mapa.categoria_radar_id,
       estado_classificacao = 'classificado',
       motivo_classificacao = 'mapeamento exato de categoria externa aprovado',
       mapeamento_categoria_loja_inter_id = mapa.id,
       versao_mapeamento = mapa.versao_mapeamento,
       classificado_em = now()
  FROM categoria_externa_loja_inter externa
  JOIN mapeamento_categoria_loja_inter mapa
    ON mapa.categoria_externa_loja_inter_id = externa.id
   AND mapa.ativo = TRUE
 WHERE produto.loja_direta_inter_id = externa.loja_direta_inter_id
   AND produto.categoria IS NOT NULL
   AND trim(produto.categoria) <> ''
   AND externa.identificador_categoria_externa = lower(
       regexp_replace(trim(produto.categoria), '[[:space:]]+', ' ', 'g')
   )
   AND (
       produto.categoria_radar_id IS DISTINCT FROM mapa.categoria_radar_id
       OR produto.mapeamento_categoria_loja_inter_id IS DISTINCT FROM mapa.id
       OR produto.estado_classificacao IS DISTINCT FROM 'classificado'
   );

COMMENT ON TABLE mapeamento_categoria_loja_inter IS
    'Mapeamentos auditáveis por categoria externa; a migration 019 semeia somente igualdade exata com slug Radar.';
