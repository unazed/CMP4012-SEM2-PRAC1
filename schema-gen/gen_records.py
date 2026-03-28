from util import *
import psycopg2
import argparse
import os


conn = psycopg2.connect(
    host="localhost",
    dbname="library_main",
    user="postgres",
    password="postgres"
)

def write_record_to_file(
    path: str, record: dict[str, str], imports: set[str], package: str) -> None:
  with open(path, 'w') as f:
    f.write(PREAMBLE)
    f.write(f"package {package};\n\n")
    for imp in sorted(imports):
      f.write(f"import {imp};\n")
    if imports:
      f.write("\n")
    f.write("public record "
            f"{os.path.splitext(os.path.basename(path))[0]}(\n")
    for i, (field_name, field_type) in enumerate(record.items()):
      comma = ',' if i < len(record) - 1 else ''
      f.write(f"\t{field_type} {field_name}{comma}\n")
    f.write(") {}\n")


def write_enum_to_file(
    path: str, enum_name: str, values: list[str], package: str) -> None:
  with open(path, 'w') as f:
    f.write(PREAMBLE)
    f.write(f"package {package};\n\n")
    f.write(f"public enum {enum_name} {{\n")
    for i, value in enumerate(values):
      comma = ',' if i < len(values) - 1 else ''
      f.write(f"\t{value.upper()}{comma}\n")
    f.write("}\n")

def main(
    package: str, schema_name: str, tables: list[str], output_dir: str) -> None:
  schema_gen = {}

  for table_name in tables:
    schema_gen[record_dir := os.path.join(output_dir, f"{table_name}.java")] = {
      "imports": set(),
      "record": {}
    }
    schema = get_table_schema(conn, schema_name, table_name.lower())
    print(f"!! processing table: {table_name!r} with schema: {schema_name!r}")
    for column_name, data_type, udt_name in schema:
      print(f"!! processing column: {column_name}@{data_type} "
            f"(udt: {udt_name})")
      java_type = psql_java_type_map.get(data_type)
      if java_type is None:
        if data_type != "USER-DEFINED":
          print(f"!! table: {table_name!r} has unhandled "
                f"column-type: {column_name}@{data_type}")
          continue
        data_typtype = get_sql_typtype(conn, schema_name, udt_name)
        if data_typtype == "e":
          enum_info = get_sql_enum_info(conn, schema_name, udt_name)
          enum_path = os.path.join(output_dir, f"{enum_info['name']}.java")
          if enum_path not in schema_gen:
            schema_gen[enum_path] = {
              "imports": set(),
              "enum": enum_info
            }
            schema_gen[record_dir]['imports'].add(
              f"{package}.{enum_info['name']}")
          java_type = enum_info['name']
          print(f"!! table: {table_name!r} has enum column: "
                f"{column_name}@{udt_name} -> {enum_info}")
        else:
          print(f"!! table: {table_name!r} has unhandled user-defined column: "
                f"{column_name}@{udt_name} with typtype {data_typtype}")
          continue
      if '.' in java_type:
        schema_gen[record_dir]['imports'].add(java_type)
        java_type = java_type.split('.')[-1]
      schema_gen[record_dir]['record'][column_name] = java_type

  print("!! generation plan:")
  for path, gen_info in schema_gen.items():
    if 'record' in gen_info:
      print(f"!! generating record for {path!r} with imports: "
            f"{gen_info['imports']} and fields: {gen_info['record']}")
      write_record_to_file(
        path, gen_info['record'], gen_info['imports'], package)
    elif 'enum' in gen_info:
      print(f"!! generating enum for {path!r} with values: "
            f"{gen_info['enum']['values']}")
      write_enum_to_file(
        path, gen_info['enum']['name'], gen_info['enum']['values'], package)
    else:
      print(f"!! unknown gen info for {path!r}: {gen_info}")


if __name__ == "__main__":
  parser = argparse.ArgumentParser(
    description="Generate Java records from PostgreSQL tables")
  
  parser.add_argument(
      "--tables",
      nargs="+",
      required=True,
      help="List of tables for which to generate records"
  )
  parser.add_argument(
      "--schema",
      default="library",
      help="PostgreSQL schema to query"
  )
  parser.add_argument(
      "--output",
      required=True,
      help="Output directory for generated Java files"
  )
  parser.add_argument(
      "--package",
      default="com.unazed.LibraryManagement.model.gen",
      help="Java package name for generated records"
  )

  args = parser.parse_args()
  exit(main(args.package, args.schema, args.tables, args.output))