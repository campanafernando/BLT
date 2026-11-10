-- Run once against the BLT database. Replace :'mcp_password' with a real
-- password (the launcher reads BLT_PG_PASSWORD from .env).
--
-- docker compose -f blt-project/compose.yaml exec -T db psql -U blt -d blt \
--   -v mcp_password="$(grep '^BLT_PG_PASSWORD=' .env | cut -d= -f2-)" \
--   -f - < mcp_servers/postgres-readonly.sql

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'blt_mcp') THEN
    CREATE ROLE blt_mcp LOGIN PASSWORD :'mcp_password' NOSUPERUSER NOCREATEDB NOCREATEROLE;
  ELSE
    ALTER ROLE blt_mcp PASSWORD :'mcp_password';
  END IF;
END $$;

GRANT CONNECT ON DATABASE blt TO blt_mcp;
GRANT USAGE ON SCHEMA public TO blt_mcp;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO blt_mcp;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO blt_mcp;
