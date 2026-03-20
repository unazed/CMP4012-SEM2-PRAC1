-- Revert library:add_loan from pg

BEGIN;

  DROP FUNCTION library_api.create_physical_loan;
  DROP FUNCTION library_api.get_physical_loans;
  DROP FUNCTION library_api.get_physical_loan_by_id;
  DROP FUNCTION library_api.get_digital_loans;
  DROP FUNCTION library_api.update_physical_loan;
  DROP FUNCTION library_api.get_qty_physical_available;

  DROP FUNCTION library_internal.user_has_physical_loan;
  DROP FUNCTION library_internal.get_qty_physical_available;
  
COMMIT;
