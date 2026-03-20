-- Deploy library:digital_book_loans to pg

BEGIN;

  CREATE TABLE library.DigitalBookLoans (
    loan_id	INTEGER GENERATED ALWAYS AS IDENTITY,
    book_isbn	TEXT NOT NULL,
    user_id	INTEGER NOT NULL,
    loan_date	TIMESTAMPTZ NOT NULL,
    loan_expiry	TIMESTAMPTZ,  -- NULL = no expiry date

    CONSTRAINT PK_DigitalBookLoans
      PRIMARY KEY (loan_id),

    CONSTRAINT FK_DigitalBookLoans__book
      FOREIGN KEY (book_isbn)
      REFERENCES library.DigitalBooks(book_isbn)
      ON DELETE RESTRICT,
    CONSTRAINT FK_DigitalBookLoans__user
      FOREIGN KEY (user_id)
      REFERENCES library.Users(user_id)
      ON DELETE RESTRICT,

    CONSTRAINT CHK_DigitalBookLoans__valid_expiry
      CHECK (loan_date < loan_expiry) 
  );

COMMIT;
