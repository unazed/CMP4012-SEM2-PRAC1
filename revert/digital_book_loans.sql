-- Revert library:digital_book_loans from pg

BEGIN;

  DROP TABLE library.DigitalBookLoans;

COMMIT;
