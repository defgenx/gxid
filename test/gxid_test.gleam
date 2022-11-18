import gleeunit
import gleeunit/should
import gxid
import gleam/iterator.{Done, Next}
import gleam/map
import gleam/pair

const test_xid_string = "h8a8u4o00de6hq6tsc00"

pub fn main() {
  gleeunit.main()
}

pub fn generate_test() {
  assert Ok(channel) = gxid.start()

  fn() {
    gxid.generate(channel)
    |> gxid.string()
  }
  |> collide()
  |> should.be_false()
}

pub fn parse_test() {
  assert Ok(channel) = gxid.start()

  let gxid = gxid.generate(channel)
  gxid.parse(
    gxid
    |> gxid.string(),
  )
  |> should.equal(gxid)
}

pub fn xid_time_test() {
  let xid = gxid.parse("h8a8u4o00de6hq6tsc00")

  xid
  |> gxid.time
  |> should.equal(2316603155)
}

pub fn xid_machine_id_test() {
  let xid = gxid.parse(test_xid_string)

  xid
  |> gxid.machine_id
  |> should.equal(860)
}

pub fn xid_pid_test() {
  let xid = gxid.parse(test_xid_string)

  xid
  |> gxid.pid
  |> should.equal(26856)
}

pub fn xid_random_number_test() {
  let xid = gxid.parse(test_xid_string)

  xid
  |> gxid.random_number
  |> should.equal(14541568)
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
