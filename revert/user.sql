-- Revert library:user from pg

BEGIN;

  DROP TABLE library.Users;
  DROP TYPE library.user_role;
  DROP TYPE library.user_status;

COMMIT;
