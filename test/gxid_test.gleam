import gleeunit
import gleeunit/should
import gxid
import gleam/iterator.{Done, Next}
import gleam/map
import gleam/pair

pub fn main() {
  gleeunit.main()
}

pub fn generate_test() {
  assert Ok(channel) = gxid.start()

  fn() { gxid.generate(channel) }
  |> collide()
  |> should.be_false()
}

/// Function heavily inspired from: https://github.com/rvcas/ids/blob/main/test/ids/cuid_test.gleam
fn collide(func: fn() -> String) -> Bool {
  iterator.unfold(
    from: 0,
    with: fn(acc) {
      case acc < 100_000 {
        False -> Done
        True -> Next(element: func(), accumulator: acc + 1)
      }
    },
  )
  |> iterator.fold(
    from: #(map.new(), False),
    with: fn(acc, id) {
      let #(id_map, flag) = acc

      case flag {
        True -> acc
        False ->
          case map.get(id_map, id) {
            Ok(_) -> #(id_map, True)
            Error(_) -> #(map.insert(id_map, id, id), False)
          }
      }
    },
  )
  |> pair.second()
}
