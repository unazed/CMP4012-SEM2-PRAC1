-- Revert library:register from pg

BEGIN;

  DROP INDEX library.IDX_Users__normalized_email;

  DROP FUNCTION library_api.register_user;
  DROP FUNCTION library_internal.get_app_config_value;
  DROP FUNCTION library_internal.normalize_email;
  DROP FUNCTION library_internal.make_error_result;
  DROP FUNCTION library_internal.make_success_result;
  
  DROP TYPE library_internal.result_type;
  DROP TYPE library_internal.auth_error_code;

COMMIT;
