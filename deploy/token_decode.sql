-- Deploy library:token_decode to pg

BEGIN;

  CREATE FUNCTION library_internal.decode_token(p_token TEXT)
  RETURNS JSONB AS $$
  DECLARE
    m_payload   JSONB;
    m_is_valid  BOOLEAN;
  BEGIN
    SELECT payload, valid
    INTO m_payload, m_is_valid
    FROM verify(p_token, library_internal.get_app_config_value('jwt_secret'));

    IF NOT m_is_valid THEN
      RETURN NULL;
    END IF;

    return m_payload;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_internal.exists_user(p_user_id INTEGER)
  RETURNS BOOLEAN AS $$
    SELECT EXISTS (SELECT FROM library.Users WHERE user_id = p_user_id);
  $$ LANGUAGE sql STABLE;
  
  CREATE FUNCTION library_internal.is_valid_session(p_token TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_session   JSONB;
  BEGIN
    m_session := library_internal.decode_token(p_token);
    IF m_session IS NULL THEN
      RETURN library_internal.make_error_result(
        'token_invalid'::library_internal.auth_error_code);
    ELSIF NOT library_internal.exists_user(
        (m_session->>'user_id')::INTEGER) THEN
      RETURN library_internal.make_error_result(
	      'token_invalid'::library_internal.auth_error_code);
    END IF;
    return library_internal.make_success_result(m_session);
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

  CREATE FUNCTION library_internal.is_librarian(p_token TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    ELSIF (m_auth_result.data->>'role')::library.user_role
        <> 'librarian'::library.user_role THEN
      RETURN library_internal.make_error_result(
        'insufficient_permissions'::library_internal.auth_error_code);
    END IF;
    RETURN m_auth_result;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
