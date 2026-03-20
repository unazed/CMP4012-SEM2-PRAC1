-- Revert library:token_decode from pg

BEGIN;

  DROP FUNCTION library_internal.decode_token;
  DROP FUNCTION library_internal.is_valid_session;
  DROP FUNCTION library_internal.is_librarian;
  DROP FUNCTION library_internal.exists_user;
  
COMMIT;
