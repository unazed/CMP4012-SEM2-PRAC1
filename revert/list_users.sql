-- Revert library:list_users from pg

BEGIN;

  DROP FUNCTION library_api.get_members;

COMMIT;
