-- Deploy library:loan to pg

BEGIN;

  CREATE TABLE library.PhysicalBooks (
    book_id		INTEGER NOT NULL,
    book_quantity	INTEGER NOT NULL,

    CONSTRAINT PK_PhysicalBooks
      PRIMARY KEY (book_id),

    CONSTRAINT FK_PhysicalBook__book_id
      FOREIGN KEY (book_id)
      REFERENCES library.Books(book_id)
      ON DELETE CASCADE,

    CONSTRAINT CHK_PhysicalBook__valid_quantity
      CHECK (book_quantity >= 0)
  );

  CREATE TABLE library.DigitalBooks (
    book_id	INTEGER NOT NULL,
    book_url	TEXT NOT NULL,

    CONSTRAINT PK_DigitalBooks
      PRIMARY KEY (book_id),

    CONSTRAINT FK_DigitalBook__book_id
      FOREIGN KEY (book_id)
      REFERENCES library.Books(book_id)
      ON DELETE CASCADE
  );

  CREATE TABLE library.PhysicalBookLoans (
    book_id		INTEGER NOT NULL,
    user_id		INTEGER NOT NULL,

    loan_date		TIMESTAMPTZ NOT NULL,
    loan_return_date	TIMESTAMPTZ,  -- NULL = no return date
    loan_returned	BOOLEAN DEFAULT FALSE NOT NULL,

    CONSTRAINT PK_PhysicalBookLoan
      PRIMARY KEY (book_id, user_id, loan_date),

    CONSTRAINT FK_PhysicalBookLoans__book
      FOREIGN KEY (book_id)
      REFERENCES library.PhysicalBooks(book_id),
    CONSTRAINT FK_PhysicalBookLoans__user
      FOREIGN KEY (user_id)
      REFERENCES library.Users(user_id),
  
    CONSTRAINT CHK_PhysicalBookLoans__valid_dates
      CHECK (loan_date < loan_return_date)
  );

COMMIT;
