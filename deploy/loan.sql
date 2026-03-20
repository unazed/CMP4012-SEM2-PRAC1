-- Deploy library:loan to pg

BEGIN;

  CREATE TABLE library.PhysicalBooks (
    book_isbn		TEXT NOT NULL,
    book_quantity	INTEGER NOT NULL,

    CONSTRAINT PK_PhysicalBooks
      PRIMARY KEY (book_isbn),

    CONSTRAINT FK_PhysicalBook__book_isbn
      FOREIGN KEY (book_isbn)
      REFERENCES library.Books(book_isbn)
      ON DELETE CASCADE,

    CONSTRAINT CHK_PhysicalBook__valid_quantity
      CHECK (book_quantity >= 0)
  );

  CREATE TABLE library.DigitalBooks (
    book_isbn	TEXT NOT NULL,
    book_url	TEXT,

    CONSTRAINT PK_DigitalBooks
      PRIMARY KEY (book_isbn),

    CONSTRAINT FK_DigitalBook__book_isbn
      FOREIGN KEY (book_isbn)
      REFERENCES library.Books(book_isbn)
      ON DELETE CASCADE
  );

  CREATE TABLE library.PhysicalBookLoans (
    loan_id		INTEGER GENERATED ALWAYS AS IDENTITY,
    book_isbn		TEXT NOT NULL,
    user_id		INTEGER NOT NULL,
    loan_qty            INTEGER NOT NULL,

    loan_date		TIMESTAMPTZ NOT NULL,
    loan_return_date	TIMESTAMPTZ,  -- NULL = no return date
    loan_returned	BOOLEAN DEFAULT FALSE NOT NULL,

    CONSTRAINT PK_PhysicalBookLoan
      PRIMARY KEY (loan_id),

    CONSTRAINT FK_PhysicalBookLoans__book
      FOREIGN KEY (book_isbn)
      REFERENCES library.PhysicalBooks(book_isbn)
      ON DELETE RESTRICT,
    CONSTRAINT FK_PhysicalBookLoans__user
      FOREIGN KEY (user_id)
      REFERENCES library.Users(user_id)
      ON DELETE RESTRICT,
  
    CONSTRAINT CHK_PhysicalBookLoans__valid_dates
      CHECK (loan_date < loan_return_date)
  );

COMMIT;
