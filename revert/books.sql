-- Revert library:books from pg

BEGIN;

  DROP TABLE library.BookAuthors;
  DROP TABLE library.Books;
  DROP TABLE library.Authors;

COMMIT;
