-- Revert library:get_authors from pg

BEGIN;

  DROP FUNCTION library_api.get_authors;

COMMIT;
