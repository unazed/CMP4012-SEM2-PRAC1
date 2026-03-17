-- Deploy library:books to pg

BEGIN;

  CREATE TABLE library.Books (
    book_isbn 		TEXT NOT NULL UNIQUE,
    book_name		TEXT NOT NULL,
    book_publish_date	DATE NOT NULL,
    book_has_digital	BOOLEAN NOT NULL,

    CONSTRAINT PK_Books
      PRIMARY KEY (book_isbn)
  );

  CREATE TABLE library.Authors (
    author_id		INTEGER GENERATED ALWAYS AS IDENTITY,
    author_first_name	TEXT NOT NULL,
    author_last_name	TEXT NOT NULL,

    CONSTRAINT PK_Authors 
      PRIMARY KEY (author_id)
  );

  CREATE TABLE library.BookAuthors (
    author_id	INTEGER NOT NULL,
    book_isbn	TEXT NOT NULL,

    CONSTRAINT PK_BookAuthors
      PRIMARY KEY (author_id, book_isbn),

    CONSTRAINT FK_BookAuthors__author
      FOREIGN KEY (author_id)
      REFERENCES library.Authors(author_id)
      ON DELETE CASCADE,
    CONSTRAINT FK_BookAuthors__book
      FOREIGN KEY (book_isbn)
      REFERENCES library.Books(book_isbn)
      ON DELETE CASCADE
  );

COMMIT;
