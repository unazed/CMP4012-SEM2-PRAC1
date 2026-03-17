-- Deploy library:digital_book_loans to pg

BEGIN;

  CREATE TABLE library.DigitalBookLoans (
    book_isbn	TEXT NOT NULL,
    user_id	INTEGER NOT NULL,
    loan_date	TIMESTAMPTZ NOT NULL,
    loan_expiry	TIMESTAMPTZ,  -- NULL = no expiry date

    CONSTRAINT PK_DigitalBookLoans
      PRIMARY KEY (book_isbn, user_id, loan_date),

    CONSTRAINT FK_DigitalBookLoans__book
      FOREIGN KEY (book_isbn)
      REFERENCES library.DigitalBooks(book_isbn)
      ON DELETE CASCADE,
    CONSTRAINT FK_DigitalBookLoans__user
      FOREIGN KEY (user_id)
      REFERENCES library.Users(user_id)
      ON DELETE CASCADE,

    CONSTRAINT CHK_DigitalBookLoans__valid_expiry
      CHECK (loan_date < loan_expiry) 
  );

COMMIT;
