-- RN29: uma tentativa com base degenerada deve ficar visível sem substituir
-- o último snapshot Livelo completo. Registros históricos são completos.
ALTER TABLE execucao
    ADD COLUMN IF NOT EXISTS qualidade TEXT NOT NULL DEFAULT 'completa'
        CHECK (qualidade IN ('completa', 'degradada'));

COMMENT ON COLUMN execucao.qualidade IS
    'Qualidade da tentativa Livelo; degradada não publica catálogo/pontuações.';
