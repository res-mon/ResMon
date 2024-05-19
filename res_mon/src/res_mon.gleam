import database
import dot_env
import dot_env/env
import mist
import simplifile
import web/router
import web/web.{Context}
import wisp

@external(erlang, "signal_handler_ffi", "wait_for_shutdown")
pub fn wait_for_shutdown() -> Nil

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


  wait_for_shutdown()

  let assert Ok(_) = database.close(db)
}

fn static_directory() {
  "./static"
}
