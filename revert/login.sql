-- Revert library:login from pg

BEGIN;

  DROP FUNCTION library_api.login_user;

COMMIT;
