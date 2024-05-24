import database
import dot_env
import dot_env/env
import extension
import gleam/io
import mist
import simplifile
import web/router
import web/web.{Context}
import wisp

pub fn main() {
  io.println("Starting ResMon...")

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

  extension.wait_for_shutdown()

  io.println("ResMon is shutting down...")
  let assert Ok(_) = database.close(db)
  io.println("ResMon has shut down. Thanks for using it! <3")
}

fn static_directory() {
  "./static"
}
