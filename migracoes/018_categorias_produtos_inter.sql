-- Categorias controladas pelo Radar para as ofertas do Compre direto.
--
-- A evolução é aditiva: a categoria textual recebida do Inter continua
-- preservada em produto_direto_inter.categoria. A categoria Radar só existe
-- quando um mapeamento aprovado a atribui explicitamente.

CREATE TABLE IF NOT EXISTS categoria_radar (
    id                  BIGSERIAL PRIMARY KEY,
    slug                TEXT NOT NULL UNIQUE CHECK (
                            slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
                            AND char_length(slug) <= 120
                        ),
    nome                TEXT NOT NULL CHECK (char_length(nome) BETWEEN 1 AND 200),
    categoria_pai_id    BIGINT REFERENCES categoria_radar (id) ON DELETE RESTRICT,
    ativo               BOOLEAN NOT NULL DEFAULT TRUE,
    ordem               INTEGER NOT NULL DEFAULT 0,
    criado_em           TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (categoria_pai_id IS NULL OR categoria_pai_id <> id)
);

CREATE INDEX IF NOT EXISTS idx_categoria_radar_pai_ordem
    ON categoria_radar (categoria_pai_id, ordem, nome);
CREATE INDEX IF NOT EXISTS idx_categoria_radar_ativas
    ON categoria_radar (ordem, nome) WHERE ativo = TRUE;

-- Impede ciclos indiretos, como A -> B -> C -> A. A árvore pode crescer sem
-- depender de uma profundidade máxima codificada na aplicação.
CREATE OR REPLACE FUNCTION impedir_ciclo_categoria_radar()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.categoria_pai_id IS NULL THEN
        RETURN NEW;
    END IF;

    IF EXISTS (
        WITH RECURSIVE ancestrais AS (
            SELECT categoria.id, categoria.categoria_pai_id
              FROM categoria_radar categoria
             WHERE categoria.id = NEW.categoria_pai_id
            UNION ALL
            SELECT categoria.id, categoria.categoria_pai_id
              FROM categoria_radar categoria
              JOIN ancestrais ON ancestrais.categoria_pai_id = categoria.id
        )
        SELECT 1 FROM ancestrais WHERE id = NEW.id
    ) THEN
        RAISE EXCEPTION 'ciclo na hierarquia de categoria_radar';
    END IF;

    RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_categoria_radar_sem_ciclo ON categoria_radar;
CREATE TRIGGER trg_categoria_radar_sem_ciclo
BEFORE INSERT OR UPDATE OF categoria_pai_id ON categoria_radar
FOR EACH ROW EXECUTE FUNCTION impedir_ciclo_categoria_radar();

-- A linha de preferência distingue uma conta ainda não migrada de uma conta
-- que salvou deliberadamente uma seleção vazia. Seleção vazia significa
-- nenhum interesse ativo; nunca significa todas as categorias.
CREATE TABLE IF NOT EXISTS preferencia_produtos_inter_usuario (
    usuario_app_id      BIGINT PRIMARY KEY
                          REFERENCES usuario_app (id) ON DELETE CASCADE,
    configurada_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizada_em       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS categoria_radar_acompanhada (
    usuario_app_id      BIGINT NOT NULL
                          REFERENCES usuario_app (id) ON DELETE CASCADE,
    categoria_radar_id  BIGINT NOT NULL
                          REFERENCES categoria_radar (id) ON DELETE RESTRICT,
    selecionada_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (usuario_app_id, categoria_radar_id)
);

CREATE INDEX IF NOT EXISTS idx_categoria_radar_acompanhada_categoria
    ON categoria_radar_acompanhada (categoria_radar_id, usuario_app_id);

-- Categoria observada é específica da loja. O identificador atual deriva da
-- categoria estruturada disponível no contrato V4; um ID externo real poderá
-- ser preservado aqui quando o Inter o fornecer.
CREATE TABLE IF NOT EXISTS categoria_externa_loja_inter (
    id                              BIGSERIAL PRIMARY KEY,
    loja_direta_inter_id            BIGINT NOT NULL
                                      REFERENCES loja_direta_inter (id)
                                      ON DELETE RESTRICT,
    identificador_categoria_externa TEXT NOT NULL CHECK (
                                        char_length(identificador_categoria_externa)
                                        BETWEEN 1 AND 500
                                      ),
    nome_categoria_externa          TEXT NOT NULL CHECK (
                                        char_length(nome_categoria_externa)
                                        BETWEEN 1 AND 500
                                      ),
    breadcrumb_externo              TEXT CHECK (
                                        char_length(breadcrumb_externo) <= 2000
                                      ),
    primeira_observacao_em          TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultima_observacao_em            TIMESTAMPTZ NOT NULL DEFAULT now(),
    estado                          TEXT NOT NULL DEFAULT 'nao_mapeada'
                                      CHECK (estado IN (
                                        'nao_mapeada', 'mapeada', 'ignorada'
                                      )),
    UNIQUE (loja_direta_inter_id, identificador_categoria_externa)
);

CREATE INDEX IF NOT EXISTS idx_categoria_externa_inter_pendentes
    ON categoria_externa_loja_inter (
        estado, primeira_observacao_em, loja_direta_inter_id
    );

-- Cada nova decisão cria uma versão. A versão anterior é desativada, nunca
-- reescrita ou excluída, para permitir auditoria e reclassificação.
CREATE TABLE IF NOT EXISTS mapeamento_categoria_loja_inter (
    id                                  BIGSERIAL PRIMARY KEY,
    categoria_externa_loja_inter_id     BIGINT NOT NULL
                                          REFERENCES categoria_externa_loja_inter (id)
                                          ON DELETE RESTRICT,
    categoria_radar_id                  BIGINT NOT NULL
                                          REFERENCES categoria_radar (id)
                                          ON DELETE RESTRICT,
    versao_mapeamento                   INTEGER NOT NULL
                                          CHECK (versao_mapeamento > 0),
    ativo                               BOOLEAN NOT NULL DEFAULT TRUE,
    motivo                              TEXT CHECK (char_length(motivo) <= 1000),
    criado_por_usuario_app_id           BIGINT REFERENCES usuario_app (id)
                                          ON DELETE SET NULL,
    criado_em                           TIMESTAMPTZ NOT NULL DEFAULT now(),
    desativado_em                       TIMESTAMPTZ,
    UNIQUE (categoria_externa_loja_inter_id, versao_mapeamento),
    CHECK ((ativo AND desativado_em IS NULL) OR NOT ativo)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mapeamento_categoria_inter_ativo
    ON mapeamento_categoria_loja_inter (categoria_externa_loja_inter_id)
    WHERE ativo = TRUE;
CREATE INDEX IF NOT EXISTS idx_mapeamento_categoria_inter_radar
    ON mapeamento_categoria_loja_inter (categoria_radar_id)
    WHERE ativo = TRUE;

ALTER TABLE produto_direto_inter
    ADD COLUMN IF NOT EXISTS categoria_externa_loja_inter_id BIGINT
        REFERENCES categoria_externa_loja_inter (id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS categoria_radar_id BIGINT
        REFERENCES categoria_radar (id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS estado_classificacao TEXT NOT NULL
        DEFAULT 'sem_categoria_na_origem'
        CHECK (estado_classificacao IN (
            'classificado',
            'categoria_externa_nao_mapeada',
            'sem_categoria_na_origem',
            'classificacao_ambigua',
            'erro_de_classificacao'
        )),
    ADD COLUMN IF NOT EXISTS motivo_classificacao TEXT
        CHECK (char_length(motivo_classificacao) <= 1000),
    ADD COLUMN IF NOT EXISTS mapeamento_categoria_loja_inter_id BIGINT
        REFERENCES mapeamento_categoria_loja_inter (id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS versao_mapeamento INTEGER
        CHECK (versao_mapeamento IS NULL OR versao_mapeamento > 0),
    ADD COLUMN IF NOT EXISTS classificado_em TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_produto_direto_inter_categoria_radar
    ON produto_direto_inter (categoria_radar_id, loja_direta_inter_id)
    WHERE ativo = TRUE AND estado_classificacao = 'classificado';
CREATE INDEX IF NOT EXISTS idx_produto_direto_inter_classificacao_pendente
    ON produto_direto_inter (estado_classificacao, atualizado_em)
    WHERE estado_classificacao <> 'classificado';
CREATE INDEX IF NOT EXISTS idx_produto_direto_inter_categoria_externa
    ON produto_direto_inter (categoria_externa_loja_inter_id);

-- Preserva as categorias externas já existentes. Não cria mapeamento Radar e
-- não decide categoria por semelhança: todas entram observáveis como pendência.
INSERT INTO categoria_externa_loja_inter (
    loja_direta_inter_id,
    identificador_categoria_externa,
    nome_categoria_externa,
    breadcrumb_externo,
    primeira_observacao_em,
    ultima_observacao_em,
    estado
)
SELECT produto.loja_direta_inter_id,
       lower(regexp_replace(trim(produto.categoria), '[[:space:]]+', ' ', 'g')),
       trim(produto.categoria),
       trim(produto.categoria),
       min(produto.criado_em),
       max(produto.atualizado_em),
       'nao_mapeada'
  FROM produto_direto_inter produto
 WHERE produto.categoria IS NOT NULL
   AND trim(produto.categoria) <> ''
 GROUP BY produto.loja_direta_inter_id,
          lower(regexp_replace(trim(produto.categoria), '[[:space:]]+', ' ', 'g')),
          trim(produto.categoria)
ON CONFLICT (loja_direta_inter_id, identificador_categoria_externa)
DO UPDATE SET
    nome_categoria_externa = EXCLUDED.nome_categoria_externa,
    breadcrumb_externo = EXCLUDED.breadcrumb_externo,
    ultima_observacao_em = GREATEST(
        categoria_externa_loja_inter.ultima_observacao_em,
        EXCLUDED.ultima_observacao_em
    );

UPDATE produto_direto_inter produto
   SET categoria_externa_loja_inter_id = externa.id,
       estado_classificacao = 'categoria_externa_nao_mapeada',
       motivo_classificacao = 'categoria_externa_sem_mapeamento_aprovado'
  FROM categoria_externa_loja_inter externa
 WHERE externa.loja_direta_inter_id = produto.loja_direta_inter_id
   AND produto.categoria IS NOT NULL
   AND trim(produto.categoria) <> ''
   AND externa.identificador_categoria_externa = lower(
       regexp_replace(trim(produto.categoria), '[[:space:]]+', ' ', 'g')
   )
   AND produto.categoria_radar_id IS NULL;

UPDATE produto_direto_inter
   SET estado_classificacao = 'sem_categoria_na_origem',
       motivo_classificacao = 'categoria_ausente_no_contrato_inter'
 WHERE (categoria IS NULL OR trim(categoria) = '')
   AND categoria_radar_id IS NULL;

-- Recorte inicial controlado. São dados evolutivos, não um enum da API,
-- coletor ou Flutter. Novas categorias podem ser adicionadas sem código.
INSERT INTO categoria_radar (slug, nome, ordem)
VALUES
    ('eletronicos', 'Eletrônicos', 10),
    ('eletrodomesticos', 'Eletrodomésticos', 20),
    ('casa', 'Casa', 30)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO categoria_radar (slug, nome, categoria_pai_id, ordem)
SELECT dados.slug, dados.nome, pai.id, dados.ordem
  FROM (VALUES
      ('celulares', 'Celulares', 'eletronicos', 10),
      ('acessorios-para-celulares', 'Acessórios para celulares', 'eletronicos', 20),
      ('tablets', 'Tablets', 'eletronicos', 30),
      ('notebooks', 'Notebooks', 'eletronicos', 40),
      ('smartwatches', 'Smartwatches', 'eletronicos', 50),
      ('tvs', 'TVs', 'eletronicos', 60),
      ('audio', 'Áudio', 'eletronicos', 70),
      ('componentes-para-computador', 'Componentes para computador', 'eletronicos', 80),
      ('perifericos-para-computador', 'Periféricos para computador', 'eletronicos', 90),
      ('monitores', 'Monitores', 'eletronicos', 100),
      ('air-fryer', 'Air Fryer', 'eletrodomesticos', 10),
      ('geladeiras', 'Geladeiras', 'eletrodomesticos', 20),
      ('fogoes', 'Fogões', 'eletrodomesticos', 30),
      ('aspiradores', 'Aspiradores', 'eletrodomesticos', 40),
      ('cozinha', 'Cozinha', 'casa', 10),
      ('sala', 'Sala', 'casa', 20)
  ) AS dados(slug, nome, pai_slug, ordem)
  JOIN categoria_radar pai ON pai.slug = dados.pai_slug
ON CONFLICT (slug) DO NOTHING;

INSERT INTO categoria_radar (slug, nome, categoria_pai_id, ordem)
SELECT dados.slug, dados.nome, pai.id, dados.ordem
  FROM (VALUES
      ('cabos', 'Cabos', 'acessorios-para-celulares', 10),
      ('carregadores', 'Carregadores', 'acessorios-para-celulares', 20),
      ('capas-e-peliculas', 'Capas e películas', 'acessorios-para-celulares', 30),
      ('suportes', 'Suportes', 'acessorios-para-celulares', 40),
      ('placas-de-video', 'Placas de vídeo', 'componentes-para-computador', 10),
      ('processadores', 'Processadores', 'componentes-para-computador', 20),
      ('ssd', 'SSD', 'componentes-para-computador', 30),
      ('teclados', 'Teclados', 'perifericos-para-computador', 10),
      ('mouses', 'Mouses', 'perifericos-para-computador', 20),
      ('headsets', 'Headsets', 'perifericos-para-computador', 30),
      ('panelas', 'Panelas', 'cozinha', 10),
      ('utensilios', 'Utensílios', 'cozinha', 20),
      ('moveis', 'Móveis', 'sala', 10),
      ('decoracao', 'Decoração', 'sala', 20)
  ) AS dados(slug, nome, pai_slug, ordem)
  JOIN categoria_radar pai ON pai.slug = dados.pai_slug
ON CONFLICT (slug) DO NOTHING;

COMMENT ON TABLE categoria_radar IS
    'Taxonomia hierárquica controlada pelo Radar; categorias usadas são inativadas, não apagadas.';
COMMENT ON TABLE categoria_radar_acompanhada IS
    'Nós escolhidos diretamente pela pessoa; descendentes são resolvidos dinamicamente.';
COMMENT ON COLUMN produto_direto_inter.categoria IS
    'Categoria externa original preservada; não equivale à categoria Radar.';
COMMENT ON COLUMN produto_direto_inter.categoria_radar_id IS
    'Categoria principal aprovada; NULL enquanto a classificação estiver pendente.';
