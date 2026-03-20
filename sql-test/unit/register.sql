BEGIN;

SELECT plan(7);

INSERT INTO library.Users (email, username, user_role, user_status, password_hash)
VALUES ('existing@example.com', 'existinguser', 'member', 'active', 'hash');

-- 1. Successful registration returns success
SELECT ok(
  (library_api.register_user('new@example.com', 'newuser', 'password123')).success,
  'register_user: returns success for valid new user'
);

-- 2. Returns a token
SELECT ok(
  (library_api.register_user('another@example.com', 'anotheruser', 'password123')).data->>'token' IS NOT NULL,
  'register_user: returns a token on success'
);

-- 3. Returns correct email in response
SELECT is(
  (library_api.register_user('cased@EXAMPLE.COM', 'caseduser', 'password123')).data->>'email',
  'cased@example.com',
  'register_user: email is normalized in response'
);

-- 4. Plus-addressing is normalized
SELECT is(
  (library_api.register_user('user+tag@example.com', 'plususer', 'password123')).data->>'email',
  'user@example.com',
  'register_user: plus-address is stripped in response'
);

-- 5. Duplicate email returns error
SELECT is(
  (library_api.register_user('existing@example.com', 'newusername', 'password123')).error_code::TEXT,
  'user_exists',
  'register_user: duplicate email returns user_exists error'
);

-- 6. Duplicate email via normalization returns error
SELECT is(
  (library_api.register_user('EXISTING@example.com', 'anotherusername', 'password123')).error_code::TEXT,
  'user_exists',
  'register_user: normalized duplicate email returns user_exists error'
);

-- 7. Duplicate username returns error
SELECT is(
  (library_api.register_user('different@example.com', 'existinguser', 'password123')).error_code::TEXT,
  'user_exists',
  'register_user: duplicate username returns user_exists error'
);

SELECT * FROM finish();
ROLLBACK;