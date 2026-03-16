-- Deploy library:digital_book_loans to pg

BEGIN;

  CREATE TABLE library.DigitalBookLoans (
    book_id	INTEGER NOT NULL,
    user_id	INTEGER NOT NULL,
    loan_date	TIMESTAMPTZ NOT NULL,
    loan_expiry	TIMESTAMPTZ,  -- NULL = no expiry date

    CONSTRAINT PK_DigitalBookLoans
      PRIMARY KEY (book_id, user_id, loan_date),

    CONSTRAINT FK_DigitalBookLoans__book
      FOREIGN KEY (book_id)
      REFERENCES library.DigitalBooks(book_id)
      ON DELETE CASCADE,
    CONSTRAINT FK_DigitalBookLoans__user
      FOREIGN KEY (user_id)
      REFERENCES library.Users(user_id)
      ON DELETE CASCADE,

    CONSTRAINT CHK_DigitalBookLoans__valid_expiry
      CHECK (loan_date < loan_expiry) 
  );

COMMIT;
