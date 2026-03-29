-- Deploy library:login_with_token to pg

BEGIN;

  CREATE FUNCTION library_api.get_token_information(p_token TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result library_internal.result_type;
    m_result      library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    SELECT true, NULL, to_jsonb(u) || jsonb_build_object('token', p_token) 
    INTO m_result
    FROM library.Users u
    WHERE u.user_id = (m_auth_result.data->>'user_id')::INTEGER;

    RETURN m_result;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
