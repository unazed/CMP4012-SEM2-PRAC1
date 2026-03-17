-- Deploy library:add_book to pg

BEGIN;

  CREATE TYPE library_internal.book_error_code AS ENUM (
    'book_not_found',
    'no_digital_entry'
  );

  CREATE FUNCTION library_internal.get_user_role(p_user_id INTEGER)
  RETURNS TEXT
  LANGUAGE sql STABLE AS $$
    SELECT user_role
      FROM library.Users
      WHERE user_id = p_user_id; 
  $$;

  CREATE FUNCTION library_internal.is_librarian(p_token TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_session 	JSON;
    m_user_role TEXT;
  BEGIN
    m_session := library_internal.decode_token(p_token);
    if m_session IS NULL THEN
      RETURN library_internal.make_error_result(
	'token_invalid'::library_internal.auth_error_code);
    END IF;
    m_user_role := library_internal.get_user_role(
      (m_session->>'user_id')::INTEGER);
    if m_user_role <> 'librarian'::library.user_role THEN
      RETURN library_internal.make_error_result(
	'insufficient_permissions'::library_internal.auth_error_code);
    END IF;
    RETURN library_internal.make_success_result(
      json_build_object('session', m_session));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.add_book(
    p_token TEXT, p_isbn TEXT, p_name TEXT, p_publish_date DATE,
    p_quantity INTEGER, p_has_digital BOOLEAN)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result	library_internal.result_type;
    m_user_role		TEXT;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
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
      jsonb_build_object('isbn', p_isbn));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_api.find_book_by_isbn(p_isbn TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_result JSONB;
  BEGIN
    SELECT to_jsonb(b)
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
      jsonb_build_object('isbn', p_isbn, 'url', p_url));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
