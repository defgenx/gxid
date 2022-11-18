import gleam/int
import gleam/list
import gleam/bit_string
import gleam/string
import gleam/bitwise
import gleam/erlang.{Millisecond}
import gleam/otp/actor.{Continue, Next, StartResult}
import gleam/erlang/process.{Subject}

const actor_timeout = 1000

/// A library implementing XID generation
/// Message handled by the actor
pub opaque type Message {
  Generate(Subject(XID))
}

/// Actor's State internal representation
pub opaque type State {
  State(machine_id: Int, pid: Int, random_number: Int)
}

/// XID representation
///
/// This is an opaque type to ensure its RO nature
pub opaque type XID {
  XID(time: Int, machine_id: Int, pid: Int, random_number: Int, string: String)
}

/// Returns xid string representation from XID type
pub fn string(xid: XID) -> String {
  xid.string
}

/// Returns time from XID type
pub fn time(xid: XID) -> Int {
  xid.time
}

/// Returns machine id from XID type
pub fn machine_id(xid: XID) -> Int {
  xid.machine_id
}

/// Returns PID from XID type
pub fn pid(xid: XID) -> Int {
  xid.pid
}

/// Returns random number from XID type
pub fn random_number(xid: XID) -> Int {
  xid.random_number
}

/// Starts State generator
pub fn start() -> StartResult(Message) {
  actor.start(
    State(find_machine_id(), find_pid(), int.random(0, 16_777_215)),
    handle,
  )
}

/// Generates a XID
///
/// ### Usage
/// ```gleam
/// import gxid.{XID}
///
/// assert Ok(channel) = gxid.start()
///
/// let xid: XID = gxid.generate(channel)
/// ```
/// See: https:///hexdocs.pm/gleam_otp/0.1.1/gleam/otp/actor/#call
pub fn generate(channel: Subject(Message)) -> XID {
  actor.call(channel, Generate, actor_timeout)
}

/// Handles generation logic with encoding
fn handle(msg: Message, state: State) -> Next(State) {
  case msg {
    Generate(reply) -> {
      actor.send(
        reply,
        [
          format_time(erlang.system_time(Millisecond)),
          format_machine_id(state.machine_id),
          format_pid(state.pid),
          format_random_number(state.random_number),
        ]
        |> bit_string.concat()
        |> to_xid(),
      )
      Continue(State(..state, random_number: state.random_number + 1))
    }
  }
}

/// 4-byte (32 bits) representation of time
fn format_time(time: Int) -> BitString {
  <<time:big-32>>
}

/// 3-byte (24 bits) representation of machine id
fn format_machine_id(mid: Int) -> BitString {
  <<mid:big-24>>
}

/// 2-byte (16 bits) representation
fn format_pid(pid: Int) -> BitString {
  <<pid:big-16>>
}

/// 3-byte (24 bits) representation of random number
fn format_random_number(random_number: Int) -> BitString {
  <<bitwise.shift_left(random_number, 8):big-24>>
}

/// Fetches current PID
fn find_pid() -> Int {
  assert Ok(pid) =
    os_getpid()
    |> char_list_to_string()
    |> int.parse()
  pid
}

/// Finds current machine ID
fn find_machine_id() -> Int {
  net_adm_localhost()
  |> list.fold(from: 0, with: fn(char, acc) { char + acc })
}

/// Encodes a BitString representation to a base32 String
fn encode(bit_xid: BitString) -> String {
  let <<b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11>> = <<
    bit_xid:bit_string,
  >>
  let res = [
    encode_hex(bitwise.shift_right(b0, 3)),
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
  string.join(res, "")
}

/// Encodes an int to string for State
///
/// 0123456789abcdefghijklmnopqrstuv - Used for encoding
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

/// Parse a XID string to have its composition
///
/// ### Usage
/// ```gleam
/// import gxid.{XID}
///
/// let xid: XID = gxid.parse("h8a8u4o00de6hq6tsc00")
/// ```
pub fn parse(str_xid: String) -> XID {
  decode(str_xid)
  |> to_xid()
}

/// Copy a BitString to a new XID and encode
pub fn to_xid(bit_xid: BitString) -> XID {
  let <<
    time:big-unsigned-32,
    mid:big-unsigned-24,
    pid:big-unsigned-16,
    rn1:big-unsigned,
    rn2:big-unsigned,
    rn3:big-unsigned,
  >> = <<bit_xid:bit_string>>

  XID(
    time,
    mid,
    pid,
    bitwise.or(
      bitwise.or(bitwise.shift_left(rn1, 16), bitwise.shift_left(rn2, 8)),
      rn3,
    ),
    encode(bit_xid),
  )
}

/// Decodes a base32 String representation to a BitString
fn decode(xid: String) -> BitString {
  let [
    s0,
    s1,
    s2,
    s3,
    s4,
    s5,
    s6,
    s7,
    s8,
    s9,
    s10,
    s11,
    s12,
    s13,
    s14,
    s15,
    s16,
    s17,
    s18,
    s19,
  ] =
    string.to_graphemes(xid)
    |> list.map(fn(x) { decode_hex(x) })

  <<
    bitwise.or(bitwise.shift_left(s0, 3), bitwise.shift_right(s1, 2)),
    bitwise.or(
      bitwise.or(bitwise.shift_left(s1, 6), bitwise.shift_left(s2, 1)),
      bitwise.shift_right(s3, 4),
    ),
    bitwise.or(bitwise.shift_left(s3, 4), bitwise.shift_right(s4, 1)),
    bitwise.or(
      bitwise.or(bitwise.shift_left(s4, 7), bitwise.shift_left(s5, 2)),
      bitwise.shift_right(s6, 3),
    ),
    bitwise.or(bitwise.shift_left(s6, 5), s7),
    bitwise.or(bitwise.shift_left(s8, 3), bitwise.shift_right(s9, 2)),
    bitwise.or(
      bitwise.or(bitwise.shift_left(s9, 6), bitwise.shift_left(s10, 1)),
      bitwise.shift_right(s11, 4),
    ),
    bitwise.or(bitwise.shift_left(s11, 4), bitwise.shift_right(s12, 1)),
    bitwise.or(
      bitwise.or(bitwise.shift_left(s12, 7), bitwise.shift_left(s13, 2)),
      bitwise.shift_right(s14, 3),
    ),
    bitwise.or(bitwise.shift_left(s14, 5), s15),
    bitwise.or(bitwise.shift_left(s16, 3), bitwise.shift_right(s17, 2)),
    bitwise.or(
      bitwise.or(bitwise.shift_left(s17, 6), bitwise.shift_left(s18, 1)),
      bitwise.shift_right(s19, 4),
    ),
  >>
}

/// Decodes a string to an int for State
///
/// We decided to hardcode this for encode and decode for performance and visibility
fn decode_hex(s: String) -> Int {
  case s {
    "0" -> 0
    "1" -> 1
    "2" -> 2
    "3" -> 3
    "4" -> 4
    "5" -> 5
    "6" -> 6
    "7" -> 7
    "8" -> 8
    "9" -> 9
    "a" -> 10
    "b" -> 11
    "c" -> 12
    "d" -> 13
    "e" -> 14
    "f" -> 15
    "g" -> 16
    "h" -> 17
    "i" -> 18
    "j" -> 19
    "k" -> 20
    "l" -> 21
    "m" -> 22
    "n" -> 23
    "o" -> 24
    "p" -> 25
    "q" -> 26
    "r" -> 27
    "s" -> 28
    "t" -> 29
    "u" -> 30
    "v" -> 31
  }
}

external type CharList

external fn os_getpid() -> CharList =
  "os" "getpid"

external fn char_list_to_string(CharList) -> String =
  "erlang" "list_to_binary"

external fn net_adm_localhost() -> List(Int) =
  "net_adm" "localhost"
