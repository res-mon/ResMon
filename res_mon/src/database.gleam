import birl
import filepath
import gleam/dict
import gleam/dynamic
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/string_builder
import simplifile
import sqlight

const start_pragmas = "
PRAGMA analysis_limit = 0;
PRAGMA auto_vacuum = 0;
PRAGMA automatic_index = 1;
PRAGMA cache_size = 4000; 
PRAGMA cell_size_check = 1;
PRAGMA defer_foreign_keys = 0;
PRAGMA encoding = 'UTF-8'; 
PRAGMA ignore_check_constraints = 0;
PRAGMA journal_mode = WAL; 
PRAGMA legacy_alter_table = 0;
PRAGMA page_size = 8192;
PRAGMA recursive_triggers = 1;	
"

const end_pragmas = "
PRAGMA integrity_check;
VACUUM;
ANALYZE;
PRAGMA optimize;
PRAGMA shrink_memory;
"

const insert_migration_query = "
INSERT
OR IGNORE INTO \"migration_script\" (\"version\", \"up\", \"down\", \"since_unix_micros\") 
VALUES
  (:version, :up, :down, :since_unix_micros);
"

const migrations_path = "./sql/migration"

const migration_filename_pattern = "Expected filename to start with a integer number followed by an underscore ('_') and ending with either '.up.sql' or '.down.sql'. For example: '0001_comment_here.up.sql'."

pub opaque type Database {
  Database(connection: sqlight.Connection)
}

pub opaque type Error {
  OpenError(error: sqlight.Error)
  CloseError(error: sqlight.Error)
  ExecError(query: String, error: sqlight.Error)
  QueryError(query: String, error: sqlight.Error)
  ErrorMessage(message: String)
  MigrationFileError(path: String, error: simplifile.FileError)
  MigrationFileNameError(path: String, error: String)
}

type Migration {
  Migration(
    version: Int,
    up: option.Option(String),
    down: option.Option(String),
  )
}

fn read_migration(path: String) -> Result(Migration, Error) {
  let parts = filepath.split(path)
  let assert Ok(filename) = list.last(parts)
  let parts = string.split(filename, "_")
  let assert Ok(version) = list.first(parts)

  case int.parse(version) {
    Error(_) -> Error(MigrationFileNameError(path, migration_filename_pattern))
    Ok(version) ->
      case simplifile.read(path) {
        Error(file_error) -> Error(MigrationFileError(path, file_error))
        Ok(content) -> {
          let up = string.ends_with(filename, ".up.sql")
          let down = string.ends_with(filename, ".down.sql")

          case up, down {
            True, False ->
              Ok(Migration(version, option.Some(content), option.None))
            False, True ->
              Ok(Migration(version, option.None, option.Some(content)))
            _, _ ->
              Error(MigrationFileNameError(path, migration_filename_pattern))
          }
        }
      }
  }
}

fn combine_migrations(
  a: Migration,
  with b: Migration,
) -> Result(Migration, Error) {
  case a.version == b.version {
    False ->
      Error(ErrorMessage("Migrations must have the same version number."))
    True -> {
      case a.up, a.down, b.up, b.down {
        option.Some(_), _, option.Some(_), _
        | _, option.Some(_), _, option.Some(_) ->
          Error(ErrorMessage(
            "Migrations from version "
            <> int.to_string(a.version)
            <> " have the same direction.",
          ))
        up, down, option.None, option.None
        | option.None, down, up, option.None
        | up, option.None, option.None, down
        | option.None, option.None, up, down ->
          Ok(Migration(a.version, up, down))
      }
    }
  }
}

fn insert_migration(
  migration: Migration,
  into database: Database,
) -> Result(Nil, Error) {
  use up <- result.try(case migration.up {
    option.Some(up) -> Ok(up)
    option.None -> Error(ErrorMessage("Migrations must have an up query."))
  })

  use down <- result.try(case migration.down {
    option.Some(down) -> Ok(down)
    option.None -> Error(ErrorMessage("Migrations must have a down query."))
  })

  let now = birl.utc_now()
  let unix_micros = birl.to_unix_micro(now)

  use _ <- result.try(query(
    insert_migration_query,
    database,
    [
      sqlight.int(migration.version),
      sqlight.text(up),
      sqlight.text(down),
      sqlight.int(unix_micros),
    ],
    dynamic.dynamic,
  ))

  Ok(Nil)
}

fn get_connnection_string(path: String) -> String {
  case path {
    "" -> ":memory:"
    _ -> {
      let connection_string = string_builder.from_string(path)

      let connection_string =
        string_builder.prepend(connection_string, {
          case string.starts_with(path, "file:") {
            True -> ""
            False -> "file:"
          }
        })

      let connection_string =
        string_builder.append(connection_string, {
          case string.contains(path, "?") {
            True -> "&"
            False -> "?"
          }
        })

      let connection_string =
        string_builder.append(connection_string, "_pragma=page_size(8192)")

      string_builder.to_string(connection_string)
    }
  }
}

pub fn open(path: String) -> Result(Database, Error) {
  let connection_string = get_connnection_string(path)

  use connection <- result.try(
    sqlight.open(connection_string)
    |> result.map_error(OpenError),
  )

  let database = Database(connection)

  use _ <- result.try(exec(start_pragmas, database))
  use _ <- result.try(migrate(database, migrations_path))
  use _ <- result.try(exec(end_pragmas, database))

  Ok(database)
}

pub fn close(database: Database) -> Result(Nil, Error) {
  sqlight.close(database.connection)
  |> result.map_error(CloseError)
}

pub fn exec(query: String, on database: Database) -> Result(Nil, Error) {
  let result = sqlight.exec(query, database.connection)

  case result {
    Ok(Nil) -> Ok(Nil)
    Error(error) -> Error(ExecError(query, error))
  }
}

pub fn query(
  query: String,
  on database: Database,
  with arguments: List(sqlight.Value),
  expecting decoder: fn(dynamic.Dynamic) -> Result(a, List(dynamic.DecodeError)),
) -> Result(List(a), Error) {
  sqlight.query(query, database.connection, arguments, decoder)
  |> result.map_error(QueryError(query, _))
}

fn migration_files(migrations_path: String) -> Result(List(Migration), Error) {
  let files = simplifile.get_files(migrations_path)

  case files {
    Error(error) -> Error(MigrationFileError(migrations_path, error))

    Ok(files) -> {
      let migrations =
        list.fold(files, Ok(dict.new()), fn(migrations, path) {
          use migrations <- result.try(migrations)
          use migration <- result.try(read_migration(path))

          let existing_migration =
            dict.get(migrations, migration.version)
            |> result.unwrap(Migration(
              migration.version,
              option.None,
              option.None,
            ))

          use migration <- result.try(combine_migrations(
            existing_migration,
            migration,
          ))

          Ok(dict.insert(migrations, migration.version, migration))
        })
        |> result.map(dict.values)

      use migrations <- result.try(migrations)
      use migrations <- result.try(
        list.map(migrations, fn(migration) {
          case migration.up, migration.down {
            option.Some(up), option.Some(down) ->
              Ok(Migration(
                migration.version,
                option.Some(up),
                option.Some(down),
              ))
            _, _ ->
              Error(ErrorMessage(
                "Migrations must have both an up and a down query.",
              ))
          }
        })
        |> result.all,
      )

      Ok(list.sort(migrations, fn(a, b) { int.compare(a.version, b.version) }))
    }
  }
}

fn get_user_version(database: Database) -> Result(Int, Error) {
  case
    query("PRAGMA user_version;", database, [], dynamic.element(0, dynamic.int))
  {
    Error(error) -> Error(error)
    Ok(versions) -> {
      case list.first(versions) {
        Ok(version) -> Ok(version)
        Error(Nil) -> Error(ErrorMessage("No user version found."))
      }
    }
  }
}

fn set_user_version(database: Database, version: Int) -> Result(Nil, Error) {
  query(
    "PRAGMA user_version = " <> int.to_string(version) <> ";",
    database,
    [],
    dynamic.dynamic,
  )
  |> result.map(fn(_) { Nil })
}

fn migrate(
  database: Database,
  and migrations_path: String,
) -> Result(Nil, Error) {
  use migrations <- result.try(migration_files(migrations_path))
  use user_version <- result.try(get_user_version(database))

  let migrations =
    list.filter(migrations, fn(migration) { migration.version > user_version })

  use _ <- result.try(
    list.fold(migrations, Ok(Nil), fn(error, migration) {
      use _ <- result.try(error)
      let assert option.Some(script) = migration.up

      use _ <- result.try(exec(script, database))
      use _ <- result.try(insert_migration(migration, database))
      use _ <- result.try(set_user_version(database, migration.version))

      Ok(Nil)
    }),
  )

  Ok(Nil)
}
