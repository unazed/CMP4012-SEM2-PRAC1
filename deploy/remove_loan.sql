-- Deploy library:remove_loan to pg

BEGIN;

  CREATE FUNCTION library_api.remove_physical_loan(
    p_token TEXT, p_loan_id INTEGER)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result   library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    ELSIF NOT EXISTS (
        SELECT FROM library.PhysicalBookLoans
        WHERE loan_id = p_loan_id) THEN
      RETURN library_internal.make_error_result(
        'loan_not_found'::library_internal.generic_error_code);
    ELSIF library_internal.is_active_physical_loan(p_loan_id) THEN
      RETURN library_internal.make_error_result(
        'loan_active'::library_internal.generic_error_code);
    END IF;

    DELETE FROM library.PhysicalBookLoans
    WHERE loan_id = p_loan_id;

    RETURN library_internal.make_success_result();
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE FUNCTION library_api.remove_digital_loan(
    p_token TEXT, p_loan_id INTEGER)
  RETURNS library_internal.result_type AS $$
  DECLARE
    m_auth_result   library_internal.result_type;
  BEGIN
    m_auth_result := library_internal.is_librarian(p_token);
    IF NOT m_auth_result.success THEN
      RETURN m_auth_result;
    ELSIF NOT EXISTS (
        SELECT FROM library.DigitalBookLoans
        WHERE loan_id = p_loan_id) THEN
      RETURN library_internal.make_error_result(
        'loan_not_found'::library_internal.generic_error_code);
    ELSIF library_internal.is_active_digital_loan(p_loan_id) THEN
      RETURN library_internal.make_error_result(
        'loan_active'::library_internal.generic_error_code);
    END IF;

    DELETE FROM library.DigitalBookLoans
    WHERE loan_id = p_loan_id;

    RETURN library_internal.make_success_result();
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;
