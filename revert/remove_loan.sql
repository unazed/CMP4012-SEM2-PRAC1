-- Revert library:remove_loan from pg

BEGIN;

    DROP FUNCTION library_api.remove_physical_loan;
    DROP FUNCTION library_api.remove_digital_loan;

COMMIT;
