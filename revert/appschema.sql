-- Revert library:appschema from pg

BEGIN;

  DROP SCHEMA library;
  
COMMIT;
