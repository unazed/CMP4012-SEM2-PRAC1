from pprint import pprint
from util import *
import psycopg2
import argparse
import os


g_conn = psycopg2.connect(
  host="localhost",
  dbname="library_main",
  user="postgres",
  password="postgres"
)

def generate_composite_parser(type_name: str, fields: dict[str, str], depth: int) -> str:
  parse_lines = []

  for i, (attname, typname) in enumerate(fields.items()):
    java_type = psql_java_type_map.get(typname, "String")
    if java_type == "boolean":
      parse_lines.append(
        f'boolean {attname} = parts[{i}].equals("t");')
    elif java_type == "int":
      parse_lines.append(
        f'int {attname} = parts[{i}].isEmpty() ? 0 : Integer.parseInt(parts[{i}]);')
    else:
      parse_lines.append(
        f'String {attname} = parts[{i}].isEmpty() ? null : parts[{i}];')

  field_args = ", ".join(f"{attname}" for attname in fields)
  parse_lines.append(f'return new {snake_to_pascal(type_name)}({field_args});')

  return ("\n" + "\t" * depth).join(parse_lines)


def generate_composite_type(
    type_name: str, fields: dict[str, str], output_types_dir: str,
    package_types: str) -> str:
  class_name = snake_to_pascal(type_name)
  output_file = os.path.join(output_types_dir, f"{class_name}.java")
  if os.path.isfile(output_file):
    print(
      f"!! composite type {type_name!r} already generated as {output_file!r}")
    return f"{package_types}.{class_name}"
  
  print(f"!! generating composite type {type_name!r} as {output_file!r}")
  with open(output_file, "w") as f:
    f.write(PREAMBLE)
    f.write(f"package {package_types};\n\n")

    for field_type in fields.values():
      if '.' in field_type:
        f.write(f"import {field_type};\n")
    f.write("import org.postgresql.util.PGobject;\n")
    f.write("import java.sql.ResultSet;\n")
    f.write("import java.sql.SQLException;\n\n")

    f.write(f"public record {class_name} " + "\n(\n")
    f.write(
      ",\n".join(f"\t{short_type_name(field_type)} {field_name}"
      for field_name, field_type in fields.items())
    )
    f.write("\n)\n{\n")
    f.write(f"""\
\tpublic static {class_name} fromPGobject(PGobject pgObj) throws SQLException
\t{{
\t\tString value = pgObj.getValue();
\t\tvalue = value.substring(1, value.length() - 1);
\t\tString[] parts = value.split(",", {len(fields)});
\t\t{generate_composite_parser(type_name, fields, 2)}
\t}}\n
\tpublic static {class_name} fromResultSet(ResultSet rs) throws SQLException
\t{{
\t\treturn fromPGobject((PGobject) rs.getObject(1));
\t}}\n""")
    f.write("}\n")

  return f"{package_types}.{class_name}"


def try_resolve_type(
    type_name: str, output_types_dir: str, package_types: str)\
      -> tuple[str, str]:
  schema = "public"
  if '.' in type_name:
    schema, type_name = type_name.split('.', 1)
  normal_type_name = snake_to_pascal(type_name)
  
  existing_type_file = os.path.join(
    output_types_dir, f"{normal_type_name}.java")
  if os.path.isfile(existing_type_file):
    return 'b', f"{package_types}.{normal_type_name}"
  
  typtype = get_sql_typtype(g_conn, schema, type_name)
  print(f"!! trying to resolve type {schema}.{type_name} (typtype={typtype!r})")
  if typtype == 'c':
    composite_info = {}
    for field_name, field_type, _ \
        in get_composite_fields(g_conn, schema, type_name):
      if psql_java_type_map.get(field_type) is not None:
        composite_info[field_name] = psql_java_type_map[field_type]
        continue

      resolved_field_type = try_resolve_type(
        field_type, output_types_dir, package_types)
      if resolved_field_type is None:
        print(f"!! skipping composite type {type_name!r} because field"
              f" {field_name!r} has unsupported type {field_type!r}")
        return None
      composite_info[field_name] = resolved_field_type
    print(f"!! resolved composite type {type_name!r} with fields:")
    pprint(composite_info)
    return 'c', generate_composite_type(
      type_name, composite_info, output_types_dir, package_types)
  else:
    print(f"!! unsupported typtype {typtype!r} for type {type_name!r}")
    return None


def generate_functions_class(
    funcs_info: dict[str, dict], output_file: str, class_name: str,
    package: str, sql_interface_singleton: str) -> None:
  with open(output_file, "w") as f:
    f.write(PREAMBLE)
    f.write(f"package {package};\n\n")

    imports = set(
      (sql_interface_singleton, "java.util.logging.Logger",
       "java.util.logging.Level", "java.sql.*"))
    for func_info in funcs_info.values():
      if '.' in func_info["ret"][1]:
        imports.add(func_info["ret"][1])
      for _, (_, arg_type) in func_info["args"]:
        if '.' in arg_type:
          imports.add(arg_type)
    
    for imp in sorted(imports):
      f.write(f"import {imp};\n")
    if imports:
      f.write("\n")

    f.write(f"public class {class_name} " + "\n{\n")
    f.write(f"\tprivate static final Logger logger = Logger.getLogger({class_name}.class.getName());\n")
    f.write(f"\tprivate static final {short_type_name(sql_interface_singleton)} sqlInterface = {short_type_name(sql_interface_singleton)}.get();\n\n")
    f.write(f"\tprivate static final Connection conn = sqlInterface.getConnection();\n\n")
    for func_name, func_info in funcs_info.items():
      args_str = ", ".join(
        f"{short_type_name(arg_type)} {snake_to_camel(arg_name)}" \
        for arg_name, (_, arg_type) in func_info["args"])
      f.write(f"\tpublic static {short_type_name(func_info['ret'][1])} {snake_to_camel(func_name)}"
              f"(\n\t\t{args_str}\n\t) throws SQLException" + "\n\t{\n")
      stmt_set_vars = []
      for i, (arg_name, _) in enumerate(func_info["args"], start=1):
        java_arg_name = snake_to_camel(arg_name)
        stmt_set_vars.append(f"\t\t\tstmt.setObject({i}, {java_arg_name});")
      if func_info["ret"][0] == 'b':
        return_line = "return (" + short_type_name(func_info["ret"][1]) + ") rs.getObject(1);"
      elif func_info["ret"][0] == 'c':
        return_line = f"return {func_info['ret'][1]}.fromResultSet(rs);"
      else:
        raise ValueError(
          f"Unsupported return type specifier {func_info['ret'][0]!r} for "
          f"function {func_name!r}") 
      f.write(f"""\
\t\ttry (PreparedStatement stmt = conn.prepareStatement(
\t\t\t"SELECT * from {func_info['schema']}.{func_name}({', '.join(['?'] * len(func_info['args']))})"))
\t\t{{
{'\n'.join(stmt_set_vars)}
\t\t\tResultSet rs = stmt.executeQuery();
\t\t\tif (!rs.next())
\t\t\t\tthrow new SQLException("No result returned from function {func_name!r}");
\t\t\t{return_line}
\t\t}} catch (SQLException sqlExc)
\t\t{{
\t\t\tlogger.log(Level.SEVERE, "Error executing function {func_name!r}", sqlExc);
\t\t\tthrow sqlExc;
\t\t}}\n""")
      f.write("\t}\n\n")
    f.write("}\n")


def main(
    schema: str, output_types_dir: str, package_types: str, output_file: str,
    class_name: str, package: str, sql_interface_singleton: str) -> int:
  argspecs = get_function_argspecs(g_conn, schema)

  funcs_info = {}  
  for func_name, argspec in argspecs.items():
    print(f"!! processing function {func_name!r} with argspec: {argspec!r}")
    funcs_info[func_name] = {"schema": schema, "args": [], "ret": None}
    if psql_java_type_map.get(argspec["ret"]) is None:
      resolved_import = try_resolve_type(
        argspec["ret"], output_types_dir, package_types)
      if resolved_import is None:
        print(f"!! skipping function {func_name!r} with unsupported return type"
              f" {argspec['ret']!r}")
        continue
      funcs_info[func_name]["ret"] = resolved_import
    else:
      funcs_info[func_name]["ret"] = ('b', psql_java_type_map[argspec["ret"]])

    for arg_name, arg_type in argspec["args"]:
      arg_type = arg_type.split("DEFAULT")[0].strip()
      if psql_java_type_map.get(arg_type) is None:
        resolved_import = try_resolve_type(
          arg_type, output_types_dir, package_types)
        if resolved_import is None:
          print(f"!! skipping function {func_name!r} with unsupported argument"
                f" type {arg_type!r}")
          break
        funcs_info[func_name]["args"].append((arg_name, resolved_import))
      else:
        funcs_info[func_name]["args"].append(
          (arg_name, ('b', psql_java_type_map[arg_type])))
    
  print(f"!! resolved function info:")
  pprint(funcs_info)
  generate_functions_class(
    funcs_info, output_file, class_name, package, sql_interface_singleton)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(
    description="Generate Java code for PostgreSQL functions")
  parser.add_argument(
    "--schema",
    default="library_api",
    help="The database schema to inspect"
  )
  parser.add_argument(
    "--output-types-dir",
    required=True,
    help="Output directory for generated types"
  )
  parser.add_argument(
    "--package-types",
    default="com.unazed.LibraryManagement.model.gen",
    help="Java package name for generated types"
  )
  parser.add_argument(
    "--output-file",
    required=True,
    help="Output file for generated Java code"
  )
  parser.add_argument(
    "--class-name",
    default="DatabaseFunctions",
    help="Name of the generated Java class"
  )
  parser.add_argument(
    "--package",
    default="com.unazed.LibraryManagement",
    help="Java package name for generated functions"
  )
  parser.add_argument(
    "--sql-interface-singleton",
    default="com.unazed.LibraryManagement.SqlInterface",
    help="Fully qualified class name of the SQL interface singleton"
  )
  args = parser.parse_args()
  exit(main(
    args.schema, args.output_types_dir, args.package_types, args.output_file,
    args.class_name, args.package, args.sql_interface_singleton))