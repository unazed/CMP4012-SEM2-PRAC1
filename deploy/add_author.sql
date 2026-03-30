-- Deploy library:add_author to pg

BEGIN;

  CREATE FUNCTION library_internal.exists_author_by_id(p_author_id INTEGER)
  RETURNS BOOLEAN AS $$
    SELECT EXISTS (SELECT 1 FROM library.Authors WHERE author_id = p_author_id);
  $$ LANGUAGE sql STABLE;

  CREATE FUNCTION library_api.add_author(
    p_token TEXT, p_isbn TEXT, p_first_name TEXT, p_last_name TEXT,
    p_author_id INTEGER DEFAULT NULL)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result library_internal.result_type;
    m_author_id   INTEGER;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    ELSIF NOT library_internal.exists_book_by_isbn(p_isbn) THEN
      RETURN library_internal.make_error_result(
        'book_not_found'::library_internal.book_error_code);
    END IF;

    IF p_author_id IS NOT NULL THEN
      IF NOT library_internal.exists_author_by_id(p_author_id) THEN
        RETURN library_internal.make_error_result(
          'author_not_found'::library_internal.author_error_code);
      END IF;

      INSERT INTO library.BookAuthors (book_isbn, author_id)
      VALUES (p_isbn, p_author_id);

      RETURN library_internal.make_success_result(
        json_build_object('author_id', p_author_id));
    END IF;

    INSERT INTO library.Authors (author_first_name, author_last_name)
    VALUES (p_first_name, p_last_name)
    RETURNING author_id INTO m_author_id;

    INSERT INTO library.BookAuthors (book_isbn, author_id)
    VALUES (p_isbn, m_author_id);

    RETURN library_internal.make_success_result(
      json_build_object('author_id', m_author_id));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
