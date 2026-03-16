-- Deploy library:appschema to pg

BEGIN;

  CREATE EXTENSION plpgsql_check;

  CREATE SCHEMA library;
  CREATE SCHEMA library_api;
  CREATE SCHEMA library_internal;

COMMIT;
