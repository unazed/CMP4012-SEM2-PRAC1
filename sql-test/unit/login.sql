BEGIN;

SELECT plan(8);

INSERT INTO library.Users (email, username, user_role, user_status, password_hash)
VALUES
  ('active@example.com',    'activeuser',    'member', 'active',    crypt('correct-password', gen_salt('bf', 8))),
  ('suspended@example.com', 'suspendeduser', 'member', 'suspended', crypt('correct-password', gen_salt('bf', 8))),
  ('deleted@example.com',   'deleteduser',   'member', 'deleted',   crypt('correct-password', gen_salt('bf', 8)));

-- 1. Successful login returns success
SELECT ok(
  (library_api.login_user('active@example.com', 'correct-password')).success,
  'login_user: returns success for valid credentials'
);

-- 2. Returns a token on success
SELECT ok(
  (library_api.login_user('active@example.com', 'correct-password')).data->>'token' IS NOT NULL,
  'login_user: returns a token on success'
);

-- 3. Returns correct email and username
SELECT is(
  (library_api.login_user('active@example.com', 'correct-password')).data->>'email',
  'active@example.com',
  'login_user: returns correct email in response'
);

-- 4. Email is normalized on login
SELECT ok(
  (library_api.login_user('ACTIVE@example.com', 'correct-password')).success,
  'login_user: normalizes email before lookup'
);

-- 5. Wrong password returns login_invalid
SELECT is(
  (library_api.login_user('active@example.com', 'wrong-password')).error_code::TEXT,
  'login_invalid',
  'login_user: wrong password returns login_invalid'
);

-- 6. Unknown email returns login_invalid
SELECT is(
  (library_api.login_user('nobody@example.com', 'correct-password')).error_code::TEXT,
  'login_invalid',
  'login_user: unknown email returns login_invalid'
);

-- 7. Suspended account returns account_disabled
SELECT is(
  (library_api.login_user('suspended@example.com', 'correct-password')).error_code::TEXT,
  'account_disabled',
  'login_user: suspended account returns account_disabled'
);

-- 8. Deleted account returns account_disabled
SELECT is(
  (library_api.login_user('deleted@example.com', 'correct-password')).error_code::TEXT,
  'account_disabled',
  'login_user: deleted account returns account_disabled'
);

SELECT * FROM finish();
ROLLBACK;