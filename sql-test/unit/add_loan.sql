BEGIN;

SELECT plan(27);

INSERT INTO library.Users (email, username, user_role, user_status, password_hash)
VALUES
  ('librarian@example.com', 'librarian', 'librarian', 'active', crypt('password', gen_salt('bf', 8))),
  ('member@example.com',    'member',    'member',    'active', crypt('password', gen_salt('bf', 8))),
  ('other@example.com',     'other',     'member',    'active', crypt('password', gen_salt('bf', 8)));

DO $$
DECLARE
  m_librarian_token TEXT;
  m_member_token    TEXT;
  m_other_token     TEXT;
  m_member_id       INTEGER;
BEGIN
  m_librarian_token := (library_api.login_user('librarian@example.com', 'password')).data->>'token';
  m_member_token    := (library_api.login_user('member@example.com',    'password')).data->>'token';
  m_other_token     := (library_api.login_user('other@example.com',     'password')).data->>'token';
  m_member_id       := (SELECT user_id FROM library.Users WHERE username = 'member');
  PERFORM set_config('test.librarian_token', m_librarian_token, TRUE);
  PERFORM set_config('test.member_token',    m_member_token,    TRUE);
  PERFORM set_config('test.other_token',     m_other_token,     TRUE);
  PERFORM set_config('test.member_id',       m_member_id::TEXT, TRUE);
END $$;

INSERT INTO library.Books (book_isbn, book_name, book_publish_date, book_has_digital)
VALUES
  ('ISBN-001', 'Physical Book',  '2020-01-01', FALSE),
  ('ISBN-002', 'Digital Book',   '2020-01-01', TRUE),
  ('ISBN-003', 'Both Book',      '2020-01-01', TRUE);

INSERT INTO library.PhysicalBooks (book_isbn, book_quantity)
VALUES ('ISBN-001', 3), ('ISBN-003', 2);

INSERT INTO library.DigitalBooks (book_isbn)
VALUES ('ISBN-002'), ('ISBN-003');

-- ==================
-- get_qty_physical_available
-- ==================

-- 1. Returns full quantity when no loans
SELECT is(
  ((library_api.get_qty_physical_available(
    current_setting('test.librarian_token'),
    'ISBN-001', NOW(), NOW() + INTERVAL '7 days')).data->>'qty')::INTEGER,
  3,
  'get_qty_physical_available: returns full quantity when no loans'
);

-- 2. Returns error for unknown ISBN
SELECT is(
  (library_api.get_qty_physical_available(
    current_setting('test.librarian_token'),
    'NO-SUCH-ISBN', NOW(), NOW() + INTERVAL '7 days')).error_code::TEXT,
  'book_not_found',
  'get_qty_physical_available: returns book_not_found for unknown ISBN'
);

-- 3. Requires valid session
SELECT ok(
  NOT (library_api.get_qty_physical_available(
    'invalid-token',
    'ISBN-001', NOW(), NOW() + INTERVAL '7 days')).success,
  'get_qty_physical_available: requires valid session'
);

-- ==================
-- create_physical_loan
-- ==================

-- 4. Librarian can create a loan
SELECT ok(
  (library_api.create_physical_loan(
    current_setting('test.librarian_token'),
    'ISBN-001',
    current_setting('test.member_id')::INTEGER,
    NOW(), NOW() + INTERVAL '7 days', 1)).success,
  'create_physical_loan: librarian can create a loan'
);

-- 5. Returns loan_id
SELECT ok(
  (library_api.create_physical_loan(
    current_setting('test.librarian_token'),
    'ISBN-001',
    current_setting('test.member_id')::INTEGER,
    NOW() + INTERVAL '8 days', NOW() + INTERVAL '14 days', 1)).data IS NOT NULL,
  'create_physical_loan: returns loan_id'
);

-- 6. Member cannot create a loan
SELECT ok(
  NOT (library_api.create_physical_loan(
    current_setting('test.member_token'),
    'ISBN-001',
    current_setting('test.member_id')::INTEGER,
    NOW(), NOW() + INTERVAL '7 days', 1)).success,
  'create_physical_loan: member cannot create a loan'
);

-- 7. Returns user_not_found for unknown user
SELECT is(
  (library_api.create_physical_loan(
    current_setting('test.librarian_token'),
    'ISBN-001', 99999,
    NOW(), NOW() + INTERVAL '7 days', 1)).error_code::TEXT,
  'user_not_found',
  'create_physical_loan: returns user_not_found for unknown user'
);

-- 8. Returns invalid_params for quantity <= 0
SELECT is(
  (library_api.create_physical_loan(
    current_setting('test.librarian_token'),
    'ISBN-001',
    current_setting('test.member_id')::INTEGER,
    NOW(), NOW() + INTERVAL '7 days', 0)).error_code::TEXT,
  'invalid_params',
  'create_physical_loan: returns invalid_params for quantity 0'
);

-- 9. Cannot loan more than available quantity
SELECT is(
  (library_api.create_physical_loan(
    current_setting('test.librarian_token'),
    'ISBN-001',
    current_setting('test.member_id')::INTEGER,
    NOW(), NOW() + INTERVAL '7 days', 99)).error_code::TEXT,
  'insufficient_quantity',
  'create_physical_loan: returns insufficient_quantity when not enough stock'
);

-- 10. Quantity available reduced after loan (was 3, loaned 1 in test 4)
SELECT is(
  ((library_api.get_qty_physical_available(
    current_setting('test.librarian_token'),
    'ISBN-001', NOW(), NOW() + INTERVAL '7 days')).data->>'qty')::INTEGER,
  2,
  'create_physical_loan: available quantity reduced after loan'
);

-- ==================
-- get_physical_loans
-- ==================

-- 11. Librarian can see all loans for a book
SELECT ok(
  jsonb_array_length(
    (library_api.get_physical_loans(
      current_setting('test.librarian_token'), 'ISBN-001')).data) >= 1,
  'get_physical_loans: librarian can see all loans'
);

-- 12. Member can only see their own loans
SELECT ok(
  (library_api.get_physical_loans(
    current_setting('test.other_token'), 'ISBN-001')).data = '[]'::JSONB,
  'get_physical_loans: member cannot see other users loans'
);

-- 13. Requires valid session
SELECT ok(
  NOT (library_api.get_physical_loans('invalid-token', 'ISBN-001')).success,
  'get_physical_loans: requires valid session'
);

-- ==================
-- get_physical_loan_by_id
-- ==================

-- Store loan_id from test 4 for subsequent tests
DO $$
DECLARE
  m_loan_id INTEGER;
BEGIN
  SELECT loan_id INTO m_loan_id
  FROM library.PhysicalBookLoans
  WHERE user_id = current_setting('test.member_id')::INTEGER
  ORDER BY loan_id
  LIMIT 1;
  PERFORM set_config('test.loan_id', m_loan_id::TEXT, TRUE);
END $$;

-- 14. Librarian can get any loan by id
SELECT ok(
  (library_api.get_physical_loan_by_id(
    current_setting('test.librarian_token'),
    current_setting('test.loan_id')::INTEGER)).success,
  'get_physical_loan_by_id: librarian can get any loan'
);

-- 15. Member can get their own loan
SELECT ok(
  (library_api.get_physical_loan_by_id(
    current_setting('test.member_token'),
    current_setting('test.loan_id')::INTEGER)).success,
  'get_physical_loan_by_id: member can get their own loan'
);

-- 16. Member cannot get another user's loan
SELECT ok(
  NOT (library_api.get_physical_loan_by_id(
    current_setting('test.other_token'),
    current_setting('test.loan_id')::INTEGER)).success,
  'get_physical_loan_by_id: member cannot get another users loan'
);

-- ==================
-- update_physical_loan
-- ==================

-- 17. Librarian can update a loan
SELECT ok(
  (library_api.update_physical_loan(
    current_setting('test.librarian_token'),
    current_setting('test.loan_id')::INTEGER,
    NULL, NULL, TRUE)).success,
  'update_physical_loan: librarian can mark loan as returned'
);

-- 18. Loan is actually marked returned
SELECT ok(
  (SELECT loan_returned FROM library.PhysicalBookLoans
   WHERE loan_id = current_setting('test.loan_id')::INTEGER),
  'update_physical_loan: loan_returned is TRUE after update'
);

-- 19. Member can update their own loan
SELECT ok(
  (library_api.update_physical_loan(
    current_setting('test.member_token'),
    current_setting('test.loan_id')::INTEGER,
    NULL, NULL, FALSE)).success,
  'update_physical_loan: member can update their own loan'
);

-- 20. Member cannot update another user's loan
-- Create a loan for member, then try to update as other
DO $$
DECLARE
  m_other_loan_id INTEGER;
BEGIN
  INSERT INTO library.PhysicalBookLoans
    (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
  VALUES (
    'ISBN-001',
    (SELECT user_id FROM library.Users WHERE username = 'other'),
    NOW(), NOW() + INTERVAL '7 days', 1, FALSE)
  RETURNING loan_id INTO m_other_loan_id;
  PERFORM set_config('test.other_loan_id', m_other_loan_id::TEXT, TRUE);
END $$;

SELECT is(
  (library_api.update_physical_loan(
    current_setting('test.member_token'),
    current_setting('test.other_loan_id')::INTEGER,
    NULL, NULL, TRUE)).error_code::TEXT,
  'insufficient_permissions',
  'update_physical_loan: member cannot update another users loan'
);

-- 21. Returns loan_not_found for unknown loan
SELECT is(
  (library_api.update_physical_loan(
    current_setting('test.librarian_token'),
    99999, NULL, NULL, TRUE)).error_code::TEXT,
  'loan_not_found',
  'update_physical_loan: returns loan_not_found for unknown loan_id'
);

-- ==================
-- get_digital_loans
-- ==================

-- Setup: insert a digital loan
INSERT INTO library.DigitalBookLoans (book_isbn, user_id, loan_date, loan_expiry)
VALUES ('ISBN-002',
  current_setting('test.member_id')::INTEGER,
  CURRENT_DATE, CURRENT_DATE + 7);

-- 22. Librarian can see all digital loans
SELECT ok(
  jsonb_array_length(
    (library_api.get_digital_loans(
      current_setting('test.librarian_token'), 'ISBN-002')).data) >= 1,
  'get_digital_loans: librarian can see all loans'
);

-- 23. Member can only see their own digital loans
SELECT ok(
  (library_api.get_digital_loans(
    current_setting('test.other_token'), 'ISBN-002')).data = '[]'::JSONB,
  'get_digital_loans: member cannot see other users loans'
);

-- 24. Requires valid session
SELECT ok(
  NOT (library_api.get_digital_loans('invalid-token', 'ISBN-002')).success,
  'get_digital_loans: requires valid session'
);

-- ==================
-- user_has_physical_loan
-- ==================

-- 25. Returns TRUE for user with active loan
SELECT ok(
  library_internal.user_has_physical_loan(
    current_setting('test.member_id')::INTEGER, 'ISBN-001'),
  'user_has_physical_loan: TRUE for user with any loan'
);

-- 26. Returns FALSE for user with no loans for that book
SELECT ok(
  NOT library_internal.user_has_physical_loan(
    current_setting('test.member_id')::INTEGER, 'ISBN-003'),
  'user_has_physical_loan: FALSE for user with no loans for book'
);

-- 27. Returns FALSE for unknown user
SELECT ok(
  NOT library_internal.user_has_physical_loan(99999, 'ISBN-001'),
  'user_has_physical_loan: FALSE for unknown user'
);

SELECT * FROM finish();
ROLLBACK;