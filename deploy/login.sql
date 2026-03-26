-- Deploy library:login to pg

BEGIN;

  CREATE FUNCTION library_api.login_user(p_email TEXT, p_password TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_token	      TEXT;
    m_email 	    TEXT;
    m_user_id 	  INTEGER;
    m_pwd_hash 	  TEXT;
    m_user_status library.user_status;
    m_user_role   library.user_role;
    m_username 	  TEXT;
  BEGIN
    IF p_email NOT LIKE '%@%.%' THEN
      RETURN library_internal.make_error_result(
        'malformed_credentials'::library_internal.auth_error_code);
    END IF;
    
    m_email := library_internal.normalize_email(p_email);

    SELECT user_id, username, password_hash, user_status, user_role
    INTO m_user_id, m_username, m_pwd_hash, m_user_status, m_user_role
    FROM library.Users 
    WHERE email = m_email;

    IF NOT FOUND THEN
      RETURN library_internal.make_error_result(
	      'login_invalid'::library_internal.auth_error_code);
    ELSIF crypt(p_password, m_pwd_hash) <> m_pwd_hash THEN
      RETURN library_internal.make_error_result(
	      'login_invalid'::library_internal.auth_error_code);
    ELSIF m_user_status <> 'active'::library.user_status THEN
      RETURN library_internal.make_error_result(
	      'account_disabled'::library_internal.auth_error_code);
    END IF;

  m_token := sign(
    json_build_object(
      'user_id', m_user_id,
      'email', m_email,
      'role', m_user_role),
    library_internal.get_app_config_value('jwt_secret'),
    'HS256');

  RETURN library_internal.make_success_result(
    json_build_object(
      'token', m_token,
      'username', m_username,
      'role', m_user_role,
      'email', m_email));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
