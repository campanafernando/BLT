-- Run once (and again after schema changes) against the BLT database. Safe to re-run.
-- The password comes from the file secrets/blt_pg_password. From the BLT root:
--
-- docker compose -f blt-project/compose.yaml exec -T db psql -U blt -d blt \
--   -v mcp_password="$(cat secrets/blt_pg_password)" \
--   -f - < mcp_servers/postgres-readonly.sql
--
-- blt_mcp can read only tasks_task, specs_spec and the mcp_users view. Everything else
-- (password hashes, JWT blacklist, sessions) stays out of reach. Run `migrate` first.

-- psql does not expand :'vars' inside $$ blocks, hence \gexec.
SELECT 'CREATE ROLE blt_mcp NOSUPERUSER NOCREATEDB NOCREATEROLE'
 WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'blt_mcp') \gexec
SELECT format('ALTER ROLE blt_mcp LOGIN PASSWORD %L', :'mcp_password') \gexec

-- Drop what earlier versions of this script granted.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE SELECT ON TABLES FROM blt_mcp;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM blt_mcp;

GRANT CONNECT ON DATABASE blt TO blt_mcp;
GRANT USAGE ON SCHEMA public TO blt_mcp;

CREATE OR REPLACE VIEW mcp_users AS
  SELECT id, username, first_name, last_name, is_active FROM auth_user;

GRANT SELECT ON tasks_task, specs_spec, mcp_users TO blt_mcp;
