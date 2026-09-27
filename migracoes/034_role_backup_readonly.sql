-- Role aditiva e somente leitura usada pelo backup criptografado em CI.
-- Aplicar como proprietário depois de conferir o banco de destino.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'radar_backup'
    ) THEN
        CREATE ROLE radar_backup
            NOLOGIN INHERIT NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
    END IF;
    IF EXISTS (
        SELECT 1
          FROM pg_catalog.pg_roles
         WHERE rolname = 'radar_backup'
           AND (
               rolcanlogin OR rolsuper OR rolcreatedb OR rolcreaterole
               OR rolreplication OR rolbypassrls
               OR EXISTS (
                   SELECT 1
                     FROM pg_catalog.pg_auth_members
                    WHERE member = pg_roles.oid
               )
           )
    ) THEN
        RAISE EXCEPTION 'radar_backup precisa ser NOLOGIN e sem atributos privilegiados';
    END IF;
END;
$$;

DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO radar_backup', current_database());
END;
$$;

GRANT USAGE ON SCHEMA public TO radar_backup;
REVOKE CREATE ON SCHEMA public FROM radar_backup;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM radar_backup;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM radar_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO radar_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO radar_backup;

-- A credencial de login deve ser criada fora do repositório e herdará esta role.
ALTER DEFAULT PRIVILEGES FOR ROLE neondb_owner IN SCHEMA public
    REVOKE ALL ON TABLES FROM radar_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE neondb_owner IN SCHEMA public
    GRANT SELECT ON TABLES TO radar_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE neondb_owner IN SCHEMA public
    REVOKE ALL ON SEQUENCES FROM radar_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE neondb_owner IN SCHEMA public
    GRANT SELECT ON SEQUENCES TO radar_backup;
