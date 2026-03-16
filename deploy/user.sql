-- Deploy library:user to pg

BEGIN;

  CREATE TABLE library.UserStatuses (
    user_status	TEXT UNIQUE NOT NULL
  );

  CREATE TABLE library.UserRoles (
    user_role	TEXT UNIQUE NOT NULL
  );

  CREATE TABLE library.Users (
    user_id		INTEGER GENERATED ALWAYS AS IDENTITY,
    email 		TEXT UNIQUE NOT NULL,
    username		TEXT UNIQUE NOT NULL,
    user_role		TEXT,
    user_status		TEXT,
    password_hash 	TEXT NOT NULL,

    CONSTRAINT PK_Users PRIMARY KEY (user_id),

    CONSTRAINT FK_Users__user_role
      FOREIGN KEY (user_role)
      REFERENCES library.UserRoles(user_role)
      ON DELETE SET NULL,
    CONSTRAINT FK_Users__user_status
      FOREIGN KEY (user_status)
      REFERENCES library.UserStatuses(user_status)
      ON DELETE SET NULL,

    CONSTRAINT CHK_Users__email_validate
      CHECK (email LIKE '%@%')
  );

COMMIT;
