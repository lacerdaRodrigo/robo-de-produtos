import { readFileSync } from "node:fs";
import { resolve } from "node:path";

import { describe, expect, it } from "vitest";

const migracao = readFileSync(
  resolve(process.cwd(), "../../migracoes/034_role_backup_readonly.sql"),
  "utf8",
);

describe("role de backup Neon somente leitura", () => {
  it("cria grupo NOLOGIN sem atributos privilegiados e falha se já estiver elevado", () => {
    expect(migracao).toMatch(/CREATE ROLE radar_backup[\s\S]*NOLOGIN/);
    expect(migracao).toContain("NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS");
    expect(migracao).toContain("radar_backup precisa ser NOLOGIN e sem atributos privilegiados");
    expect(migracao).toContain("FROM pg_catalog.pg_auth_members");
  });

  it("remove grants anteriores e concede SELECT, nunca escrita", () => {
    expect(migracao).toContain("REVOKE ALL ON ALL TABLES IN SCHEMA public FROM radar_backup");
    expect(migracao).toContain("REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM radar_backup");
    expect(migracao).toContain("GRANT SELECT ON ALL TABLES IN SCHEMA public TO radar_backup");
    expect(migracao).not.toMatch(/GRANT\s+(?:INSERT|UPDATE|DELETE|TRUNCATE|ALL)\b/i);
  });

  it("aplica leitura padrão a objetos futuros e não contém senha", () => {
    expect(migracao).toContain("ALTER DEFAULT PRIVILEGES FOR ROLE neondb_owner IN SCHEMA public");
    expect(migracao).toContain("GRANT SELECT ON TABLES TO radar_backup");
    expect(migracao).toContain("GRANT SELECT ON SEQUENCES TO radar_backup");
    expect(migracao).not.toMatch(/PASSWORD\s+['\"]/i);
  });
});
