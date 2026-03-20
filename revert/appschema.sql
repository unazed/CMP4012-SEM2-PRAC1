-- Revert library:appschema from pg

BEGIN;

  DROP TYPE library_internal.generic_error_code;
  DROP TYPE library_internal.auth_error_code;
  DROP TYPE library_internal.book_error_code;
  DROP TYPE library_internal.result_type;

  DROP SCHEMA library_api;
  DROP SCHEMA library_internal;
  DROP SCHEMA library;

  DROP EXTENSION pgtap;
  DROP EXTENSION plpgsql_check;

COMMIT;
