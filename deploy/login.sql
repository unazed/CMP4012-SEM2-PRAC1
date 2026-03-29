-- Deploy library:login to pg

BEGIN;

  CREATE FUNCTION library_api.login_user(p_email TEXT, p_password TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_token	      TEXT;
    m_email 	    TEXT;
    m_user        library.Users%ROWTYPE;
  BEGIN
    IF p_email NOT LIKE '%@%.%' THEN
      RETURN library_internal.make_error_result(
        'malformed_credentials'::library_internal.auth_error_code);
    END IF;
    
    m_email := library_internal.normalize_email(p_email);

    SELECT * INTO m_user
    FROM library.Users U 
    WHERE email = m_email;

    IF NOT FOUND THEN
      RETURN library_internal.make_error_result(
	      'login_invalid'::library_internal.auth_error_code);
    ELSIF crypt(p_password, m_user.password_hash) <> m_user.password_hash THEN
      RETURN library_internal.make_error_result(
	      'login_invalid'::library_internal.auth_error_code);
    ELSIF m_user.user_status <> 'active'::library.user_status THEN
      RETURN library_internal.make_error_result(
	      'account_disabled'::library_internal.auth_error_code);
    END IF;

  m_token := sign(
    json_build_object(
      'user_id', m_user.user_id,
      'username', m_user.username,
      'email', m_user.email,
      'user_role', m_user.user_role),
    library_internal.get_app_config_value('jwt_secret'),
    'HS256');

  RETURN library_internal.make_success_result(
    to_jsonb(m_user) || jsonb_build_object('token', m_token));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
