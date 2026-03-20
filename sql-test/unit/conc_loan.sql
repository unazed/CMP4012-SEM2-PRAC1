BEGIN;

SELECT plan(12);

INSERT INTO library.Users (email, username, user_role, user_status, password_hash)
VALUES ('librarian@example.com', 'librarian', 'librarian', 'active', crypt('password', gen_salt('bf', 8)));

INSERT INTO library.Books (book_isbn, book_name, book_publish_date, book_has_digital)
VALUES ('ISBN-CON', 'Concurrency Test Book', '2020-01-01', FALSE);

INSERT INTO library.PhysicalBooks (book_isbn, book_quantity)
VALUES ('ISBN-CON', 10);

-- We test get_max_concurrent_physical_loans indirectly via
-- get_qty_physical_available, since that subtracts concurrent loans
-- from total quantity. With quantity=10, available = 10 - max_concurrent.

DO $$
DECLARE
  m_librarian_token TEXT;
  m_member_id       INTEGER;
BEGIN
  m_librarian_token := (library_api.login_user('librarian@example.com', 'password')).data->>'token';
  PERFORM set_config('test.librarian_token', m_librarian_token, TRUE);
END $$;

-- ==================
-- Baseline
-- ==================

-- 1. No loans: full quantity available
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-01-01'::TIMESTAMPTZ,
    '2024-01-31'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  10,
  'concurrent: no loans means full quantity available'
);

-- ==================
-- Non-overlapping loans
-- Two loans that don't overlap should never stack
-- [--A--]       [--B--]
-- ==================

INSERT INTO library.PhysicalBookLoans
  (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
VALUES
  ('ISBN-CON',
    (SELECT user_id FROM library.Users WHERE username = 'librarian'),
    '2024-01-01'::TIMESTAMPTZ, '2024-01-10'::TIMESTAMPTZ, 3, FALSE),
  ('ISBN-CON',
    (SELECT user_id FROM library.Users WHERE username = 'librarian'),
    '2024-01-20'::TIMESTAMPTZ, '2024-01-31'::TIMESTAMPTZ, 4, FALSE);

-- 2. Window covers only loan A: available = 10 - 3
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-01-01'::TIMESTAMPTZ,
    '2024-01-10'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  7,
  'concurrent: window covering only loan A gives correct availability'
);

-- 3. Window covers only loan B: available = 10 - 4
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-01-20'::TIMESTAMPTZ,
    '2024-01-31'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  6,
  'concurrent: window covering only loan B gives correct availability'
);

-- 4. Window covers both but they don't overlap: peak is max(3,4) = 4, available = 6
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-01-01'::TIMESTAMPTZ,
    '2024-01-31'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  6,
  'concurrent: non-overlapping loans do not stack, peak is max of individuals'
);

-- ==================
-- Overlapping loans
-- [----A----]
--       [----B----]
-- Peak is during overlap: qty_A + qty_B
-- ==================

INSERT INTO library.PhysicalBookLoans
  (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
VALUES
  ('ISBN-CON',
    (SELECT user_id FROM library.Users WHERE username = 'librarian'),
    '2024-02-01'::TIMESTAMPTZ, '2024-02-15'::TIMESTAMPTZ, 2, FALSE),
  ('ISBN-CON',
    (SELECT user_id FROM library.Users WHERE username = 'librarian'),
    '2024-02-10'::TIMESTAMPTZ, '2024-02-28'::TIMESTAMPTZ, 3, FALSE);

-- 5. Window before overlap: only loan A active, available = 10 - 2
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-02-01'::TIMESTAMPTZ,
    '2024-02-09'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  8,
  'concurrent: window before overlap sees only first loan'
);

-- 6. Window during overlap: both active, peak = 2+3 = 5, available = 5
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-02-10'::TIMESTAMPTZ,
    '2024-02-15'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  5,
  'concurrent: window during overlap stacks both loans'
);

-- 7. Window after overlap: only loan B active, available = 10 - 3
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-02-16'::TIMESTAMPTZ,
    '2024-02-28'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  7,
  'concurrent: window after overlap sees only second loan'
);

-- 8. Window spanning entire overlapping period: peak = 5, available = 5
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-02-01'::TIMESTAMPTZ,
    '2024-02-28'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  5,
  'concurrent: window spanning full overlap period uses peak concurrency'
);

-- ==================
-- Loan spanning the entire window (case 4 from earlier discussion)
-- [----------window----------]
--    [------loan spans-------]
-- ==================

INSERT INTO library.PhysicalBookLoans
  (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
VALUES
  ('ISBN-CON',
    (SELECT user_id FROM library.Users WHERE username = 'librarian'),
    '2024-03-05'::TIMESTAMPTZ, '2024-03-25'::TIMESTAMPTZ, 5, FALSE);

-- 9. Loan entirely contains the window: available = 10 - 5
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-03-10'::TIMESTAMPTZ,
    '2024-03-20'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  5,
  'concurrent: loan spanning entire window is counted correctly'
);

-- ==================
-- Returned loans are excluded
-- ==================

INSERT INTO library.PhysicalBookLoans
  (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
VALUES
  ('ISBN-CON',
    (SELECT user_id FROM library.Users WHERE username = 'librarian'),
    '2024-04-01'::TIMESTAMPTZ, '2024-04-15'::TIMESTAMPTZ, 6, TRUE); -- returned!

-- 10. Returned loan does not affect availability
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-04-01'::TIMESTAMPTZ,
    '2024-04-15'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  10,
  'concurrent: returned loans are excluded from concurrency count'
);

-- ==================
-- Open-ended loan (no return date)
-- ==================

INSERT INTO library.PhysicalBookLoans
  (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
VALUES
  ('ISBN-CON',
    (SELECT user_id FROM library.Users WHERE username = 'librarian'),
    '2024-05-01'::TIMESTAMPTZ, NULL, 2, FALSE);

-- 11. Open-ended loan is active in a future window
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-05-10'::TIMESTAMPTZ,
    '2024-05-20'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  8,
  'concurrent: open-ended loan counts as active in future window'
);

-- 12. Window before open-ended loan start: not counted
SELECT is(
  ((library_internal.get_qty_physical_available(
    'ISBN-CON',
    '2024-04-20'::TIMESTAMPTZ,
    '2024-04-30'::TIMESTAMPTZ)).data->>'qty')::INTEGER,
  10,
  'concurrent: open-ended loan not counted before its start date'
);

SELECT * FROM finish();
ROLLBACK;