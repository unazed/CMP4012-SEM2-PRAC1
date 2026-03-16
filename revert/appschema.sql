-- Revert library:appschema from pg

BEGIN;

  DROP SCHEMA library_api;
  DROP SCHEMA library_internal;
  DROP SCHEMA library;

  DROP EXTENSION plpgsql_check;

COMMIT;
