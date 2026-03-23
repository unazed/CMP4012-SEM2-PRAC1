-- Revert library:permissions from pg

BEGIN;

  REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA library_api FROM app_user;
  REVOKE EXECUTE ON ALL PROCEDURES IN SCHEMA library_api FROM app_user;
  REVOKE USAGE ON SCHEMA library_api FROM app_user;
  DROP ROLE app_user;

COMMIT;
