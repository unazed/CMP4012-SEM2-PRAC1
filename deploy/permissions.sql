-- Deploy library:permissions to pg

BEGIN;

  CREATE ROLE app_user LOGIN PASSWORD 'app_user';

  REVOKE ALL ON SCHEMA library FROM app_user;
  GRANT USAGE ON SCHEMA library_api TO app_user;
  GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA library_api TO app_user;
  GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA library_api TO app_user;

COMMIT;
