-- Deploy library:register to pg

BEGIN;

  CREATE FUNCTION library_internal.make_success_result()
    RETURNS library_internal.result_type AS $$
  BEGIN
    RETURN ROW(TRUE, NULL, NULL)::library_internal.result_type;
  END;
  $$ LANGUAGE plpgsql;

  CREATE FUNCTION library_internal.make_success_result(data anyelement)
  RETURNS library_internal.result_type AS $$
  BEGIN
    RETURN ROW(TRUE, NULL, data)::library_internal.result_type;
  END;
  $$ LANGUAGE plpgsql;

  CREATE FUNCTION library_internal.make_error_result(error_code anyelement)
  RETURNS library_internal.result_type AS $$
  BEGIN
    RETURN ROW(FALSE, error_code::TEXT, NULL)::library_internal.result_type;
  END;
  $$ LANGUAGE plpgsql;

  CREATE FUNCTION library_internal.normalize_email(email TEXT)
  RETURNS TEXT
  LANGUAGE sql IMMUTABLE AS $$
    SELECT lower(
      split_part(split_part(email, '@', 1), '+', 1)
      || '@' ||
      split_part(email, '@', 2)
    );
  $$;

  SET lock_timeout = '2s';
  CREATE UNIQUE INDEX IDX_Users__normalized_email
  ON library.Users (library_internal.normalize_email(email));

  CREATE FUNCTION library_internal.get_app_config_value(p_key TEXT)
  RETURNS TEXT
  LANGUAGE sql STABLE AS $$
    SELECT value
      FROM library_internal.app_config
      WHERE key = p_key;
  $$;

  CREATE FUNCTION library_api.register_user(
    p_email 	  TEXT,
    p_username  TEXT,
    p_password 	TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_pwd_hash  TEXT;
    m_user_id 	INTEGER;
    m_token 	  TEXT;
    m_email	    TEXT;
  BEGIN
    IF p_email NOT LIKE '%@%.%' THEN
      RETURN library_internal.make_error_result(
        'malformed_credentials'::library_internal.auth_error_code);
    END IF;
    
    m_email = library_internal.normalize_email(p_email);
    m_pwd_hash := crypt(p_password, gen_salt('bf', 8));

    BEGIN
      INSERT INTO library.Users (
	      email, username, user_role, user_status, password_hash)
      VALUES (
	      m_email, p_username, 'member', 'active', m_pwd_hash)
      RETURNING user_id INTO m_user_id;
    EXCEPTION
      WHEN unique_violation THEN
        RETURN library_internal.make_error_result(
          'user_exists'::library_internal.auth_error_code);
    END;
    
  m_token := sign(
    json_build_object(
      'user_id', m_user_id,
      'email', m_email,
      'role', 'member'::library.user_role),
    library_internal.get_app_config_value('jwt_secret'),
    'HS256');

    RETURN library_internal.make_success_result(
      json_build_object(
        'token', m_token,
        'username', p_username,
        'email', m_email,
        'role', 'member'::library.user_role));
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
