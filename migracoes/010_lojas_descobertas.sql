-- Separa lojas encontradas na Livelo das lojas escolhidas pelo usuario.
ALTER TABLE loja ADD COLUMN IF NOT EXISTS favorita BOOLEAN NOT NULL DEFAULT TRUE;
