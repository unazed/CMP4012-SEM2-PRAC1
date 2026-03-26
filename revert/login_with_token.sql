-- Revert library:login_with_token from pg

BEGIN;

  DROP FUNCTION library_api.get_token_information;

COMMIT;
