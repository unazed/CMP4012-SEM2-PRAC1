BEGIN;

SELECT plan(14);

INSERT INTO library.Users (email, username, user_role, user_status, password_hash)
VALUES
  ('librarian@example.com', 'librarian', 'librarian', 'active', crypt('password', gen_salt('bf', 8))),
  ('member@example.com',    'member',    'member',    'active', crypt('password', gen_salt('bf', 8)));

DO $$
DECLARE
  m_librarian_token TEXT;
  m_member_token    TEXT;
BEGIN
  m_librarian_token := (library_api.login_user('librarian@example.com', 'password')).data->>'token';
  m_member_token    := (library_api.login_user('member@example.com',    'password')).data->>'token';
  PERFORM set_config('test.librarian_token', m_librarian_token, TRUE);
  PERFORM set_config('test.member_token',    m_member_token,    TRUE);
END $$;

INSERT INTO library.Books (book_isbn, book_name, book_publish_date, book_has_digital)
VALUES ('ISBN-001', 'Test Book', '2020-01-01', TRUE);

INSERT INTO library.PhysicalBooks (book_isbn, book_quantity)
VALUES ('ISBN-001', 5);

INSERT INTO library.DigitalBooks (book_isbn)
VALUES ('ISBN-001');

DO $$
DECLARE
  m_user_id               INTEGER;
  m_active_physical_id    INTEGER;
  m_inactive_physical_id  INTEGER;
  m_active_digital_id     INTEGER;
  m_inactive_digital_id   INTEGER;
BEGIN
  m_user_id := (SELECT user_id FROM library.Users WHERE username = 'member');

  INSERT INTO library.PhysicalBookLoans
    (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
  VALUES ('ISBN-001', m_user_id, NOW() - INTERVAL '1 day', NOW() + INTERVAL '7 days', 1, FALSE)
  RETURNING loan_id INTO m_active_physical_id;

  INSERT INTO library.PhysicalBookLoans
    (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
  VALUES ('ISBN-001', m_user_id, NOW() - INTERVAL '10 days', NOW() - INTERVAL '3 days', 1, TRUE)
  RETURNING loan_id INTO m_inactive_physical_id;

  INSERT INTO library.DigitalBookLoans
    (book_isbn, user_id, loan_date, loan_expiry)
  VALUES ('ISBN-001', m_user_id, CURRENT_DATE - 1, CURRENT_DATE + 7)
  RETURNING loan_id INTO m_active_digital_id;

  INSERT INTO library.DigitalBookLoans
    (book_isbn, user_id, loan_date, loan_expiry)
  VALUES ('ISBN-001', m_user_id, CURRENT_DATE - 10, CURRENT_DATE - 1)
  RETURNING loan_id INTO m_inactive_digital_id;

  PERFORM set_config('test.active_physical_id',   m_active_physical_id::TEXT,   TRUE);
  PERFORM set_config('test.inactive_physical_id', m_inactive_physical_id::TEXT, TRUE);
  PERFORM set_config('test.active_digital_id',    m_active_digital_id::TEXT,    TRUE);
  PERFORM set_config('test.inactive_digital_id',  m_inactive_digital_id::TEXT,  TRUE);
END $$;

-- ==================
-- remove_physical_loan
-- ==================

-- 1. Cannot remove an active physical loan
SELECT is(
  (library_api.remove_physical_loan(
    current_setting('test.librarian_token'),
    current_setting('test.active_physical_id')::INTEGER)).error_code::TEXT,
  'loan_active',
  'remove_physical_loan: cannot remove active loan'
);

-- 2. Active loan still exists after failed removal
SELECT ok(
  EXISTS (SELECT FROM library.PhysicalBookLoans
    WHERE loan_id = current_setting('test.active_physical_id')::INTEGER),
  'remove_physical_loan: active loan still exists after failed removal'
);

-- 3. Librarian can remove an inactive physical loan
SELECT ok(
  (library_api.remove_physical_loan(
    current_setting('test.librarian_token'),
    current_setting('test.inactive_physical_id')::INTEGER)).success,
  'remove_physical_loan: librarian can remove inactive loan'
);

-- 4. Loan is actually gone after removal
SELECT ok(
  NOT EXISTS (SELECT FROM library.PhysicalBookLoans
    WHERE loan_id = current_setting('test.inactive_physical_id')::INTEGER),
  'remove_physical_loan: loan no longer exists after removal'
);

-- 5. Member cannot remove a physical loan
SELECT ok(
  NOT (library_api.remove_physical_loan(
    current_setting('test.member_token'),
    current_setting('test.active_physical_id')::INTEGER)).success,
  'remove_physical_loan: member cannot remove a loan'
);

-- 6. Invalid token is rejected
SELECT ok(
  NOT (library_api.remove_physical_loan(
    'invalid-token',
    current_setting('test.active_physical_id')::INTEGER)).success,
  'remove_physical_loan: invalid token is rejected'
);

-- 7. Returns loan_not_found for unknown loan_id (assuming your function handles this)
SELECT is(
  (library_api.remove_physical_loan(
    current_setting('test.librarian_token'),
    99999)).error_code::TEXT,
  'loan_not_found',
  'remove_physical_loan: returns loan_not_found for unknown loan_id'
);

-- ==================
-- remove_digital_loan
-- ==================

-- 8. Cannot remove an active digital loan
SELECT is(
  (library_api.remove_digital_loan(
    current_setting('test.librarian_token'),
    current_setting('test.active_digital_id')::INTEGER)).error_code::TEXT,
  'loan_active',
  'remove_digital_loan: cannot remove active loan'
);

-- 9. Active loan still exists after failed removal
SELECT ok(
  EXISTS (SELECT FROM library.DigitalBookLoans
    WHERE loan_id = current_setting('test.active_digital_id')::INTEGER),
  'remove_digital_loan: active loan still exists after failed removal'
);

-- 10. Librarian can remove an inactive digital loan
SELECT ok(
  (library_api.remove_digital_loan(
    current_setting('test.librarian_token'),
    current_setting('test.inactive_digital_id')::INTEGER)).success,
  'remove_digital_loan: librarian can remove inactive loan'
);

-- 11. Loan is actually gone after removal
SELECT ok(
  NOT EXISTS (SELECT FROM library.DigitalBookLoans
    WHERE loan_id = current_setting('test.inactive_digital_id')::INTEGER),
  'remove_digital_loan: loan no longer exists after removal'
);

-- 12. Member cannot remove a digital loan
SELECT ok(
  NOT (library_api.remove_digital_loan(
    current_setting('test.member_token'),
    current_setting('test.active_digital_id')::INTEGER)).success,
  'remove_digital_loan: member cannot remove a loan'
);

-- 13. Invalid token is rejected
SELECT ok(
  NOT (library_api.remove_digital_loan(
    'invalid-token',
    current_setting('test.active_digital_id')::INTEGER)).success,
  'remove_digital_loan: invalid token is rejected'
);

-- 14. Returns loan_not_found for unknown loan_id
SELECT is(
  (library_api.remove_digital_loan(
    current_setting('test.librarian_token'),
    99999)).error_code::TEXT,
  'loan_not_found',
  'remove_digital_loan: returns loan_not_found for unknown loan_id'
);

SELECT * FROM finish();
ROLLBACK;