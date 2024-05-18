import birl
import database
import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/io
import mist
import simplifile
import web/router
import web/web.{Context}
import wisp

pub fn main() {
  let assert Ok(_) = simplifile.create_directory_all("./data")
  let assert Ok(db) = database.open("./data/database.db")

  wisp.configure_logger()

  dot_env.load()
  let assert Ok(secret_key_base) = env.get("SECRET_KEY_BASE")

  let ctx = Context(static_directory: static_directory(), items: [])

  let handler = router.handle_request(_, ctx)

  let assert Ok(_) =
    wisp.mist_handler(handler, secret_key_base)
    |> mist.new
    |> mist.port(8321)
    |> mist.start_http

  process.trap_exits(True)

  // Create a selector to handle exit signals
  let selector =
    process.new_selector()
    |> process.selecting_trapped_exits(handle_exit_signal(db))

  // Run your main application logic here
  io.println("Application is running...")

  // Wait for an exit signal
  let _ = process.select_forever(selector)

  io.println("Application is shutting down.")
}

fn handle_exit_signal(db: database.Database) -> fn(process.ExitMessage) -> Nil {
  fn(signal: process.ExitMessage) -> Nil{
    // Close the database connection here
    io.println("Received exit signal:")
    io.debug(signal)
    io.println("Closing database connection...")
    // Your code to close the database connection
    
    let assert Ok(_) = database.close(db)
    Nil
  }
}

fn static_directory() {
  "./static"
}
