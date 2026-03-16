-- Revert library:jwt from pg

BEGIN;

  DROP EXTENSION pgjwt CASCADE;
  DROP TABLE library_internal.app_config;

COMMIT;
