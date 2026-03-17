-- Revert library:add_book from pg

BEGIN;

  DROP FUNCTION library_api.set_digital_book_url;
  DROP FUNCTION library_api.find_book_by_isbn;
  DROP FUNCTION library_api.add_book;

  DROP FUNCTION library_internal.is_librarian;
  DROP FUNCTION library_internal.get_user_role;
  DROP TYPE library_internal.book_error_code;

COMMIT;
