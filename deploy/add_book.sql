-- Deploy library:add_book to pg

BEGIN;

  CREATE FUNCTION library_internal.get_user_role(p_user_id INTEGER)
  RETURNS TEXT
  LANGUAGE sql STABLE AS $$
    SELECT user_role
      FROM library.Users
      WHERE user_id = p_user_id; 
  $$;

  CREATE FUNCTION library_api.add_book(
    p_token TEXT, p_isbn TEXT, p_name TEXT, p_publish_date DATE,
    p_quantity INTEGER, p_has_digital BOOLEAN)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result	library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    ELSIF library_internal.exists_book_by_isbn(p_isbn) THEN
      RETURN library_internal.make_error_result(
        'book_already_exists'::library_internal.book_error_code);
    END IF;

    INSERT INTO library.Books (
      book_name, book_publish_date, book_has_digital, book_isbn)
    VALUES (p_name, p_publish_date, p_has_digital, p_isbn);

    IF p_quantity > 0 THEN
      INSERT INTO library.PhysicalBooks (book_isbn, book_quantity)
      VALUES (p_isbn, p_quantity);
    END IF;

    IF p_has_digital THEN
      INSERT INTO library.DigitalBooks (book_isbn)
      VALUES (p_isbn);
    END IF;
    
    RETURN library_internal.make_success_result(
      json_build_object('isbn', p_isbn));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_internal.exists_book_by_isbn(p_isbn TEXT)
  RETURNS BOOLEAN AS $$
    SELECT EXISTS (SELECT FROM library.Books WHERE book_isbn = p_isbn);
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_api.find_book_by_isbn(p_isbn TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_result JSON;
  BEGIN
    SELECT to_json(b)
    INTO m_result
    FROM library.Books b
    WHERE b.book_isbn = p_isbn;

    IF m_result IS NULL THEN
      RETURN library_internal.make_error_result(
	      'book_not_found'::library_internal.book_error_code);
    END IF;

    RETURN library_internal.make_success_result(m_result);
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.set_digital_book_url(
    p_token TEXT, p_isbn TEXT, p_url TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result library_internal.result_type;
    m_book_result library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    m_book_result := library_api.find_book_by_isbn(p_isbn);
    IF NOT m_book_result.success THEN
      RETURN m_book_result;
    ELSIF NOT (m_book_result.data->>'book_has_digital')::BOOLEAN THEN
      return library_internal.make_error_result(
	      'no_digital_entry'::library_internal.book_error_code);
    END IF;

    UPDATE library.DigitalBooks
    SET book_url = p_url
    WHERE book_isbn = p_isbn;

    RETURN library_internal.make_success_result(
      json_build_object('isbn', p_isbn, 'url', p_url));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_internal.get_max_concurrent_physical_loans(
      p_isbn TEXT, p_from TIMESTAMPTZ, p_to TIMESTAMPTZ)
    RETURNS INTEGER AS $$
      WITH
        events AS (
          SELECT
            GREATEST(loan_date, p_from) AS t,
            loan_qty AS delta
          FROM library.PhysicalBookLoans
          WHERE book_isbn = p_isbn
            AND NOT loan_returned
            AND loan_date < COALESCE(p_to, 'infinity'::TIMESTAMPTZ)
            AND COALESCE(loan_return_date, 'infinity'::TIMESTAMPTZ) > p_from
          UNION ALL
          SELECT
            LEAST(
              COALESCE(loan_return_date, 'infinity'::TIMESTAMPTZ),
              COALESCE(p_to, 'infinity'::TIMESTAMPTZ)) AS t,
            -loan_qty AS delta
          FROM library.PhysicalBookLoans
          WHERE book_isbn = p_isbn
            AND NOT loan_returned
            AND loan_date < COALESCE(p_to, 'infinity'::TIMESTAMPTZ)
            AND COALESCE(loan_return_date, 'infinity'::TIMESTAMPTZ) > p_from
        ),
        ordered AS (
          SELECT
            SUM(delta) OVER (ORDER BY t, delta DESC) AS active_qty
          FROM events
        )
      SELECT COALESCE(MAX(active_qty), 0)::INTEGER
      FROM ordered;
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_internal.get_qty_physical_loans(p_isbn TEXT)
    RETURNS INTEGER AS $$
      SELECT library_internal.get_max_concurrent_physical_loans(
        p_isbn, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_internal.is_active_physical_loan(p_loan_id INTEGER)
    RETURNS BOOLEAN AS $$
      SELECT EXISTS (
        SELECT FROM library.PhysicalBookLoans
        WHERE loan_id = p_loan_id
          AND NOT loan_returned
          AND (loan_return_date IS NULL OR loan_return_date > NOW())
      );
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_internal.is_active_digital_loan(p_loan_id INTEGER)
    RETURNS BOOLEAN AS $$
      SELECT EXISTS (
        SELECT FROM library.DigitalBookLoans
        WHERE loan_id = p_loan_id
          AND loan_date <= CURRENT_DATE
          AND (loan_expiry IS NULL OR CURRENT_DATE <= loan_expiry)
      );
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_internal.has_active_physical_loans(p_isbn TEXT)
    RETURNS BOOLEAN AS $$
      SELECT EXISTS (
        SELECT FROM library.PhysicalBookLoans
        WHERE book_isbn = p_isbn
          AND NOT loan_returned
          AND (loan_return_date IS NULL OR loan_return_date > NOW())
      );
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_internal.has_active_digital_loans(p_isbn TEXT)
    RETURNS BOOLEAN AS $$
      SELECT EXISTS (
        SELECT FROM library.DigitalBookLoans
        WHERE book_isbn = p_isbn
          AND loan_date <= CURRENT_DATE
          AND (loan_expiry IS NULL OR CURRENT_DATE <= loan_expiry)
      );
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_internal.get_qty_digital_loans(p_isbn TEXT)
  RETURNS INTEGER AS $$
    SELECT COUNT(*)::INTEGER
    FROM library.DigitalBookLoans
    WHERE book_isbn = p_isbn
      AND (loan_expiry IS NULL or CURRENT_DATE <= loan_expiry)
      AND loan_date <= CURRENT_DATE;
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_internal.is_physical_book(p_isbn TEXT)
  RETURNS BOOLEAN AS $$
    SELECT EXISTS (SELECT FROM library.PhysicalBooks WHERE book_isbn = p_isbn);
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_api.update_book(
    p_token TEXT, p_isbn TEXT, p_name TEXT, p_publish_date DATE,
    p_quantity INTEGER, p_has_digital BOOLEAN)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result	library_internal.result_type;
    m_book_result	library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    m_book_result := library_api.find_book_by_isbn(p_isbn);
    IF NOT m_book_result.success THEN
      RETURN m_book_result;
    END IF;

    -- Ensure we can't reduce book quantity less than what we have loaned
    -- out already.
    IF p_quantity IS NOT NULL THEN
      IF p_quantity < library_internal.get_qty_physical_loans(p_isbn) THEN
        RETURN library_internal.make_error_result(
          'active_loans'::library_internal.book_error_code);
      ELSIF NOT library_internal.is_physical_book(p_isbn)
          AND p_quantity > 0 THEN
        INSERT INTO library.PhysicalBooks (book_isbn, book_quantity)
        VALUES (p_isbn, p_quantity);
      ELSIF library_internal.is_physical_book(p_isbn) AND p_quantity = 0 THEN
        DELETE FROM library.PhysicalBooks
        WHERE book_isbn = p_isbn;
      ELSE
        UPDATE library.PhysicalBooks
        SET book_quantity = p_quantity
        WHERE book_isbn = p_isbn;
      END IF;
    END IF;

    -- Similar to above, if we remove the digital version, then we should 
    -- cancel any active digital loans;
    IF p_has_digital IS NOT DISTINCT FROM FALSE
	      AND (m_book_result.data->>'book_has_digital')::BOOLEAN THEN
      IF library_internal.get_qty_digital_loans(p_isbn) > 0 THEN
        RETURN library_internal.make_error_result(
          'active_loans'::library_internal.book_error_code);
      END IF;
      DELETE FROM library.DigitalBooks WHERE book_isbn = p_isbn;
    END IF;

    IF p_has_digital IS NOT DISTINCT FROM TRUE
        AND NOT (m_book_result.data->>'book_has_digital')::BOOLEAN THEN
      INSERT INTO library.DigitalBooks (book_isbn) VALUES (p_isbn);
    END IF;

    UPDATE library.Books
    SET 
      book_name         = COALESCE(p_name, book_name),
      book_publish_date = COALESCE(p_publish_date, book_publish_date),
      book_has_digital  = COALESCE(p_has_digital, book_has_digital)
    WHERE book_isbn = p_isbn;

    RETURN library_internal.make_success_result();
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.remove_book(p_token TEXT, p_isbn TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result	library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    IF NOT library_internal.exists_book_by_isbn(p_isbn) THEN
      RETURN library_internal.make_error_result(
	      'book_not_found'::library_internal.book_error_code);
    ELSIF (library_internal.has_active_physical_loans(p_isbn))
	      OR (library_internal.has_active_digital_loans(p_isbn)) THEN
      RETURN library_internal.make_error_result(
	      'active_loans'::library_internal.book_error_code);
    END IF;

    DELETE FROM library.Books
    WHERE book_isbn = p_isbn;

    RETURN library_internal.make_success_result();
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
