-- Preferência explícita do sino por loja (Livelo).
--
-- O alerta calculado em `pontuacao.alertou` é um retrato da coleta; não é
-- uma escolha do usuário. A escolha agora mora em `loja.alerta_ativo`.
ALTER TABLE loja
    ADD COLUMN IF NOT EXISTS alerta_ativo BOOLEAN NOT NULL DEFAULT FALSE;

-- Descarta somente o resultado antigo de alerta. Catálogo, acompanhamentos e
-- demais retratos históricos continuam preservados.
UPDATE pontuacao SET alertou = FALSE WHERE alertou = TRUE;
