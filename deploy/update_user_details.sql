-- Deploy library:update_user_details to pg

BEGIN;

  CREATE FUNCTION library_api.update_user_details(
    p_token TEXT, p_user_id INTEGER, p_email TEXT, p_username TEXT,
    p_account_status library.user_status)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    UPDATE library.users
    SET email = p_email, username = p_username, user_status = p_account_status
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
      RETURN library_internal.make_error_result(
        'user_not_found'::library_internal.generic_error_code);
    END IF;

    RETURN library_internal.make_success_result();

  EXCEPTION
    WHEN unique_violation THEN
      RETURN library_internal.make_error_result(
        'user_exists'::library_internal.auth_error_code);
    
    WHEN OTHERS THEN  -- Likely invalid `user_status` value
      RETURN library_internal.make_error_result(
        'invalid_params'::library_internal.generic_error_code);
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
