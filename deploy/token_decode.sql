-- Deploy library:token_decode to pg

BEGIN;

  CREATE FUNCTION library_internal.decode_token(p_token TEXT)
  RETURNS JSON AS $$
  DECLARE
    m_payload 	JSON;
    m_is_valid 	BOOLEAN;
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

COMMIT;
