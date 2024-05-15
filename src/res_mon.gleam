import dot_env
import dot_env/env
import gleam/erlang/process
import mist
import web/router
import web/web.{Context}
import wisp

pub fn main() {
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

  process.sleep_forever()
}

fn static_directory() {
  let assert Ok(priv_directory) = wisp.priv_directory("res_mon")
  priv_directory <> "/static"
}
