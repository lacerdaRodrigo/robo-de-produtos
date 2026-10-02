-- Registra cada push por evento e aparelho para retomar somente entregas falhas.
-- Antes da aplicação, suspenda o processamento da outbox para encerrar a fila
-- legada sem risco de um worker antigo enviar mensagens durante o corte.
-- Aplicar manualmente após autorização operacional; não aplicar em produção por automação.

BEGIN;

-- A fila anterior não guardava aceite individual por aparelho. Encerra itens
-- antigos sem replay: o histórico completo continua disponível na Central.
UPDATE notificacao_outbox_alerta
   SET estado = 'enviada',
       ultimo_erro = 'fila legada encerrada sem histórico por dispositivo',
       atualizado_em = now()
 WHERE estado IN ('pendente', 'falha', 'enviando');

CREATE TABLE IF NOT EXISTS notificacao_entrega_alerta (
    evento_alerta_id  BIGINT NOT NULL REFERENCES evento_alerta (id) ON DELETE CASCADE,
    token_fcm_app_id  BIGINT NOT NULL REFERENCES token_fcm_app (id) ON DELETE CASCADE,
    estado            TEXT NOT NULL DEFAULT 'pendente'
                      CHECK (estado IN ('pendente', 'enviando', 'enviada', 'falha', 'invalida', 'cancelada')),
    tentativas        INTEGER NOT NULL DEFAULT 0 CHECK (tentativas >= 0),
    proxima_tentativa_em TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultimo_erro       TEXT CHECK (ultimo_erro IS NULL OR char_length(ultimo_erro) <= 200),
    criado_em         TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (evento_alerta_id, token_fcm_app_id)
);

CREATE INDEX IF NOT EXISTS idx_notificacao_entrega_alerta_pendente
    ON notificacao_entrega_alerta (proxima_tentativa_em, evento_alerta_id, token_fcm_app_id)
    WHERE estado IN ('pendente', 'falha');

-- A API usa robo_api; a role pode não existir em instalações anteriores à 032.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'robo_api') THEN
        EXECUTE 'GRANT SELECT, INSERT, UPDATE ON TABLE public.notificacao_entrega_alerta TO robo_api';
    END IF;
END;
$$;

COMMIT;
