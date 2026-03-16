-- Revert library:user from pg

BEGIN;

  DROP TABLE library.Users;
  DROP TABLE library.UserRoles;
  DROP TABLE library.UserStatuses;

COMMIT;
