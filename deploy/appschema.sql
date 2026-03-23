-- Deploy library:appschema to pg

BEGIN;

  CREATE EXTENSION plpgsql_check;

  CREATE SCHEMA library;
  CREATE SCHEMA library_api;
  CREATE SCHEMA library_internal;

  CREATE EXTENSION pgtap;

  CREATE TYPE library_internal.generic_error_code AS ENUM (
    'user_existing_loans',
    'user_not_found',
    'insufficient_quantity',
    'invalid_params',
    'loan_not_found',
    'loan_active'
  );

  CREATE TYPE library_internal.auth_error_code AS ENUM (
    'user_exists',
    'login_invalid',
    'malformed_credentials',
    'account_disabled',
    'token_invalid',
    'insufficient_permissions'
  );

  CREATE TYPE library_internal.book_error_code AS ENUM (
    'book_already_exists',
    'book_not_found',
    'no_digital_entry',
    'active_loans'
  );

  CREATE TYPE library_internal.result_type AS (
    success     BOOLEAN,
    error_code  TEXT,
    data        JSONB
  );

COMMIT;
