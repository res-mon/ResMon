import web/models/item.{type Item}
import web/pages/home

pub fn home(items: List(Item)) {
  home.root(items)
}
