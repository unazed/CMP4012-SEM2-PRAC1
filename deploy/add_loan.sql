-- Deploy library:add_loan to pg

BEGIN;

  CREATE FUNCTION library_internal.user_has_physical_loan(
    p_user_id INTEGER, p_isbn TEXT, 
    p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL)
  RETURNS BOOLEAN AS $$
  BEGIN
    IF p_from_date IS NULL THEN
      RETURN (SELECT EXISTS (
        SELECT FROM library.PhysicalBookLoans
        WHERE user_id = p_user_id
        AND book_isbn = p_isbn));
    END IF;

    RETURN (SELECT EXISTS (
      SELECT FROM library.PhysicalBookLoans
      WHERE user_id = p_user_id
        AND book_isbn = p_isbn
        AND NOT loan_returned
        AND loan_date <= p_from_date
        AND COALESCE(p_to_date <= loan_return_date, TRUE)));
  END;
  $$ LANGUAGE plpgsql STABLE;

  CREATE FUNCTION library_internal.get_qty_physical_available(
    p_isbn TEXT, p_from TIMESTAMPTZ, p_to TIMESTAMPTZ)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_book_result       library_internal.result_type;
    m_qty               INTEGER;
  BEGIN
    m_book_result := library_api.find_book_by_isbn(p_isbn);
    IF NOT m_book_result.success THEN
      RETURN m_book_result;
    END IF;

    SELECT book_quantity
    INTO m_qty
    FROM library.PhysicalBooks
    WHERE book_isbn = p_isbn;

    m_qty := m_qty - library_internal.get_max_concurrent_physical_loans(
      p_isbn, p_from, p_to);

    RETURN library_internal.make_success_result(
      jsonb_build_object('qty', m_qty));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.get_qty_physical_available(
    p_token TEXT, p_isbn TEXT, p_from TIMESTAMPTZ, p_to TIMESTAMPTZ)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result       library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;
    RETURN library_internal.get_qty_physical_available(p_isbn, p_from, p_to);
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.create_physical_loan(
    p_token TEXT, p_isbn TEXT, p_loanee_id INTEGER,
    p_from_date TIMESTAMPTZ, p_to_date TIMESTAMPTZ,
    p_quantity INTEGER DEFAULT 1)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result       library_internal.result_type;
    m_loan_id           INTEGER;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    ELSIF NOT library_internal.exists_user(p_loanee_id) THEN
      RETURN library_internal.make_error_result(
        'user_not_found'::library_internal.generic_error_code);
    ELSIF p_quantity <= 0 THEN
      RETURN library_internal.make_error_result(
        'invalid_params'::library_internal.generic_error_code);
    ELSIF ((library_internal.get_qty_physical_available(
        p_isbn, p_from_date, p_to_date)).data->>'qty')::INTEGER
        < p_quantity THEN
      RETURN library_internal.make_error_result(
        'insufficient_quantity'::library_internal.generic_error_code);
    END IF;

    INSERT INTO library.PhysicalBookLoans(
      book_isbn, user_id, loan_date, loan_return_date, loan_qty)
    VALUES (p_isbn, p_loanee_id, p_from_date, p_to_date, p_quantity)
    RETURNING loan_id INTO m_loan_id;

    RETURN library_internal.make_success_result(
      jsonb_build_object('loan_id', m_loan_id));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.get_physical_loans(p_token TEXT, p_isbn TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result       library_internal.result_type;
    m_user_role         library.user_role;
    m_user_id           INTEGER;
    m_loans             JSONB;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    m_user_role := (m_auth_result.data->>'user_role')::library.user_role;
    m_user_id := (m_auth_result.data->>'user_id')::INTEGER;

    SELECT COALESCE(jsonb_agg(to_jsonb(PL)), '[]'::JSONB)
    INTO m_loans
    FROM library.PhysicalBookLoans PL
    WHERE book_isbn = p_isbn
      AND (m_user_role = 'librarian'::library.user_role OR user_id = m_user_id);
      
    RETURN library_internal.make_success_result(m_loans);
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.get_physical_loan_by_id(
    p_token TEXT, p_loan_id INTEGER)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result       library_internal.result_type;
    m_user_role         library.user_role;
    m_user_id           INTEGER;
    m_loan              library.PhysicalBookLoans%ROWTYPE;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    m_user_role := (m_auth_result.data->>'user_role')::library.user_role;
    m_user_id := (m_auth_result.data->>'user_id')::INTEGER;

    SELECT * INTO m_loan
    FROM library.PhysicalBookLoans
    WHERE loan_id = p_loan_id;

    IF NOT FOUND THEN
      RETURN library_internal.make_error_result(
        'loan_not_found'::library_internal.generic_error_code);
    ELSIF m_user_role = 'member'::library.user_role
        AND m_loan.user_id <> m_user_id THEN
      RETURN library_internal.make_error_result(
        'insufficient_permissions'::library_internal.auth_error_code);
    END IF;

    RETURN library_internal.make_success_result(to_jsonb(m_loan));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.get_digital_loans(p_token TEXT, p_isbn TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result       library_internal.result_type;
    m_user_role         library.user_role;
    m_user_id           INTEGER;
    m_loans             JSONB;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    m_user_role := (m_auth_result.data->>'user_role')::library.user_role;
    m_user_id := (m_auth_result.data->>'user_id')::INTEGER;

    SELECT COALESCE(jsonb_agg(to_jsonb(DL)), '[]'::JSONB)
    INTO m_loans
    FROM library.DigitalBookLoans DL
    WHERE book_isbn = p_isbn
      AND (m_user_role = 'librarian'::library.user_role OR user_id = m_user_id);

    RETURN library_internal.make_success_result(m_loans);
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.update_physical_loan(
    p_token TEXT, p_loan_id INTEGER, p_loan_date TIMESTAMPTZ,
    p_loan_return_date TIMESTAMPTZ, p_loan_returned BOOLEAN)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result       library_internal.result_type;
    m_user_role         library.user_role;
    m_user_id           INTEGER;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    m_user_role := (m_auth_result.data->>'user_role')::library.user_role;
    m_user_id := (m_auth_result.data->>'user_id')::INTEGER;

    IF NOT EXISTS (
        SELECT FROM library.PhysicalBookLoans
        WHERE loan_id = p_loan_id) THEN
      RETURN library_internal.make_error_result(
        'loan_not_found'::library_internal.generic_error_code);
    END IF;

    CASE
      WHEN m_user_role = 'librarian'::library.user_role THEN
        NULL;
      WHEN m_user_role = 'member'::library.user_role THEN
        IF NOT EXISTS (
            SELECT FROM library.PhysicalBookLoans
            WHERE loan_id = p_loan_id
              AND user_id = m_user_id) THEN
          RETURN library_internal.make_error_result(
            'insufficient_permissions'::library_internal.auth_error_code);
        END IF;
      ELSE
        RAISE EXCEPTION 'Unhandled user role: %', m_user_role;
    END CASE;

    UPDATE library.PhysicalBookLoans
    SET
      loan_date = COALESCE(p_loan_date, loan_date),
      loan_return_date = COALESCE(p_loan_return_date, loan_return_date),
      loan_returned = COALESCE(p_loan_returned, loan_returned)
    WHERE loan_id = p_loan_id;

    RETURN library_internal.make_success_result();
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
