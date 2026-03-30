-- Deploy library:get_authors to pg

BEGIN;

  CREATE FUNCTION library_api.get_authors(p_token TEXT)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result library_internal.result_type;
    m_result      library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_valid_session(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    END IF;

    SELECT true, NULL, jsonb_agg(to_jsonb(A))
    INTO m_result.success, m_result.error_code, m_result.data
    FROM library.Authors A;

    RETURN m_result;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
