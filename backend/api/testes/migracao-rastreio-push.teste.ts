import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const migracao = readFileSync(
  resolve(process.cwd(), "../../migracoes/036_rastreio_entrega_push.sql"),
  "utf8",
);

describe("migration do rastreio de entrega FCM", () => {
  it("registra uma entrega por evento e aparelho sem copiar o token FCM", () => {
    expect(migracao).toContain("evento_alerta_id  BIGINT NOT NULL REFERENCES evento_alerta (id) ON DELETE CASCADE");
    expect(migracao).toContain("token_fcm_app_id  BIGINT NOT NULL REFERENCES token_fcm_app (id) ON DELETE CASCADE");
    expect(migracao).toContain("PRIMARY KEY (evento_alerta_id, token_fcm_app_id)");
    expect(migracao).toContain("CHECK (estado IN ('pendente', 'enviando', 'enviada', 'falha', 'invalida', 'cancelada'))");
    expect(migracao).not.toContain("token          TEXT");
  });

  it("indexa retries e concede acesso somente ao grupo da API quando existente", () => {
    expect(migracao).toContain("WHERE estado IN ('pendente', 'falha')");
    expect(migracao).toContain("rolname = 'robo_api'");
    expect(migracao).toContain("EXECUTE 'GRANT SELECT, INSERT, UPDATE ON TABLE public.notificacao_entrega_alerta TO robo_api'");
  });

  it("encerra a fila anterior sem histórico por aparelho para evitar replay ambíguo", () => {
    expect(migracao).toContain("UPDATE notificacao_outbox_alerta");
    expect(migracao).toContain("fila legada encerrada sem histórico por dispositivo");
    expect(migracao).toContain("WHERE estado IN ('pendente', 'falha', 'enviando')");
  });
});
