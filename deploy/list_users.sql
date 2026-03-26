-- Deploy library:list_users to pg

BEGIN;

  CREATE FUNCTION library_api.get_members(p_token TEXT)
  RETURNS library_internal.result_type
  AS $$
  DECLARE
    m_auth_result library_internal.result_type;
    m_result      library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    SELECT true, NULL, jsonb_agg(jsonb_build_object(
      'id', U.user_id,
      'username', U.username,
      'email', U.email,
      'user_role', U.user_role
    ))
    INTO m_result.success, m_result.error_code, m_result.data
    FROM library.Users U
    WHERE U.user_role = 'member'::library.user_role;

    RETURN m_result;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
