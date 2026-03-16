-- Revert library:loan from pg

BEGIN;

  DROP TABLE library.PhysicalBookLoans;
  DROP TABLE library.DigitalBooks;
  DROP TABLE library.PhysicalBooks;

COMMIT;
