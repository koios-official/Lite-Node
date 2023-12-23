--------------------------------------------------------------------------------
-- Entry point for Koios node DB setup:
-- 1) {{SCHEMA}} schema that will hold all RPC functions/views and cached tables
-- 2) web_anon user
-- 3) {{SCHEMA}}.control_table
-- 4) {{SCHEMA}}.genesis
-- 5) drop existing functions
-- 6) helper functions
-- 7) optional db indexes on important public tables
--------------------------------------------------------------------------------
-- GREST SCHEMA --
CREATE SCHEMA IF NOT EXISTS {{SCHEMA}};
CREATE SCHEMA IF NOT EXISTS {{SCHEMA}}v0;

-- WEB_ANON USER --
DO $$
BEGIN
  CREATE ROLE web_anon nologin;
EXCEPTION
  WHEN DUPLICATE_OBJECT THEN
    RAISE NOTICE 'web_anon exists, skipping...';
END
$$;

DO $$
BEGIN
  CREATE ROLE authenticator LOGIN;
  EXECUTE FORMAT('GRANT CONNECT ON DATABASE %I to authenticator', current_database());
EXCEPTION
  WHEN DUPLICATE_OBJECT THEN
    RAISE NOTICE 'authenticator exists, skipping...';
END;
$$;

GRANT USAGE ON SCHEMA public TO authenticator, web_anon;
GRANT USAGE ON SCHEMA {{SCHEMA}} TO authenticator, web_anon;
GRANT USAGE ON SCHEMA {{SCHEMA}}v0 TO authenticator, web_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticator, web_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA {{SCHEMA}} TO authenticator, web_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA {{SCHEMA}}v0 TO authenticator, web_anon;
GRANT web_anon TO authenticator;
ALTER ROLE authenticator SET statement_timeout = 125000;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT
SELECT ON TABLES TO authenticator, web_anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA {{SCHEMA}} GRANT
SELECT ON TABLES TO authenticator, web_anon;

ALTER DEFAULT PRIVILEGES IN SCHEMA {{SCHEMA}}v0 GRANT
SELECT ON TABLES TO authenticator, web_anon;

ALTER ROLE web_anon SET search_path TO {{SCHEMA}}, public;
ALTER ROLE authenticator SET search_path TO {{SCHEMA}}, public;

-- CONTROL TABLE --
CREATE TABLE IF NOT EXISTS {{SCHEMA}}.control_table (
  key text PRIMARY KEY,
  last_value text NOT NULL,
  artifacts text
);

-- GENESIS TABLE --
DROP TABLE IF EXISTS {{SCHEMA}}.genesis;

-- Data Types are intentionally kept varchar for single ID row to avoid future edge cases
CREATE TABLE {{SCHEMA}}.genesis (
  networkmagic varchar,
  networkid varchar,
  activeslotcoeff varchar,
  updatequorum varchar,
  maxlovelacesupply varchar,
  epochlength varchar,
  systemstart varchar,
  slotsperkesperiod varchar,
  slotlength varchar,
  maxkesrevolutions varchar,
  securityparam varchar,
  alonzogenesis varchar
);


-- DROP EXISTING FUNCTIONS
DO
$do$
DECLARE
  _sql text;
BEGIN
  SELECT INTO _sql
    string_agg(
      format(
        'DROP %s %s CASCADE;',
        CASE prokind
            WHEN 'f' THEN 'FUNCTION'
            WHEN 'a' THEN 'AGGREGATE'
            WHEN 'p' THEN 'PROCEDURE'
            WHEN 'w' THEN 'FUNCTION'  -- window function (rarely applicable)
        END,
        oid::regprocedure
      ),
      E'\n'
    )
  FROM 
    pg_proc
  WHERE
    pronamespace = '{{SCHEMA}}'::regnamespace  -- schema name here
    AND prokind = ANY ('{f,a,p,w}');      -- optionally filter kinds

  IF _sql IS NOT NULL THEN
    RAISE NOTICE '%', _sql; -- debug
    EXECUTE _sql;
  ELSE 
    RAISE NOTICE 'No fuctions found in schema %', quote_ident('{{SCHEMA}}');
  END IF;
END
$do$;

-- DROP EXISTING GREST ADDED TRIGGERS ON PUBLIC SCHEMA
DO
$$
DECLARE
  r record;
BEGIN
  FOR r IN (SELECT trigger_name, event_object_table FROM information_schema.triggers WHERE trigger_schema = 'public' AND action_statement LIKE '%{{SCHEMA}}.%')
  LOOP
    EXECUTE 'DROP TRIGGER IF EXISTS ' || quote_ident(r.trigger_name) || ' ON ' || quote_ident(r.event_object_table);
  END LOOP;
END
$$;

-- HELPER FUNCTIONS --
CREATE FUNCTION {{SCHEMA}}.get_query_pids_partial_match(_query text)
RETURNS TABLE (
  pid integer
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    pg_stat_activity.pid
  FROM
    pg_stat_activity
  WHERE
    query ILIKE '%' || _query || '%'
    AND query NOT ILIKE '%{{SCHEMA}}.get_query_pids_partial_match%'
    AND query NOT ILIKE '%{{SCHEMA}}.kill_queries_partial_match%'
    AND datname = (SELECT current_database());
END;
$$;

CREATE PROCEDURE {{SCHEMA}}.kill_queries_partial_match(_query text)
LANGUAGE plpgsql
AS $$
DECLARE
  _pids integer[];
  _pid integer;
BEGIN
  _pids := ARRAY (
    SELECT {{SCHEMA}}.get_query_pids_partial_match (_query)
  );
  FOREACH _pid IN ARRAY _pids
  LOOP
    RAISE NOTICE 'Cancelling PID: %', _pid;
    PERFORM PG_TERMINATE_BACKEND(_pid);
  END LOOP;
END;
$$;

CREATE FUNCTION {{SCHEMA}}.update_control_table(_key text, _last_value text, _artifacts text DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
AS
$$
  BEGIN
    INSERT INTO
      GREST.CONTROL_TABLE (key, last_value, artifacts)
    VALUES
      (_key, _last_value, _artifacts)
    ON CONFLICT (
      key
    ) DO UPDATE
      SET
        last_value = _last_value,
        artifacts = _artifacts;
  END;
$$;

-- Refresh asset token registry cache from github, to avoid stale deletes
DELETE FROM {{SCHEMA}}.control_table WHERE key = 'asset_registry_commit';
-- DATABASE INDEXES --
-- Empty
