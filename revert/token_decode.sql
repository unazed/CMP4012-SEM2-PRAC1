-- Revert library:token_decode from pg

BEGIN;

  DROP FUNCTION library_internal.decode_token;

COMMIT;
