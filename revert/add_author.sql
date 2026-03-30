-- Revert library:add_author from pg

BEGIN;

  DROP FUNCTION library_api.add_author;
  DROP FUNCTION library_internal.exists_author_by_id;

COMMIT;
