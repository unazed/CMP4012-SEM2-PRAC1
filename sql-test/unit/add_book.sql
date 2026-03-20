BEGIN;

SELECT plan(36);

INSERT INTO library.Users (email, username, user_role, user_status, password_hash)
VALUES
  ('librarian@example.com', 'librarian', 'librarian', 'active', crypt('password', gen_salt('bf', 8))),
  ('member@example.com',    'member',    'member',    'active', crypt('password', gen_salt('bf', 8)));

-- Get tokens for use in tests
DO $$
DECLARE
  m_librarian_token TEXT;
  m_member_token TEXT;
BEGIN
  m_librarian_token := (library_api.login_user('librarian@example.com', 'password')).data->>'token';
  m_member_token    := (library_api.login_user('member@example.com',    'password')).data->>'token';
  PERFORM set_config('test.librarian_token', m_librarian_token, TRUE);
  PERFORM set_config('test.member_token',    m_member_token,    TRUE);
END $$;

-- ==================
-- add_book
-- ==================

-- 1. Librarian can add a book
SELECT ok(
  (library_api.add_book(
    current_setting('test.librarian_token'),
    'ISBN-001', 'Test Book', '2020-01-01', 5, FALSE)).success,
  'add_book: librarian can add a physical book'
);

-- 2. Returns isbn in response
SELECT is(
  (library_api.add_book(
    current_setting('test.librarian_token'),
    'ISBN-002', 'Digital Book', '2020-01-01', 0, TRUE)).data->>'isbn',
  'ISBN-002',
  'add_book: returns isbn in response'
);

-- 3. Member cannot add a book
SELECT ok(
  NOT (library_api.add_book(
    current_setting('test.member_token'),
    'ISBN-003', 'Unauthorized Book', '2020-01-01', 5, FALSE)).success,
  'add_book: member cannot add a book'
);

-- 4. Invalid token is rejected
SELECT ok(
  NOT (library_api.add_book(
    'invalid-token',
    'ISBN-004', 'Some Book', '2020-01-01', 5, FALSE)).success,
  'add_book: invalid token is rejected'
);

-- 5. Can add book with both physical and digital
SELECT ok(
  (library_api.add_book(
    current_setting('test.librarian_token'),
    'ISBN-005', 'Both Book', '2020-01-01', 3, TRUE)).success,
  'add_book: can add book with both physical and digital'
);

-- 6. Duplicate ISBN returns error
SELECT ok(
  NOT (library_api.add_book(
    current_setting('test.librarian_token'),
    'ISBN-001', 'Duplicate Book', '2020-01-01', 1, FALSE)).success,
  'add_book: duplicate ISBN returns error'
);

-- ==================
-- find_book_by_isbn
-- ==================

-- 7. Returns book data for known ISBN
SELECT ok(
  (library_api.find_book_by_isbn('ISBN-001')).success,
  'find_book_by_isbn: returns success for known ISBN'
);

-- 8. Returns correct book name
SELECT is(
  (library_api.find_book_by_isbn('ISBN-001')).data->>'book_name',
  'Test Book',
  'find_book_by_isbn: returns correct book name'
);

-- 9. Returns error for unknown ISBN
SELECT is(
  (library_api.find_book_by_isbn('NO-SUCH-ISBN')).error_code::TEXT,
  'book_not_found',
  'find_book_by_isbn: returns book_not_found for unknown ISBN'
);

-- ==================
-- set_digital_book_url
-- ==================

-- 10. Librarian can set URL on digital book
SELECT ok(
  (library_api.set_digital_book_url(
    current_setting('test.librarian_token'),
    'ISBN-002', 'https://example.com/book')).success,
  'set_digital_book_url: librarian can set URL on digital book'
);

-- 11. Returns isbn and url in response
SELECT is(
  (library_api.set_digital_book_url(
    current_setting('test.librarian_token'),
    'ISBN-002', 'https://example.com/book')).data->>'url',
  'https://example.com/book',
  'set_digital_book_url: returns url in response'
);

-- 12. Cannot set URL on non-digital book
SELECT is(
  (library_api.set_digital_book_url(
    current_setting('test.librarian_token'),
    'ISBN-001', 'https://example.com/book')).error_code::TEXT,
  'no_digital_entry',
  'set_digital_book_url: returns no_digital_entry for non-digital book'
);

-- 13. Returns book_not_found for unknown ISBN
SELECT is(
  (library_api.set_digital_book_url(
    current_setting('test.librarian_token'),
    'NO-SUCH-ISBN', 'https://example.com/book')).error_code::TEXT,
  'book_not_found',
  'set_digital_book_url: returns book_not_found for unknown ISBN'
);

-- 14. Member cannot set URL
SELECT ok(
  NOT (library_api.set_digital_book_url(
    current_setting('test.member_token'),
    'ISBN-002', 'https://example.com/book')).success,
  'set_digital_book_url: member cannot set URL'
);

-- ==================
-- update_book
-- ==================

-- 15. Librarian can update a book
SELECT ok(
  (library_api.update_book(
    current_setting('test.librarian_token'),
    'ISBN-001', 'Updated Title', '2021-01-01', 5, FALSE)).success,
  'update_book: librarian can update a book'
);

-- 16. Member cannot update a book
SELECT ok(
  NOT (library_api.update_book(
    current_setting('test.member_token'),
    'ISBN-001', 'Updated Title', '2021-01-01', 5, FALSE)).success,
  'update_book: member cannot update a book'
);

-- 17. Returns book_not_found for unknown ISBN
SELECT is(
  (library_api.update_book(
    current_setting('test.librarian_token'),
    'NO-SUCH-ISBN', 'Title', '2021-01-01', 1, FALSE)).error_code::TEXT,
  'book_not_found',
  'update_book: returns book_not_found for unknown ISBN'
);

-- 18. Can add physical stock to a previously digital-only book
SELECT ok(
  (library_api.update_book(
    current_setting('test.librarian_token'),
    'ISBN-002', 'Digital Book', '2020-01-01', 3, TRUE)).success,
  'update_book: can add physical stock to digital-only book'
);

-- 18b. Physical book record exists after adding stock
SELECT ok(
  library_internal.is_physical_book('ISBN-002'),
  'update_book: is_physical_book TRUE after adding stock'
);

-- 18c. Can reduce physical stock back to 0 (removes physical record)
SELECT ok(
  (library_api.update_book(
    current_setting('test.librarian_token'),
    'ISBN-002', 'Digital Book', '2020-01-01', 0, TRUE)).success,
  'update_book: can reduce physical stock to 0'
);

-- 18d. Physical book record is gone after reducing to 0
SELECT ok(
  NOT library_internal.is_physical_book('ISBN-002'),
  'update_book: is_physical_book FALSE after reducing stock to 0'
);

-- 19. Cannot reduce quantity below active loan count
-- First create an active loan
INSERT INTO library.PhysicalBookLoans
  (book_isbn, user_id, loan_date, loan_return_date, loan_qty, loan_returned)
VALUES ('ISBN-001', 
  (SELECT user_id FROM library.Users WHERE username = 'member'),
  NOW() - INTERVAL '1 day', NOW() + INTERVAL '7 days', 4, FALSE);

SELECT is(
  (library_api.update_book(
    current_setting('test.librarian_token'),
    'ISBN-001', 'Test Book', '2020-01-01', 1, FALSE)).error_code::TEXT,
  'active_loans',
  'update_book: cannot reduce quantity below active loan count'
);

-- 20. Can reduce quantity to exactly active loan count
SELECT ok(
  (library_api.update_book(
    current_setting('test.librarian_token'),
    'ISBN-001', 'Test Book', '2020-01-01', 4, FALSE)).success,
  'update_book: can reduce quantity to exactly active loan count'
);

-- 21. Cannot remove digital flag while digital loans are active
INSERT INTO library.DigitalBookLoans
  (user_id, book_isbn, loan_date, loan_expiry)
VALUES ((SELECT user_id FROM library.Users WHERE username = 'member'), 'ISBN-005', CURRENT_DATE - 1, CURRENT_DATE + 7);

SELECT is(
  (library_api.update_book(
    current_setting('test.librarian_token'),
    'ISBN-005', 'Both Book', '2020-01-01', 3, FALSE)).error_code::TEXT,
  'active_loans',
  'update_book: cannot remove digital flag while digital loans are active'
);

-- 22. Can remove digital flag when no active digital loans
SELECT ok(
  (library_api.update_book(
    current_setting('test.librarian_token'),
    'ISBN-002', 'Digital Book', '2020-01-01', NULL, FALSE)).success,
  'update_book: can remove digital flag when no active digital loans'
);

-- ==================
-- remove_book
-- ==================

-- 23. Librarian can remove a book with no loans
SELECT ok(
  (library_api.add_book(
    current_setting('test.librarian_token'),
    'ISBN-DEL', 'Book To Delete', '2020-01-01', 0, FALSE)).success,
  'remove_book: setup - add book to delete'
);

SELECT ok(
  (library_api.remove_book(
    current_setting('test.librarian_token'), 'ISBN-DEL')).success,
  'remove_book: librarian can remove book with no loans'
);

-- 24. Book is actually gone after removal
SELECT ok(
  NOT library_internal.exists_book_by_isbn('ISBN-DEL'),
  'remove_book: book no longer exists after removal'
);

-- 25. Member cannot remove a book
SELECT ok(
  NOT (library_api.remove_book(
    current_setting('test.member_token'), 'ISBN-001')).success,
  'remove_book: member cannot remove a book'
);

-- 26. Returns book_not_found for unknown ISBN
SELECT is(
  (library_api.remove_book(
    current_setting('test.librarian_token'), 'NO-SUCH-ISBN')).error_code::TEXT,
  'book_not_found',
  'remove_book: returns book_not_found for unknown ISBN'
);

-- 27. Cannot remove book with active physical loans
SELECT is(
  (library_api.remove_book(
    current_setting('test.librarian_token'), 'ISBN-001')).error_code::TEXT,
  'active_loans',
  'remove_book: cannot remove book with active physical loans'
);

-- 28. Cannot remove book with active digital loans
SELECT is(
  (library_api.remove_book(
    current_setting('test.librarian_token'), 'ISBN-005')).error_code::TEXT,
  'active_loans',
  'remove_book: cannot remove book with active digital loans'
);

-- ==================
-- exists_book_by_isbn
-- ==================

-- 29. Returns TRUE for known ISBN
SELECT ok(
  library_internal.exists_book_by_isbn('ISBN-001'),
  'exists_book_by_isbn: TRUE for known ISBN'
);

-- 30. Returns FALSE for unknown ISBN
SELECT ok(
  NOT library_internal.exists_book_by_isbn('NO-SUCH-ISBN'),
  'exists_book_by_isbn: FALSE for unknown ISBN'
);

-- ==================
-- is_physical_book
-- ==================

-- 31. Returns TRUE for physical book
SELECT ok(
  library_internal.is_physical_book('ISBN-001'),
  'is_physical_book: TRUE for physical book'
);

-- 32. Returns FALSE for digital-only book (ISBN-002 had physical removed in test 22)
SELECT ok(
  NOT library_internal.is_physical_book('ISBN-002'),
  'is_physical_book: FALSE for digital-only book'
);

SELECT * FROM finish();
ROLLBACK;