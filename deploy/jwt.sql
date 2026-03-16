-- Deploy library:jwt to pg

BEGIN;

  CREATE EXTENSION pgjwt CASCADE;

  CREATE TABLE library_internal.app_config (
    key        TEXT PRIMARY KEY,
    value      TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
  );

  INSERT INTO library_internal.app_config (key, value)
  VALUES ('jwt_secret', :'JWT_SECRET')
  ON CONFLICT (key) DO UPDATE SET
    value      = EXCLUDED.value,
    created_at = NOW();

COMMIT;
