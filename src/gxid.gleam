// A library implementing XID generation

import gleam/int
import gleam/list
import gleam/bit_string
import gleam/string
import gleam/bitwise
import gleam/erlang.{Millisecond}
import gleam/otp/actor.{Continue, Next, StartResult}
import gleam/erlang/process.{Subject}

// Message handled by the actor
pub opaque type Message {
  Generate(Subject(String))
}

// Actor's internal state
pub opaque type State {
  State(random_number: Int, pid: Int, machine_id: Int)
}

// Starts XID generator
pub fn start() -> StartResult(Message) {
  actor.start(
    State(int.random(0, 16_777_215), get_int_pid(), get_machine_id()),
    handle,
  )
}

// Generates a XID
//
// ### Usage
// ```gleam
// import gxid
//
// assert Ok(channel) = gxid.start()
//
// let id: String = gxid.generate(channel)
// ```
// See: https://hexdocs.pm/gleam_otp/0.1.1/gleam/otp/actor/#call
pub fn generate(channel: Subject(Message)) -> String {
  actor.call(channel, Generate, 1000)
}

// Handles generation logic (encoding)
fn handle(msg: Message, state: State) -> Next(State) {
  case msg {
    Generate(reply) -> {
      let id =
        format_id([
          format_time(erlang.system_time(Millisecond)),
          format_machine_id(state.machine_id),
          format_pid(state.pid),
          format_random_number(state.random_number),
        ])
      actor.send(reply, id)
      Continue(State(..state, random_number: state.random_number + 1))
    }
  }
}

// 4-byte (32 bits) representation
fn format_time(time: Int) -> BitString {
  <<time:big-32>>
}

// 3-byte (24 bits) representation
fn format_machine_id(mid: Int) -> BitString {
  <<mid:big-24>>
}

// 2-byte (16 bits) representation
fn format_pid(pid: Int) -> BitString {
  <<pid:big-16>>
}

// 3-byte (24 bits) representation
fn format_random_number(random_number: Int) -> BitString {
  <<bitwise.shift_left(random_number, 8):24>>
}

fn format_id(id_data: List(BitString)) -> String {
  encode(
    id_data
    |> bit_string.concat(),
  )
}

fn get_int_pid() -> Int {
  assert Ok(pid) =
    os_getpid()
    |> char_list_to_string()
    |> int.parse()
  pid
}

fn get_machine_id() -> Int {
  let localhost = net_adm_localhost()
  localhost
  |> list.fold(from: 0, with: fn(char, acc) { char + acc })
}

fn encode(bit_xid: BitString) -> String {
  let <<
    b0:8,
    b1:8,
    b2:8,
    b3:8,
    b4:8,
    b5:8,
    b6:8,
    b7:8,
    b8:8,
    b9:8,
    b10:8,
    b11:8,
  >> = <<bit_xid:bit_string>>
  let rez = [
    encode_hex(bitwise.shift_right(b0, 8)),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b1, 6), 0x1F),
      bitwise.and(bitwise.shift_left(b0, 2), 0x1F),
    )),
    encode_hex(bitwise.and(bitwise.shift_right(b1, 1), 0x1F)),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b2, 4), 0x1F),
      bitwise.and(bitwise.shift_left(b1, 4), 0x1F),
    )),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b3, 7), 0x1F),
      bitwise.and(bitwise.shift_left(b2, 1), 0x1F),
    )),
    encode_hex(bitwise.and(bitwise.shift_right(b3, 2), 0x1F)),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b4, 5), 0x1F),
      bitwise.and(bitwise.shift_left(b3, 3), 0x1F),
    )),
    encode_hex(bitwise.and(b4, 0x1F)),
    encode_hex(bitwise.shift_right(b5, 3)),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b6, 6), 0x1F),
      bitwise.and(bitwise.shift_left(b5, 2), 0x1F),
    )),
    encode_hex(bitwise.and(bitwise.shift_right(b6, 1), 0x1F)),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b7, 4), 0x1F),
      bitwise.and(bitwise.shift_left(b6, 4), 0x1F),
    )),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b8, 7), 0x1F),
      bitwise.and(bitwise.shift_left(b7, 1), 0x1F),
    )),
    encode_hex(bitwise.and(bitwise.shift_right(b8, 2), 0x1F)),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b9, 5), 0x1F),
      bitwise.and(bitwise.shift_left(b8, 3), 0x1F),
    )),
    encode_hex(bitwise.and(b9, 0x1F)),
    encode_hex(bitwise.shift_right(b10, 3)),
    encode_hex(bitwise.or(
      bitwise.and(bitwise.shift_right(b11, 6), 0x1F),
      bitwise.and(bitwise.shift_left(b10, 2), 0x1F),
    )),
    encode_hex(bitwise.and(bitwise.shift_right(b11, 1), 0x1F)),
    encode_hex(bitwise.and(bitwise.shift_left(b11, 4), 0x1F)),
  ]
  string.join(rez, "")
}

// 0123456789abcdefghijklmnopqrstuv - Used for encoding
fn encode_hex(i: Int) -> String {
  case i {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    10 -> "a"
    11 -> "b"
    12 -> "c"
    13 -> "d"
    14 -> "e"
    15 -> "f"
    16 -> "g"
    17 -> "h"
    18 -> "i"
    19 -> "j"
    20 -> "k"
    21 -> "l"
    22 -> "m"
    23 -> "n"
    24 -> "o"
    25 -> "p"
    26 -> "q"
    27 -> "r"
    28 -> "s"
    29 -> "t"
    30 -> "u"
    31 -> "v"
  }
}

external type CharList

external fn os_getpid() -> CharList =
  "os" "getpid"

external fn char_list_to_string(CharList) -> String =
  "erlang" "list_to_binary"

external fn net_adm_localhost() -> List(Int) =
  "net_adm" "localhost"