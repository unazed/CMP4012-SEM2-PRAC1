-- Revert library:update_user_details from pg

BEGIN;

  DROP FUNCTION library_api.update_user_details;

COMMIT;
