-- Revert library:add_book from pg

BEGIN;

  DROP FUNCTION library_api.remove_book;
  DROP FUNCTION library_api.update_book;
  DROP FUNCTION library_api.add_book;
  DROP FUNCTION library_api.set_digital_book_url;
  DROP FUNCTION library_api.find_book_by_isbn;

  DROP FUNCTION library_internal.get_max_concurrent_physical_loans;
  DROP FUNCTION library_internal.get_qty_physical_loans;
  DROP FUNCTION library_internal.has_active_physical_loans;
  DROP FUNCTION library_internal.has_active_digital_loans;
  DROP FUNCTION library_internal.get_qty_digital_loans;
  DROP FUNCTION library_internal.is_physical_book;
  DROP FUNCTION library_internal.exists_book_by_isbn;
  DROP FUNCTION library_internal.get_user_role;
  DROP FUNCTION library_internal.is_active_physical_loan;
  DROP FUNCTION library_internal.is_active_digital_loan;

COMMIT;
