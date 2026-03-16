-- Deploy library:user to pg

BEGIN;

  CREATE TYPE library.user_role AS ENUM (
    'librarian',
    'member'
  );
  
  CREATE TYPE library.user_status AS ENUM (
    'active',
    'suspended',
    'deleted'
  );

  CREATE TABLE library.Users (
    user_id		INTEGER GENERATED ALWAYS AS IDENTITY,
    email 		TEXT UNIQUE NOT NULL,
    username		TEXT UNIQUE NOT NULL,
    user_role		library.user_role,
    user_status		library.user_status,
    password_hash 	TEXT NOT NULL,
    
    created_at		TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT PK_Users PRIMARY KEY (user_id),

    CONSTRAINT CHK_Users__email_validate
      CHECK (email LIKE '%@%')
  );

COMMIT;
